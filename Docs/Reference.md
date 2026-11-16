# AssetsAgent reference

How the `assets` agent is found, what a call takes and answers, the lines it reads, the sets it makes, how they are
drawn, and how to test it. What it is for is in the [README](../README.md); the agent standard it follows is Granite's
[granite-agent/1](https://github.com/riteshpakala/Granite/blob/main/Schema/GraniteAgent.md).

## How an app finds it

AssetsAgent is a `GraniteAgentPackage`, and it carries a record in its binary:

```swift
@used @section("__DATA_CONST,__granite")
let assetsRecord: GraniteRoster.Record = { GraniteRoster.record(AssetsAgent.self) }
```

In [Craft](https://github.com/riteshpakala/Craft), install it from the Agent Store or with
`craft agents add https://github.com/rao-craft/AssetsAgent.git`, then say `$assets` in a request:

```
$assets brand the recipe app Simmer: its S in Didot on a warm orange gradient, a cream paper colour
and a herb green, and a whisk symbol
```

The model writes the call; it shows on Craft's agent map as `assets-1`, and the catalog it names is built with the turn.

## What a call takes and answers

| Field | | |
|---|---|---|
| `into` | optional | the asset catalog, relative to the project; `Shared/Assets.xcassets` when left out |
| `name` | optional | the app's name: the monogram's initials and the wordmark; the Xcode project's name when left out |
| `mark` | optional | `monogram` (the default), `shape`, `image` or `medallion` |
| `letters` | optional | the monogram's one to three letters; the name's initials when left out |
| `shape` | optional | `ring`, `knot`, `wave`, `spark`, `stack`, `leaf`, `bubble` or `grid` |
| `image` | optional | a PNG, JPEG, PDF or SVG in the project; a square opaque PNG is the whole icon |
| `metal` | optional | the medallion's metal: `silver` (the default), `bronze`, `gold`, or a hex colour for its middle tone |
| `backing` | optional | what the medallion is set in: a hex colour for its stone, or `none` (the dish is the image's edge); a light stone grey when left out |
| `motif` | optional | the medallion's engraved band: `swirls` (the default) or `plain` |
| `seed` | optional | a whole number, 0 or more, for the medallion's grain; the same seed draws the same pixels; 0 when left out |
| `background` | optional | the icon's ground as hex: one colour (solid) or two or three (a gradient); picked from the name when left out |
| `foreground` | optional | the mark's colour; white or ink, by contrast, when left out |
| `palette` | optional | one colour set a line (below) |
| `contrast` | optional | whether every colour set also gets high-contrast colours |
| `font` | optional | a bundled macOS family or face: Avenir Next (the default), Futura, Georgia, Didot, Gill Sans, Menlo… |
| `wordmark` | optional | the wordmark's text; the name when left out |
| `sets` | optional | `icon`, `accent`, `colors`, `logos`, `launch`, `placeholders`, `empty`, `symbols`, `data`; all but symbols and data when left out |
| `symbols` | optional | one custom symbol a line (below) |
| `data` | optional | one data set a line: `pantry: Resources/pantry.json` |
| `platforms` | optional | `ios`, `macos`, `watchos`, `visionos`; iOS and macOS when left out |
| `view` | optional | the mark as a SwiftUI view, by its type's name: `SeerMark` |
| `viewInto` | optional | the folder for the view's file, relative to the project; `Shared/Design` when left out |
| `directory` | the host's | the folder the host works in; a host fills it and does not show it to a model |

Any of `metal`, `backing`, `motif` or `seed` makes the mark a medallion when `mark` is left out; with another mark they
are refused. Every field, with its note, is in [Schema/assets.input.schema.json](../Schema/assets.input.schema.json);
[Schema/examples/seer.json](../Schema/examples/seer.json) is the Seer call:

```json
{"name": "Seer", "mark": "medallion", "metal": "silver", "view": "SeerMark",
 "background": ["#2A2622", "#4A4038"], "palette": ["accent: #AE9060"], "platforms": ["ios", "macos"], "seed": 7}
```

The answer is an `AssetsResult`: every file written (`path`, the largest icon; `paths`, all of them, absolute, the
view's file last), the catalog, the sets by the names code uses, and a sentence for anything the project still needs
(an app target that names no icon, a launch screen that does not name the launch logo, a view with no `LogoMark` to
draw).

## The lines

```
palette:  paper: #FFF8F0/#1C1714          light, then dark
          ink: #1D1B19                    the same in both
          danger: #D93A2B/#FF6B5E/#A3180D/#FFA39A   light, dark, then each in high contrast
          accent: #E8590C/#FF8A4C         the app's tint: the AccentColor set
          LaunchBackground: #FFF8F0/#1C1714   the launch screen's colour
symbols:  whisk: M30 90 L50 40 L70 90 M50 40 L50 10
          pin.fill: M50 94 C50 94 18 62 18 40 A32 32 0 0 1 82 40 C82 62 50 94 50 94 Z M50 28 A12 12 0 1 0 50.01 28 Z
data:     pantry: Resources/pantry.json
```

- A symbol is SVG path data in a 0…100 box, y down: every command, absolute and relative, arcs included. The path is
  the symbol's centre line, stroked at Ultralight, Regular and Black; a name ending `.fill` (or `fill` before the
  colon) fills it, holes and all.
- Two names Xcode's asset symbols would make the same (`paper` and `paperColor`, `pin.fill` and `pinFill`) are refused,
  so the app's build never warns; a palette line named `accent` is the AccentColor itself.
- Every line, value and font that cannot be honoured is refused with its reason, all at once, and nothing is written.

## What it makes

| Set | What |
|---|---|
| `AppIcon` | iOS: one 1024 square in its any, dark and tinted looks. macOS: the rounded square on Apple's grid (824 of 1024, continuous corners, shadow) at all ten sizes, each drawn at its size, 16 and 32 pixels from a simpler cut. watchOS: one 1024 square (its own `WatchAppIcon` beside Mac sizes). visionOS: `AppIcon.solidimagestack`, front, middle and back layers |
| `AccentColor` and a set a palette line | sRGB, light and dark, high contrast when asked |
| `Logo`, `LogoMark`, `Wordmark`, `Lockup` | vector PDFs: the badge, the mark alone as a template, the name outlined in the brand's face, badge and name; light and dark |
| `LaunchLogo` | the icon's rounded square, light and dark |
| `Logo`, `LogoMark`, `LaunchLogo` for a medallion | the medallion itself: PNGs at 1x, 2x and 3x (128, 128 and 120 points), each drawn at its size, rendered as drawn; `Wordmark` and `Lockup` stay PDFs, the lockup with the medallion beside the name |
| `Placeholder/Avatar`, `Placeholder/Avatar1…4` | a neutral avatar, light and dark, and four sample avatars for previews and seed data |
| `Empty/Inbox`, `Empty/Search`, `Empty/Offline`, `Empty/Error` | empty-state illustrations, light and dark |
| `<name>.symbolset` | an SF Symbols template (v3) a symbol line: `Image("whisk")` at every weight and scale |
| `<name>.dataset` | the file, with its uniform type |

Code reads them as `Image("Logo")`, `Image(.logo)`, `Image("Placeholder/Avatar")`, `Color("paper")`, `Color.accentColor`,
`Image("whisk")`, `NSDataAsset(name: "pantry")`.

With `view`, one Swift file lands beside the catalog, `Shared/Design/SeerMark.swift` unless `viewInto` names another
folder:

```swift
import SwiftUI

/// The app's mark: the LogoMark image from the asset catalog, scaled to fit whatever frame it is given.
struct SeerMark: View {
    var body: some View {
        Image("LogoMark")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}
```

It fills whatever frame it is given (`SeerMark().frame(width: 100, height: 100)`) and adds no size, shadow or rotation of
its own. It compiles for iOS and macOS in Swift 5 and Swift 6. The file is parsed before it lands, and it lands with the
catalog: a call whose catalog does not compile writes neither. The type's name is a capital letter then letters, digits
and underscores, and never `View`, `Image`, `App` or `Scene`; a later call with only `view` writes the view and draws
nothing again.

## The medallion

`mark: medallion` draws a struck-metal medallion set in stone, pixel by pixel, in layers measured off a reference
medallion at 512 pixels (radii as a share of the backing's):

| Layer | Radius | What |
|---|---|---|
| Dome | 0 to 0.25 | a brushed cap, its highlight a band across the top, its foot dark |
| Bevel | 0.25 to 0.28 | the dark reflection band round the dome, lit again at the bottom |
| Polished rings | 0.28 to 0.48 | a bright ring, a dark groove, a thin bright lip, the groove before the dish |
| Dish | 0.48 to 0.82 | brushed silver shaded like a shallow bowl, bright at the top, its rim at 0.82 |
| Engraved band | 0.59 to 0.71 | raised strokes swirling round four eyes on the diagonals, each turning the other way from its neighbours: S-curls with a fan between each pair, lit from the top (the upper side of a stroke bright, the lower in shadow) |
| Stone | 0.82 to 1 | a light stone grey, mottled, lit a little from the right, in the dish's shadow at its inner edge |

- Each ring's lightness (CIE L*) is measured every 30° from the top round to the bottom and eased between; the metal is
  brushed in fine vertical streaks. The rings and textures add up a lightness, and the metal's ramp gives it its
  colour: gold and bronze are silver's light in their tone, a hex `metal` is the tone the metal shows half lit, and a hex
  `backing` is the stone's light in that colour.
- Every grain (the brushing, the stone's mottling, the engraving's wobble) comes from `seed`: the same call draws the
  same bytes, and another seed another grain.
- Every size is drawn at its own pixels: a ring's edges blend over one pixel, and a texture or the engraving's relief
  fades out where it would fall under a pixel or two. Outside the backing (or the dish, with `backing: none`) the image
  is clear.
- On the icon the medallion takes 76% of the brand's ground (the call's `background`), with the icon's soft shadow.
- Its parity with the reference, inside the backing's circle: mean ΔE76 2.40 over a 16 × 16 grid in CIELAB, SSIM 0.595
  in grey at 256 pixels (seed 7). The swirls follow the reference's layout and light, not its hand-cut strokes.

## How the assets are made

| Step | What |
|---|---|
| Read | every field and line checked; a call that cannot be honoured names every reason |
| Colour | the brand's tones in OKLCH from what the call gives: the dark looks keep the brand's hue, the accent is moved until it reads on white and on black |
| Draw | the mark (letters outlined from the font, a glyph built from circles and strokes, the picture, or the medallion drawn pixel by pixel) on the brand's ground; PNGs for icons and the medallion, vector PDFs for everything else |
| Write | every set staged with the `Contents.json` Xcode 27 writes, byte for byte |
| Check | the staged catalog compiled by actool for every platform asked for; an error writes nothing |
| Land | the mark's view, then each set swapped in whole for the one of its name; every other set in the catalog is left alone |

Apple's SF Pro, SF Symbols and New York never appear in an icon or a logo: their licence keeps them out. A letter the
chosen face lacks is refused rather than set by macOS in another font.

## Testing

```
swift test                    # the record, the schema, the lines, every Contents.json, the pixels, the medallion and
                              # the view, actool for iOS, macOS, watchOS and visionOS, what the compiled catalog loads,
                              # running again, and the bytes every existing kind of call writes
ASSETS_BUILD=1 swift test     # the catalog in a two-platform app: xcodebuild for macOS and the iOS Simulator with no
                              # asset warning, and the Mac app run to report what it finds in its own bundle; the Seer
                              # call's medallion and SeerMark built the same way in Swift 5 and in Swift 6
ASSETS_WRITE_SCHEMA=1 swift test   # writes Schema/assets.input.schema.json again from the package
```

`Tests/Golden/existing-calls.json` pins the SHA-256 of every file each existing kind of call writes (a PDF's dates and
document ID masked): a change that adds a mark or a field proves there that it moved nothing. `ASSETS_WRITE_GOLDEN=1`
records them again, only on the commit before a change or when a new macOS moves the bytes.
