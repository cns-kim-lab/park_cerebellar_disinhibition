"""
assumes
1. sections to be innervated have been appended to a SectionList called seclist
2. synaptic density is in units of number/(length in um)
3. geometry specification has been completed, including spatial discretization
4. total number of synapses to distribute is called NUMSYN
https://www.neuron.yale.edu/phpBB/viewtopic.php?f=8&t=2264
"""

import numpy as np
from neuron import h


## Climbing fiber synapses
def get_cumulative_sum_seg_length(cf):
    # mvec = np.zeros(numsegs) # will hold cumulative sums of segment length
    # each element in mvec corresponds to a segment in seclist
    mvec = []
    # ii = 0 # to iterate over mvec
    mtotal = 0  # will be total length in seclist
    for sec in cf:
        for seg in sec:  # iterate over internal nodes of current section
            mtotal += sec.L / sec.nseg  # or area(x) if density is in (number)/area
            # mvec[ii] = mtotal
            mvec.append(mtotal)
            # now mvec[ii] is the sum of segment lengths (or areas)
            # for all segments up to and including segment ii
            # ii += 1
    return np.array(mvec)


def show_synapses(pkj, synlist):
    sl2 = h.SectionList()
    sl2.wholetree(sec=pkj.somaA)
    ss = h.Shape(sl2)

    for syn in synlist:
        ss.point_mark(syn, 2, 4, 2)

    return ss


def add_cf_synapses_old(pkj, d=45, L=50, min_p=0.025, seed=44):
    mvec = get_cumulative_sum_seg_length(pkj.cf)

    numsegs = len(mvec)
    nvec = np.zeros(numsegs)
    # each element in nvec corresponds to a segment in seclist
    # when done, each element will hold the number of synaptic mechanisms
    # that are to be attached to the corresponding segment

    nvec = np.zeros(mvec.size, dtype=int)

    NUMSYN = 500
    for i in range(NUMSYN):
        x = (
            mvec[-1] / NUMSYN * i
        )  # value drawn from uniform distribution over [0,mtotal]????
        (jj,) = np.where(mvec >= x)
        jj = jj[0]  # the first element in mvec that is >=x
        # this is the index of the segment that should get the synapse
        # print(i, jj)
        nvec[jj] += 1

    ii = 0
    for sec in pkj.cf:
        for seg in sec:
            num = nvec[ii]
            if num > 0:
                for j in range(num):
                    pkj.cfsynlist.append(h.Exp2Syn(seg))
                    # print(sec.name(), seg.x)
            ii += 1  # we're moving on to the next segment, so move on to the next element of nvec

    for syn in pkj.cfsynlist:
        syn.tau1 = 0.3
        syn.tau2 = 3
        syn.e = 0


def add_cf_synapses(pkj, d0=35, L=50, min_p=0.05, max_p=0.5, seed=44):

    np.random.seed(seed)

    p_base = min_p / max_p

    h.distance(pkj.somaA(0.5))
    for sec in pkj.cf:
        lseg = sec.L / sec.nseg
        for seg in sec:
            d = h.distance(seg.x, sec=sec)
            # print(sec.hname(), seg.x, d,)
            synapse_density = (1 - p_base) * np.min([1, np.exp(-(d - d0) / L)]) + p_base
            synapse_density = synapse_density * max_p
            nsyn_per_seg = int(lseg * synapse_density + np.random.rand() - 0.5)
            # print(lseg, synapse_density, nsyn_per_seg)
            for j in range(nsyn_per_seg):
                pkj.cfsynlist.append(h.Exp2Syn(seg))
                # print(1,)
    # print()

    ii = 0
    for syn in pkj.cfsynlist:
        syn.tau1 = 0.3
        syn.tau2 = 3
        syn.e = 0
        ii += 1
    print("Added", ii, "CF synapses")


## Parallel fiber synapses
def add_synapses(
    cell,
    target_dend_name="spinydend",
    synapse_density=2.8,
    compress_ratio=1,
    seed=43,
    syn_params=(0.3, 3, 0),
    offset=0,
):
    np.random.seed(seed)

    dends = eval(f"cell.{target_dend_name}")
    syn_id = 0
    real_syn_id = offset

    # syn_map maps unique synapse IDs to real synapse IDs in the cell's synlist.
    syn_map = {}

    for sec in dends:
        for seg in sec:

            lseg = sec.L / sec.nseg
            nsyn_per_seg = int(
                lseg * synapse_density / compress_ratio + np.random.rand() - 0.5
            )

            if nsyn_per_seg > 0:
                cell.synlist.append(h.Exp2Syn(seg))
                cell.synlist[-1].tau1 = syn_params[0]
                cell.synlist[-1].tau2 = syn_params[1]
                cell.synlist[-1].e = syn_params[2]

                for _ in range(nsyn_per_seg):
                    syn_map[syn_id] = real_syn_id
                    syn_id += 1

                real_syn_id += 1

    print("Added", real_syn_id, "synapse objects.")
    return syn_map


def add_pf_synapses(cell, offset=0, compress_ratio=1):
    return add_synapses(
        cell,
        target_dend_name="spinydend",
        synapse_density=2.8,
        compress_ratio=compress_ratio,
        seed=43,
        syn_params=(0.3, 3, 0),
        offset=0,
    )


def add_IN_synapses(cell, offset=0):
    return add_synapses(
        cell,
        target_dend_name="alldend",
        synapse_density=2.8 / 15.7 * 1.6,
        compress_ratio=1,
        seed=43,
        syn_params=(0.8, 6, -80),
        offset=offset,
    )
