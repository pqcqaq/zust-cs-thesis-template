# Frontmatter

本目录保存论文前置固定页。

- `cover.docx`：毕业设计论文封面占位源文件。
- `authorization.docx`：学位论文出版授权书占位源文件。
- `copyright.docx`：毕业设计（论文）、学位论文版权使用授权书占位源文件。
- `*.pdf`：由构建脚本从 Word 源文件导出的中间产物，不纳入 Git 跟踪。

实际使用时，建议把学校官方 Word 模板复制到本目录，并保持 `frontmatter.json` 中的文件名一致。运行 `.\scripts\build.ps1` 后，构建脚本会自动导出 PDF 并合并进最终论文。
