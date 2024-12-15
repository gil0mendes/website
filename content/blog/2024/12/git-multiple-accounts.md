---
tags: [blog, git]
date: 2024-12-14
---

# Múltiplas Contas de Git

Existem certas situações em que é necessário fazer commits com diferentes contas, como, por exemplo: múltiplas chaves SSH por cada host de Git, usar o mesmo computador para trabalho e projetos pessoais, ou até ajudar alguém que não se queira que se saiba que o commit foi feito por outra pessoa 😜.

No meu caso, eu uso 1Password como o meu password manager. Como o me password manager permite gerir as minhas keys SSH e oferece um agent de SSH, posso configura o nosso servidor de SSH para fazer uso deste agente. Desta forma a configuração do meu SSH (`~/.ssh/config`) parecesse com algo como:

```
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

> [!NOTE]
> Estou a usar macOS para este artigo, mas o mesmo pode ser feito em qualquer outro sistema.

Agora que sabemos o estado por defeito do nosso sistema, vamos assumir que temos duas contas de Git, uma para trabalho e outra para projetos pessoais.

## 1. Criar a nova key para trabalho

Assumindo que já tenho a minha key para projetos pessoais e que esta é fornecida pelo meu 1Password, apenas tenho que gerar uma nova key para o meu trabalho. Para gerar a nova key podemos executar o comando:

```sh
ssh-keygen -t ed25519 -C "gil0mendes@my-work.com"
```

Quando for pedido para especificar o caminho onde a chave será gravada teremos que assegurar que não destruimos nenhuma chave já existente. No meu carro o diretório está vazio uma vez que as minhas chaves não deixam o 1Password. Mesmo assim, vou guardar a chave com um nome mais sugestivo que iremos usar daqui em diante, `id_work`.

O próximo passo é adicionar a nova chave SSH à nossa conta, no host que a empresa está a usar. No meu caso é GitHub, então apenas tenho que seguir [este artigo](https://docs.github.com/pt/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

## 2. Configurar SSH para usar a nova chave

Como eu uso o GitHub pessoalmente, não posso simplesmente deixar o servidor de SSH decidir a chave a usar. Sem nenhuma alteração iria fazer uso da minha chave pessoal. Para resolver isto vamos adicionar um novo host no ficheiro `~/.ssh/config`:

```
# work configuration
Host github.com-work
	Hostname github.com
	User git
	IdentifyFile ~/.ssh/id_work
	IdentitiesOnly yes
```

Como podem notar o host é algo que não existe, podemos olhar para isto como um alias, e o verdadeiro domínio é especificado em `Hostname`.

## 3. Configurar a Identidade do Git

O nosso próximo objetivo é fazer o clone de um dos repositórios do meu trabalho, mas teremos que substituir o `github.com` ou `github.com-work` - como anteriormente configurado.

```sh
git clone git@github.com-work/my-work/my-project.git work-project && cd work-project
```

Com o clone feito, falta-nos configurar um novo utilizador. Para isso, executamos `git config --local -e` e adicionamos:

```sh
[user]
	name = Gil Mendes
	email = gil0mendes@my-work.com
```

Desta forma configuramos o utilizador que vai ser usado no repositório. O último passo é assegurar que o remote está com a informação correta. Para isso corremos o seguinte comando:

```sh
git remote set-url origin git@github.com-work:my-work/my-project.git
```

O mesmo pode ser conseguida modificando a config do Git local, como anteriormente (`git config --local -e`):

```sh
[remote "origin"]
	url = git@github.com-work:my-work/my-project.git
	fetch = +refs/heads/*:refs/remotes/origin/*
```

## 4. Conclusão

Com isto, todas as ações que faça de agora em diante iram usar o utilizador e a chave SSH que criamos. Usando esta técnica podemos ter duas ou mais chaves diferentes em uso simultaneamente.

## Referências

- [Specify an SSH key for git push for a given domain](https://stackoverflow.com/questions/7927750/specify-an-ssh-key-for-git-push-for-a-given-domain)
- [Gerando uma nova chave SSH e adicionando-a ao agente SSH](https://docs.github.com/pt/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
