#!/bin/bash
# pi6529 first boot. Runs once, as root, from pi6529-firstboot.service.
set -u
DATA=/var/lib/6529-validator
ACCOUNT=validator6529
SETTINGS=/boot/firmware/pi6529.txt
STAMP_DIR=/var/lib/pi6529
log() { echo "pi6529 firstboot: $*"; }

mkdir -p "$STAMP_DIR"

# 1. Settings from the boot partition (key=value, # comments).
name=""; mode="home"; tor="on"; ui_port="7529"; country=""
if [ -r "$SETTINGS" ]; then
    while IFS='=' read -r k v; do
        k="${k//[[:space:]]/}"; v="${v%%#*}"; v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
        case "$k" in
            name) name="$v" ;; mode) mode="$v" ;; tor) tor="$v" ;; ui_port) ui_port="$v" ;; country) country="$v" ;;
            ''|'#'*) ;; *) log "ignoring unknown setting '$k' in $SETTINGS" ;;
        esac
    done < <(grep -v '^[[:space:]]*#' "$SETTINGS" | grep '=' || true)
fi
[ -n "$name" ] || name="$(hostname 2>/dev/null || echo pi6529)"
case "$mode" in home|datacenter) ;; *) log "mode '$mode' is not home or datacenter; using home"; mode=home ;; esac
case "$tor" in on|off) ;; *) log "tor '$tor' is not on or off; using on"; tor=on ;; esac
case "$ui_port" in ''|*[!0-9]*) log "ui_port '$ui_port' is not a number; using 7529"; ui_port=7529 ;; esac
if [ "$ui_port" = "6529" ]; then log "6529 reserves port 6529; using 7529"; ui_port=7529; fi
country="$(echo "$country" | tr '[:lower:]' '[:upper:]')"
case "$country" in ''|[A-Z][A-Z]) ;; *) log "country '$country' is not a two-letter code; ignoring it"; country="" ;; esac

# 2. The service account and its folder, as 6529's package makes them.
if ! getent passwd "$ACCOUNT" >/dev/null; then
    adduser --system --group --home "$DATA" --no-create-home \
        --shell /usr/sbin/nologin --gecos "6529 validator" --quiet "$ACCOUNT"
fi
install -d -m 0700 -o "$ACCOUNT" -g "$ACCOUNT" "$DATA"

# 3. validator init, on this Pi, so the keystore password is this Pi's own.
if [ ! -e "$DATA/config.toml" ]; then
    log "setting the validator up: mode=$mode tor=$tor page=127.0.0.1:$ui_port name='$name'"
    if (cd / && runuser -u "$ACCOUNT" -- /usr/bin/validator init --data-dir "$DATA" \
            --mode "$mode" --tor "$tor" --ui-bind "127.0.0.1:$ui_port" --name "$name"); then
        if [ -n "$country" ]; then
            # config.toml has a [location] table; add the country under it.
            runuser -u "$ACCOUNT" -- sed -i "s/^\[location\]$/[location]\ncountry = \"$country\"/" "$DATA/config.toml"
        fi
        # Backup tools (borg, restic, tar --exclude-caches) skip a folder with
        # this tag. A restored key with an old signer state can sign twice.
        printf '%s\n%s\n' 'Signature: 8a477f597d28d172789f06886806bc55' \
            '# 6529 validator: keys and signer state; never restore a copy on a second machine.' \
            > "$DATA/CACHEDIR.TAG"
        chown "$ACCOUNT:$ACCOUNT" "$DATA/CACHEDIR.TAG"; chmod 0600 "$DATA/CACHEDIR.TAG"
    else
        log "validator init failed; the validator service will not start. Run: sudo pi6529 repair"
        exit 1
    fi
else
    log "config.toml already exists; keeping it"
fi
printf 'mode=%s\ntor=%s\nui_port=%s\nname=%s\ncountry=%s\n' "$mode" "$tor" "$ui_port" "$name" "$country" > "$STAMP_DIR/settings"

# 4. The validator service starts now and with every boot.
systemctl daemon-reload
systemctl enable 6529-validator.service >/dev/null 2>&1 || true
systemctl --no-block start 6529-validator.service || true

date -u +%Y-%m-%dT%H:%M:%SZ > "$STAMP_DIR/firstboot-done"
log "done. The validator is starting. Log in and run: pi6529"
exit 0
