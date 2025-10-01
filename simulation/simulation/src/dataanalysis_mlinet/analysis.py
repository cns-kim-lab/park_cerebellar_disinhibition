import numpy as np
import pandas as pd
from scipy.signal import find_peaks
from tqdm.autonotebook import trange, tqdm
import matplotlib.pyplot as plt


class PCDataAnalysis:
    def __init__(self, simulation_data_dir, data_label, network_id):
        self.simulation_data_dir = simulation_data_dir
        self.data_label = data_label
        self.network_id = network_id
        self.data_path = (
            f"{self.simulation_data_dir}/{self.data_label}_{self.network_id}"
        )

        self.sync_list = None
        self.cf_scales = None
        self.trial_range = None
        self.spiny = None

    def load_single_somav(self, cf_scale, sync, trial, verbose=False):
        f1 = np.load(
            f"{self.data_path}/pc_cf2_cf_{cf_scale}_pf_12_sync_{sync}_trial_{trial}_somav.npz"
        )
        if verbose:
            print(
                f"Loading {self.data_path}/pc_cf2_cf_{cf_scale}_pf_12_sync_{sync}_trial_{trial}_somav.npz ..."
            )
        return f1

    def load_all_somav(self, cf_scale, sync, trial_range, verbose=False):
        vs = []
        for trial in range(trial_range[0], trial_range[1]):
            f1 = self.load_single_somav(cf_scale, sync, trial, verbose)
            vs.append(f1["data"])
            t1 = f1["t"]

        vs = np.array(vs)

        return vs, t1

    def compute_all_spiketime(
        self, cf_scale, sync, trial_range, threshold=-20, verbose=False
    ):
        vs, t = self.load_all_somav(cf_scale, sync, trial_range, verbose)
        spiketimes = None
        for trial_idx, trial_data in enumerate(vs):
            peaks, _ = find_peaks(trial_data, height=threshold)
            if spiketimes is None:
                spiketimes = np.vstack([t[peaks], peaks * 0 + trial_idx]).T
            else:
                spiketimes = np.vstack(
                    [spiketimes, np.vstack([t[peaks], peaks * 0 + trial_idx]).T]
                )
        return spiketimes

    def compute_cs_stats(self, verbose=False):
        assert self.sync_list is not None, "sync_list is not set"
        assert self.cf_scales is not None, "cf_scales is not set"
        assert self.trial_range is not None, "trial_range is not set"

        def compute_cs_stats_for_each(vs, t1):
            for trial_idx, trial_data in enumerate(vs):
                peaks, _ = find_peaks(trial_data, height=-30)
                peak_times = t1[peaks]

                # Filter peaks between 150-190 ms
                mask = (peak_times > 150) & (peak_times < 190)
                peak_times = peak_times[mask]
                peaks = peaks[mask]

                # peak_heights = trial_data[peaks]

                # Store peak times in a dataframe
                if len(peak_times) > 0:
                    if trial_idx == 0:
                        df = pd.DataFrame(
                            columns=[
                                "trial",
                                "first_peak",
                                "last_peak",
                                "n_peaks",
                                "delta_t",
                                "sync",
                            ],
                        )
                    df.loc[trial_idx] = [
                        trial_idx + 1,
                        peak_times[0],
                        peak_times[-1],
                        len(peak_times),
                        peak_times[-1] - peak_times[0],
                        sync,
                    ]

            return df

        dfs = []
        for cf_scale in self.cf_scales:
            for sync in self.sync_list:
                vs, t1 = self.load_all_somav(cf_scale, sync, self.trial_range, verbose)
                df = compute_cs_stats_for_each(vs, t1)
                df["cf_scale"] = cf_scale
                dfs.append(df)

                plt.close("all")
                _, ax = plt.subplots(figsize=(12, 4))
                _ = ax.plot(t1, vs.T)
                ax.set_xlim([147, 250])
                ax.set_title(
                    f'CF={cf_scale}, CS width={df["delta_t"].mean():.2f}±{df["delta_t"].std():.2f} ms'
                )
                plt.tight_layout()
                plt.savefig(
                    f"{self.data_path}/v_pc_soma_multi_cf_{cf_scale}_pf_12_sync_{sync}_normal_inhibition.pdf"
                )

        cs_stats = pd.concat(dfs, ignore_index=True)
        cs_stats["sync"] = cs_stats["sync"].astype(int)
        cs_stats["trial"] = cs_stats["trial"].astype(int)

        return cs_stats

    def load_single_cai(self, cf_scale, sync, trial):
        f3 = np.load(
            f"{self.data_path}/pc_cf2_cf_{cf_scale}_pf_12_sync_{sync}_trial_{trial}_ca.npz"
        )
        return f3["data"]

    def get_cai_mean(self, cf_scale, sync, trial, on_spiny):

        vx3 = self.load_single_cai(cf_scale, sync, trial)
        if on_spiny:
            assert self.spiny is not None, "spiny is not set"
            return vx3[self.spiny, 7500:9000].mean()
        else:
            return vx3[:, 7500:9000].mean()

    def compute_cai_mean_stats(self, on_spiny=True, cf_scale=-1):
        assert self.sync_list is not None, "sync_list is not set"
        assert self.cf_scales is not None, "cf_scales is not set"
        assert self.trial_range is not None, "trial_range is not set"

        if cf_scale == -1:
            cf_scale = self.cf_scales[0]

        df_ca = pd.DataFrame(columns=["sync", "trial", "cai_mean"])

        for sync in tqdm(self.sync_list):
            for trial in trange(self.trial_range[0], self.trial_range[1]):
                df_ca.loc[len(df_ca)] = [
                    int(sync),
                    trial,
                    self.get_cai_mean(cf_scale, sync, trial, on_spiny) * 1e6,
                ]

        return df_ca

    def get_dspike_spread(self, cf_scale, sync, trial, threshold, on_spiny):

        vx3 = self.load_single_cai(cf_scale, sync, trial)
        if on_spiny:
            assert self.spiny is not None, "spiny is not set"
            count = np.sum(vx3[self.spiny, 7500:9000].max(axis=-1) >= threshold).astype(
                float
            )
        else:
            count = np.sum(vx3[:, 7500:9000].max(axis=-1) >= threshold).astype(float)
        return count

    def compute_dspike_spread(self, threshold=5e-3, cf_scale=-1, on_spiny=True):
        assert self.sync_list is not None, "sync_list is not set"
        assert self.cf_scales is not None, "cf_scales is not set"
        assert self.trial_range is not None, "trial_range is not set"

        if cf_scale == -1:
            cf_scale = self.cf_scales[0]

        df_ca = pd.DataFrame(columns=["sync", "trial", "count"])

        for sync in tqdm(self.sync_list):
            for trial in trange(self.trial_range[0], self.trial_range[1]):
                df_ca.loc[len(df_ca)] = [
                    int(sync),
                    trial,
                    self.get_dspike_spread(cf_scale, sync, trial, threshold, on_spiny),
                ]

        return df_ca
