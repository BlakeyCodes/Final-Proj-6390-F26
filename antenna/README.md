# antenna/ — Spacecraft High-Gain Antenna (HGA) Radiation Pattern

This folder models the lunar orbiter's **Earth-pointing high-gain antenna** as a
standard **prime-focus parabolic dish**. It computes the dish's far-field
radiation pattern from first principles. It then uses the team's orbit, ADCS and
thermal models to evaluate that pattern along the orbit: gain toward Earth,
EIRP and C/N0.

## Quick start

```matlab
path_init                 % from repo root: loads mice + SPICE kernels, adds folders
antSelfTest               % verification checks (no SPICE needed)
antMain                   % design -> pattern -> orbit/ADCS/thermal coupling -> plots
```

Without mice/SPICE on the path, `antMain` still computes and plots the
stand-alone pattern and skips the orbit-coupled part with a warning.

To try a different design, change the `antParams` call in `antMain.m`. Any
parameter can be overridden by name/value:

```matlab
ant = antParams(consts,'freq_Hz',26e9,'D_m',0.75);   % Ka-band, 0.75 m (LRO-like)
pat = dishPattern(ant);
antSummary(ant,pat,consts); antPlotPattern(ant,pat,consts);
```

## Files

| File | Type | Purpose |
|---|---|---|
| `antMain.m` | script | Driver. Builds the antenna and pattern, propagates the orbit (`orbprop`), runs `atSim` and `thermSim`, then calls `antPerformance`, the summary and the plots. |
| `antParams.m` | function | All antenna design inputs (with defaults) plus derived quantities: λ, focal length, rim angle, feed exponent q, ideal gain, Ruze loss, mass/area/SRP checks against `load_consts`. |
| `dishPattern.m` | function | Physical-optics aperture integration giving G(θ) in dBi, with peak gain, HPBW, FNBW, sidelobe level, F/B and the efficiency breakdown. Returns `pat.gain_dBi(theta_deg)` for interpolation. |
| `antPerformance.m` | function | Time series along the orbit: Earth range and angular size, Moon occultation, ADCS mispointing, thermal surface distortion, gain to Earth centre and limb, EIRP, FSPL, PFD, Prx, C/N0. |
| `antOffBoresight.m` | function | Converts ADCS attitude-error rotation vectors (`atErrHist`) into a boresight pointing-error angle. |
| `antEarthVisible.m` | function | Checks whether the Moon blocks the line of sight from the s/c to the Earth. |
| `antRefEnvelope.m` | function | ITU-R S.672-style satellite antenna reference envelope, overlaid on the pattern for comparison. |
| `antSummary.m` | function | Prints the design, pattern metrics, efficiency budget, s/c checks and orbit statistics. |
| `antPlotPattern.m` | function | Four figures: full gain cut with envelope, main beam with the Earth disk and mispointing band, polar plot, 3-D pattern in the s/c body frame. |
| `antPlotPerformance.m` | function | Stacked time-series plots of the `antPerformance` outputs. |
| `antSelfTest.m` | function | Checks against closed-form results (see Verification). |

## Model

### Geometry

A prime-focus paraboloid with diameter D and focal length f = (f/D)·D. Its rim
half-angle seen from the focus is ψ₀ = 2·atan(1/(4·f/D)). The feed has a
rotationally symmetric field pattern E_f(ψ) = cos^q(ψ) for ψ ≤ 90°. q is solved
so that the **total** rim illumination (feed taper × space attenuation
(1+cos ψ₀)/2) equals `edgeTaper_dB`.

### Aperture field and pattern

A point at feed angle ψ maps to aperture radius ρ = 2f·tan(ψ/2). The aperture
field there is

E_a(ρ) = cos^q(ψ) · (1+cos ψ)/2

The rotationally symmetric radiation integral is a Hankel transform:

I(θ) = 2π ∫₀^a E_a(ρ) J₀(kρ sin θ) ρ dρ
D(θ) = (4π/λ²) |I(θ)|² / ∫∫|E_a|² dA · ((1+cos θ)/2)²

The field inside the blockage diameter `Dblock_m` is set to zero in I(θ) but
kept in the power normalisation. Blockage loss and the raised sidelobes it
causes are therefore both captured.

Gain = D(θ) · η_spill · η_Ruze · η_misc. Two terms are added on top:
* **Spillover lobe:** feed power past the rim (ψ₀ < ψ ≤ 90°) radiates directly
  toward θ = 180° − ψ.
* **Back region (θ > 90°):** the aperture model does not apply here, so the
  gain is the larger of the spillover lobe and `backFloor_dBi` (−10 dBi, the
  ITU-R S.465 far-sidelobe level).

### Efficiencies (default design)

| Term | Formula | Value |
|---|---|---|
| Taper | \|∫E_a dA\|² / (A ∫\|E_a\|² dA) | 0.886 |
| Spillover | 1 − cos^(2q+1) ψ₀ | 0.933 |
| Blockage | \|I_blocked(0)\|² / \|I(0)\|² | 0.965 |
| Ruze | exp(−(4πε/λ)²), ε = 0.25 mm | 0.992 |
| Misc | ohmic, mismatch, polarisation, phase (assumed) | 0.95 |
| **Total** | | **0.752 (−1.24 dB)** |

### Coupling to the rest of the spacecraft model

* **Pointing (ADCS):** `atSim` returns `atErrHist`, the rotation vector of
  C_err = C_est'·C_des. `antOffBoresight` rotates the boresight by that vector
  and measures the off-axis angle. Roll about the boresight gives zero loss.
  The **commanded** attitude is assumed to point the boresight at Earth (that is
  `ePoint`'s job), so Earth sits at θ = mispointing angle.
* **Earth geometry:** SPICE gives the Earth position (km → m). From it we get
  the range, the Earth angular radius asin(Re/R) ≈ 0.95°, and Moon occultation
  using `consts.Rm`. Link outputs are `NaN` while Earth is hidden.
* **Thermal:** `thermSim` returns `Teq`. The thermal surface error is
  ε_th = κ·CTE·|Teq − Tref|·D. It is root-sum-squared with the manufacturing RMS
  error, and the resulting Ruze loss is applied relative to nominal.
* **Link:** EIRP = Ptx − L_line + G. Then FSPL = 20·log10(4πR/λ),
  PFD = EIRP − 10·log10(4πR²), Prx = EIRP − FSPL + G_rx and
  C/N0 = Prx − 10·log10(k·Tsys).

## How each spacecraft variable in the repo is used

| Variable (source) | Used for |
|---|---|
| `consts.c` (load_consts) | Wavelength λ = c/f, and everything that depends on it |
| `consts.m` | Dish mass fraction check |
| `consts.area` | Dish aperture area fraction of the s/c area |
| `consts.P0`, `consts.Cr` | SRP force on the dish aperture (same model as `orbprop`) |
| `consts.Re` | Earth angular radius seen from the s/c, and gain at the Earth limb |
| `consts.Rm` | Moon occultation of the Earth link |
| `consts.muM`, `J2m`, `muE`, `muSun`, `AU`, `P0`, `Cr`, `area`, `m` | Indirectly, through `orbprop` (s/c position, and so range and occultation) |
| `consts.Kp`, `consts.Kd` | Indirectly, through `atSim`/`ePController` (pointing error) |
| `consts.sigma`, `Gs`, `alpha_m`, `Rm`, `area` | Indirectly, through `thermSim` (Teq, and so thermal distortion) |
| `boresight_B = [0;1;0]` (atSim) | Antenna axis in the body frame (`ant.boresight_B`), also used for the 3-D plot |
| `T_des = 293 K` (thermSim) | Reference temperature at which the surface is figured (`ant.Tref_K`) |
| `r0, v0, epoch` (earlier team scripts) | Test trajectory in `antMain` |
| `consts.muE`, `muSun`, `h`, `J2m` | Not used directly by the antenna (no RF meaning) |

## Default design and results

8.475 GHz (X-band, 8450–8500 MHz lunar space-research band), D = 1.0 m,
f/D = 0.4, −11 dB edge taper, 10 cm blockage, 0.25 mm RMS CFRP surface.

| Metric | Value |
|---|---|
| Peak gain | 37.73 dBi (ideal 38.97 dBi) |
| HPBW | 2.33° (≈ 66 λ/D) |
| First-null BW | 5.88° |
| First sidelobe | −22.8 dB at 3.7° |
| Earth angular radius from LLO | 0.95° (HPBW/2 leaves 0.21° margin) |
| Dish mass | ≈ 3.6 kg (0.4 % of 900 kg) |

Things to note:
* The beam is sized to cover the **whole Earth disk** from lunar distance. The
  gain at the Earth limb, at perfect pointing, is ≈ 2.0 dB below peak.
* The 10 cm blockage lifts the first sidelobe to −22.8 dB, slightly above the
  S.672 −25 dB envelope. A smaller feed/strut footprint or an offset-fed dish
  would fix this.
* In a 24 h run with the current **placeholder** ADCS noise in `atSim`
  (`randn*0.01` added to the DCM), mispointing averages 0.5° and reaches 1.8°.
  That costs up to ~7 dB toward Earth centre and makes pointing the dominant
  loss. Thermal distortion is negligible at X-band (< 0.001 dB for ΔT ≈ 145 K
  with CFRP).
* From the 1937 km test orbit, the Moon blocks Earth for about 30 % of each
  orbit.

## Assumptions and limitations

* Rotationally symmetric feed: no E/H-plane asymmetry and no cross-polarisation.
* Ruze surface scatter is treated as a pure gain loss; the scattered power is
  not redistributed into the sidelobes.
* Strut scattering and rim diffraction are not modelled. Behind the aperture
  plane a constant floor is used.
* The dish is body-fixed (no gimbal), so pointing equals the s/c attitude.
* Link parameters (`Ptx_W`, `Lline_dB`, `Grx_dBi`, `Tsys_K`) are typical
  34 m-class ground station values and can be overridden in `antParams`.

## Verification (`antSelfTest`)

1. Near-uniform aperture reproduces the Airy pattern: HPBW = 1.029 λ/D (error
   < 0.2 %), first sidelobe −17.60 dB, taper efficiency 1.000.
2. The default −11 dB taper gives HPBW ≈ 66 λ/D, sidelobes in −22…−32 dB, and
   taper × spill = 0.827.
3. Peak gain equals ideal gain plus the efficiency budget to within 0.01 dB.
4. Power conservation: for a lossless dish, ∫G dΩ / 4π = 0.9986.
5. Pointing geometry: tilts give the right angle and roll gives zero.
6. Moon occultation: near side, far side and limb cases.
7. The reference envelope is continuous.

The full `antMain` pipeline was also run end to end, with stand-in `cspice_*`
functions approximating circular Earth/Sun ephemerides, because mice was not
installed on the test machine. Run it with real mice and kernels for the actual
numbers.
