# ZUST 计算机学院本科毕业设计（论文）LaTeX 模板

本模板从实际的 WiSh-LaTeX 毕业论文工程抽象而来，提供学校计算机学院论文的页面样式、固定页合并、Mermaid 图、正文单独编译和 PDF 转 DOCX 工作流。仓库中的论文内容是**虚构的完整演示稿**，主题为“校园实验设备借用管理系统的设计与实现”，仅用于展示结构与写法；身份、数据、测试结论和截图都必须在正式提交前替换或核验。

## 版式基准

- A4；页边距上 3 cm、下 2.5 cm、左 3.5 cm、右 2.5 cm。
- 正文小四号宋体，英文优先 Times New Roman，最小约 22 磅行距；章标题小二黑体居中，节标题小三黑体。
- 页眉五号宋体，文前罗马页码，正文阿拉伯页码；每章另起页。
- 图题在图下，表题按当前实际项目置于表下；图表按章编号。
- 封面和授权页优先嵌入学校 Word 固定页导出的 PDF。无 PDF 时使用类文件的备用页面，备用页不能代替学校签名与审核要求。
- Windows 优先宋体、黑体、仿宋与 Times New Roman；macOS/Linux 按 Songti/Heiti、Noto CJK、Fandol 依次回退。跨平台回退仅保证可编译，正式版式需在目标环境目视检查。

## 文件入口

- `main.tex`：完整论文入口，负责封面、装订空白页、固定页、摘要、目录、正文、致谢和参考文献。
- `main-body.tex`：只编译正文，不含前置页和参考文献列表。
- `zustcs-thesis.cls`：页面尺寸、字体、标题、图表、代码、占位图等样式。
- `chapters/`：完整演示论文，可按章替换。
- `frontmatter/`：学校固定页 Word 源文件和导出清单。
- `figures/mermaid/`：图源码；`figures/generated/`：可再生的渲染结果；`figures/screenshots/`：实际截图。
- `scripts/`：PDF、DOCX、正文版、固定页、Mermaid、清理脚本。

## 环境准备

Windows 推荐 Microsoft Word、MiKTeX/TeX Live、Perl、latexmk、Node.js/npx。macOS/Linux 可用 LibreOffice 导出固定页，并需要 Bash、Python 3、TeX Live/MacTeX。Mermaid 渲染还需要 Chrome/Chromium 或 Puppeteer 的 headless shell。PDF 转 DOCX 需要 Python 的 `pymupdf` 和 `python-docx`；`pdf2docx` 是备用转换方案。最终 PDF 以 XeLaTeX 编译结果为准。

## 构建命令

克隆仓库后，先在模板目录执行一次完整构建：

```bash
git clone https://github.com/pqcqaq/zust-cs-thesis-template.git
cd zust-cs-thesis-template
```

Windows PowerShell：

```powershell
.\scripts\build.ps1
.\scripts\build-body.ps1
.\scripts\build-docx.ps1
.\scripts\clean.ps1
```

macOS/Linux：

```bash
./scripts/build.sh
./scripts/build-body.sh
./scripts/build-docx.sh
./scripts/clean.sh
```

`build.ps1` 默认先导出过期的 Word 固定页、渲染过期的 Mermaid 图，再运行 `latexmk`。已准备好图片或固定页时，可用 `-SkipMermaid`、`-SkipFrontmatter` 跳过；需要强制刷新时使用 `-ForceMermaid`、`-ForceFrontmatter`。Bash 脚本使用对应的 `--skip-mermaid`、`--skip-frontmatter`、`--force-mermaid`、`--force-frontmatter` 参数。直接运行 `latexmk -xelatex main.tex` 也会通过 `.latexmkrc` 调用预处理包装脚本。

常用组合：

```powershell
# 已有固定页和 Mermaid 输出，只检查 LaTeX
.\scripts\build.ps1 -SkipFrontmatter -SkipMermaid

# 修改正文后只查看正文版
.\scripts\build-body.ps1 -SkipMermaid -OutputPath dist\body-review.pdf

# 修改 Word 固定页或 Mermaid 源码后强制刷新
.\scripts\build.ps1 -ForceFrontmatter -ForceMermaid
```

正文版可用 `-SkipMermaid` 复用现有图片，生成 `main-body.pdf`；脚本会从 `chapters/references.tex` 生成正文版引用编号。DOCX 脚本先构建 PDF，再以 PDF 对象转换为可编辑文本框；必要时回退到 Word/Python 转换或整页图片。DOCX 仅供审阅，转换后应核对页数和关键页面。

## 替换演示内容

1. 在 `main.tex` 修改九项封面字段和页眉届次；在 `frontmatter/` 的 Word 文件填写真实身份信息并确认签名页。
2. 修改 `chapters/abstract-cn.tex`、`abstract-en.tex`、`body/*.tex`、`acknowledgements.tex`、`references.tex`。示例论文的系统、测试结果和代码均是演示，不可直接作为个人项目事实。
3. 将 Mermaid 源码放入 `figures/mermaid/`，正文用 `\rendermermaid{文件名}{高度}` 插入。构建脚本会生成同名 PDF；若浏览器缺失，LaTeX 会显示源码作为回退。正式论文应确保图像已渲染。
4. 将真实截图放入 `figures/screenshots/`。`\renderscreenshot{标签}{文件名}{图题}{来源}` 会在图片缺失时显示占位框。
5. 参考文献必须逐条核验真实来源、出版信息和引用关系。演示稿中的书籍条目仅作引用格式示例。

演示稿覆盖摘要、目录、六章正文、Mermaid 图、长表、代码片段、截图占位、引用、致谢和参考文献，适合先完整编译，再逐章替换。

## 构建失败时

- 找不到 `xelatex` 或 `latexmk`：确认 MiKTeX/TeX Live 和 Perl 已加入 `PATH`。
- Mermaid 无法启动浏览器：安装 Chrome、Edge 或 Chromium；Windows 脚本会自动探测常见安装位置，也可以设置 `PUPPETEER_EXECUTABLE_PATH` 指向浏览器可执行文件。暂时缺少浏览器时，构建会保留 Mermaid 源码回退，不会阻止 LaTeX 编译。
- 固定页没有更新：关闭 Word 后执行 `build.ps1 -ForceFrontmatter`。没有 Word 的 macOS/Linux 环境使用 LibreOffice 导出，正式提交前应在 Word 环境复核。
- 中文字体缺失：Windows 使用宋体/黑体/仿宋；Linux 安装 Noto CJK；模板会继续尝试 Fandol 字体作为最后回退。
- DOCX 页数与 PDF 不一致：DOCX 只用于审阅，检查 `build-docx.ps1` 的转换后页数；最终提交以 `main.pdf` 为准。

## 验证记录

2026-09-29 在 Windows + MiKTeX 环境运行 `build.ps1 -SkipFrontmatter`，生成 19 页 `main.pdf`；运行 `build-body.ps1 -SkipMermaid`，生成 9 页 `main-body.pdf`。随后脚本自动检测到本机 Chrome，Mermaid 两图成功渲染；再次构建得到含真实图形的 20 页 `main.pdf`。固定页导出和 DOCX 转换需要在安装 Word/LibreOffice、Python 依赖的环境中另行验证。

