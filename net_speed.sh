#!/bin/sh
# macOS 网速:tmux-net-speed 只认 Linux 的 /proc/net/dev,这里改用 netstat 读默认路由网卡
#   sh net_speed.sh setup  把 status-right 里的网速占位符换成本脚本(由 tmux.conf 调用)
#   sh net_speed.sh        输出 "↓x ↑y",状态栏每秒调用一次

if [ "$1" = setup ]; then
    tmux set -g status-right "$(tmux show -gv status-right | sed "s|↓#{download_speed} ↑#{upload_speed}|#(sh '$0')|")"
    exit
fi

iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
now=$(netstat -ibn -I "${iface:-en0}" | awk 'NR==2{print $(NF-4), $(NF-1)}')
state=${TMPDIR:-/tmp}/tmuxconf-net-$(id -u)
old=$(cat "$state" 2>/dev/null)
echo "$(date +%s) $now" > "$state"

# 与上次的字节差 / 时间差,格式与 tmux-net-speed 一致
echo "$old" "$(date +%s) $now" | awk '
function fmt(v) { return v >= 1048576 ? int(v/1048576) " MB/s" : v >= 1024 ? int(v/1024) " KB/s" : int(v) " B/s" }
{
    dt = $4 - $1; if (dt < 1) dt = 1
    rx = $5 - $2; tx = $6 - $3
    if (NF < 6 || rx < 0 || tx < 0) rx = tx = 0
    printf "↓%s ↑%s", fmt(rx / dt), fmt(tx / dt)
}'
