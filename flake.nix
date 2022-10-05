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
    manual_krylov = {
        url = "git+http://10.0.0.1:3000/aethan/ManualSolvers";
        inputs.online_lib.follows = "eigen_integrations";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, eigen_integrations, cim, krylov, manual_krylov, flake-utils }:
    let
      # wrap this in another let .. in to add the hydra job only for a single architecture
      output_set = flake-utils.lib.eachDefaultSystem (system:
        let
            pkgs = nixpkgs.legacyPackages.${system};
            python = pkgs.python3.withPackages(p: with p; [ numpy pandas matplotlib ]);
            makeRunner = {ty, algorithm, params, inputs}: pkgs.stdenv.mkDerivation {
                name = algorithm+ty;
                src = ./krylov/runner;
                        
                nativeBuildInputs = [ manual_krylov.packages.${system}.solvers ];
                buildInputs = [];
                        
                buildPhase = ''
                    mkdir -p output
                    ls ${inputs}
                    ${ty}${algorithm} -im ${inputs}/mat.mtx -iv ${inputs}/vec.vec ${params} -o output/${algorithm}_${ty}
                '';
                    
                installPhase = ''
                    mkdir -p $out/
                    cp output/* $out
                '';
            };
            GMRESRunners = {params, inputs}: {
                Float = makeRunner { ty ="Float"; algorithm = "GMRES"; inherit params; inherit inputs; };
                Double = makeRunner { ty ="Double"; algorithm = "GMRES"; inherit params; inherit inputs; };
                LongDouble = makeRunner { ty ="LongDouble"; algorithm = "GMRES"; inherit params; inherit inputs; };
                Posit16 = makeRunner { ty ="Posit16"; algorithm = "GMRES"; inherit params; inherit inputs; };
                Posit32 = makeRunner { ty ="Posit32"; algorithm = "GMRES"; inherit params; inherit inputs; };
                Posit64 = makeRunner { ty ="Posit64"; algorithm = "GMRES"; inherit params; inherit inputs; };
            };
            QMRRunners = {params, inputs}: {
                Float = makeRunner { ty ="Float"; algorithm = "QMR"; inherit params; inherit inputs; };
                Double = makeRunner { ty ="Double"; algorithm = "QMR"; inherit params; inherit inputs; };
                LongDouble = makeRunner { ty ="LongDouble"; algorithm = "QMR"; inherit params; inherit inputs; };
                Posit16 = makeRunner { ty ="Posit16"; algorithm = "QMR"; inherit params; inherit inputs; };
                Posit32 = makeRunner { ty ="Posit32"; algorithm = "QMR"; inherit params; inherit inputs; };
                Posit64 = makeRunner { ty ="Posit64"; algorithm = "QMR"; inherit params; inherit inputs; };
            };
            QMRWLARunners = {params, inputs}: {
                Float = makeRunner { ty ="Float"; algorithm = "QMRWLA"; inherit params; inherit inputs; };
                Double = makeRunner { ty ="Double"; algorithm = "QMRWLA"; inherit params; inherit inputs; };
                LongDouble = makeRunner { ty ="LongDouble"; algorithm = "QMRWLA"; inherit params; inherit inputs; };
                Posit16 = makeRunner { ty ="Posit16"; algorithm = "QMRWLA"; inherit params; inherit inputs; };
                Posit32 = makeRunner { ty ="Posit32"; algorithm = "QMRWLA"; inherit params; inherit inputs; };
                Posit64 = makeRunner { ty ="Posit64"; algorithm = "QMRWLA"; inherit params; inherit inputs; };
            };
            runMatrixAlgorithm = {name, runners}: pkgs.stdenv.mkDerivation {
                name = name;

                unpackPhase = "true";
                buildPhase = "true";

                installPhase = ''
                    mkdir $out
                    cp ${runners.Float}/* $out
                    cp ${runners.Double}/* $out
                    cp ${runners.LongDouble}/* $out
                    cp ${runners.Posit16}/* $out
                    cp ${runners.Posit32}/* $out
                    cp ${runners.Posit64}/* $out
                '';

            };
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
                        mkdir -p $out/
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
                        cp max_residuals.svg $out/max_residuals.svg
                        cp all_residuals.svg $out/all_residuals.svg
                    '';
                };

                krylov_random_inputs = pkgs.stdenv.mkDerivation {
                    name = "Random data for krylov";

                    unpackPhase = "true";

                    nativeBuildInputs = [python];

                    buildPhase = ''
                        python ${packages.shared_tools}/make_random_matrix.py --rows 40 --cols 40 -s 1 -m 2 -o random40.mtx
                        python ${packages.shared_tools}/make_random_matrix.py --rows 40 --cols 1 -s 2 -m 2 -o random40.vec
                    '';

                    installPhase = ''
                        mkdir $out
                        cp random40.mtx $out/mat.mtx
                        cp random40.vec $out/vec.vec
                    '';
                };

                krylov_sherman_inputs = pkgs.stdenv.mkDerivation {
                    name = "Sherman data for krylov";

                    src = krylov/inputs;

                    nativeBuildInputs = [python];

                    buildPhase = ''
                        python ${packages.shared_tools}/make_random_matrix.py --rows 3312 --cols 1 -s 3 -m 2 -o sherman5.vec
                    '';

                    installPhase = ''
                        mkdir $out
                        cp sherman5.mtx $out/mat.mtx
                        cp sherman5.vec $out/vec.vec
                    '';
                };

                eval_krylov2 = pkgs.stdenv.mkDerivation {
                    name = "KrylovEvaluator";
                    src = krylov/evaluate;

                    nativeBuildInputs = [python];

                    buildPhase = ''
                        mkdir data_random
                        cp ${runMatrixAlgorithm {name = "Random"; runners=GMRESRunners{inputs=packages.krylov_random_inputs; params = "-iters 200 -hh";};}}/* data_random
                        cp ${runMatrixAlgorithm {name = "Random"; runners=QMRRunners{inputs=packages.krylov_random_inputs; params = "-iters 200 -hh";};}}/* data_random
                        cp ${runMatrixAlgorithm {name = "Random"; runners=QMRWLARunners{inputs=packages.krylov_random_inputs; params = "-iters 200 -hh";};}}/* data_random

                        mkdir plots_random
                        python postprocess_krylov.py -i data_random -o plots_random -max_iter 200 -tol 1e-80

                        mkdir data_sherman
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=QMRRunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -hh -sparse -precond";};}}/* data_sherman
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=QMRWLARunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -hh -sparse -precond";};}}/* data_sherman
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=GMRESRunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -hh -sparse -restart 30 -precond";};}}/* data_sherman

                        mkdir plots_sherman
                        python postprocess_krylov.py -i data_sherman -o plots_sherman -max_iter 4000 -tol 1e-80

                        mkdir data_random_arnoldi
                        cp ${runMatrixAlgorithm {name = "Random"; runners=GMRESRunners{inputs=packages.krylov_random_inputs; params = "-iters 200";};}}/* data_random_arnoldi

                        mkdir plots_random_arnoldi
                        python postprocess_krylov.py -i data_random_arnoldi -o plots_random_arnoldi -max_iter 200 -tol 1e-80

                        mkdir data_sherman_arnoldi
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=GMRESRunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -sparse -restart 30 -precond";};}}/* data_sherman_arnoldi

                        mkdir plots_sherman_arnoldi
                        python postprocess_krylov.py -i data_sherman_arnoldi -o plots_sherman_arnoldi -max_iter 4000 -tol 1e-80


                        # space for additional analyses
                    '';

                    installPhase = ''
                        mkdir -p $out/{random40,sherman5}
                        cp plots_random/* $out/random40
                        cp plots_sherman/* $out/sherman5
                    '';
                };

                run_krylov = pkgs.stdenv.mkDerivation {
                    name = "KrylovRunner";
                    src = ./krylov/runner;

                    nativeBuildInputs = [
                        python
                        # krylov.packages.${system}.solvers
                        manual_krylov.packages.${system}.solvers
                        packages.shared_tools
                    ];

                    buildPhase = ''
                        python ${packages.shared_tools}/make_random_matrix.py --rows 40 --cols 40 -s 1 -m 2 -o random40.mtx
                        python ${packages.shared_tools}/make_random_matrix.py --rows 40 --cols 1 -s 2 -m 2 -o random40.vec
                        python ${packages.shared_tools}/make_random_matrix.py --rows 3312 --cols 1 -s 3 -m 2 -o sherman5.vec

                        mkdir -p output/random40
                        mkdir -p output/sherman5

                        echo "Running random matrix"
                        # python run_krylov.py -im random40.mtx -iv random40.vec -o output/random40 -tol 1e-80 -max_iter 100 -restart -1
                        python run_custom_krylov.py -im random40.mtx -iv random40.vec -o output/random40 -iters 100 -hh

                        echo "Running sherman5 matrix"
                        # python run_krylov.py -im sherman5.mtx -iv sherman5.vec -o output/sherman5 -max_iter 4000 -restart 30 -tol 1e-80
                        python run_custom_krylov.py -im sherman5.mtx -iv sherman5.vec -o output/sherman5 -iters 100 -hh -sparse
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
                        python postprocess_krylov.py -i data/output/sherman5 -o plots/sherman5 -max_iter 100 -tol 1e-80
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

            defaultPackage = packages.eval_krylov2;


            devShell = pkgs.mkShell {
                buildInputs = [
                    manual_krylov.packages.${system}.solvers
                    cim.packages.${system}.cim
                    python
                ];

                shellHook = ''

                '';
            };
        }
    );
    in
        output_set // { hydraJobs.build."aarch64-linux" = output_set.defaultPackage."aarch64-linux"; };
    }
