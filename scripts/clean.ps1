param()

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot

$temporaryFiles = @(
    "main.aux",
    "main.fdb_latexmk",
    "main.fls",
    "main.log",
    "main.out",
    "main.toc",
    "main.xdv",
    "main.synctex.gz"
)

foreach ($file in $temporaryFiles) {
    $path = Join-Path $ProjectRoot $file
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Remove-Item -LiteralPath $path -Force
    }
}

Write-Host "Cleaned LaTeX temporary files. main.pdf and generated figures were preserved."
