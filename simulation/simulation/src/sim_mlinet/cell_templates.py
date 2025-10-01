from neuron import h
import numpy as np


def lambda_f(freq, diam, Ra, cm):
    return 1e5 * np.sqrt(diam / (4 * np.pi * freq * Ra * cm))


def nseg_lambda(sec, d_lambda=0.1, freq=100):
    return (
        int((sec.L / (d_lambda * lambda_f(freq, sec.diam, sec.Ra, sec.cm)) + 0.9) / 2)
        * 2
        + 1
    )


# INs
class IN:
    def __init__(self, bias_current, Lscale=1.0, diam_scale=1):

        self.create_sections()
        self.set_topology()
        self.set_geometry(Lscale, diam_scale)
        self.set_biophysics()

        self.bias = h.IClamp(self.soma(0.5))
        self.bias.delay = 0
        self.bias.dur = 360e3
        self.bias.amp = bias_current

        self.synlist = {}
        self.synlist["E"] = []
        self.synlist["I"] = []
        self.synlist["CF"] = []

        self.gap_list = []

        self.has_soma = True

        self.spike_detector = self.connect2target(None)

    def create_sections(self):
        self.soma = h.Section(name="soma", cell=self)
        self.dend = [h.Section(name=f"dend[{i}]", cell=self) for i in range(12)]
        self.allsec = h.SectionList()
        self.allsec.append(self.soma)

        for sec in self.dend:
            self.allsec.append(sec)

    def set_geometry(self, Lscale, diam_scale):
        self.soma.L = 17
        self.soma.diam = 5.3

        for i in range(4):
            self.dend[i].L = 20
            self.dend[i].diam = 0.57
            self.dend[i].nseg = nseg_lambda(self.dend[i])

        for i in range(4, 12):
            self.dend[i].L = 180 * Lscale
            self.dend[i].diam = 0.57 * diam_scale
            self.dend[i].nseg = nseg_lambda(self.dend[i])

    def set_topology(self):

        self.dend[0].connect(self.soma(0))
        self.dend[1].connect(self.soma(0))
        self.dend[2].connect(self.soma(1))
        self.dend[3].connect(self.soma(1))
        self.dend[4].connect(self.dend[0](1))
        self.dend[5].connect(self.dend[0](1))
        self.dend[6].connect(self.dend[1](1))
        self.dend[7].connect(self.dend[1](1))
        self.dend[8].connect(self.dend[2](1))
        self.dend[9].connect(self.dend[2](1))
        self.dend[10].connect(self.dend[3](1))
        self.dend[11].connect(self.dend[3](1))

    def set_biophysics(self):
        """
        All the parameters are from Ma et al., Nat Commun, 2020.
        A soma has active mechanisms whereas dendrites are passive.
        """
        Vleak = -65
        fator = 1.0

        Cm_all = fator * 1.5  # uF/cm**2 Molineux et al., 2005
        Rm_all = 20e3 / 1.4  # ohm*cm**2 Molineux et al., 2005
        Ra_all = 115  # ohm*cm Roth and Hausser 2001
        gL = fator * 1.0 / Rm_all  # siemens/cm**2

        for sec in self.allsec:
            sec.insert("pas")
            sec.g_pas = gL
            sec.Ra = Ra_all
            sec.e_pas = Vleak
            sec.cm = Cm_all

        Cm_soma = 1.5  # uF/cm**2 Molineux et al., 2005
        Rm_soma = 20e3 / 1.4  # ohm*cm**2 Traub 91
        Ra_soma = 115  # ohm*cm Roth and Hausser 2001
        gL_soma = 1.0 / Rm_soma  # siemens/cm**2

        self.soma.insert("pas")
        self.soma.g_pas = gL_soma
        self.soma.Ra = Ra_soma
        self.soma.e_pas = Vleak
        self.soma.cm = Cm_soma

        self.soma.insert("Golgi_Na")
        self.soma.insert("Golgi_KV")
        self.soma.insert("Golgi_KA")
        self.soma.insert("Golgi_Ca_LVA")

        self.soma.ena = 60  # Masoli et al. 2015
        self.soma.ek = -88  # Masoli et al. 2015

        self.soma.gnabar_Golgi_Na = 100e-2  # (S/cm2)
        self.soma.gkbar_Golgi_KV = 60e-2  # (S/cm2)

        self.soma.Aalpha_n_Golgi_KV = 0.1 * -0.01  # (/ms-mV)
        self.soma.Abeta_n_Golgi_KV = 0.1 * 0.125  # (/ms)

        self.soma.gkbar_Golgi_KA = 5 * 2e-2  # (S/cm2)
        self.soma.gca2bar_Golgi_Ca_LVA = 16 * 0.2e-2  # (S/cm2)

    def add_gap_junction(self, dendi, x, g=300e-6, pc=None):
        if pc:
            # Parallel version
            # it should check if pc is really h.ParallelContext... my bad
            gap = h.gap(self.dend[dendi](x))
        else:
            gap = h.gaps(self.dend[dendi](x))

        gap.g = g
        self.gap_list.append(gap)
        return self.gap_list[-1]

    def add_synapses(self, dendid, x, syntype):
        syn = h.Exp2Syn(self.dend[dendid](x))
        if syntype == "E":
            syn.tau1 = 0.28
            syn.tau2 = 1.23
            syn.e = 0
        elif syntype == "I":
            syn.tau1 = 1.8
            syn.tau2 = 8.5
            syn.e = -65
        elif syntype == "CF":
            syn.tau1 = 0.4
            syn.tau2 = 3
            syn.e = 0
        else:
            raise ValueError(f"Unknown synapse type: {syntype}")

        self.synlist[syntype].append(syn)
        return self.synlist[syntype][-1]

    def connect2target(self, target, thresh=-30, delay=0.1):
        nc = h.NetCon(self.soma(1)._ref_v, target, sec=self.soma)
        nc.threshold = thresh
        nc.delay = delay
        return nc


class IN1(IN):
    def __init__(self, bias_current):
        super().__init__(bias_current, Lscale=1.0)

    def spray_synapses(self):
        Ltotal = 0
        for dend in self.dend:
            Ltotal += dend.L

        prob_per_dend = np.array([sec.L / Ltotal for sec in self.dend])

        # Excitatory
        found = np.random.choice(12, 645, p=prob_per_dend)
        for i in found:
            syn = h.Exp2Syn(self.dend[i](np.random.rand()))
            syn.tau1 = 0.28
            syn.tau2 = 1.23
            syn.e = 0
            self.synlist["E"].append(syn)

        # Inhibitory
        found = np.random.choice(12, 43, p=prob_per_dend)
        for i in found:
            syn = h.Exp2Syn(self.dend[i](np.random.rand()))
            syn.tau1 = 1.8
            syn.tau2 = 8.5
            syn.e = -65
            self.synlist["I"].append(syn)


class IN2(IN):
    def __init__(self, bias_current):
        super().__init__(bias_current, Lscale=100 / 180)
        # self.add_synapses()

    def spray_synapses(self):
        Ltotal = 0
        for dend in self.dend:
            Ltotal += dend.L

        self.synlist = {}
        self.synlist["E"] = []
        self.synlist["I"] = []
        self.synlist["CF"] = []

        prob_per_dend = np.array([sec.L / Ltotal for sec in self.dend])

        # Excitatory
        found = np.random.choice(12, 460, p=prob_per_dend)
        for i in found:
            syn = h.Exp2Syn(self.dend[i](np.random.rand()))
            syn.tau1 = 0.28
            syn.tau2 = 1.23
            syn.e = 0
            self.synlist["E"].append(syn)

        # Inhibitory
        found = np.random.choice(12, 23, p=prob_per_dend)
        for i in found:
            syn = h.Exp2Syn(self.dend[i](np.random.rand()))
            syn.tau1 = 1.8
            syn.tau2 = 8.5
            syn.e = -65
            self.synlist["I"].append(syn)

        # Climbing fiber
        self.synlist["CF"] = [h.Exp2Syn(self.dend[i](0.5)) for i in range(4)]
        for syn in self.synlist["CF"]:
            syn.tau1 = 0.5
            syn.tau2 = 12
            syn.e = 0


# Parallel fibers
class PF(object):
    def __init__(self, seed, init_rate=4, duration=360000):
        self.v = h.NetStim()
        self.v.start = 0
        self.v.noise = 1
        self.set_rate(init_rate)
        self.v.number = int(duration / self.v.interval)
        self.v.noiseFromRandom123(seed, 0, 0)

        self.has_soma = False

        self.spike_detector = self.connect2target(None)

    def set_rate(self, rate):
        self.v.interval = 1000 / rate

    def connect2target(self, target, thresh=0.5, delay=0.05):
        nc = h.NetCon(self.v, target)
        nc.threshold = thresh
        nc.delay = delay
        return nc


class CF(object):
    def __init__(self, t_cf):
        self.v = h.NetStim()
        self.v.start = t_cf
        self.v.interval = 1000
        self.v.noise = 0
        self.v.number = 1

        self.has_soma = False

        self.spike_detector = self.connect2target(None)

    def connect2target(self, target, thresh=0.5, delay=0.05):
        nc = h.NetCon(self.v, target)
        nc.threshold = thresh
        nc.delay = delay
        return nc


class CF_noisy(object):
    def __init__(self, seed, t_cf, t_offset=0, noise=0.00075, number=1):
        self.v = h.NetStim()
        self.v.start = t_cf - t_offset
        self.v.interval = 1000
        self.v.noise = noise
        self.v.number = number
        self.v.noiseFromRandom123(0, seed, 0)

        self.has_soma = False

        self.spike_detector = self.connect2target(None)

    def connect2target(self, target, thresh=0.5, delay=0.05):
        nc = h.NetCon(self.v, target)
        nc.threshold = thresh
        nc.delay = delay
        return nc


class SpikeData(object):
    def __init__(self, spiketime):
        self.spiketime = h.Vector()
        self.spiketime.from_python(spiketime)

        self.v = h.VecStim()
        self.v.play(self.spiketime)

        ## CAUTION: This part causes an issue with ParallelComputeTool.
        ## Either spike_detector is turned off or the delay should be
        ## sufficiently large, e.g. 0.05 ms

        ## self.spike_detector = self.connect2target(None)
        ## self.spike_detector.delay = 0.05

    def print_spiketime(self):
        for time in self.spiketime:
            print(f"Spike at time: {time}")

    def connect2target(self, target, thresh=0.5, delay=0.05):
        nc = h.NetCon(self.v, target)
        nc.threshold = thresh
        nc.delay = delay
        return nc


h.load_file("stdrun.hoc")

h.celsius = 34  # temperature (Forrest, 2015)
h.v_init = -67
# h.dt = 0.01
