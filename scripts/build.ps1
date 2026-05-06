param(
    [switch]$SkipFrontmatter,
    [switch]$SkipMermaid,
    [switch]$ForceFrontmatter,
    [switch]$ForceMermaid
)

$ErrorActionPreference = "Stop"

function Add-MiKTeXToPath {
    $miktexBin = Join-Path $env:USERPROFILE "scoop\apps\miktex\current\texmfs\install\miktex\bin\x64"
    if ((Test-Path -LiteralPath $miktexBin -PathType Container) -and -not ($env:PATH.Split(";") -contains $miktexBin)) {
        $env:PATH = "$miktexBin;$env:PATH"
    }
}

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot
Add-MiKTeXToPath

if (-not $SkipFrontmatter) {
    $frontmatterArgs = @()
    if ($ForceFrontmatter) {
        $frontmatterArgs += "-Force"
    }
    & (Join-Path $PSScriptRoot "export-frontmatter.ps1") @frontmatterArgs
}

if (-not $SkipMermaid) {
    $mermaidArgs = @("-AllowFallback")
    if ($ForceMermaid) {
        $mermaidArgs += "-Force"
    }
    & (Join-Path $PSScriptRoot "render-mermaid.ps1") @mermaidArgs
}

$latexmk = Get-Command latexmk -ErrorAction SilentlyContinue
if ($null -eq $latexmk) {
    throw "latexmk not found. Install latexmk, then retry."
}

$oldSkip = $env:ZUST_SKIP_LATEX_PREPARE
$env:ZUST_SKIP_LATEX_PREPARE = "1"
try {
    & $latexmk.Source -xelatex -interaction=nonstopmode -file-line-error main.tex
    exit $LASTEXITCODE
}
finally {
    if ($null -eq $oldSkip) {
        Remove-Item Env:\ZUST_SKIP_LATEX_PREPARE -ErrorAction SilentlyContinue
    }
    else {
        $env:ZUST_SKIP_LATEX_PREPARE = $oldSkip
    }
}
