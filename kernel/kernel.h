#pragma once

#include <stdint.h>

void uart_init(int raspi);
void uart_putc(uint8_t c);
uint8_t uart_getc(void);
void uart_puts(const char *str);
