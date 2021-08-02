+++
title = "Simulação, Emulação e Virtualização"

[taxonomies]
categories = ["blog"]
tags = ["emulation", "virtualization"]

[extra]
comments=true
applause=true
+++

A palavra emulação tem origem muito próxima do próprio computador, desde cedo engenheiros tentaram executar programas de outros sistemas nos seus computadores, dado que existiam múltiplas plataforma e arquiteturas, tudo era muito incompatível dada a diferença. Infelizmente, na altura, dado ao hardware ser muito lento e limitado na sua capacidade, a emulação era impossível ou muito limitada.

<!-- more -->

# Emulation

De uma forma simples e resumida, emulação é o ato de executar código destinado a um sistema externo, com uma arquitetura diferente, através da conversão de assembly para uma linguagem que o CPU hospedeiro consegue entender. Isto pode ser feito de duas formas, uma mais alto nível e outra mais baixo nível - sendo esta última bem mais precisa.

Na emulação de alto nível, a aplicação simplesmente olha para as instruções alheias e tenta aproximá-las a um resultado aproximado ao original. Esta era a única forma de emular até meados dos anos 90. Este tipo de abordagem não é tão precisa na sua implementação.

No entanto, na implementação de baixo nível, o emulador olha para as diferentes instruções, componentes e tenta converter de forma direta para instruções que o hardware em questão consegue executar. Já esta abordagem e muito mais precisa, mas obviamente muito mais exigente.

Os emuladores começaram por ser usados por desenvolvedores de jogos para consolas que queria uma forma mais rápida de testar os jogos. Com o avanço dos CPUs de 32-bit e com sistemas operativos mais completos, como Windows 95 e Linux, o desenvolvimento de emuladores disparou o que permitiu correr jogos de consola (chamados ROMs) no computador.

{{ fit_image(path="blog/2021-07-17_lc-3-part-1/nes.jpg", alt="Nintendo Entertainment System", alt_link="https://unsplash.com/photos/mzOOPzRmCqE" ) }}

O desenvolvimento de emuladores continua a ser uma área muito ativa nos dias de hoje. Existem comunidades inteiras com o objetivo de criar emuladores estáveis suficientes para correr qualquer jogo legado de uma forma performante. Existe muita controvérsia a volta deste tópico devido à parte legal que envolve as ROMs destes sistemas antigos na ausência de hardware licenciado, mas não foi o suficiente para parar esta tendência.

Alguns exemplos de emuladores são o [Mesen](https://www.mesen.ca/), um emulador da famosa consola da Nintendo lançada na década de 80, a NES; e o [mgba](https://mgba.io/) que é um emulador para a Gameboy. Existem imensos, e mesmo estando a falar de sistema antigos ainda existem muitas pessoas/grupos a criarem novos. No que toca a computadores os exemplos mais clássicos são o [Bochs](https://bochs.sourceforge.io/) e o [Qemu](https://www.qemu.org/) (mesmo que este atualmente tenha capacidades de virtualização).

# Simulação

A criação de uso de simulações aparecem muito antes dos emuladores. O seu objetivo é simular com elevada precisão eventos reais de modo a saber os seus resultados. Estes sistemas chegaram a ser usados durante a Segunda Guerra Mundial, usando tubos de vácuo, para calcular trajetórias de projéteis e mesmo muitos outros resultados de diversas estratégias de guerra.

Na ciência, as simulações, têm um importante papel para compreender o universo e toda a natureza. A criação de simulações com base em modelos complexos permitiu e permite grandes avanços na engenharia, química, astrofísica, meteorologia e muito mais.

{{ fit_image(path="blog/2021-07-17_lc-3-part-1/universe-simulation.jpg", alt="Simulação do Universo", alt_link="https://news.mit.edu/2019/early-galaxy-fuzzy-universe-simulation-1003" ) }}

É importante notar que as simulações estão cada vez mais complexas, consequentemente mais os resultados são muito mais poderosos e computacionalmente exigente. Hoje em dia, com os computadores modernos, conseguimos criar simulações muito precisas do universo nos seus tempos mais primordiais.

Um exemplo de um software que pode se encaixar nesta categoria é o [Packet Tracer](https://www.netacad.com/courses/packet-tracer) da Cisco.

# Interpretadores

Alguns interpretadores também são chamados de máquinas virtuais, mas em nada tem a ver com os softwares que permitem emular todo um sistema operativo nele.

Interpretadores foram a próxima etapa natural depois do surgimento dos emuladores. Estes sistemas recorrem a técnicas muito similares a emulação de alto nível para permitir correr o mesmo programa em múltiplos CPUs sem a necessidade de recompilação ou adaptações. Isto é conseguido com a criação de uma máquina virtual que interpreta um código muito similar a assembly, conhecido como bytecode.

Esta maquina virtual é a única componente que ter que ser adaptada e recompilada na arquitetura de cada CPUs, mas os compiladores modernos ajudam imenso neste processo, pois o mesmo compilador consegue emitir binários para múltiplos CPUs, tudo na mesma maquina - isto é chamada do cross compiling. Este processo permitiu escrever um programa uma única vez e este correr em múltiplas maquinas e sistemas operativos diferentes.

Alguns exemplos de linguagens que recorrem a esta técnica é o [JAVA](https://en.wikipedia.org/wiki/Java_bytecode), JavaScript, [Erlang/Elixir](<https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)>) e mais recentemente temos o [WebAssembly](https://webassembly.org/). O Web Assembly recorre à implementação de uma VM para criar um ambiente sandbox que permite isolar completamente o programa em execução e tornar o mesmo multiplataforma.

# Virtualização

Presentemente, quando se fala de máquinas virtuais ou VMs, ninguém se refere aos conceitos clássicos descritos acima, mas sim a um resultado dessa tecnologia. Com a estabilização de algumas arquiteturas, técnicas e poder de computação, a virtualização era algo completamente inevitável.

A virtualização vai muito além de emular com exatidão o hardware completo de um computador. Por exemplo, quando se pretende virtualizar um Windows ou Linux x86 numa máquina com a mesma arquitetura podemos tirar vantagens de algumas extensões do próprio hardware que permite descartar a emulação de algumas partes e usar diretamente o hardware.

{{ fit_image(path="blog/2021-07-17_lc-3-part-1/virtualization.png", alt="Arquitetura da Virtualização", alt_link="https://insights.sei.cmu.edu/blog/virtualization-via-virtual-machines/" ) }}

Com todos os avanços feitos na área, os produtores de CPUs pensaram na possibilidade de mover algumas camadas de virtualização no nível do software para dentro do próprio CPU permitindo self-virtualization. No meio de algumas destas extensões adicionar do CPU, no mundo do x86, temos o [VT-x](https://www.intel.com/content/www/us/en/virtualization/virtualization-technology/intel-virtualization-technology.html) da Intel e o [AMD-V](https://www.amd.com/en/technologies/virtualization-solutions) da AMD. Com estas extensões a virtualização ficou muito mais facilitada, contudo havia alguns problemas de desempenho no que tocava ao acesso à memória, mas logo foram resolvidos com a introdução da virtualização da Unidade de Gestão de Memoria (MMU).

Nesta categoria podemos encontrar alguns softwares mais conhecidos como o [VirtualBox](https://www.virtualbox.org/) e o [VMWare Fusion](https://www.vmware.com/products/fusion.html). Dois softwares de virtualização muito conhecidos.

## Hypervisors

Permitido pelas capacidades do hardware se auto virtualizar logo surgiram os hypervisors. Os hypervisors podem ser divididos em dois grandes tipos: tipo 2, sendo o equivalente à virtualização anteriormente descrita; e o tipo 1 ou BareMetal hypervisors sistemas instalados diretamente no hardware que não recorrer a um sistema operativo hospedeiro e que intermédia todas as maquinas virtuais, lidando com todos os acessos privilegiados ao hardware.

Pode-se entender como acessos privilegiados como configurar as tabelas de paginação (gestão da memória física e mapeamento para a memória virtual) ou ler/escrever para portas de I/O. De forma resumida o hypervisor valida todas as operações que envolvam a memória e ele próprio é que executa as operações protegidas; as operações de I/O são mapeadas para o hardware do dispositivo emulado em vez do CPU emulado.

No que toca a hypervisors existem alguns bastantes famosos na industria, como o exemplo o Microsoft [Hyper-V](https://en.wikipedia.org/wiki/Hyper-V) e [VMware ESXi](https://www.vmware.com/products/esxi-and-esx.html).

# Aplicações

Existem imensas aplicações para a virtualização e acredito piamente que haverão ainda muito mais num futuro próximo ou até mesmo outros níveis de virtualização.

Nos dias que correm a virtualização é usada para executar programas em ambientes isolados sem afetar o sistema hospedeiro, usado para impedir que um conjunto de máquinas crash visto que se a VM for abaixo não compromete as demais nem o sistema hospedeiro, correr sistemas antigos na mesma maquina ou sistemas operativos diferentes.

As aplicações são diversas e permitem poupar muito tempo e reduzir custos em diversos cenários.
