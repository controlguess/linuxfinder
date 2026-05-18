#!/usr/bin/env bash

FILES='
{
	"Linux Downloads": {
		"Mint Cinnamon": "https://mirror.hoobly.com/linuxmint-iso/stable/22.3/linuxmint-22.3-cinnamon-64bit.iso",
		"Fedora (Intel+AMD)": "https://download.fedoraproject.org/pub/fedora/linux/releases/44/KDE/x86_64/iso/Fedora-KDE-Desktop-Live-44-1.7.x86_64.iso",
		"Fedora (ARM aarch64)": "https://download.fedoraproject.org/pub/fedora/linux/releases/44/KDE/aarch64/iso/Fedora-KDE-Desktop-Live-44-1.7.aarch64.iso",
		"AntiX-26 Full": "https://mirror.umd.edu/mxlinux-iso/ANTIX/Final/antiX-26/antiX-26_x64-full.iso",
		"AntiX-26 Core": "https://mirror.umd.edu/mxlinux-iso/ANTIX/Final/antiX-26/antiX-26_x64-core.iso",
		"Debian (AMD64)": "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso",
		"Arch": "https://mirrors.bloomu.edu/archlinux/iso/2026.05.01/archlinux-x86_64.iso",
		"Pop!_OS": "https://iso.pop-os.org/24.04/amd64/generic/24/pop-os_24.04_amd64_generic_24.iso",
		"CachyOS (Desktop Edition)": "https://cdn77.cachyos.org/ISO/desktop/260426/cachyos-desktop-linux-260426.iso",
		"CachyOS (Handheld Edition)": "https://cdn77.cachyos.org/ISO/handheld/260426/cachyos-handheld-linux-260426.iso",
		"Alma KDE": "https://repo.almalinux.org/almalinux/10/live/x86_64/AlmaLinux-10.1-x86_64-Live-KDE.iso",
		"Alma GNOME": "https://repo.almalinux.org/almalinux/10/live/x86_64/AlmaLinux-10.1-x86_64-Live-GNOME.iso",
		"Bazzite GNOME": "https://download.bazzite.gg/bazzite-gnome-stable-live-amd64.iso",
		"EndeavourOS": "https://mirrors.gigenet.com/endeavouros/iso/EndeavourOS_Titan-Neo-2026.04.27.iso",
		"Gentoo": "https://distfiles.gentoo.org/releases/amd64/autobuilds/20260510T170106Z/livegui-amd64-20260510T170106Z.iso",
		"Zorin": "https://distro.ibiblio.org/zorinos/18/Zorin-OS-18.1-Core-64-bit.iso",
		"Nobara": "https://nobara-images.nobaraproject.org/Nobara-43-Official-2026-04-19.iso",
		"Nobara GNOME": "https://nobara-images.nobaraproject.org/Nobara-43-GNOME-2026-04-19.iso",
		"Garuda": "https://iso.builds.garudalinux.org/iso/latest/garuda/mokka/latest.iso",
		"Deepin (AMD64)": "https://cdimage.deepin.com/releases/25.1.0/amd64/deepin-desktop-community-25.1.0-amd64.iso",
		"Kubuntu": "https://cdimage.ubuntu.com/kubuntu/releases/26.04/release/kubuntu-26.04-desktop-amd64.iso",
		"Manjaro KDE": "https://download.manjaro.org/kde/26.0.4/manjaro-kde-26.0.4-260327-linux618.iso",
		"Manjaro XFCE": "https://download.manjaro.org/xfce/26.0.4/manjaro-xfce-26.0.4-260327-linux618.iso",
		"AnduinOS": "https://download.anduinos.com/1.1/1.1.12/AnduinOS-1.1.12-en_US.iso",
		"PikaOS": "https://iso.pika-os.com/PikaOS-Nest-GNOME-4.0-amd64-v3-26.04.04-1.iso",
		"BigLinux": "https://iso.biglinux.com.br/biglinux_2026-05-16_k618.iso",
		"NixOS": "https://channels.nixos.org/nixos-25.11/latest-nixos-graphical-x86_64-linux.iso",
		"Omarchy": "https://iso.omarchy.org/omarchy-3.8.0.iso",
		"MiniOS": "https://github.com/minios-linux/minios-live/releases/download/v5.1.1/minios-trixie-xfce-standard-amd64-5.1.1.iso",
		"Void": "https://repo-default.voidlinux.org/live/current/void-live-x86_64-20250202-base.iso",
		"Kali": "https://cdimage.kali.org/kali-2026.1/kali-linux-2026.1-installer-amd64.iso"
	}
}
'

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
mkdir -p "$DOWNLOAD_DIR" || exit 1

selected=0
PATH_STACK=()

get_current_json() {
    local jq_path="."
    for p in "${PATH_STACK[@]}"; do
        jq_path="$jq_path[\"$p\"]"
    done
    printf "%s" "$FILES" | jq "$jq_path"
}

draw_menu() {
    clear
    CURRENT=$(get_current_json)
    mapfile -t ITEMS < <(printf "%s" "$CURRENT" | jq -r 'keys[]')
    COUNT=${#ITEMS[@]}
    WIDTH=$(tput cols)
    HEIGHT=$(tput lines)
    VIEWING=$((selected + 1))
	INSTR="Enter = open/download | LeftArrow = back ($VIEWING/$COUNT)"
    MAX_DISPLAY=$((HEIGHT - 3))
    ROW_START=$((selected / MAX_DISPLAY * MAX_DISPLAY))
    ROW_END=$((ROW_START + MAX_DISPLAY - 1))
    [ $ROW_END -ge $((COUNT - 1)) ] && ROW_END=$((COUNT - 1))
    MAX_LENGTH=0
    for ITEM in "${ITEMS[@]}"; do
        [ ${#ITEM} -gt $MAX_LENGTH ] && MAX_LENGTH=${#ITEM}
    done
    COL_WIDTH=$((MAX_LENGTH + 2))
    for i in $(seq $ROW_START $ROW_END); do
        ITEM="${ITEMS[$i]}"
        TYPE=$(printf "%s" "$CURRENT" | jq -r --arg k "$ITEM" '.[$k] | type')
        [ "$TYPE" = "object" ] && DISPLAY="$ITEM/" || DISPLAY="$ITEM"
        if [ "$i" -eq "$selected" ]; then
            printf "> %-${MAX_LENGTH}s\n" "$DISPLAY"
        else
            printf "  %-${MAX_LENGTH}s\n" "$DISPLAY"
        fi
    done
    printf "\n%s\n" "$INSTR"
}

download_file() {
    local name="$1"
    local url="$2"
    filename=$(basename "$url")
    clear
    printf "\nDownloading: %s\n\n" "$name"
    curl -L --progress-bar "$url" -o "$DOWNLOAD_DIR/$filename"
    printf "\nPress Enter to continue..."
    read -r _
}

while true; do
    draw_menu
    IFS= read -rsn1 key
    CURRENT=$(get_current_json)
    mapfile -t ITEMS < <(printf "%s" "$CURRENT" | jq -r 'keys[]')
    COUNT=${#ITEMS[@]}

    if [[ "$key" == $'\x1b' ]]; then
        read -rsn2 key2
        case "$key2" in
            '[A') 
                ((selected--))
                [ "$selected" -lt 0 ] && selected=$((COUNT - 1))
                ;;
            '[B') 
                ((selected++))
                [ "$selected" -ge "$COUNT" ] && selected=0
                ;;
            '[D') 
                if [ "${#PATH_STACK[@]}" -gt 0 ]; then
                    unset 'PATH_STACK[-1]'
                    selected=0
                fi
                ;;
        esac
    elif [[ "$key" == "" ]]; then
        ITEM="${ITEMS[$selected]}"
        TYPE=$(printf "%s" "$CURRENT" | jq -r --arg k "$ITEM" '.[$k] | type')
        if [ "$TYPE" = "object" ]; then
            PATH_STACK+=("$ITEM")
            selected=0
        else
            URL=$(printf "%s" "$CURRENT" | jq -r --arg k "$ITEM" '.[$k]')
            download_file "$ITEM" "$URL"
        fi
    fi
done
