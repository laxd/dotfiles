#! /bin/bash

is_installed() {
	if [[ -z $(pacman -Qs ^$1$) ]]; then
		return 1
	else
		return 0
	fi
}

FILES=( .zshrc .xinitrc .Xmodmap .gitconfig .gitignore_global .vimrc .gradle .muttrc .tmux.conf .vnc/xstartup .config/i3/config .config/neofetch/config .newsbeuter/urls )
PACKAGES=( git tmux i3 xscreensaver newsbeuter terminator scrot feh )
AUR_PACKAGES=( neofetch )
DOTFILES=$(pwd)

echo "Setting up symlinks for dotfiles..."
for f in ${FILES[@]}; do
	if [ ! -e ~/$f ]; then
		echo Creating symlink for $f

		# Create the parent directory if it doesn't exist
		mkdir -p $(dirname ~/$f)
		ln -s $DOTFILES/$f ~/$f
	else
		echo "~/$f already exists, skipping..."
	fi
done

mkdir -p ~/.mutt/tmp

if [ ! -f ~/.mutt/imapconfig ]; then
	cp $DOTFILES/exampleimapconfig ~/.mutt/imapconfig
	echo "Don't forget to update ~/.mutt/imapconfig with your email settings!"
fi

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

echo "Installing pacaur"

CURRENT_DIR=`pwd`

mkdir -p /tmp/pacaur_install
cd /tmp/pacaur_install


# Git is required for aur installs
if ! is_installed git; then
	sudo pacman -S git
fi

install_from_aur() {
	# Check it's already installed
	if ! is_installed $1; then
		curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$1
		makepkg PKGBUILD --skippgpcheck
		sudo pacman -U $1*.xz --noconfirm
	else 
		echo "$1 is already installed, skipping..."
	fi
}

# Install cower
install_from_aur cower

# Install pacaur
install_from_aur pacaur

cd $CURRENT_DIR
rm -r /tmp/pacaur_install

echo "Pacaur installation complete, installing AUR packages..."

pacaur -S ${AUR_PACKAGES[*]}

echo "Setting up wallpapers etc"
mkdir -p ~/.wallpapers
cp $DOTFILES/images/wallpapers/* ~/.wallpapers/

echo Done!
