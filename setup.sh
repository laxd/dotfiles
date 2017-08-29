#! /bin/bash

FILES=( .zshrc .xinitrc .xprofile .gitconfig .gitignore_global .vimrc .gradle .muttrc .tmux.conf .vnc/xstartup .config/i3/config .config/i3/lock.sh .config/i3/lock.png .config/i3status/config .config/neofetch/config .newsbeuter/urls .xscreensaver .Xdefaults .config/fontconfig/fonts.conf )
PACKAGES=( git binutils gcc make fakeroot pkg-config tmux i3 xscreensaver newsbeuter rxvt-unicode urxvt-perls scrot feh base-devel expac sysstat imagemagick xautolock dex zsh )
AUR_PACKAGES=( neofetch neomutt py3status urxvt-resize-font-git )

usage() {
	echo "$0 [-Aacdfhimpvw]"
	echo " -A perform a full setup of ALL options"
	echo " -a install required AUR packages"
	echo " -c Ask for confirmation before changing anything"
	echo " -d symlink dotfiles"
	echo " -f force - Overwrite files even if they exist - USE WITH CAUTION"
	echo " -h Print this help text"
	echo " -i install pacaur"
	echo " -I Install i3"
	echo " -m setup mutt"
	echo " -p install required packages"
	echo " -v verbose"
	echo " -w copy wallpapers"
    echo " -z install oh-my-zsh"
}

is_verbose() {
	return $VERBOSE
}

is_force() {
	return $FORCE
}

log() {
	if is_verbose; then
		echo "$@"
	fi
}

install_from_aur_manually() {

	if ! confirm "Install $1 from AUR?"; then
		return 1
	fi

	# Check it's already installed
	if ! is_installed $1 || is_force; then
		curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$1
		makepkg PKGBUILD --skippgpcheck
		sudo pacman -U $1*.xz --noconfirm
	else
		log "$1 is already installed"
	fi

	return 0
}

install_pacaur() {
	echo "Installing pacaur"

	CURRENT_DIR=`pwd`

	mkdir -p /tmp/pacaur_install
	cd /tmp/pacaur_install || exit 1


	# Git is required for aur installs
	if ! is_installed git; then
		sudo pacman -S git --noconfirm
	fi

	# Install cower
	if ! install_from_aur_manually cower; then
		echo "Cower must be installed for pacuar, exiting..."

		cd $CURRENT_DIR || exit 1
		rm -r /tmp/pacaur_install
		exit 1
	fi

	# Install pacaur
	install_from_aur_manually pacaur

	cd $CURRENT_DIR || exit 1
	rm -r /tmp/pacaur_install

	log "Completed installing pacaur"
}

is_installed() {
	if [[ -z $(pacman -Qs ^$1$) ]]; then
		return 1
	else
		return 0
	fi
}

install_aur_packages() {
	if ! is_installed pacaur; then
		echo "Pacaur must be installed to install from AUR"
		echo "Please run 'setup.sh pacaur' first, then re-run this"
		exit 1
	fi

	log ""
	log "Attempting to install required packages from AUR:"

	TO_INSTALL=()

	if is_force; then
		TO_INSTALL=${AUR_PACKAGES[@]}
	else
		for p in "${AUR_PACKAGES[@]}"; do
			if is_installed $p; then
				log "$p already installed"
			else
				log "Installing $p"
				TO_INSTALL+=($p)
			fi
		done
	fi

	if [ ${#TO_INSTALL[@]} -gt 0 ]; then
		pacaur -S ${TO_INSTALL[*]} --noconfirm
	fi
}

confirm() {
	if [[ 0 -eq $ASK_CONFIRM ]]; then
		return 0
	fi

	read -p "$1 (y/n)" -n 1 -r
	echo

	if [[ $REPLY =~ ^[Yy]$ ]]; then
		return 0
	fi

	return 1
}

symlink_dotfiles() {
	echo "Setting up symlinks for dotfiles"
	for f in "${FILES[@]}"; do
        if [[ -e $DOTFILES/$f ]] && ( is_force || [[ ! -e ~/$f ]] ); then
			if is_force || confirm "Symlink $DOTFILES/$f to ~/$f?"; then

				log "Creating symlink for ~/$f"

				# Create the parent directory if it doesn't exist
				mkdir -p "$(dirname ~/$f)"

                # If we are forcing, delete target first
                if is_force && [[ -e ~/$f ]]; then
                    rm -rf ~/$f
                fi

				ln -s $DOTFILES/$f ~/$f
			fi
		else
			log "$HOME/$f already exists or doesn't exist in the repository, skipping..."
		fi
	done
}

setup_mutt() {
	local MUTT_CONFIG_SOURCE=$DOTFILES/exampleimapconfig
	local MUTT_CONFIG=~/.mutt/imapconfig

	mkdir -p ~/.mutt/tmp

	log "Setting up mutt"

	if [ ! -f $MUTT_CONFIG ]; then
		read -p "Mail Domain: " -r
		DOMAIN=$REPLY

		read -p "Username: " -r
		USERNAME=$REPLY

		read -p "Password: " -r
		PASSWORD=$REPLY

		read -p "Real Name: " -r
		NAME=$REPLY

		read -p "Sent Folder [Sent]: " -r
		SENT=${REPLY:-Sent}

		read -p "Drafts Folder [Drafts]: " -r
		DRAFTS=${REPLY:-Drafts}

		read -p "Trash folder [Trash]: " -r
		TRASH=${REPLY:-Trash}

		sed -e "s/\$DOMAIN/$DOMAIN/g; s/\$USERNAME/$USERNAME/g; s/\$PASSWORD/$PASSWORD/g; s/\$NAME/$NAME/g; s/\$SENT/$SENT/g; s/\$DRAFTS/$DRAFTS/g; s/\$TRASH/$TRASH/g" $MUTT_CONFIG_SOURCE > $MUTT_CONFIG

		# Remove read permissions for everyone else
		chmod 0700 $MUTT_CONFIG
	else
		log "$MUTT_CONFIG already exists! Remove this file first to enable mutt setup"
	fi
}

install_packages() {
	log ""
	log "Attempting to install required packages:"

	TO_INSTALL=()

	if is_force; then
		TO_INSTALL=PACKAGES
	else
		for p in "${PACKAGES[@]}"; do
			if is_installed $p; then
				log "$p already installed"
			else
				log "Installing $p"
				TO_INSTALL+=($p)
			fi
		done
	fi

	if [ ${#TO_INSTALL[@]} -gt 0 ]; then
		sudo pacman -S ${TO_INSTALL[*]} --noconfirm
	fi
}

setup_wallpapers() {
	log "Copying wallpapers..."

	mkdir -p ~/.wallpapers

	for wp in $DOTFILES/images/wallpapers/*; do
		wp=$(basename $wp)
		if is_verbose; then
			log "Linking $DOTFILES/images/wallpapers/$wp to ~/.wallpapers/$wp"
		fi
		ln -s $DOTFILES/images/wallpapers/$wp ~/.wallpapers/$wp
	done
}

setup_ohmyzsh() {
    log "Installing ohmyzsh"

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

setup_i3() {
    echo "Setting up i3"
    I3_TARGET=".config/i3/config"
    I3_FILES=$(find .config/i3/ -name "*-all.config" -o -name "*-`hostname`.config")
    echo -e "#########################################\n# Combined using github.com/laxd/dotfiles setup on `date`\n#########################################" > $I3_TARGET

    for config in "${I3_FILES[@]}"; do
        echo "Using $config"
        echo -e "\n################### $config ###################\n" >> $I3_TARGET
        cat $config >> $I3_TARGET
    done
}

ASK_CONFIRM=1
VERBOSE=1
FORCE=1
DOTFILES=$(pwd)

DO_DOTFILES=1
DO_MUTT=1
DO_PACKAGES=1
DO_AUR_PACKAGES=1
DO_SETUP_WALLPAPERS=1
DO_INSTALL_PACAUR=1
DO_OH_MY_ZSH_SETUP=1
DO_INSTALL_I3=1

while getopts ":AacdfhiImpvwz" opt; do
	case $opt in
		A)
			DO_AUR_PACKAGES=0
			DO_DOTFILES=0
			DO_INSTALL_PACAUR=0
			DO_MUTT=0
			DO_PACKAGES=0
			DO_SETUP_WALLPAPERS=0
			DO_INSTALL_I3=0
			;;
		a)
			DO_AUR_PACKAGES=0
			;;
		c)
			ASK_CONFIRM=0
			;;
		d)
			DO_DOTFILES=0
			;;
		f)
			FORCE=0
			;;
		h)
			usage
			exit;;
		i)
			DO_INSTALL_PACAUR=0
			;;
		I)
			DO_INSTALL_I3=0
			;;
		m)
			DO_MUTT=0
			;;
		p)
			DO_PACKAGES=0
			;;
		v)
			VERBOSE=0
			;;
		w)
			DO_SETUP_WALLPAPERS=0
			;;
    z)
        DO_OH_MY_ZSH_SETUP=0
        ;;
		\?)
			echo "Invalid option : -$OPTARG"
			exit 2;;
	esac
done

[[ $DO_OH_MY_ZSH_SETUP == 0 ]] && setup_ohmyzsh
[[ $DO_INSTALL_I3 == 0 ]] && setup_i3
[[ $DO_DOTFILES == 0 ]] && symlink_dotfiles
[[ $DO_MUTT == 0 ]] && setup_mutt
[[ $DO_PACKAGES == 0 ]] && install_packages
[[ $DO_INSTALL_PACAUR == 0 ]] && install_pacaur
[[ $DO_AUR_PACKAGES == 0 ]] && install_aur_packages
[[ $DO_SETUP_WALLPAPERS == 0 ]] && setup_wallpapers

echo Done!
