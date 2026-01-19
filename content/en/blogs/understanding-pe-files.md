---
title: "Understanding Windows PE Files"
date: 2026-01-10T16:11:53-05:00
lastmod: 2026-01-10T16:11:53-05:00
draft: false
tags: ["windows","pe-file"]
summary: "Technical deep-dive into Windows PE file format"
externalUrl: ""
---

## Introduction

So what is a PE file? Well, PE stands for _portable executable_ and is more of file family that share common elements rather than a single file type. Hence why we discuss PE as a format rather than a discrete file type. Members of the PE family include `.exe`, `.com`, `.dll`, `.sys`, `.acm`, `.ax`, `.cpl`, `.drv`, `.efi`, `.mui`, `.oxc`, `.scr`, `.tsp`, `.msstyles`, and many more. Following its introduction in Windows NT 3.1 in 1993, the format has a long history that I'd like to touch on briefly as it helps set the stage for implementation level details.

## History

- __NE Format (1985-1993)__ — Strictly a 16-bit executable format (minimal, bolted-on 32-bit support added later). Supported dynamic linking and resources but limited by 16b addressing. Optimized for the segmented memory model of Intel 8086/286/386 processors relying on protected/unreal mode. This imposed severe restrictions:
  - Maximum program size was tightly limited.
  - Accessing larger memory required complex segment management and far pointers.
  - Could not natively exploit the full 32-bit capabilities of the 386 and later processors.
- __PE32 Format (1993-2005)__ — The original 32-bit PE format introduced with Windows NT 3.1. Largely an extended variant of the `COFF` format made by AT&T for Unix. Designed for a flat virtual address space, it uses relative virtual addresses and page-aligned sections enabling efficient memory mapping and relocation. Key advantages over NE:
  - Full 32-bit flat addressing (up to ~4 GB per process) with no segment limits.
  - Position-independent code and data via RVAs and a single relocation table.
  - Page-aligned sections mapped directly into virtual memory with hardware-enforced protections (executable, writable, readable).
  - Native support for dynamic linking, resources, TLS, and future extensibility.
- __PE32+ Format (2005 onward)__ - The 64-bit extension of the format, introduced with Windows XP x64 Edition and Windows Server 2003 x64. It preserves the core PE/COFF structure while expanding addressability to support 64-bit flat virtual memory spaces. Key changes and advantages over PE32:
  - Expands the virtual address space from ~4 GB (32-bit) to 16 exabytes (theoretical), with practical limits of 128 TB user-mode and 128 TB kernel-mode in modern Windows.
  - Optional header magic number changed from 0x10B (PE32) to 0x20B (PE32+). The `ImageBase` field is now 64-bit (8 bytes instead of 4), as are several other fields (e.g., `SizeOfImage`, `SizeOfStackReserve`).
  - All RVA and size fields that reference virtual addresses are widened to 64-bit (though most remain 32-bit for compatibility and efficiency).
  - 64-bit Windows continues to support 32-bit PE32 executables via WOW64 (Windows on Windows 64-bit) emulation layer.

## Portability
So why is PE 'Portable'? Well, primarily this is a nod to the format's deliberate design for architecture independence and cross-platform consistency within the Windows ecosystem. Note, this does not mean a single compiled binary runs unchanged on different CPUs (e.g. source code portability or 'real' cross-platform executables like Java bytecode). Instead the goal was a single, unified executable container that could support multiple CPU architectures without requiring a complete redesign of the loader, linker, or analysis tools for each new processor. While this behavior is taken for granted today one should note that NE lacked this due to its interwoven nature with x86 conventions.

How was this achieved? 
- __Machine Agnostic Headers__ - The COFF File Header (part of the NT Headers) contains a Machine field (WORD at offset 4 in IMAGE_FILE_HEADER) that specifies the target CPU architecture: 0x014c → x86 (32-bit), 0x8664 → x64/AMD64 etc. All other headers, section tables, data directories, RVAs, and loading logic remain identical regardless of the Machine value. Only the .text (code) section contains architecture-specific machine instructions.
- 

## Main Content

Your main content goes here...

## Conclusion

Wrap up your thoughts...
