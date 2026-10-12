#!/usr/bin/env bash
# tmuxconf 安装脚本
#   本地: git clone https://github.com/ninvfeng/tmuxconf ~/.tmuxconf && ~/.tmuxconf/install.sh
#   远程: curl -fsSL https://raw.githubusercontent.com/ninvfeng/tmuxconf/main/install.sh | bash
set -e

REPO=${TMUXCONF_REPO:-https://github.com/ninvfeng/tmuxconf}
TPM_REPO=${TPM_REPO:-https://github.com/tmux-plugins/tpm}
DIR=${TMUXCONF_DIR:-$HOME/.tmuxconf}

command -v tmux >/dev/null || { echo "请先安装 tmux (>= 3.2)"; exit 1; }
command -v git >/dev/null || { echo "请先安装 git"; exit 1; }

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
for rc in ~/.zshrc ~/.bashrc; do
    [ -f "$rc" ] || continue
    grep -q '# tmuxconf$' "$rc" || { echo "$line" >> "$rc"; echo "已写入 ta 命令 -> $rc"; }
done

# 正在运行的 tmux 直接生效
tmux source-file ~/.tmux.conf 2>/dev/null || true

echo
echo "✓ 安装完成。新开一个终端,在项目目录下执行 ta 即可。"
