param(
    [string]$OutputPath = "dist\毕业设计论文.md"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("zust-md-sync-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempRoot | Out-Null

function Read-Utf8([string]$Path) {
    [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Read-Utf8Lines([string]$Path) {
    [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom)
}

function Convert-InlineLatex([string]$Text) {
    $s = $Text -replace "\\allowbreak\{\}", ""
    $s = $s.Replace("\_", "_").Replace("\&", "&").Replace("\%", "%")
    $s = $s -replace "\\texttt\{([^{}]+)\}", '`$1`'
    $s = $s -replace "\\textbf\{([^{}]+)\}", '**$1**'
    $s = $s -replace "\\emph\{([^{}]+)\}", '*$1*'
    return $s.Trim()
}

function Expand-LatexInputs([string]$Path) {
    $text = Read-Utf8 $Path
    return [regex]::Replace($text, "\\input\{([^{}]+)\}", {
        param($m)
        $inputPath = $m.Groups[1].Value
        if (-not $inputPath.EndsWith(".tex")) {
            $inputPath = "$inputPath.tex"
        }
        $fullPath = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $inputPath))
        return Expand-LatexInputs $fullPath
    })
}

function Get-ThesisTitle {
    $mainPath = Join-Path $ProjectRoot "main.tex"
    $content = Read-Utf8 $mainPath
    $title = "毕业设计论文"
    $match = [regex]::Match($content, "\\makethesiscover\s*\{(?<title>[^}]+)\}")
    if ($match.Success) {
        $candidate = Convert-InlineLatex $match.Groups["title"].Value
        if ($candidate -and $candidate -notmatch "请.*填写|毕业设计.*题目") {
            $title = $candidate
        }
    }
    return $title
}

function Convert-AbstractFile([string]$Path, [string]$MacroName, [string]$KeywordMacro, [string]$KeywordLabel) {
    $paragraphs = @()
    $keywords = $null
    foreach ($line in Read-Utf8Lines $Path) {
        if ($line.StartsWith("\$MacroName{")) {
            $content = $line.Substring($MacroName.Length + 2)
            if ($content.EndsWith("}")) {
                $content = $content.Substring(0, $content.Length - 1)
            }
            $paragraphs += Convert-InlineLatex $content
        }
        elseif ($line.StartsWith("\$KeywordMacro{")) {
            $content = $line.Substring($KeywordMacro.Length + 2)
            if ($content.EndsWith("}")) {
                $content = $content.Substring(0, $content.Length - 1)
            }
            $keywords = "**$KeywordLabel：** " + (Convert-InlineLatex $content)
        }
    }
    return (($paragraphs + @($keywords)) -join "`n`n")
}

$refMap = @{}
foreach ($line in Read-Utf8Lines (Join-Path $ProjectRoot "chapters\references.tex")) {
    if ($line -match "^\\bibitem\{([^}]+)\}\s+(.+)$") {
        $key = $matches[1]
        $rest = $matches[2]
        $title = $rest
        if ($rest -match "^.+?\.\s+(.+?)\[[A-ZJDC/OL]+\\]") {
            $title = $matches[1]
        }
        $refMap[$key] = Convert-InlineLatex $title
    }
}

$body = Expand-LatexInputs (Join-Path $ProjectRoot "chapters\body.tex")
$body = [regex]::Replace($body, "\\cite\{([^}]+)\}", {
    param($m)
    $keys = $m.Groups[1].Value -split "," | ForEach-Object { $_.Trim() }
    $titles = foreach ($key in $keys) {
        if ($refMap.ContainsKey($key)) { $refMap[$key] } else { $key }
    }
    "\{" + ($titles -join "；") + "\}"
})
$body = [regex]::Replace($body, "\\renderscreenshot\{([^{}]+)\}\{([^{}]+)\}\{([^{}]+)\}\{([^{}]+)\}", {
    param($m)
    $num = $m.Groups[1].Value
    $file = $m.Groups[2].Value
    $caption = Convert-InlineLatex $m.Groups[3].Value
    $source = Convert-InlineLatex $m.Groups[4].Value
    "![图 $num $caption](figures/screenshots/$file)`n`n> 页面或功能来源：$source"
})

$bodyTex = Join-Path $TempRoot "body-cited.tex"
Write-Utf8 $bodyTex $body
$bodyMd = Join-Path $TempRoot "body.md"
& pandoc -f latex -t gfm --wrap=none $bodyTex -o $bodyMd
if ($LASTEXITCODE -ne 0) {
    throw "pandoc body conversion failed"
}

$cnAbstract = Convert-AbstractFile (Join-Path $ProjectRoot "chapters\abstract-cn.tex") "abstractparagraph" "keywords" "关键词"
$enAbstract = Convert-AbstractFile (Join-Path $ProjectRoot "chapters\abstract-en.tex") "enabstractparagraph" "enkeywords" "Keywords"

$refs = @("# 参考文献", "")
foreach ($line in Read-Utf8Lines (Join-Path $ProjectRoot "chapters\references.tex")) {
    if ($line -match "^\\bibitem\{([^}]+)\}\s+(.+)$") {
        $idx = $refs.Count - 1
        $refs += "[$idx] " + (Convert-InlineLatex $matches[2])
    }
}

$ackRaw = Read-Utf8 (Join-Path $ProjectRoot "chapters\acknowledgements.tex")
$ackRaw = $ackRaw -replace "\\addcontentsline\{toc\}\{chapter\}\{致谢\}", ""
$ackRaw = $ackRaw -replace "\\phantomsection", ""
$ackTex = Join-Path $TempRoot "ack.tex"
Write-Utf8 $ackTex $ackRaw
$ackMd = Join-Path $TempRoot "ack.md"
& pandoc -f latex -t gfm --wrap=none $ackTex -o $ackMd
if ($LASTEXITCODE -ne 0) {
    throw "pandoc acknowledgement conversion failed"
}

$resolvedOutput = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $OutputPath))
$outputDir = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$title = Get-ThesisTitle
$final = @(
    "# $title",
    "",
    "> 说明：此文件由 LaTeX 主源同步生成，参考文献已按正文引用同步展开。",
    "",
    "## 摘要",
    "",
    $cnAbstract,
    "",
    "## Abstract",
    "",
    $enAbstract,
    "",
    (Read-Utf8 $bodyMd).Trim(),
    "",
    ($refs -join "`n`n"),
    "",
    (Read-Utf8 $ackMd).Trim()
) -join "`n"

Write-Utf8 $resolvedOutput $final
Write-Host "[sync-md] wrote $resolvedOutput"
Write-Host "[sync-md] temp $TempRoot"
