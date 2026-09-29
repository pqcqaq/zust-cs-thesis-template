# AGENTS.md

本仓库是浙江科技大学计算机科学与技术学院本科毕业设计（论文）LaTeX 模板。AI 修改论文时，应以仓库中的 `zustcs-thesis.cls`、`main.tex`、构建脚本和学校固定页为准，不要凭通用 LaTeX 模板猜测格式。

## 任务边界与事实规则

- `chapters/` 中的当前内容是完整演示论文，主题、身份、数据、测试结果和截图均为示例。使用模板写真实论文时，必须替换所有演示内容。
- 先阅读 `README.md`、`main.tex`、`zustcs-thesis.cls`、`chapters/body.tex` 和相关章节，再开始写作或改格式。
- 项目源码、任务书、开题报告和用户明确提供的事实优先于 README 中的旧说明；无法核验的功能、性能指标、测试结果、用户数量和参考文献不得编造。
- 保留 LaTeX 命令、引用键、图表标签和文件路径的稳定性。修改章节标题后，要同步检查目录、正文引用和图表编号。
- 正文语言应具体描述问题、设计、实现和验证，避免连续使用空泛结论或模板化套话。摘要只说明背景、工作、方法和结果，不写“第几章介绍了什么”。

## 文件组织

- `main.tex`：完整论文入口，包含封面、装订空白页、固定页、中文摘要、英文摘要、目录、正文、致谢和参考文献。
- `main-body.tex`：只编译正文，用于快速检查章节、图表和引用，不包含摘要、目录、致谢和参考文献列表。
- `chapters/abstract-cn.tex`、`chapters/abstract-en.tex`：中英文摘要。
- `chapters/body.tex`：正文章节入口；实际章节放在 `chapters/body/`，通常按 `01-` 到 `06-` 排列。
- `chapters/acknowledgements.tex`、`chapters/references.tex`：致谢和参考文献。
- `figures/mermaid/`：Mermaid 源码；`figures/generated/`：构建生成的 PDF 图；`figures/screenshots/`：真实软件截图。
- `frontmatter/`：学校封面、授权书和版权页的 Word 源文件及清单。正式提交时优先使用 Word 导出的固定页。

## 论文结构

默认正文结构如下，可按课题调整，但第 4 章通常应是全文最详细的章节：

1. 绪论：研究背景、意义、相关工作、研究内容和论文结构。
2. 需求分析：业务场景、角色、功能需求、非功能需求和可行性。
3. 系统总体设计：架构、模块、数据模型、接口和关键流程。
4. 系统详细设计与实现：每个核心模块的用途、流程、关键实现、图或截图和必要代码。
5. 系统测试与结果分析：环境、测试用例、结果、问题和限制。
6. 总结与展望：已完成工作、结论、局限和后续计划。

第 4 章的每个主要模块至少应有实现说明；如果确有页面，应配对应截图；如果有关键算法、状态转换或接口逻辑，可放短代码片段。大段源码放附件或项目源码，不要堆入正文。

## 格式要求

模板当前 `zustcs-thesis.cls` 的主要格式是：

- A4 纸；上 3 cm、下 2.5 cm、左 3.5 cm、右 2.5 cm。
- 中文正文小四号宋体，行距约 1.53 倍；英文优先使用 Times New Roman，缺失时自动回退到 TeX Gyre Termes 或 Latin Modern Roman。
- 中文字体按宋体、Songti SC、Noto Serif CJK SC、FandolSong 回退；黑体和仿宋也有对应回退链。
- 章标题小二号黑体居中；节标题小三号黑体；小节标题四号黑体；四级标题使用行内标题形式。
- 正文首行缩进 2 个汉字，段前段后不额外留空。
- 页眉五号宋体；文前使用罗马数字，正文使用阿拉伯数字；各章另起页。
- 图、表按章编号，例如 `图 3-1`、`表 3-1`。图题在图下，表题按当前类文件设置在表下。
- 引用使用 `\cite{key}`，输出为正文中的上标数字形式；参考文献统一维护在 `chapters/references.tex`。
- 代码使用 `lstlisting` 和 `thesiscode` 样式；不要把含大量特殊字符的代码直接放进普通正文。

不要为了某一页的局部效果直接修改 `zustcs-thesis.cls`。先确认是论文内容、浮动体位置、字体缺失还是构建缓存导致的问题；确需改类文件时，应说明对全局版式的影响并重新编译完整论文。

## Mermaid 图

1. 在 `figures/mermaid/` 新建 `.mmd` 文件，文件名使用稳定、可读的编号，例如 `fig-3-1.mmd`、`fig-3-2.mmd`。
2. 使用 Mermaid 描述架构、流程、时序或实体关系；节点文字尽量简短，避免一张图塞入过多实现细节。
3. 在正文中使用：

```tex
\begin{figure}[H]
\centering
\rendermermaid{fig-3-1}{0.50\textheight}
\caption{系统总体架构}
\label{fig:3-1}
\end{figure}
```

4. `\rendermermaid{fig-3-1}{...}` 中只写文件基名，不写 `.mmd` 或 `.pdf`；图源码和生成文件必须同名。
5. 运行 `.\scripts\build.ps1 -ForceMermaid` 或 `./scripts/build.sh --force-mermaid` 生成 `figures/generated/*.pdf`。构建脚本会自动寻找常见 Chrome、Edge 或 Chromium；也可设置 `PUPPETEER_EXECUTABLE_PATH`。
6. 如果浏览器暂时不可用，LaTeX 会回退显示 Mermaid 源码，便于继续写作。正式交付前必须安装浏览器并确认 PDF 中显示真实图形。
7. 图必须在正文中被解释和引用，例如“如图~`\ref{fig:3-1}` 所示……”，不能只放图不说明。

## 图片和截图

普通图片使用 `graphicx`，路径统一使用 `/`：

```tex
\begin{figure}[H]
\centering
\includegraphics[width=0.85\textwidth]{figures/screenshots/example.png}
\caption{设备列表页面}
\label{fig:4-1}
\end{figure}
```

页面截图优先使用模板提供的占位命令：

```tex
\begin{figure}[H]
\centering
\renderscreenshot{4-1}{screenshot-equipment-list.png}{设备列表页面}{equipment-list-page}
\end{figure}
```

图片文件放入 `figures/screenshots/`，文件名必须与命令第二个参数完全一致。图片不存在时会显示占位框；补入同名图片后重新构建即可替换。截图题目要说明具体页面或功能，不要只写“系统界面图”。图片应清晰、裁剪适度、不得包含未经授权的个人信息或密钥。

## 表格和代码

- 字段多的表格使用 `longtable`，控制列宽，避免超出版心；跨页表格要保留表头。
- 表格内容必须在正文中解释，不能只贴数据库字段。
- 代码只保留能说明关键规则的短片段，使用 `language=python`、`language=json` 等明确语言。
- 代码中的真实密码、Token、内网地址和个人信息必须替换为安全占位符。

## 参考文献

参考文献写入 `chapters/references.tex`，正文使用已有 `bibitem` 键引用。AI 不得生成无法核验的作者、题名、期刊、年份、卷期、页码或 DOI。新增文献前应记录来源并检查正文确实引用了它；删除文献时同步检查是否仍存在对应 `\cite`。

## 编译与检查

Windows：

```powershell
.\scripts\build.ps1
.\scripts\build-body.ps1 -SkipMermaid
.\scripts\build.ps1 -SkipFrontmatter -SkipMermaid
```

macOS/Linux：

```bash
./scripts/build.sh
./scripts/build-body.sh --skip-mermaid
```

修改后至少完成一次完整构建。交付前检查：

- `main.pdf` 能打开，目录页码和交叉引用正确；
- 没有残留“请填写”“示例”“截图占位”或演示身份信息；
- Mermaid 图已渲染为真实 PDF，截图已替换；
- 图题、表题、引用和编号连续；
- 第 4 章内容完整且通常为全文最长章节；
- 参考文献真实可查，致谢已替换；
- 固定页、签名页和最终 PDF 页数符合学校要求。

构建产生的 `*.aux`、`*.log`、`figures/generated/*.pdf`、`dist/` 等文件属于可再生产物，遵循仓库 `.gitignore`，不要把临时文件当作论文源文件提交。
