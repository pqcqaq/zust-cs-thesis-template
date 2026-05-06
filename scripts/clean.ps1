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
    "main.synctex.gz",
    "main-body.aux",
    "main-body.fdb_latexmk",
    "main-body.fls",
    "main-body.log",
    "main-body.out",
    "main-body.toc",
    "main-body.xdv",
    "main-body.synctex.gz"
)

foreach ($file in $temporaryFiles) {
    $path = Join-Path $ProjectRoot $file
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Remove-Item -LiteralPath $path -Force
    }
}

Write-Host "Cleaned LaTeX temporary files. main.pdf, main-body.pdf and generated figures were preserved."
