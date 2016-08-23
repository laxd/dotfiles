#! /bin/bash

usage() {
	echo "$0 [-Aacdfhimpvw]"
	echo " -A perform a full setup of ALL options"
	echo " -a install required AUR packages"
	echo " -c Ask for confirmation before changing anything"
	echo " -d symlink dotfiles"
	echo " -f force - Overwrite files even if they exist - USE WITH CAUTION"
	echo " -h Print this help text"
	echo " -i install pacaur"
	echo " -m setup mutt"
	echo " -p install required packages"
	echo " -v verbose"
	echo " -w copy wallpapers"
}

is_verbose() {
	return $VERBOSE
}

is_force() {
	return $FORCE
}

log() {
	if is_verbose; then
		echo $*
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
	cd /tmp/pacaur_install


	# Git is required for aur installs
	if ! is_installed git; then
		sudo pacman -S git --noconfirm
	fi

	# Install cower
	if ! install_from_aur_manually cower; then
		echo "Cower must be installed for pacuar, exiting..."

		cd $CURRENT_DIR
		rm -r /tmp/pacaur_install
		exit 1
	fi

	# Install pacaur
	install_from_aur_manually pacaur

	cd $CURRENT_DIR
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
		for p in ${AUR_PACKAGES[@]}; do
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
	for f in ${FILES[@]}; do
		if [[ ! -e ~/$f ]]; then
			if confirm "Symlink $DOTFILES/$f to ~/$f?"; then

				log "Creating symlink for ~/$f"

				# Create the parent directory if it doesn't exist
				mkdir -p $(dirname ~/$f)
				ln -s $DOTFILES/$f ~/$f
			fi
		else
			log "~/$f already exists, skipping..."
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
		TO_INSTALL=${PACKAGES[@]}
	else
		for p in ${PACKAGES[@]}; do
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

ASK_CONFIRM=1
VERBOSE=1
FORCE=1
FILES=( .zshrc .xinitrc .Xmodmap .gitconfig .gitignore_global .vimrc .gradle .muttrc .tmux.conf .vnc/xstartup .config/i3/config .config/neofetch/config .newsbeuter/urls .xscreensaver )
PACKAGES=( git tmux i3 xscreensaver newsbeuter terminator scrot feh base-devel expac )
AUR_PACKAGES=( neofetch )
DOTFILES=$(pwd)

DO_DOTFILES=1
DO_MUTT=1
DO_PACKAGES=1
DO_AUR_PACKAGES=1
DO_SETUP_WALLPAPAERS=1
DO_INSTALL_PACAUR=1

while getopts ":Aacdfhimpvw" opt; do
	case $opt in
		A)
			DO_AUR_PACKAGES=0
			DO_DOTFILES=0
			DO_INSTALL_PACAUR=0
			DO_MUTT=0
			DO_PACKAGES=0
			DO_SETUP_WALLPAPERS=0
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
		\?)
			echo "Invalid option : -$OPTARG"
			exit 2;;
	esac
done

[[ $DO_DOTFILES == 0 ]] && symlink_dotfiles
[[ $DO_MUTT == 0 ]] && setup_mutt
[[ $DO_PACKAGES == 0 ]] && install_packages
[[ $DO_INSTALL_PACAUR == 0 ]] && install_pacaur
[[ $DO_AUR_PACKAGES == 0 ]] && install_aur_packages
[[ $DO_SETUP_WALLPAPERS == 0 ]] && setup_wallpapers

echo Done!
