#!/usr/bin/bash
set -eu

# This is a modified version of Allan's bootstrap script. It will initialize a
# devtools chroot and bootstrap the toolchain by building the packages in the
# following order:
#
#     linux-api-headers
#     glibc
#     binutils
#     gcc
#     glibc
#     binutils
#     gcc
#
# The checks for glibc, binutils and gcc are deferred to the second pass. Once
# the toolchain is built, this will also rebuild the following packages:
#
#     linux
#     libtools
#     valgrind
#
# It may or may not be necessary to rebuild the latter packages depending on
# which toolchain packages were updated, but it's better to just automate the
# full rebuild and not have to worry about it.
#
# The argument to this script is one of the repo names corresponding to a build
# script in the devtools package. If not given, it defaults to "staging".
#
# Whichever repo is given, it is re-initialized before building
# linux-api-headers. As each package is built, it is installed in the chroot for
# the subsequent builds.
#
# To restart a failed build, comment out the chroot re-initialization line and
# the build commands preceding the failed build command below.

# Use absolute paths to this script and related files so that it can be run
# anywhere.
SELF=$(readlink -f "$BASH_SOURCE")
ROOT_DIR=${SELF%/*/*}
SCRIPT_DIR=${ROOT_DIR}/scripts
PKGBUILD_DIR=${ROOT_DIR}/pkgbuilds

DEFAULT_REPO=staging

# Create a build directory, log and packages directory in the current working
# directory.
BUILD_DIR=$PWD/build
LOG_FILE=$PWD/${SELF##*/}.log
PKG_DIR=$PWD/pkgs

function show_help()
{
  cat <<HELP
Usage
  ${0##*/} [-h] [<chroot name>]"

  <chroot name> defaults to ${DEFAULT_REPO@Q}"

Options
  -h Show this message and exit.
HELP
  exit "${1:-0}"
}

while getopts 'h' flag; do
  case "$flag" in
    h)
      show_help 0
      ;;
  esac
done

REPO=${1:-$DEFAULT_REPO}
ARCH=$(uname -m)
BUILD_CMD=("$REPO-$ARCH-build")
MAKECHROOTPKG_CMD=(sudo --preserve-env=MAKEFLAGS makechrootpkg -r "/var/lib/archbuild/$REPO-$ARCH/" -- -C)

mkdir -p "$BUILD_DIR"
rsync -rtvv "$PKGBUILD_DIR/" "$BUILD_DIR"
cd "$BUILD_DIR"

# Rudimentary log to get an overview of the build progress and duration.
function log() {
  local timestamp=$(date '+%F %R:%S')
  echo "[$timestamp] ${@@Q}" >> "$LOG_FILE"
}

function build() {
  pkgname=$1
  shift 1

  log "Building $pkgname" "$@"

  pushd "$pkgname"
  "${MAKECHROOTPKG_CMD[@]}" "$@"
  # "${BUILD_CMD[@]}" -c
  popd
}

# Move packages to a timestamped subdirectory of the current packages directory.
function move_pkgs() {
  local name=$1
  local pkgname
  shift 1
  pkgdir=$PKG_DIR/$name-$(date '+%Y%m%d%H%M%S')
  mkdir -p "$pkgdir"
  for pkgname in "$@"
  do
    mv -t "$pkgdir" "$BUILD_DIR/$pkgname"/*.pkg.*
  done
}

# Some previous bug required libiberty to be moved from binutils to gcc but the
# change was never reverted after the bug was fixed. This removes the existing
# libiberty files in the chroot and clears them from gcc's file list.
function resolve_libiberty_conflicts() {
  pushd "/var/lib/archbuild/$REPO-$ARCH/$USER"
  sudo rm -fr ./usr/include/libiberty ./usr/lib/libiberty.a
  sudo sed -i '/^usr\/include\/libiberty\//d;/^usr\/lib\/libiberty.a/d' \
    ./var/lib/pacman/local/gcc-*/files
  popd
}


# This will re-initialize the chroot but exit with error 255 because it still
# expects a PKGBUILD to build after the re-initialization. Ignore the error.
log "Re-initializing $REPO-$ARCH"
"${BUILD_CMD[@]}" -c || [[ $? -eq 255 ]]

build linux-api-headers -ir

build glibc -ir --nocheck

# skip install binutils and gcc into the chroot env due to conflicts in libiberty
build binutils -r --nocheck
build gcc -r --nocheck

STAGE1_DIR=/var/lib/archbuild/$REPO-$ARCH/$USER/stage1
sudo mkdir -p $STAGE1_DIR
sudo cp $BUILD_DIR/linux-api-headers/*.zst $STAGE1_DIR/
sudo cp $BUILD_DIR/glibc/*.zst $STAGE1_DIR/
sudo cp $BUILD_DIR/binutils/*.zst $STAGE1_DIR/
sudo cp $BUILD_DIR/gcc/*.zst $STAGE1_DIR/

# remove gcc/binutils and reinstall them in chroot env
arch-nspawn /var/lib/archbuild/staging-x86_64/john pacman -Rs --noconfirm gcc binutils
arch-nspawn /var/lib/archbuild/staging-x86_64/john pacman -U --noconfirm  \
  /stage1/binutils-2.37-1-x86_64.pkg.tar.zst                              \
  /stage1/gcc-11.2.1-1-x86_64.pkg.tar.zst                                 \
  /stage1/gcc-ada-11.2.1-1-x86_64.pkg.tar.zst                             \
  /stage1/gcc-d-11.2.1-1-x86_64.pkg.tar.zst                               \
  /stage1/gcc-fortran-11.2.1-1-x86_64.pkg.tar.zst                         \
  /stage1/gcc-go-11.2.1-1-x86_64.pkg.tar.zst                              \
  /stage1/gcc-libs-11.2.1-1-x86_64.pkg.tar.zst                            \
  /stage1/gcc-objc-11.2.1-1-x86_64.pkg.tar.zst                            \
  /stage1/lib32-gcc-libs-11.2.1-1-x86_64.pkg.tar.zst


# Move the unchecked packages to a separate directory as a checkpoint.
#move_pkgs unchecked glibc binutils gcc
#
build glibc -ir
build binutils -ir
build gcc -ir

#build linux
#build libtools
#build valgrind
