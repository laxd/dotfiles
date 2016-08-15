#! /bin/bash

usage() {
	echo "$0 [dotfiles|mutt|packages|aur_packages|wallpapers|pacaur] [-a]"
	echo "    dotfiles - Create symlinks for all dotfiles and exit"
	echo "    mutt - Setup mutt"
	echo "    packages - Install all required packages and exit"
	echo "    aur_packages - Install cower and pacaur (if required), then install all required AUR packages and exit"
	echo "    wallpapers - Install wallpapers to ~/.wallpapers"
	echo "    pacaur - Install pacaur (pre-requisite for aur_packages)"
	echo ""
	echo " -a Ask for confirmation before changing anything. I.e. before each dotfile is linked, before any packages are downloaded etc."
	echo " -h Print this help text"
}

install_from_aur_manually() {
	
	if ! confirm "Install $1 from AUR?"; then
		return 1
	fi

	# Check it's already installed
	if ! is_installed $1; then
		curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$1
		makepkg PKGBUILD --skippgpcheck
		sudo pacman -U $1*.xz --noconfirm
	else 
		echo "$1 is already installed"
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
		sudo pacman -S git
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

	echo "Completed installing pacaur"
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

	echo ""
	echo "Attempting to install required packages from AUR:"

	TO_INSTALL=()

	for p in ${AUR_PACKAGES[@]}; do
		if is_installed $p; then
			echo "$p already installed"
		else
			echo $p
			TO_INSTALL+=($p)
		fi
	done

	if [ ${#TO_INSTALL[@]} -gt 0 ]; then
		pacaur -S ${TO_INSTALL[*]}
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

				echo Creating symlink for ~/$f

				# Create the parent directory if it doesn't exist
				mkdir -p $(dirname ~/$f)
				ln -s $DOTFILES/$f ~/$f
			fi
		else
			echo "~/$f already exists, skipping..."
		fi
	done
}

setup_mutt() {
	mkdir -p ~/.mutt/tmp

	if [ ! -f ~/.mutt/imapconfig ]; then
		cp $DOTFILES/exampleimapconfig ~/.mutt/imapconfig
		echo "Don't forget to update ~/.mutt/imapconfig with your email settings!"
	fi
}

install_packages() {
	echo ""
	echo "Attempting to install required packages:"

	TO_INSTALL=()

	for p in ${PACKAGES[@]}; do
		if is_installed $p; then
			echo "$p already installed"
		else
			echo $p
			TO_INSTALL+=($p)
		fi
	done

	if [ ${#TO_INSTALL[@]} -gt 0 ]; then
		sudo pacman -S ${TO_INSTALL[*]}
	fi
}

setup_wallpapers() {
	echo "Setting up wallpapers etc"
	mkdir -p ~/.wallpapers
	cp $DOTFILES/images/wallpapers/* ~/.wallpapers/
}

ASK_CONFIRM=0
FILES=( .zshrc .xinitrc .Xmodmap .gitconfig .gitignore_global .vimrc .gradle .muttrc .tmux.conf .vnc/xstartup .config/i3/config .config/neofetch/config .newsbeuter/urls .xscreensaver )
PACKAGES=( git tmux i3 xscreensaver newsbeuter terminator scrot feh )
AUR_PACKAGES=( neofetch )
DOTFILES=$(pwd)

while getopts ":ah" opt; do
	case $opt in
		a)
			ASK_CONFIRM=1
			;;
		h)
			usage
			exit;;
		\?)
			echo "Invalid option : -$OPTARG"
			;;
	esac
done

shift $(($OPTIND -1))
ARGUMENTS=$*

[[ -z $ARGUMENTS ]] && ARGUMENTS="dotfiles mutt packages aur_packages wallpapers pacaur"

DO_DOTFILES=1
DO_MUTT=1
DO_PACKAGES=1
DO_AUR_PACKAGES=1
DO_SETUP_WALLPAPAERS=1
DO_INSTALL_PACAUR=1

for arg in $ARGUMENTS; do
	[[ $arg == "dotfiles" ]] && DO_DOTFILES=0
	[[ $arg == "mutt" ]] && DO_MUTT=0
	[[ $arg == "packages" ]] && DO_PACKAGES=0
	[[ $arg == "aur_packages" ]] && DO_AUR_PACKAGES=0
	[[ $arg == "wallpapers" ]] && DO_SETUP_WALLPAPERS=0
	[[ $arg == "pacaur" ]] && DO_INSTALL_PACAUR=0
done

[[ $DO_DOTFILES == 0 ]] && symlink_dotfiles
[[ $DO_MUTT == 0 ]] && setup_mutt
[[ $DO_PACKAGES == 0 ]] && install_packages
[[ $DO_INSTALL_PACAUR == 0 ]] && install_pacaur
[[ $DO_AUR_PACKAGES == 0 ]] && install_aur_packages
[[ $DO_SETUP_WALLPAPERS == 0 ]] && setup_wallpapers

echo Done!
