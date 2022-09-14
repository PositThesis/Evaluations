{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";
    eigen_integrations.url = "git+http://10.0.0.1:3000/aethan/EigenPositIntegration";
    cim = {
        url = "git+http://10.0.0.1:3000/aethan/ContourIntegralMethod";
        inputs.online_lib.follows = "eigen_integrations";
    };
    krylov = {
        url = "git+http://10.0.0.1:3000/aethan/KrylovSolvers";
        inputs.online_lib.follows = "eigen_integrations";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, eigen_integrations, cim, krylov, flake-utils }:
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

                        python run_cim.py -i complex20A.mtx -i complex20B.mtx -i complex20C.mtx -o output -r 0.6
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

                        python plot_eigs.py -i data/output/992/Double.mtx -r 0.6 --ref octave_eigs.mtx -o eigs.svg
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

                run_krylov = pkgs.stdenv.mkDerivation {
                    name = "KrylovRunner";
                    src = ./krylov/runner;

                    nativeBuildInputs = [
                        python
                        krylov.packages.${system}.solvers
                        packages.shared_tools
                    ];

                    buildPhase = ''
                        python ${packages.shared_tools}/make_random_matrix.py --rows 40 --cols 40 -s 1 -m 2 -o random40.mtx
                        python ${packages.shared_tools}/make_random_matrix.py --rows 40 --cols 1 -s 2 -m 2 -o random40.vec
                        python ${packages.shared_tools}/make_random_matrix.py --rows 3312 --cols 1 -s 3 -m 2 -o sherman5.vec

                        mkdir -p output/random40
                        mkdir -p output/sherman5

                        echo "Running random matrix"
                        python run_krylov.py -im random40.mtx -iv random40.vec -o output/random40 -tol 1e-80 -max_iter 100 -restart -1

                        echo "Running sherman5 matrix"
                        python run_krylov.py -im sherman5.mtx -iv sherman5.vec -o output/sherman5 -tol 1e-80 -max_iter 4000 -restart 30
                    '';

                    installPhase = ''
                        mkdir -p $out/{data,inputs}
                        cp -riva output $out/data
                        cp random40.{mtx,vec} $out/inputs
                        cp sherman5.{mtx,vec} $out/inputs
                    '';
                };

                eval_krylov = pkgs.stdenv.mkDerivation {
                    name = "KrylovEvaluator";
                    src = ./krylov/evaluate;

                    nativeBuildInputs = [
                        python
                    ];

                    buildInputs = [
                        python
                        packages.run_krylov
                    ];

                    buildPhase = ''
                        cp -riva ${packages.run_krylov}/inputs inputs
                        cp -riva ${packages.run_krylov}/data data

                        mkdir -p plots/random40
                        mkdir -p plots/sherman5

                        ls data/output/sherman5

                        python postprocess_krylov.py -i data/output/random40 -o plots/random40 -max_iter 100 -tol 1e-80
                        python postprocess_krylov.py -i data/output/sherman5 -o plots/sherman5 -max_iter 4000 -tol 1e-80
                    '';

                    installPhase = ''
                        mkdir -p $out/{inputs,data}
                        cp -riva ${packages.run_krylov}/inputs $out/inputs
                        cp -riva ${packages.run_krylov}/data $out/data
                        cp -riva plots/ $out/plots/
                    '';
                };

                eval_both = pkgs.stdenv.mkDerivation {
                    name = "Evaluator";
                    src = ./.;

                    buildInputs = [
                        packages.eval_cim
                        packages.eval_krylov
                    ];

                    buildPhase = "";

                    installPhase = ''
                        mkdir -p $out/{cim,krylov}
                        cp -riva ${packages.eval_cim}/ $out/cim
                        cp -riva ${packages.eval_krylov}/ $out/krylov
                    '';
                };
            };

            defaultPackage = packages.eval_both;
        }
    );
    in
        output_set // { hydraJobs.build."aarch64-linux" = output_set.defaultPackage."aarch64-linux"; };
    }
