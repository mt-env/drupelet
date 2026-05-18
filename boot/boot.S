// AArch64 mode

// To keep this in the first portion of the binary.
.section ".text.boot"

// Make _start global.
.globl _start

    .org 0x80000
// Entry point for the kernel. Registers:
// x0 -> 32 bit pointer to DTB in memory (primary core only) / 0 (secondary cores)
// x1 -> 0
// x2 -> 0
// x3 -> 0
// x4 -> 32 bit kernel entry point, _start location
_start:
    // halt cores 1-3, only core 0 continues
    mrs     x5, mpidr_el1
    and     x5, x5, #0x3
    cbnz    x5, halt

    // Drop to EL1 via a fake exception return. We may enter at EL3 (QEMU's
    // raspi4b default), EL2 (real RPi4 AArch64), or EL1 (if firmware already
    // demoted us). The strategy: program the EL1 system regs that EL1 will
    // need (SCTLR_EL1, plus HCR_EL2 so EL1 runs AArch64, plus the timer regs),
    // then ERET from whichever EL we're in straight to el1_entry.
    mrs     x5, CurrentEL
    lsr     x5, x5, #2                  // EL number in bits [3:2] -> [1:0]
    cmp     x5, #1
    b.eq    el1_entry                   // already EL1, nothing to do

    // Common EL1 setup: SCTLR_EL1 reset value (MMU/caches off, RES1 bits set).
    // Without this, EL1 can fault on its first instruction.
    ldr     x5, =0x30C50830
    msr     sctlr_el1, x5

    // HCR_EL2.RW = 1 so EL1 executes in AArch64. EL1's RW is taken from this
    // bit when EL2 is implemented, even if we ERET directly from EL3 to EL1.
    mov     x5, #(1 << 31)
    msr     hcr_el2, x5

    // Let EL1 read the physical/virtual counter; zero the virt offset.
    mrs     x5, cnthctl_el2
    orr     x5, x5, #3                  // EL1PCEN | EL1PCTEN
    msr     cnthctl_el2, x5
    msr     cntvoff_el2, xzr

    // EL1h uses SP_EL1, so seed it before the ERET (the current sp doesn't
    // carry across the EL change).
    ldr     x5, =_start
    msr     sp_el1, x5

    // Branch on current EL.
    mrs     x5, CurrentEL
    lsr     x5, x5, #2
    cmp     x5, #3
    b.eq    from_el3

    // --- From EL2 ---
    // SPSR_EL2 = 0x3C5: DAIF masked, return mode EL1h.
    mov     x5, #0x3C5
    msr     spsr_el2, x5
    adr     x5, el1_entry
    msr     elr_el2, x5
    eret

from_el3:
    // SCR_EL3: NS=1 (non-secure), RW=1 (lower EL is AArch64), bits 4/5 RES1.
    // 0x431 = NS | RES1[4:5] | RW.
    mov     x5, #0x431
    msr     scr_el3, x5

    // SPSR_EL3 = 0x3C5: DAIF masked, return mode EL1h (skip EL2 entirely).
    mov     x5, #0x3C5
    msr     spsr_el3, x5
    adr     x5, el1_entry
    msr     elr_el3, x5
    eret

el1_entry:
    // Now at EL1 (or we were already at EL1 and jumped straight here).
    // Set the current-EL stack.
    ldr     x5, =_start
    mov     sp, x5

    // clear bss
    ldr     x5, =__bss_start
    ldr     w6, =__bss_size
1:  cbz     w6, 2f
    str     xzr, [x5], #8
    sub     w6, w6, #1
    cbnz    w6, 1b

    // jump to C code, should not return
2:  bl      kernel_main
    // for failsafe, halt this core
halt:
    wfe
    b halt
