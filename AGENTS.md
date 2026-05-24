# AGENTS.md

## Project Shape
- Static personal site built with Emanote from `content/`; there is no JS/package manager workspace.
- `flake.nix` is the source of truth for tooling: Emanote site `gil0mendes`, content layer `./content`, dev server port `9801`, pretty URLs.
- Site metadata/theme/edit-link config lives in `content/index.yaml`; page content and assets live under `content/`.
- Custom Emanote template hook: `content/templates/hooks/after-note.tpl` adds the GitHub edit link using `template.editBaseUrl`.

## Commands
- Dev server: `nix run`.
- Static build: `nix build -o ./result`.
- Preview built output: `nix run nixpkgs#nodePackages.live-server -- ./result`.
- Update Emanote input only: `nix flake lock --update-input emanote`.
- Format Nix files with the dev-shell tool: `nix develop -c nixpkgs-fmt flake.nix`.

## Publish Flow
- GitHub Actions publishes only on pushes to branch `live`.
- CI build order: `nix build -o ./_site`, `nix run . -- export metadata > export.json`, `nix run github:gil0mendes/emanote-sitemap-generator`, copy `_site` plus `sitemap.xml` into `dist`.
- Docker image expects the CI artifact at `./website`; `Dockerfile` copies it into nginx at `/usr/share/nginx/html`.
- Deploy uses Nomad (`deploy/job.nomad.hcl`) with `$CI_IMAGE_TAG`; current CI fills it via `envsubst` before `nomad job run`.

## Content Notes
- Markdown files use Obsidian/Emanote-style syntax; keep existing wikilinks/embeds and frontmatter intact.
- Blog index is query-driven: `content/blog.md` renders `tag:blog`, so posts need the right tag metadata to appear.
- Generated/local outputs are ignored: `.direnv`, `.obsidian`, `/result`, `/_site`.
