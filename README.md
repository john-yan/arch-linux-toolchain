---
title: README
author: Xyne
date: 2022-02-06T05:37:44+00:00
---

# About

At the time of writing, the Arch Linux toolchain has been out-of-date for several months with known security vulnerabilities. There is an ongoing [discussion about this on the Arch Linux forum](https://bbs.archlinux.org/viewtopic.php?id=270662). There is also an [open issue about reproducible toolchain builds](https://bugs.archlinux.org/task/70954).

This is intended to be a starting point for a collaborative effort to remedy the situation. The goal is to provide a working bootstrap script that can build the full toolchain in an Arch Linux devtool's chroot and pass all tests while ignoring false negatives.

Check the Git log for information about applied patches.

The [bootstrap script](scripts/bootstrap.sh) is a modified version of the one that [Allan posted on the forum](https://bbs.archlinux.org/viewtopic.php?pid=2020328#p2020328). Allan also has a [Git repository with an alternative Arch Linux toolchain](https://github.com/allanmcrae/toolchain) but with some significant changes that are unsuitable for the official repos (no multilib, no Ada, D or ObjC).

# Usage

Run the [bootstrap script](scripts/bootstrap.sh) in an empty directory to copy the PKGBUILDs and related files into a new build directory. When it fails, try to understand why and fix it. If it succeeds, rejoice and find a way to get the new toolchain into the official testing repo.

## Dependencies

* bash
* devtools
* rsync


# TODO

* A working automatic bootstrap process for the toolchain, preferably via a CI pipeline. I need to check what the current plan is for build automation using the Arch Linux infrastructure and make it compatible with that.
* Multilib support.
* Support all languages currently supported by the official toolchain.
* Merge gcc-libs back into gcc to avoid having to split the package in the PKGBUILD (cmp. Allan's toolchain)
* Keep the minimum supported kernel version at 4.4.
* Update to the latest released versions.
* Create a systemtap package and make it a dependency of glibc (see Allan's readme).
* Move libiberty back to binutils.
* Drop libcrypt.so.1 support from glibc.


# Disclaimer

This is very much a work in progress and I am completely new to building the toolchain. Even if the bootstrap script succeeds, there is no guarantee that the resulting packages will be suitable for use. Use them at your own risk. I do not recommend it and I accept no liability. Keep a rescue medium handy if you do.

# Troubleshooting

## Reinstall a package in the chroot without re-initializing it

A failure in the bootstrap script can leave the chroot unable to build packages. You can re-install a previously built package from the bootstrap sequence with the following command:

~~~sh
pacman -U --root /var/lib/archbuild/<repo>-<arch>/<user> <package file>
~~~

This should only be done to debug a build. The entire bootstrap sequence should succeed without manual intervention for it to be considered correct.
