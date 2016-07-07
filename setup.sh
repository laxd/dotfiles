#! /bin/bash

FILES=( .xinitrc .Xmodmap .gitconfig .gitignore_global .vimrc .gradle .muttrc .tmux.conf .vnc/xstartup .config/i3/config .config/i3/lockimage.png .config/neofetch/config )
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

echo Done!
