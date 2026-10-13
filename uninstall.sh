#!/usr/bin/env bash
# tmuxconf 卸载:移除软链与 ta 命令,恢复最近一次备份。插件目录保留,不影响其他配置
set -e

if [ -L ~/.tmux.conf ]; then
    rm ~/.tmux.conf
    bak=$(ls -t ~/.tmux.conf.bak.* 2>/dev/null | head -1)
    [ -n "$bak" ] && mv "$bak" ~/.tmux.conf && echo "已恢复 $bak"
fi

for rc in ~/.zshrc ~/.bashrc ~/.bash_profile; do
    [ -f "$rc" ] && sed -i.tmuxconf-bak '/# tmuxconf$/d' "$rc" && rm -f "$rc.tmuxconf-bak"
done

echo "✓ 已卸载,新开终端生效。~/.tmux/plugins 与仓库目录未删除,可手动清理。"
