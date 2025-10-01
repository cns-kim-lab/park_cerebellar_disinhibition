import os
from re import X
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime
from scipy.ndimage import gaussian_filter1d
from scipy.signal import get_window

def get_trial_sync_from_filenames(x):
    """read trial and sync number from filename"""
    parts = x.split("_")

    # Find trial number after "trial_"
    trial_idx = None
    for i, part in enumerate(parts):
        if part == "trial":
            trial_idx = i + 1
            break

    # Find sync number after "sync_"
    sync_idx = None
    for i, part in enumerate(parts):
        if part == "sync":
            sync_idx = i + 1
            break

    if trial_idx is not None and trial_idx < len(parts):
        trial = parts[trial_idx].split(".")[0]  # Remove .csv extension if present
    else:
        raise ValueError("Could not find trial number in filename")

    if sync_idx is not None and sync_idx < len(parts):
        sync = parts[sync_idx]
    else:
        raise ValueError("Could not find sync number in filename")

    return int(trial), int(sync)

class Plot:
    def __init__(self):
        now = datetime.now()
        self.savedir = f"../reports/figures/{now.year}_{now.month:02d}_{now.day:02d}"
        os.makedirs(self.savedir, exist_ok=True)

    def get_full_savepath(self, filename):
        return f"{self.savedir}/{filename}"

    def savefig(self, filename):
        filepath = self.get_full_savepath(filename)
        self._savefig(filepath)

    def _savefig(self, filepath):
        raise NotImplementedError


class MatPlotLibPlot(Plot):
    def __init__(self, fig_ax=None, figsize=(3.54, 2.54), **kwargs):
        super().__init__()

        if fig_ax is None:
            self.fig, self.ax = plt.subplots(figsize=figsize, **kwargs)
        else:
            self.fig, self.ax = fig_ax

    def show(self):
        plt.show()

    def _savefig(self, filepath, dpi=1200, use_tight_layout=True):
        if use_tight_layout:
            plt.tight_layout()
        self.fig.savefig(filepath, dpi=dpi)


class MultiTrace(MatPlotLibPlot):
    def __init__(
        self, data_type, t0=0, show_legend=False, fig_ax=None, figsize=(1.77*1.5, 1*1.5)
    ):
        super().__init__(fig_ax, figsize)
        self.data_type = data_type
        self.t0 = t0
        self.show_legend = show_legend
        self.ylabel = self._get_ylabel(data_type)
        self.traces = []

    def _get_ylabel(self, data_type):
        if data_type == "voltage":
            return "voltage (mV)"
        elif data_type == "calcium":
            return "[Ca2+] (nM)"
        else:
            raise ValueError(
                "Unsupported data type. Supported types are 'voltage' and 'calcium'."
            )

    def add_trace(self, f, select, color, label):
        t = f["t"]
        if self.data_type == "voltage":
            v = f["data"]
        elif self.data_type == "calcium":
            v = f["data"] * 1e6
        else:
            raise ValueError(
                "Unsupported data type. Supported types are 'voltage' and 'calcium'."
            )

        if select is None:
            v = v[None, :]
            self.traces.append((t, v, [0], color, label))
        else:
            self.traces.append((t, v, select, color, label))

    def plot_traces(self, with_xscale_bar=False, with_yscale_bar=False, with_error_bars=False, with_xaxis=True, return_data=False):
        plotted_data = []
        for t, v, select, color, label in self.traces:
            if with_error_bars:
                if np.issubdtype(select.dtype, np.number):
                    N = select.size
                elif np.issubdtype(select.dtype, np.bool_):
                    N = np.sum(select)
                else:
                    raise ValueError(
                        "Unsupported select array type. Supported types are numerical and boolean."
                    )
                sem = v[select, self.t0 :].std(axis=0) / np.sqrt(N)
                self.ax.fill_between(
                    t[self.t0 :],
                    v[select, self.t0 :].mean(axis=0) + sem,
                    v[select, self.t0 :].mean(axis=0) - sem,
                    color=color,
                    alpha=0.3,
                    linewidth=0.01,
                )

            self.ax.plot(
                t[self.t0 :],
                v[select, self.t0 :].mean(axis=0),
                color,
                label=label,
                linewidth=0.5,
            )
            plotted_data.append((t, v[select,:].mean(axis=0)))

        # self.ax.set(ylabel=self.ylabel)
        # if self.ax.get_xticklabels():
        #     self.ax.set(xlabel="time (ms)")

        if with_xscale_bar:
            self.ax.spines["bottom"].set_bounds(90, 110)
            self.ax.set(
                # xlim=[80, 270],
                xticks=[90, 110, 150],
                xticklabels=["20 ms", "", ""],
            )
        else:
            if with_xaxis:
                self.ax.spines["bottom"].set_visible(True)
                self.ax.spines["bottom"].set_bounds(80, 275)
                self.ax.set(xticks=np.arange(100, 275, 50))
            else:
                self.ax.spines["bottom"].set_visible(False)
                self.ax.set(xticks=[])

        if with_yscale_bar:
            if self.data_type == "voltage":
                lower_ylim = -70
                # self.ax.plot(
                #     [80 + 2, 100 + 2],
                #     [lower_ylim, lower_ylim],
                #     color="black",
                #     linewidth=1,
                # )
                # self.ax.plot(
                #     [80 + 2, 80 + 2],
                #     [lower_ylim, lower_ylim + 20],
                #     color="black",
                #     linewidth=1,
                # )
                self.ax.spines["left"].set_bounds(lower_ylim, lower_ylim+70)
                self.ax.set(
                    # xlim=[80, 270],
                    yticks=[lower_ylim, lower_ylim+70],
                    yticklabels=["-70", "0"],  # 40Hz: IN1, 100Hz: IN2
                )

            if self.data_type == "calcium":
                # lower_ylim = self.ax.get_ylim()[0]
                lower_ylim = v[select, self.t0].min()-60
                # self.ax.plot(
                #     [80 + 2, 100 + 2],
                #     [lower_ylim, lower_ylim],
                #     color="black",
                #     linewidth=1,
                # )
                # self.ax.plot(
                #     [80 + 2, 80 + 2],
                #     [lower_ylim, lower_ylim + 500],
                #     color="black",
                #     linewidth=1,
                # )
                yaxshift = 50
                self.ax.spines["left"].set_bounds(lower_ylim+yaxshift, lower_ylim+500+yaxshift)
                self.ax.set(
                    yticks=[lower_ylim+yaxshift, lower_ylim+500+yaxshift],
                    yticklabels=["", "500 nM"],  # 40Hz: IN1, 100Hz: IN2
                )
        else:
            # if self.data_type == "voltage":
                # self.ax.set(
                    # xlim=[80, 270],
                    # yticks=[lower_ylim, lower_ylim+50],
                # )

            if self.data_type == "calcium":
                # lower_ylim = self.ax.get_ylim()[0]
                # lower_ylim = v[select, self.t0].min()-60
                # self.ax.plot(
                #     [80 + 2, 100 + 2],
                #     [lower_ylim, lower_ylim],
                #     color="black",
                #     linewidth=1,
                # )
                # self.ax.plot(
                #     [80 + 2, 80 + 2],
                #     [lower_ylim, lower_ylim + 500],
                #     color="black",
                #     linewidth=1,
                # )
                # yaxshift = 50

                lower_ylim = 0
                yaxshift = 0
                self.ax.spines["left"].set_bounds(lower_ylim+yaxshift, lower_ylim+1000+yaxshift)
                self.ax.set(
                    yticks=[0, 1000],
                    yticklabels=["0", "1"]  # 40Hz: IN1, 100Hz: IN2
                )

        self.ax.set(xlim=(80, 270))

        # no axis
        # self.ax.axis("off")

        if self.show_legend:
            self.ax.legend()

        if return_data:
            return self.ax, plotted_data
        else:
            return self.ax


def jackhist(data, bins):
    cells = np.unique(data[:, 1])
    n = cells.size
    jackknife_samples = np.empty((n, len(bins) - 1))

    for i, c in enumerate(cells):
        sample = data[data[:, 1] != c, 0]
        hist, _ = np.histogram(sample, bins=bins)
        jackknife_samples[i] = hist

    jackknife_mean = np.mean(jackknife_samples, axis=0)
    jackknife_std = np.std(jackknife_samples, axis=0, ddof=1)  # * np.sqrt(n - 1)

    return gaussian_filter1d(jackknife_mean, sigma=1.5), gaussian_filter1d(
        jackknife_std, sigma=1.5
    )


def fracrate(tspike, tend, wsize=2, window_type="tukey"):
    L = tend + 1

    r = np.zeros(L)
    isi = np.diff(tspike) / 1e3
    ispike = np.round(tspike).astype(int)
    for i in range(ispike.size - 1):
        ibeg = ispike[i]
        iend = ispike[i + 1]
        r[ibeg:iend] = 1 / isi[i]

    win = get_window(window_type, wsize)
    win /= win.sum()
    rx = np.convolve(win, r, mode="valid")

    delta = r.size - rx.size
    d2 = delta // 2 + 1
    r[:d2] = rx[0]
    r[d2 : (rx.size + d2)] = rx
    r[(rx.size + d2) :] = rx[-1]

    return r


def pfracrate(data, tbegin, tend):
    cells = np.unique(data[:, 1])
    n = cells.size
    rate = np.empty((n, tend - tbegin + 1))

    for i, c in enumerate(cells):
        sample = data[data[:, 1] == c, 0] - tbegin
        r = fracrate(sample, tend - tbegin)
        rate[i] = r

    rate_mean = np.mean(rate, axis=0)
    rate_std = np.std(rate, axis=0, ddof=1)  # * np.sqrt(n - 1)

    return rate_mean, rate_std


class SpikePlot(MatPlotLibPlot):
    def __init__(self, filenames=None, ylim=None, binsize=1, tstop=300, **kwargs):
        super().__init__(nrows=2, sharex=True, **kwargs)
        self.filenames = filenames
        self.ylim = ylim
        self.binsize = binsize
        self.tstop = tstop

        self.define_ts_variables()
        plt.subplots_adjust(hspace=0)

    def define_ts_variables(self, tbegin=80, tend=280):
        read_ts = lambda f: pd.read_csv(
            f, header=None, names=["t", "gid"], dtype={"t": float, "gid": int}
        )

        if isinstance(self.filenames, str):
            # single file
            ts = read_ts(self.filename)
            ts["trial"], ts["sync"] = get_trial_sync_from_filenames(self.filenames)
        elif isinstance(self.filenames, list):
            # multiple files in a list
            dfs = []
            for f in self.filenames:
                df = read_ts(f)
                df["trial"], df["sync"] = get_trial_sync_from_filenames(f)
                dfs.append(df)
            ts = pd.concat(dfs)
        else:
            raise ValueError(f"Unsupported filenames type: {type(self.filenames)}")

        # plot only between tbegin and tend
        self.tbegin = tbegin
        self.tend = tend

        ts = ts[ts.t > self.tbegin]
        ts = ts[ts.t < self.tend]

        ts1 = ts[ts.gid < 208]  # IN1
        ts2 = ts[(ts.gid >= 208) & (ts.gid < (208 + 59))]  # IN2
        ts3 = ts[ts.gid >= (21606)]  # CF
        ts3.loc[:, "gid"] = (
            21627 - ts3.gid + (208 + 59 + 10)
        )  # reverse CF id for better visualization

        # annotate cell types
        ts1, ts2, ts3 = ts1.copy(), ts2.copy(), ts3.copy()
        ts1.loc[:, "cell_type"] = "IN1"
        ts2.loc[:, "cell_type"] = "IN2"
        ts3.loc[:, "cell_type"] = "CF"

        self.ts = pd.concat([ts1, ts2, ts3], ignore_index=True)

    def raster_plot(self, trial=1, show_xaxis=False):
        """make raster plot for a given trial"""
        ts = self.ts[self.ts.trial == trial]

        self.ax[0].scatter(
            ts[ts.cell_type == "IN1"].t,
            ts[ts.cell_type == "IN1"].gid,
            0.25,
            color="#ED1C24",
        )
        self.ax[0].scatter(
            ts[ts.cell_type == "IN2"].t,
            ts[ts.cell_type == "IN2"].gid,
            0.25,
            color="#1C75BC",
        )

        cf_gid_min = ts[ts.cell_type == "CF"].gid.min()
        self.ax[0].plot(
            ts[ts.cell_type == "CF"].t,
            (ts[ts.cell_type == "CF"].gid-cf_gid_min)*0+cf_gid_min+20,
            '|', markersize=5,
            color="#FBB040",
        )
        self.ax[0].set_xlim([self.tbegin, self.tend])
        self.ax[0].spines["bottom"].set_visible(show_xaxis)
        self.ax[0].spines["left"].set_visible(False)
        self.ax[0].set(yticks=[])

    def grouped_rate_plot(self, xscalebar=True):
        """plot rates of all the cell types together"""
        tcenter = np.arange(0, self.tstop, self.binsize)
        ts = self.ts[self.ts.cell_type == "IN1"]

        def plot_rate(self, ts, nfactor, color, ax):

            # compute rate histogram for each trial
            hists = np.array(
                [
                    np.histogram(
                        ts[ts.trial == i].t.values,
                        bins=np.arange(0, self.tstop + self.binsize, self.binsize),
                    )[0]
                    for i in ts.trial.unique()
                ]
            )

            # compute mean and sem across trials and smooth them with gaussian filter
            zm = gaussian_filter1d(hists.mean(axis=0), 2) * nfactor
            zsd = (
                gaussian_filter1d(hists.std(axis=0), 2)
                * nfactor
                / np.sqrt(hists.shape[0])
            )
            # zm = hists.mean(axis=0)
            # zsd = hists.std(axis=0)

            ax.plot(tcenter, zm, color=color)
            ax.fill_between(
                tcenter,
                zm + zsd,
                zm - zsd,
                color=color,
                alpha=0.3,
            )

        plot_rate(
            self,
            self.ts[self.ts.cell_type == "IN2"],
            1e3
            / 59
            / 2.5,  # (kHz -> Hz), 59 IN2s, 2.5 scaling down for better visualization
            "#1C75BC",
            self.ax[1],
        )

        plot_rate(
            self,
            self.ts[self.ts.cell_type == "IN1"],
            1e3 / 208,  # (kHz -> Hz), 208 IN1s
            "#ED1C24",
            self.ax[1],
        )

        self.ax[1].spines["left"].set_bounds(0, 40)
        self.ax[1].set(
            xlim=[80, 270],
            yticks=[0, 40],
            yticklabels=["0", ""],  # 40Hz: IN1, 100Hz: IN2
        )
        # self.ax[1].tick_params(axis="y", rotation=90)

        # annotate "100 Hz" in red near the 40 Hz tick

        self.ax[1].annotate(
            "40",
            fontsize=6,
            xy=(0, 40),
            xycoords=self.ax[1].get_yaxis_transform(),
            xytext=(-4, 4),
            textcoords="offset points",
            ha="right",
            va="center",
            color="#ED1C24",
            rotation=0,
        )

        self.ax[1].annotate(
            "100",
            fontsize=6,
            xy=(0, 40),
            xycoords=self.ax[1].get_yaxis_transform(),
            xytext=(-4, -4),
            textcoords="offset points",
            ha="right",
            va="center",
            color="#1C75BC",
            rotation=0,
        )


        if xscalebar:
            self.ax[1].spines["bottom"].set_bounds(80, 100)
            self.ax[1].set(
                xticks=[80, 100],
                xticklabels=["20 ms", ""],
            )

            self.ax[1].xaxis.get_ticklabels()[0].set_ha("left")
        else:
            self.ax[1].spines["bottom"].set_visible(False)
            self.ax[1].set(xticks=[])
            # self.ax[1].set(xticks=[])

        # for spine in self.ax[1].spines.values():
        #     spine.set_linewidth(2)
        # self.ax[1].tick_params(length=0)

        plt.tight_layout()
