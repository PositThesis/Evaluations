build:
    nix build -L --max-jobs 1

update:
    nix flake lock --update-input manual_krylov
    nix flake lock --update-input eigen_integration
    nix flake lock --update-input cim
