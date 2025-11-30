# Modular BOOM Config Pipeline
The goal of this repository is to easily run multiple configurations of
BOOM cores for a specific workload and exctract the performance metrics.
The repository is meant to be run on linux (developed on Ubuntu).

## Setup repo
1. Pull the repo
2. Initialize chipyard as we did for previous labs
3. Run init.sh to inject custom files to chipyard environment

## Setup pipeline
1. Add new .c workload to workloads/ directory
2. Edit Makefile.md to include your new wokload
3. Run make to compile binary (make sure you are in the chipyard conda env)
4. Edit pipeline.sh with your binary name and the configs you want (options are displayed in pipeline.sh)

## Run pipeline
1. cd to chipyard/sims/verilator
2. Run pipeline.sh from inside that directory
3. The pipeline takes a while to run but will keep you updated

# Comments
A lot of comments provide extra detail, especially in ModularBoomConfig.scala to explain design decisions.

## Configuration Options
- There are 7 different parameters to change for each config
- The config variations are a mixin of already existing BOOM configurations (small, medium, large, mega)
- Not every possible combination of paramters is expected to work. A list of successful and failed configs can be found in output/config_history
- Some parameters were changed from the project proposal due to BOOM limitations and project scope.

## Workload files
- Every workload file should include hpm_boom.h and run the respective init and and print functions
- hpm_boom.h is BOOM-specific and the hpm definitions can be found in the comments in hpm_boom.h
- I have included hpm_rocket.h and multiplication_rocket.c from lab 3 as reference.

## Future work
- I wanted to do chip size analysis using UC Berkely's Hammer tool set, but could not get it to work with only opensource materials
- I ran into mapping issues with sram, and the sram22 repo requires access to UC Berkeley servers.
- I tried using OpenRAM, but also failed to get that working.
- I think future iterations of this project could look into Power Performance Area (PPA) analysis using UC Berkeley's tools or other open source tools