# 32-bit Intel Kernel

A minimal 32-bit kernel for Intel x86, built from scratch as part of the **System Programming Workshop** at **FCEN – UBA** (Computer Architecture and Organization).

---

## Overview

The kernel boots from a floppy disk image via QEMU. Once the BIOS hands off execution, it transitions the CPU from Real Mode to 32-bit Protected Mode and builds the full execution environment from the ground up — no OS underneath, no standard library.

It sets up segmentation (GDT), interrupt handling (IDT), and virtual memory through a two-level paging structure with isolated per-task address spaces. Task switching is hardware-assisted via TSS descriptors, and a preemptive round-robin scheduler driven by the PIT timer keeps four concurrent user-space tasks running at Ring 3.

The tasks are interactive games rendered simultaneously in separate screen quadrants: **Pong** (two-player, keyboard controlled), **Snake**, **Conway's Game of Life**, and a typing game. Each task communicates with the kernel via a shared memory page (keyboard state, tick count, task ID) and a `syscall_draw` interrupt to render its viewport.

## Features

- Protected Mode transition with GDT (Ring 0 / Ring 3 code and data segments)
- IDT with handlers for CPU exceptions (0–20), hardware IRQs (timer, keyboard), and software syscalls (int 88 / int 98)
- Two-level paging with per-task page directories, identity mapping for the kernel, and on-demand memory mapping for the range `0x07000000–0x07000FFF`
- Round-robin scheduler with `RUNNABLE` / `PAUSED` / `FREE` task states and idle task fallback
- Shared memory page mapped into every task's virtual address space for kernel-to-task communication

---

## How to Run

### Requirements

- `gcc` with `-m32` support
- `nasm`
- `qemu-system-i386`
- `gdb`
- `mtools`
- `bzip2`

### Running

```bash
cd TPSP/src
make qemu     # builds the kernel and launches QEMU
make attach   # attach GDB (in a separate terminal)
```

---

## Reference

- [Intel SDM Vol. 1 – Basic Architecture](https://software.intel.com/content/dam/develop/external/us/en/documents-tps/253665-sdm-vol-1.pdf)
- [Intel SDM Vol. 2 – Instruction Set Reference](https://software.intel.com/content/dam/develop/external/us/en/documents-tps/325383-sdm-vol-2abcd.pdf)
- [Intel SDM Vol. 3 – System Programming Guide](https://software.intel.com/content/dam/develop/external/us/en/documents-tps/325384-sdm-vol-3abcd.pdf)

> Per-stage documentation (Protected Mode, Interrupts, Paging, Tasks) is available in the `TPSP/` directory in Spanish.
