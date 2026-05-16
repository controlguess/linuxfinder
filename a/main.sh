#!/usr/bin/env bash

FILES='
[
  { "name": "Mint Cinnamon", "url": "https://mirror.hoobly.com/linuxmint-iso/stable/22.3/linuxmint-22.3-cinnamon-64bit.iso" },
  { "name": "Fedora (Intel+AMD)", "url": "https://download.fedoraproject.org/pub/fedora/linux/releases/44/KDE/x86_64/iso/Fedora-KDE-Desktop-Live-44-1.7.x86_64.iso" },
  { "name": "Fedora (ARM aarch64)", "url": "https://download.fedoraproject.org/pub/fedora/linux/releases/44/KDE/aarch64/iso/Fedora-KDE-Desktop-Live-44-1.7.aarch64.iso" },
  { "name": "AntiX-26 Full", "url": "https://mirror.umd.edu/mxlinux-iso/ANTIX/Final/antiX-26/antiX-26_x64-full.iso" },
  { "name": "AntiX-26 Core", "url": "https://mirror.umd.edu/mxlinux-iso/ANTIX/Final/antiX-26/antiX-26_x64-core.iso" },
  { "name": "Debian (AMD64)", "url": "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso" },
  { "name": "Arch", "url": "https://mirrors.bloomu.edu/archlinux/iso/2026.05.01/archlinux-x86_64.iso" },
  { "name": "Pop!_OS", "url": "https://iso.pop-os.org/24.04/amd64/generic/24/pop-os_24.04_amd64_generic_24.iso" },
  { "name": "CachyOS (Desktop Edition)", "url": "https://cdn77.cachyos.org/ISO/desktop/260426/cachyos-desktop-linux-260426.iso" },
  { "name": "CachyOS (Handheld Edition)", "url": "https://cdn77.cachyos.org/ISO/handheld/260426/cachyos-handheld-linux-260426.iso" },
  { "name": "Alma KDE", "url": "https://repo.almalinux.org/almalinux/10/live/x86_64/AlmaLinux-10.1-x86_64-Live-KDE.iso" },
  { "name": "Alma GNOME", "url": "https://repo.almalinux.org/almalinux/10/live/x86_64/AlmaLinux-10.1-x86_64-Live-GNOME.iso" },
  { "name": "Bazzite GNOME", "url": "https://download.bazzite.gg/bazzite-gnome-stable-live-amd64.iso" },
  { "name": "EndeavourOS", "url": "https://mirrors.gigenet.com/endeavouros/iso/EndeavourOS_Titan-Neo-2026.04.27.iso" },
  { "name": "Gentoo", "url": "https://distfiles.gentoo.org/releases/amd64/autobuilds/20260510T170106Z/livegui-amd64-20260510T170106Z.iso" },
  { "name": "Zorin", "url": "https://distro.ibiblio.org/zorinos/18/Zorin-OS-18.1-Core-64-bit.iso" }
]
'

WHITE="\033[37m"
DIM="\033[2m"
RESET="\033[0m"

install_package() {
    PACKAGE="$1"

    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y "$PACKAGE"

    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm "$PACKAGE"

    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$PACKAGE"

    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y "$PACKAGE"

    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "$PACKAGE"

    elif command -v apk >/dev/null 2>&1; then
        sudo apk add "$PACKAGE"

    elif command -v brew >/dev/null 2>&1; then
        brew install "$PACKAGE"

    else
        echo "Unsupported package manager."
        exit 1
    fi
}

check_dependency() {
    CMD="$1"
    PKG="$2"

    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "Installing missing dependency: $PKG"
        install_package "$PKG"
    fi
}

check_dependency curl curl
check_dependency jq jq
check_dependency tput ncurses

clear
printf "\nEnter download path: "
read -r DOWNLOAD_DIR

mkdir -p "$DOWNLOAD_DIR" || {
    echo "Failed to create directory."
    exit 1
}

FILES=$(printf "%s" "$FILES" | jq 'sort_by(.name)')
COUNT=$(printf "%s" "$FILES" | jq length)
selected=0

draw_menu() {
    clear

    printf "\n"
    printf "DistroBin\n\n"

    i=0
    while [ "$i" -lt "$COUNT" ]; do
        NAME=$(printf "%s" "$FILES" | jq -r ".[$i].name")

        if [ "$i" -eq "$selected" ]; then
            printf "${DIM}${WHITE}> %s${RESET}\n" "$NAME"
        else
            printf "  %s\n" "$NAME"
        fi

        i=$((i + 1))
    done

    printf "\nUse ↑ ↓ arrows and Enter to download.\n"
}

download_selected() {
    NAME=$(printf "%s" "$FILES" | jq -r ".[$selected].name")
    URL=$(printf "%s" "$FILES" | jq -r ".[$selected].url")

    FILENAME=$(basename "$URL")

    clear
    printf "\nDownloading: %s\n\n" "$NAME"

    curl -L --progress-bar "$URL" -o "$DOWNLOAD_DIR/$FILENAME"

    if [ $? -eq 0 ]; then
        printf "\nSaved to: %s/%s\n" "$DOWNLOAD_DIR" "$FILENAME"
    else
        printf "\nDownload failed.\n"
    fi

    printf "\nPress Enter to continue..."
    read -r _
}

while true; do
    draw_menu

    IFS= read -rsn1 key

    if [[ "$key" == $'\x1b' ]]; then
        read -rsn2 key

        case "$key" in
            '[A')
                ((selected--))
                [ "$selected" -lt 0 ] && selected=$((COUNT - 1))
                ;;
            '[B')
                ((selected++))
                [ "$selected" -ge "$COUNT" ] && selected=0
                ;;
        esac

    elif [[ "$key" == "" ]]; then
        download_selected
    fi
done
