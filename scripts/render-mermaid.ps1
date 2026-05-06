param(
    [switch]$Force,
    [switch]$Quiet,
    [switch]$AllowFallback
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message
    }
}

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$MermaidDir = Join-Path $ProjectRoot "figures\mermaid"
$OutputDir = Join-Path $ProjectRoot "figures\generated"
$PuppeteerConfig = Join-Path $ProjectRoot "puppeteer-config.json"
$MermaidConfig = Join-Path $ProjectRoot "mermaid-config.json"

if (-not (Test-Path -LiteralPath $MermaidDir -PathType Container)) {
    Write-Step "[mermaid] no source directory"
    exit 0
}
if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$sources = @(Get-ChildItem -LiteralPath $MermaidDir -Filter "*.mmd" | Sort-Object Name)
if ($sources.Count -eq 0) {
    Write-Step "[mermaid] no .mmd files"
    exit 0
}

function Test-NeedsRender {
    param(
        [System.IO.FileInfo]$Source,
        [string]$TargetPath
    )
    if ($Force -or -not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        return $true
    }
    $targetTime = (Get-Item -LiteralPath $TargetPath).LastWriteTimeUtc
    if ($Source.LastWriteTimeUtc -gt $targetTime) {
        return $true
    }
    foreach ($configPath in @($PuppeteerConfig, $MermaidConfig)) {
        if ((Test-Path -LiteralPath $configPath -PathType Leaf) -and (Get-Item -LiteralPath $configPath).LastWriteTimeUtc -gt $targetTime) {
            return $true
        }
    }
    return $false
}

$jobs = @()
foreach ($source in $sources) {
    $targetPath = Join-Path $OutputDir ($source.BaseName + ".pdf")
    if (Test-NeedsRender -Source $source -TargetPath $targetPath) {
        $jobs += [pscustomobject]@{ Source = $source; Target = $targetPath }
    }
}

if ($jobs.Count -eq 0) {
    Write-Step "[mermaid] generated PDFs are up to date"
    exit 0
}

$npx = Get-Command npx.cmd -ErrorAction SilentlyContinue
if ($null -eq $npx) {
    $npx = Get-Command npx -ErrorAction SilentlyContinue
}
if ($null -eq $npx) {
    $message = "npx not found; cannot render Mermaid diagrams"
    if ($AllowFallback) {
        Write-Warning $message
        exit 0
    }
    throw $message
}

$env:PUPPETEER_SKIP_DOWNLOAD = "true"
foreach ($job in $jobs) {
    Write-Step "[mermaid] render: $($job.Source.Name) -> $([System.IO.Path]::GetFileName($job.Target))"
    & $npx.Source --yes "@mermaid-js/mermaid-cli" `
        -i $job.Source.FullName `
        -o $job.Target `
        -p $PuppeteerConfig `
        -c $MermaidConfig `
        --pdfFit `
        --backgroundColor white
    if ($LASTEXITCODE -ne 0) {
        $message = "Mermaid rendering failed: $($job.Source.FullName)"
        if ($AllowFallback) {
            Write-Warning $message
        }
        else {
            throw $message
        }
    }
}
