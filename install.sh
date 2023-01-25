#!/bin/bash

############################################################
# Colors                                                   #
############################################################

readonly cyan='\033[0;36m'        # Title
readonly red='\033[0;31m'         # Error
readonly yellow='\033[1;33m'      # Warning
readonly purple='\033[0;35m'      # Alert
readonly blue='\033[0;34m'        # Attention
readonly light_gray='\033[0;37m'  # Option
readonly green='\033[0;32m'       # Done
readonly reset='\033[0m'          # No color, end of sentence

# %b - Print the argument while expanding backslash escape sequences.
# %q - Print the argument shell-quoted, reusable as input.
# %d, %i - Print the argument as a signed decimal integer.
# %s - Print the argument as a string.

#Syntax:
#    printf "'%b' 'TEXT' '%s' '%b'\n" "${color}" "${var}" "${reset}"

############################################################
# Help                                                     #
############################################################

function Help() {

   # Display Help
   echo ""
   echo "Syntax: ./install.sh [OPTION..] [MODIFIER..]"
   echo ""
   echo "Options:"
   echo "-h, --help                Print this help message."
   echo ""
   echo "-a, --arch                Current operational system (Arch Linux)."
   echo "-u, --ubuntu              Current operational system (Ubuntu-based Distro)."
   echo "-wsl, --wsl               Current operational system (Windows Subsystem for Linux)."
   echo "-w, --windows             Current operational system (Windows)."
   echo ""
   echo "Modifiers:"
   echo "-c, --config-sys          Configure system."
   echo "-i, --install-packages    Install packages."
   echo "-p, --check-packages      Check if all packages are installed (not available for -w, --windows)."
   echo ""

}

############################################################
# Main program                                             #
############################################################

#Section: "Functions"

function timer() {

    if [ "${#}" == "" ]; then
        printf "%bIncorrect use of 'timer' Function !%b\nSyntax:\vtimer_ 'PHRASE';%b\n" "${purple}" "${light_gray}" "${reset}" 1>&2
        exit 2
    fi

    printf "%b%s%b\n" "${blue}" "${*}" "${reset}"
    local duration=5  # In seconds
    while [ ! "${duration}" == 0 ]; do
        printf "%bContinuing in: %s%b\r" "${light_gray}" "${duration}" "${reset}"
        ((--duration))
        sleep 1
    done
    printf "\n"

}

function mkfile() {

    if [ "${#}" -ne "1" ]; then
        printf "%bIncorrect use of 'mkfile' Function !%b\nSyntax:\vmkfile [PATH]... ;%b" "${red}" "${light_gray}" "${reset}" 1>&2 ;
        exit 2 ;
    fi

    # Create File and Folder if needed
    mkdir --parents --verbose "$(dirname "${1}")" && touch "${1}" || exit 2 ;

}

#Section: "--config-sys"

function configure-timezone() {

    ln --force --symbolic --verbose /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

}

function configure-hardware-clock() {

    hwclock --systohc --verbose

}

function configure-locale() {

    sed --expression 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' --in-place /etc/locale.gen
    sed --expression 's/#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/g' --in-place /etc/locale.gen
    locale-gen
    printf "LANG=en_US.UTF-8" | tee "/etc/locale.conf" > /dev/null 2>&1

}

function configure-hostname() {

    read -r -p "$(printf "\n%bEnter HOSTNAME: %b" "${cyan}" "${reset}")" SET_HOSTNAME
    printf "%s" "${SET_HOSTNAME}" | ${permit} tee "/etc/hostname" > /dev/null 2>&1

}

function configure-pretty-hostname() {

    while true; do
        read -r -p "$(printf "\n%bIs this machine a '%blaptop%b' or '%bdesktop%b'? %b" "${cyan}" "${light_gray}" "${cyan}" "${light_gray}" "${cyan}" "${reset}")" yn
        case "${yn}" in
            'desktop' )
                SET_CHASSIS="${yn}"
                break ;
                ;;
            'laptop' )
                SET_CHASSIS="${yn}"
                break ;
                ;;
            * )
                printf "%bPlease answer with '%bdesktop%b' or '%blaptop%b'. %b\n" "${red}" "${light_gray}" "${red}" "${light_gray}" "${red}" "${reset}"
                ;;
        esac
    done
    read -r -p "$(printf "\n%bEnter Pretty Hostname: %b" "${cyan}" "${reset}")" SET_PRETTYNAME
    SET_ICON_NAME="computer"
    SET_DEPLOYMENT="production"
    {
        printf "PRETTY_HOSTNAME=\"%s\"" "${SET_PRETTYNAME}"
        printf "\nICON_NAME=%s" "${SET_ICON_NAME}"
        printf "\nCHASSIS=%s" "${SET_CHASSIS}"
        printf "\nDEPLOYMENT=%s" "${SET_DEPLOYMENT}"
    } | ${permit} tee "/etc/machine-info" > /dev/null 2>&1

}

function configure-hosts() {

    {
        printf "127.0.0.1    localhost"
        printf "\n::1          localhost"
        printf "\n127.0.1.1    %s.localdomain    %s" "${SET_HOSTNAME}" "${SET_HOSTNAME}"
    } | ${permit} tee "/etc/hosts" > /dev/null 2>&1

}

function configure-keyboard-layout() {

    printf "KEYMAP=us" | tee "/etc/vconsole.conf" > /dev/null 2>&1

}

function configure-package-manager() {

    case "${system}" in
        arch )

            mkdir --verbose "${PWD}"/Backup
            if [ ! -f "${PWD}"/Backup/pacman.conf.backup ]; then
                cp --verbose /etc/pacman.conf "${PWD}"/Backup/pacman.conf.backup
            fi

            cp --verbose "${PWD}"/Backup/pacman.conf.backup /etc/pacman.conf
            sed --expression 's/#ParallelDownloads = 5/ParallelDownloads = 5/g' --in-place /etc/pacman.conf
            sed --expression 's/#Color/Color/g' --in-place /etc/pacman.conf
            {
                printf "\n[multilib]"
                printf "\nInclude = /etc/pacman.d/mirrorlist"
            } | tee --append "/etc/pacman.conf" > /dev/null 2>&1

            pacman --sync --refresh --refresh --noconfirm
            ;;
        ubuntu )
            ${permit} apt update --yes
            ${permit} apt upgrade --yes
            ;;
        wsl )
            ${permit} apt update --yes
            ${permit} apt upgrade --yes
            ;;
    esac

}

function configure-grub() {

    pacman --sync grub \
    efibootmgr         \
    os-prober          \
    intel-ucode        --noconfirm

    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
    sed --expression 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0.1/g' --in-place /etc/default/grub
    sed --expression 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=true/g' --in-place /etc/default/grub
    grub-mkconfig --output /boot/grub/grub.cfg

}

function configure-network() {

    pacman --sync networkmanager --noconfirm
    systemctl enable NetworkManager.service

}

function configure-home-directory() {

    case "${system}" in
        arch )
            mkdir --verbose /etc/skel/Desktop
            mkdir --verbose /etc/skel/Documents
            mkdir --verbose /etc/skel/Downloads
            mkdir --verbose /etc/skel/Music
            mkdir --verbose /etc/skel/Pictures
            mkdir --verbose /etc/skel/Pictures/Screenshots
            mkdir --verbose /etc/skel/Pictures/Wallpapers
            mkdir --verbose /etc/skel/Projects
            mkdir --verbose /etc/skel/Public
            mkdir --verbose /etc/skel/Repositories
            mkdir --verbose /etc/skel/Templates
            mkdir --verbose /etc/skel/Video\ Games
            mkdir --verbose /etc/skel/Videos
            mkdir --verbose /etc/skel/Virtual\ Machine
            mkdir --verbose /etc/skel/.local
            mkdir --verbose /etc/skel/.local/bin
            ;;
        ubuntu )
            mkdir --verbose "${HOME}"/Pictures/Screenshots
            mkdir --verbose "${HOME}"/Pictures/Wallpapers
            mkdir --verbose "${HOME}"/Projects
            mkdir --verbose "${HOME}"/Video\ Games
            mkdir --verbose "${HOME}"/Repositories
            mkdir --verbose "${HOME}"/Virtual\ Machine
            mkdir --verbose "${HOME}"/.local
            mkdir --verbose "${HOME}"/.local/bin
            ;;
        wsl )
            mkdir --verbose "${HOME}"/Desktop
            mkdir --verbose "${HOME}"/Documents
            mkdir --verbose "${HOME}"/Downloads
            mkdir --verbose "${HOME}"/Music
            mkdir --verbose "${HOME}"/Pictures
            mkdir --verbose "${HOME}"/Pictures/Screenshots
            mkdir --verbose "${HOME}"/Pictures/Wallpapers
            mkdir --verbose "${HOME}"/Projects
            mkdir --verbose "${HOME}"/Public
            mkdir --verbose "${HOME}"/Repositories
            mkdir --verbose "${HOME}"/Templates
            mkdir --verbose "${HOME}"/Video\ Games
            mkdir --verbose "${HOME}"/Videos
            mkdir --verbose "${HOME}"/Virtual\ Machine
            mkdir --verbose "${HOME}"/.local
            mkdir --verbose "${HOME}"/.local/bin
            ;;
        windows )
            mkdir --verbose "${HOME}"/Projects
            mkdir --verbose "${HOME}"/Public
            mkdir --verbose "${HOME}"/Repositories
            mkdir --verbose "${HOME}"/Templates
            mkdir --verbose "${HOME}"/Virtual\ Machine
            mkdir --verbose "${HOME}"/bin
            ;;
    esac

}

function configure-user() {

    while true; do
        read -r -p "$(printf "\n%bWould you like to add a new user? %b" "${cyan}" "${reset}")" yn
        case "${yn}" in
            'yes' )
                read -r -p "$(printf "\n%bEnter User's Full Name: %b" "${cyan}" "${reset}")" USER_NAME
                read -r -p "$(printf "\n%bEnter Username (Login): %b" "${cyan}" "${reset}")" USER_LOGIN

                useradd --badname --create-home --groups wheel --shell /bin/bash "${USER_LOGIN}"
                usermod --comment "${USER_NAME}" "${USER_LOGIN}"

                printf "%bSet Password for %b'%s'%b\n" "${cyan}" "${light_gray}" "${USER_LOGIN}" "${reset}"
                until passwd "${USER_LOGIN}"
                do
                    printf "%bPasswords do not match. Try again..%b\n" "${red}" "${reset}"
                done
                break ;
                ;;
            'no' )
                break ;
                ;;
            * )
                printf "%bPlease answer with '%byes%b' or '%bno%b'. %b\n" "${red}" "${light_gray}" "${red}" "${light_gray}" "${red}" "${reset}"
                ;;
        esac
    done

}

function configure-sudoers() {

    printf "%%wheel ALL=(ALL:ALL) ALL\n" | ${permit} tee "/etc/sudoers.d/wheel" > /dev/null 2>&1
    printf "\nDefaults insults" | ${permit} tee --append "/etc/sudoers.d/wheel" > /dev/null 2>&1
    printf "\nDefaults timestamp_timeout=10" | ${permit} tee --append "/etc/sudoers.d/wheel" > /dev/null 2>&1
    printf "\nDefaults lecture = always" | ${permit} tee --append "/etc/sudoers.d/wheel" > /dev/null 2>&1

}

#Section: "--check-packages"

function check-installed-packages() {

    printf "\n%bChecking if Packages from '%s' are installed... %b\n\n" "${blue}" "${file}" "${reset}"
    sleep 2

    case "${system}" in
        arch )
            while IFS="" read -r p || [ -n "${p}" ]; do
                if pacman --query --groups "${p}" > /dev/null 2>&1 && ! pacman --query --info "${p}" > /dev/null 2>&1; then
                    # It is a Group and not a Package and is installed
                    printf "%bThe package '%s' is installed%b\n" "${green}" "${p}" "${reset}"
                    sleep 0.05
                elif ! pacman --query --groups "${p}" > /dev/null 2>&1 && pacman --query --info "${p}" > /dev/null 2>&1; then
                    # It is not a Group, but a package and is installed
                    printf "%bThe package '%s' is installed%b\n" "${green}" "${p}" "${reset}"
                    sleep 0.05
                else
                    # It is neither a Group nor a Package and is not installed
                    printf "%bThe package '%s' is not installed%b\n" "${red}" "${p}" "${reset}"
                    sleep 0.5
                fi
            done < "${file}"
            ;;
        * )
            while IFS="" read -r p || [ -n "${p}" ]; do
                if sudo dpkg --list "${p}" > /dev/null 2>&1 ; then
                    # It is a Group or a Package and is installed
                    printf "%bThe package '%s' is installed%b\n" "${green}" "${p}" "${reset}"
                    sleep 0.05
                else
                    # It is neither a Group nor a Package and is not installed
                    printf "%bThe package '%s' is not installed%b\n" "${red}" "${p}" "${reset}"
                    sleep 0.5
                fi
            done < "${file}"
            ;;
    esac

}

#Section: "--install-packages"

function install-packages() {

    printf "\n%bInstalling Packages from '%s'%b\n" "${yellow}" "${file}" "${reset}"
    sleep 2

    case "${system}" in
        arch )
            while IFS="" read -r p || [ -n "${p}" ]; do
                    printf "%bInstalling %s...%b\n" "${yellow}" "${p}" "${reset}"
                    sudo pacman --sync "${p}" --noconfirm
            done < "${file}"
            ;;
        * )
            while IFS="" read -r p || [ -n "${p}" ]; do
                    printf "%bInstalling %s...%b\n" "${yellow}" "${p}" "${reset}"
                    sudo apt install "${p}" --yes
            done < "${file}"
            ;;
    esac

}

function install-other-packages() {

    mkdir --parents --verbose "${PWD}"/Downloads/Packages ;

    (
        # ly
        printf "\n%bInstalling LY (GitHub Fork)...%b\n" "${yellow}" "${reset}"
        sleep 2

        if [ -d "${PWD}"/Downloads/Packages/ly-display-manager ]; then rm --force --recursive --verbose "${PWD}"/Downloads/Packages/ly-display-manager; fi
        git clone --recurse-submodules https://github.com/gnsbriel/ly-display-manager.git "${PWD}"/Downloads/Packages/ly-display-manager
        cd "${PWD}"/Downloads/Packages/ly-display-manager || exit
        make
        sudo make install installsystemd
    )

    (
        # Spotify
        printf "\n%bInstalling Spotify (AUR)...%b\n" "${yellow}" "${reset}"
        sleep 2

        if [ -d "${PWD}"/Downloads/Packages/spotify ]; then rm --force --recursive --verbose "${PWD}"/Downloads/Packages/spotify; fi
        curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | gpg --import -
        git clone https://aur.archlinux.org/spotify.git "${PWD}"/Downloads/Packages/spotify
        cd "${PWD}"/Downloads/Packages/spotify || exit
        makepkg -si --noconfirm
    )

    (
        # Picom
        printf "\n%bInstalling Picom (AUR)...%b\n" "${yellow}" "${reset}"
        sleep 2

        if [ -d "${PWD}"/Downloads/Packages/picom-jonaburg-git ]; then rm --force --recursive --verbose "${PWD}"/Downloads/Packages/picom-jonaburg-git; fi
        git clone https://aur.archlinux.org/picom-jonaburg-git.git "${PWD}"/Downloads/Packages/picom-jonaburg-git
        cd "${PWD}"/Downloads/Packages/picom-jonaburg-git || exit
        makepkg -si --noconfirm
    )

    (
        # VSCode
        printf "\n%bInstalling VSCode (AUR)...%b\n" "${yellow}" "${reset}"
        sleep 2

        if [ -d "${PWD}"/Downloads/Packages/visual-studio-code-bin ]; then rm --force --recursive --verbose "${PWD}"/Downloads/Packages/visual-studio-code-bin; fi
        git clone https://aur.archlinux.org/visual-studio-code-bin.git "${PWD}"/Downloads/Packages/visual-studio-code-bin
        cd "${PWD}"/Downloads/Packages/visual-studio-code-bin || exit
        makepkg -si --noconfirm
    )

    (
        # Only Office
        printf "\n%bInstalling Only Office (AUR)...%b\n" "${yellow}" "${reset}"
        sleep 2

        if [ -d "${PWD}"/Downloads/Packages/onlyoffice-bin ]; then rm --force --recursive --verbose "${PWD}"/Downloads/Packages/onlyoffice-bin; fi
        git clone https://aur.archlinux.org/onlyoffice-bin.git "${PWD}"/Downloads/Packages/onlyoffice-bin
        cd "${PWD}"/Downloads/Packages/onlyoffice-bin || exit
        makepkg -si --noconfirm
    )

}

function install-others() {

    mkdir --parents --verbose "${PWD}"/Downloads/Bin

    case "${system}" in
        windows )
            mkdir --parents --verbose "${HOME}"/bin/

            # Chrome driver
            if [ -f "${PWD}"/Downloads/Bin/chromedriver_latest_release ]; then rm --force --verbose "${PWD}"/Downloads/Bin/chromedriver_latest_release; fi
            curl --location https://chromedriver.storage.googleapis.com/LATEST_RELEASE --output "${PWD}"/Downloads/Bin/chromedriver_latest_release
            LATEST_RELEASE=$( cat "${PWD}"/Downloads/Bin/chromedriver_latest_release )
            if [ -f "${PWD}"/Downloads/Bin/chromedriver_win32.zip ]; then rm --force --verbose "${PWD}"/Downloads/Bin/chromedriver_win32.zip; fi
            curl --location https://chromedriver.storage.googleapis.com/"${LATEST_RELEASE}"/chromedriver_win32.zip --output "${PWD}"/Downloads/Bin/chromedriver_win32.zip
            unzip -o "${PWD}"/Downloads/Bin/'chromedriver_win32.zip' -d "${HOME}"/bin/

            # Geckodriver
            VERSION=$(curl -s https://api.github.com/repos/mozilla/geckodriver/releases/latest \
            | grep "tag_name" \
            | awk '{ print $2 }' \
            | sed 's/,$//'       \
            | sed 's/"//g' )     \
            ; if [ -f "${PWD}"/Downloads/Bin/geckodriver-${VERSION}-win64.zip ]; then rm --force --verbose "${PWD}"/Downloads/Bin/geckodriver-${VERSION}-win64.zip; fi
            curl --location "https://github.com/mozilla/geckodriver/releases/download/${VERSION}/geckodriver-${VERSION}-win64.zip" --output "${PWD}/Downloads/Bin/geckodriver-${VERSION}-win64.zip"
            unzip -o "${PWD}"/Downloads/Bin/geckodriver-"${VERSION}"-win64.zip -d "${HOME}"/bin -o
            ;;
        *)
            mkdir --parents --verbose "${HOME}"/.local/bin/

            # Chrome driver
            if [ -f "${PWD}"/Downloads/Bin/chromedriver_latest_release ]; then rm --force --verbose "${PWD}"/Downloads/Bin/chromedriver_latest_release; fi
            curl --location https://chromedriver.storage.googleapis.com/LATEST_RELEASE --output "${PWD}"/Downloads/Bin/chromedriver_latest_release
            LATEST_RELEASE=$( cat "${PWD}"/Downloads/Bin/chromedriver_latest_release )
            if [ -f "${PWD}"/Downloads/Bin/chromedriver_linux64.zip ]; then rm --force --verbose "${PWD}"/Downloads/Bin/chromedriver_linux64.zip; fi
            curl --location https://chromedriver.storage.googleapis.com/"${LATEST_RELEASE}"/chromedriver_linux64.zip --output "${PWD}"/Downloads/Bin/chromedriver_linux64.zip
            unzip -o "${PWD}"/Downloads/Bin/'chromedriver_linux64.zip' -d "${HOME}"/.local/bin/

            # NVM (NodeJS Version Manager)
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
            export NVM_DIR="${HOME}/.nvm"
            [ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"                    # This loads nvm
            [ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion
            nvm install --lts
            nvm use --lts

            if [ ! "${system}" == "arch" ] ;then
                VERSION=$(curl -s https://api.github.com/repos/mozilla/geckodriver/releases/latest \
                | grep "tag_name" \
                | awk '{ print $2 }' \
                | sed 's/,$//'       \
                | sed 's/"//g' )     \
                ; if [ -f "${PWD}"/Downloads/Bin/geckodriver-"${VERSION}"-linux64.tar.gz ]; then rm --force --verbose "${PWD}"/Downloads/Bin/geckodriver-"${VERSION}"-linux64.tar.gz; fi
                curl --location "https://github.com/mozilla/geckodriver/releases/download/${VERSION}/geckodriver-${VERSION}-linux64.tar.gz" --output "${PWD}/Downloads/Bin/geckodriver-${VERSION}-linux64.tar.gz"
                tar -xvzf "${PWD}/Downloads/Bin/geckodriver-${VERSION}-linux64.tar.gz" -C "${HOME}"/.local/bin/
            fi
            ;;
    esac

}

function install-fonts() {

    mkdir --parents --verbose "${PWD}"/Downloads/Fonts

    # Icons (Material Design Fonts)
    if [ -d "${PWD}"/Downloads/Fonts/MaterialDesign-Font ]; then rm --force --recursive --verbose "${PWD}"/Downloads/Bin/MaterialDesign-Font; fi
    git clone https://github.com/Templarian/MaterialDesign-Font.git "${PWD}"/Downloads/Fonts/MaterialDesign-Font/

    # Nerd Fonts (Hack)
    VERSION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
    | grep "tag_name" \
    | awk '{ print $2 }' \
    | sed 's/,$//'       \
    | sed 's/"//g' )     \
    ; if [ -f "${PWD}"/Downloads/Fonts/Hack.zip ]; then rm --force --verbose "${PWD}"/Downloads/Bin/Hack.zip; fi
    curl --location https://github.com/ryanoasis/nerd-fonts/releases/download/"${VERSION}"/Hack.zip --output "${PWD}"/Downloads/Fonts/Hack.zip

    # Nerd Fonts (FiraCode)
    VERSION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
    | grep "tag_name" \
    | awk '{ print $2 }' \
    | sed 's/,$//'       \
    | sed 's/"//g' )     \
    ; if [ -f "${PWD}"/Downloads/Fonts/FiraCode.zip ]; then rm --force --verbose "${PWD}"/Downloads/Bin/FiraCode.zip; fi
    curl --location https://github.com/ryanoasis/nerd-fonts/releases/download/"${VERSION}"/FiraCode.zip --output "${PWD}"/Downloads/Fonts/FiraCode.zip

    case "${system}" in
        windows )
            mkdir --verbose --parents "${HOME}"/Fonts/

            if [ -d "${HOME}"/Fonts/MaterialDesign-Font ]; then rm --force --recursive --verbose "${HOME}"/Fonts/MaterialDesign-Font; fi
            cp --recursive "${PWD}"/Downloads/Fonts/MaterialDesign-Font "${HOME}"/Fonts/

            if [ -d "${HOME}"/Fonts/Hack ]; then rm --force --recursive --verbose "${HOME}"/Fonts/Hack; fi
            mkdir --verbose --parents "${HOME}"/Fonts/Hack
            unzip -o "${PWD}"/Downloads/Fonts/Hack.zip -d "${HOME}"/Fonts/Hack

            if [ -d "${HOME}"/Fonts/FiraCode ]; then rm --force --recursive --verbose "${HOME}"/Fonts/FiraCode; fi
            mkdir --verbose --parents "${HOME}"/Fonts/FiraCode
            unzip -o "${PWD}"/Downloads/Fonts/FiraCode.zip -d "${HOME}"/Fonts/FiraCode
            ;;
        * )
            mkdir --verbose --parents "${HOME}"/.local/share/fonts/

            # Install Fonts
            if [ -d "${HOME}"/.local/share/fonts/MaterialDesign-Font ]; then rm --force --recursive --verbose "${HOME}"/.local/share/fonts/MaterialDesign-Font; fi
            cp --recursive "${PWD}"/Downloads/Fonts/MaterialDesign-Font/ "${HOME}"/.local/share/fonts/

            if [ -d "${HOME}"/.local/share/fonts/Hack ]; then rm --force --recursive --verbose "${HOME}"/.local/share/fonts/Hack; fi
            mkdir --verbose --parents "${HOME}"/.local/share/fonts/Hack
            unzip -o "${PWD}"/Downloads/Fonts/'Hack.zip' -d "${HOME}"/.local/share/fonts/Hack/

            if [ -d "${HOME}"/.local/share/fonts/FiraCode ]; then rm --force --recursive --verbose "${HOME}"/.local/share/fonts/FiraCode; fi
            mkdir --verbose --parents "${HOME}"/.local/share/fonts/FiraCode
            unzip -o "${PWD}"/Downloads/Fonts/'FiraCode.zip' -d "${HOME}"/.local/share/fonts/FiraCode/

            # Refresh Fonts Cache
            fc-cache --really-force
            ;;
    esac

}

#Section: "--install-config-files"

function install-config-files() {

    mkdir --verbose "${PWD}"/Ignored
    source "/etc/machine-info"

    case "${system}" in
        arch )
            if [ "${CHASSIS}" == "desktop" ]; then
                mkdir --parents "${PWD}"/Ignored/etc/X11/xorg.conf.d/
                mv --verbose "${PWD}"/etc/X11/xorg.conf.d/30-libinput.conf "${PWD}"/Ignored/etc/X11/xorg.conf.d/
            fi
            if [ "${CHASSIS}" == "laptop" ]; then
                mkdir --parents "${PWD}"/Ignored/etc/X11/xorg.conf.d/
                mv --verbose "${PWD}"/etc/X11/xorg.conf.d/10-monitor.conf "${PWD}"/Ignored/etc/X11/xorg.conf.d/
                mv --verbose "${PWD}"/etc/X11/xorg.conf.d/20-amdgpu.conf "${PWD}"/Ignored/etc/X11/xorg.conf.d/
            fi
            ;;
        ubuntu )
            if [ "${CHASSIS}" == "desktop" ]; then
                mkdir --parents "${PWD}"/Ignored/etc/X11/xorg.conf.d/
                mv --verbose "${PWD}"/etc/X11/xorg.conf.d/30-libinput.conf "${PWD}"/Ignored/etc/X11/xorg.conf.d/
                mv --verbose "${PWD}"/etc/modules-load.d "${PWD}"/Ignored/etc/
                mv --verbose "${PWD}"/etc/ly "${PWD}"/Ignored/etc/
                mv --verbose "${PWD}"/etc/pam.d "${PWD}"/Ignored/etc/
            elif [ "${CHASSIS}" == "laptop" ]; then
                mkdir --parents "${PWD}"/Ignored/etc/X11/xorg.conf.d/
                mv --verbose "${PWD}"/etc/X11/xorg.conf.d/10-monitor.conf "${PWD}"/Ignored/etc/X11/xorg.conf.d/
                mv --verbose "${PWD}"/etc/X11/xorg.conf.d/20-amdgpu.conf "${PWD}"/Ignored/etc/X11/xorg.conf.d/
                mv --verbose "${PWD}"/etc/modules-load.d "${PWD}"/Ignored/etc/
                mv --verbose "${PWD}"/etc/ly "${PWD}"/Ignored/etc/
                mv --verbose "${PWD}"/etc/pam.d "${PWD}"/Ignored/etc/
            fi
            ;;
    esac

    sudo cp --recursive --verbose "${PWD}"/etc /
    sudo cp --recursive --verbose "${PWD}"/usr /

    cp --recursive "${PWD}"/Ignored/etc "${PWD}"/
    rm --force --recursive "${PWD}"/Ignored

}

#Section: "--install-dotfiles"

function install-dotfiles() {

    rm --force --recursive "${HOME}"/.dotfiles

    git clone https://github.com/gnsbriel/.dotfiles.git "${HOME}"/.dotfiles

    (
        cd "${HOME}"/.dotfiles || exit 1

        case "${system}" in
            arch )
                bash install.sh --arch
                ;;
            ubuntu )
                bash install.sh --ubuntu
                ;;
            wsl )
                bash install.sh --wsl
                ;;
            windows )
                bash install.sh --windows
                ;;
        esac
    )

}

function download-wallpapers() {

    git clone https://gitlab.com/dwt1/wallpapers.git "${HOME}"/Pictures/Wallpapers

}

#Section: "--enable-services"

function enable-services() {

    case "${system}" in
        ubuntu )
            sudo systemctl enable numlock.service      ; # Enable Numlock Service
            ;;
        * )
            sudo systemctl enable ufw.service          ; # Enable firewall Service
            sudo systemctl enable ly.service           ; # Enable Ly Service
            sudo systemctl disable getty@tty2.service  ; # Disable getty on Ly's tty to prevent "login" from spawning on top of it
            sudo systemctl enable numlock.service      ; # Enable Numlock Service
            sudo ufw enable                            ; # Enable firewall
            ;;
    esac

}

############################################################
# Options                                                  #
############################################################

while true; do
    case "${1}" in
        -h | --help)
            Help
            exit 0
            ;;
        -a | --arch)
            system="arch"
            permit=""
            file="${PWD}/packages-arch.txt"
            shift
            ;;
        -u | --ubuntu)
            system="ubuntu"
            permit="sudo"
            file="${PWD}/packages-linux.txt"
            shift
            ;;
        -wsl | --wsl)
            system="wsl"
            permit="sudo"
            file="${PWD}/packages-wsl.txt"
            shift
            ;;
        -w | --windows)
            system="windows"
            permit="sudo"
            shift
            ;;
        -i | --install-packages)
            timer "$(printf "%bWarning: You chose to Install Packages for %s..%b" "${yellow}" "${system}" "${reset}")"

            if [ "${system}" == "arch" ]; then
                install-packages
                install-other-packages
                install-others
                install-fonts
                install-config-files
                install-dotfiles
                download-wallpapers
                enable-services
                check-installed-packages
            fi

            if [ "${system}" == "ubuntu" ]; then
                install-packages
                install-others
                install-fonts
                install-config-files
                install-dotfiles
                download-wallpapers
                enable-services
                check-installed-packages
            fi

            if [ "${system}" == "wsl" ]; then
                install-packages
                install-others
                install-fonts
                install-dotfiles
                check-installed-packages
            fi

            if [ "${system}" == "windows" ]; then
                install-others
                install-fonts
                install-dotfiles
            fi

            exit 0
            ;;
        -c | --config-sys)
            timer "$(printf "%bWarning: You chose to config %s..%b" "${yellow}" "${system}" "${reset}")"

            if [ "${system}" == "arch" ]; then
                configure-timezone
                configure-hardware-clock
                configure-locale
                configure-hostname
                configure-pretty-hostname
                configure-hosts
                configure-keyboard-layout
                configure-package-manager
                configure-grub
                configure-network
                configure-home-directory
                configure-user
                configure-sudoers
            fi

            if [ "${system}" == "ubuntu" ]; then
                configure-hostname
                configure-pretty-hostname
                configure-hosts
                configure-package-manager
                configure-home-directory
                configure-sudoers
            fi

            if [ "${system}" == "wsl" ]; then
                configure-package-manager
                configure-home-directory
                configure-sudoers
            fi

            if [ "${system}" == "windows" ]; then
                configure-home-directory
            fi

            exit 0
            ;;
        -p | --check-packages)
            timer "$(printf "%bWarning: You chose to check if packages for %s are installed..%b" "${yellow}" "${system}" "${reset}")"

            if [ "${system}" == "arch" ]; then
                check-installed-packages
            fi

            if [ "${system}" == "ubuntu" ]; then
                check-installed-packages
            fi

            if [ "${system}" == "wsl" ]; then
                check-installed-packages
            fi

            if [ "${system}" == "windows" ]; then
                Help
            fi

            exit 0
            ;;
        *)
            Help
            exit 0
            ;;
    esac
done
