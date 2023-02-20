---
tags: [blog, haskell]
date: 2023-02-20
---

# Haskell with Stack and Nix

[Haskell](https://www.haskell.org/) is one of those languages that fascinates me, I had the first contact with it in 2011, and since then, from time to time, I end up revisiting just to play around. I nothing close to an expert on it, since its mental modal is wholly different from other languages, but I know one thing or two about it.

The most complex thing that I did on it was a 2D game, to help a friend complete a college appointment. It was hard, but fun at the same time. I probably would take less time today since I learn some concepts from lambda calculus and category theory; two heavily mathematical topics presents in each line that you write in Haskell.

One of the things that stressed me out a lot with Haskell is the lake of modern tooling that makes it easy to maintain the software that we write; this is one of the main reasons why a love Rust, [Cargo](https://doc.rust-lang.org/cargo/) is a complete tool set for all your needs while creating a Rust project. It can be your:

- Dependency manager;
- Testing tool;
- Documentation;
- Build system;
- and, a lot more.

Fortunately, something have improved last years, and we have now tools like [Stack](https://docs.haskellstack.org/en/stable/) that are wonderful to manage your Haskell project; however, I don't want to install another tool directly on my machine, but fortunately, I already used a solution for that for quite some time - [[Nix]].

## Solution

Nix is a package manager that provides -- among other benefits -- the [nix-shell](https://nixos.wiki/wiki/Development_environment_with_nix-shell), a sort of virtual environment for everything.

Nix in a way can solve the same challenges as Docker, in particular, as a solution to the dreaded "it works on my machine" class of problems often encountered by teams working on a project. However, I have other reasons to use it daily, as being a replacement for my OS package manager, and a way to isolate installed tools.

To create a Nix Shell with the needed Haskell tools is pretty simple, we just create a `shell.nix` file that will contain the shell definition.

```nix
let
  pkgs = import <nixpkgs> { };
  stack-wrapped = pkgs.symlinkJoin {
    name = "stack";
    paths = [ pkgs.stack ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/stack \
        --add-flags "\
            --nix \
            --no-nix-pure \
            "
    '';
  };
in
pkgs.mkShell {
  # Do NOT use `stack`, otherwise system dependencies like `zlib` are missing at compilation
  buildInputs = [ stack-wrapped ];
  NIX_PATH = "nixpkgs=" + pkgs.path;
}
```

The contents of the above file will create a new wrapper around Stack that will pass two new flags `--nix` and `--no-nix-pure`, that will tell Stack to use Nix to fetch any missing library/executable and allow running Stack in a non-pure way, correspondingly. The latest, mining two things:

1. environment variables will be forwarded from the shell into nix session;
2. the build will use host libraries to build the artifacts.

Now, you can simply navigate to the directory where the `shell.nix` lives and run `nix-shell`; Nix will automatically set up a Haskell environment for you, without changing your host system. All the tools only will exist inside this shell. 🎉

## Resources

- https://www.tweag.io/blog/2022-06-02-haskell-stack-nix-shell/
- https://docs.haskellstack.org/en/stable/
