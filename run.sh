#!/usr/bin/env bash

QEMU=qemu-system-aarch64

# path to clang and compiler flags
CC=clang
CFLAGS="-std=c11 -O2 -g3 -Wall -Wextra --target=aarch64-linux-gnu -fuse-ld=lld -fno-stack-protector -ffreestanding -nostdlib"

# build the kernel
$CC $CFLAGS -Wl,-Tlinker.ld -Wl,-Map=kernel.map -o kernel.elf \
    boot.S kernel.c

# start QEMU
$QEMU -machine raspi4b -nographic -serial mon:stdio --no-reboot \
    -kernel kernel.elf
