# 统计计算复习手册（stat-compute-cheatsheet）

> 一份**离线可用、可全文搜索**的统计计算开卷考试速查册。覆盖 R 语言基础、随机变量生成、蒙特卡罗积分、蒙特卡罗推断、Bootstrap / Jackknife、数值优化、MCMC 共 7 章作业，外加 3 份测验、附加题与一份可直接 `source()` 的工具函数库。

---

## ⚠️ 重点提醒

**请勿直接双击 `index.html` 打开**！由于本项目采用 `fetch()` 异步加载 `data/*.json` 章节内容，浏览器在 `file://` 协议下会触发跨域限制（CORS），导致页面一片空白。

**必须使用 VS Code 的 Live Server 插件启动**（详见下方「使用教程」）。

---

## 项目简介

- **目标场景**：统计计算课程的开卷考试，需要在断网环境下快速翻查公式与 R 代码。
- **设计哲学**：内容 = 知识点 + 公式 + 题目 + 标准答案 + 易错点，所有数学符号通过本地打包的 KaTeX 渲染，无需网络。
- **交互特性**：折叠式章节、模糊搜索关键词高亮、打印友好（自动展开全部节）。

## 内容覆盖

| 章节 | 主题 | 题数 |
|------|------|------|
| Ch 1 | R 语言基础与数据操作 | 6 |
| Ch 2 | 随机变量生成 | 6 |
| Ch 3 | 蒙特卡罗积分 | 4 |
| Ch 4 | 蒙特卡罗推断（CI 与假设检验） | 4 |
| Ch 5 | Bootstrap 与 Jackknife | 3 |
| Ch 6 | 数值优化方法 | 3 |
| Ch 7 | MCMC（Metropolis-Hastings） | 3 |
| 补充 1 | 测验 & 附加题 | 4 |
| 补充 2 | 工具函数库（7 类 · 23 函数） | — |

## 主要特性

- 章节、题目两级折叠，点击展开 / 收起
- 顶部搜索框：实时模糊匹配 + 关键词高亮 + 命中计数（自动隐藏未命中题目）
- 数学公式由本地打包的 **KaTeX** 渲染，无需互联网
- 打印模式：自动展开全部内容，隐藏搜索框
- 工具函数库可独立下载（`statcomp_exam_toolkit.R`），考试时直接 `source()`

## 目录结构

```
.
├── index.html                    # 外壳页（加载 JSON 数据后动态渲染）
├── assets/
│   ├── styles.css                # 全部样式
│   └── app.js                    # 渲染器 + 搜索 + KaTeX 触发
├── data/
│   ├── manifest.json             # 章节清单
│   ├── ch1.json ~ ch7.json       # 7 个章节内容
│   ├── sup1.json                 # 测验 & 附加题
│   └── sup2.json                 # 工具函数库展示
├── katex/                        # 离线 KaTeX 包（CSS / JS / fonts）
├── statcomp_exam_toolkit.R       # 可独立 source() 的工具函数库
├── LICENSE
└── README.md
```

## 使用教程

### 0. 安装 VS Code（前置）

如果尚未安装 [Visual Studio Code](https://code.visualstudio.com/)，请先从其官网下载并安装对应操作系统的版本。

### 1. 下载代码库

打开仓库主页 [`https://github.com/miracleyang-dev/stat-compute-cheatsheet`](https://github.com/miracleyang-dev/stat-compute-cheatsheet)，点击右上角绿色的 **Code → Download ZIP**，下载压缩包到本地。

### 2. 解压压缩包

将下载得到的 `stat-compute-cheatsheet-main.zip` 解压到任意目录。解压后会得到一个完整文件夹，里面包含 `index.html`、`assets/`、`data/`、`katex/` 等文件。

### 3. 在 VS Code 中安装 Live Server 插件

1. 打开 VS Code，点击左侧活动栏的「扩展」图标（或按 `Ctrl + Shift + X` / macOS 上 `⌘ + Shift + X`）。
2. 在搜索框输入 **Live Server**。
3. 找到作者为 **Ritwick Dey** 的同名插件，点击「安装 / Install」。

### 4. 启动本地服务

1. 在 VS Code 顶部菜单选择 **文件 → 打开文件夹**，选中第 2 步解压出来的项目根目录。
2. 在左侧资源管理器中右键点击 `index.html`，选择 **Open with Live Server**。
3. 浏览器会自动弹出 `http://127.0.0.1:5500/index.html`，正常情况下立即看到完整页面。

> ⚠️ **重点提醒**：请勿直接双击 `index.html` 打开（即 `file://` 路径），必须通过 Live Server 启动，否则浏览器会因 `file://` 协议限制无法加载 `data/*.json`，页面将一片空白。
>
> 如果你在打开后看到红色错误提示「加载失败」，几乎可以确定就是这个原因。

### 5. 离线使用 / 携带

整个项目本身就是离线可运行的（不依赖任何 CDN）。考试场景下，把整个文件夹拷到 U 盘 / 考场电脑，按上述方式启动 Live Server 即可。如果考场电脑没有 VS Code，也可以使用任何本地 HTTP 服务器替代，例如：

```bash
# 进入项目根目录后
python3 -m http.server 8000
# 然后浏览器访问 http://localhost:8000
```

## 工具函数库使用

`statcomp_exam_toolkit.R` 集成了 23 个常用函数，按七大类组织：随机变量生成 / MC 积分 / MC 推断 / Bootstrap 与 Jackknife / MCMC / 数值求根 / EM。考试时把它放到工作目录，在 R 里执行：

```r
source("statcomp_exam_toolkit.R")
# 然后直接调用，例如：
mc_antithetic_unit(function(x) exp(-x) / (1 + x^2), n = 10000, seed = 12)
```

> 接口约定：MC 类返回 `c(est, se, var_est)`；Bootstrap 类返回 `c(theta_hat, se, bias)` 或矩阵；MCMC 类返回 `list(chain, reject_rate)`，**接受率 = 1 − reject_rate**。

## 许可证

[MIT](LICENSE)
