#!/usr/bin/env python
import argparse
import glob
import socket
import os
import sys
import logging
from subprocess import call


def symlink_dotfiles():
    dotfiles = [".gradle",
                ".muttrc",
                ".tmux.conf",
                ".vnc/xstartup",
                ".config/neofetch/config",
                ".newsbeuter/urls",
                ".xscreensaver",
                ".config/fontconfig/fonts.conf"]

    for dotfile in dotfiles:
        symlink(dotfile)


def install_packages():
    logging.info("Installing packages...")
    install(["git",
             "openssh",
             "tmux",
             "xscreensaver",
             "newsbeuter",
             "scrot",
             "feh",
             "sysstat",
             "imagemagick",
             "xautolock",
             "rofi",
             "dex"],
            aur=False)

    if is_installed("pacaur"):
        install(["neofetch"],
            aur=True)


def configure_mutt():
    mutt_config_dotfile="exampleimapconfig"
    mutt_config="~/.mutt/imapconfig"

    os.makedirs("~/.mutt/tmp", exist_ok=True)

    logging.info("Setting up mutt")

    if not os.path.isfile(mutt_config):
        sys.stdout.write("Mail Domain:")
        domain = input()

        sys.stdout.write("Username:")
        username = input()

        sys.stdout.write("Password:")
        password = input()

        sys.stdout.write("Real Name:")
        name = input()

        sys.stdout.write("Sent Folder [Sent]:")
        sent_folder = input()

        sys.stdout.write("Drafts Folder [Drafts]")
        drafts_folder = input()

        sys.stdout.write("Trash Folder [Trash]")
        trash_folder = input()

        f = open(mutt_config_dotfile, 'r')
        data = f.read()
        f.close()

        data = data.replace("$DOMAIN", domain)
        data = data.replace("$USERNAME", username)
        data = data.replace("$PASSWORD", password)
        data = data.replace("$NAME", name)
        data = data.replace("$SENT", sent_folder)
        data = data.replace("$DRAFTS", drafts_folder)
        data = data.replace("$TRASH", trash_folder)

        f = open(mutt_config, 'w')
        f.write(data)
        f.close()

        os.chmod(mutt_config, 700)
    else:
        logging.error(mutt_config + " already exists! Remove this file to enable mutt setup")


def configure_vim():
    install(["vim"])
    symlink(".vimrc")
    call(["vim", "-c", "VundleUpdate", "-c", "quitall"])


def configure_i3():
    logging.info("Installing i3")
    install(["i3", "dmenu", "rxvt-unicode", "urxvt-perls"])
    install(["urxvt-resize-font-git", "py3status"], aur=True)
    merge_files(output=".config/i3/config", pattern=".config/i3/*-{}.config")
    symlink(".config/i3/config")
    symlink(".config/i3status/config")
    symlink(".config/i3/lock.sh")
    symlink(".config/i3/lock.png")
    symlink(".Xdefaults")


def configure_zsh():
    install(["zsh"])
    symlink(".zshrc")
    call("sh -c \"$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)\"", shell=True)


def configure_pacaur():
    install(["git", "make", "fakeroot", "binutils", "gcc", "pkg-config", "expac", "yajl"])
    install_from_aur_manually("cower")
    install_from_aur_manually("pacaur")


def configure_git():
    install(["git"])
    symlink(".gitconfig")
    symlink(".gitignore_global")


def configure_x():
    merge_files(output=".xprofile")
    symlink(".xprofile")
    symlink(".xinitrc")


def configure_dev():
    # Docker
    install(["docker", "docker-compose"], aur=False)

    # Java
    install(["jdk8"], aur=True)

    # Python
    install(["python-pip"])

    # IDEs
    install(["brackets", "jetbrains-toolbox", "intellij-idea-ultimate-edition", "pycharm-professional", "android-studio"], aur=True)


def configure_photography():
    install(["darktable"])

def confirm(text, values={"Y": True,"N": False}):
    while True:
        sys.stdout.write("{} [{}]".format(text, "/".join(values)))
        choice = input().upper()

        if choice in values.keys():
            return values[choice]
        else:
            sys.stdout.write("Invalid selection, please enter one of {}\n".format(", ".join(values)))

os_types = {
        "debian": "sudo apt-get install -y"
        }

os = "debian"

def install(package, debian=None, arch=None):
    if os == "debian":
        package = debian
    if os == "arch":
        package = arch

    logging.debug("Installing packages: {}".format(", ".join(install_targets)))
    call(os_types[os] + package)


def merge_files(output, pattern=None, comment="#"):
    """
    Merges all files that match the given pattern into a single output file.

    Mutliple arguments are used to help specify the files to merge:

    all - These files apply to all merges
    hostname - These files will only be picked up if their hostname matches

    Example:

    Given the output file .xprofile, and the machine hostname being zen, the following files will be picked up:

    01-zen.xprofile (as it matches *-zen.xprofile)
    99-all.xprofile (as it matches *-all.xprofile)

    :param output: File that will be created as a result of merging the files
    :param pattern: Pattern to use to match files, a single {} can be used to match
        the argument (i.e. "all", the hostname of the machine).
        MUST be specified if the output file contains a directory (i.e. .config/i3/config)
    :param comment: Character to use for comments
    """
    if pattern is None:
        pattern="*-{}" + output if output.startswith(".") else ("." + output)

    filenames = []
    for arg in ["all", socket.gethostname()]:
        filenames.extend(glob.glob(pattern.format(arg)))

    filenames.sort()

    logging.debug("Found {} from patterns".format(", ".join(filenames)))

    open(output, 'w').close()
    config = open(output, 'a')

    config.write("{}\n{} Combined using github.com/laxd/dotfiles setup\n{}\n".format(comment*40, comment, comment*40))

    for file_name in filenames:
        logging.debug("Including {} in {}".format(file_name, output))
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
        install(["git"])

    call(["curl", "-o", "/tmp/PKGBUILD", "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h={}".format(package), "-O"])
    call(["makepkg", "/tmp/PKGBUILD", "--skippgpcheck"])

    return call(["sudo", "pacman", "-U", "/tmp/{}*.xz", "--noconfirm"])


def symlink(filename, target=None):
    source = "{}/{}".format(os.getcwd(), filename)
    target = os.path.expanduser("~/{}".format(filename) if target is None else target)

    if not os.path.isfile(source):
        logging.error("{} doesn't exist".format(source))
        return

    # Create parent dir first, just in case it doesn't exist.
    os.makedirs(os.path.dirname(target), exist_ok=True)

    if not os.path.isfile(target):
        logging.debug("Symlinking {}->{}".format(target, source))
        os.symlink(source, target)
    else:
        logging.debug("{} already exists".format(target))


parser = argparse.ArgumentParser()
parser.add_argument("-A", "--all", help="Perform a full setup including ALL options. Equivalent to -dpPawi", action="store_true")
# parser.add_argument("-c", "--confirm", help="Confirm actions", action="store_true")
parser.add_argument("-d", "--dotfiles", help="Symlink dotfiles, this will need to be run after each '--configure-*' command", action="store_true")
parser.add_argument("-D", "--configure-dev", help="Install IDEs and setup dev environment", action="store_true")
parser.add_argument("-f", "--force", help="Overwrite files, even if they exist, or in the case of packages, reinstall them if they are installed", action="store_true")
parser.add_argument("-i", "--configure-i3", help="Configure i3, combining the .config/i3/config files", action="store_true")
parser.add_argument("-g", "--configure-git", help="Configure git, combining the .gitconfig files", action="store_true")
parser.add_argument("-x", "--configure-x", help="Configure X, combining the .xprofile files", action="store_true")
parser.add_argument("-z", "--configure-zsh", help="Install zsh, setup oh-my-zsh and copy .zshrc config", action="store_true")
parser.add_argument("-P", "--configure-pacaur", help="Install pacaur, and any required dependencies", action="store_true")
parser.add_argument("-V", "--configure-vim", help="Install vim, including Vundle plugins", action="store_true")
parser.add_argument("-m", "--configure-mutt", help="Configure Mutt", action="store_true")
parser.add_argument("-o", "--configure-photography", help="Configure photography editing environment", action="store_true")
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
    configure_i3()

if args.configure_zsh or args.all:
    configure_zsh()

if args.configure_pacaur or args.all:
    configure_pacaur()

if args.configure_git or args.all:
    configure_git()

if args.configure_x or args.all:
    configure_x()
    
if args.configure_dev or args.all:
    configure_dev()

if args.configure_photography or args.all:
    configure_photography()

if args.configure_vim or args.all:
    configure_vim()

if args.configure_mutt or args.all:
    configure_mutt()

if args.dotfiles or args.all:
    symlink_dotfiles()

if args.install_packages or args.all:
    install_packages()

logging.info("Done!")
