{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";
    cim.url = "git+http://10.0.0.1:3000/aethan/ContourIntegralMethod";
    krylov.url = "git+http://10.0.0.1:3000/aethan/KrylovSolvers";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, cim, krylov, flake-utils }:
    let
      # wrap this in another let .. in to add the hydra job only for a single architecture
      output_set = flake-utils.lib.eachDefaultSystem (system:
        let
            pkgs = nixpkgs.legacyPackages.${system};
            python = pkgs.python3.withPackages(p: with p; [ numpy pandas matplotlib ]);
        in
        rec {
            packages = flake-utils.lib.flattenTree {
                shared_tools = pkgs.stdenv.mkDerivation {
                    name = "SharedTools";
                    src = ./shared;

                    nativeBuildInputs = [];

                    buildPhase = ''

                    '';

                    installPhase = ''
                        mkdir -p $out
                        cp $src/make_random_matrix.py $out/make_random_matrix.py
                    '';
                };

                run_cim = pkgs.stdenv.mkDerivation {
                    name = "CimRunner";
                    src = ./cim/runner;

                    nativeBuildInputs = [
                        python
                        cim.packages.${system}.cim
                        packages.shared_tools
                    ];

                    buildPhase = ''
                        python ${packages.shared_tools}/make_random_matrix.py --rows 20 --cols 20 -c -s 1 -m 2 -o complex20A.mtx
                        python ${packages.shared_tools}/make_random_matrix.py --rows 20 --cols 20 -c -s 2 -m 2 -o complex20B.mtx
                        python ${packages.shared_tools}/make_random_matrix.py --rows 20 --cols 20 -c -s 3 -m 2 -o complex20C.mtx

                        mkdir output

                        python run_cim.py -i complex20A.mtx -i complex20B.mtx -i complex20C.mtx -o output -r 0.7
                    '';

                    installPhase = ''
                        mkdir -p $out/{data,inputs}
                        cp -riva output $out/data
                        cp complex20{A,B,C}.mtx $out/inputs
                    '';
                };

                eval_cim = pkgs.stdenv.mkDerivation {
                    name = "CimEvaluator";
                    src = ./cim/evaluate;

                    nativeBuildInputs = [
                        python
                    ];

                    buildInputs = [
                        python
                        packages.run_cim
                        pkgs.octave
                    ];

                    buildPhase = ''
                        cp -riva ${packages.run_cim}/inputs inputs
                        cp -riva ${packages.run_cim}/data data
                        octave octave_cim.m

                        python plot_eigs.py -i data/output/992/Double.mtx -r 0.7 --ref octave_eigs.mtx -o eigs.svg
                        python plot_cim_res.py -i data/output
                    '';

                    installPhase = ''
                        mkdir -p $out/{inputs,data}
                        cp -riva ${packages.run_cim}/inputs $out/inputs
                        cp -riva ${packages.run_cim}/data $out/data
                        cp octave_eigs.mtx $out/octave_eigs.mtx
                        cp eigs.svg $out/eigs.svg
                        cp cim_residuals.svg $out/cim_residuals.svg
                    '';
                };
            };

            defaultPackage = packages.eval_cim;
        }
    );
    in
        output_set // { hydraJobs.build."aarch64-linux" = output_set.defaultPackage."aarch64-linux"; };
    }
