+++
title = "Simulation, Emulation, and Virtualization"

[taxonomies]
categories = ["blog"]
tags = ["emulation", "virtualization"]

[extra]
comments=true
applause=true
+++

The word emulation appeared very close to the computer itself, since early engineers tried to run programs from other systems on their computers. As there were multiple platforms and architectures, everything was very incompatible, given the difference. Unfortunately, at the time, as the hardware was very slow and limited in its capacity, emulation was either impossible or very limited.

<!-- more -->

# Emulation

In a simple and summarized way, emulation is the act of executing code targeted to an external system, with a different architecture, through assembly conversion to a language that the host CPU can understand. This can be done in two ways, a higher level and a lower level - the latter being much more precise.

In high-level emulation, the application simply looks at someone else's instructions and tries to approximate them to a result close to the original. This was the only way to emulate until the mid-90s. This kind of approach is not so precise in its implementation.

However, in the low-level implementation, the emulator looks at the different instructions, components and tries to convert directly to instructions that the hardware in question can execute. This approach is much more precise, but obviously much more demanding.

Emulators were first used by console game developers who wanted a faster way to test games. With the advancement of 32-bit CPUs and with more complete operating systems, such as Windows 95 and Linux, the development of emulators took off, allowing running console games (called ROMs) on the computer.

{{ fit_image(path="blog/2021-07-17_lc-3-part-1/nes.jpg", alt="Nintendo Entertainment System", alt_link="https://unsplash.com/photos/mzOOPzRmCqE" ) }}

Emulator development remains a very active area today. There are entire communities with the goal of creating enough stable emulators to run any legacy game in a performant manner. There is a lot of controversy surrounding this topic due to the legality surrounding the ROMs of these older systems in the absence of licensed hardware, but it wasn't enough to stop this trend. 

Some examples of emulators are [Mesen](https://www.mesen.ca/), an emulator for the famous Nintendo console released in the 1980s, the NES; and [mgba](https://mgba.io/) which is an emulator for Gameboy. There are many, and even talking about old systems there are still many people/groups creating new ones. When it comes to computers, the most classic examples are [Bochs](https://bochs.sourceforge.io/) and [Qemu](https://www.qemu.org/) (even though it currently has virtualization capabilities).

# Simulation 

Creating and using simulations appear long before emulators. Its objective is to simulate real events with high precision in order to know their results. These systems came to be used during World War II, using vacuum tubes to calculate projectile trajectories and even many other outcomes of various war strategies.

In science, simulations play an essential role in understanding the universe and all of nature. Creating simulations based on complex models has enabled major advances in engineering, chemistry, astrophysics, meteorology, and much more.

{{ fit_image(path="blog/2021-07-17_lc-3-part-1/universe-simulation.jpg", alt="Simulation of Universe", alt_link="https://news.mit.edu/2019/early-galaxy-fuzzy-universe-simulation-1003" ) }}

It is important to note that simulations are increasingly complex. Consequently, the results are much more powerful and computationally demanding. Today, with modern computers, we are able to create very accurate simulations of the universe in its earliest stages.

An example of software that might fall into this category is Cisco's [Packet Tracer](https://www.netacad.com/courses/packet-tracer).

# Interpreters 

Some interpreters are also called virtual machines, but it has nothing to do with the software that allows you to emulate an entire operating system on it.

Interpreters were the natural next step after the rise of emulators. These systems use techniques very similar to high-level emulation to run the same program on multiple CPUs without the need for recompilation or adaptations. This is achieved by creating a virtual machine that interprets code very similar to assembly, known as bytecode.

This virtual machine is the only component that has to be adapted and recompiled targeting the architecture of each CPU, but modern compilers help a lot in this process, as the same compiler can emit binaries for multiple CPUs, all on the same machine - this is called the cross-compiling. This process allowed writing a program once and running it on multiple machines and different operating systems.

Some examples of languages that use this technique are [JAVA](https://en.wikipedia.org/wiki/Java_bytecode), JavaScript, [Erlang/Elixir](<https://en.wikipedia.org/wiki) /BEAM_(Erlang_virtual_machine)>) and more recently, we have [WebAssembly](https://webassembly.org/). Web Assembly uses the implementation of a VM to create a sandbox environment that allows you to completely isolate the running program and make it cross-platform.

# Virtualization 

At present, when talking about virtual machines or VMs, no one is referring to the classic concepts described above, but rather to the result of that technology. With the stabilization of some architectures, techniques, and computing power, virtualization was utterly inevitable.

Virtualization goes far beyond accurately emulating a computer's complete hardware. For example, when you want to virtualize a Windows or Linux x86 on a machine with the same architecture, you can take advantage of some extensions of the hardware itself, which allows you to discard the emulation of some parts and use the hardware directly.

{{ fit_image(path="blog/2021-07-17_lc-3-part-1/virtualization.png", alt="Virtualization Architecture", alt_link="https://insights.sei.cmu.edu/blog/virtualization-via-virtual-machines/" ) }}

With all the advances made in the area, CPU manufactures have considered the possibility of moving some layers of virtualization at the software level into the CPU itself, allowing self-virtualization. In the midst of some of these add-on CPU extensions, in the x86 world, we have [VT-x](https://www.intel.com/content/www/us/en/virtualization/virtualization-technology/intel-virtualization-technology.html) from Intel and [AMD-V](https://www.amd.com/en/technologies/virtualization-solutions) from AMD. With these extensions, virtualization became much more straightforward. However, there were some performance issues when it came to memory access, but they were soon resolved with the introduction of the Memory Management Unit's (MMU) virtualization.

In this category, we can find some better-known software such as [VirtualBox](https://www.virtualbox.org/) and [VMWare Fusion](https://www.vmware.com/products/fusion.html). Two famous virtualization software.

## Hypervisors

Allowed by the capabilities of the hardware to self-virtualize, hypervisors soon emerged. Hypervisors can be divided into two broad types: type 2 is equivalent to the virtualization described above; type 1 or BareMetal hypervisors systems are installed directly on hardware that does not resort to a host operating system and intermediates all virtual machines, handling all privileged accesses to the hardware.


Privileged access can be understood as configuring the paging tables (management of physical memory and mapping to virtual memory) or read/write to I/O ports. In short, the hypervisor validates all operations involving memory, and it performs the protected operations itself; I/O operations are mapped to the emulated device hardware rather than the emulated CPU.

When it comes to hypervisors, there are some quite famous in the industry, such as Microsoft [Hyper-V](https://en.wikipedia.org/wiki/Hyper-V) and [VMware ESXi](https://www.vmware.com/products/esxi-and-esx.html).

# Uses

There are many applications for virtualization, and I firmly believe there will be a lot more in the near future or even other levels of virtualization.

These days virtualization is used to run programs in isolated environments without affecting the host system, used to prevent a set of machines from crashing since if a VM goes down it doesn't compromise the others or the host system, running old systems in the same or a different machine or operating systems.

The applications are diverse and allow you to save lots of time and reduce costs in various scenarios.
