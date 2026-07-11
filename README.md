# A kinda crappy, vibecoded nix flake for Dank Calendar

To install add the following to your nix flake:

```nix
  inputs = {
    dcal-flake.url = "github:presi300/dcal-nix-flake";
  }
```
Then this to your nix config:

```nix
 {
  inputs,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    inputs.dcal-flake.packages.${pkgs.system}.default
  ]; 
}
```
