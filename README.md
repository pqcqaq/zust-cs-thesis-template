# ZUST Computer College Thesis LaTeX Template

浙江科技大学计算机学院本科毕业设计（论文）LaTeX 模板。

本仓库由一个已完成论文项目抽取结构后清理而来，只保留通用版式、构建脚本和占位内容，不包含任何学生个人信息、课题内容或真实论文正文。

## 目录结构

- `main.tex`：论文入口。
- `zustcs-thesis.cls`：论文格式类文件。
- `chapters/`：摘要、正文、致谢、参考文献等章节文件。
- `frontmatter/`：封面和授权书 Word 源文件及导出清单。
- `figures/mermaid/`：Mermaid 图源码。
- `figures/generated/`：Mermaid 渲染后的 PDF 输出目录。
- `figures/screenshots/`：系统截图目录。
- `scripts/`：固定页导出、Mermaid 渲染、LaTeX 编译和清理脚本。

## 使用方式

1. 修改 `main.tex` 中的题目、学院、专业、班级、学号、姓名、导师、职称和完成日期。
2. 用学校官方 Word 模板替换 `frontmatter/*.docx`，或直接编辑当前占位文件。
3. 修改 `chapters/*.tex` 中的摘要、正文、致谢和参考文献。
4. 将 Mermaid 图源码放入 `figures/mermaid/`，将软件截图放入 `figures/screenshots/`。
5. 运行构建命令生成最终 PDF。

```powershell
.\scripts\build.ps1
```

也可以直接运行：

```powershell
latexmk -xelatex main.tex
```

`.latexmkrc` 会调用 `scripts/run-xelatex.ps1`，因此直接运行 `latexmk` 时也会先检查固定页 PDF 和 Mermaid 图片。

## 依赖

- Microsoft Word：用于把 `frontmatter/*.docx` 导出为 PDF。
- MiKTeX 或 TeX Live：用于 XeLaTeX 编译。
- Perl 与 latexmk：用于多轮编译。
- Node.js 与 npx：用于 Mermaid 图渲染。

如果暂时无法渲染 Mermaid 图，正文会回退显示 `.mmd` 源码。正式提交前建议确保图已渲染为 PDF。

## 固定页说明

`frontmatter/*.pdf` 是构建产物，不纳入 Git 跟踪。修改 Word 源文件后重新运行 `.\scripts\build.ps1` 即可自动更新。

## 清理

```powershell
.\scripts\clean.ps1
```

该命令只清理 LaTeX 临时文件，不删除 `main.pdf`、Word 源文件或图像资源。
