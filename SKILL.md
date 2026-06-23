---
name: setup-vim-code-browsing
description: Set up Vim as a code browser/IDE for reading large codebases — symbol outline, go-to-definition/references, project-wide search, call hierarchy (incoming/outgoing calls), and per-line git blame. Installs coc.nvim (LSP) + fzf + ripgrep + vim-fugitive without root, into the user's home directory. Use when the user wants to browse, navigate, or read code in Vim/Vim9, asks to "配置 vim 看代码", set up vim plugins for code navigation, jump to definitions, search the whole project, see who calls a function, or see git blame per line. Defaults target Python + TypeScript projects but the LSP set is configurable.
---

# Setup Vim Code Browsing

## Overview

Turns a plain Vim into a code-reading environment. Maps five common needs to tools:

| 需求 | 工具 | 默认快捷键 |
|---|---|---|
| 代码结构 / 大纲 | coc.nvim `:CocOutline` | `<space>o` |
| 跳转(定义/引用/实现) | coc.nvim LSP | `gd` / `gr` / `gi` |
| 全局搜索 | fzf.vim + ripgrep | `<space>f`(文件)`<space>g`(全文) |
| 函数调用关系(谁调用/调用谁) | coc.nvim call hierarchy | `<space>ci` / `<space>co` |
| 某行提交人/时间(git blame) | vim-fugitive + coc-git | 行内自动 + `<space>gb` |

`<leader>` 是空格键。**记不住快捷键时,在 vim 里按 `<space>?` 随时弹出速查表,`q` 关闭。**

**关键点:跳转和调用关系依赖 LSP**,所以只对 coc 扩展支持的语言生效。这也是必须用 coc.nvim(而非纯 ctags/cscope)的原因——只有 LSP 能干净地做 call hierarchy。

## Prerequisites (hard requirements)

- `node` ≥ v18 —— coc.nvim 必需。**没有 node 就装不了**,先让用户装 node。
- `vim` ≥ 8.1(推荐 9.x),`git`,`curl`。
- `ripgrep` (`rg`) —— 全局搜索(`<space>f`/`:Rg`)需要。`install.sh` 会在缺失时自动装到 `~/.local/bin`(免 root)。缺了其余功能仍可用。
- 不需要 root:fzf 装到 `~/.fzf`,插件装到 `~/.vim`,ripgrep 装到 `~/.local/bin`。

> ⚠️ **`rg` 探测陷阱**:某些环境(如 Claude Code 的 shell)会注入一个名为 `rg` 的 shell 函数,
> 使 `command -v rg` / `rg --version` 误报成功。但 vim 的 fzf 用非交互 `sh -c` 执行,
> 那里没有真正的 `rg` 二进制 → `<space>f` 报 `Command failed`。
> 正确判断:`sh -c 'command -v rg'`。`install.sh` 已按此检测。

## Workflow

### 1. 探测环境
先确认 node/vim/git/rg 是否齐全,以及工程语言(决定要装哪些 coc 扩展):

```bash
vim --version | head -1; node --version; git --version; rg --version | head -1
# 工程语言分布(挑 LSP 用):
git ls-files | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -15
```

- 见到大量 `.py` → 需要 `coc-pyright`。
- 见到 `.ts/.tsx/.js/.vue` 或 `package.json`/`tsconfig.json` → 需要 `coc-tsserver`(Vue 另加 `coc-volar`)。
- 其它语言对应扩展:`coc-rust-analyzer`、`coc-clangd`、`coc-go`、`coc-java` 等。

### 2. 注意 vendored 目录(重要)
大工程常把第三方代码 vendored 进仓库(如本机的 `cooked/` 里有 2.4 万个 `.py`)。若不排除,会拖垮全局搜索和 LSP 索引。`assets/vimrc` 与 `assets/coc-settings.json` 默认排除了 `cooked/`、`node_modules/`、`dist/`。**若该工程的 vendored 目录叫别的名字,安装后改这两个文件里的 glob。**

### 3. 运行安装脚本
脚本幂等、无 root、会备份用户已有的 `~/.vimrc`:

```bash
bash scripts/install.sh
# 自定义要装的 LSP 扩展:
COC_EXTENSIONS="coc-pyright coc-json coc-git" bash scripts/install.sh
```

脚本依次:装 fzf → 装 vim-plug → 部署 `~/.vimrc` 和 `~/.vim/coc-settings.json`(备份旧的)→ `:PlugInstall` → `:CocInstall` 扩展 → 校验加载无报错。

### 4. 验证
```bash
# .vimrc 加载报错(应为空):
vim -es -u ~/.vimrc -c 'messages' -c 'qa' 2>&1 | grep -iE 'error|E[0-9]+:'
# coc 扩展已装:
ls ~/.config/coc/extensions/node_modules/
```
然后打开一个真实源码文件让用户试。**首次打开某语言文件时 LSP 会后台索引几秒**,之后跳转/调用关系才生效。Python 工程可能需要选解释器:`:CocCommand python.setInterpreter`。

## Customization notes

- **改 leader/快捷键**:编辑 `~/.vimrc`(由 `assets/vimrc` 部署而来)。
- **改排除目录**:同时改 `~/.vimrc` 里的 `$FZF_DEFAULT_COMMAND` 与 `:Rg` 命令的 glob,以及 `~/.vim/coc-settings.json` 的 `python.analysis.exclude`。
- **混合行号**(当前行绝对、其余相对):`set number relativenumber`。默认用纯绝对 `set number`,因为相对行号会随光标移动,易被误认为 bug。
- **配色**:`~/.vimrc` 末尾的 `colorscheme gruvbox`。

## Resources

- `scripts/install.sh` —— 幂等安装器(探测依赖 → 装 fzf/vim-plug → 部署配置 → PlugInstall → CocInstall → 校验)。
- `assets/vimrc` —— 完整 `~/.vimrc`(插件列表 + 全部快捷键 + 搜索排除)。
- `assets/coc-settings.json` —— coc 配置(LSP 排除 vendored 目录、开启行内 git blame、诊断显示)。
- `assets/cheatsheet.txt` —— 快捷键速查表,部署到 `~/.vim/cheatsheet.txt`,vim 内按 `<space>?` 打开。
