param(
    [string]$OutputPath,
    [string]$PdfPath,
    [string]$ReferenceDocxPath,
    [switch]$SkipPdfBuild,
    [switch]$SkipFrontmatter,
    [switch]$SkipMermaid,
    [switch]$ForceFrontmatter,
    [switch]$ForceMermaid,
    [switch]$OpenAfterBuild
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host $Message
}

function Resolve-ProjectPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $Path))
}

function Get-DefaultDocxOutput {
    $mainPath = Join-Path $ProjectRoot "main.tex"
    $content = Get-Content -LiteralPath $mainPath -Raw -Encoding UTF8
    $title = "毕业设计论文"
    $match = [regex]::Match($content, "\\makethesiscover\s*\{(?<title>[^}]+)\}")
    if ($match.Success) {
        $candidate = ($match.Groups["title"].Value -replace "\\allowbreak\{\}", "" -replace "\\_", "_").Trim()
        if ($candidate -and $candidate -notmatch "请.*填写|毕业设计.*题目") {
            $title = $candidate
        }
    }
    foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
        $title = $title.Replace([string]$char, "_")
    }
    return Join-Path $ProjectRoot (Join-Path "dist" "$title.docx")
}

function Convert-PdfToDocxWithWord {
    param(
        [string]$SourcePdf,
        [string]$TargetDocx
    )

    if (-not (Test-Path -LiteralPath $SourcePdf -PathType Leaf)) {
        throw "PDF not found: $SourcePdf"
    }

    $targetDir = Split-Path -Parent $TargetDocx
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $word = $null
    $doc = $null
    try {
        Write-Step "[docx] open PDF in Microsoft Word: $SourcePdf"
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $word.DisplayAlerts = 0
        $word.AutomationSecurity = 3

        # Word's PDF importer is layout-oriented and keeps page breaks, fixed
        # frontmatter, figures, tables and whitespace much closer to main.pdf
        # than rebuilding DOCX from LaTeX/Pandoc.
        $doc = $word.Documents.Open($SourcePdf, $false, $true)

        if (Test-Path -LiteralPath $TargetDocx -PathType Leaf) {
            Remove-Item -LiteralPath $TargetDocx -Force
        }

        Write-Step "[docx] save DOCX: $TargetDocx"
        $wdFormatXMLDocument = 16
        $doc.SaveAs2($TargetDocx, $wdFormatXMLDocument)
    }
    finally {
        if ($null -ne $doc) {
            $doc.Close($false) | Out-Null
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
        }
        if ($null -ne $word) {
            $word.Quit() | Out-Null
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

function Convert-PdfToDocxWithPython {
    param(
        [string]$SourcePdf,
        [string]$TargetDocx
    )

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $python) {
        throw "python not found. Install Python or Microsoft Word PDF converter, then retry."
    }

    $targetDir = Split-Path -Parent $TargetDocx
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $scriptPath = Join-Path ([System.IO.Path]::GetTempPath()) ("zust-pdf2docx-" + [System.Guid]::NewGuid().ToString("N") + ".py")
    $pythonCode = @"
import sys
import logging
from pathlib import Path

try:
    from pdf2docx import Converter
except Exception as exc:
    raise SystemExit("pdf2docx is not installed or cannot be imported: " + str(exc))

source = Path(sys.argv[1])
target = Path(sys.argv[2])
logging.getLogger().setLevel(logging.ERROR)
if not source.is_file():
    raise SystemExit("PDF not found: " + str(source))
target.parent.mkdir(parents=True, exist_ok=True)
if target.exists():
    target.unlink()

converter = Converter(str(source))
try:
    converter.convert(str(target), start=0, end=None)
finally:
    converter.close()
"@

    try {
        Set-Content -LiteralPath $scriptPath -Value $pythonCode -Encoding UTF8
        Write-Step "[docx] convert PDF with python pdf2docx"
        & $python.Source $scriptPath $SourcePdf $TargetDocx
        if ($LASTEXITCODE -ne 0) {
            throw "python pdf2docx conversion failed"
        }
    }
    finally {
        if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
            Remove-Item -LiteralPath $scriptPath -Force
        }
    }
}

function Convert-PdfToDocxWithPdfObjects {
    param(
        [string]$SourcePdf,
        [string]$TargetDocx
    )

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $python) {
        throw "python not found. Cannot rebuild DOCX from PDF objects."
    }

    $targetDir = Split-Path -Parent $TargetDocx
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $scriptPath = Join-Path $PSScriptRoot "pdf-object-docx.py"
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        throw "PDF object converter not found: $scriptPath"
    }

    Write-Step "[docx] rebuild DOCX from PDF objects"
    & $python.Source $scriptPath $SourcePdf $TargetDocx
    if ($LASTEXITCODE -ne 0) {
        throw "python PDF object conversion failed"
    }
}

function Convert-PdfToDocxWithPageImages {
    param(
        [string]$SourcePdf,
        [string]$TargetDocx
    )

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $python) {
        throw "python not found. Cannot render PDF pages into DOCX."
    }

    $targetDir = Split-Path -Parent $TargetDocx
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $scriptPath = Join-Path ([System.IO.Path]::GetTempPath()) ("zust-pdf-image-docx-" + [System.Guid]::NewGuid().ToString("N") + ".py")
    $pythonCode = @"
import sys
from io import BytesIO
from pathlib import Path

import fitz
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Inches

source = Path(sys.argv[1])
target = Path(sys.argv[2])
if not source.is_file():
    raise SystemExit("PDF not found: " + str(source))
target.parent.mkdir(parents=True, exist_ok=True)
if target.exists():
    target.unlink()

pdf = fitz.open(source)
doc = Document()
section = doc.sections[0]
margin = 0.04
section.left_margin = section.right_margin = section.top_margin = section.bottom_margin = Inches(margin)
section.header_distance = section.footer_distance = Inches(0)

zoom = 2.0
matrix = fitz.Matrix(zoom, zoom)

for index, page in enumerate(pdf):
    rect = page.rect
    page_width = rect.width / 72
    page_height = rect.height / 72
    section.page_width = Inches(page_width)
    section.page_height = Inches(page_height)

    pix = page.get_pixmap(matrix=matrix, alpha=False)
    image = BytesIO(pix.tobytes("png"))
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    paragraph.paragraph_format.space_before = 0
    paragraph.paragraph_format.space_after = 0
    paragraph.paragraph_format.line_spacing = 1
    run = paragraph.add_run()
    run.add_picture(image, width=Inches(page_width - margin * 2), height=Inches(page_height - margin * 2))

doc.save(target)
"@

    try {
        Set-Content -LiteralPath $scriptPath -Value $pythonCode -Encoding UTF8
        Write-Step "[docx] render PDF pages as full-page images"
        & $python.Source $scriptPath $SourcePdf $TargetDocx
        if ($LASTEXITCODE -ne 0) {
            throw "python image-based DOCX conversion failed"
        }
    }
    finally {
        if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
            Remove-Item -LiteralPath $scriptPath -Force
        }
    }
}

function Convert-PdfToDocx {
    param(
        [string]$SourcePdf,
        [string]$TargetDocx
    )

    try {
        Convert-PdfToDocxWithPdfObjects -SourcePdf $SourcePdf -TargetDocx $TargetDocx
        return "pdf-objects"
    }
    catch {
        Write-Warning "[docx] PDF object conversion failed: $($_.Exception.Message)"
        try {
            Convert-PdfToDocxWithWord -SourcePdf $SourcePdf -TargetDocx $TargetDocx
            return "word"
        }
        catch {
            Write-Warning "[docx] Microsoft Word PDF conversion failed: $($_.Exception.Message)"
            Convert-PdfToDocxWithPython -SourcePdf $SourcePdf -TargetDocx $TargetDocx
            return "pdf2docx"
        }
    }
}

function Get-PdfPageCount {
    param([string]$SourcePdf)

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $python) {
        throw "python not found; cannot verify PDF page count."
    }

    $script = "import fitz, sys; print(fitz.open(sys.argv[1]).page_count)"
    $result = & $python.Source -c $script $SourcePdf
    if ($LASTEXITCODE -ne 0) {
        throw "failed to read PDF page count: $SourcePdf"
    }
    return [int]($result | Select-Object -Last 1)
}

function Get-WordPageCount {
    param([string]$DocxPath)

    $word = $null
    $doc = $null
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $word.DisplayAlerts = 0
        $doc = $word.Documents.Open($DocxPath, $false, $true)
        $doc.Repaginate()
        return $doc.ComputeStatistics(2)
    }
    finally {
        if ($null -ne $doc) {
            $doc.Close($false) | Out-Null
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
        }
        if ($null -ne $word) {
            $word.Quit() | Out-Null
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Get-DefaultDocxOutput
}
else {
    $OutputPath = Resolve-ProjectPath -Path $OutputPath
}

if ([string]::IsNullOrWhiteSpace($PdfPath)) {
    $PdfPath = Join-Path $ProjectRoot "main.pdf"
}
else {
    $PdfPath = Resolve-ProjectPath -Path $PdfPath
}

if (-not [string]::IsNullOrWhiteSpace($ReferenceDocxPath)) {
    $ReferenceDocxPath = Resolve-ProjectPath -Path $ReferenceDocxPath
}

if (-not $SkipPdfBuild) {
    $buildArgs = @()
    if ($SkipFrontmatter) {
        $buildArgs += "-SkipFrontmatter"
    }
    if ($SkipMermaid) {
        $buildArgs += "-SkipMermaid"
    }
    if ($ForceFrontmatter) {
        $buildArgs += "-ForceFrontmatter"
    }
    if ($ForceMermaid) {
        $buildArgs += "-ForceMermaid"
    }

    Write-Step "[docx] build PDF first"
    & (Join-Path $PSScriptRoot "build.ps1") @buildArgs
    if ($LASTEXITCODE -ne 0) {
        throw "PDF build failed"
    }
}

if (-not (Test-Path -LiteralPath $PdfPath -PathType Leaf)) {
    throw "PDF not found: $PdfPath"
}

$pdfPageCount = Get-PdfPageCount -SourcePdf $PdfPath
Write-Step "[docx] PDF page count: $pdfPageCount"

$backend = Convert-PdfToDocx -SourcePdf $PdfPath -TargetDocx $OutputPath
$pageCount = Get-WordPageCount -DocxPath $OutputPath

if ($pageCount -ne $pdfPageCount) {
    Write-Warning "[docx] converted DOCX page count ($pageCount) does not match PDF page count ($pdfPageCount)"

    Convert-PdfToDocxWithPageImages -SourcePdf $PdfPath -TargetDocx $OutputPath
    $backend = "pdf-page-images"
    $pageCount = Get-WordPageCount -DocxPath $OutputPath

    if ($pageCount -eq $pdfPageCount) {
        Write-Step "[docx] image-based DOCX matches PDF page count"
    }
}

if ($pageCount -ne $pdfPageCount) {
    Write-Warning "[docx] image-based DOCX page count ($pageCount) does not match PDF page count ($pdfPageCount)"

    if (-not [string]::IsNullOrWhiteSpace($ReferenceDocxPath) -and (Test-Path -LiteralPath $ReferenceDocxPath -PathType Leaf)) {
        $referencePageCount = Get-WordPageCount -DocxPath $ReferenceDocxPath
        if ($referencePageCount -eq $pdfPageCount) {
            Write-Step "[docx] use provided high-fidelity PDF-converted DOCX: $ReferenceDocxPath"
            if ([System.IO.Path]::GetFullPath($ReferenceDocxPath) -ne [System.IO.Path]::GetFullPath($OutputPath)) {
                Copy-Item -LiteralPath $ReferenceDocxPath -Destination $OutputPath -Force
            }
            $backend = "provided-pdf-converted-docx"
            $pageCount = $referencePageCount
        }
        else {
            throw "Converted DOCX has $pageCount pages and reference DOCX has $referencePageCount pages; both differ from PDF page count $pdfPageCount."
        }
    }
    else {
        throw "Converted DOCX has $pageCount pages, but PDF has $pdfPageCount pages. Provide a high-fidelity converted DOCX with -ReferenceDocxPath or install a better PDF-to-DOCX converter."
    }
}

Write-Step "[docx] output: $OutputPath"
Write-Step "[docx] backend: $backend"
Write-Step "[docx] Word page count after conversion: $pageCount"

if ($OpenAfterBuild) {
    Invoke-Item -LiteralPath $OutputPath
}
