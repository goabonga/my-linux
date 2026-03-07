#!/bin/bash
# LFS 12.2 - Chapter 5: Compiling a Cross-Toolchain
# This builds: binutils pass 1, gcc pass 1, linux headers, glibc, libstdc++
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "=== Chapter 5: Building Cross-Toolchain ==="

# Ensure tools directory exists
mkdir -pv "$LFS_TOOLS"

# ============================================================
# 5.2 Binutils-2.43.1 - Pass 1
# ============================================================
echo ">>> Building Binutils Pass 1..."
extract_and_cd "binutils-${PKG_BINUTILS}.tar.xz"

mkdir -v build && cd build
../configure --prefix="$LFS_TOOLS" \
             --with-sysroot="$LFS" \
             --target="$LFS_TGT" \
             --disable-nls \
             --enable-gprofng=no \
             --disable-werror \
             --enable-new-dtags \
             --enable-default-hash-style=gnu
make
make install

cleanup_pkg "binutils-${PKG_BINUTILS}"
echo ">>> Binutils Pass 1 complete"

# ============================================================
# 5.3 GCC-14.2.0 - Pass 1
# ============================================================
echo ">>> Building GCC Pass 1..."
extract_and_cd "gcc-${PKG_GCC}.tar.xz"

# Extract required dependencies
tar -xf "$LFS_SOURCES/mpfr-${PKG_MPFR}.tar.xz"
mv -v "mpfr-${PKG_MPFR}" mpfr
tar -xf "$LFS_SOURCES/gmp-${PKG_GMP}.tar.xz"
mv -v "gmp-${PKG_GMP}" gmp
tar -xf "$LFS_SOURCES/mpc-${PKG_MPC}.tar.gz"
mv -v "mpc-${PKG_MPC}" mpc

# On x86_64, set the default directory name for 64-bit libraries to "lib"
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
    ;;
esac

mkdir -v build && cd build
../configure \
    --target="$LFS_TGT" \
    --prefix="$LFS_TOOLS" \
    --with-glibc-version=2.40 \
    --with-sysroot="$LFS" \
    --with-newlib \
    --without-headers \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++
make
make install

# Create a full version of the internal header
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  "$(dirname $("$LFS_TOOLS"/bin/"$LFS_TGT"-gcc -print-libgcc-file-name))/include/limits.h"

cleanup_pkg "gcc-${PKG_GCC}"
echo ">>> GCC Pass 1 complete"

# ============================================================
# 5.4 Linux-6.10.5 API Headers
# ============================================================
echo ">>> Installing Linux API Headers..."
extract_and_cd "linux-${PKG_LINUX}.tar.xz"

make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include "$LFS/usr"

cleanup_pkg "linux-${PKG_LINUX}"
echo ">>> Linux API Headers complete"

# ============================================================
# 5.5 Glibc-2.40
# ============================================================
echo ">>> Building Glibc..."
extract_and_cd "glibc-${PKG_GLIBC}.tar.xz"

# Create LSB compliance symlink
case $(uname -m) in
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64"
            ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64/ld-lsb-x86-64.so.3"
            ;;
esac

# Apply FHS patch
patch -Np1 -i "$LFS_SOURCES/glibc-${PKG_GLIBC}-fhs-1.patch"

mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure \
    --prefix=/usr \
    --host="$LFS_TGT" \
    --build="$(../scripts/config.guess)" \
    --enable-kernel=4.19 \
    --with-headers="$LFS/usr/include" \
    --disable-nscd \
    libc_cv_slibdir=/usr/lib
make
make DESTDIR="$LFS" install

# Fix ldd script hardcoded path
sed '/RTLDLIST=/s@/usr@@g' -i "$LFS/usr/bin/ldd"

# Sanity check
echo 'int main(){}' | "$LFS_TOOLS/bin/$LFS_TGT-gcc" -xc -
readelf -l a.out | grep ld-linux
rm -v a.out

cleanup_pkg "glibc-${PKG_GLIBC}"
echo ">>> Glibc complete"

# ============================================================
# 5.6 Libstdc++ from GCC-14.2.0
# ============================================================
echo ">>> Building Libstdc++..."
extract_and_cd "gcc-${PKG_GCC}.tar.xz"

mkdir -v build && cd build
../libstdc++-v3/configure \
    --host="$LFS_TGT" \
    --build="$(../config.guess)" \
    --prefix=/usr \
    --disable-multilib \
    --disable-nls \
    --disable-libstdcxx-pch \
    --with-gxx-include-dir="/tools/$LFS_TGT/include/c++/${PKG_GCC}"
make
make DESTDIR="$LFS" install

# Remove unneeded archive files
rm -v "$LFS"/usr/lib/lib{stdc++{,exp,fs},supc++}.la

cleanup_pkg "gcc-${PKG_GCC}"
echo ">>> Libstdc++ complete"

echo "=== Chapter 5: Cross-Toolchain build complete ==="
