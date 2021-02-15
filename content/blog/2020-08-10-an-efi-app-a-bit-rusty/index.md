+++
title = "An EFI App a bit rusty"
description = "The objective is to create a UEFI application in Rust that prints out the memory map filtered by usable memory."

[taxonomies]
categories = ["blog"]
tags = ["rust", "development"]

[extra]
comments=true
applause=true

+++

> This is a new version of an old [article](https://medium.com/@gil0mendes/an-efi-app-a-bit-rusty-82c36b745f49) of mine on Medium. This version no longer uses XBuild since cargo nightly is receiving build-std that does the same job. 

After two tweets that I made last week, playing around with UEFI and Rust, some people asked to publish a blog post explaining how to create a UEFI application fully written in Rust and demonstrate all the testing environment.

So todays objective it’s to create a UEFI application in Rust that prints out the memory map filtered by usable memory (described as conventional memory by the UEFI specification). But before putting the hands at work let’s review some concepts first.

<!-- more -->

## A mess beginning

When the computer turns on the hardware is on an unpredictable state and some initialization must be made in order to prepare the system to work as intended. Introduced around 1975, BIOS, an acronym for Basic Input/Output System, was been used since then was a way to perform hardware initialization during booting process (power-on startup) and to provide runtime services for operating system and program. However, BIOS has some limitations and after more than 40 years at the service, is being replaced by the Unified Extensible Firmware Interface (or UEFI for short), UEFI aims to address its technical shortcomings.

UEFI is a specification that defines a software interface between an operating system/UEFI application and platform firmware. Intel developed the original Extensible Firmware Interface (EFI) which the development was ceased in July 2005 and Apple was one of the early adopters with their first Intel Macintosh early 2006. In the same year, 2005, UEFI deprecated EFI 1.10 (the final release of EFI). The Unified EFI Forum is the industry body that manages the UEFI Specification. The interface defined by the EFI Specification includes data tables that contains platform information, boot and runtime services that are available to the OS loader/application. This firmware provides several technical advantages over a traditional BIOS system: 
- Ability to use a larger disk with a GUID Partition Table (GPT)
- CPU-independent architecture
- CPU-independent drivers
- Flexible pre-OS environment, including network capability
- Modular design
- Backward and forward compatibility

As is possible to see UEFI is more modern and future-proof solution compared with BIOS, also provides more advanced features to easily implement a bootloader or a UEFI application without the need to have advanced architecture knowledge.

## Oxidation is good

Was said on the beginning Rust will be used to write the UEFI application previous spoken. For those who don’t know what Rust is, Rust is a systems programming language sponsored by Mozilla which describes it as a “safe, concurrent, practical language” supporting functional and imperative-procedural paradigms. Rust is very similar to C++ syntactically speaking, but its designers intend it to provide better memory safety while still maintaining performance.

The language resulted from a personal project of a Mozilla employ, Graydon Hoare. Mozilla started to fund the project in 2009, after realizing the potential of it. Only in 2010 was made a public announcement of the project, in the same year that the compiler, originally written in OCaml, is started to be rewritten in Rust, using LLVM as backend.

The first pre-alpha version of the compiler appends in January of 2012, but just 3 years later, on May 15th of 2015 is launched the first stable version (now known as 2015 edition). Rust is an open community project, that means that everyone can contribute on the development and on the language refinement and that can be done in many ways, for example, improve documentation, reporting bugs, propose RFCs to add features or contribute with code. The language received a huge feedback from the experience of developing the Servo engine, a modern browser engine with extreme performance for applications and embedded use. Noways, Rust starts to be present in all kind of areas, like satellite control software, micro-controller programming, web servers, on Firefox and so on. Rust won first place for “most loved programming language” in the Stack Overflow Developer Survey in 2016, 2017 and 2018.

## Just more 2 or 3 things before start

In order to write a bootloader, hypervisor or a low-level application it’s required to use a system programming language. There is a [great article](https://willcrichton.net/notes/systems-programming/) that discusses in detail what that concept is. But generically speaking, a system programming language is a language that allows fine control over the execution of the code in the machine, with the possibility of manipulating all individual bytes in the computer’s memory, and with Rust it’s possible to do that.

Furthermore, to avoid the need to describe all UEFI tables the **uefi-rs** crate will be used. This crate makes it easy to write UEFI applications in Rust. The objective of uefi-rs is to provide safe and performant wrappers for UEFI interfaces and allow developers to write idiomatic Rust code.

Finally, for the test environment will be used Python and QEMU alongside with OVMF. QEMU is a well-known full-system emulator that allows run code for any machine, on any supported architecture. OVMF is an EDK II based project to enable UEFI support for Virtual Machines (QEMU and KVM). QEMU doesn’t come with OVMF, so it requires to installing it on your PC or get a pre-built image from the Internet, it’s possible to download it from my test [repository](https://github.com/gil0mendes/Initium/tree/rust).

## Let’s begin

With no further delays, let’s get the work done! First thing, create a new folder and start a rust project in it.

```shell
mkdir uefi-app && cd uefi-app
cargo init
```

Now it’s time to add _uefi-rs_ as a dependency. To do that just add the following dependency to your `Cargo.toml`:

```toml
uefi = "0.5.0"
uefi-services = "0.2.5"
```

Now, when the `cargo run` command is executed, Cargo will build all `uefi-rs` alongside with our application.

## Build/Run workflow

The next step is creating a target configuration file and a python script to help build and run the UEFI application. Basically, a target configuration describes the output binary, "endianess", architecture, binary organization and features to use during compilation. This file will be used by [`build-std`](https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#build-std), a cargo feature to produce a cross-compiled `core` crate (the dependency-free foundation of the Rust Standard Library with no system libraries and no libc).

So firstly, we need to tell cargo to enable build-std by creating a new file inside `.cargo/config`:

```toml
[unstable]
build-std = ["core", "compiler_builtins", "alloc"]
```

> **Note:** to this to work you need to have installed the rust nightly as well as the rust-src component, you can use rustup to do that: `rustup component add rust-src --toolchain nightly`

When building using Cargo's `build-std` feature, the `mem` feature of `compiler-builtins` does not automatically get enabled. Therefore, we have to manually add support for the memory functions by adding the following to `Cargo.toml` file:

```toml
rlibc = "1"
```

And then add the crate as an dependency so the `mem*` functions are linked in:

```rust
extern crate rlibc;
```

Then, we create a file named `x86_64-none-efi.json` with the following content:

```json
{
  "llvm-target": "x86_64-pc-windows-gnu",
  "env": "gnu",
  "target-family": "windows",
  "target-endian": "little",
  "target-pointer-width": "64",
  "target-c-int-width": "32",
  "os": "uefi",
  "arch": "x86_64",
  "data-layout": "e-m:e-i64:64-f80:128-n8:16:32:64-S128",
  "linker": "rust-lld",
  "linker-flavor": "lld-link",
  "pre-link-args": {
    "lld-link": [
      "/Subsystem:EFI_Application",
      "/Entry:uefi_start"
    ]
  },
  "panic-strategy": "abort",
  "default-hidden-visibility": true,
  "executables": true,
  "position-independent-executables": true,
  "exe-suffix": ".efi",
  "is-like-windows": true,
  "emit-debug-gdb-scripts": false
}
```

A UEFI executable is nothing more than a PE binary format used by Windows, but with a specific subsystem and without a symbol table, for that, the `target-family` is set as being `windows`.

Now, a `build.py` file must be created by implementing two commands:
- `build`: this command builds the UEFI application
- `run`: run the application inside QEMU

```python
#!/usr/bin/env python3

import argparse
import os
import shutil
import sys
import subprocess as sp
from pathlib import Path

ARCH = "x86_64"
TARGET = ARCH + "-none-efi"
CONFIG = "debug"
QEMU = "qemu-system-" + ARCH

WORKSPACE_DIR = Path(__file__).resolve().parents[0]
BUILD_DIR = WORKSPACE_DIR / "build"
CARGO_BUILD_DIR = WORKSPACE_DIR / "target" / TARGET / CONFIG

OVMF_FW = WORKSPACE_DIR / "OVMF_CODE.fd"
OVMF_VARS = WORKSPACE_DIR / "OVMF_VARS-1024x768.fd"

def run_build(*flags):
  "Run Cargo-<tool> with the given arguments"

  cmd = ["cargo", "build", "--target", TARGET, *flags]
  sp.run(cmd).check_returncode()

def build_command():
  "Builds UEFI application"

  run_build("--package", "uefi-app")

  # Create build folder
  boot_dir = BUILD_DIR / "EFI" / "BOOT"
  boot_dir.mkdir(parents=True, exist_ok=True)

  # Copy the build EFI application to the build directory
  built_file = CARGO_BUILD_DIR / "uefi-app.efi"
  output_file = boot_dir / "BootX64.efi"
  shutil.copy2(built_file, output_file)

  # Write a startup script to make UEFI Shell load into
  # the application automatically
  startup_file = open(BUILD_DIR / "startup.nsh", "w")
  startup_file.write("\EFI\BOOT\BOOTX64.EFI")
  startup_file.close()

def run_command():
  "Run the application in QEMU"

  qemu_flags = [
    # Disable default devices
    # QEMU by default enables a ton of devices which slow down boot.
    "-nodefaults",

    # Use a standard VGA for graphics
    "-vga", "std",

    # Use a modern machine, with acceleration if possible.
    "-machine", "q35,accel=kvm:tcg",

    # Allocate some memory
    "-m", "128M",

    # Set up OVMF
    "-drive", f"if=pflash,format=raw,readonly,file={OVMF_FW}",
    "-drive", f"if=pflash,format=raw,file={OVMF_VARS}",

    # Mount a local directory as a FAT partition
    "-drive", f"format=raw,file=fat:rw:{BUILD_DIR}",

    # Enable serial
    #
    # Connect the serial port to the host. OVMF is kind enough to connect
    # the UEFI stdout and stdin to that port too.
    "-serial", "stdio",

    # Setup monitor
    "-monitor", "vc:1024x768",
  ]

  sp.run([QEMU] + qemu_flags).check_returncode()

def main(args):
  "Runs the user-requested actions"

  # Clear any Rust flags which might affect the build.
  os.environ["RUSTFLAGS"] = ""
  os.environ["RUST_TARGET_PATH"] = str(WORKSPACE_DIR)

  usage = "%(prog)s verb [options]"
  desc = "Build script for the UEFI App"

  parser = argparse.ArgumentParser(usage=usage, description=desc)

  subparsers = parser.add_subparsers(dest="verb")
  build_parser = subparsers.add_parser("build")
  run_parser = subparsers.add_parser("run")

  opts = parser.parse_args()

  if opts.verb == "build":
    build_command()
  elif opts.verb == "run":
    run_command()
  else:
    print(f"Unknown verb '{opts.verb}'")

if __name__ == '__main__':
    sys.exit(main(sys.argv))

```

> Note: For some reason, I didn’t find any information on why the executable doesn’t load automatically with this OVMF version, so the startup.nsh script is used to make the boot less painful.

## The App itself

The first step is making the application boot and enter in an infinite loop, to prevent it to exit into the firmware. In Rust, errors can be promoted into a panic or abort. A panic happens when something goes wrong but the whole can continue running (this usually happens with threads), an abort happens when the program goes into an unrecoverable state and aborts. The existence of a panic handler is mandatory, it is implemented on the standard library, but since the application doesn’t depend on an operating system the std lib can’t be used. Instead, we will use the core library, this one doesn’t contain a panic handler implementation, so one must be made by us. Luckily, `uefi-rs` already implement one, so no needs to do it ourselves, however, it could be an empty function.

If you noticed, on the target config file it’s specified to pass a couple of parameters to the `lld` (LLVM linker) indicating the entry point (`uefi_start`) and the subsystem. So, the next spec is importing the uefi-rs crate and define a function named `uefi_start` with an infinite loop and check if it runs.

The `main.rs` file should be edited to have the following content:

```rust
#![no_std]
#![no_main]
#![feature(asm)]
#![feature(abi_efiapi)]

extern crate uefi;
extern crate uefi_services;

use uefi::prelude::*;

#[entry]
fn uefi_start(_image_handler: uefi::Handle, system_table: SystemTable<Boot>) -> Status {
    loop {}
    Status::SUCCESS
}
```
The first two lines indicated that out crate doesn’t have a main function and won’t use the std lib, also, the entry point is marked by using the `entry` attribute.

Finally, after building and running the application, QEMU will show something similar to the image below:

```sh
./build.py build && ./build.py run
```

{{ fit_image(path="blog/2020-08-10-an-efi-app-a-bit-rusty/step1-qemu.png", alt="QEMU running the UEFI application") }}

Nothing too interesting here, but since QEMU doesn’t enter in a boot loop or jump into the EFI shell it confirms that our application is being called.
The next step is printing the UEFI version on the screen. Once again, rust-rs already implement helper functions to deal with that, so is just initialize the logging system and use the `info!` macro to print out the text to screen and serial port too.

A new dependency needs to be added to `Cargo.toml` to access that `info!` macro:

```toml
log = { version = "0.4.11", default-features = false }
```

Then you just need to add the following code to the `uefi_start` function, before the infinity loop statement:

```rust
uefi_services::init(&system_table).expect_success("Failed to initialize utils");

// reset console before doing anything else
system_table
    .stdout()
    .reset(false)
    .expect_success("Failed to reset output buffer");

// Print out UEFI revision number
{
    let rev = system_table.uefi_revision();
    let (major, minor) = (rev.major(), rev.minor());

    info!("UEFI {}.{}", major, minor);
}
```

After build and running it, it will log something like `INFO: UEFI 2.70`, this value depends on the version of the firmware that you are running on.

To finalize let’s write a function that receives a reference for the Boot Services table and prints out the free usable memory regions.
Firstly we need to include the `alloc` crate to have access to the `Vec` structure, for that, these three lines must be added to the begging of the file:

```rust
#![feature(alloc)]  
// (...)
extern crate alloc;
// (...)
use crate::alloc::vec::Vec;
```

After that, we define a constant with the size of each EFI page, wish is `4KB` regardless of the system.

```rust
const EFI_PAGE_SIZE: u64 = 0x1000;
```

And then we finalize with the functions responsible for walking through the memory map searching for conventional memory and print the free ranges on the screen:

```rust
fn memory_map(bt: &BootServices) {
    // Get the estimated map size
    let map_size = bt.memory_map_size();

    // Build a buffer bigger enough to handle the memory map
    let mut buffer = Vec::with_capacity(map_size);
    unsafe {
        buffer.set_len(map_size);
    }

    let (_k, desc_iter) = bt
        .memory_map(&mut buffer)
        .expect_success("Failed to retrieve UEFI memory map");

    let descriptors = desc_iter.copied().collect::<Vec<_>>();

    assert!(!descriptors.is_empty(), "Memory map is empty");

    // Print out a list of all the usable memory we see in the memory map.
    // Don't print out everything, the memory map is probably pretty big
    // (e.g. OVMF under QEMU returns a map with nearly 50 entries here).

    info!("efi: usable memory ranges ({} total)", descriptors.len());
    descriptors
        .iter()
        .for_each(|descriptor| match descriptor.ty {
            MemoryType::CONVENTIONAL => {
                let size = descriptor.page_count * EFI_PAGE_SIZE;
                let end_address = descriptor.phys_start + size;
                info!(
                    "> {:#x} - {:#x} ({} KiB)",
                    descriptor.phys_start, end_address, size
                );
            }
            _ => {}
        })
}

// (...)
// Call this function inside main
memory_map(&system_table.boot_services());
```

The end result must be very similar to the following screenshot:

{{ fit_image(path="blog/2020-08-10-an-efi-app-a-bit-rusty/memory-map.png", alt="UEFI usable memory map") }}

And its done, not so hard right? 💪 Now is up to you continuing to implement new features to the application and maybe ending up writing a bootloader or a more complex UEFI application.

> Just one important note if you are adventurous enough. If you end up writing your own Operating System or learn a bit more about the way that things work you should put the APIs that UEFI offers to interact with the filesystem, networking, and accessing PCI devices, etc, apart and write your own drivers.
>
> Don't get lazy for having all these abstractions exposed to you. 😜
