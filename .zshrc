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
	mkdir -p $2 && rmdir $2 && mv $1 $2 && ln -s $1 $2
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

exec_in_background cleanup_downloads
neofetch
