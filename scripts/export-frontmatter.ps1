param(
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$WordExportFormatPDF = 17

function Write-Step {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message
    }
}

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$FrontmatterDir = (Resolve-Path (Join-Path $ProjectRoot "frontmatter")).Path
$ManifestPath = Join-Path $FrontmatterDir "frontmatter.json"

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Frontmatter manifest not found: $ManifestPath"
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$pages = @($manifest.pages)
if ($pages.Count -eq 0) {
    throw "No frontmatter pages configured in $ManifestPath"
}

$word = $null
try {
    foreach ($page in $pages) {
        $sourcePath = [System.IO.Path]::GetFullPath((Join-Path $FrontmatterDir $page.source))
        $targetPath = [System.IO.Path]::GetFullPath((Join-Path $FrontmatterDir $page.target))

        if (-not $sourcePath.StartsWith($FrontmatterDir, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Unsafe frontmatter source path: $sourcePath"
        }
        if (-not $targetPath.StartsWith($FrontmatterDir, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Unsafe frontmatter target path: $targetPath"
        }
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "Frontmatter source not found: $sourcePath"
        }

        $sourceItem = Get-Item -LiteralPath $sourcePath
        $targetItem = Get-Item -LiteralPath $targetPath -ErrorAction SilentlyContinue
        if (-not $Force -and $targetItem -and $targetItem.LastWriteTimeUtc -ge $sourceItem.LastWriteTimeUtc) {
            Write-Step "[frontmatter] up to date: $($targetItem.Name)"
            continue
        }

        if ($null -eq $word) {
            $word = New-Object -ComObject Word.Application
            $word.Visible = $false
            $word.DisplayAlerts = 0
        }

        $targetDir = Split-Path -Parent $targetPath
        if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
        }

        $targetBase = [System.IO.Path]::GetFileNameWithoutExtension($targetPath)
        $tempPath = Join-Path $targetDir ".$targetBase.tmp.pdf"
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Force
        }

        Write-Step "[frontmatter] export: $($sourceItem.Name) -> $([System.IO.Path]::GetFileName($targetPath))"
        $doc = $null
        try {
            $doc = $word.Documents.Open($sourcePath, $false, $true)
            $doc.ExportAsFixedFormat($tempPath, $WordExportFormatPDF)
        }
        finally {
            if ($null -ne $doc) {
                $doc.Close($false) | Out-Null
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
            }
        }

        Move-Item -LiteralPath $tempPath -Destination $targetPath -Force
    }
}
finally {
    if ($null -ne $word) {
        $word.Quit() | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}
