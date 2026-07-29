# Project Joker crisp card candidate

- File: `project_joker_crisp.png`
- Generated: 2026-07-29
- Tool: OpenAI built-in ImageGen in Codex
- Input image: `project_joker.png`
- Game-ready size: 500×726 pixels, matching the Vector Classic face cards
- Edge treatment: full opaque card face with the generated vertical keylines removed from the outer 15-pixel side fields; the shared runtime alpha mask produces the only visible straight antialiased contour
- Status: connected as the Vector Classic Joker
- Terms: https://openai.com/policies/terms-of-use/

## Final prompt

```text
Use case: precise-object-edit
Asset type: portrait Joker face for the existing Vector Classic playing-card deck in a Godot PC game, displayed at approximately 88x128 pixels
Input image: edit target and strict design reference
Primary request: redraw the same original Joker character so it remains crisp and readable at tiny gameplay size
Preserve: the same single theatrical jester, same centered full-body pose and gesture, same friendly mischievous face, same red/black/antique-gold costume, same cap, same warm ivory card field, same symmetric ornament placement and thin rounded black outer keyline, same portrait composition
Change only: simplify dense engraved micro-detail, use stronger clean vector-like silhouettes, moderately thicker consistent outlines, flatter high-contrast color regions, fewer tiny interior strokes, sharply separated red/black/gold shapes, clearer face and costume landmarks at thumbnail size
Composition: full card face with generous safe margins, no perspective and no 3D mockup
Constraints: original character only; no text, letters, suit symbols, logos, watermark, blur, glow, depth-of-field, painterly softness, noisy texture, tiny decorative clutter, cropped body or border. The final downscaled image must look as sharp as a conventional vector playing-card king at 88x128 pixels.
```
