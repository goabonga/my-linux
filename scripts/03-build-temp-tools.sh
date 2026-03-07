#!/bin/bash
# LFS 12.2 - Chapter 6: Cross Compiling Temporary Tools
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "=== Chapter 6: Cross Compiling Temporary Tools ==="

# ============================================================
# 6.2 M4-1.4.19
# ============================================================
echo ">>> Building M4..."
extract_and_cd "m4-${PKG_M4}.tar.xz"
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make
make DESTDIR="$LFS" install
cleanup_pkg "m4-${PKG_M4}"

# ============================================================
# 6.3 Ncurses-6.5
# ============================================================
echo ">>> Building Ncurses..."
extract_and_cd "ncurses-${PKG_NCURSES}.tar.gz"

# Build tic for the host
mkdir build-host && pushd build-host
  ../configure
  make -C include
  make -C progs tic
popd

./configure --prefix=/usr \
            --host="$LFS_TGT" \
            --build="$(./config.guess)" \
            --mandir=/usr/share/man \
            --with-manpage-format=normal \
            --with-shared \
            --without-normal \
            --with-cxx-shared \
            --without-debug \
            --without-ada \
            --disable-stripping
make
make DESTDIR="$LFS" TIC_PATH="$(pwd)/build-host/progs/tic" install
ln -sv libncursesw.so "$LFS/usr/lib/libncurses.so"
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "$LFS/usr/include/curses.h"
cleanup_pkg "ncurses-${PKG_NCURSES}"

# ============================================================
# 6.4 Bash-5.2.32
# ============================================================
echo ">>> Building Bash..."
extract_and_cd "bash-${PKG_BASH}.tar.gz"
./configure --prefix=/usr \
            --build="$(sh support/config.guess)" \
            --host="$LFS_TGT" \
            --without-bash-malloc \
            bash_cv_strtold_broken=no
make
make DESTDIR="$LFS" install
ln -sv bash "$LFS/bin/sh"
cleanup_pkg "bash-${PKG_BASH}"

# ============================================================
# 6.5 Coreutils-9.5
# ============================================================
echo ">>> Building Coreutils..."
extract_and_cd "coreutils-${PKG_COREUTILS}.tar.xz"
./configure --prefix=/usr \
            --host="$LFS_TGT" \
            --build="$(build-aux/config.guess)" \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime \
            gl_cv_macro_MB_CUR_MAX_good=y
make
make DESTDIR="$LFS" install
mv -v "$LFS/usr/bin/chroot" "$LFS/usr/sbin"
mkdir -pv "$LFS/usr/share/man/man8"
mv -v "$LFS/usr/share/man/man1/chroot.1" "$LFS/usr/share/man/man8/chroot.8"
sed -i 's/"1"/"8"/' "$LFS/usr/share/man/man8/chroot.8"
cleanup_pkg "coreutils-${PKG_COREUTILS}"

# ============================================================
# 6.6 Diffutils-3.10
# ============================================================
echo ">>> Building Diffutils..."
extract_and_cd "diffutils-${PKG_DIFFUTILS}.tar.xz"
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./build-aux/config.guess)"
make
make DESTDIR="$LFS" install
cleanup_pkg "diffutils-${PKG_DIFFUTILS}"

# ============================================================
# 6.7 File-5.45
# ============================================================
echo ">>> Building File..."
extract_and_cd "file-${PKG_FILE}.tar.gz"
mkdir build-host && pushd build-host
  ../configure --disable-bzlib --disable-libseccomp \
               --disable-xzlib --disable-zlib
  make
popd
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)"
make FILE_COMPILE="$(pwd)/build-host/src/file"
make DESTDIR="$LFS" install
rm -v "$LFS/usr/lib/libmagic.la"
cleanup_pkg "file-${PKG_FILE}"

# ============================================================
# 6.8 Findutils-4.10.0
# ============================================================
echo ">>> Building Findutils..."
extract_and_cd "findutils-${PKG_FINDUTILS}.tar.xz"
./configure --prefix=/usr --localstatedir=/var/lib/locate \
            --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make
make DESTDIR="$LFS" install
cleanup_pkg "findutils-${PKG_FINDUTILS}"

# ============================================================
# 6.9 Gawk-5.3.0
# ============================================================
echo ">>> Building Gawk..."
extract_and_cd "gawk-${PKG_GAWK}.tar.xz"
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make
make DESTDIR="$LFS" install
cleanup_pkg "gawk-${PKG_GAWK}"

# ============================================================
# 6.10 Grep-3.11
# ============================================================
echo ">>> Building Grep..."
extract_and_cd "grep-${PKG_GREP}.tar.xz"
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./build-aux/config.guess)"
make
make DESTDIR="$LFS" install
cleanup_pkg "grep-${PKG_GREP}"

# ============================================================
# 6.11 Gzip-1.13
# ============================================================
echo ">>> Building Gzip..."
extract_and_cd "gzip-${PKG_GZIP}.tar.xz"
./configure --prefix=/usr --host="$LFS_TGT"
make
make DESTDIR="$LFS" install
cleanup_pkg "gzip-${PKG_GZIP}"

# ============================================================
# 6.12 Make-4.4.1
# ============================================================
echo ">>> Building Make..."
extract_and_cd "make-${PKG_MAKE}.tar.gz"
./configure --prefix=/usr --without-guile \
            --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make
make DESTDIR="$LFS" install
cleanup_pkg "make-${PKG_MAKE}"

# ============================================================
# 6.13 Patch-2.7.6
# ============================================================
echo ">>> Building Patch..."
extract_and_cd "patch-${PKG_PATCH}.tar.xz"
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make
make DESTDIR="$LFS" install
cleanup_pkg "patch-${PKG_PATCH}"

# ============================================================
# 6.14 Sed-4.9
# ============================================================
echo ">>> Building Sed..."
extract_and_cd "sed-${PKG_SED}.tar.xz"
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./build-aux/config.guess)"
make
make DESTDIR="$LFS" install
cleanup_pkg "sed-${PKG_SED}"

# ============================================================
# 6.15 Tar-1.35
# ============================================================
echo ">>> Building Tar..."
extract_and_cd "tar-${PKG_TAR}.tar.xz"
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make
make DESTDIR="$LFS" install
cleanup_pkg "tar-${PKG_TAR}"

# ============================================================
# 6.16 Xz-5.6.2
# ============================================================
echo ">>> Building Xz..."
extract_and_cd "xz-${PKG_XZ}.tar.xz"
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)" \
            --disable-static --docdir=/usr/share/doc/xz-${PKG_XZ}
make
make DESTDIR="$LFS" install
rm -v "$LFS/usr/lib/liblzma.la"
cleanup_pkg "xz-${PKG_XZ}"

# ============================================================
# 6.17 Binutils-2.43.1 - Pass 2
# ============================================================
echo ">>> Building Binutils Pass 2..."
extract_and_cd "binutils-${PKG_BINUTILS}.tar.xz"
sed '6009s/$add_dir//' -i ltmain.sh
mkdir -v build && cd build
../configure --prefix=/usr \
             --build="$(../config.guess)" \
             --host="$LFS_TGT" \
             --disable-nls \
             --enable-shared \
             --enable-gprofng=no \
             --disable-werror \
             --enable-64-bit-bfd \
             --enable-new-dtags \
             --enable-default-hash-style=gnu
make
make DESTDIR="$LFS" install
rm -v "$LFS"/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
cleanup_pkg "binutils-${PKG_BINUTILS}"

# ============================================================
# 6.18 GCC-14.2.0 - Pass 2
# ============================================================
echo ">>> Building GCC Pass 2..."
extract_and_cd "gcc-${PKG_GCC}.tar.xz"

tar -xf "$LFS_SOURCES/mpfr-${PKG_MPFR}.tar.xz"
mv -v "mpfr-${PKG_MPFR}" mpfr
tar -xf "$LFS_SOURCES/gmp-${PKG_GMP}.tar.xz"
mv -v "gmp-${PKG_GMP}" gmp
tar -xf "$LFS_SOURCES/mpc-${PKG_MPC}.tar.gz"
mv -v "mpc-${PKG_MPC}" mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
    ;;
esac

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build && cd build
../configure \
    --build="$(../config.guess)" \
    --host="$LFS_TGT" \
    --target="$LFS_TGT" \
    LDFLAGS_FOR_TARGET=-L"$PWD/$LFS_TGT/libgcc" \
    --prefix=/usr \
    --with-build-sysroot="$LFS" \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-nls \
    --disable-multilib \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libsanitizer \
    --disable-libssp \
    --disable-libvtv \
    --enable-languages=c,c++
make
make DESTDIR="$LFS" install
ln -sv gcc "$LFS/usr/bin/cc"

cleanup_pkg "gcc-${PKG_GCC}"
echo ">>> GCC Pass 2 complete"

echo "=== Chapter 6: Cross Compiling Temporary Tools complete ==="
