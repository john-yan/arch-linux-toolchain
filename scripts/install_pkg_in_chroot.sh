#!/usr/bin/bash
set -eu

REPO=staging
ARCH=$(uname -m)
while getopts 'r:' flag; do
  case "$flag" in
    r)
      REPO=$OPTARG
      ;;
  esac
done
shift $((OPTIND - 1))

pacman -U --root /var/lib/archbuild/$REPO-$ARCH/${SUDO_USER:-$USER} "$@"
