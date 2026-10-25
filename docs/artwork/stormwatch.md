# Slim frame and Stormwatch — 2026-10-25

Version 2.4.0 replaces the tall opaque atlas banner with separate scenery and
perimeter assets. Both were produced with the built-in imagegen tool and
copied unchanged into `src/assets/`; no CLI fallback, resampling, recoloring,
export or manual crop was used. Runtime crop/slicing uses Qt.

## Files and provenance

- `duris-backdrop-stormwatch.png`: RGB, 1983×793, 2,464,268 bytes,
  SHA-256 `9c985b679d1a9b387e866381a7d35ed4487de5fc8ee67d83cd6fb1d02b2cda9e`.
- `duris-frame-slim.png`: RGBA, 1586×992, 531,296 bytes,
  SHA-256 `59980d4e4137bbc54ae970d76fb7f7e70e8e7bd1f78119e0a4a834619e1b5163`. Its central opening is alpha-transparent.
- Reference: [the retired Duris atlas frame](duris-frame.md),
  SHA-256 `a7f12cbc69d3afd4f5e709ebf77f7f809bbeba4b30c3685b53c8616ef417693b`.
  It guided frame materials only; the old opaque asset is removed from the
  package after source/runtime-reference audit. Historic records retain links.

Generated originals are retained in
`C:/Users/apexw/.codex/generated_images/01a1736b-064b-7fe3-8a33-fb4a2030e3bd/`:
`exec-023104dc-03c3-4fd4-bc69-635225167169.png` (scene) and
`exec-506f452b-cdf7-49e0-995a-c52b9e7a1d19.png` (frame).
The scene prompt requested ≥2560px when supported; the actual tool output is
1983px wide. It is not described as a higher-resolution master.

## Scene prompt

```text
Use case: stylized-concept. Asset type: original panoramic landscape bitmap for the exposed background of a dark-fantasy text-game workspace. Generate a wide landscape master at least 2560 pixels wide if supported, ideally 3072x1536 or 3840x1920. Stormwatch: an ancient ruined stronghold with fractured ramparts distributed across the panorama, distant mountain silhouettes, layered static mist and a storm-dark sky. Obsidian charcoal and desaturated slate, weathered bronze accents, sparse dim amber windows, very restrained verdigris. Rich painterly material detail, low overall brightness, broad soft contrast. Spread interest across left, center and right; opaque movable UI panels may cover any region. Composition must survive centered cover cropping for 16:10, 16:9 and ultrawide displays; put no essential focal feature near edges. No people, heroes, faces, text, logos, watermark, border, interface, glowing centerpiece, bright lightning or map. Atmospheric original world illustration, subdued enough to sit behind combat text panels.
```

## Frame prompt

Reference image: `src/assets/duris-v1.png` from base `bdfdbe4` (inspected before generation).

```text
Use case: stylized-concept. Asset type: transparent game UI frame; Input image is the existing Duris frame, used as a material/style reference. Create a separate NEW slim rectangular perimeter with all four rails of equal thin visual weight, matching the reference side/bottom rails. Obsidian iron, worn bronze double bevels, fine navigation engravings, tiny rivets, restrained verdigris in recesses. Landscape rectangle 1600x1000 if possible. Outer rail thickness about 26 pixels and corner joints about 40 pixels at this size. Rails join cleanly at corners without projecting deep into the opening. Entire central opening genuinely alpha transparent, also transparent exterior beyond the frame if any. No central wordmark, DURIS text, letters, plaque, crest, tall header, landscape, interface or background. Straight top rail as thin as bottom, balanced restrained ornament. Designed for native Qt nine-slice borders: keep all corner decoration inside 48 pixels of each outer corner, straight rails elsewhere. Preserve dark richly textured obsidian bronze style and small navigation ornament of the reference, but simplify the top rail radically.
```

## Integration

The actual corner decoration fits within 96px source slices, larger than the
brief's requested 48px. Equal logical destination slices keep the corners
square, with matching rail weight on all four sides. Scenery uses a centered
cover crop in the inner opening, independent of frame dimensions. Its dimness
is baked into the original art; no brightness option or animated layer exists.

Mudlet `getImageSize` decodes assets before using them, so missing and corrupt
files share the same independent fallbacks. [Mudlet UI APIs](https://wiki.mudlet.org/w/Manual:UI_Functions#getImageSize)
and [Qt border-image documentation](https://doc.qt.io/qt-6/stylesheet-reference.html#border-image)
were inspected; actual crop, transparency and input behavior were then checked
in Mudlet. Runtime and visual evidence is recorded in the
[implementation plan](../ongoing-projects/plan-slim-frame-backdrop.md).
