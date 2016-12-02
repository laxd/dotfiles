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
export TERM=rxvt

# Aliases
alias open="xdg-open"
alias tojson="python -m json.tool"

# Functions
mvln() {
	mkdir -p $2 && rmdir $2 && mv $1 $2 && ln -s $2 $1
}

docker_cleanup() {
	docker ps -a | grep 'weeks ago' | awk '{print $1}' | xargs --no-run-if-empty docker rm -v
}

docker_cleanup_images() {
	docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi
}

docker_ps() {
	WIDTH=`tput cols`
	NAMES_WIDTH=$(($WIDTH - 20 - 10))
	docker ps -a --format="table {{printf \"%.20s\" .Names}}\t{{printf \"%.${NAMES_WIDTH}s\" .Image}}\t{{printf \"%.10s\" .Status}}"
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

tmux_create_and_attach() {
	SESSION_NAME=$1
	if [[ $2 ]]; then
		COMMAND=$2
	else
		COMMAND="cd"
	fi

	echo "Command is $COMMAND"

	if [[ ! `tmux list-sessions 2>/dev/null | cut -f1 -d: | grep ^$1$` ]]; then
		echo "Creating session $SESSION_NAME"
		tmux new -d -s $SESSION_NAME $COMMAND
	fi

	echo "Attaching to $SESSION_NAME"

	tmux attach -t $SESSION_NAME
}

exec_in_background cleanup_downloads
neofetch
