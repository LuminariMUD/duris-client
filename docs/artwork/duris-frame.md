# Duris atlas frame

The production asset is `src/assets/duris-v1.png`; the stable filename preserves
existing package asset references. It replaces the original “New Duris” border.
Generated on 2026-10-15 using the built-in imagegen tool, with one targeted
refinement to fit the header above the existing GUI panels. No CLI fallback or
programmatic image editing was used. The final generated PNG was copied into
the source assets unchanged.

Art direction: obsidian iron, worn bronze atlas engravings, a compass clasp,
a single DURIS wordmark, narrow perimeter rails, and a black interior. The
existing percentage-based GUI layout remains unchanged.

Final generated source:
`/home/staging/.codex/generated_images/01a13f95-6ad2-7e61-9962-fa429dea00c4/exec-5e0e6a47-bcb7-442b-a95c-e4575b0aa897.png`

## Validation

The delivered PNG is 1586×992, SHA-256
`a7f12cbc69d3afd4f5e709ebf77f7f809bbeba4b30c3685b53c8616ef417693b`.
Package 1.3.5 was built with Lua 5.1 syntax and XML validation. All 19 offline
suite expectations passed in real Mudlet 5.0.1, plus three size/scaling runs.
Screenshots and Errors views were reviewed at 1280×720, 1366×768, 1920×1080,
and 2732×1536 at scale 2. The wordmark remains visible above the panels; the
frame loads after reinstall/profile reopen and the primary feed stays black.

Evidence is retained outside the checkout under
`/home/staging/.local/share/duris-client-dev/runs/atlas-frame-1.3.5` and
`atlas-frame-sizes-1.3.5`. The former's `candidate-comparison.json` verifies
that all 22 suite/matrix candidates have the same payload as the root archive.
Root package SHA-256:
`fa667cf100cfacf351b5a93441f92baa83f7ed273817050c9c428cd73f53e30b`.
These were offline Xvfb checks; Mudlet 4.19.1 and physical desktop DPI were
not tested. The asset change requires no server integration change.

## Initial generation prompt

```text
Use case: stylized-concept
Asset type: Production-ready raster background frame for the Duris desktop MUD game client. This is the actual border artwork asset, not a screenshot or UI mockup.
Primary request: Completely reimagine an old fantasy border as a unique, sophisticated relic: an ancient world-atlas binding forged from obsidian-black iron and weathered bronze. Make it beautifully crafted, atmospheric, confident, and unmistakably dark fantasy.
Canvas: Landscape, 2048 x 1280 pixels, approximately 16:10. Flat straight-on orthographic artwork filling the entire canvas, sharp detailed relief, no perspective, no outer margins.
Composition is a strict functional requirement: all ornament is confined to the top 10% band, outermost 2.5% of the left and right edges, and bottom 2.8%. The enormous uninterrupted inner rectangle from x=2.5% to 97.5% and y=10.5% to 97.2% is uniform pure black (#000000). Nothing protrudes into this usable inner rectangle. No internal dividers or UI panels. Top corners can be richer but stay above y=10%.
Design: A narrow double-beveled black iron perimeter, fine hand-cut aged-bronze inlay, angular thornlike metal joinery, tiny rivets and engraved geometric navigation details. The top band forms a low, elegant ceremonial atlas clasp. Center the wordmark in that band, flanked by subtly asymmetric engraved compass arcs and topographic linework that fade toward the sides. A small broken-ring compass seal belongs ABOVE the wordmark within the top band, integrated into the metalwork. Thin lower and side rails have purposeful little engraved wayfinding marks, not readable letters. Corners feel forged and structurally joined, not pasted ornaments. Aim for a cohesive original game identity with material depth and precise craftsmanship.
Materials/color: predominantly near-black charcoal/obsidian, muted antique bronze and worn warm silver lettering, extremely subtle aged verdigris in recesses. Small restrained ember highlights only within the top corner fittings; no bright orange glow surrounding the whole frame. The engraved surfaces are dark enough for long play sessions. The center must stay perfectly solid black without textures, smoke, grain, vignettes, gradients, illumination or scenery.
Text (verbatim): "DURIS" -- exactly D U R I S, only once, clearly legible, centered horizontally, chiseled elegant fantasy serif capitals in warm pale silver with subtle bronze bevel. Lettering occupies about x=42% to 58%, y=4.5% to 8.5%; it must be fully inside the top band with breathing room. No "New", no subtitles, no tagline, no other text anywhere.
Lighting/mood: low-key handcrafted dark-fantasy artifact, subtle grazing light bringing out engraving, rich controlled contrast, polished game UI art, not glossy plastic.
Constraints: one continuous outer frame, unbroken pure-black central space, no transparent background, no characters, faces, skulls, weapons, giant jewels, pentagrams, HUD elements, buttons, sample text, faux screenshot, watermarks or additional logos. Make the design visually distinctive through its engraved atlas/compass identity and exquisite metalwork. Respect the very slim side and bottom borders.
```

## Final refinement prompt

Input: the initial generated frame, not the old border artwork.

```text
Use case: precise-object-edit
Asset type: Production border artwork for the Duris Mudlet client.
Input image 1 is the edit target, our new atlas/compass iron-and-bronze frame.
Make ONE precise layout correction: reduce the entire TOP HEADER from its current roughly 15% of image height to at most 9.5% of image height. In this 1586x992 image the complete top header, wordmark, compass crest, corner fittings and lower header edge must all fit in y=0 through y=94. The uninterrupted black opening must start at y=99 or sooner. It is essential that NO part of the word DURIS or its plaque descends below y=90. The GUI content starts at y=104, so nothing important may be placed there.
Recompose the top engraving into a shallower horizontal band with smaller/simpler compass arcs; make the wordmark elegantly wide and about 40 pixels tall, centered around y=52. It must read exactly "DURIS", once. Reduce the small compass crest if needed. Do not crop the letters or merely erase the bottom of the original header. Redraw a complete compact header with the same excellent metalwork and palette.
Preserve the overall canvas aspect ratio, black iron and muted bronze aesthetic, all side and bottom rails, engraved wayfinding details, and huge pure-black central space. Preserve the exact outer border alignment. Do not enlarge any side or bottom ornament, do not add text. Borders left/right should remain within the outermost 2.5% and bottom within 2.8%. Output the corrected full artwork, flat and straight on, opaque. No screenshot or mockup.
```
