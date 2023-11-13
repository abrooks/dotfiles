{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core   = { flake = false; url = "github:homebrew/homebrew-core"; };
    homebrew-cask   = { flake = false; url = "github:homebrew/homebrew-cask"; };
    homebrew-bundle = { flake = false; url = "github:homebrew/homebrew-bundle"; };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, ...}:
  #outputs = inputs@{ self, nix-darwin, nixpkgs}:
  let
    user = "abrooks";
    homebrew = nix-homebrew;
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs.clojure
          pkgs.neovim
          pkgs.vim
        ];

      homebrew = {
        enable = true;
        brews = [
        ];
      };

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      programs.bash.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Aarons-MacBook-Pro
    darwinConfigurations."Aarons-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user = "${user}";
            enableRosetta = true;
            taps = {
              "homebrew/homebrew-core"   = homebrew-core;
              "homebrew/homebrew-cask"   = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
            };
            mutableTaps = false;
            #autoMigrate = true;
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Aarons-MacBook-Pro".pkgs;
  };
}
