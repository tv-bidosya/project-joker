# Реєстр матеріалів Project Joker

До публічної або Steam-збірки допускаються лише матеріали з підтвердженим походженням і правом комерційного розповсюдження. Один файл або цілісний набір з однаковою ліцензією — один рядок.

| Шлях у проєкті | Матеріал і джерело | Ліцензія | Підтвердження | Статус |
| --- | --- | --- | --- | --- |
| `Assets/Cards/JumboIndex/*.png` | карти saul / OpenGameArt | [CC0](https://opengameart.org/content/jumbo-index-playing-cards) | `Assets/Cards/JumboIndex/README.md` | готово |
| `Assets/Cards/ClassicFourColor/*.svg` | карти Heratexx / OpenGameArt | [CC0](https://opengameart.org/content/classic-4-color-poker-deck-svg) | `Assets/Cards/ClassicFourColor/README.md` | готово |
| `Assets/Cards/CompactFourColor/*.png` | карти scl / OpenGameArt | [CC0](https://opengameart.org/content/4-color-playing-cards) | `Assets/Cards/CompactFourColor/README.md` | готово |
| `Assets/Cards/VectorClassic/*.png`, крім `project_joker*.png` | векторні карти Byron Knoll / OpenGameArt | [CC0](https://opengameart.org/content/playing-cards-vector-png) | `Assets/Cards/VectorClassic/README.md` | готово |
| `Assets/Cards/VectorClassic/project_joker.png` | оригінальна карта Джокера, OpenAI ImageGen / Project Joker, 2026-07-26 | [OpenAI Terms of Use](https://openai.com/policies/terms-of-use/) | `PROJECT_JOKER_README.md` | готово |
| `Assets/Cards/VectorClassic/project_joker_crisp.png` | відредагована карта Джокера, OpenAI ImageGen / Project Joker, 2026-07-29 | [OpenAI Terms of Use](https://openai.com/policies/terms-of-use/) | `PROJECT_JOKER_CRISP_README.md`; очищено краї | готово |
| `Assets/Effects/Joker/laughing_jester.png` | оригінальний 2.5D-ефект, OpenAI ImageGen / Project Joker, 2026-07-29 | [OpenAI Terms of Use](https://openai.com/policies/terms-of-use/) | `Assets/Effects/Joker/README.md`; очищено alpha, 640×640 | готово |
| `Assets/Effects/Joker/laughing_jester_middle_fingers.png` | відредагований 2.5D-ефект, OpenAI ImageGen / Project Joker, 2026-07-29 | [OpenAI Terms of Use](https://openai.com/policies/terms-of-use/) | `Assets/Effects/Joker/README.md`; змінено жести, 640×640 | готово |
| `Assets/Social/FluentEmoji3D/*.png` | 30 реакцій і подарунків Microsoft Fluent Emoji | [MIT](https://github.com/microsoft/fluentui-emoji/blob/main/LICENSE) | локальні README та `THIRD_PARTY_LICENSE.txt` | готово |
| `Assets/Audio/KenneyCasino/*.ogg` | звуки карт і фішок Kenney Vleugels | [CC0 1.0](https://kenney.nl/assets/casino-audio) | README і `LICENSE.txt` | готово |
| `Assets/Avatars/{avatar_fox_v2,avatar_clown,avatar_ace,avatar_mystery}.png` | чотири оригінальні аватари, OpenAI ImageGen / Project Joker, 2026-08-10 | [OpenAI Terms of Use](https://openai.com/policies/terms-of-use/) | `Assets/Avatars/README.md`; зменшено до 512×512 | готово |
| `Assets/Soundboard/{Bright Female,Mature Female}/*.wav`, `solo-clap.wav`, `wolf-whistle.wav` | 19 тестових звуків cicifyre та OwlishMedia / OpenGameArt | CC0 1.0 | сторінки наборів і вкладені `readme.txt` | готово |
| `Assets/Soundboard/custom/{yapidar,yebiwe}.mp3` | дві оригінальні записи власника Project Joker і друзів | оригінальний матеріал; походження підтверджено 2026-08-10 | `Assets/Soundboard/custom/SOURCES.md`; зберігати згоди учасників | готово за умови збереження згод |
| `Assets/PublicSoundboard/**/*.{mp3,ogg,wav}` | 19 CC0-звуків і дві оригінальні записи | CC0 1.0 та власні права Project Joker | `Assets/PublicSoundboard/SOURCES.md`, маніфест | готово |
| `Assets/Brand/project_joker_icon.{png,ico}` | оригінальна іконка, OpenAI ImageGen / Project Joker, 2026-08-10 | [OpenAI Terms of Use](https://openai.com/policies/terms-of-use/) | `Assets/Brand/README.md`; багаторозмірний ICO | готово |
| `Assets/UI/menu_card_salon_night_v2.png`, `menu_card_salon_day_v3.png` | парні оригінальні фони меню, OpenAI ImageGen / Project Joker, 2026-08-14 | [OpenAI Terms of Use](https://openai.com/policies/terms-of-use/) | `Assets/UI/README.md`; виправлено карти, створено денний варіант | готово |
| Godot Engine у EXE | Godot Engine contributors | [MIT](https://godotengine.org/license/) | повний текст у `THIRD_PARTY_NOTICES.md` | готово |
| GodotSteam у Steam-шаблоні | GodotSteam contributors | [MIT](https://godotsteam.com/) | перед релізом додати точний notice і версію фактичного шаблону | перевірити перед власним App ID |

## Стан аудиту

- Чотири зовнішні карткові колекції мають підтверджену CC0.
- Варіанти Джокера й ефекти ImageGen описано окремими промптами.
- Для Fluent Emoji збережено локальну копію MIT-ліцензії.
- Старий непідтверджений мемний саундпад видалено; публічний набір містить 19 CC0-звуків і дві власні записи.
- Для власних голосових записів необхідно зберігати згоду всіх учасників.
- Іконка Godot замінена; перед сторінкою магазину потрібно перевірити PNG/ICO у 16, 32 та 64 px.
- Notice Godot Engine готовий; дані конкретного шаблону GodotSteam звіряються під час переходу на власний App ID.

## Правила ведення

- Обліковувати все, що потрапляє до експорту: карти, сорочки, аватари, реакції, іконки, шрифти, музику, ефекти, звуки й фони.
- «Безкоштовно» або «з інтернету» не означає дозвіл на використання.
- Для відкритого матеріалу потрібна ліцензія, яка дозволяє комерційне використання, поширення в грі та необхідні зміни.
- Для AI-матеріалів зберігати сервіс, дату, промпт і чинні умови; уникати впізнаваних чужих персонажів, брендів та оформлення інших ігор.
- Особиста музика й аватари користувача не входять до реєстру, якщо не копіюються до `Assets` і не експортуються.
- Окремо перевіряти назву, логотип, шрифти, бібліотеки, Steam-шаблон і матеріали сторінки магазину.
