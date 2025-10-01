import os
import subprocess
import numpy as np
import concurrent.futures
from neuron import h
from tqdm.autonotebook import tqdm, trange

### Shape plot class
class MyShapePlot(object):
    def __init__(self, var, ncolors=30, cmap="cividis"):
        from matplotlib import colormaps

        self.ps = h.PlotShape(0)
        self.ps.size(-47.4309, 186.521, -7.27145, 220.471)
        self.ps.view(-47.4309, -7.27145, 233.952, 227.742, 39, 16, 518.4, 504.64)

        self.ps.variable(var)

        # h.fast_flush_list.append(self.ps)
        self.ps.exec_menu("Shape Plot")
        self.ps.exec_menu("Show Diam")
        # h.graphList[0].append(self.ps)

        self.ncolors = ncolors
        self.cm = colormaps[cmap]

        self.rgbs = (self.cm(np.linspace(0, 1, ncolors + 1))[:, :3] * 255).astype(int)

        self.ps.colormap(ncolors + 1)
        for i, rgb in enumerate(self.rgbs):
            self.ps.colormap(i, rgb[0], rgb[1], rgb[2])
        self.ps.scale(0, ncolors)
        self.var = var

    def set_range(self, vmin, vmax):
        self.vmin = vmin
        self.vmax = vmax

    def rescale_data(self, data):
        return (data - self.vmin) / (self.vmax - self.vmin) * self.ncolors

    def set_plot_data(self, data):
        self.data = data
        self.rescaled_data = self.rescale_data(data.data)

    def plot_data_at(self, i):
        for j, seg in enumerate(self.data.segs):
            setattr(seg, self.var, self.rescaled_data[j, i])
        self.ps.flush()
        h.doNotify()

    def save(self, filename):
        self.ps.printfile(filename)

    def save_range(
        self,
        save_path,
        save_range,
        step=1,
        unit="time",
        convert_to_png=False,
        delete_ps=False,
        annotate_time=True,
    ):
        if save_range == "whole":
            ibegin, iend = 0, len(self.data.tvec)
        elif unit == "index":
            ibegin, iend = save_range
        elif unit == "time":
            tbegin, tend = save_range
            ibegin = np.where(self.data.tvec >= tbegin)[0][0]
            iend = np.where(self.data.tvec <= tend)[0][-1] + 1

        ps_filenames = []
        for i in trange(ibegin, iend, step):
            self.plot_data_at(i)
            ps_filename = f"{save_path}/t={self.data.tvec[i]:04.2f}.ps"
            self.save(ps_filename)
            ps_filenames.append(ps_filename)

            if annotate_time:
                time = self.data.tvec[i]
            else:
                time = -1

            if convert_to_png and ps_filenames:
                convert_single_ps_to_png(
                    ps_filenames[-1], time=time, delete_ps=delete_ps
                )


def convert_single_ps_to_png(ps_file, time=-1, delete_ps=False, dpi=100):
    def convert():
        png_file = os.path.join(
            os.path.dirname(ps_file),
            f"{os.path.splitext(os.path.basename(ps_file))[0]}.png",
        )
        width = int(1079 * dpi / 150)
        height = int(1050 * dpi / 150)
        margin = int(0.2 * width)
        new_width = width - 2 * margin
        margin = margin - 100
        if time < 0:
            time_text = ""
        else:
            time_text = f"t = {time:04.2f} ms"
        subprocess.run(
            [
                "magick",
                ps_file,
                "-density",
                f"{dpi}",
                "-crop",
                f"{new_width}x{height}+{margin}+0",
                "-gravity",
                "NorthWest",
                "-pointsize",
                "12",
                "-annotate",
                "+60+10",
                time_text,
                "+repage",
                png_file,
            ]
        )
        if delete_ps:
            os.remove(ps_file)

    with concurrent.futures.ThreadPoolExecutor() as executor:
        future = executor.submit(convert)
        return future


def convert_ps_to_png(directory, delete_ps=False, dpi=100):
    for filename in tqdm(os.listdir(directory)):
        if filename.endswith(".ps"):
            ps_file = os.path.join(directory, filename)
            convert_single_ps_to_png(ps_file, delete_ps, dpi)
