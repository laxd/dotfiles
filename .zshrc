# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# Name of the theme to load (from ~/.oh-my-zsh/themes)
ZSH_THEME="gallois"

# Plugins to load (from ~/.oh-my-zsh/plugins)
plugins=(git cp docker pip archlinux systemd)

##### User configuration

# Set up path
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:$HOME/bin:/opt/gradle/bin"

source $ZSH/oh-my-zsh.sh

export EDITOR='vim'

# Aliases
alias open="xdg-open"
alias tojson="python -m json.tool"

# Functions
mvln() {
	mkdir -p $2 && rmdir $2 && mv $1 $2 && ln -s $2 $1
}

cleanup_downloads() {
	file=~/.cleanup.socket
	last_run=$(date -r $file +%Y%m%d 2>/dev/null )
	now=$(date +%Y%m%d )

	if [ -d ~/Downloads ] && [[ $now -gt $last_run ]]; then
		echo "Cleaning up downloads..."
		find ~/Downloads -mtime +30 -exec rm -rf ~/Downloads/{} \;
		touch $file
	fi
}

exec_in_background() {
	($1 &) &> /dev/null
}

exec_in_background cleanup_downloads
neofetch
