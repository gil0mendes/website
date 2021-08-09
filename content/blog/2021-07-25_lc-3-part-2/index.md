+++
title = "LC-3 Architecture"

[taxonomies]
categories = ["blog"]
tags = ["emulation", "rust", "CPU"]

[extra]
comments=true
applause=true
+++

In the [previous post](@/blog/2021-07-17_lc-3-part-1/index.md) we talked about what emulators and virtual machines are, when they appeared, what is their current status and use.

What I want in this set of articles is to explain in a simple and summarized way how a computer works and the best way to do it is to create one, I don't mean physically, but rather an emulator. I will explain and write some code throughout the article. To implement the emulator I'll use [Rust](https://www.rust-lang.org/) and the architecture we are going to use is from [LC-3](https://en.wikipedia.org/wiki/Little_Computer_3), since implementing an emulator for x86 is extremely laborious, even for an old system.

<!-- more -->

# What is an architecture?

We can say that the architecture of a computer is a set of rules and methods that describe the functionality, organization and implementation of a computer system.

An excellent example of a computer architecture is the von Neumann architecture, which remains the foundation of most computers even today. This architecture was proposed by the brilliant mathematician John von Neumann, the person we can dub the uncle of the electronic computer next to his father [Alan Turing](https://en.wikipedia.org/wiki/Alan_Turing).

{{ fit_image(path="blog/2021-07-25_lc-3-part-2/von_neumann_architecture.svg", alt="Von Neumann Architecture", alt_link="https://en.wikipedia.org/wiki/Von_Neumann_architecture" ) }}

Von Neumann's architecture proposal for the electronic computer in the year 1945 is composed of 5 main parts, Control Unit (CU), Arithmetic and Logic Unit (ALU), memory, input and output (I/O). In today's computers the control unit and the ALU have merged to become what we know today as the CPU.

What we have been talking about so far is what is known as _System Design_, but when it comes to computer architecture, we can also refer to Instruction Set Architecture (ISA) or even a micro-architecture of the computer.

## Instruction Set Architecture

An ISA is like a programming language embedded in the CPU that contains and defines data types, registers, ways of addressing memory, fundamental functions to facilitate the creation of programs as well as the I/O model. Some examples of well-known ISAs are [x86](https://en.wikipedia.org/wiki/X86_instruction_listings), [MIPS](https://en.wikipedia.org/wiki/MIPS_architecture), and [ARM](https://en.wikipedia.org/wiki/ARM_architecture). More recently you can see a growing interest in [RISC-V](https://en.wikipedia.org/wiki/RISC-V).

As mentioned above, to better understand how a computer works in its genesis we will use a simplified architecture that has a reduced and simple ISA, specifically for learning; so we are going to use [LC-3](https://en.wikipedia.org/wiki/Little_Computer_3). The LC-3 is the perfect candidate because it is used by several universities to teach assembly programming to students and because it has a very small _instruction set_ [compared to x86](http://ref.x86asm.net/coder64.html), but even so, it contains the foundations that a modern CPU also has.

# Our Components

As stated above for the creation of our emulator we will use the [Rust](https://www.rust-lang.org/) language, as it is a modern system language and I have a special affection. From now on, I will make a brief explanation of what we have to do and follow up with code. At the end of each part I will put a link to GitHub where it contains all the code referring to each part.

It's time to create a project using [Cargo](https://doc.rust-lang.org/cargo/) and create two main modules. One will be to contain our emulator code and the other will contain the code to interact with the emulator, the communication interface.

## Memory

The LC-3 is a 16-bit architecture, meaning that it has 65,536 possible memory locations (we can know this by doing `2^16`) and each with the capacity to store 16-bit values. This means that our machine will have a total of 128kb of RAM memory. It seems very little compared to modern computers, but I guarantee it will be more than enough for us to run some interesting programs.

In our code memory will be represented by a simple vector. To minimally organize things, let's create a separate module especially for memory, where later we'll implement some read and write functions.

```rust
/// Represents the size of a LC-3 memory.
const MEMORY_SIZE: usize = u16::MAX as usize;

pub struct Memory {
   /// Memory is a vector of 65_536 positions
   cells: [u16; MEMORY_SIZE],
}
```

## Registers

Registers are an ultra-fast storage category that resides on the CPU itself. This type of storage is accessed in just one CPU cycle, which is extremely fast, as memory usually takes more than just one cycle.

Another peculiarity of registers is that they do not have a memory address, that is, they are not addressable, but rather, affected and accessed through instructions (as we will see later in this article). A regular CPU task is to do calculations, this is its great function along with controlling the flow of execution. To make these calculations, the CPU has to use these locations to temporarily store the values to be used in the operations. Since the number of registers is limited, the CPU is constantly loading values from memory into the registers and at the end of operations put them back into memory.

The LC-3 has a total of 10 registers, each exactly 16 bits long. Most are for general use, but some have limited access to their special functions:

- 8 general purpose registers (identifying as `R0-R7`)
- 1 register for the program counter (`PC`)
- 1 register with condition flags (`COND`)

General purpose registers allow you to perform any calculation that a program needs to run. The program counter is an unsigned integer register that contains the memory address of the next instruction after execution. And the condition flags are what provide relevant information about the last calculation performed.

To represent it in code, let's create a module to represent a CPU and inside it another one to represent the registers.

```rust
/// LC-3 CPU condition flags
#[derive(Default)]
pub struct Flags {}

/// LC-3 CPU registers
#[derive(Default)]
pub struct Registers {
   /// General purpose register 0
   pub r0: u16,
   /// General purpose register 1
   pub r1: u16,
   /// General purpose register 2
   pub r2: u16,
   /// General purpose register 3
   pub r3: u16,
   /// General purpose register 4
   pub r4: u16,
   /// General purpose register 5
   pub r5: u16,
   /// General purpose register 6
   pub r6: u16,
   /// General purpose register 7
   pub r7: u16,
   /// Program counter
   pub pc: u16,
   // Condition flags
   pub flags: Flags,
}
```

To store the state of the CPU registers we will use a struct, so we will easily see what we modify when implementing each CPU operation. Another observation is that the structure of the flags for now is empty, since we'll talk about them later.

The `derive(Default)` directive will automatically implement the default values in the structures, in this case zeroing out all integers and setting booleans to `false`. This will come in handy later when we have to initialize the structures.

## Instructions

Instructions are the commands we can give to the CPU. These instructions are fundamental operations, that is, they are simple operations like adding between two numbers. Each instruction is formed by two parts, the **opcode** that indicates which task has to be executed and a part with the **parameters** of the operation, some instructions have no parameters.

We can look at opcodes as a representation of what the CPU “knows how to do”. The LC-3 contains a total of 16 opcodes. Everything the computer can do and all the programs that we will run on it are just sequences of these 16 instructions.

{{ fit_image(path="blog/2021-07-25_lc-3-part-2/add-instruction-structure.png", alt="Addition Instruction Structure " ) }}

The instructions are of fixed length, always occupying 16 bits long, the first 4 bits are for storing the opcode and the remaining bits are for the parameters.

In a future post we will talk in detail about each of the instructions, what they do and what effects they have on the system. There are many ways to implement this part, but the most readable way and for educational purposes we will create an enumeration with all the instructions.

```rust
//! CPU instructions declaration and  decoder

/// LC-3 Instructions
pub enum Instructions {
   /// branch
   BR,
   /// add
   ADD,
   /// load
   LD,
   /// store
   ST,
   /// jump register
   JSR,
   /// bitwise and
   AND,
   /// load register
   LDR,
   /// store register
   STR,
   /// unused
   RTI,
   /// bitwise not
   NOT,
   /// load indirect
   LDI,
   /// store indirect
   STI,
   /// jump
   JMP,
   /// reserved (unused)
   RES,
   /// load effective address
   LEA,
   /// execute trap
   TRAP,
}
```

> **Note:** As we can see above, the LC-3 has a very reduced amount of instructions compared to x86. Other categories of architectures, such as ARM, which follow a [RISC](https://en.wikipedia.org/wiki/Reduced_instruction_set_computer) philosophy have much less instructions than x86 ([CISC](https://en.wikipedia.org/wiki/Complex_instruction_set_computer)), but there is no fundamental operation missing. The big difference between CISC and RISC is that a CISC processor contains multiple complex instructions that require more CPU cycles and facilitate assembly writing, versus simpler and lighter RISC instructions that require more instructions to do more complex operations. Given the above, CISC is much more complex for engineers to design and produce a CPU. There is a reason why this has been so and why we are witnessing a shift in CPUs that dominate our everyday lives. [Here](https://cs.stackexchange.com/questions/269/why-would-anyone-want-cisc) is a brief but complete explanation of some of the reasons.

## Condition Flags

The CPU needs a way to maintain state of the result of some operations, for example, when there is an `if x > 0 { … }` compare operation. This state can be used by the next instruction to know, in this case, whether the condition is true or false. This is how it is possible to make conditional jumps.

Each CPU has its variation of condition flags, in the case of the LC-3 there are only 3:

- Negative
- Zero
- Positive

These flags will say the sign of the previous option. To represent them, let's add new properties to the `Flags` structure we created earlier.

```rust
/// LC-3 CPU condition flags
pub struct Flags {
   pub negative: bool,
   pub zero: bool,
   pub positive: bool,
}
```

# Conclusion

With this we finish creating the base components of our emulator. In the next post we will look at some LC-3 assembly examples and how to implement some of the instructions. To see all the code implemented in this part please [access GitHub](https://github.com/gil0mendes/rust-lc3/tree/part-1/).

# References

- [https://www.techopedia.com/definition/26757/computer-architecture](https://www.techopedia.com/definition/26757/computer-architecture)
- [https://en.wikipedia.org/wiki/Computer_architecture](https://en.wikipedia.org/wiki/Computer_architecture)
- [https://en.wikipedia.org/wiki/Little_Computer_3](https://en.wikipedia.org/wiki/Little_Computer_3)
- [https://en.wikipedia.org/wiki/Processor_register](https://en.wikipedia.org/wiki/Processor_register)
