# Реестр ассетов Project Joker

Заполните реестр до первой публичной или Steam-сборки. Один файл или цельный набор с одинаковой лицензией — одна строка. Если права не подтверждены, ассет не должен попасть в релиз.

| Путь в проекте | Тип | Автор / источник | Лицензия и ссылка | Коммерческое распространение | Изменён? | Нужна атрибуция | Где указана атрибуция | Подтверждение прав | Статус |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Assets/...` | PNG / OGG / шрифт / код |  |  | да / нет / проверить | да / нет | да / нет | титры / README / нет | ссылка, чек или файл лицензии | проверить |
| `Assets/Cards/JumboIndex/*.png` | card faces and backs (PNG) | saul / OpenGameArt | CC0 — https://opengameart.org/content/jumbo-index-playing-cards | да | нет | нет | не требуется | страница источника и `Assets/Cards/JumboIndex/README.md` | готово |
| `Assets/Cards/ClassicFourColor/*.svg` | card faces (SVG) | Heratexx / OpenGameArt | CC0 — https://opengameart.org/content/classic-4-color-poker-deck-svg | да | нет | нет | не требуется | страница источника и `Assets/Cards/ClassicFourColor/README.md` | готово |
| `Assets/Cards/CompactFourColor/*.png` | card faces (PNG) | scl / OpenGameArt | CC0 — https://opengameart.org/content/4-color-playing-cards | да | нет | нет | не требуется | страница источника и `Assets/Cards/CompactFourColor/README.md` | готово |
| `Assets/Cards/VectorClassic/*.png` кроме `project_joker.png` | card faces (high-resolution PNG export from vector originals) | Byron Knoll / OpenGameArt | CC0 — https://opengameart.org/content/playing-cards-vector-png | да | нет | нет | не требуется | страница источника и `Assets/Cards/VectorClassic/README.md` | готово |
| `Assets/Cards/VectorClassic/project_joker.png` | original Joker card illustration (PNG) | OpenAI ImageGen / Project Joker, 2026-07-26 | OpenAI Terms of Use — https://openai.com/policies/terms-of-use/ | да | нет | нет | не требуется | промпт и сведения в `Assets/Cards/VectorClassic/PROJECT_JOKER_README.md` | готово |
| `Assets/Effects/Joker/laughing_jester.png` | original 2.5D Joker celebration overlay (RGBA PNG) | OpenAI ImageGen / Project Joker, 2026-07-29 | OpenAI Terms of Use — https://openai.com/policies/terms-of-use/ | да | да, chroma-key удалён и изображение уменьшено до 640×640 | нет | не требуется | финальный промпт и обработка в `Assets/Effects/Joker/README.md` | готово |
| `Assets/Social/FluentEmoji3D/*.png` | 30 social reaction and gift images (3D-style PNG) | Microsoft / Fluent Emoji | MIT — https://github.com/microsoft/fluentui-emoji/blob/main/LICENSE | да | нет, исходные PNG сохранены без изменений | да | bundled license | официальный репозиторий, `Assets/Social/FluentEmoji3D/README.md` и `THIRD_PARTY_LICENSE.txt` | готово |

## Правила заполнения

- Учитывайте всё, что попадает в экспорт: карты, рубашки, аватары, стикеры, иконки, шрифты, музыку, эффекты, звуки саундпада и любые изображения интерфейса.
- Для открытых ассетов нужна лицензия, которая разрешает коммерческое использование, распространение внутри игры и нужные изменения. «Бесплатный» или «из открытого интернета» сам по себе не означает разрешение.
- Для AI-материалов сохраните сервис, дату генерации и действующие условия использования. Не используйте материалы, похожие на чужие узнаваемые бренды, персонажей или дизайн другой игры.
- Личная музыка и личные аватары игрока не входят в реестр, если они не копируются в `Assets` и не включаются в экспорт.
- Отдельно проверьте названия, логотипы и шрифты: до Steam-релиза нужно убедиться, что их использование не нарушает товарные знаки и лицензии.
