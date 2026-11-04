#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

NAME="MacSDDM"
DEST="/usr/share/sddm/themes/$NAME"

CONF_DIR="/etc/sddm.conf.d"
CONF="$CONF_DIR/90-macsddm.conf"

DATA="$HOME/.local/share/macsddm"
BACKUPS="$DATA/backups"
STATE="$DATA/last-backup"

mkdir -p "$BACKUPS" "$DATA"

BOLD='\033[1m'
RESET='\033[0m'
WHITE='\033[97m'
GRAY='\033[90m'
BLUE='\033[38;5;75m'
GREEN='\033[38;5;114m'
RED='\033[38;5;203m'

title() {
    clear
    printf "${BLUE}${BOLD}"
    cat <<'ART'
    __  ___             _____  ____  ______
   /  |/  /___ _____   / ___/ / __ \/ __  /
  / /|_/ / __ `/ __ \  \__ \ / / / / /_/ /
 / /  / / /_/ / /_/ / ___/ // /_/ / ____/
/_/  /_/\__,_/ .___/ /____/ \____/_/
            /_/
ART
    printf "${RESET}"
    printf "${GRAY}  Liquid Glass SDDM theme${RESET}\n\n"
}

check_project() {
    local missing=0

    for file in \
        Main.qml \
        GlassPill.qml \
        theme.conf \
        metadata.desktop \
        assets/avatar.png \
        assets/wallpaper.jpg \
        assets/fonts/OpenRunde-Regular.otf \
        assets/fonts/OpenRunde-Semibold.otf \
        shaders/liquidglass.frag.qsb
    do
        if [[ ! -f "$ROOT/$file" ]]; then
            printf "${RED}Missing: %s${RESET}\n" "$file"
            missing=1
        fi
    done

    if (( missing )); then
        return 1
    fi
}

preview() {
    local greeter=""

    if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
        greeter="sddm-greeter-qt6"
    elif command -v sddm-greeter >/dev/null 2>&1; then
        greeter="sddm-greeter"
    else
        printf "${RED}SDDM greeter not found.${RESET}\n"
        return 1
    fi

    printf "${BLUE}Opening MacSDDM preview...${RESET}\n"

    "$greeter" --test-mode --theme "$ROOT"
}

save_backup() {
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"

    BACKUP_DIR="$BACKUPS/$stamp"

    mkdir -p "$BACKUP_DIR"

    if [[ -d "$DEST" ]]; then
        sudo cp -a "$DEST" "$BACKUP_DIR/theme"
    fi

    if [[ -f "$CONF" ]]; then
        sudo cp -a "$CONF" "$BACKUP_DIR/config"
    fi

    printf '%s\n' "$BACKUP_DIR" > "$STATE"
}

install_theme() {
    local activate="${1:-yes}"

    check_project || return 1

    sudo -v

    save_backup

    printf "\n${BLUE}Installing theme...${RESET}\n"

    sudo rm -rf "$DEST"
    sudo install -d "$DEST"

    sudo cp -a \
        "$ROOT/Main.qml" \
        "$ROOT/GlassPill.qml" \
        "$ROOT/theme.conf" \
        "$ROOT/metadata.desktop" \
        "$ROOT/assets" \
        "$ROOT/shaders" \
        "$DEST/"

    if [[ -d "$ROOT/third_party" ]]; then
        sudo cp -a "$ROOT/third_party" "$DEST/"
    fi

    sudo chmod -R a+rX "$DEST"

    if [[ "$activate" == "yes" ]]; then
        sudo install -d "$CONF_DIR"

        printf '[Theme]\nCurrent=MacSDDM\n' \
            | sudo tee "$CONF" >/dev/null

        printf "${GREEN}Theme installed and activated.${RESET}\n"
    else
        printf "${GREEN}Theme installed without changing the active theme.${RESET}\n"
    fi
}

restore() {
    if [[ ! -f "$STATE" ]]; then
        printf "${RED}No backup information found.${RESET}\n"
        return 1
    fi

    local backup
    backup="$(cat "$STATE")"

    if [[ ! -d "$backup" ]]; then
        printf "${RED}Backup directory does not exist.${RESET}\n"
        return 1
    fi

    sudo -v

    printf "${BLUE}Restoring previous configuration...${RESET}\n"

    if [[ -d "$backup/theme" ]]; then
        sudo rm -rf "$DEST"
        sudo cp -a "$backup/theme" "$DEST"
    else
        sudo rm -rf "$DEST"
    fi

    if [[ -f "$backup/config" ]]; then
        sudo cp -a "$backup/config" "$CONF"
    else
        sudo rm -f "$CONF"
    fi

    printf "${GREEN}Previous configuration restored.${RESET}\n"
}

change_asset() {
    local type="$1"
    local source=""

    if [[ "$type" == "avatar" ]]; then
        printf "Path to new PNG avatar: "
        read -r source
        [[ -f "$source" ]] || return 1

        cp -- "$source" "$ROOT/assets/avatar.png"
    else
        printf "Path to new JPG wallpaper: "
        read -r source
        [[ -f "$source" ]] || return 1

        cp -- "$source" "$ROOT/assets/wallpaper.jpg"
    fi

    printf "${GREEN}Asset updated in project.${RESET}\n"
    install_theme yes
}

uninstall_theme() {
    if [[ -f "$STATE" ]]; then
        restore
    else
        sudo rm -f "$CONF"
        sudo rm -rf "$DEST"
    fi

    printf "${GREEN}MacSDDM removed.${RESET}\n"
}

menu() {
    while true; do
        title

        printf "  ${WHITE}1${RESET}  Preview theme\n"
        printf "  ${WHITE}2${RESET}  Install and activate\n"
        printf "  ${WHITE}3${RESET}  Install without activation\n"
        printf "  ${WHITE}4${RESET}  Change avatar\n"
        printf "  ${WHITE}5${RESET}  Change wallpaper\n"
        printf "  ${WHITE}6${RESET}  Restore previous version\n"
        printf "  ${WHITE}7${RESET}  Uninstall MacSDDM\n"
        printf "  ${WHITE}0${RESET}  Exit\n\n"

        printf "${GRAY}  Select action: ${RESET}"
        read -r choice

        case "$choice" in
            1) preview ;;
            2) install_theme yes ;;
            3) install_theme no ;;
            4) change_asset avatar ;;
            5) change_asset wallpaper ;;
            6) restore ;;
            7) uninstall_theme ;;
            0) exit 0 ;;
            *) printf "${RED}Unknown option.${RESET}\n" ;;
        esac

        printf "\n${GRAY}Press Enter to continue...${RESET}"
        read -r _
    done
}

case "${1:-}" in
    --preview)
        preview
        ;;
    --install)
        install_theme yes
        ;;
    --install-only)
        install_theme no
        ;;
    --restore)
        restore
        ;;
    --uninstall)
        uninstall_theme
        ;;
    --avatar)
        [[ -f "${2:-}" ]] || exit 1
        cp -- "$2" "$ROOT/assets/avatar.png"
        install_theme yes
        ;;
    --wallpaper)
        [[ -f "${2:-}" ]] || exit 1
        cp -- "$2" "$ROOT/assets/wallpaper.jpg"
        install_theme yes
        ;;
    *)
        menu
        ;;
esac
