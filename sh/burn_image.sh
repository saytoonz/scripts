#!/bin/bash

# Check if device file is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <device_file> (e.g., sdb)"
    exit 1
fi

DEVICE=/dev/$1

# Check if device file exists
if [ ! -e $DEVICE ]; then
    echo "Error: Device file $DEVICE does not exist."
    exit 1
fi


# Erase SD card partition information
echo "======================================="
echo "Erasing SD card partition information..."
echo "======================================="
sudo dd if=/dev/zero of=$DEVICE bs=1M count=10
echo "SD card partition information erased."


# Create new partition table
echo "======================================="
echo "Creating new partition table..."
echo "======================================="
sudo sgdisk -o $DEVICE
sudo sgdisk --resize-table=128 -a 1 \
                      -n 1:34:545      -c 1:fsbl1   \
                      -n 2:546:1057    -c 2:fsbl2   \
                      -n 3:1058:5153   -c 3:fip    \
                      -n 4:5154:136225 -c 4:bootfs    \
                      -n 5:136226:     -c 5:rootfs  \
                      -p $DEVICE
sudo sgdisk -A 4:set:2 $DEVICE
echo "New partition table created."


# Burn TF-A and FIP firmware
echo "======================================="
echo "Burning TF-A and FIP firmware..."
echo "======================================="
echo "Burning TF-A to partition 1..."
sudo dd if=arm-trusted-firmware/tf-a-stm32mp157c-odyssey-sdcard.stm32 of=${DEVICE}1
echo "TF-A burned to partition 1."
echo "Burning TF-A to partition 2..."
sudo dd if=arm-trusted-firmware/tf-a-stm32mp157c-odyssey-sdcard.stm32 of=${DEVICE}2
echo "TF-A burned to partition 2."
echo "Burning FIP to partition 3..."
sudo dd if=fip/fip-stm32mp157c-odyssey-trusted.bin of=${DEVICE}3
echo "FIP burned to partition 3."


# Format and burn bootfs and rootfs
echo "======================================="
echo "Formatting and burning bootfs and rootfs..."
echo "======================================="
echo "Formatting bootfs partition..."
sudo mkfs.ext4 -L bootfs ${DEVICE}4
echo "bootfs partition formatted."
echo "Formatting rootfs partition..."
sudo mkfs.ext4 -L rootfs ${DEVICE}5
echo "rootfs partition formatted."

sudo mkdir -p /media/boot/
sudo mkdir -p /media/rootfs/
sudo mount ${DEVICE}4 /media/boot/
sudo mount ${DEVICE}5 /media/rootfs/

export kernel_version=5.10.10-stm32-r1


# Find the dtb and zImage files with dynamic names and copy them
echo "Copying kernel files..."
DTB_FILE=$(find kernel/ -name "stm32mp157c-odyssey--5.10.10-r0.0-stm32mp1*.dtb")
sudo mkdir -p /media/boot/dtbs/${kernel_version}/
sudo cp $DTB_FILE /media/boot/dtbs/${kernel_version}/stm32mp157c-odyssey.dtb
echo "Device tree blob copied."

ZIMAGE_FILE=$(find kernel/ -name "zImage--5.10.10-r0.0-stm32mp1*.bin")
sudo cp $ZIMAGE_FILE /media/boot/zImage
echo "Kernel image copied."

sudo sh -c "echo 'uname_r=${kernel_version}' >> /media/boot/uEnv.txt"
sudo sh -c "echo 'dtb=stm32mp157c-odyssey.dtb' >> /media/boot/uEnv.txt"
echo "Kernel files copied."

echo "Mounting rootfs image..."
sudo mkdir -p rootfs_mount
ROOTFS_FILE=$(find . -name "st-image-weston-openstlinux-weston-stm32mp1*.rootfs.ext4")
sudo mount $ROOTFS_FILE rootfs_mount/
echo "rootfs image mounted."

echo "Copying rootfs files..."
sudo cp -rf rootfs_mount/*  /media/rootfs/
echo "rootfs files copied."


# Unmount filesystems
echo "Unmounting filesystems..."

sync
echo "Unmounting filesystems..."
echo "Unmounting boot filesystem..."
sudo umount /media/boot/
echo "Unmounting root filesystem..."
sudo umount /media/rootfs/
echo "Unmounting rootfs image..."
sudo umount rootfs_mount
echo "Filesystems unmounted."

echo "======================================="
echo "Image burning complete!"
echo "======================================="