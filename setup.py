#!/usr/bin/env python
import argparse
import glob
import socket
import os
import logging
from subprocess import call

def merge_files(output, patterns=[], comment="#"):
    filenames = []
    for pattern in patterns:
        filenames.extend(glob.glob(pattern))

    logging.debug("Found {} from patterns: {}".format(", ".join(filenames), ", ".join(patterns)))

    open(output, 'w').close()
    config = open(output, 'a')

    config.write("{}\n{} Combined using github.com/laxd/dotfiles setup\n{}\n".format(comment*40, comment, comment*40))

    for file_name in filenames:
        file = open(file_name, "r")
        config.write("\n{} {} {}\n\n".format(comment*15, file.name, comment*15))
        config.write(file.read())
        file.close()

    config.close()
    logging.debug("Finished writing {}".format(output))

def is_installed(package):
    is_installed = not call(["pacman", "-Qs", "^{}$".format(package)])
    logging.debug("{} installed? {}".format(package, is_installed))
    return is_installed

packages=["git", "binutils", "gcc", "make", "fakeroot", "tmux", "i3", "xscreensaver", "newsbeuter", "rxvt-unicode", "urxvt-perls", "scrot", "feh", "base-devel", "expac", "sysstat", "imagemagick", "xautolock", "dex", "zsh"]
dotfiles=[".zshrc", ".xinitrc", ".xprofile", ".gitconfig", ".gitignore_global", ".vimrc", ".gradle", ".muttrc", ".tmux.conf", ".vnc/xstartup", ".config/i3/config", ".config/i3/lock.sh", ".config/i3/lock.png", ".config/i3status/config", ".config/neofetch/config", ".newsbeuter/urls", ".xscreensaver", ".Xdefaults", ".config/fontconfig/fonts.conf"]

parser = argparse.ArgumentParser()
parser.add_argument("-A", "--all", help="Perform a full setup including ALL options", action="store_true")
parser.add_argument("-a", "--aur", help="Install AUR packages", action="store_true")
# parser.add_argument("-c", "--confirm", help="Confirm actions", action="store_true")
parser.add_argument("-d", "--dotfiles", help="Symlink dotfiles", action="store_true")
# parser.add_argument("-f", "--force", help="Overwrite files, even if they exist", action="store_true")
parser.add_argument("-P", "--install-pacaur", help="Install pacaur", action="store_true")
parser.add_argument("-i", "--configure-i3", help="Configure i3", action="store_true")
parser.add_argument("-m", "--configure-mutt", help="Configure Mutt", action="store_true")
parser.add_argument("-p", "--install-packages", help="Install packages", action="store_true")
parser.add_argument("-v", "--verbose", help="Increase logging", action="count", default=0)
parser.add_argument("-w", "--wallpapers", help="Copy wallpapers", action="store_true")
args = parser.parse_args()

if args.verbose == 0:
    logging.basicConfig(level=logging.WARNING, format='%(message)s')
elif args.verbose == 1:
    logging.basicConfig(level=logging.INFO, format='%(message)s')
elif args.verbose >= 2:
    logging.basicConfig(level=logging.DEBUG, format='%(message)s')

if args.configure_i3 or args.all:
    logging.info("Configuring i3")
    merge_files(".config/i3/config", [".config/i3/*-all.config", ".config/i3/*-{}.config".format(socket.gethostname())])

if args.dotfiles or args.all:
    logging.info("Symlinking dotfiles")

    for dotfile in dotfiles:
        # Create parent dir first
        call(["mkdir", "-p", "\"$(dirname $HOME/{})\"".format(dotfile)])
        call(["ln", "-s", "{}/{}".format(os.getcwd(), dotfile), "$HOME/{}".format(dotfile)])

if args.install_packages or args.all:
    print("Installing packages")
    install_targets = [package for package in packages if not is_installed(package)]

    if install_targets:
        print("Found packages to install: {}".format(", ".join(install_targets)))
        call(["sudo", "pacman", "--noconfirm", "-S"] + install_targets)

print("Done!")
