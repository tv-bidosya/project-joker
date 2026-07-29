# Laughing Joker celebration

`laughing_jester.png` is an original 640×640 RGBA celebration overlay generated
for Project Joker with OpenAI ImageGen on 2026-07-29.

The existing original card illustration
`Assets/Cards/VectorClassic/project_joker.png` was used only as a visual
reference for the same red, black, ivory and antique-gold character identity.
The generated character was explicitly required not to resemble a film, comic,
game franchise or real actor.

Final prompt:

> Use case: stylized-concept. Asset type: original game celebration overlay,
> square transparent cutout source. Create a close-up bust of this original
> playing-card jester laughing triumphantly after winning a card trick. Head,
> shoulders and both raised gloved hands; expressive open laugh; large
> red-and-black two-point jester hat with gold bells; elegant ivory ruff collar.
> Premium polished 3D-rendered storybook character preserving a refined
> ornamental playing-card aesthetic. Centered three-quarter bust, strong
> silhouette at 160 px. Deep crimson, near-black, warm ivory and antique gold.
> No resemblance to any film, comic, game franchise or real actor; no card
> frame, playing cards, text, logo or watermark. Generate on a perfectly flat
> solid `#00ff00` chroma-key background.

The chroma-key source was converted locally to alpha with the bundled ImageGen
skill helper using a soft matte (`transparent-threshold 8`,
`opaque-threshold 58`) and despill, visually checked, then reduced to 640×640.
Only the final RGBA PNG is shipped.

Usage terms: OpenAI Terms of Use —
https://openai.com/policies/terms-of-use/
