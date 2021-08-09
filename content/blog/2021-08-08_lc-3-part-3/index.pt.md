+++
title = "LC-3 Implementação de Instruções"

[taxonomies]
categories = ["blog"]
tags = ["emulation", "rust", "CPU"]

[extra]
comments=true
applause=true

image = "blog/2021-08-08_lc-3-part-3/add-to-machine.png"
+++

Na [parte anterior](@/blog/2021-07-25_lc-3-part-2/index.pt.md) descrevemos alguns dos componentes principais do nosso emulador, hoje é altura de implementar algumas instruções da nossa CPU, mas primeiro vamos olhar para algum assembly exemplo.

O objetivo desta série não é ensinar assembly, mas precisamos de um binário de testes que iremos usar para testar a implementação do nosso sistema. Para esse efeito criei um simples código assembly que incrementa o register R0 em 1 até chegar a 10:

```asm
.ORIG x3000

AND R0, R0, 0     ; clear R0
LOOP              ; label to indicate the start of our loop
ADD R0, R0, 1     ; add 1 to R0 and store the result into R0
ADD R1, R0, -10   ; subtract 10 from R0 and store the result on R1
BRn LOOP

HALT              ; halt the program
.end              ; mark the end of the file
```

Com o pequeno programa acima já conseguimos implementar as primeiras instruções e validar a implementação verificando o valor dos registers. O programa acima seria uma espécie de ciclo while, se fosse codificado em outras linguagens, por exemplo em C.

Como podemos ver, os nomes em algumas declarações correspondem a alguns opcodes definidos no artigo anterior. Nesse mesmo artigo falamos que cada instrução tem sempre um tamanho fixo de 16 bits, mas claramente existe um número diferente de caracteres por cada comando. Como é possível isto funcionar?

Isto funciona porque o código que escrevemos é assembly, sendo uma forma mais amigável para nós humanos ler e escrever o código e codificado em plain text. Com este código, usa-se um assembler que o que ele faz é converter cada uma das instruções em linguagem máquina. Muita gente confunde linguagem máquina com assembly, mas, na verdade, linguagem máquina são apenas zeros e uns, como se pode conferir na imagem abaixo.

{{ fit_image(path="blog/2021-08-08_lc-3-part-3/add-to-machine.png", alt="Assembly para Linguagem Máquina" ) }}

Cada instrução é convertida num conjunto binário de 16 bits, este sim, é o código interpretado pela CPU, no nosso caso, pelo emulador.

> **Nota:** À primeira vista, um assembler e um compilador parecem ferramentas muito similares, mas na realidade elas são diferentes. Um compilador interpreta uma gramática e converte isso em assembly. O código produzido não é direto, ou seja, o que se escreve na linguagem original normalmente corresponde a um maior conjunto de operações em assembly. Já um assembler pega no código escrito pelo programador, substitui os símbolos necessários e converte diretamente cada operação numa representação binária, produzindo assim um conjunto de instruções.

O comando `.ORIG` e outros começados por um ponto (`.`) podem parecer instruções, mas são diretivas do assembler. Podemos olhar para estas diretivas como sendo uma espécie de macro que irá gerar um conjunto de código ou dados. O ORIG define o endereço onde o programa será carregado em memória, isto, é usado pelo assembler para definir endereços de memória, por exemplo, em operações de offset.

Ainda relacionado com o ORIG, quando queremos criar um loop (similar a um for ou while), usamos labels. Labels são marcadores que não ocupam espaço no binário final, eles apenas identificam uma posição de memória no binário relativamente à ORIG definida no início do código. Dessa forma as labels podem ser usadas em operações de jump, onde o fluxo de execução de um programa salta para outra posição. Na hora da conversão o assembler substitui todos os usos dos labels pelos seus endereços de memória correspondentes.

# Fetch, Decode, Execute

A fim das instruções serem executadas pelo processador estas têm que ser carregadas em memória. Isto acontece através de um ciclo de fetch, como se pode ver na imagem abaixo.

{{ fit_image(path="blog/2021-08-08_lc-3-part-3/fetch-decode-execute.png", alt="Ciclo Fetch" ) }}

O ciclo _fetch-decode-execute_ define três etapas, as que compõem o nome. O **fetch** é o ato de carregar a próxima instrução da memória, cujo o seu endereço é indicado pelo registo PC (Program Counter), no final desta operação o PC passa a apontar para a próxima instrução. Na fase de **decode** a instrução carregada é descodificada a fim da CPU saber qual a operação tem que executar. É também nesta fase que qualquer endereço relativo é convertido num endereço absoluto. Depois, na fase de **execute** a Unidade de Controlo (CU) da CPU envia os comandos relativos à fase de decode para a parte de CPU responsável pela instrução descodificada. Uma nota importante aqui é que algumas operações podem alterar o endereço que o PC guarda, isto pode acontecer com uma operação de jump ou branching. Por fim, todas as fases anteriores são repetidas na mesma sequência até que a CPU entre num estado de halt.

## Ciclo de Execução

Agora que sabemos, de uma forma bem resumida e direcionada para a nossa arquitetura LC-3, como a máquina funciona, já estamos em condições de implementar o ciclo inicial do nosso emulador.

Como anteriormente falado, não é necessário saber assembly para implementar o emulador, apenas mostrei alguns exemplos para dar uma ideia base do que é que o emulador faz. E com isto já conseguimos implementar a parte central do emulador onde implementamos o ciclo de fetch-decode-execute. De uma forma resumida as etapas a implementar são:

1. Carregar uma instrução da memória do endereço para o qual o PC aponta;
2. Incrementar o PC;
3. Olhar para o opcode para determinar a instrução que é para executar;
4. Executar a instrução usando os parâmetros da mesma;
5. Voltar a repetir todas as etapas nesta ordem.

## Inicialização da Máquina

De modo a conseguirmos carregar um binário para ser executado vamos usar um argument parser (neste caso o [Clap](https://clap.rs/)) para especificar os argumentos que o nosso programa aceita. Primeiramente adicionamos a nova dependência ao ficheiro Cargo.toml:

```toml
[dependencies]
clap = "2.33.3"
```

Agora na nossa função main vamos adicionar a lógica para fazer parse dos argumentos. O Clap tem várias formas de descrever os argumentos do terminal, mas para fazermos menos magia Rust vamos usar o builder pattern tão presente em muitas outras linguagens.

```rust
use clap::{App, Arg, ArgMatches};

// (...)

/// Get matched arguments
fn build_command_line<'a>() -> ArgMatches<'a> {
 App::new("lc3emu")
     .version("1.0")
     .author("Gil Mendes <gil00mendes@gmail.com>")
     .about("A LC3 emulator written in Rust")
     .arg(
         Arg::with_name("ROM")
             .help("ROM to be executed")
             .required(true)
             .index(1),
     )
     .get_matches()
}

fn main() {
 // Build command line and get the matched arguments
 let matches = build_command_line();
 println!("=> {:?}", matches);
}
```

Agora, se corremos o comando `cargo run -- --help` iremos ver todos os argumentos suportados pelo nosso programa. Como está expresso no código vai ser possível ver que o primeiro argumento é de facto a nossa ROM. De modo a termos uma base de testes, no repositório onde partilho o código do emulador, irei criar uma pasta com binários de exemplo. Por agora, o binário que irei colocar lá será o exemplo que expus anteriormente.

Neste primeiro argumento, a ROM, vamos usar para passar o caminho do binário. Por agora, vamos usar o que está na pasta `examples/1-count/count.obj`. A primeira parte é extrair o argumento do parser e obter um vetor do tipo `u8` (ou seja, 8 bits) com os dados do binário. O ideal seria de 16 bits, visto que é o tamanho de cada instrução do LC3, mas o Rust apenas retorna um vetor de 8 bits.

```rust
/// Read ROM content as 8-bit integer vector
fn read_room<P: AsRef<Path>>(path: P) -> Vec<u8> {
   // read file
   let mut file = File::open(path).unwrap();

   // create a new vector to hold the instructions
   let mut file_buffer = Vec::new();

   // get the file content into the buffer
   file.read_to_end(&mut file_buffer).unwrap();
   file_buffer
}
```

A função apresentada acima recebe um Path que após ler o ficheiro devolve o vetor com a integridade dos dados do ficheiro. Agora no nosso `main` podemos chamar esta função para obter os dados do binário que teremos de carregar em memória.

```rust
// read file content into a vector
let rom_path = matches.value_of("ROM").unwrap();
let rom_data = read_room(rom_path);
```

## Carregamento em memória

Agora que temos acesso aos bytes do nosso binário está na hora de desenvolver um pouco mais a nossa estrutura de memória, que criamos na parte anterior e adicionar métodos que permitam a escrita e leitura da mesma.

```rust
impl Memory {
   /// Create a new memory instance
   pub fn new() -> Self {
       Self {
           cells: [0; MEMORY_SIZE],
       }
   }

   /// Read a 16 bit value from the given address
   pub fn read(&self, address: u16) -> u16 {
       self.cells[address as usize]
   }

   /// Write a 16 bit value into the given address
   pub fn write(&mut self, address: u16, data: u16) {
       self.cells[address as usize] = data
   }
}
```

Isto é apenas uma implementação simplificada, que posteriormente terá que ser expandida para acomodar alguns I/O registers, mais tarde falaremos disso. Agora podemos pegar num endereço de memória de 16 bit e ler ou escrever um valor de igual tamanho.

De seguida, vamos ao nosso ficheiro `emulator/mod.rs` e implementar uma estrutura simples que inicia a estrutura de memória e escreve os dados do binário carregado na mesma.

```rust
pub struct Emulator {
   memory: Memory,
}

impl Emulator {
   pub fn new(binary_data: Vec<u8>) -> Self {
       let mut emulator = Self {
           memory: Memory::new(),
       };

       // first 16 bit entry is the base address here the binary must be loaded
       let mut address = (binary_data[0] as u16) << 8 | (binary_data[1] as u16);

       // load the rest of the binary on the memory
       let mut i = 2;
       let limit = Vec::len(&binary_data);
       while i + 1 <= limit {
           let data = (binary_data[i] as u16) << 8 | (binary_data[i + 1] as u16);
           emulator.memory.write(address, data);

           i += 2;
           address += 1;
       }

       emulator
   }
}
```

Com o ciclo acima, são carregamos os dados do binário na memória no sítio especificado pela diretiva `ORIG`. A primeira entrada de 16 bits é na realidade a posição em memória onde devemos carregar o nosso programa.

Por fim, vamos ao nosso main e criamos uma nova instância do emulador usando o método new que acabamos de implementar.

```rust
let emulator = Emulator::new(rom_data);
```

Agora a memória contém o nosso binário colocado na posição `0x3000`. Se pretenderem ver o conteúdo da mesma, pode ser feito usando a diretiva Debug, do Rust, nas estruturas Emulator e Memory.

## Fetch de Instruções

O próximo passo é criar o mecanismo que obtêm a próxima instrução em memória, cujo endereço é apontado pelo register PC. Para isso vamos criar um ciclo infinito que vai chamar um método next_tick que irá ser implementado na CPU (visto que a nossa CPU combina a unidade de controlo e a ALU em apenas um componente). Este método recebe como argumento uma referência mutável para a nossa memória e será responsável por fazer o fetch da instrução, incrementar o PC e por fim executar a instrução propriamente dita (mas isto iremos fazer depois).

Assim sendo, no ficheiro `cpu/mod.rs` vamos criar a estrutura da CPU e o método acima falado.

```rust
/// This is the default PC value when the CPU starts
const DEFAULT_PC: u16 = 0x3000;

/// LC-3 CPU
pub struct CPU {
   /// CPU registers and flags
   registers: Registers,
}

impl CPU {
   /// Create a new CPU instance
   pub fn new() -> Self {
       let mut cpu = Self {
           registers: Registers::default(),
       };

       // define default PC address
       cpu.registers.pc = DEFAULT_PC;

       cpu
   }

   /// Borrow CPU registers to external consult
   pub fn get_registers(&self) -> &Registers {
       &self.registers
   }


   pub fn next_tick(&mut self, memory: &Memory) {
       // get the next instruction in memory
       let instruction_raw = memory.read(self.registers.pc);

       // increment PC
       self.registers.pc += 1;

       // TODO: process instruction
   }
}
```

Por design, o LC-3 quando é iniciado, o seu `PC` aponta para o endereço `0x3000` e isso é o que estamos a fazer após a criação da instância da nossa CPU. Adicionamos também um método que permite obter o estado dos registers, isto será útil mais á frente.

Agora, vamos criar um método execute na estrutura do nosso emulator. Este método é para o ciclo de execução e também para verificar se o nosso PC passa do limite máximo de memória. Mais tarde poderemos fazer mais algumas otimizações e saber se a CPU está num estado de halt e assim parar o ciclo de execução.

```rust
pub struct Emulator {
   memory: Memory,
   cpu: CPU,
}

// (...)

/// Initiate the execution loop
   pub fn execute(&mut self) {
       loop {
           self.cpu.next_tick(&mut self.memory);

           if self.cpu.get_registers().pc >= MEMORY_SIZE as u16 {
               println!("Emulator: out of memory bound");
               break;
           }
       }
   }
```

Após tornar o `MEMORY_SIZE` no módulo de memória público, adicionamos a CPU a estrutura do Emulador e criamos o nosso método para iniciar o loop de execução. Isto após chamar o método no main, como podem ver aqui:

```rust
let mut emulator = Emulator::new(rom_data);
emulator.execute();
```

Ao executar de novo o nosso programa, será esperado que veja a seguinte mensagem:

```text
Emulator: out of memory bound
```

Isto acontece porque o nosso Program Counter foi incrementado em cada ciclo da CPU até sair fora dos limites da memória, tal como a verificação feita no método execute do emulador.

## Descodificação e Execução

Para finalizar, por hoje, vamos implementar o código necessário para criar o decoder das instruções e implementar a primeira instrução do nosso binário.

A tabela abaixo mostra todas as instruções existentes no computador LC-3 e a anatomia de cada uma delas em termos de bits.

{{ fit_image(path="blog/2021-08-08_lc-3-part-3/lc-3-opcodes.png", alt="ISA do LC-3" ) }}

Se tomarmos atenção podemos ver que os primeiros 4 bits são os bits que identificam a instrução codificada nos 16 bits, os restantes são os parâmetros codificados com a instrução.

Vamos ver um exemplo da nossa primeira instrução do nosso programa exemplo. A instrução em binário corresponde a **0101 000 000 1 00000**. Olhando para os primeiros quatro bits e procurando na tabela acima, conseguimos ver que a instrução em questão é uma operação de AND e se olharmos para o bit 5 (conta-se ao contrário e começa-se em zero) podemos ver o bit 1, isso quer dizer que estamos perante uma comparação entre um register e um valor imediato. A tabela abaixo identifica o que cada conjunto de valores quer dizer:

| Valor | Representação                                                                  |
| ----- | ------------------------------------------------------------------------------ |
| 0101  | Corresponde a operação de comparação                                           |
| 000   | Destino da operação, neste caso R0                                             |
| 000   | Primeiro operando, neste caso R0                                               |
| 1     | Indica que o próximo conjunto de bits são correspondentes a um escalar inteiro |
| 00000 | Valor zero                                                                     |

Agora que sabemos como compreender a primeira instrução do nosso binário, vamos criar o código que faz a descodificação das instruções e implementar esta primeira instrução.

No módulo das instruções vamos implementar uma função para facilitar a conversão entre um `u16` para a Enum que contém todas as instruções. Isto irá facilitar a leitura de código porque iremos usar Enum em vez de números:

```rust
impl Instructions {
   /// Get instruction from u16
   pub fn get(opcode: u16) -> Option<Instructions> {
       match opcode {
           0 => Some(Self::BR),
           1 => Some(Self::ADD),
           2 => Some(Self::LD),
           3 => Some(Self::ST),
           4 => Some(Self::JSR),
           5 => Some(Self::AND),
           6 => Some(Self::LDR),
           7 => Some(Self::STR),
           8 => Some(Self::RTI),
           9 => Some(Self::NOT),
           10 => Some(Self::LDI),
           11 => Some(Self::STI),
           12 => Some(Self::JMP),
           13 => Some(Self::RES),
           14 => Some(Self::LEA),
           15 => Some(Self::TRAP),
           _ => None,
       }
   }
}
```

Vamos também implementar um método na estrutura Registers que permite definir e ler registers usando os seus índices. Os _registers_ de uso geral são numerados de `000` a `111` binário.

```rust
impl Registers {
   /// Read a register state by its index
   pub fn get(&self, index: u16) -> u16 {
       match index {
           0 => self.r0,
           1 => self.r1,
           2 => self.r2,
           3 => self.r3,
           4 => self.r4,
           5 => self.r5,
           6 => self.r6,
           7 => self.r7,
           _ => panic!("Registers: index out of bound"),
       }
   }

   /// Set a register state by its index
   pub fn set(&mut self, index: u16, value: u16) {
       match index {
           0 => self.r0 = value,
           1 => self.r1 = value,
           2 => self.r2 = value,
           3 => self.r3 = value,
           4 => self.r4 = value,
           5 => self.r5 = value,
           6 => self.r6 = value,
           7 => self.r7 = value,
           _ => panic!("Registers: index out of bound"),
       }
   }
}
```

Já no módulo da CPU vamos criar três novos métodos. A função `next_opcode`, que vai ser responsável por chamar o método de _decode_ e vai chamar a função correspondente para cada uma das operações. A função que implementa a função AND. Por fim, uma função especial que permite expandir um valor imediato (escalar) de um X número de bits em um novo valor de 16-bit usando o Two’s Complemente.

No nosso sistema os números são negativos quando o último bit é 1. Por isso, ao converter os valores deveremos ter em atenção esse detalhe. Números positivos apenas temos que aumentar o número de bits, para os números negativos, acrescentar 1s à esquerda até que tenhamos 16 bits no total.

```rust
/// Process the next opcode
pub fn next_opcode(&mut self, instruction: u16) {
    let opcode_raw = instruction >> 12;
    let opcode = Instructions::get(opcode_raw);

    match opcode {
        Some(Instructions::AND) => self.opcode_and(instruction),
        _ => panic!("CPU: instruction ({:?}) not implemented", opcode.unwrap()),
    };
}


/// Sign-extend a small value into a 16-bit one using two's complements
fn sign_extend(&self, mut value: u16, num_bits: u16) -> u16 {
    if (value >> (num_bits - 1)) & 1 != 0 {
        value |= 0xFFFF << num_bits
    }

    value
}

/// AND operator
///
/// If bit [5] is 0, the second source operand is obtained from SR2.
/// If bit [5] is 1, the second source operand is obtained by sign-extending the imm5 field to 16 bits.
/// In both cases, the second source operand is added to the contents of SR1 and the result stored in DR. The
/// condition codes are set, based on whether the result is negative, zero, or positive.
fn opcode_and(&mut self, instruction: u16) {
    let dest = (instruction >> 9) & 0x7;
    let src1 = (instruction >> 6) & 0x7;
    let is_imm = (instruction >> 5) & 0x1 == 1;

    let new_value = if is_imm {
        let src2 = self.sign_extend(instruction & 0x1F, 5);
        self.registers.get(src1) & src2
    } else {
        let src2 = instruction & 0x7;
        self.registers.get(src1) & self.registers.get(src2)
    };

    self.registers.set(dest, new_value);
    self.registers.flags.update(new_value);
}
```

Como é possível ver acima, para facilitar o update das flags, criamos um método na estrutura `Flags`.

```rust
impl Flags {
   /// Update flags based on the given value
   pub fn update(&mut self, value: u16) {
       // reset all flags
       self.negative = false;
       self.zero = false;
       self.positive = false;

       if value == 0 {
           self.zero = true
       } else if (value >> 15) != 0 {
           self.negative = true;
       } else {
           self.positive = true;
       }
   }
}
```

Depois de tudo isto, não podemos esquecer de chamar a função `self.next_opcode(instruction_raw);` no método `next_tick`. Para validar que todo o nosso código está ok, ao correr o cargo irá aparecer uma mensagem a dizer que o opcode ADD não está implementado.

```
CPU: instruction (ADD) not implemented
```

# Conclusão

E com isto o nosso emulador é agora capaz de fazer carregar binários na memória, fazer o fetch de instruções, descodificar cada instrução a fim de saber que operação tem que ser executada, sabendo já como lidar com o opcode AND. Como antes, no [GitHub](https://github.com/gil0mendes/rust-lc3/tree/part-2) tem todo o codigo desta parte.

Na próxima parte iremos implementar mais algumas instruções para conseguirmos correr o programa por completo e ver o estado dos registers.

# Referencias

- https://blueaccords.gitbooks.io/lc-3-reference/content/op-codes.html
