#!/usr/bin/env bash
# tmuxconf 安装脚本
#   本地: git clone https://github.com/ninvfeng/tmuxconf ~/.tmuxconf && ~/.tmuxconf/install.sh
#   远程: curl -fsSL https://raw.githubusercontent.com/ninvfeng/tmuxconf/main/install.sh | bash
set -e

REPO=${TMUXCONF_REPO:-https://github.com/ninvfeng/tmuxconf}
TPM_REPO=${TPM_REPO:-https://github.com/tmux-plugins/tpm}
DIR=${TMUXCONF_DIR:-$HOME/.tmuxconf}

# 缺 tmux / git 就用系统包管理器装上
pkg_install() {
    local sudo=; [ "$(id -u)" = 0 ] || sudo=sudo
    if command -v brew >/dev/null; then brew install "$@"
    elif command -v apt-get >/dev/null; then $sudo apt-get update -qq && $sudo apt-get install -y "$@"
    elif command -v dnf >/dev/null; then $sudo dnf install -y "$@"
    elif command -v yum >/dev/null; then $sudo yum install -y "$@"
    elif command -v pacman >/dev/null; then $sudo pacman -S --noconfirm "$@"
    elif command -v apk >/dev/null; then $sudo apk add "$@"
    else echo "没找到包管理器,请手动安装:$*"; exit 1
    fi
}
missing=
for c in tmux git; do command -v $c >/dev/null || missing="$missing $c"; done
[ -z "$missing" ] || { echo "安装$missing ..."; pkg_install $missing; }

# 老发行版仓库里的 tmux 可能低于 3.2,部分功能不可用,提醒一下但不拦
ver=$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)
awk "BEGIN{exit !($ver < 3.2)}" && echo "⚠ 当前 tmux $ver 低于 3.2,部分功能不可用,建议升级"

# 从仓库里执行就用仓库本身,curl | bash 时才去 clone
SRC=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)
if [ -f "$SRC/tmux.conf" ] && [ -f "$SRC/ta.sh" ]; then
    DIR=$SRC
elif [ -d "$DIR/.git" ]; then
    git -C "$DIR" pull --ff-only
else
    git clone --depth 1 "$REPO" "$DIR"
fi

# 已有配置先备份,软链指向我们的就不用备份
if [ -e ~/.tmux.conf ] && [ "$(readlink ~/.tmux.conf)" != "$DIR/tmux.conf" ]; then
    bak=~/.tmux.conf.bak.$(date +%Y%m%d%H%M%S)
    mv ~/.tmux.conf "$bak"
    echo "已备份原配置 -> $bak"
fi
ln -sfn "$DIR/tmux.conf" ~/.tmux.conf

# 在 tmux 里执行时会继承外层的插件路径,固定到 tpm 所在目录,避免装到别处
export TMUX_PLUGIN_MANAGER_PATH=$HOME/.tmux/plugins/
[ -d ~/.tmux/plugins/tpm ] || git clone --depth 1 "$TPM_REPO" ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins || { echo "插件安装失败,检查网络后重新执行 install.sh"; exit 1; }

# ta 命令写入 shell 配置,已写过则跳过
line="[ -f \"$DIR/ta.sh\" ] && . \"$DIR/ta.sh\"  # tmuxconf"
rcs="$HOME/.zshrc $HOME/.bashrc"
# macOS 终端开的 bash 是登录 shell,只读 .bash_profile
[ "$(uname)" = Darwin ] && rcs="$rcs $HOME/.bash_profile"
found=
for rc in $rcs; do
    [ -f "$rc" ] || continue
    found=1
    grep -q '# tmuxconf$' "$rc" || { echo "$line" >> "$rc"; echo "已写入 ta 命令 -> $rc"; }
done
# 新机器(尤其新 Mac)可能一个 rc 都没有,按当前 shell 建一个
if [ -z "$found" ]; then
    case "$SHELL" in
        *zsh) rc=~/.zshrc ;;
        *) [ "$(uname)" = Darwin ] && rc=~/.bash_profile || rc=~/.bashrc ;;
    esac
    echo "$line" >> "$rc"
    echo "已写入 ta 命令 -> $rc"
fi

# 正在运行的 tmux 直接生效
tmux source-file ~/.tmux.conf 2>/dev/null || true

echo
echo "✓ 安装完成。新开一个终端,在项目目录下执行 ta 即可。"
