# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# Name of the theme to load (from ~/.oh-my-zsh/themes)
ZSH_THEME="gallois"

# Plugins to load (from ~/.oh-my-zsh/plugins)
plugins=(git cp jump extract mvn gradle ant docker pip archlinux systemd)

##### User configuration

# Set up path
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:$HOME/bin"

if command -v ruby > /dev/null 2>&1; then
	export PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"
fi

export PATH="/opt/gradle/bin:$PATH"

source $ZSH/oh-my-zsh.sh

export EDITOR='vim'

# You may need to manually set your language environment
export LANG=en_GB.UTF-8
setxkbmap gb

# Aliases
alias open="xdg-open"
alias tojson="python -m json.tool"
alias docker_rmi_untagged="docker rmi $(docker images | grep '<none>' | awk '{print $3}')"

# Functions
mvln() {
	mkdir -p $2 && rmdir $2 && mv $1 $2 && ln -s $2 $1
}

tmux_create_if_no_exists() {
	if [[ ! `tmux list-sessions 2>/dev/null | cut -f1 -d: | grep ^$1$` ]]; then
		sh -c "tmux new-session -d -s '$1' '$2'"
	fi
}

cleanup_downloads() {
	find ~/Downloads -mtime +30 -exec rm -rf ~/Downloads/{} \;
}
up() {
	if [[ "$#" < 1 ]] ; then
		cd ..
	else
		CDSTR=""
		for i in {1..$1} ; do
			CDSTR="../$CDSTR"
		done
		cd $CDSTR
	fi
}

export TZ='Europe/London'

neofetch
cleanup_downloads

# Setup some Tmux panes
tmux_create_if_no_exists 'htop' 'htop'
tmux_create_if_no_exists 'logs' 'journalctl -f'
