#! /bin/bash

FILES=( .gitconfig .gitignore_global .vimrc .gradle .muttrc .tmux.conf )
DOTFILES=$(pwd)

echo "Setting up symlinks for dotfiles..."
for f in ${FILES[@]}; do
	if [ ! -e ~/$f ]; then
		echo Creating symlink for $f
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
