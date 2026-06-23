# setup-vim-code-browsing

把普通 Vim 变成一个**只读代码浏览器 / 轻量 IDE**,适合在大型代码库里看代码。一条命令(或一句话给 Claude)装好,无需 root,全部装进用户 home 目录。

这是一个 [Claude Code](https://claude.com/claude-code) skill,也可以脱离 Claude 直接当 dotfiles 用。

## 能做什么

| 需求 | 工具 | 默认快捷键 |
|---|---|---|
| 代码结构 / 大纲 | coc.nvim `:CocOutline` | `<space>o` |
| 跳转(定义/引用/实现) | coc.nvim (LSP) | `gd` / `gr` / `gi` |
| 全局搜索 | fzf.vim + ripgrep | `<space>f`(文件)`<space>g`(全文) |
| 函数调用关系(谁调用/调用谁) | coc.nvim call hierarchy | `<space>ci` / `<space>co` |
| 某行提交人 / 时间(git blame) | vim-fugitive + coc-git | 行内自动 + `<space>gb` |
| **快捷键速查表** | 内置 | **`<space>?`**(记不住时随时弹出) |

`<leader>` 是空格键。

## 依赖

- `node` ≥ v18 —— coc.nvim 必需(**硬依赖**)
- `vim` ≥ 8.1(推荐 9.x)、`git`、`curl`
- `ripgrep` (`rg`) —— 全局搜索需要

## 安装

```bash
git clone https://github.com/gaoxiaowei2117/setup-vim-code-browsing.git
cd setup-vim-code-browsing
bash scripts/install.sh
```

脚本幂等、无 root,会**备份**你已有的 `~/.vimrc`。可指定要装的 LSP 扩展:

```bash
COC_EXTENSIONS="coc-pyright coc-json coc-git" bash scripts/install.sh
```

装完打开任意源码文件即可使用(首次打开某语言 LSP 会后台索引几秒)。按 `<space>?` 看全部快捷键。

## 作为 Claude Code skill 使用

把本仓库克隆到 `~/.claude/skills/setup-vim-code-browsing`,然后对 Claude 说「配置 vim 看代码」即可触发。

## 默认面向 Python + TypeScript

默认装 `coc-pyright` + `coc-tsserver`,并把 vendored 目录(`cooked/`、`node_modules/`、`dist/`)从搜索和 LSP 索引中排除。其它语言改 `COC_EXTENSIONS` 与 `assets/coc-settings.json` 即可。

## 许可

MIT
