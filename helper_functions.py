#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""

Helper functions for PAAS analysis

Contains:
    - wavelength2color
    - plot_bg: difference between consequtive bg measurements (from Schnaiter et al.)
    - plot_relative_uncertainty
"""

import numpy as np
import matplotlib.pyplot as plt
import os

def wavelength2color(wavelength, gammaVal=0.8, maxIntensity=1.0, colorSpace='rgb'):
    """
    Convert wavelength (nm) to RGB color with gamma correction.
    Based on Urs Hofmann's MATLAB function.
    """
    def adjust(val, factor):
        return (val * factor) ** gammaVal if val != 0 else 0

    # Initialize RGB
    r = g = b = 0

    # Visible spectrum ranges
    if 380 <= wavelength < 440:
        r = -(wavelength - 440) / (440 - 380)
        g = 0
        b = 1
    elif 440 <= wavelength < 490:
        r = 0
        g = (wavelength - 440) / (490 - 440)
        b = 1
    elif 490 <= wavelength < 510:
        r = 0
        g = 1
        b = -(wavelength - 510) / (510 - 490)
    elif 510 <= wavelength < 580:
        r = (wavelength - 510) / (580 - 510)
        g = 1
        b = 0
    elif 580 <= wavelength < 645:
        r = 1
        g = -(wavelength - 645) / (645 - 580)
        b = 0
    elif 645 <= wavelength < 780:
        r = 1
        g = 0
        b = 0
    else:
        r = g = b = 0

    # Factor for intensity near edges
    if 380 <= wavelength < 420:
        factor = 0.3 + 0.7 * (wavelength - 380) / (420 - 380)
    elif 420 <= wavelength < 700:
        factor = 1
    elif 700 <= wavelength < 780:
        factor = 0.3 + 0.7 * (780 - wavelength) / (780 - 700)
    else:
        factor = 0

    r = adjust(r, factor)
    g = adjust(g, factor)
    b = adjust(b, factor)

    rgb = np.array([r, g, b]) * maxIntensity

    if colorSpace.lower() == 'hsv':
        import matplotlib.colors as mcolors
        rgb = mcolors.rgb_to_hsv(rgb)

    return rgb




def plot_bg(bg_405, bg_473, bg_515, bg_660,
                        rmse_405, rmse_473, rmse_515, rmse_660,
                        wavelengths, analysis_period):

    dfs = [bg_405, bg_473, bg_515, bg_660]
    rmses = [rmse_405, rmse_473, rmse_515, rmse_660]
    positions_y = [0.77, 0.56, 0.35, 0.14]

    fig = plt.figure(figsize=(12, 8))

    for df, rmse, wl, y0 in zip(dfs, rmses, wavelengths, positions_y):

        sigma = rmse * 1e6
        color = wavelength2color(wl, gammaVal=1, maxIntensity=1, colorSpace='rgb')

        # =========================
        # Time Series (left panel)
        # =========================
        ax_ts = fig.add_axes([0.075, y0, 0.68, 0.2])

        ax_ts.plot(df.index, df['diff']*1e6, '.', color=color)

        ax_ts.plot(
            [df.index.min(), df.index.max()],
            [2*sigma, 2*sigma],
            '--k', linewidth=3
        )
        ax_ts.plot(
            [df.index.min(), df.index.max()],
            [-2*sigma, -2*sigma],
            '--k', linewidth=3
        )

        ax_ts.set_xlim(analysis_period)
        ax_ts.set_ylim([-1.99, 1.99])
        ax_ts.set_ylabel(r'b$_{abs}$ [1/Mm]')
        ax_ts.grid(True)
        ax_ts.tick_params(labelsize=12, width=1.5)

        if y0 != 0.14:
            ax_ts.set_xticklabels([])
        else:
            ax_ts.set_xlabel("Time")

        ax_ts.legend([f'{wl} nm'], loc='upper right', fontsize=14)

        # =========================
        # Histogram (right panel)
        # =========================
        ax_hist = fig.add_axes([0.76, y0, 0.2, 0.2])

        data = df['diff'] * 1e6

        # Histogram (horizontal to mimic MATLAB rotation)
        ax_hist.hist(
            data,
            bins=20,
            density=True,
            orientation='horizontal',
            color=color,
            edgecolor='none'
        )
        
        # PDF
        y = np.linspace(-4, 4, 400)
        mu = np.nanmean(data)
        pdf = np.exp(-(y - mu)**2 / (2*sigma**2)) / (sigma*np.sqrt(2*np.pi))
        
        ax_hist.plot(pdf, y, linewidth=2.5, color=color)
        
        ax_hist.set_ylim([-1.99, 1.99])
        ax_hist.set_xlim([0, 3.5])
        
        ax_hist.grid(True)
        ax_hist.tick_params(labelsize=12, width=1.5)
        
        if y0 != 0.14:
            ax_hist.set_xticklabels([])
            ax_hist.set_yticklabels([])
        else:
            ax_hist.set_xlabel("Probability Density")

        ax_hist.legend(['Histogram', 'Normal PDF'],
                       loc='upper right',
                       fontsize=12)

        # =========================
        # Sigma annotation
        # =========================
        fig.text(
            0.85, y0 + 0.03,
            r'$\sigma$ = ' + f'{sigma:.2f} Mm$^{{-1}}$',
            fontsize=14,
            bbox=dict(facecolor='white', edgecolor='black'),
            ha='center',
            va='center'
        )

    plt.show()
    


def plot_relative_uncertainty(rmses, wavelengths, time_av,
                              savefolder='',
                              beta_min=0.05, beta_max=50,
                              thr25=25, thr50=50):
    """
    Publication-ready relative uncertainty plot.

    Parameters
    ----------
    rmses : list or array
        RMSE values (in Mm^-1) corresponding to wavelengths
    wavelengths : list
        Wavelengths in nm
    time_av : float or int
        Averaging time in hours
    beta_min, beta_max : float
        Beta range for x-axis [Mm^-1]
    thr25, thr50 : float
        Relative uncertainty thresholds [%]
    """

    beta_range = np.logspace(np.log10(beta_min),
                             np.log10(beta_max), 1000)

    plt.figure(figsize=(7, 5))

    # Convert sigma to Mm^-1 if needed
    sigmas = []
    for s in rmses:
        sigmas.append(s * 1e6 if s < 1 else s)

    # Plot all wavelengths
    for sigma, wl in zip(sigmas, wavelengths):

        rel = 100 * sigma / beta_range

        color = wavelength2color(
            wl, gammaVal=1, maxIntensity=1, colorSpace='rgb'
        )

        plt.plot(beta_range, rel,
                 linewidth=2.5,
                 color=color,
                 label=f"{wl} nm")
        
        # === Vertical beta thresholds ===
        beta_25 = 100 * sigma / thr25
        beta_50 = 100 * sigma / thr50

        plt.axvline(beta_25, linestyle=":", linewidth=1.8, color=color, alpha=0.8)
        plt.axvline(beta_50, linestyle="--", linewidth=1.8, color=color, alpha=0.8)


    # Threshold lines
    plt.axhline(thr25, linestyle="--", color="k", linewidth=1.5)
    plt.axhline(thr50, linestyle="--", color="k", linewidth=1.5)

    plt.xscale("log")
    plt.xlim(beta_min, beta_max)
    plt.ylim(0, 200)

    plt.xlabel(r"$\beta_{\mathrm{abs}}$ [Mm$^{-1}$]", fontsize=14)
    plt.ylabel("Relative uncertainty [%]", fontsize=14)
    plt.title(f"Relative uncertainty ({time_av} h averaging)", fontsize=14)

    plt.grid(True, which="both", linestyle=":", linewidth=0.8)
    plt.legend(frameon=True, fontsize=11)
    
    # ==========================================================
    # Add textbox for highest sigma wavelength
    # ==========================================================

    idx_max = np.argmax(sigmas)
    sigma_max = sigmas[idx_max]
    wl_max = wavelengths[idx_max]

    beta_25 = 100 * sigma_max / thr25
    beta_50 = 100 * sigma_max / thr50

    textbox = (
        f"{wl_max} nm (highest σ)\n"
        f"σ = {sigma_max:.2f} Mm⁻¹\n"
        f"β @ 25% = {beta_25:.2f} Mm⁻¹\n"
        f"β @ 50% = {beta_50:.2f} Mm⁻¹"
    )

    plt.text(0.97, 0.97, textbox,
             transform=plt.gca().transAxes,
             fontsize=11,
             verticalalignment='top',
             horizontalalignment='right',
             bbox=dict(facecolor='white',
                       edgecolor='black',
                       boxstyle='round'))
    
    if savefolder != '':
    
        os.makedirs(savefolder, exist_ok=True)
    
        filename = f"Relative_uncertainty_{time_av}h_averaging.png"
        filepath = os.path.join(savefolder, filename)
    
        plt.savefig(
            filepath,
            dpi=300,
            bbox_inches='tight'
        )