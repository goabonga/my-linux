#!/bin/bash
# LFS 12.2 Configuration
# Based on https://www.linuxfromscratch.org/lfs/view/12.2/

set -euo pipefail

export LFS_VERSION="12.2"
export LFS=/mnt/lfs
export LFS_TGT="x86_64-lfs-linux-gnu"
export LFS_SOURCES="$LFS/sources"
export LFS_TOOLS="$LFS/tools"

# Build parallelism
export MAKEFLAGS="-j$(nproc)"

# Package versions (LFS 12.2)
export PKG_ACL="2.3.2"
export PKG_ATTR="2.5.2"
export PKG_AUTOCONF="2.72"
export PKG_AUTOMAKE="1.17"
export PKG_BASH="5.2.32"
export PKG_BC="7.0.3"
export PKG_BINUTILS="2.43.1"
export PKG_BISON="3.8.2"
export PKG_BZIP2="1.0.8"
export PKG_CHECK="0.15.2"
export PKG_COREUTILS="9.5"
export PKG_DEJAGNU="1.6.3"
export PKG_DIFFUTILS="3.10"
export PKG_E2FSPROGS="1.47.1"
export PKG_ELFUTILS="0.191"
export PKG_EXPAT="2.6.2"
export PKG_EXPECT="5.45.4"
export PKG_FILE="5.45"
export PKG_FINDUTILS="4.10.0"
export PKG_FLEX="2.6.4"
export PKG_FLIT_CORE="3.9.0"
export PKG_GAWK="5.3.0"
export PKG_GCC="14.2.0"
export PKG_GDBM="1.24"
export PKG_GETTEXT="0.22.5"
export PKG_GLIBC="2.40"
export PKG_GMP="6.3.0"
export PKG_GPERF="3.1"
export PKG_GREP="3.11"
export PKG_GROFF="1.23.0"
export PKG_GRUB="2.12"
export PKG_GZIP="1.13"
export PKG_IANA_ETC="20240806"
export PKG_INETUTILS="2.5"
export PKG_INTLTOOL="0.51.0"
export PKG_IPROUTE2="6.10.0"
export PKG_JINJA2="3.1.4"
export PKG_KBD="2.6.4"
export PKG_KMOD="33"
export PKG_LESS="661"
export PKG_LIBCAP="2.70"
export PKG_LIBFFI="3.4.6"
export PKG_LIBPIPELINE="1.5.7"
export PKG_LIBTOOL="2.4.7"
export PKG_LIBXCRYPT="4.4.36"
export PKG_LINUX="6.10.5"
export PKG_M4="1.4.19"
export PKG_MAKE="4.4.1"
export PKG_MAN_DB="2.12.1"
export PKG_MAN_PAGES="6.9.1"
export PKG_MARKUPSAFE="2.1.5"
export PKG_MESON="1.5.1"
export PKG_MPC="1.3.1"
export PKG_MPFR="4.2.1"
export PKG_NCURSES="6.5"
export PKG_NINJA="1.12.1"
export PKG_OPENSSL="3.3.1"
export PKG_PATCH="2.7.6"
export PKG_PERL="5.40.0"
export PKG_PKGCONF="2.3.0"
export PKG_PROCPS_NG="4.0.4"
export PKG_PSMISC="23.7"
export PKG_PYTHON="3.12.5"
export PKG_READLINE="8.2.13"
export PKG_SED="4.9"
export PKG_SETUPTOOLS="72.2.0"
export PKG_SHADOW="4.16.0"
export PKG_SYSKLOGD="2.6.1"
export PKG_SYSVINIT="3.10"
export PKG_TAR="1.35"
export PKG_TCL="8.6.14"
export PKG_TEXINFO="7.1"
export PKG_TZDATA="2024a"
export PKG_UDEV_SYSTEMD="256.4"
export PKG_UTIL_LINUX="2.40.2"
export PKG_VIM="9.1.0660"
export PKG_WHEEL="0.44.0"
export PKG_XML_PARSER="2.47"
export PKG_XZ="5.6.2"
export PKG_ZLIB="1.3.1"
export PKG_ZSTD="1.5.6"

# Helper function to extract and enter a source directory
extract_and_cd() {
    local tarball="$1"
    local dir_name="${2:-}"

    cd "$LFS_SOURCES"
    tar -xf "$tarball"

    if [ -z "$dir_name" ]; then
        dir_name=$(tar -tf "$tarball" 2>/dev/null | head -1 | cut -d'/' -f1) || true
    fi

    cd "$dir_name"
    echo "Entered $(pwd)"
}

# Helper function to clean up after building a package
cleanup_pkg() {
    local dir_name="$1"
    cd "$LFS_SOURCES"
    rm -rf "$dir_name"
}
