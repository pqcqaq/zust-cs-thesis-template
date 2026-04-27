$pdf_mode = 5;
if ($^O =~ /MSWin32|cygwin|msys/i) {
    $xelatex = 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-xelatex.ps1 %O %S';
}
else {
    $xelatex = 'bash scripts/run-xelatex.sh %O %S';
}
$max_repeat = 5;
