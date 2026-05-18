#pragma once

#include <stdint.h>
#include "lib/stdio.h"

void uart_init(int raspi);
void uart_putc(uint8_t c);
uint8_t uart_getc(void);
void uart_puts(const char *str);

#define PANIC(fmt, ...)                                                        \
    do {                                                                       \
        kprintf("PANIC: %s:%d: " fmt "\n", __FILE__, __LINE__, ##__VA_ARGS__); \
        while (1) {}                                                           \
    } while (0)
