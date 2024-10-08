{
  description = "A Python development environment with pip & venv";

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs }:
  let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    eachSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f rec {
      inherit system;
      pkgs = import nixpkgs { inherit system; };
      python = pkgs.python310; #TODO: change to the version you want. e.g. `pkgs.python39` for python3.9;
      # or change to `pkgs.python310.withPackages (p: [])` if you need more python packages in nixpkgs
      pyver = python.version;
    });
  in
  {
    devShells = eachSystem ({pkgs, python, pyver, ...}: rec {
      default = pip;

      pip = pkgs.mkShell {
        buildInputs = [
          python
          # Add dev dependencies here
          python.pkgs.pip
          python.pkgs.virtualenv
          python.pkgs.setuptools
          python.pkgs.wheel
          python.pkgs.typing-extensions
          pkgs.git
        ];

        shellHook = ''
          echo "Welcome to your Python development environment with pip!"

          export PROMPT_COMMAND='PS1="\[\033[01;32m\]venv-py${pyver}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ";unset PROMPT_COMMAND'

          python3 -m venv --system-site-packages ./.venv-py${pyver}
          source ./.venv-py${pyver}/bin/activate

          export PIP_EXTRA_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

          if [ -f setup.py ] || [ -f setup.cfg ] || [ -f pyproject.toml ]; then
            echo "Project manifest detected. Installing project dependencies..."
            pip install -e .
          elif [ -f requirements.txt ]; then
            echo "requirements.txt detected, installing dependencies..."
            pip install -r requirements.txt
          fi
        '';
      };
    });

    apps = eachSystem ({system, pkgs, ...}: rec {
      default = main;
      main = {
        type = "app";
        # TODO: change this script to your own app entry
        program = "${pkgs.writeShellScript "funix-app" ''
          source ${self.devShells.${system}.default.shellHook}
          funix ./src
        ''}";
      };
    });

  };
}
