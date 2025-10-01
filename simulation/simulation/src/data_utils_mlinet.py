"""
Utility functions for data recording and analysis.

Written by Sungho Hong, Center for Cognition and Sociality, IBS, South Korea

September 26, 2025
"""

__version__ = "0.1.0"

import numpy as np
from neuron import h
from tqdm.autonotebook import tqdm, trange

class SingleRecording(object):
    def __init__(self, seg):
        self.seg = seg

    def prepare_to_record(self):
        self.tvec = h.Vector()
        self.prepare_empty_data()

    def prepare_empty_data(self):
        self.data = h.Vector()

    def set_recording(self, variable):
        self.tvec.record(h._ref_t)
        if variable == "v":
            self.data.record(self.seg._ref_v)
        elif variable == "cai":
            self.data.record(self.seg._ref_cai)
        else:
            raise NotImplementedError

    def save(self, filename):
        # assert the file name ends with npz
        assert filename[-4:] == ".npz"

        np.savez_compressed(
            filename,
            t=np.array(self.tvec),
            data=np.array(self.data),
            allow_pickle=True,
        )


class AllSegData(object):
    def __init__(self, pkj):
        self.pkj = pkj

    def prepare_to_record(self):
        self.tvec = h.Vector()
        self.collect_all_segs()
        self.prepare_empty_data()

    def collect_all_segs(self):
        def _collect_all_segs(pkj):
            segs = [seg for seg in pkj.somaA]

            for sec in pkj.alldend:
                segs_sec = [seg for seg in sec]
                segs.extend(segs_sec)

            return segs

        self.segs = _collect_all_segs(self.pkj)

    def prepare_empty_data(self):
        self.data = []
        for seg in self.segs:
            self.data.append(h.Vector())

    def set_recording(self, variable):
        self.var = variable
        self.tvec.record(h._ref_t)
        for i, seg in enumerate(self.segs):
            self.data[i].record(eval(f"seg._ref_{variable}"))

    def save(self, filename):
        # assert the file name ends with npz
        assert filename[-4:] == ".npz"

        # Convert segments to their indices or properties
        seg_indices = [
            (seg.sec.name(), seg.x, seg.diam, h.distance(seg, self.pkj.somaA(0.05)))
            for seg in self.segs
        ]

        np.savez_compressed(
            filename,
            t=np.array(self.tvec),
            data=np.array(self.data),
            segs=np.array(seg_indices),
            allow_pickle=True,
        )

    def load(self, filename):
        data_all = np.load(filename, allow_pickle=True)
        self.tvec = data_all["t"]
        self.data = data_all["data"]
        seg_indices = data_all["segs"]

        self.segs = [eval(f"h.{seg[0]}({seg[1]})") for seg in seg_indices]
