{
  description = "Gil Mendes Personal Webside";
  nixConfig = {
    extra-substituters = "https://cache.garnix.io";
    extra-trusted-public-keys = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";
  };

  inputs = {
    emanote.url = "github:srid/emanote";
    nixpkgs.follows = "emanote/nixpkgs";
    flake-parts.follows = "emanote/flake-parts";
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [ inputs.emanote.flakeModule ];
      perSystem = { self', pkgs, system, ... }: {
        emanote.sites."gil0mendes" = {
          layers = [{ path = ./content; pathString = "./content"; }];
          port = 9801;
          prettyUrls = true;
        };
        apps.default.program = self'.apps.gil0mendes.program;
        packages.default = pkgs.symlinkJoin {
          name = "gil0mendes-static-site";
          paths = [ self'.packages.gil0mendes ];
        };
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
            act
          ];
        };
      };
    };
}
