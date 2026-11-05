![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg) ![AI Assisted](https://www.aihonestybadge.com/badges/ai-assisted-small.svg)

# IHP CMOS5L SRAM demo

A minimal Tiny Tapeout project that integrates the IHP `RM_IHPSG13_1P_256x16_c2_bm_bist` SRAM macro (256 x 16 bits) on the IHP SG13CMOS5L process.

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

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)

## What next?

- [Submit your design to the next shuttle](https://app.tinytapeout.com/).
- Edit [this README](README.md) and explain your design, how it works, and how to test it.
- Share your project on your social network of choice:
  - LinkedIn [#tinytapeout](https://www.linkedin.com/search/results/content/?keywords=%23tinytapeout) [@TinyTapeout](https://www.linkedin.com/company/100708654/)
  - Mastodon [#tinytapeout](https://chaos.social/tags/tinytapeout) [@matthewvenn](https://chaos.social/@matthewvenn)
  - X (formerly Twitter) [#tinytapeout](https://twitter.com/hashtag/tinytapeout) [@tinytapeout](https://twitter.com/tinytapeout)
  - Bluesky [@tinytapeout.com](https://bsky.app/profile/tinytapeout.com)
