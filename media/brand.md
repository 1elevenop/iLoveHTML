# iLoveHTML brand

A bold, friendly, hand-made look: cream paper, thick black ink, hard offset
shadows and flat colour blocks. Everything here is free to use for writing
about iLoveHTML.

## Logo

| File | Use |
|---|---|
| `logo/mark-colour.svg` (+ `-1024/-512/-192.png`) | Default mark: heart holding `</>` on a yellow tile |
| `logo/mark-on-dark.svg` (+ PNGs) | On dark backgrounds: white outline and shadow so the tile stays visible |
| `logo/mark-mono.svg` (+ PNGs) | One colour (black ink on white), for print or single-colour use |
| `logo/wordmark.png`, `logo/wordmark-on-dark.png` | Mark + "iLove**HTML**" lockup |
| `logo/src/` | Vector sources; the PNGs and exported SVGs are made from them in Affinity |
| `social-preview.png` (1280×640) | GitHub social preview (Settings → Social preview) |
| `feature-graphic.png` (1024×500) | Google Play feature graphic |
| `demo.mp4` | Screen recording behind `docs/demo.gif` |

App icons are made from the same sources: Android launcher icons in
`app/android/app/src/main/res/mipmap-*` (adaptive foreground, monochrome layer
for themed icons, yellow background) and the Windows icon in
`app/windows/runner/resources/app_icon.ico` (16–256 px).

## Colours

| Name | Hex | Use |
|---|---|---|
| Paper | `#FFFDF5` | Light background |
| Ink | `#000000` | Text, outlines, shadows |
| Night | `#0F0F0F` / `#1A1A1A` | Dark background / dark panels |
| Yellow | `#FFD60A` | Main accent, logo tile |
| Pink | `#FF5C8A` | Heart, second accent |
| Purple | `#7B61FF` | Accent |
| Teal | `#00C2CB` | Accent |
| Green | `#3CCB4A` | Accent |

Yellow, teal and green are too light for text on Paper; use Ink for text and
the colours as fills.

## Type

- **Space Grotesk** (Bold for headings, Regular/Medium for text). SIL Open Font License.
- **JetBrains Mono** for code, package IDs and logs. SIL Open Font License.

## Shape

- Outlines 2.5 px (UI) or ~3.4 % of the logo's width; corners 8 px.
- Shadows are hard and offset down-right (4 px in the UI), never blurred.

## Clear space and size

- Keep empty space around the mark of at least a quarter of its width.
- Smallest sizes: mark 24 px, wordmark 120 px wide.

## Please don't

- Recolour the heart or the tile outside the palette, or add gradients.
- Blur, soften or remove the shadow; rotate, stretch or outline the mark.
- Put the colour mark on busy photos or on dark backgrounds (use `mark-on-dark`).
- Use the name or mark in a way that suggests an official endorsement.
