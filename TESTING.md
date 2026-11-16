# Testing AssetsAgent

How `assets` is tested: its own suite, its gated build of real output, and prompts run through
[Craft](https://github.com/riteshpakala/Craft) on a Mac with Craft's own local model, each logged below verbatim with
what came out. A prompt is run as a person would type it, in a project folder, with `$` naming the agent; nothing is
edited between the prompt and the screenshots. A test that needs a server uses mock backend responses, never a live
service.

## The suite

```
swift test                                  # the record, the schema, the lines, the files, a call through the roster
ASSETS_BUILD=1 swift test --filter AssetsBuildTests   # the output built for real (gated, minutes)
ASSETS_WRITE_SCHEMA=1 swift test            # writes Schema/assets.input.schema.json again from the package
```

- **`ExistingCallsTests`:** every kind of call made before the medallion (each mark, every glyph, a picture of each
  format, a whole icon, every set and platform, another catalog, a later palette call) writes the same bytes as
  `Tests/Golden/existing-calls.json` pins, file by file, with the same sets, notes and first path. `ASSETS_WRITE_GOLDEN=1`
  records it again, only on the commit before a change or when a new macOS moves the bytes.
- **`MedallionTests`:** the medallion clear outside its backing, its dome, bevel and dish lit where the reference is
  lit; the same seed the same bytes and another seed another grain; each metal, a hex metal, a stone of a colour and
  none, swirls and plain; its values read and naming the mark; every value it cannot honour refused at once with
  nothing written; `Logo`, `LogoMark` and `LaunchLogo` as PNGs at 1x, 2x and 3x; the icon's medallion on the brand's
  ground down to 16 pixels; the view's one file, in its folder, named in the answer, and a later call with only the
  view; the Seer call whole.
- **`AssetsAgentTests`:** the record, the schema a model is shown, the schema file, the example calls, the guide's
  calls, and calls through the roster.
- **`AssetsBuildTests` (gated):** the recipe call in a two-platform app built for macOS and the iOS Simulator; and the
  Seer call (`Schema/examples/seer.json`) in an app whose screen shows `SeerMark()` at 100 and 96 points, built for
  macOS and `generic/platform=iOS Simulator` in Swift 5 and in Swift 6 (iOS 26, macOS 26), with no warning from the
  view or the catalog, and its Mac app run to report the medallion in its bundle. No simulator is booted.

## Prompts run on this Mac

Setup: MacBook Pro M4 Max (128 GB), macOS 27, Xcode 27.1, Craft built from `main`, the model Craft loads
(`rao-studios/Qwen3-Coder-Next-REAP-48B-A3B-mlx-4bit`), permission mode bypass, the agent installed from this repository
with `craft agents add`.

## Conformance on Hearth

Level 1 of the regime: the call a model should write, sent straight to the installed runner over its wire
(granite-agent/1) with no model, on a copy of Hearth as the journey left it (services, mock data and loom's views
made), then checked by building, testing and screenshotting the app. A pass here means the agent can produce the
result deterministically; whether Craft's model writes this call is tested by the prompts above.

## The medallion beside the reference

The medallion's tones were measured off the original Seer app's raster logo (a photoreal silver medallion, 512 × 512)
ring by ring; the logo itself is not in this repository. The Seer call's medallion (seed 7), drawn at 512 pixels, is
compared with it inside the backing's circle:

- **Colour:** each cell of a 16 × 16 grid averaged in sRGB, taken to CIELAB and compared: mean ΔE76 **2.40** (the bar
  is 6; 90th percentile 4.86).
- **Structure:** both in grey at 256 pixels, SSIM **0.595** (the bar is 0.55).
- **By eye at 300 pixels** (the mark at 100 points on a 3x screen): the same object, a brushed dome in polished rings
  inside a dish of swirls on stone, lit from the top. The swirls follow the reference's layout and light, not its
  hand-cut strokes; the stone is a little smoother.

## Changes

### 2026-11-15: the medallion, and the mark as a view

- **`mark: medallion`:** a struck-metal medallion drawn pixel by pixel (`MedallionPainter`), its rings measured off
  the reference; `metal` (silver, bronze, gold or hex), `backing` (hex or none), `motif` (swirls or plain) and `seed`
  each read and refused in a sentence. It is `Logo`, `LogoMark` and `LaunchLogo` as PNGs at 1x, 2x and 3x, sits on the
  icon's ground, and stands beside the name in the lockup.
- **`view` and `viewInto`:** the mark as a SwiftUI view, one file (`Shared/Design/SeerMark.swift` by default) drawing
  `Image("LogoMark")` to fit its frame, landed with the catalog and named in the answer.
- **Additive:** `ExistingCallsTests` pins the bytes of every existing kind of call, recorded before the change; they
  are unchanged.
- **Schema:** `Schema/assets.input.schema.json` (new, pinned to the package) and `Schema/examples/seer.json`.

