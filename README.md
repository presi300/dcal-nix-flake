# A kinda crappy, vibecoded nix flake for Dank Calendar

To install add the following to your nix flake:

```nix
{
  inputs = {
    # Your other flake inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    dcal-flake.url = "github:presi300/dcal-nix-flake";
  };
  outputs = { dcal-flake, nixpkgs  }: #Add along side other flake outputs
  {
    nixosConfigurations.<name> = nixpkgs.lib.nixosSystem { #Your flake config
      modules = [
        # Your other stuff, nixos configurations, etc...
        dcal-flake.nixosModules.default

      ];
    };
  };
}
  
```
Then this to your nixos config:

```nix
 services.dcal.enable = true;
```
