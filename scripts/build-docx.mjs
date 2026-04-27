#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDir, "..");

const options = {
  outputPath: "",
  skipMermaid: false,
  forceMermaid: false,
  keepTemp: false,
};

function usage() {
  console.log(`Usage: node scripts/build-docx.mjs [options]

Options:
  --output <path>      Output DOCX path. Default: dist/<thesis-title>.docx
  --skip-mermaid      Skip Mermaid PNG rendering.
  --force-mermaid     Re-render Mermaid PNG files.
  --keep-temp         Keep temporary Pandoc input directory.
  -h, --help          Show this help.`);
}

for (let index = 2; index < process.argv.length; index += 1) {
  const arg = process.argv[index];
  if (arg === "--output" || arg === "-o") {
    index += 1;
    if (index >= process.argv.length) {
      throw new Error("--output requires a path");
    }
    options.outputPath = process.argv[index];
  } else if (arg === "--skip-mermaid") {
    options.skipMermaid = true;
  } else if (arg === "--force-mermaid") {
    options.forceMermaid = true;
  } else if (arg === "--keep-temp") {
    options.keepTemp = true;
  } else if (arg === "-h" || arg === "--help") {
    usage();
    process.exit(0);
  } else {
    throw new Error(`Unknown option: ${arg}`);
  }
}

function writeStep(message) {
  console.log(message);
}

function quoteShellArg(value) {
  if (process.platform === "win32") {
    return `"${String(value).replace(/"/g, '\\"')}"`;
  }
  return `'${String(value).replace(/'/g, "'\\''")}'`;
}

function needsShell(command) {
  return process.platform === "win32" && /\.(cmd|bat)$/i.test(command);
}

function run(command, args, opts = {}) {
  const result = needsShell(command)
    ? spawnSync([command, ...args.map(quoteShellArg)].join(" "), {
      cwd: opts.cwd ?? projectRoot,
      stdio: opts.stdio ?? "inherit",
      shell: true,
    })
    : spawnSync(command, args, {
      cwd: opts.cwd ?? projectRoot,
      stdio: opts.stdio ?? "inherit",
      shell: false,
    });
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed with exit code ${result.status}`);
  }
  return result;
}

function commandName(name) {
  if (process.platform === "win32") {
    return `${name}.cmd`;
  }
  return name;
}

function testCommand(command, args = ["--version"]) {
  const result = needsShell(command)
    ? spawnSync([command, ...args.map(quoteShellArg)].join(" "), {
      cwd: projectRoot,
      stdio: "ignore",
      shell: true,
    })
    : spawnSync(command, args, {
      cwd: projectRoot,
      stdio: "ignore",
      shell: false,
    });
  return !result.error && result.status === 0;
}

function ensureCommand(command, installHint) {
  if (!testCommand(command)) {
    throw new Error(`${command} not found. ${installHint}`);
  }
}

function readUtf8(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function writeUtf8(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content, "utf8");
}

function normalizeLatexText(value) {
  return value
    .replace(/\\allowbreak\{\}/g, "")
    .replace(/\\allowbreak/g, "")
    .replace(/\\_/g, "_")
    .trim();
}

function parseBraceArguments(source, commandNameText) {
  const commandIndex = source.indexOf(`\\${commandNameText}`);
  if (commandIndex < 0) {
    return [];
  }
  const args = [];
  let index = commandIndex + commandNameText.length + 1;
  while (index < source.length && args.length < 16) {
    while (index < source.length && /\s/.test(source[index])) {
      index += 1;
    }
    if (source[index] !== "{") {
      break;
    }
    index += 1;
    let depth = 1;
    let value = "";
    while (index < source.length && depth > 0) {
      const ch = source[index];
      const previous = source[index - 1];
      if (ch === "{" && previous !== "\\") {
        depth += 1;
        value += ch;
      } else if (ch === "}" && previous !== "\\") {
        depth -= 1;
        if (depth > 0) {
          value += ch;
        }
      } else {
        value += ch;
      }
      index += 1;
    }
    args.push(normalizeLatexText(value));
  }
  return args;
}

function isPlaceholderTitle(title) {
  return !title || /请.*填写|毕业设计.*题目/.test(title);
}

function safeFileName(value) {
  const safe = value.replace(/[<>:"/\\|?*\x00-\x1F]/g, "_").trim();
  return safe || "毕业设计论文";
}

function getMetadata() {
  const mainPath = path.join(projectRoot, "main.tex");
  const mainContent = readUtf8(mainPath);
  const fields = parseBraceArguments(mainContent, "makethesiscover");
  const title = fields[0] || "请在此填写毕业设计（论文）题目";
  const author = fields[5] || "请填写学生姓名";
  const date = fields[8] || "请填写完成日期";
  const outputBase = isPlaceholderTitle(title) ? "毕业设计论文" : title;
  return {
    title,
    author,
    date,
    outputName: `${safeFileName(outputBase)}.docx`,
  };
}

function needsRender(sourcePath, targetPath, relatedFiles) {
  if (options.forceMermaid || !fs.existsSync(targetPath)) {
    return true;
  }
  const targetTime = fs.statSync(targetPath).mtimeMs;
  if (fs.statSync(sourcePath).mtimeMs > targetTime) {
    return true;
  }
  return relatedFiles.some((filePath) => fs.existsSync(filePath) && fs.statSync(filePath).mtimeMs > targetTime);
}

function renderMermaidPng() {
  if (options.skipMermaid) {
    writeStep("[docx] skip Mermaid PNG rendering");
    return;
  }

  const mermaidDir = path.join(projectRoot, "figures", "mermaid");
  const outputDir = path.join(projectRoot, "figures", "generated");
  const puppeteerConfig = path.join(projectRoot, "puppeteer-config.json");
  const mermaidConfig = path.join(projectRoot, "mermaid-config.json");

  if (!fs.existsSync(mermaidDir)) {
    writeStep("[docx] no Mermaid source directory");
    return;
  }

  const sources = fs.readdirSync(mermaidDir)
    .filter((name) => name.endsWith(".mmd"))
    .sort()
    .map((name) => path.join(mermaidDir, name));

  if (sources.length === 0) {
    writeStep("[docx] no Mermaid diagrams");
    return;
  }

  const npxCommand = commandName("npx");
  ensureCommand(npxCommand, "Install Node.js/npx, then retry.");
  fs.mkdirSync(outputDir, { recursive: true });

  for (const source of sources) {
    const baseName = path.basename(source, ".mmd");
    const target = path.join(outputDir, `${baseName}.png`);
    if (!needsRender(source, target, [puppeteerConfig, mermaidConfig])) {
      continue;
    }
    writeStep(`[docx] render Mermaid PNG: ${path.basename(source)} -> ${path.basename(target)}`);
    run(npxCommand, [
      "--yes",
      "@mermaid-js/mermaid-cli",
      "-i",
      source,
      "-o",
      target,
      "-p",
      puppeteerConfig,
      "-c",
      mermaidConfig,
      "--backgroundColor",
      "white",
    ]);
  }
}

function getCitationMap() {
  const referencesPath = path.join(projectRoot, "chapters", "references.tex");
  const content = readUtf8(referencesPath);
  const map = new Map();
  let index = 1;
  for (const match of content.matchAll(/\\bibitem\{([^}]+)\}/g)) {
    map.set(match[1], index);
    index += 1;
  }
  return map;
}

function convertCitations(content, citationMap) {
  return content.replace(/\\cite\{([^}]+)\}/g, (_match, keyText) => {
    const numbers = keyText
      .split(",")
      .map((key) => key.trim())
      .filter(Boolean)
      .map((key) => citationMap.get(key) ?? key);
    return numbers.length > 0 ? `\\textsuperscript{[${numbers.join(",")}]}` : "";
  });
}

function convertGeneralLatex(content) {
  return content
    .replace(/\\allowbreak\{\}/g, "")
    .replace(/\\allowbreak/g, "")
    .replace(/\\zihao\{[^}]+\}/g, "")
    .replace(/\\phantomsection/g, "")
    .replace(/\\addcontentsline\{[^}]+\}\{[^}]+\}\{[^}]+\}/g, "")
    .replace(/\\clearpage/g, "");
}

function toProjectPath(relativePath) {
  return path.join(projectRoot, ...relativePath.split("/"));
}

function convertGeneratedFigureFallbacks(content) {
  const lines = content.split(/\r?\n/);
  const output = [];
  let skipFallback = false;

  for (const line of lines) {
    const match = line.match(/^\\IfFileExists\{(?<pdf>figures\/generated\/[^}]+\.pdf)\}\{\\includegraphics\[[^\]]+\]\{[^}]+\.pdf\}\}\{%?\s*$/);
    if (!skipFallback && match?.groups?.pdf) {
      const pdfPath = match.groups.pdf;
      const pngPath = pdfPath.replace(/\.pdf$/, ".png");
      if (fs.existsSync(toProjectPath(pngPath))) {
        output.push(`\\includegraphics[width=0.92\\textwidth]{${pngPath}}`);
      } else if (fs.existsSync(toProjectPath(pdfPath))) {
        output.push(`\\includegraphics[width=0.92\\textwidth]{${pdfPath}}`);
      } else {
        output.push(`\\emph{图形占位：${pngPath}}`);
      }
      skipFallback = true;
      continue;
    }

    if (skipFallback) {
      if (/^\\end\{minipage\}\}\s*$/.test(line)) {
        skipFallback = false;
      }
      continue;
    }

    output.push(line);
  }

  return output.join("\n");
}

function convertScreenshotMacros(content) {
  return content.replace(
    /\\renderscreenshot\{([^}]+)\}\{([^}]+)\}\{([^}]+)\}\{([^}]+)\}/g,
    (_match, label, fileName, caption, source) => {
      const relativePath = `figures/screenshots/${fileName}`;
      if (fs.existsSync(toProjectPath(relativePath))) {
        return `\\includegraphics[width=0.92\\textwidth]{${relativePath}}\n\\caption{${caption}}\\label{fig:${label}}`;
      }
      return `\\emph{截图占位：${caption}（文件：${relativePath}；参考页面：\\texttt{${source}}）}\n\\caption{${caption}}\\label{fig:${label}}`;
    },
  );
}

function convertReferencesChapter(sourcePath) {
  const content = readUtf8(sourcePath);
  const lines = ["\\chapter*{参考文献}", "\\begin{enumerate}"];
  const itemPattern = /\\bibitem\{[^}]+\}\s*(.*?)(?=\\bibitem\{|\\end\{thebibliography\})/gs;
  for (const match of content.matchAll(itemPattern)) {
    const text = convertGeneralLatex(match[1].trim().replace(/\r?\n\s*/g, " "));
    if (text) {
      lines.push(`\\item ${text}`);
    }
  }
  lines.push("\\end{enumerate}");
  return lines.join("\n");
}

function convertChapterForDocx(sourcePath, citationMap) {
  if (path.basename(sourcePath) === "references.tex") {
    return convertReferencesChapter(sourcePath);
  }
  let content = readUtf8(sourcePath);
  content = convertGeneralLatex(content);
  content = convertCitations(content, citationMap);
  content = convertGeneratedFigureFallbacks(content);
  content = convertScreenshotMacros(content);
  return content;
}

function createPandocSource(tempRoot, metadata, citationMap) {
  const tempChapters = path.join(tempRoot, "chapters");
  fs.mkdirSync(tempChapters, { recursive: true });

  for (const fileName of [
    "abstract-cn.tex",
    "abstract-en.tex",
    "body.tex",
    "acknowledgements.tex",
    "references.tex",
  ]) {
    const sourcePath = path.join(projectRoot, "chapters", fileName);
    const targetPath = path.join(tempChapters, fileName);
    writeUtf8(targetPath, convertChapterForDocx(sourcePath, citationMap));
  }

  const mainContent = String.raw`\documentclass{ctexbook}
\usepackage{graphicx}
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{tabularx}
\usepackage{array}
\usepackage{float}
\usepackage{listings}
\usepackage{hyperref}
\newcommand{\abstractparagraph}[1]{#1}
\newcommand{\enabstractparagraph}[1]{#1}
\newcommand{\keywords}[1]{\textbf{关键词：}#1}
\newcommand{\enkeywords}[1]{\textbf{Keywords: }#1}
\title{${metadata.title}}
\author{${metadata.author}}
\date{${metadata.date}}
\begin{document}
\chapter*{摘要}
\input{chapters/abstract-cn}
\chapter*{ABSTRACT}
\input{chapters/abstract-en}
\input{chapters/body}
\input{chapters/acknowledgements}
\input{chapters/references}
\end{document}
`;

  const mainPath = path.join(tempRoot, "main-docx.tex");
  writeUtf8(mainPath, mainContent);
  return mainPath;
}

function resolveOutputPath(metadata) {
  if (options.outputPath) {
    return path.isAbsolute(options.outputPath)
      ? options.outputPath
      : path.resolve(projectRoot, options.outputPath);
  }
  return path.join(projectRoot, "dist", metadata.outputName);
}

function buildDocx() {
  const metadata = getMetadata();
  const outputPath = resolveOutputPath(metadata);
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });

  ensureCommand(process.platform === "win32" ? "pandoc.exe" : "pandoc", "Install Pandoc, then retry.");
  renderMermaidPng();

  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "zust-thesis-docx-"));
  try {
    const citationMap = getCitationMap();
    createPandocSource(tempRoot, metadata, citationMap);
    const resourcePath = [tempRoot, projectRoot].join(path.delimiter);
    writeStep("[docx] run pandoc");
    run(process.platform === "win32" ? "pandoc.exe" : "pandoc", [
      "main-docx.tex",
      "-f",
      "latex",
      "-o",
      outputPath,
      "--standalone",
      "--toc",
      "--toc-depth=2",
      "--number-sections",
      `--resource-path=${resourcePath}`,
      "--metadata",
      `title=${metadata.title}`,
    ], { cwd: tempRoot });
    writeStep(`[docx] output: ${outputPath}`);
  } finally {
    if (options.keepTemp) {
      writeStep(`[docx] keep temp directory: ${tempRoot}`);
    } else {
      fs.rmSync(tempRoot, { recursive: true, force: true });
    }
  }
}

try {
  buildDocx();
} catch (error) {
  console.error(`[docx] ${error.message}`);
  process.exit(1);
}
