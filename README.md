# Gil Mendes' Website

My personal website and blog.

The website is build with a Markdown-based [Emanote](https://github.com/srid/emanote) notebook with [Visual Studio Code](https://code.visualstudio.com/) support.

See https://emanote.srid.ca/start/resources/emanote-template for details.

## Running using Nix

To start the Emanote live server using Nix:

```sh
# If you using VSCode, you can also: Ctrl+Shift+B
nix run
```

To update Emanote version in flake.nix:

```sh
nix flake lock --update-input emanote
```

To build the static website via Nix:

```sh
nix build -o ./result
# Then test it:
nix run nixpkgs#nodePackages.live-server -- ./result
```
