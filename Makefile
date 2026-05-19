CC      := clang
QEMU    := qemu-system-aarch64

TARGET_TRIPLE := aarch64-none-elf

CFLAGS  := -std=c11 -O2 -g3 -Wall -Wextra --target=$(TARGET_TRIPLE) \
           -fno-stack-protector -ffreestanding -nostdlib \
           -fno-builtin -I.
LDFLAGS := --target=$(TARGET_TRIPLE) -fuse-ld=lld -nostdlib \
           -Wl,-Tlinker.ld -Wl,-Map=kernel.map

BUILD   := build
SRCS    := boot/boot.S kernel/kernel.c lib/stdio.c
OBJS    := $(addprefix $(BUILD)/,$(addsuffix .o,$(basename $(SRCS))))
DEPS    := $(OBJS:.o=.d)
TARGET  := kernel.elf

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(OBJS) linker.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

$(BUILD)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/%.o: %.S
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

run: $(TARGET)
	$(QEMU) -machine raspi4b -nographic -serial mon:stdio --no-reboot -kernel $(TARGET)

clean:
	rm -rf $(BUILD) $(TARGET) kernel.map

-include $(DEPS)
