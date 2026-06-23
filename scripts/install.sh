#!/usr/bin/env bash
# 安装/配置 Vim 代码浏览环境 (coc.nvim + fzf + fugitive)。
# 幂等:可重复运行。不需要 root,全部装在用户 home 目录。
#
# 用法:  bash install.sh
#
# 可通过环境变量定制:
#   COC_EXTENSIONS  要安装的 coc 扩展(默认 Python+TS+Json+Git+Css+Html)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"
COC_EXTENSIONS="${COC_EXTENSIONS:-coc-pyright coc-tsserver coc-json coc-git coc-css coc-html}"

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn] %s\033[0m\n' "$*"; }

# ---------- 0. 前置依赖检查 ----------
say "检查前置依赖"
command -v vim  >/dev/null || { echo "缺少 vim(需要 8.1+,推荐 9.x)"; exit 1; }
command -v git  >/dev/null || { echo "缺少 git"; exit 1; }
command -v node >/dev/null || { echo "缺少 node(coc.nvim 必需,推荐 v18+)。请先装 node。"; exit 1; }
command -v rg   >/dev/null || warn "缺少 ripgrep(rg):全局搜索将不可用。建议安装 ripgrep。"
echo "vim  $(vim --version | head -1 | awk '{print $5}')"
echo "node $(node --version)"

# ---------- 1. fzf(无 root) ----------
say "安装 fzf"
if [ ! -x "$HOME/.fzf/bin/fzf" ]; then
  [ -d "$HOME/.fzf" ] || git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --bin >/dev/null
fi
echo "fzf $("$HOME/.fzf/bin/fzf" --version)"

# ---------- 2. vim-plug ----------
say "安装 vim-plug"
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
echo "vim-plug 就绪"

# ---------- 3. 部署配置文件(备份已有的) ----------
say "部署 .vimrc 与 coc-settings.json"
ts="$(date +%Y%m%d-%H%M%S)"
if [ -f "$HOME/.vimrc" ] && ! cmp -s "$ASSETS_DIR/vimrc" "$HOME/.vimrc"; then
  cp "$HOME/.vimrc" "$HOME/.vimrc.bak-$ts"; warn "已备份原有 ~/.vimrc → ~/.vimrc.bak-$ts"
fi
cp "$ASSETS_DIR/vimrc" "$HOME/.vimrc"
mkdir -p "$HOME/.vim"
if [ -f "$HOME/.vim/coc-settings.json" ] && ! cmp -s "$ASSETS_DIR/coc-settings.json" "$HOME/.vim/coc-settings.json"; then
  cp "$HOME/.vim/coc-settings.json" "$HOME/.vim/coc-settings.json.bak-$ts"
  warn "已备份原有 coc-settings.json"
fi
cp "$ASSETS_DIR/coc-settings.json" "$HOME/.vim/coc-settings.json"
cp "$ASSETS_DIR/cheatsheet.txt" "$HOME/.vim/cheatsheet.txt"   # <space>? 打开

# ---------- 4. 安装 vim 插件 ----------
say "安装 vim 插件 (PlugInstall)"
vim -es -u "$HOME/.vimrc" -c 'PlugInstall --sync' -c 'qa' >/dev/null 2>&1 || true
ls "$HOME/.vim/plugged/"

# ---------- 5. 安装 coc 扩展(LSP 引擎,会下载 npm 包,较慢) ----------
say "安装 coc 扩展: $COC_EXTENSIONS"
# shellcheck disable=SC2086
vim -es -u "$HOME/.vimrc" -c "CocInstall -sync $COC_EXTENSIONS" -c 'qa' >/dev/null 2>&1 || true
ls "$HOME/.config/coc/extensions/node_modules/" 2>/dev/null || warn "未发现 coc 扩展,请在 vim 内手动运行 :CocInstall $COC_EXTENSIONS"

# ---------- 6. 校验 ----------
say "校验"
if vim -es -u "$HOME/.vimrc" -c 'qa' 2>&1 | grep -qiE 'error|E[0-9]+:'; then
  warn ".vimrc 加载有报错,请用 :messages 查看"
else
  echo "✓ .vimrc 加载无报错"
fi
echo "✓ 完成。打开任意源码文件即可使用(首次打开 LSP 会后台索引几秒)。"
