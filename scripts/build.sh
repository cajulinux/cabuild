#!/usr/bin/mksh

set -eu

print "=== Create Caju mount folder ==="
mkdir -p /mnt/cajurootfs

print "=== Create Caju virtual disk (4GiB Sparse)"
rm -f ./caju.img
truncate -s 4G ./caju.img

print "=== Create partitions automaticaly (sfdisk) ==="
sfdisk ./caju.img <<EOF
label: gpt
size=512M, type=uefi
type=linux
EOF

print "=== Create loop device ==="
LOOP_DEV=$(sudo losetup -Pf --show ./caju.img)
trap 'sudo losetup -D' EXIT
print "Loop device create at $LOOP_DEV"

print "=== Format partitions ==="
sudo mkfs.vfat -F32 ${LOOP_DEV}p1
sudo mkfs.ext4 ${LOOP_DEV}p2

print "=== Mount partitions ==="
sudo mount -v ${LOOP_DEV}p2 /mnt/cajurootfs
sudo mkdir -pv /mnt/cajurootfs/efi
sudo mount -v ${LOOP_DEV}p1 /mnt/cajurootfs/efi

trap 'sudo umount /mnt/cajurootfs/efi; sudo umount /mnt/cajurootfs; sudo losetup -d ${LOOP_DEV}' EXIT

print "=== Creating FHS folders ==="
sudo mkdir -pv /mnt/cajurootfs/{dev,etc,home,proc,root,sys,temp,caju,var,run,apps}
sudo mkdir -pv /mnt/cajurootfs/caju/{bin,lib,share}

print "=== Creating for compatibility symlinks ==="

sudo ln -s caju/bin /mnt/cajurootfs/bin
sudo ln -s caju/bin /mnt/cajurootfs/sbin
sudo ln -s caju/lib /mnt/cajurootfs/lib
sudo ln -s caju/lib /mnt/cajurootfs/lib64
sudo ln -s caju /mnt/cajurootfs/usr
sudo ln -s ../run /mnt/cajurootfs/var/run
sudo ln -s apps /mnt/cajurootfs/opt

print "=== Creating internal caju symlinks ==="
sudo ln -s bin /mnt/cajurootfs/caju/sbin
sudo ln -s lib /mnt/cajurootfs/caju/lib64

print "=== Bind mounting virtual filesystems ==="
sudo mount --bind /dev /mnt/cajurootfs/dev
sudo mount -t devpts devpts /mnt/cajurootfs/dev/pts
sudo mount -t proc proc /mnt/cajurootfs/proc
sudo mount -t sysfs sysfs /mnt/cajurootfs/sys

trap 'sudo umount /mnt/cajurootfs/dev/pts; sudo umount /mnt/cajurootfs/dev; sudo umount /mnt/cajurootfs/proc; sudo umount /mnt/cajurootfs/sys; sudo umount /mnt/cajurootfs/efi; sudo umount /mnt/cajurootfs; sudo losetup -d ${LOOP_DEV}' EXIT

print "=== Start Programs Build ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/programs.sh"

rm -r /tmp/caju
mkdir -pv /tmp/caju
cd /tmp/caju
musl
mksh
toybox

print "=== Changes root to rootfs ==="
chroot /mnt/cajurootfs/