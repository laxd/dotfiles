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

def install_from_aur_manually(package):
    if not is_installed("git"):
        call(["sudo", "pacman", "--noconfirm", "-S", "git"])

    call(["curl", "-o", "/tmp/PKGBUILD", "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h={}".format(package), "-O"])
    call(["makepkg", "/tmp/PKGBUILD", "--skippgpcheck"])

    return call(["sudo", "pacman", "-U", "/tmp/{}*.xz", "--noconfirm"])

packages=["git", "binutils", "gcc", "make", "fakeroot", "tmux", "i3", "xscreensaver", "newsbeuter", "rxvt-unicode", "urxvt-perls", "scrot", "feh", "base-devel", "expac", "sysstat", "imagemagick", "xautolock", "dex", "zsh"]
aur_packages=["neofetch", "neomutt", "py3status", "urxvt-resize-font-git"]
dotfiles=[".zshrc", ".xinitrc", ".xprofile", ".gitconfig", ".gitignore_global", ".vimrc", ".gradle", ".muttrc", ".tmux.conf", ".vnc/xstartup", ".config/i3/config", ".config/i3/lock.sh", ".config/i3/lock.png", ".config/i3status/config", ".config/neofetch/config", ".newsbeuter/urls", ".xscreensaver", ".Xdefaults", ".config/fontconfig/fonts.conf"]

parser = argparse.ArgumentParser()
parser.add_argument("-A", "--all", help="Perform a full setup including ALL options. Equivalent to -dpPawi", action="store_true")
# parser.add_argument("-c", "--confirm", help="Confirm actions", action="store_true")
parser.add_argument("-d", "--dotfiles", help="Symlink dotfiles", action="store_true")
parser.add_argument("-f", "--force", help="Overwrite files, even if they exist, or in the case of packages, reinstall them if they are installed", action="store_true")
parser.add_argument("-P", "--install-pacaur", help="Install pacaur", action="store_true")
parser.add_argument("-i", "--configure-i3", help="Configure i3", action="store_true")
# parser.add_argument("-m", "--configure-mutt", help="Configure Mutt", action="store_true")
parser.add_argument("-p", "--install-packages", help="Install packages", action="store_true")
parser.add_argument("-a", "--install-aur-packages", help="Install AUR packages. If pacaur is not installed, implies --install-pacaur option", action="store_true")
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

if args.install_pacaur or args.all:
    logging.info("Installing pacaur")
    if not is_installed("cower"):
        install_from_aur_manually("cower")

    install_from_aur_manually("pacaur")

if args.dotfiles or args.all:
    logging.info("Symlinking dotfiles")

    for dotfile in dotfiles:
        source="{}/{}".format(os.getcwd(), dotfile)
        target="$HOME/{}".format(dotfile)

        if not open(source, "r").exists:
            logging.error("{} doesn't exist in repository".format(source))
            continue

        # Create parent dir first, just in case it doesn't exist.
        target_dir=call(["dirname", target]).stdout
        call(["mkdir", "-p", target_dir])

        if open(dotfile, "r").exists and args.force:
            logging.debug("Overwriting {}".format(target))
            call(["rm", "-f", target])

        if not open(target, "r").exists:
            logging.debug("Symlinking {}->{}".format(target, source))
            call(["ln", "-s", source, target])
        else:
            logging.debug("{} already exists")

if args.install_packages or args.all:
    logging.info("Installing packages")
    install_targets = [package for package in packages if not is_installed(package) or args.force]

    if install_targets:
        logging.debug("Found packages to install: {}".format(", ".join(install_targets)))
        call(["sudo", "pacman", "--noconfirm", "-S"] + install_targets)

if args.install_aur_packages or args.all:
    logging.info("Installing AUR Packages")
    install_targets = [package for package in aur_packages if not is_installed(pacakge) or args.force]

    if install_targets:
        logging.debug("Installing packages: {}".format(", ".join(install_targets)))
        call(["sudo", "pacaur", "--noconfirm", "-S"] + install_targets)

logging.info("Done!")
