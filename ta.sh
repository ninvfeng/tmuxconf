# ta: 以当前目录名创建或回到 tmux 会话,ta <name> 指定会话名
# 由 install.sh 在 ~/.zshrc / ~/.bashrc 中 source,兼容 bash 与 zsh

# 老版本里 ta 常是 alias,zsh 下同名 alias 会让函数定义报错
unalias ta 2>/dev/null

ta() {
    local name
    # tmux 会话名不允许 . 和 :
    name=$(printf '%s' "${1:-${PWD##*/}}" | tr '.:' '__')
    [ -n "$name" ] || name=root

    if [ -n "$TMUX" ]; then
        # 已在 tmux 内,直接 attach 会报嵌套,改为后台建好再切过去
        tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$PWD"
        tmux switch-client -t "=$name"
    else
        tmux new-session -A -s "$name" -c "$PWD"
    fi
}
