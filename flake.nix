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
            timeout = builtins.toString (3*3600);
            makeRunner = {ty, algorithm, params, inputs, use_fdp}:
                let
                    binary = if (use_fdp) then
                        "${ty}${algorithm}"
                    else "${ty}${algorithm}_no_fdp";
                    output = if (use_fdp) then
                        "${ty}_${algorithm}"
                    else "${ty}_${algorithm}_no_fdp";
                in
                pkgs.stdenv.mkDerivation {
                    name = algorithm+ty;
                    src = ./krylov/runner;

                    nativeBuildInputs = [ manual_krylov.packages.${system}.solvers ];
                    buildInputs = [];

                    buildPhase = ''
                        mkdir -p output
                        ${binary} -im ${inputs}/mat.mtx -iv ${inputs}/vec.vec ${params} -o output/${output} -timeout ${timeout}
                    '';

                    installPhase = ''
                        mkdir -p $out/
                        cp output/* $out
                    '';
                };
            GMRESRunners = {params, inputs, use_fdp}: {
                Float = makeRunner { ty ="Float"; algorithm = "GMRES"; inherit params; inherit inputs; use_fdp = true; };
                Double = makeRunner { ty ="Double"; algorithm = "GMRES"; inherit params; inherit inputs; use_fdp = true; };
                LongDouble = makeRunner { ty ="LongDouble"; algorithm = "GMRES"; inherit params; inherit inputs; use_fdp = true; };
                Posit16 = makeRunner { ty ="Posit16"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp; };
                Posit32 = makeRunner { ty ="Posit32"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp; };
                Posit64 = makeRunner { ty ="Posit64"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp; };
            };
            QMRRunners = {params, inputs, use_fdp}: {
                Float = makeRunner { ty ="Float"; algorithm = "QMR"; inherit params; inherit inputs; use_fdp = true; };
                Double = makeRunner { ty ="Double"; algorithm = "QMR"; inherit params; inherit inputs; use_fdp = true; };
                LongDouble = makeRunner { ty ="LongDouble"; algorithm = "QMR"; inherit params; inherit inputs; use_fdp = true; };
                Posit16 = makeRunner { ty ="Posit16"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp; };
                Posit32 = makeRunner { ty ="Posit32"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp; };
                Posit64 = makeRunner { ty ="Posit64"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp; };
            };
            QMRWLARunners = {params, inputs, use_fdp}: {
                Float = makeRunner { ty ="Float"; algorithm = "QMRWLA"; inherit params; inherit inputs; use_fdp = true; };
                Double = makeRunner { ty ="Double"; algorithm = "QMRWLA"; inherit params; inherit inputs; use_fdp = true; };
                LongDouble = makeRunner { ty ="LongDouble"; algorithm = "QMRWLA"; inherit params; inherit inputs; use_fdp = true; };
                Posit16 = makeRunner { ty ="Posit16"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp; };
                Posit32 = makeRunner { ty ="Posit32"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp; };
                Posit64 = makeRunner { ty ="Posit64"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp; };
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
            
            GMRESNBitsVariationRunners = {params, inputs, use_fdp}: {
                P16 = makeRunner { ty ="Posit16"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P20 = makeRunner { ty ="Posit20"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P24 = makeRunner { ty ="Posit24"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P28 = makeRunner { ty ="Posit28"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P32 = makeRunner { ty ="Posit32"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P36 = makeRunner { ty ="Posit36"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P40 = makeRunner { ty ="Posit40"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P44 = makeRunner { ty ="Posit44"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P48 = makeRunner { ty ="Posit48"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P52 = makeRunner { ty ="Posit52"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P56 = makeRunner { ty ="Posit56"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P60 = makeRunner { ty ="Posit60"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P64 = makeRunner { ty ="Posit64"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P68 = makeRunner { ty ="Posit68"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P72 = makeRunner { ty ="Posit72"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P76 = makeRunner { ty ="Posit76"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P80 = makeRunner { ty ="Posit80"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
            };
            QMRNBitsVariationRunners = {params, inputs, use_fdp}: {
                P16 = makeRunner { ty ="Posit16"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P20 = makeRunner { ty ="Posit20"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P24 = makeRunner { ty ="Posit24"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P28 = makeRunner { ty ="Posit28"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P32 = makeRunner { ty ="Posit32"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P36 = makeRunner { ty ="Posit36"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P40 = makeRunner { ty ="Posit40"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P44 = makeRunner { ty ="Posit44"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P48 = makeRunner { ty ="Posit48"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P52 = makeRunner { ty ="Posit52"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P56 = makeRunner { ty ="Posit56"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P60 = makeRunner { ty ="Posit60"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P64 = makeRunner { ty ="Posit64"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P68 = makeRunner { ty ="Posit68"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P72 = makeRunner { ty ="Posit72"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P76 = makeRunner { ty ="Posit76"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P80 = makeRunner { ty ="Posit80"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
            };
            QMRWLANBitsVariationRunners = {params, inputs, use_fdp}: {
                P16 = makeRunner { ty ="Posit16"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P20 = makeRunner { ty ="Posit20"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P24 = makeRunner { ty ="Posit24"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P28 = makeRunner { ty ="Posit28"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P32 = makeRunner { ty ="Posit32"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P36 = makeRunner { ty ="Posit36"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P40 = makeRunner { ty ="Posit40"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P44 = makeRunner { ty ="Posit44"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P48 = makeRunner { ty ="Posit48"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P52 = makeRunner { ty ="Posit52"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P56 = makeRunner { ty ="Posit56"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P60 = makeRunner { ty ="Posit60"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P64 = makeRunner { ty ="Posit64"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P68 = makeRunner { ty ="Posit68"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P72 = makeRunner { ty ="Posit72"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P76 = makeRunner { ty ="Posit76"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P80 = makeRunner { ty ="Posit80"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
            };
            runNBitsVariation = {name, runners}: pkgs.stdenv.mkDerivation {
                name = name;
                unpackPhase = "true";
                buildPhase = "true";
                
                installPhase = ''
                    mkdir $out
                    cp ${runners.P16}/* $out
                    cp ${runners.P20}/* $out
                    cp ${runners.P24}/* $out
                    cp ${runners.P28}/* $out
                    cp ${runners.P32}/* $out
                    cp ${runners.P36}/* $out
                    cp ${runners.P40}/* $out
                    cp ${runners.P44}/* $out
                    cp ${runners.P48}/* $out
                    cp ${runners.P52}/* $out
                    cp ${runners.P56}/* $out
                    cp ${runners.P60}/* $out
                    cp ${runners.P64}/* $out
                    cp ${runners.P68}/* $out
                    cp ${runners.P72}/* $out
                    cp ${runners.P76}/* $out
                    cp ${runners.P80}/* $out
                '';
            };
            
            
            GMRESESVariationRunners = {params, inputs, use_fdp}: {
                P160 = makeRunner { ty ="Posit160"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P161 = makeRunner { ty ="Posit161"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P162 = makeRunner { ty ="Posit162"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P163 = makeRunner { ty ="Posit163"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P164 = makeRunner { ty ="Posit164"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P320 = makeRunner { ty ="Posit320"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P321 = makeRunner { ty ="Posit321"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P322 = makeRunner { ty ="Posit322"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P323 = makeRunner { ty ="Posit323"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P324 = makeRunner { ty ="Posit324"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P640 = makeRunner { ty ="Posit640"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P641 = makeRunner { ty ="Posit641"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P642 = makeRunner { ty ="Posit642"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P643 = makeRunner { ty ="Posit643"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
                P644 = makeRunner { ty ="Posit644"; algorithm = "GMRES"; inherit params; inherit inputs; inherit use_fdp;  };
            };
            QMRESVariationRunners = {params, inputs, use_fdp}: {
                P160 = makeRunner { ty ="Posit160"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P161 = makeRunner { ty ="Posit161"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P162 = makeRunner { ty ="Posit162"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P163 = makeRunner { ty ="Posit163"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P164 = makeRunner { ty ="Posit164"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P320 = makeRunner { ty ="Posit320"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P321 = makeRunner { ty ="Posit321"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P322 = makeRunner { ty ="Posit322"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P323 = makeRunner { ty ="Posit323"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P324 = makeRunner { ty ="Posit324"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P640 = makeRunner { ty ="Posit640"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P641 = makeRunner { ty ="Posit641"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P642 = makeRunner { ty ="Posit642"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P643 = makeRunner { ty ="Posit643"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
                P644 = makeRunner { ty ="Posit644"; algorithm = "QMR"; inherit params; inherit inputs; inherit use_fdp;  };
            };
            QMRWLAESVariationRunners = {params, inputs, use_fdp}: {
                P160 = makeRunner { ty ="Posit160"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P161 = makeRunner { ty ="Posit161"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P162 = makeRunner { ty ="Posit162"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P163 = makeRunner { ty ="Posit163"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P164 = makeRunner { ty ="Posit164"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P320 = makeRunner { ty ="Posit320"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P321 = makeRunner { ty ="Posit321"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P322 = makeRunner { ty ="Posit322"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P323 = makeRunner { ty ="Posit323"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P324 = makeRunner { ty ="Posit324"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P640 = makeRunner { ty ="Posit640"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P641 = makeRunner { ty ="Posit641"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P642 = makeRunner { ty ="Posit642"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P643 = makeRunner { ty ="Posit643"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
                P644 = makeRunner { ty ="Posit644"; algorithm = "QMRWLA"; inherit params; inherit inputs; inherit use_fdp;  };
            };
            runESVariation = {name, runners}: pkgs.stdenv.mkDerivation {
                name = name;
                unpackPhase = "true";
                buildPhase = "true";
                
                installPhase = ''
                    mkdir $out
                    cp ${runners.P160}/* $out
                    cp ${runners.P161}/* $out
                    cp ${runners.P162}/* $out
                    cp ${runners.P163}/* $out
                    cp ${runners.P164}/* $out
                    cp ${runners.P320}/* $out
                    cp ${runners.P321}/* $out
                    cp ${runners.P322}/* $out
                    cp ${runners.P323}/* $out
                    cp ${runners.P324}/* $out
                    cp ${runners.P640}/* $out
                    cp ${runners.P641}/* $out
                    cp ${runners.P642}/* $out
                    cp ${runners.P643}/* $out
                    cp ${runners.P644}/* $out
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
                        cp -riva inputs $out/inputs
                        cp -riva data $out/data
                        cp octave_eigs.mtx $out/octave_eigs.mtx
                        # cp eigs.svg $out/eigs.svg
                        # cp max_residuals.svg $out/max_residuals.svg
                        # cp all_residuals.svg $out/all_residuals.svg

                        cp reference.csv $out/reference_eigs.csv
                        cp cim_residuals_*.csv $out
                        cp cim.csv $out/cim_eigs.csv
                    '';
                };

                krylov_random_inputs = pkgs.stdenv.mkDerivation {
                    name = "Random data for krylov";

                    unpackPhase = "true";

                    nativeBuildInputs = [python];

                    buildPhase = ''
                        python ${packages.shared_tools}/make_random_matrix.py --rows 400 --cols 400 -s 1 -m 2 -o random1000.mtx -band 6
                        python ${packages.shared_tools}/make_random_matrix.py --rows 400 --cols 1 -s 2 -m 2 -o random1000.vec
                    '';

                    installPhase = ''
                        mkdir $out
                        cp random1000.mtx $out/mat.mtx
                        cp random1000.vec $out/vec.vec
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

                eval_krylov_nbits = pkgs.stdenv.mkDerivation {
                    name = "KrylovEvaluator NBits";
                    src = krylov/evaluate;

                    nativeBuildInputs = [python];

                    buildPhase = ''
                        mkdir data_random
                        cp ${runNBitsVariation {name = "Random"; runners=GMRESNBitsVariationRunners{inputs=packages.krylov_random_inputs; params = "-iters 200 -hh"; use_fdp = true; };}}/* data_random
                        cp ${runNBitsVariation {name = "Random"; runners=QMRNBitsVariationRunners{inputs=packages.krylov_random_inputs; params = "-iters 200 -hh"; use_fdp = true; };}}/* data_random
                        cp ${runNBitsVariation {name = "Random"; runners=QMRWLANBitsVariationRunners{inputs=packages.krylov_random_inputs; params = "-iters 200 -hh"; use_fdp = true; };}}/* data_random
                        sed -i 's/nar/nan/g' data_random/QMRWLA_Posit16.csv || true

                        mkdir plots_random
                        python postprocess_krylov.py -i data_random -o plots_random -max_iter 200 -tol 1e-80

                        mkdir data_random_arnoldi
                        cp ${runNBitsVariation {name = "Random"; runners=GMRESNBitsVariationRunners{inputs=packages.krylov_random_inputs; params = "-iters 200"; use_fdp = true; };}}/* data_random_arnoldi

                        mkdir plots_random_arnoldi
                        python postprocess_krylov.py -i data_random_arnoldi -o plots_random_arnoldi -max_iter 200 -tol 1e-80
                    '';

                    installPhase = ''
                        mkdir -p $out/{random,random_arnoldi}
                        mkdir -p $out/data/{random,random_arnoldi}
                        cp plots_random/* $out/random
                        cp plots_random_arnoldi/* $out/random_arnoldi

                        cp data_random/* $out/data/random
                        cp data_random_arnoldi/* $out/data/random_arnoldi
                    '';
                };

                eval_krylov_es = pkgs.stdenv.mkDerivation {
                    name = "KrylovEvaluator ES";
                    src = krylov/evaluate;

                    nativeBuildInputs = [python];


                    buildPhase = ''
                        mkdir data_random
                        cp ${runESVariation {name = "Random"; runners=GMRESESVariationRunners{inputs=packages.krylov_random_inputs; params = "-iters 200 -hh"; use_fdp = true; };}}/* data_random
                        cp ${runESVariation {name = "Random"; runners=QMRESVariationRunners{inputs=packages.krylov_random_inputs; params = "-iters 200 -hh"; use_fdp = true; };}}/* data_random
                        cp ${runESVariation {name = "Random"; runners=QMRWLAESVariationRunners{inputs=packages.krylov_random_inputs; params = "-iters 200 -hh"; use_fdp = true; };}}/* data_random

                        mkdir plots_random
                        python postprocess_krylov.py -i data_random -o plots_random -max_iter 200 -tol 1e-80

                        mkdir data_random_arnoldi
                        cp ${runESVariation {name = "Random"; runners=GMRESESVariationRunners{inputs=packages.krylov_random_inputs; params = "-iters 200"; use_fdp = true; };}}/* data_random_arnoldi

                        mkdir plots_random_arnoldi
                        python postprocess_krylov.py -i data_random_arnoldi -o plots_random_arnoldi -max_iter 200 -tol 1e-80

                        # space for additional analyses
                    '';

                    installPhase = ''
                        mkdir -p $out/{random40,random_arnoldi}
                        mkdir -p $out/data/{random40,random_arnoldi}
                        cp plots_random/* $out/random40
                        cp plots_random_arnoldi/* $out/random_arnoldi

                        cp data_random/* $out/data/random40
                        cp data_random_arnoldi/* $out/data/random_arnoldi
                    '';
                };

                eval_krylov_sherman = pkgs.stdenv.mkDerivation {
                    name = "KrylovShermanEvaluator";
                    src = krylov/evaluate;

                    nativeBuildInputs = [python];

                    buildPhase = ''
                        mkdir -p data_sherman/{GMRES,QMR,QMRWLA}
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=GMRESRunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -hh -sparse -restart 30 -precond"; use_fdp = true;};}}/* data_sherman/GMRES
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=QMRRunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -hh -sparse -precond"; use_fdp = true;};}}/* data_sherman/QMR
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=QMRWLARunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -hh -sparse -precond"; use_fdp = true;};}}/* data_sherman/QMRWLA

                        mkdir -p plots_sherman/{GMRES,QMR,QMRWLA}
                        python postprocess_krylov.py -i data_sherman/GMRES -o plots_sherman/GMRES -max_iter 1500 -tol 1e-80
                        python postprocess_krylov.py -i data_sherman/QMR -o plots_sherman/QMR -max_iter 400 -tol 1e-80
                        python postprocess_krylov.py -i data_sherman/QMRWLA -o plots_sherman/QMRWLA -max_iter 250 -tol 1e-80

                        # cp plots_sherman/GMRES/GMRES.{png,svg} plots_sherman
                        # cp plots_sherman/QMR/QMR.{png,svg} plots_sherman
                        # cp plots_sherman/QMRWLA/QMRWLA.{png,svg} plots_sherman

                        mkdir data_sherman_arnoldi
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=GMRESRunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -sparse -restart 30 -precond"; use_fdp = true;};}}/* data_sherman_arnoldi

                        mkdir plots_sherman_arnoldi
                        python postprocess_krylov.py -i data_sherman_arnoldi -o plots_sherman_arnoldi -max_iter 4000 -tol 1e-80
                    '';

                    installPhase = ''
                        mkdir -p $out/{sherman5,sherman5_arnoldi}
                        mkdir -p $out/data/{sherman5,sherman5_arnoldi}
                        # cp -r plots_sherman/* $out/sherman5
                        # cp plots_sherman_arnoldi/* $out/sherman5_arnoldi

                        cp -r data_sherman/* $out/data/sherman5
                        cp data_sherman_arnoldi/* $out/data/sherman5_arnoldi
                    '';
                };

                eval_krylov_random = pkgs.stdenv.mkDerivation {
                    name = "KrylovRandomEvaluator";
                    src = krylov/evaluate;

                    nativeBuildInputs = [python];

                    buildPhase = ''
                        mkdir data_random
                        cp ${runMatrixAlgorithm {name = "Random"; runners=GMRESRunners{inputs=packages.krylov_random_inputs; params = "-iters 500 -sparse -hh"; use_fdp=true;};}}/* data_random
                        cp ${runMatrixAlgorithm {name = "Random"; runners=QMRRunners{inputs=packages.krylov_random_inputs; params = "-iters 500 -sparse -hh";use_fdp=true;};}}/* data_random
                        cp ${runMatrixAlgorithm {name = "Random"; runners=QMRWLARunners{inputs=packages.krylov_random_inputs; params = "-iters 500 -sparse -hh";use_fdp=true;};}}/* data_random

                        mkdir plots_random
                        python postprocess_krylov.py -i data_random -o plots_random -max_iter 500 -tol 1e-80

                        mkdir data_random_arnoldi
                        cp ${runMatrixAlgorithm {name = "Random"; runners=GMRESRunners{inputs=packages.krylov_random_inputs; params = "-iters 500 -sparse";use_fdp=true;};}}/* data_random_arnoldi

                        mkdir plots_random_arnoldi
                        python postprocess_krylov.py -i data_random_arnoldi -o plots_random_arnoldi -max_iter 500 -tol 1e-80
                    '';

                    installPhase = ''
                        mkdir -p $out/{random,random_arnoldi}
                        mkdir -p $out/data/{random,random_arnoldi}
                        cp plots_random/* $out/random
                        cp plots_random_arnoldi/* $out/random_arnoldi

                        cp data_random/* $out/data/random
                        cp data_random_arnoldi/* $out/data/random_arnoldi
                    '';
                };


                eval_krylov_sherman_no_fdp = pkgs.stdenv.mkDerivation {
                    name = "KrylovShermanEvaluator";
                    src = krylov/evaluate;

                    nativeBuildInputs = [python];

                    buildPhase = ''
                        mkdir -p data_sherman/{GMRES,QMR,QMRWLA}
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=GMRESRunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -hh -sparse -restart 30 -precond"; use_fdp = false;};}}/* data_sherman/GMRES
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=QMRRunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -hh -sparse -precond"; use_fdp = false;};}}/* data_sherman/QMR
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=QMRWLARunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -hh -sparse -precond"; use_fdp = false;};}}/* data_sherman/QMRWLA

                        mkdir -p plots_sherman/{GMRES,QMR,QMRWLA}
                        python postprocess_krylov.py -i data_sherman/GMRES -o plots_sherman/GMRES -max_iter 1500 -tol 1e-80
                        python postprocess_krylov.py -i data_sherman/QMR -o plots_sherman/QMR -max_iter 400 -tol 1e-80
                        python postprocess_krylov.py -i data_sherman/QMRWLA -o plots_sherman/QMRWLA -max_iter 250 -tol 1e-80

                        # cp plots_sherman/GMRES/GMRES.{png,svg} plots_sherman
                        # cp plots_sherman/QMR/QMR.{png,svg} plots_sherman
                        # cp plots_sherman/QMRWLA/QMRWLA.{png,svg} plots_sherman

                        mkdir data_sherman_arnoldi
                        cp ${runMatrixAlgorithm {name = "Sherman"; runners=GMRESRunners{inputs=packages.krylov_sherman_inputs; params = "-iters 4000 -sparse -restart 30 -precond"; use_fdp = false;};}}/* data_sherman_arnoldi

                        mkdir plots_sherman_arnoldi
                        python postprocess_krylov.py -i data_sherman_arnoldi -o plots_sherman_arnoldi -max_iter 4000 -tol 1e-80
                    '';

                    installPhase = ''
                        mkdir -p $out/{sherman5,sherman5_arnoldi}
                        mkdir -p $out/data/{sherman5,sherman5_arnoldi}
                        # cp -r plots_sherman/* $out/sherman5
                        # cp plots_sherman_arnoldi/* $out/sherman5_arnoldi

                        cp -r data_sherman/* $out/data/sherman5
                        cp data_sherman_arnoldi/* $out/data/sherman5_arnoldi
                    '';
                };

                eval_krylov_random_no_fdp = pkgs.stdenv.mkDerivation {
                    name = "KrylovRandomEvaluator";
                    src = krylov/evaluate;

                    nativeBuildInputs = [python];

                    buildPhase = ''
                        mkdir data_random
                        cp ${runMatrixAlgorithm {name = "Random"; runners=GMRESRunners{inputs=packages.krylov_random_inputs; params = "-iters 500 -sparse -hh"; use_fdp=false;};}}/* data_random
                        cp ${runMatrixAlgorithm {name = "Random"; runners=QMRRunners{inputs=packages.krylov_random_inputs; params = "-iters 500 -sparse -hh";use_fdp=false;};}}/* data_random
                        cp ${runMatrixAlgorithm {name = "Random"; runners=QMRWLARunners{inputs=packages.krylov_random_inputs; params = "-iters 500 -sparse -hh";use_fdp=false;};}}/* data_random

                        mkdir plots_random
                        python postprocess_krylov.py -i data_random -o plots_random -max_iter 500 -tol 1e-80

                        mkdir data_random_arnoldi
                        cp ${runMatrixAlgorithm {name = "Random"; runners=GMRESRunners{inputs=packages.krylov_random_inputs; params = "-iters 500 -sparse";use_fdp=false;};}}/* data_random_arnoldi

                        mkdir plots_random_arnoldi
                        python postprocess_krylov.py -i data_random_arnoldi -o plots_random_arnoldi -max_iter 500 -tol 1e-80
                    '';

                    installPhase = ''
                        mkdir -p $out/{random,random_arnoldi}
                        mkdir -p $out/data/{random,random_arnoldi}
                        cp plots_random/* $out/random
                        cp plots_random_arnoldi/* $out/random_arnoldi

                        cp data_random/* $out/data/random
                        cp data_random_arnoldi/* $out/data/random_arnoldi
                    '';
                };

                eval_krylov = pkgs.stdenv.mkDerivation {
                    name = "KrylovEvaluation";
                    unpackPhase = "true";
                    buildPhase = "true";

                    installPhase = ''
                        mkdir -p $out/{random,sherman}
                        mkdir $out/random/{fdp,no_fdp}
                        mkdir $out/sherman/{fdp,no_fdp}
                        cp -r ${packages.eval_krylov_random}/* $out/random/fdp
                        cp -r ${packages.eval_krylov_sherman}/* $out/sherman/fdp
                        cp -r ${packages.eval_krylov_random_no_fdp}/* $out/random/no_fdp
                        cp -r ${packages.eval_krylov_sherman_no_fdp}/* $out/sherman/no_fdp
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
                        cp -riva ${packages.eval_cim}/* $out/cim
                        cp -riva ${packages.eval_krylov}/* $out/krylov
                    '';
                };
            };

            defaultPackage = packages.eval_krylov;


            devShell = pkgs.mkShell {
                buildInputs = [
                    #manual_krylov.packages.${system}.solvers
                    #cim.packages.${system}.cim
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
