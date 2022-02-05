#!/usr/bin/bash
set -eu

# This will import the required GPG keys to the build user's keychain. You can
# comment out the lines for keys that you already possess.

KEYS=(
  # Signature                                # Name/Email                       # Package
  'ABAF11C65A2970B130ABE3C479BE3E4300411886' # Linus Torvalds                   linux
  '647F28654894E3BD457199BE38DBBDC86092693E' # Greg Kroah-Hartman               linux
  '7273542B39962DF7B299931416792B4EA25340F8' # Carlos O'Donell                  glibc
  'BC7C7372637EC10C57D7AA6579C43DFBF1CF2187' # Siddhesh Poyarekar               glibc
  '3A24BC1E8FB409FA9F14371813FCEF89DD9E3C4F' # Nick Clifton                     binutils
  'F3691687D867B81B51CE07D9BBE43771487328A9' # bpiotrowski@archlinux.org        gcc
  '86CFFCA918CF3AF47147588051E8B148A9999C34' # evangelos@foutrelis.com          gcc
  '13975A70E63C361C73AE69EF6EEB81F8981C74C7' # richard.guenther@gmail.com       gcc
  'D3A93CAD751C2AF4F8C7AD516C35B99309B5FA62' # Jakub Jelinek <jakub@redhat.com> gcc
)

# Receiving keys from GPG servers can be flaky. You may need to try the same
# server multiple times or wait a random period of time. Try them until you find
# one that works.

SERVER=keyserver.ubuntu.com
# SERVER=pool.sks-keyservers.net
# SERVER=pgpkeys.mit.edu
# SERVER=pgp.mit.edu

for key in "${KEYS[@]}"; do
  gpg --keyserver "$SERVER" --recv-keys "$key"
done
