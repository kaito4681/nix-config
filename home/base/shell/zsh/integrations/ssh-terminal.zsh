if [[ -o interactive && -t 0 ]]; then
    { stty -ixon < /dev/tty } 2>/dev/null
fi
