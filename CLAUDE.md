# CLAUDE.md

Context and action log for Claude Code sessions in this repo. Read this first
to retrace earlier work.

## Project

ECE 6390 (Satellite Communications) term project, Nov 2026. MATLAB model of a
**900 kg lunar orbiter** that points a body-fixed comms antenna at Earth.

| Path | What it does |
|---|---|
| `path_init.m` | Adds folders to the path and loads NAIF mice + kernels (`data/naif0012.tls`, `data/de440s.bsp`). The mice path is hard-coded to a Windows machine. |
| `load_consts.m` | `consts` struct: physical constants, PD gains `Kp`/`Kd`, s/c `m`, `area` (= m/5, a TODO), `Cr`. |
| `orbprop.m` | `ode45` Moon-centred J2000 propagator: two-body + lunar J2 + Earth/Sun 3rd body + SRP with a cylindrical eclipse. Input in km, km/s; **output `y` in m, m/s**. |
| `ADCS/ePoint.m` | Desired attitude: body `boresight_B` toward Earth, roll referenced to the orbit normal. |
| `ADCS/ePController.m` | PD attitude controller that returns a torque, the attitude-error rotation vector and the desired rate. |
| `ADCS/atSim.m` | Loops over the orbit. Estimates are faked as truth + `randn*0.01`. Boresight is `[0;1;0]`. |
| `thermals/thermSim.m` | Single-node equilibrium temperature: solar, lunar albedo, lunar IR, internal and radiated terms. |
| `plot/plotAll.m` | Lunar globe + orbit, Teq and Qnet plots. |
| `antenna/` | HGA dish radiation pattern + orbit coupling (see `antenna/README.md`). |

Conventions: one function per file, header block (`% name.m`, description,
author, `ECE 6390`, `November 2026`, `%% Inputs`, `%% Outputs`), camelCase
names. `.png/.tif/.mat/.bsp/.asv` are git-ignored.

Tooling on this machine: MATLAB R2026a at `/usr/local/bin/matlab`, with only
the Image Processing and Signal Processing toolboxes. **No** Antenna, Stats or
Aerospace toolbox, so don't use `prctile`, `patternCustom`, etc. **mice is not
installed.** To test SPICE-dependent code, put throw-away `cspice_spkezr` /
`cspice_str2et` stubs in a scratch dir (never in the repo) and add it to the
path.

Run headless: `matlab -batch "addpath('antenna'); antSelfTest"`.

## Known issues found in existing code (not fixed; owners should decide)

1. `ADCS/ePoint.m`: `rEarth` comes from SPICE in **km**, but `rSC` comes from
   `orbprop` in **m**. `rEarth - rSC` mixes units, so the Earth direction is
   wrong. Fix: `rEarth = earthPos(1:3)*1e3`.
2. `thermals/thermSim.m`: `cspice_spkezr('SUN', t(n), ...)` passes sim time,
   not `et0 + t(n)`. `Q_rad` is added instead of subtracted. The flux distance
   uses `norm(rSC)+Rm`, but rSC is already Moon-centred.
3. `ADCS/atSim.m`: `atEst = at_des + randn` is not orthonormal, and
   `omg_B_est` is a 3x3 matrix, so `tau_cmd` comes out 3x3.
4. `path_init.m` adds `power/` and `radiation/`, which don't exist yet (this
   only produces warnings).

## Session log

### 2026-11-19: antenna radiation pattern (branch `bmarty/antenna_sims_personal`)
Request: describe the repo, then build a standard satellite dish radiation
pattern using all s/c variables, with code in `antenna/`, an `antenna/README.md`,
and this file.

Actions:
1. Read all files and the git history. The older `plot/plot_traj.m` and
   `atSim.m` in commit 8c0a004 hold the test trajectory/epoch reused in
   `antMain`.
2. Created `antenna/`: `antParams`, `dishPattern` (PO aperture integration,
   cos^q feed, blockage, spillover, Ruze), `antRefEnvelope` (S.672),
   `antOffBoresight`, `antEarthVisible`, `antPerformance`, `antSummary`,
   `antPlotPattern`, `antPlotPerformance`, `antMain`, `antSelfTest`, `README.md`.
3. Edited `path_init.m`: added `addpath('antenna')`. This is the only change
   outside `antenna/`.
4. Verified: `antSelfTest` passes all checks (Airy limit, power conservation
   0.9986, budget consistency, geometry). The full `antMain` ran with SPICE
   stubs: 24 h, 24,621 samples, ~8 s.
5. Default design: X-band 8.475 GHz, D = 1 m, f/D = 0.4, −11 dB taper.
   Result: 37.7 dBi, HPBW 2.33°, SLL −22.8 dB.
6. Nothing committed.

Possible next steps: run with real mice; fix the ePoint unit bug and re-check
the pointing loss; trade dish size/frequency (`antParams` name/value
overrides); add a Ka-band or S-band case; add a full link budget with data rate
and Eb/N0.
