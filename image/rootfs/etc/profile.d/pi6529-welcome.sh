# pi6529: on an interactive login, show what the validator is doing and how
# to open its page. Nothing here runs for scripts or scp.
case "$-" in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac
[ -n "${SSH_TTY:-}" ] || [ "$(tty 2>/dev/null)" != "not a tty" ] || return 0
if [ -x /usr/local/sbin/pi6529 ]; then
    if [ "$(id -u)" = "0" ]; then
        /usr/local/sbin/pi6529 welcome
    elif sudo -n true 2>/dev/null; then
        sudo -n /usr/local/sbin/pi6529 welcome
    else
        echo "pi6529: run 'sudo pi6529' to see the validator's status and the link to its page."
    fi
fi
