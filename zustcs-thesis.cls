\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{zustcs-thesis}[2026/04/26 ZUST Computer College thesis class]

\LoadClass[UTF8,zihao=-4,openany]{ctexbook}
\let\cleardoublepage\clearpage

\RequirePackage[a4paper,top=3cm,bottom=2.5cm,left=3.5cm,right=2.5cm,headheight=15pt,headsep=0.8cm,footskip=1.0cm]{geometry}
\RequirePackage{fontspec}
\RequirePackage{setspace}
\RequirePackage{fancyhdr}
\RequirePackage{titlesec}
\RequirePackage{tocloft}
\RequirePackage{caption}
\RequirePackage{booktabs}
\RequirePackage{longtable}
\RequirePackage{tabularx}
\RequirePackage{array}
\RequirePackage{float}
\RequirePackage{graphicx}
\RequirePackage{pdfpages}
\RequirePackage{xcolor}
\RequirePackage{listings}
\RequirePackage{ragged2e}
\RequirePackage{enumitem}
\RequirePackage{needspace}
\RequirePackage{hyperref}
\RequirePackage{etoolbox}

\hypersetup{hidelinks}
\sloppy
\raggedbottom
\setmainfont{Times New Roman}
\setCJKmainfont{SimSun}
\setCJKsansfont{SimHei}
\setCJKmonofont{FangSong}

\newcommand{\thesisHeaderText}{浙江科技大学计算机科学与技术学院2026届本科毕业设计（论文）}
\newcommand{\setthesisheader}[1]{\renewcommand{\thesisHeaderText}{#1}}

\newcommand{\setupthesisfancy}{%
  \fancyhf{}%
  \fancyhead[C]{\zihao{5}\songti \thesisHeaderText}%
  \fancyfoot[C]{\zihao{5}\songti -~\thepage~-}%
  \renewcommand{\headrulewidth}{0.4pt}%
  \renewcommand{\footrulewidth}{0pt}%
}
\setupthesisfancy
\pagestyle{fancy}
\fancypagestyle{plain}{%
  \setupthesisfancy
}
\fancypagestyle{cover}{%
  \fancyhf{}
  \renewcommand{\headrulewidth}{0pt}
}

\AtBeginDocument{\zihao{-4}\songti\setstretch{1.53}}
\setlength{\parindent}{2em}
\setlength{\parskip}{0pt}
\setlength{\LTpre}{0.5\baselineskip}
\setlength{\LTpost}{0.5\baselineskip}
\setlength{\LTleft}{0pt plus 1fill}
\setlength{\LTright}{0pt plus 1fill}
\setlist[enumerate]{label=\arabic*.,leftmargin=2.2em,labelsep=0.6em,itemsep=0.05\baselineskip,topsep=0.15\baselineskip,parsep=0pt,partopsep=0pt}

\ctexset{
  chapter = {
    name = {第,章},
    number = \arabic{chapter},
    format = \centering\heiti\zihao{-2},
    aftername = \quad,
    beforeskip = 0.5\baselineskip,
    afterskip = 1.0\baselineskip,
    pagestyle = fancy
  },
  section = {
    format = \Needspace{7\baselineskip}\heiti\zihao{-3},
    beforeskip = 0.8\baselineskip,
    afterskip = 0.4\baselineskip
  },
  subsection = {
    format = \Needspace{6\baselineskip}\heiti\zihao{4},
    beforeskip = 0.6\baselineskip,
    afterskip = 0.3\baselineskip
  },
  subsubsection = {
    format = \Needspace{5\baselineskip}\heiti\zihao{-4},
    beforeskip = 0.4\baselineskip,
    afterskip = 0.2\baselineskip
  }
}

\renewcommand{\contentsname}{目录}
\setcounter{tocdepth}{2}
\renewcommand{\cftchapfont}{\heiti\zihao{5}}
\renewcommand{\cftsecfont}{\songti\zihao{5}}
\renewcommand{\cftsubsecfont}{\songti\zihao{5}}
\renewcommand{\cftchappagefont}{\fontspec{Times New Roman}\bfseries\zihao{5}}
\renewcommand{\cftsecpagefont}{\fontspec{Times New Roman}\zihao{5}}
\renewcommand{\cftsubsecpagefont}{\fontspec{Times New Roman}\zihao{5}}
\renewcommand{\cftchapleader}{\cftdotfill{\cftdotsep}}
\renewcommand{\cftsecleader}{\cftdotfill{\cftdotsep}}
\renewcommand{\cftsubsecleader}{\cftdotfill{\cftdotsep}}
\renewcommand{\cftdotsep}{1.6}
\cftsetpnumwidth{2.6em}
\cftsetrmarg{3.4em}
\setlength{\cftbeforechapskip}{0.22em}
\setlength{\cftbeforesecskip}{0.02em}
\setlength{\cftbeforesubsecskip}{0em}
% 目录编号本身形成阶梯缩进，避免只移动标题文字。
\cftsetindents{chapter}{0em}{5.3em}
\cftsetindents{section}{0em}{7.2em}
\cftsetindents{subsection}{0em}{9.1em}
\renewcommand{\cftchappresnum}{}
\renewcommand{\cftsecpresnum}{\hspace*{2.0em}}
\renewcommand{\cftsubsecpresnum}{\hspace*{4.0em}}

\renewcommand{\thefigure}{\thechapter-\arabic{figure}}
\renewcommand{\thetable}{\thechapter-\arabic{table}}
\captionsetup[figure]{font={small,bf},labelfont=bf,labelsep=space,position=bottom}
\captionsetup[table]{font={small,bf},labelfont=bf,labelsep=space,position=top}
\renewcommand{\figurename}{图}
\renewcommand{\tablename}{表}

\lstdefinestyle{thesiscode}{
  basicstyle=\ttfamily\small,
  breaklines=true,
  columns=fullflexible,
  keepspaces=true,
  frame=single,
  numbers=left,
  numberstyle=\tiny,
  xleftmargin=2em,
  framexleftmargin=1.5em,
  keywordstyle=\color{blue!60!black},
  commentstyle=\color{green!40!black},
  stringstyle=\color{red!50!black}
}
\lstdefinelanguage{json}{
  morestring=[b]",
  morekeywords={true,false,null},
  sensitive=false
}
\lstdefinestyle{mermaid}{
  basicstyle=\ttfamily\scriptsize,
  breaklines=true,
  columns=fullflexible,
  keepspaces=true,
  frame=single,
  numbers=none,
  xleftmargin=0pt
}

\makeatletter
\renewcommand{\@cite}[2]{\textsuperscript{[#1]}}
\makeatother

\newcommand{\coverfield}[1]{%
  \begin{minipage}[b][1.15cm][b]{10.5cm}%
    \centering\songti\fontsize{16pt}{20pt}\selectfont\bfseries\strut #1\par
    \vskip0.16cm\hrule height 0.4pt%
  \end{minipage}%
}
\newcommand{\covertitlefield}[1]{%
  \begin{minipage}[b][1.78cm][b]{10.5cm}%
    \centering\songti\fontsize{16pt}{22pt}\selectfont\bfseries\strut #1\par
    \vskip0.16cm\hrule height 0.4pt%
  \end{minipage}%
}
\newcommand{\coverlabel}[2]{%
  \begin{minipage}[b][#1][b]{3.0cm}%
    \raggedleft\heiti\fontsize{16pt}{22pt}\selectfont\bfseries #2%
  \end{minipage}%
}
\newcommand{\coverrow}[2]{%
  \noindent\coverlabel{1.15cm}{#1}\hspace{0.75cm}\coverfield{#2}\par\vspace{0.06cm}%
}
\newcommand{\covertitlerow}[2]{%
  \noindent\coverlabel{1.78cm}{#1}\hspace{0.75cm}\covertitlefield{#2}\par\vspace{0.06cm}%
}
\newcommand{\renderscreenshot}[4]{%
  \IfFileExists{figures/screenshots/#2}{%
    \includegraphics[width=0.92\textwidth,height=0.50\textheight,keepaspectratio]{figures/screenshots/#2}%
  }{%
    \fbox{%
      \begin{minipage}[c][0.34\textwidth][c]{0.88\textwidth}
        \centering
        {\heiti\zihao{-4}截图占位\par}
        \vspace{0.5em}
        {\songti\zihao{5}#3\par}
        \vspace{0.35em}
        {\ttfamily\zihao{5}figures/screenshots/#2\par}
        \vspace{0.35em}
        {\songti\zihao{5}参考页面：\texttt{#4}\par}
      \end{minipage}%
    }%
  }%
  \caption{#3}\label{fig:#1}%
}

\newcommand{\makethesiscover}[9]{%
  \clearpage
  \IfFileExists{frontmatter/cover.pdf}{%
    \pagestyle{empty}%
    \includepdf[pages=1,pagecommand={\thispagestyle{empty}},fitpaper=true]{frontmatter/cover.pdf}%
    \setupthesisfancy
    \pagestyle{fancy}%
  }{%
    \begingroup
    \newgeometry{top=2.54cm,bottom=2.54cm,left=3.175cm,right=3.175cm}
    \pagestyle{cover}
    \thispagestyle{cover}
    \begin{center}
      \vspace*{1.05cm}
      {\heiti\fontsize{36pt}{42pt}\selectfont 2026届本科毕业设计\par}
      \vspace{1.25cm}
      \makebox[\textwidth][c]{%
        \begin{minipage}{14.25cm}
          \covertitlerow{题\quad 目}{#1}
          \coverrow{学\quad 院}{#2}
          \coverrow{专\quad 业}{#3}
          \coverrow{班\quad 级}{#4}
          \coverrow{学\quad 号}{#5}
          \coverrow{学生姓名}{#6}
          \coverrow{指导教师}{#7}
          \coverrow{教师职称}{#8}
          \coverrow{完成日期}{#9}
        \end{minipage}%
      }
    \end{center}
    \restoregeometry
    \endgroup
    \setupthesisfancy
    \pagestyle{fancy}%
  }
}

\newcommand{\fronttitle}[1]{%
  \clearpage
  \phantomsection
  \chapter*{#1}
  \thispagestyle{fancy}
  \addcontentsline{toc}{chapter}{#1}
}
\newcommand{\makeauthorizationpage}{%
  \clearpage
  \IfFileExists{frontmatter/authorization.pdf}{%
    \pagestyle{empty}%
    \includepdf[pages=1,pagecommand={\thispagestyle{empty}},fitpaper=true]{frontmatter/authorization.pdf}%
    \setupthesisfancy
    \pagestyle{fancy}%
  }{%
    \pagestyle{cover}
    \thispagestyle{cover}
    \begingroup
    \newgeometry{top=3cm,bottom=2.5cm,left=3.5cm,right=2.5cm}
    \songti\zihao{-4}\setstretch{2.0}
    \begin{center}
      {\heiti\zihao{4} 浙江科技大学学位论文出版授权书\par}
    \end{center}
    \vspace{1.0cm}
    本人已经完全了解浙江科技大学图书馆有关保存、使用学位论文的规定，同意将本人的学位论文提交“浙江科技大学图书馆学位论文全文数据库”全文发布并提供检索，图书馆有权将学位论文的标题和摘要汇编出版。保密论文在解密后适用本规定。同意论文提交后：

    \vspace{0.4cm}
    1. 公开论文：立即；（仅适用于公开论文，请在方框内打勾。）

    2. 保密：□内部；□秘密；□机密；□绝密。（仅适用于保密论文，且须与保密协议保密级别一致，请在相应方框内打勾。）

    \vspace{1.0cm}
    作者签名：\hspace{5.5cm}导师签名：

    \vspace{0.6cm}
    \hspace*{1.4cm}年\hspace{0.8cm}月\hspace{0.8cm}日\hspace{3.0cm}年\hspace{0.8cm}月\hspace{0.8cm}日

    \vfill
    {\zihao{5}\setstretch{1.4}
    注：授权书作者签名和导师签名都需手写签名；授权书应放在论文封面后，顺序为封面、授权书、论文摘要、目录和正文。如公开论文，需在“立即”方框内打勾（√）。\par}
    \restoregeometry
    \endgroup
    \setupthesisfancy
    \pagestyle{fancy}%
  }
}
\newcommand{\makecopyrightpage}{%
  \clearpage
  \IfFileExists{frontmatter/copyright.pdf}{%
    \pagestyle{empty}%
    \includepdf[pages=1,pagecommand={\thispagestyle{empty}},fitpaper=true]{frontmatter/copyright.pdf}%
    \setupthesisfancy
    \pagestyle{fancy}%
  }{}%
}
\makeatletter
\newcommand{\thesistableofcontents}{%
  \clearpage
  \phantomsection
  \thispagestyle{fancy}
  \vspace*{0.3cm}
  \begin{center}{\heiti\zihao{-2}目录\par}\end{center}
  \vspace{0.8cm}
  \begingroup
  \zihao{5}\songti\setstretch{1.02}
  \@starttoc{toc}
  \endgroup
  \clearpage
}
\makeatother
\newcommand{\abstractparagraph}[1]{\par #1\par}
\newcommand{\enabstractparagraph}[1]{\par\fontspec{Times New Roman} #1\par}
\newcommand{\keywords}[1]{\par\noindent{\heiti\zihao{-4}关键词：}{\songti\zihao{-4}#1}\par}
\newcommand{\enkeywords}[1]{\par\noindent{\bfseries Keywords: }#1\par}
