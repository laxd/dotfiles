#!/usr/bin/env python
import argparse
import glob
import socket

def merge_files(output, patterns=[], comment="#"):
    filenames = []
    for pattern in patterns:
        filenames.extend(glob.glob(pattern))

    open(output, 'w').close()
    config = open(output, 'a')

    config.write("{}\n{} Combined using github.com/laxd/dotfiles setup\n{}\n".format(comment*40, comment, comment*40))

    for file_name in filenames:
        file = open(file_name, "r")
        config.write("\n{} {} {}\n\n".format(comment*15, file.name, comment*15))
        config.write(file.read())
        file.close()

    config.close()

parser = argparse.ArgumentParser()
parser.add_argument("-A", "--all", help="Perform a full setup including ALL options", action="store_true")
parser.add_argument("-a", "--aur", help="Install AUR packages", action="store_true")
parser.add_argument("-c", "--confirm", help="Confirm actions", action="store_true")
parser.add_argument("-d", "--dotfiles", help="Symlink dotfiles", action="store_true")
parser.add_argument("-f", "--force", help="Overwrite files, even if they exist", action="store_true")
parser.add_argument("-P", "--install-pacaur", help="Install pacaur", action="store_true")
parser.add_argument("-i", "--i3", help="Configure i3", action="store_true")
parser.add_argument("-m", "--configure-mutt", help="Configure Mutt", action="store_true")
parser.add_argument("-p", "--install-packages", help="Install packages", action="store_true")
parser.add_argument("-v", "--verbose", help="Increase logging", action="store_true")
parser.add_argument("-w", "--wallpapers", help="Copy wallpapers", action="store_true")
args = parser.parse_args()

if args.i3:
    print("Configuring i3")
    merge_files(".config/i3/config", [".config/i3/*-all.config", ".config/i3/*-{}.config".format(socket.gethostname())])

print("Done!")
