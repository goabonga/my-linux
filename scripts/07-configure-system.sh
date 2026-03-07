#!/bin/bash
# LFS 12.2 - Chapter 9: System Configuration
# This script runs INSIDE the chroot environment
set -euo pipefail

echo "=== Chapter 9: System Configuration ==="

# ============================================================
# 9.2 LFS-Bootscripts
# ============================================================
# We use a minimal boot configuration since we don't have
# the LFS bootscripts package in our wget-list.
# For a full system, download from:
# https://www.linuxfromscratch.org/lfs/downloads/12.2/lfs-bootscripts-20240825.tar.xz

# Create basic init scripts directory structure
mkdir -pv /etc/rc.d/{init.d,rc{0,1,2,3,4,5,6,S}.d}
mkdir -pv /etc/sysconfig

# ============================================================
# 9.5 General Network Configuration
# ============================================================
cat > /etc/sysconfig/ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=192.168.1.100
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF

cat > /etc/resolv.conf << "EOF"
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# ============================================================
# 9.6 Hostname
# ============================================================
echo "lfs" > /etc/hostname

cat > /etc/hosts << "EOF"
127.0.0.1 localhost lfs
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF

# ============================================================
# 9.7 Configuring Sysvinit
# ============================================================
cat > /etc/inittab << "EOF"
id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600
EOF

# ============================================================
# 9.8 System Clock
# ============================================================
cat > /etc/sysconfig/clock << "EOF"
UTC=1
EOF

# ============================================================
# 9.9 Console
# ============================================================
cat > /etc/sysconfig/console << "EOF"
UNICODE="1"
FONT="Lat2-Terminus16"
EOF

# ============================================================
# 9.10 Shell Profile
# ============================================================
cat > /etc/profile << "EOF"
export LANG=en_US.UTF-8
export PATH=/usr/bin:/usr/sbin
export HISTSIZE=1000
export HISTFILESIZE=2000

alias ls='ls --color=auto'
alias ll='ls -la'

# Set up prompt
PS1='\u@\h:\w\$ '
EOF

cat > /etc/locale.conf << "EOF"
LANG=en_US.UTF-8
EOF

cat > /etc/inputrc << "EOF"
set horizontal-scroll-mode Off
set meta-flag On
set input-meta On
set convert-meta Off
set output-meta On
set bell-style none

"\eOd": backward-word
"\eOc": forward-word
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert
"\eOH": beginning-of-line
"\eOF": end-of-line
"\e[H": beginning-of-line
"\e[F": end-of-line
EOF

# ============================================================
# 9.11 /etc/shells
# ============================================================
cat > /etc/shells << "EOF"
/bin/sh
/bin/bash
EOF

# ============================================================
# 9.12 /etc/fstab
# ============================================================
cat > /etc/fstab << "EOF"
# file system  mount-point    type     options             dump  fsck
#                                                                order
/dev/sda1      /              ext4     defaults            1     1
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults             0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid     0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev         0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev  0     0
EOF

echo "=== Chapter 9: System Configuration complete ==="
