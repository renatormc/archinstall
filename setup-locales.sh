#!/usr/bin/env bash
set -euo pipefail

UI_LANG="en_US.UTF-8"
FORMAT_LOCALE="pt_BR.UTF-8"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> Verifying generated system locales..."
AVAILABLE_LOCALES=$(locale -a 2>/dev/null || true)

for loc in "$UI_LANG" "$FORMAT_LOCALE"; do
    normalized="${loc%%.*}"
    if ! echo "$AVAILABLE_LOCALES" | grep -iq "${normalized//_/-}\|${normalized}"; then
        echo "WARNING: Locale '$loc' may not be generated on your host system."
        echo "If formatting fails, generate it (e.g. 'sudo locale-gen $loc')."
    fi
done

# 1. Detect KDE config utility (Plasma 6 vs Plasma 5)
KWRITE=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)

if [[ -z "$KWRITE" ]]; then
    echo "ERROR: Neither 'kwriteconfig6' nor 'kwriteconfig5' was found. Is KDE Plasma installed?" >&2
    exit 1
fi

echo "==> Configuring KDE Plasma localerc using $(basename "$KWRITE")..."

# Set UI language
"$KWRITE" --file plasma-localerc --group Translations --key LANGUAGE "en_US"
"$KWRITE" --file plasma-localerc --group Formats --key LANG "$UI_LANG"

# Set all regional formats to pt_BR
CATEGORIES=(
    LC_NUMERIC
    LC_TIME
    LC_MONETARY
    LC_MEASUREMENT
    LC_COLLATE
    LC_PAPER
    LC_NAME
    LC_ADDRESS
    LC_TELEPHONE
    LC_IDENTIFICATION
)

for cat in "${CATEGORIES[@]}"; do
    "$KWRITE" --file plasma-localerc --group Formats --key "$cat" "$FORMAT_LOCALE"
done

# 2. Write POSIX standard locale.conf for shell and non-KDE apps
echo "==> Updating $CONFIG_DIR/locale.conf..."
mkdir -p "$CONFIG_DIR"

cat << EOF > "$CONFIG_DIR/locale.conf"
LANG=$UI_LANG
LANGUAGE=en_US:en
LC_NUMERIC=$FORMAT_LOCALE
LC_TIME=$FORMAT_LOCALE
LC_MONETARY=$FORMAT_LOCALE
LC_PAPER=$FORMAT_LOCALE
LC_NAME=$FORMAT_LOCALE
LC_ADDRESS=$FORMAT_LOCALE
LC_TELEPHONE=$FORMAT_LOCALE
LC_MEASUREMENT=$FORMAT_LOCALE
LC_IDENTIFICATION=$FORMAT_LOCALE
EOF

echo ""
echo "Done. Changes will take effect on next login."
read -rp "Do you want to log out now to apply changes? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null \
      || loginctl terminate-session "${XDG_SESSION_ID:-}"
fi