CC      := clang
QEMU    := qemu-system-aarch64

CFLAGS  := -std=c11 -O2 -g3 -Wall -Wextra --target=aarch64-linux-gnu \
           -fuse-ld=lld -fno-stack-protector -ffreestanding -nostdlib
LDFLAGS := -Wl,-Tlinker.ld -Wl,-Map=kernel.map

SRCS    := boot/boot.S kernel/kernel.c
TARGET  := kernel.elf

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(SRCS) linker.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRCS)

run: $(TARGET)
	$(QEMU) -machine raspi4b -nographic -serial mon:stdio --no-reboot -kernel $(TARGET)

clean:
	rm -f $(TARGET) kernel.map
