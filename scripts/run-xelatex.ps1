param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$LatexArgs
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

if ($env:WISH_SKIP_LATEX_PREPARE -ne "1") {
    & (Join-Path $PSScriptRoot "export-frontmatter.ps1")
    & (Join-Path $PSScriptRoot "render-mermaid.ps1") -AllowFallback
}

$xelatex = Get-Command xelatex -ErrorAction SilentlyContinue
if ($null -eq $xelatex) {
    throw "xelatex not found. Install MiKTeX or TeX Live, then retry."
}

& $xelatex.Source @LatexArgs
exit $LASTEXITCODE
