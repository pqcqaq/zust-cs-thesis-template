param(
    [string]$OutputPath,
    [switch]$SkipMermaid,
    [switch]$ForceMermaid,
    [switch]$NoFrontmatter,
    [switch]$KeepTemp
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host $Message
}

function Test-IsWindows {
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        return $true
    }
    return [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows
    )
}

function Get-Tool {
    param(
        [string[]]$Names,
        [string]$InstallHint
    )

    foreach ($name in $Names) {
        $tool = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $tool) {
            return $tool
        }
    }

    throw "$($Names -join '/') not found. $InstallHint"
}

function Resolve-ProjectPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $Path))
}

function Get-DefaultDocxOutput {
    $mainPath = Join-Path $ProjectRoot "main.tex"
    $content = Get-Content -LiteralPath $mainPath -Raw -Encoding UTF8
    $start = $content.IndexOf("\makethesiscover", [System.StringComparison]::Ordinal)
    $title = "毕业设计论文"
    if ($start -ge 0) {
        $tail = $content.Substring($start)
        $match = [regex]::Match($tail, "\\makethesiscover\s*\{(?<title>[^}]+)\}")
        if ($match.Success) {
            $candidate = ($match.Groups["title"].Value -replace "\\allowbreak\{\}", "" -replace "\\_", "_").Trim()
            if ($candidate -and $candidate -notmatch "请.*填写|毕业设计.*题目") {
                $title = $candidate
            }
        }
    }
    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    foreach ($char in $invalid) {
        $title = $title.Replace([string]$char, "_")
    }
    return Join-Path $ProjectRoot (Join-Path "dist" "$title.docx")
}

function Merge-FrontmatterWithBody {
    param(
        [string]$BodyDocxPath,
        [string]$OutputDocxPath
    )

    if ($NoFrontmatter) {
        Copy-Item -LiteralPath $BodyDocxPath -Destination $OutputDocxPath -Force
        Write-Step "[docx] frontmatter merge disabled; wrote body DOCX"
        return $false
    }

    if (-not (Test-IsWindows)) {
        Copy-Item -LiteralPath $BodyDocxPath -Destination $OutputDocxPath -Force
        Write-Warning "[docx] Microsoft Word COM is only available on Windows; wrote body DOCX without fixed frontmatter"
        return $false
    }

    $frontmatterFiles = @(
        (Join-Path $ProjectRoot "frontmatter\cover.docx"),
        (Join-Path $ProjectRoot "frontmatter\authorization.doc"),
        (Join-Path $ProjectRoot "frontmatter\copyright.doc")
    )
    foreach ($file in $frontmatterFiles) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
            Copy-Item -LiteralPath $BodyDocxPath -Destination $OutputDocxPath -Force
            Write-Warning "[docx] missing frontmatter source: $file; wrote body DOCX without fixed frontmatter"
            return $false
        }
    }

    $word = $null
    $doc = $null
    try {
        try {
            $word = New-Object -ComObject Word.Application
        }
        catch {
            Copy-Item -LiteralPath $BodyDocxPath -Destination $OutputDocxPath -Force
            Write-Warning "[docx] Microsoft Word is not available; wrote body DOCX without fixed frontmatter"
            return $false
        }

        $word.Visible = $false
        $word.DisplayAlerts = 0

        $doc = $word.Documents.Open($frontmatterFiles[0], $false, $false)

        foreach ($file in @($frontmatterFiles[1], $frontmatterFiles[2], $BodyDocxPath)) {
            $range = $doc.Range()
            $range.Collapse(0) | Out-Null
            $range.InsertBreak(7) | Out-Null
            $range = $doc.Range()
            $range.Collapse(0) | Out-Null
            $range.InsertFile($file) | Out-Null
        }

        if (Test-Path -LiteralPath $OutputDocxPath -PathType Leaf) {
            Remove-Item -LiteralPath $OutputDocxPath -Force
        }
        $doc.SaveAs2($OutputDocxPath, 16)
        Write-Step "[docx] merged fixed frontmatter with body DOCX"
        return $true
    }
    finally {
        if ($null -ne $doc) {
            $doc.Close($false) | Out-Null
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
        }
        if ($null -ne $word) {
            $word.Quit() | Out-Null
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
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

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$node = Get-Tool -Names @("node.exe", "node") -InstallHint "Install Node.js, then retry."
$bodyDocx = Join-Path ([System.IO.Path]::GetTempPath()) ("zust-thesis-body-" + [System.Guid]::NewGuid().ToString("N") + ".docx")

try {
    $nodeArgs = @(
        (Join-Path $PSScriptRoot "build-docx.mjs"),
        "--output",
        $bodyDocx
    )
    if ($SkipMermaid) {
        $nodeArgs += "--skip-mermaid"
    }
    if ($ForceMermaid) {
        $nodeArgs += "--force-mermaid"
    }
    if ($KeepTemp) {
        $nodeArgs += "--keep-temp"
    }

    & $node.Source @nodeArgs
    if ($LASTEXITCODE -ne 0) {
        throw "DOCX body build failed"
    }

    Merge-FrontmatterWithBody -BodyDocxPath $bodyDocx -OutputDocxPath $OutputPath | Out-Null
    Write-Step "[docx] output: $OutputPath"
}
finally {
    if (Test-Path -LiteralPath $bodyDocx -PathType Leaf) {
        Remove-Item -LiteralPath $bodyDocx -Force
    }
}
