#!/bin/bash

# conda-auto-env automatically activates a conda environment when
# entering a folder with an environment.yml file.
#
# If the environment doesn't exist, conda-auto-env creates it and
# activates it for you.
#
# To install add this line to your .bashrc, .bash-profile, or .zshrc:
#
#       source /path/to/conda_auto_env.sh
#

function conda_auto_env() {
  if [ -e "environment.yml" ]; then
    ENV=$(cat environment.yml | grep name | sed -r 's/name: ([^\s]+)/\1/g' | xargs)
    echo "environment.yml file found describing environment '$ENV'"
    # Check if the environment is already active.
    if [[ $PATH != */envs/*$ENV*/* ]]; then
      # Attempt to activate environment.
      CONDA_ENVIRONMENT_ROOT="" #For spawned shells
      conda activate $ENV
      # Set root directory of active environment.
      if [ $? -ne 0 ]; then
        # Create the environment and activate.
        echo "Conda environment '$ENV' doesn't exist: Creating."
        conda env create -q
        conda activate $ENV
      fi
      CONDA_ENVIRONMENT_ROOT="$(pwd)"
    fi
  # Deactivate active environment if we are no longer among its subdirectories.
  elif [[ $PATH = */envs/* ]]\
    && [[ $(pwd) != $CONDA_ENVIRONMENT_ROOT ]]\
    && [[ $(pwd) != $CONDA_ENVIRONMENT_ROOT/* ]]
  then
    CONDA_ENVIRONMENT_ROOT=""
    conda deactivate
  fi
}

# Check active shell.
if [[ $(ps -p$$ -ocmd=) == "/usr/bin/zsh" ]]; then
  # For zsh, use the chpwd hook.
  autoload -U add-zsh-hook
  add-zsh-hook chpwd conda_auto_env
  # Run for present directory as it does not fire the above hook.
  conda_auto_env
  # More aggressive option in case the above hook misses some use case:
  #precmd() { conda_auto_env; }
else
  # For bash, no hooks and we rely on the env. var. PROMPT_COMMAND:
  export PROMPT_COMMAND=conda_auto_env
fi
