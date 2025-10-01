"""Run simulation of the MLI network.

rm -rf $SPECIAL_PATH # e.g. x86_64
nrnivmodl -coreneuron ../src/modIN

mpiexec -n $NPROC $SPECIAL_PATH/special -mpi -python run_network_simulation.py -cfsync $SYNC -trial $TRIAL

Command line arguments:
    -trial: Trial number (default: 1)
    -cfsync: CF synchronization group number (default: 8)
    -netid: Network ID (default: "43_20241112_153832")
    -w2: Weight multiplier for IN2->IN1 synapses (default: 70)

Created by Sungho Hong, Center for Cognition and Sociatlity, IBS, South Korea

September 26, 2025
"""

import os
import argparse
import pandas as pd
from sim_mlinet.cell_templates import IN1, IN2, PF, CF
from neuron import h, coreneuron
import random

parser = argparse.ArgumentParser(description="Run parallel simulation.")
parser.add_argument("-trial", type=int, default=1, metavar="T", help="Trial number")
parser.add_argument("-cfsync", type=int, default=8, metavar="S", help="CF sync number")
parser.add_argument(
    "-netid", type=str, default="43_20241112_153832", metavar="N", help="Network ID"
)
parser.add_argument(
    "-w2",
    type=int,
    default=70,
    metavar="W",
    help="Weight multiplier for IN2->IN1 synapses",
)

args, unknown = parser.parse_known_args()

trial = args.trial
cf_id = f"sync_{args.cfsync}"
network_id = args.netid
w2 = args.w2

# ## Hard-coded weights
weightE = 5e-6 * 3  # pS
weightI2 = 1e-6 * w2  # IN2->IN1 pS
weightI1 = 25e-6  # all others pS

# Update: June 2025
# Peak EPSC = 110.41 pA at -70 mV (traces)
# conductance = 110.41/70 = 1.5773 nS (traces)
weightCF = 1577.3e-6  # CF->IN2 pS (traces)

#
h.cvode.cache_efficient(1)
coreneuron.enable = True
coreneuron.gpu = False


h.nrnmpi_init()  # initialize MPI
pc = h.ParallelContext()
rank = int(pc.id())
nhost = int(pc.nhost())


def load_network_files(
    network_id, network_data_dir="../data/processed/generated_networks"
):
    cells = pd.read_csv(f"{network_data_dir}/cells_{network_id}.csv")
    synaptic_connections = pd.read_csv(
        f"{network_data_dir}/synaptic_connections_{network_id}.csv"
    )
    gap_connections = pd.read_csv(
        f"{network_data_dir}/gap_connections_{network_id}.csv"
    )
    return cells, synaptic_connections, gap_connections


def load_cf_times(
    cf_times_id, cf_times_data_dir="../data/processed/generated_networks"
):
    cf_times = pd.read_csv(f"{cf_times_data_dir}/cf_times_43_{cf_times_id}.csv")
    return cf_times

# initialize MPI
h.nrnmpi_init()
pc = h.ParallelContext()
rank = int(pc.id())
nhost = int(pc.nhost())

# set random seed
random.seed(42 + trial + rank)

# load network files
cells, synaptic_connections, gap_connections = load_network_files(network_id)
cf_times = load_cf_times(cf_id)

# Round-robin partitioning
cells = cells[cells["gid"] % nhost == rank]

# Create cells based on their type
cell_list = []
cf_list = []
for _, row in cells.iterrows():

    gid = row["gid"]
    cell_type = row["cell_type"]

    if cell_type == "IN1":
        r = (random.random() - 0.5) * 2
        cell = IN1((0.0325 - 0.002 + 0.008 * r))
    elif cell_type == "IN2":
        r = (random.random() - 0.5) * 2
        cell = IN2((0.0185 - 0.004 + 0.004 * r))
    elif cell_type.startswith("PF"):
        cell = PF(gid + trial, init_rate=4)
    elif cell_type == "CF":
        t_cf = cf_times.loc[cf_times["gid"] == gid, "spiketime"].values[0]
        cell = CF(t_cf=t_cf)
    else:
        raise ValueError(f"Unknown cell type: {cell_type}")

    cell_list.append(cell)

    # Register this cell in the parallel context
    pc.set_gid2node(gid, rank)
    nc = cell.connect2target(None)
    pc.cell(gid, nc)

# Connect gap junctions
for sid, row in gap_connections.iterrows():
    gid_source = row["source"]
    gid_target = row["target"]
    if pc.gid_exists(gid_source):
        source_dendid = int(row["source_dendid"])
        source_x = row["source_x"]

        source_sec = pc.gid2cell(gid_source).dend[source_dendid]
        source_seg = source_sec(source_x)
        pc.source_var(source_seg._ref_v, sid, sec=source_sec)

    if pc.gid_exists(gid_target):
        target_dendid = int(row["target_dendid"])
        target_x = row["target_x"]

        target_cell = pc.gid2cell(gid_target)
        gap = target_cell.add_gap_junction(target_dendid, target_x, pc=pc)
        pc.target_var(gap, gap._ref_vgap, sid)

pc.setup_transfer()

nclist = []
for _, row in synaptic_connections.iterrows():
    gid_source = row["source"]
    gid_target = row["target"]
    if pc.gid_exists(gid_target):
        target_cell = pc.gid2cell(gid_target)
        connection_type = row["label"]
        target_dendid = int(row["dendid"])
        target_x = row["x"]

        # PF->IN
        if connection_type.startswith("PF"):
            syn = target_cell.add_synapses(
                dendid=target_dendid, x=target_x, syntype="E"
            )
            nc = pc.gid_connect(gid_source, syn)
            nc.delay = 0.05
            nc.weight[0] = weightE

        # IN->IN
        elif connection_type.startswith("IN"):
            syn = target_cell.add_synapses(
                dendid=target_dendid, x=target_x, syntype="I"
            )
            nc = pc.gid_connect(gid_source, syn)
            nc.delay = 1 + 0.5 * random.random()
            if connection_type == "IN2->IN1":
                nc.weight[0] = weightI2
            else:
                nc.weight[0] = weightI1

        # CF->IN
        elif connection_type.startswith("CF"):
            # print(f"{gid_source}, {gid_target}, {row['label']}")
            syn = target_cell.add_synapses(
                dendid=target_dendid, x=target_x, syntype="CF"
            )
            nc = pc.gid_connect(gid_source, syn)
            nc.delay = 1.75
            nc.weight[0] = weightCF
        else:
            raise ValueError(f"Unknown connection type: {connection_type}")

    # MUST STORE NCs
    nclist.append(nc)

# record spikes
tvec = h.Vector(1000000)
idvec = h.Vector(1000000)
pc.spike_record(-1, tvec, idvec)

# set simulation parameters
h.celsius = 34
h.dt = 0.025

pc.set_maxstep(10)

# run simulation
h.stdinit()
pc.psolve(300)
pc.barrier()

# save spikes
save_dir = "../../data/processed/simulation_results/output_network_simulation"
os.makedirs(save_dir, exist_ok=True)
fname = f"{save_dir}/spk_{network_id}_cfsync_{cf_id}_w2_{w2}_trial_{trial}.csv"

if rank == 0:
    print(f"Saving spikes to {fname}")
    f = open(fname, "w")
    f.close()
for r in range(nhost):
    if r == rank:
        f = open(fname, "a")
        for i in range(len(tvec)):
            f.write("%g,%d\n" % (tvec.x[i], int(idvec.x[i])))
        f.close()
    pc.barrier()
