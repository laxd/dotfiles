#! /bin/bash

FILES=( .gitconfig .gitignore_global .vimrc .gradle )
DOTFILES=$(pwd)

for f in ${FILES[@]}; do
	echo ln -s $DOTFILES/$f ~/$f
done

cp $DOTFILES/exampleimapconfig ~/.mutt/imapconfig
echo "Don't forget to update ~/.mutt/imapconfig with your email settings!"
