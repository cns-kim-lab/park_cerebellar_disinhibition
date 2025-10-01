# Purkinje Cell - Molecular Layer Interneuron Network Simulation

A NEURON-based simulations of cerebellar molecular layer interneuron (MLI) networks and their interactions with Purkinje cells (PC), with a focus on studying climbing fiber (CF) synchrony effects.

## Overview

This project implements detailed biophysical simulations of:

- **MLI network** (MLI1 and MLI2 cells) with gap junction coupling and synaptic connections that receive inputs from parallel fibers (PF) and climbing fibers (CF).
- **PC model** with realistic morphology and ion channel dynamics that receives inputs from the MLIs, PFs, and one of CFs.
- **CF synchrony experiments** to study the impact of synchronized CF inputs on MLI network activity and PC dendritic calcium dynamics

## Project Structure

```plaintext
├── README.md                          # This file
├── data/
│   └── processed/
│       ├── generated_networks/       # Network connectivity based on experimental data
│       │   ├── cells_*.csv           # Cell types and IDs
│       │   ├── synaptic_connections_*.csv # Synaptic connections
│       │   ├── gap_connections_*.csv # Gap junction connections
│       │   ├── cf_times_*_sync_*.csv # CF spike times
│       │   └── pf_syn_table.csv # table for PC PF synapses
│       └── simulation_results/
│           ├── output_network_simulation/  # Example network spike data
│           └── output_pc_simulation/ # Example PC recordings (V)
└── simulation/
    ├── pyproject.toml                # Package configuration
    ├── scripts/
    │   ├── run_network_simulation.py # MLI network simulation
    │   └── run_pc_simulation.py      # Purkinje cell simulation
    ├── src/
    │   ├── modPC/                    # Purkinje cell ion channel mechanisms
    │   ├── modIN/                    # MLI1 and MLI2 cell mechanisms
    │   ├── hoc/                      # PC morphology and templates
    │   ├── sim_mlinet/               # Cell templates and utilities
    │   └── dataanalysis_mlinet/      # Analysis and plotting tools
    └── notebooks/
        └── plot_all_vertically.ipynb # Visualization notebook
```

## Dependencies

- **Python 3.10+**: Core language
- **MPI (MPICH or OpenMPI)**: For parallel computing
- **Scientific stack**: numpy, scipy, pandas, matplotlib
- **NEURON 8.2+**: Neural simulator with Python interface
- **Additional**: networkx, tqdm, omegaconf, hydra-core

## Installation

We recommend using [uv](https://docs.astral.sh/uv/) for environment management.

```bash
cd simulation/
uv venv
uv sync
```

Then, we activate the environment and install the package:
```bash
source .venv/bin/activate
uv pip install -e .
```

## Running Simulations

### MLI Network Simulation

First we compile the NEURON mechanisms for the MLI models:
```bash
cd scripts/

# Clean up existing compiled mechanisms
rm -rf x86_64 # use arm64 on Apple Silicon

# Compile MLI cell mechanisms
nrnivmodl -coreneuron ../src/modIN # Note that we use coreneuron.
```

Then, we run the simulation:
```bash
# Use arm64/special on Apple Silicon
mpiexec -n $NPROCS ./x86_64/special -mpi -python run_network_simulation.py \
  -cfsync $CFSYNC -trial $TRIAL
```

Here `NPROCS` is the number of parallel processes, `CFSYNC` is the CF synchrony level (0-8), and `TRIAL` is the trial number (1-20 in the paper).

**Parameters:**

- `-cfsync`: CF synchrony level (0-8)
- `-trial`: Trial number (1-20) for different random seeds
- `-netid`: Network configuration ID (default: "43_20241112_153832" as an example in data/processed/generated_networks)
- `-w2`: IN2→IN1 synapse weight multiplier (default: 70)

**Output:** Spike time CSV files in `data/processed/simulation_results/output_network_simulation/spk_{netid}_cfsync_sync_{sync}_w2_{w2}_trial_{trial}.csv`

### Purkinje Cell Simulation

Uses MLI network spike data as input to simulate PC responses:

```bash
cd simulation/scripts/

# Clean up existing compiled mechanisms
rm -rf x86_64 # or arm64 if you are on Apple Silicon

# Rebuild mechanisms for PC
nrnivmodl ../src/modPC # not coreneuron compatible yet

# Run PC simulation (using network spike data from sync_8, trial 1)
python run_pc_simulation.py $NETID $SYNC $TRIAL
```
Here `NETID` is the network ID (default: "43_20241112_153832" as an example in data/processed/generated_networks).
`SYNC` is the CF synchrony level (0-8), and `TRIAL` is the trial number (1-20 in the paper).

**Parameters:**

- `network_sim_name`: Network ID (matches netid from MLI simulation, default: "43_20241112_153832")
- `sync`: CF synchrony level (0-8)
- `trial`: Trial number (1-20)
- `-pf_syn_scale_factor`: PF synapse conductance scaling (default: 12 → 1.2e-4 S/cm²)
- `-cf_syn_scale_factor`: CF synapse conductance scaling (default: 29 → 2.9e-4 S/cm²)
- `-ncpu`: Number of CPU threads (default: 16)

**Output:** NPZ files in `data/processed/simulation_results/output_pc_simulation/`

- `*_somav.npz`: membrane voltage at soma
- `*_ca.npz`: dendritic calcium concentration (all segments)

## Data Analysis and Visualization

Please see the provided Jupyter notebook `plot_all_vertically.ipynb` in `simulation/notebooks/` for how to read and analyze simulation results and generate visualization:

---
Written by Sungho Hong, Center for Cognition and Sociality, IBS, South Korea

September 26, 2025
