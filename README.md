![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg) ![AI Assisted](https://www.aihonestybadge.com/badges/ai-assisted-small.svg)

# IHP CMOS5L SRAM demo

A minimal Tiny Tapeout project that integrates the IHP `RM_IHPSG13_1P_256x16_c2_bm_bist` SRAM macro (256 x 16 bits) on the IHP SG13CMOS5L process.

**Caveat:** this design has not been proven in silicon yet. Until it has, treat the SRAM power scheme as experimental.

- [How to use the design](docs/info.md)

## How the SRAM is integrated

| File                                                                                           | What it does                                                                                                                                                                 |
| ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [src/project.v](src/project.v)                                                                 | Instantiates the macro (instance `sram`) behind a small command interface.                                                                                                   |
| [src/sram_bb.v](src/sram_bb.v)                                                                 | Blackbox declaration of the macro for synthesis and linting                                                                                                                  |
| [src/config.json](src/config.json)                                                             | Macro placement, power connections                                                                                                                                           |
| [src/pdn_cfg.tcl](src/pdn_cfg.tcl)                                                             | PDN configuration that disables the per-macro grid.                                                                                                                          |
| [librelane_plugin_sram_pdn.py](librelane_plugin_sram_pdn.py), [odb_stripes.py](odb_stripes.py) | The `Project.ExtendPowerStripes` LibreLane step, which powers the macro. Adapted from [Ken Pettit's CMOS5L SRAM design](https://github.com/kdp1965/ihp-um-janestreet-prism). |
| [test/sram_model](test/sram_model)                                                             | IHP's behavioural model of the macro, for RTL and gate level simulation.                                                                                                     |

The macro is 236.8 x 118.78 um, so the project uses a 2x2 tile. It sits at the bottom left, flipped (`FS`) so that its pins, on its bottom edge, face the logic.

### Power

On the SG13CMOS5L tile, the power grid is a single layer of vertical Metal4 stripes (TopMetal1 is reserved for the chip-level grid). The SRAM's power pins (`VDD!`, `VDDARRAY!`, `VSS!`) are also vertical Metal4 columns, so they can only be reached by a stripe running straight over them, and the PDN generator cuts its stripes around macros. Two things make it work:

1. The PDN stripes are matched to the macro's columns: `FP_PDN_VPITCH` 44.96 um (4 x the 11.24 um column pitch), `FP_PDN_VSPACING` 3.52 um (VPWR to VGND 5.62 um, as in the macro), `FP_PDN_VWIDTH` 2.1 um (inside the 2.81 um columns) and `FP_PDN_VOFFSET` 6.15 um. With the macro at x = 3.36 um, the stripes land on its left bit-cell array's columns.
2. `Project.ExtendPowerStripes` runs after `OpenROAD.GeneratePDN` (`meta.substituting_steps` in `src/config.json`). It moves the stripes crossing the macro onto its power columns, completes the VPWR/VGND pairs, and leaves one full-height box per stripe, as the precheck pin check requires. With `EXTEND_STRIPES_SRAM_ARRAY_EVERY_OTHER` it also adds a pair on every other column pair of the two bit-cell arrays, for better power delivery to the macro. In this build it put 11 VPWR and 11 VGND stripes over the macro.

LibreLane loads the step from `librelane_plugin_sram_pdn.py` because it runs from the repository root.

## Using this in your own design

To add the SRAM to your own SG13CMOS5L project (started from the [ttihp-verilog-template](https://github.com/TinyTapeout/ttihp-verilog-template)):

1. Copy `librelane_plugin_sram_pdn.py` and `odb_stripes.py` to the root of your repository, and `src/pdn_cfg.tcl` and `src/sram_bb.v` to your `src` directory. Add `sram_bb.v` to `source_files` in `info.yaml` and to `PROJECT_SOURCES` in `test/Makefile`.
2. Copy the "IHP SRAM macro" section of [src/config.json](src/config.json) (from `meta` to `ERROR_ON_ILLEGAL_OVERLAPS`) and the `FP_PDN_VPITCH`, `FP_PDN_VWIDTH`, `FP_PDN_VSPACING` and `FP_PDN_VOFFSET` values. They match the stripes to the macro's power columns. The stripe width (2.1 um) must fit inside the 2.81 um columns.
3. Instantiate the macro like [src/project.v](src/project.v) does: tie `A_DLY` high, tie off the BIST ports, and drive the macro's inputs from registers. Use the macro's instance name in `MACROS` and `PDN_MACRO_CONNECTIONS`. If the macro is not a direct child of your top module, this is its hierarchical name after flattening (e.g. `core.mem.sram`).
4. Place the macro with orientation `N` or `FS` (the stripe step supports only these two), with its pins facing your logic. Preferably keep x = 3.36 + n x 11.24 um: the PDN stripes then land on the left bit-cell array's power columns, so the stripes over the macro stay on the tile's grid pitch. Any other x works too, as the stripe step moves every stripe crossing the macro onto the nearest free column of its polarity. The step log then reports the stripes it moved, which is expected.
5. For more than one instance of the macro, add each one under `instances` in `MACROS` and give it its own two lines in `PDN_MACRO_CONNECTIONS`. Instances placed side by side each get their own stripes, so step 4 applies to each x. Instances stacked above each other must have the same x, so that their power columns line up: the stripes run the full height of the tile and would otherwise cross the other instance off its columns.
6. For simulation, copy `test/sram_model` and the `SRAM_MODEL` and `COMPILE_ARGS` lines of [test/Makefile](test/Makefile).
7. For another IHP SRAM macro, check its `VDD!` / `VSS!` column positions in its LEF, change the views in `MACROS` and the port list in `src/sram_bb.v`, replace the macro's wrapper in `test/sram_model` with that macro's wrapper from the PDK's `verilog` directory, and pick a tile size that fits it.

After hardening, check that the macro is powered: the `*-project-extendpowerstripes` step log lists the stripes it put on the macro, LVS must match, and the IR drop report (`runs/wokwi/*-openroad-irdropreport/irdrop.rpt`) must say that all shapes on VPWR and VGND are connected.

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)
