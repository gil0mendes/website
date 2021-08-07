+++
title = "Arquitetura do LC-3"

[taxonomies]
categories = ["blog"]
tags = ["emulation", "rust", "CPU"]

[extra]
comments=true
applause=true
+++

No post [anterior](@/blog/2021-07-17_lc-3-part-1/index.pt.md) falamos do que são emuladores e maquinas virtuais, quando surgiram, qual o seu estado e uso atualmente.

O que pretendo neste conjunto de artigos e explicar de uma forma simples e resumida o funcionamento de um computador e a melhor forma para o fazer é a criar um, não me refiro fisicamente, mas mais propriamente um emulador. Irei explicar e escrever algum código ao longo do artigo para isso irei recorrer a [Rust](https://www.rust-lang.org/) para a implementação do emulador e a arquitetura que vamos usar é do [LC-3](https://en.wikipedia.org/wiki/Little_Computer_3), visto que implementar um emulador para x86 é extremamente trabalhoso, mesmo que para um sistema antigo. Mais ainda, gostava de deixar a nota que muitos dos nomes de componentes e conceitos irei estar a usar as palavras em inglês para preservar ao máximo significado e diminuir qualquer ambiguidade, dentro do possível.

<!-- more -->

# O que é uma arquitetura?

Podemos dizer que a arquitetura de um computador é um conjunto de regras e métodos que descrevem a funcionalidade, organização e a implementação de um sistema de computação.

Um excelente exemplo de uma arquitetura de computador é a arquitetura de von Neumann, que continua a ser a base da maioria dos computadores, mesmo atualmente. Esta arquitetura foi proposta pelo brilhante matemático John von Neumann, a pessoa que podemos de apelidar como o tio do computador eletrónico ao lado do pai [Alan Turing](https://en.wikipedia.org/wiki/Alan_Turing).

{{ fit_image(path="blog/2021-07-25_lc-3-part-2/von_neumann_architecture.svg", alt="Arquitetura da Von Neumann", alt_link="https://en.wikipedia.org/wiki/Von_Neumann_architecture" ) }}

A proposta de arquitetura de Von Neumann para o computador eletrónico no ano de 1945 era composta por 5 partes principais, unidade de controlo, unidade lógica e aritmética (ALU), memoria, input e output. Nos computadores atuais a unidade de controlo e a ALU fundiram-se para se tornar o que conhecemos hoje por CPU.

O que falamos até agora foi do que é conhecido como _System Design_, mas quando se fala de arquitetura de computadores pode-se também estar a referir a Instruction Set Architecture (ISA) ou ainda a microarquitetura do computador.

## Instruction Set Architecture

Uma ISA é como fosse uma linguagem de programação embebida no CPU que contem e define os tipos de dados, registers, formas de endereçamento de memória, funções fundamentais para facilitar a criação de programas assim como o modelo de input/output. Alguns exemplos de ISAs bem conhecidos são o [x86](https://en.wikipedia.org/wiki/X86_instruction_listings), [MIPS](https://en.wikipedia.org/wiki/MIPS_architecture) e [ARM](https://en.wikipedia.org/wiki/ARM_architecture), mais recentemente é possível ver um crescente interesse no [RISC-V](https://en.wikipedia.org/wiki/RISC-V).

Como mencionado acima, para compreender melhor a forma como um computador funciona na sua génese iremos usar uma arquitetura simplificada que tenha uma ISA reduzida e simples, especificamente para aprendizagem; por isso vamos usar o [LC-3](https://en.wikipedia.org/wiki/Little_Computer_3). O LC-3 é o perfeito candidato porque é usado por várias universidades para ensinar programação em assembly para os alunos e porque tem um _instruction set_ muito reduzido [comparado com o x86](http://ref.x86asm.net/coder64.html), mas mesmo assim, contem as bases que um um CPU moderno também possui.

# Os nossos componentes

Como dito acima para a criação do nosso emulador vamos usar a linguagem [Rust](https://www.rust-lang.org/), por ser uma linguagem de sistema moderna e que eu tenho um carinho especial. Doravante, irei fazer uma breve explicação do que temos que fazer e acompanhar com código. No final de cada parte irei colocar um link para o GitHub onde contem todo o código referente a cada parte.

Esta na altura de criar um projeto usando o [Cargo](https://doc.rust-lang.org/cargo/) e criar dois módulos principais. Um será para contem o código do nosso emulador e outro ira conter o código para interagirmos com o emulador, a interface de comunicação.

## Memoria

O LC-3 é uma arquitetura de 16-bit, isso quer dizer que tem 65 536 posições de memória possíveis (podemos saber isso fazendo `2^16`) e cada uma com a capacidade de armazenar valores de 16-bit. Isto significa que a nossa maquina irá ter um total de 128kb de memória RAM. Parece muito pouco comparado aos computadores modernos, mas garanto que será mais que suficiente para corrermos alguns programas interessantes.

No nosso código a memória será representado por um simples vetor. Para organizar minimamente as coisas, vamos criar um modulo separado especialmente para a memória, onde mais tarde iremos implementar algumas funções de leitura e escrita.

```rust
/// Represents the size of a LC-3 memory.
const MEMORY_SIZE: usize = u16::MAX as usize;

pub struct Memory {
   /// Memory is a vector of 65_536 positions
   cells: [u16; MEMORY_SIZE],
}
```

## Registers

Os registers são uma categoria de armazenamento ultra rapido que ficam na própria CPU. Este tipo de armazenamento é acedido em apenas um ciclo de CPU, o que é extremamente rápido, dado que a ceder a memória normalmente leva mais do que apenas um ciclo.

Outra particularidade dos registers é que estes não possuem um endereço de memória, ou seja, não são endereçáveis, mais sim, afetados e acedidos através de instruções (como vamos poder ver mais à frente neste artigo). Uma tarefa regular da CPU é fazer cálculos, essa é a sua grande função juntamente com o controlo do fluxo de execução. Para fazer esses cálculos, a CPU tem que usar estas localizações para temporariamente armazenar os valores a serem usados nas operações. Visto que o número de registers é limitado a CPU fica constantemente a carregar valores de memória para os registers e no final das operações volta a colocar-los de volta em memória.

O LC-3 tem um total de 10 registers, cada um com exatamente 16 bits. A maioria são de uso geral, mas alguns tem o seu acesso limitado dado as suas funções especiais:

- 8 registos de uso geral (identificando-se de `R0-R7`)
- 1 registo para o program counter (`PC`)
- 1 registo com as flags de condição (`COND`)

Os registers de uso geral permitem realizar qualquer calculo que um programa necessite de executar. O program counter é um register inteiro sem sinal que contem o endereço de memória da próxima instrução a ser executada. E as flags de condição são quem dão informação relevante sobre o último cálculo realizado.

Para representar em código vamos criar um modulo para que representara a CPU e dentro dele outro para representar os registers.

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

Para armazenar o estado dos registers da CPU vamos usar uma struct, assim vamos facilmente perceber o que modificamos aquando a implementação de cada operação da CPU. Outra observação é que a estrutura das flags por agora está vazia, visto que vamos falar mais a frente delas.

A diretiva `derive(Default)` automaticamente vai implementar os valores por defeito nas estrutura, neste caso zerar todos os inteiros e colocar os booleanos a `false`. Isto vai ser útil mais tarde quando tivermos que inicializar as estruturas.

## Instruções

As instruções são os comandos que podemos dar a CPU. Estas instruções são operações fundamentais, ou seja, são operações simples como a adição entre dois números. Cada instrução é formada por duas partes, o **opcode** que indica que tarefa tem que ser executada e uma parte com os **parâmetros** dessa operação, algumas instruções não possuem parâmetros.

Podemos olhar para os opcodes como uma representação do que a CPU “sabe fazer”. O LC-3 contem um total de 16 opcodes. Tudo que o computador pode fazer e todos os programas que iremos executar nele, são apenas sequências destas 16 instruções.

{{ fit_image(path="blog/2021-07-25_lc-3-part-2/add-instruction-structure.png", alt="Estrutura da Instrução de Adição" ) }}

As instruções são de tamanho fixo, ocupando sempre 16 bits de cumprimento, os primeiros 4 bits são para armazenar o opcode e os restantes bits são para os parâmetros.

Num futuro post iremos falar em detalhe de cada uma das instruções, o que elas fazem e que efeitos têm no sistema. Existem muitas formas de implementar esta parte, mas a forma mais legível e para fins educacionais vamos criar uma enumeração com todas as instruções.

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

> **Nota:** Como podemos ver acima, o LC-3 tem uma quantidade muito reduzida de instruções, comparativamente com x86. Outras categorias de arquiteturas, como o ARM, que seguem uma filosofia [RISC](https://en.wikipedia.org/wiki/Reduced_instruction_set_computer) tem muitas menos do que o x86 (um processador [CISC](https://en.wikipedia.org/wiki/Complex_instruction_set_computer)), mas não existe nenhuma operação fundamental em falta. A grande diferença entre CISC e RISC é que um processador CISC contem múltiplas instruções complexas e que necessitam de mais ciclos de CPU e que facilitam a escrita de assembly, contra instruções mais simples e leves do RISC que requerem mais instruções para fazer operações mais complexas. Dado o anteriormente referido o CISC é muito mais complexo para engenheiros desenharem e produzirem uma CPU. Existe uma razão para isto ter sido assim e o porquê de estarmos a assistir uma mudança nas CPUs que dominam o nosso dia a dia. [Aqui](https://cs.stackexchange.com/questions/269/why-would-anyone-want-cisc) fica uma breve, mas completa, explicação de algumas das razões.

## Flags de Condição

A CPU necessita de uma forma de manter estado do resultado de algumas operações, como, por exemplo, quando existe uma operação de comparação `if x > 0 { … }`. Esse estado pode ser usado pela próxima instrução de modo a saber, neste caso, se a condição é verdadeira ou falsa. É desta forma que é possível fazer saltos condicionais.

Cada CPU tem a sua variação de flags de condição, no caso do LC-3 existem apenas 3:

- Negativo
- Zero
- Positivo

Estas flags vão dizermos o sinal da opção anterior. Para representar as mesmas vamos adicionar novas propriedades a estrutura `Flags` que criamos anteriormente.

```rust
/// LC-3 CPU condition flags
pub struct Flags {
   pub negative: bool,
   pub zero: bool,
   pub positive: bool,
}
```

# Conclusão

Com isto terminamos de criar os componentes base do nosso emulador. No próximo post vamos olhar para alguns exemplos de assembly LC-3 e como implementar algumas das instruções. Para ver todo o código implementado nesta parte um vasta [aceder ao GitHub](https://github.com/gil0mendes/rust-lc3/tree/part-1/).

# Referencias

- [https://www.techopedia.com/definition/26757/computer-architecture](https://www.techopedia.com/definition/26757/computer-architecture)
- [https://en.wikipedia.org/wiki/Computer_architecture](https://en.wikipedia.org/wiki/Computer_architecture)
- [https://en.wikipedia.org/wiki/Little_Computer_3](https://en.wikipedia.org/wiki/Little_Computer_3)
- [https://en.wikipedia.org/wiki/Processor_register](https://en.wikipedia.org/wiki/Processor_register)
