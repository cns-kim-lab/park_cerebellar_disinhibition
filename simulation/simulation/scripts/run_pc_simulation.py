"""run_pc_simulation.py

Run network simulation with a Purkinje cell model.

rm -rf $SPECIAL_PATH # e.g. x86_64
nrnivmodl ../src/modPC

python run_pc_simulation.py $NETID $SYNC $TRIAL

Command line arguments:
    network_sim_name: Network simulation ID (e.g. '43_20241112_153832')
    sync: CF synchronization group number
    trial: Trial number (1-20)
    -pf_syn_scale_factor: Parallel fiber synapse conductance scaling (default: 12, gmax=1.2e-4)
    -cf_syn_scale_factor: Climbing fiber synapse conductance scaling (default: 29, gmax=2.9e-4)
    -ncpu: Number of CPUs to use for simulation (default: 16)
    -with_gui: Whether to open the GUI for visualization (default: False)

Written by Sungho Hong, Center for Cognition and Sociality, IBS, South Korea

September 26, 2025
"""

import argparse

parser = argparse.ArgumentParser(
    description="Run network simulation with a Purkinje cell model."
)

parser.add_argument(
    "network_sim_name",
    type=str,
    metavar="network_sim_name",
    help="Name of the network simulation to load (e.g. '43_20241112_153832')",
)
parser.add_argument(
    "sync",
    type=int,
    metavar="sync",
    help="Climbing fiber synchronization group number (controls CF input timing)",
)
parser.add_argument(
    "trial",
    type=int,
    metavar="trial",
    help="Trial number for this simulation run (1-20)",
)
parser.add_argument(
    "-pf_syn_scale_factor",
    type=int,
    default=12,
    metavar="pf_syn_scale_factor",
    help="Scaling factor for parallel fiber synapse conductance. Default is 12, which gives gmax=1.2e-4",
)
parser.add_argument(
    "-cf_syn_scale_factor",
    type=int,
    default=29,
    metavar="cf_syn_scale_factor",
    help="Scaling factor for climbing fiber synapse conductance. Default is 29, which gives gmax=2.9e-4",
)
parser.add_argument(
    "-ncpu",
    type=int,
    default=16,
    metavar="ncpu",
    help="Number of CPUs to use for simulation. Default is 16.",
)
parser.add_argument(
    "-with_gui",
    type=bool,
    default=False,
    help="Whether to open the GUI for visualization. Default is False.",
)

args, unknown = parser.parse_known_args()

pf_syn_scale_factor = args.pf_syn_scale_factor
cf_syn_scale_factor = args.cf_syn_scale_factor

sync = args.sync
trial = args.trial
print(
    f"Network configuration: Network name: {args.network_sim_name}, CF sync group: {sync}, Trial number: {trial},",
    f"PF synapse scale: {pf_syn_scale_factor}, CF synapse scale: {cf_syn_scale_factor}\n---",
    f"with_gui: {args.with_gui}",
)

import os
import numpy as np
import pandas as pd

from neuron import h
import sys
import os
import sim_mlinet.syndist as syndist
import data_utils_mlinet as data_utils
import random
from tqdm.autonotebook import trange

from sim_mlinet.cell_templates import PF, SpikeData

h.load_file("stdrun.hoc")


# Transform the spike data into a list of SpikeData objects
def create_spike_data(ts, nodes):
    return [SpikeData(ts[ts[:, 1] == n, 0]) for n in nodes]


network_sim_name = args.network_sim_name
network_name = '_'.join(network_sim_name.split("_")[:3])

cf_syn_gmax = cf_syn_scale_factor * 1e-5
print(f"CF synapse gmax = {cf_syn_gmax}")

h.celsius = 34
h.dt = 0.02
h.steps_per_ms = 1 / h.dt
h.tstop = 300

random.seed(43)

# load PC model
pc_type = "pc_cf2"
h.xopen(f"../src/hoc/{pc_type}.hoc")
# h.xopen("pc_cf_passive_dend.hoc")

pkj = h.pkj_neuron()

# set up the parallel computing tool
h.load_file("parcom.hoc")
p = h.ParallelComputeTool()
p.change_nthread(args.ncpu, 1)
p.multisplit(1)
print(f"cpu: {args.ncpu}")

# add CF synapses - use the same method as Zang et al., 2018
syndist.add_cf_synapses_old(pkj)

pf_syn_map = syndist.add_pf_synapses(pkj)
IN_syn_map = syndist.add_IN_synapses(pkj, offset=np.max(list(pf_syn_map.values())) + 1)

n_pf = len(pf_syn_map)
n_in = len(IN_syn_map)
print(f"Number of pf_syn_map entries: {n_pf}")
print(f"Number of IN_syn_map entries: {n_in}")

# load the spike data
spikedata_filename = f"../../data/processed/simulation_results/output_network_simulation/spk_{network_name}_cfsync_sync_{sync}_w2_70_trial_{trial}.csv"
ts = np.loadtxt(spikedata_filename, delimiter=",")

# Load the network configurationfrom the file
cells = pd.read_csv(f"../../data/processed/generated_networks/cells_{network_name}.csv")
df_pf_syn = pd.read_csv(
    f"../../data/processed/generated_networks/pf_syn_table.csv", index_col=0
)

# Get the nodes for each cell type
pf234_nodes = cells[cells.cell_type.isin(["PF2", "PF3", "PF4"])].gid.values
assert len(pf234_nodes) == 6990, "The length of pf234_nodes is not 6990."

in1_nodes = cells[cells.cell_type == "IN1"].gid.values
assert len(in1_nodes) == 208, "The length of in1_nodes is not 208."
in2_nodes = cells[cells.cell_type == "IN2"].gid.values
assert len(in2_nodes) == 59, "The length of in2_nodes is not 59."

cf_nodes = cells[cells.cell_type == "CF"].gid.values
assert len(cf_nodes) == 22, "The length of cf_nodes is not 22."


# create the PF objects
n_pf_data = cells[cells.cell_type.isin(["PF2", "PF3", "PF4"])].gid.nunique()
print(f"Number of PF data nodes = {n_pf_data}")
n_pf1 = n_pf - n_pf_data
print(f"Number of PF1s = {n_pf1}")

pf234_spike = create_spike_data(ts, pf234_nodes)
in1_spike = create_spike_data(ts, in1_nodes)
in2_spike = create_spike_data(ts, in2_nodes)

random.seed(43)
pf_indices = np.array(list(pf_syn_map.keys()))
# random.shuffle(pf_indices)
i234 = np.arange(2000, n_pf, 3, dtype=int)
i234 = i234[:n_pf_data]
i1 = np.setdiff1d(np.arange(len(pf_indices), dtype=int), i234)
pf234_indices = sorted(pf_indices[i234])
pf1_indices = sorted(pf_indices[i1])
print("IN-projecting PF indices:", np.array(pf234_indices))
print("Non IN-projecting PF indices:", np.array(pf1_indices))

# connecting neurons to synapses
nclist = []

# 1. IN-projecting PFs
df_pf234 = df_pf_syn[df_pf_syn.shared == True]
for i, pf in enumerate(pf234_spike):
    (syn,) = df_pf234[df_pf234.pf_index == i].syn.values
    nc = pf.connect2target(pkj.synlist[syn])
    nc.weight[0] = 1e-6 * pf_syn_scale_factor
    nc.delay = 0.05
    nclist.append(nc)

    # pf_spiketimes.append(h.Vector())
    # pf.spike_detector.record(pf_spiketimes[-1])


# 2. Non IN-projecting PFs
df_pf1 = df_pf_syn[df_pf_syn.shared == False]
pf1_spike = [PF(i + 10000, init_rate=4) for i in df_pf1.index]
for i, pf in enumerate(pf1_spike):
    (syn,) = df_pf1[df_pf1.pf_index == i].syn.values
    nc = pf.connect2target(pkj.synlist[syn])
    nc.weight[0] = 1e-6 * pf_syn_scale_factor
    nc.delay = 0.05
    nclist.append(nc)

    # pf_spiketimes.append(h.Vector())
    # pf.spike_detector.record(pf_spiketimes[-1])

# 3. INs
in_syns_indices = list(IN_syn_map.keys())

# 3.1. IN1s
for i, in1 in enumerate(in1_spike):
    n_syns = round(7.5 + random.random() - 0.5)
    isyns = random.sample(in_syns_indices, n_syns)
    for isyn in isyns:
        nc = in1.connect2target(pkj.synlist[IN_syn_map[isyn]])
        nc.weight[0] = 25e-6
        nc.delay = 1.65
        nclist.append(nc)

# 3.2. IN2s
for i, in2 in enumerate(in2_spike):
    isyns = random.sample(in_syns_indices, 1)
    for isyn in isyns:
        nc = in2.connect2target(pkj.synlist[IN_syn_map[isyn]])
        nc.weight[0] = 25e-6
        nc.delay = 1.65
        nclist.append(nc)

# 4. CFs
CF = SpikeData([151.7])

for s in pkj.cfsynlist:
    nc = CF.connect2target(s)
    nc.weight[0] = cf_syn_gmax
    nc.delay = 0.05
    nc.threshold = 0.5
    nclist.append(nc)

# run the simulation by default record only soma voltage and calcium
def init_and_run(tstop=-1, record_ca=True, record_v=False, record_somav=True):

    if record_ca:
        ca_recording = data_utils.AllSegData(pkj)
        ca_recording.prepare_to_record()
        ca_recording.set_recording("cai")
    else:
        ca_recording = None

    if record_v:
        v_recording = data_utils.AllSegData(pkj)
        v_recording.prepare_to_record()
        v_recording.set_recording("v")
    else:
        v_recording = None

    if record_somav:
        # soma_v = create_single_recording(pkj.somaA(0.5), "v")
        soma_v = data_utils.SingleRecording(pkj.somaA(0.5))
        soma_v.prepare_to_record()
        soma_v.set_recording("v")
    else:
        soma_v = None

    h.init()
    h.continuerun(h.dt)

    if tstop < 0:
        tstop = int(h.tstop)

    for t in trange(tstop):
        h.continuerun(t)

    return {"ca": ca_recording, "v": v_recording, "somav": soma_v}



recordings = init_and_run()
save_dir = "../../data/processed/simulation_results/output_pc_simulation"
os.makedirs(save_dir, exist_ok=True)

fcommon = f"{save_dir}/{pc_type}_cf_{cf_syn_scale_factor}_pf_{pf_syn_scale_factor}_sync_{sync}_trial_{trial}_"

for key, recording in recordings.items():
    if recording is not None:
        recording.save(fcommon + f"{key}.npz")
        print(f"Saved {key} recording to {fcommon + f'{key}.npz'}")

h.quit()
