#!/usr/bin/mksh

set -eu
#trap

print "=== Create Caju mount folder ==="
mkdir -p /mnt/caju

print "=== Create Caju virtual disk (4GiB Sparse)"
rm -f ../caju.img
truncate -s 4G ../caju.img

print "=== Create partitions automaticaly (sfdisk) ==="
sfdisk ../caju.img <<EOF
label: gpt
size=512M, type=uefi
type=linux
EOF

print "=== Create loop device ==="
LOOP_DEV=$(sudo losetup -Pf --show ../caju.img)
trap 'sudo losetup -D' ERR EXIT
print "Loop device create at $LOOP_DEV"

print "=== Format partitions ==="
sudo mkfs.vfat -F32 ${LOOP_DEV}p1
sudo mkfs.ext4 ${LOOP_DEV}p2

print "=== Mount partitions ==="
sudo mount -v ${LOOP_DEV}p2 /mnt/caju
sudo mkdir -pv /mnt/caju/boot
sudo mount -v ${LOOP_DEV}p1 /mnt/caju/boot

trap 'sudo umount /mnt/caju/boot; sudo umount /mnt/caju; sudo losetup -d ${LOOP_DEV}' ERR EXIT

print "=== Creating FHS folders ==="
sudo mkdir -pv /mnt/caju{dev,etc,home,proc,root,sys,tmp,caju,var,run,apps}
sudo mkdir -pv /mnt/caju/{bin,lib,share}