# Реестр ассетов Project Joker

Заполните реестр до первой публичной или Steam-сборки. Один файл или цельный набор с одинаковой лицензией — одна строка. Если права не подтверждены, ассет не должен попасть в релиз.

| Путь в проекте | Тип | Автор / источник | Лицензия и ссылка | Коммерческое распространение | Изменён? | Нужна атрибуция | Где указана атрибуция | Подтверждение прав | Статус |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Assets/...` | PNG / OGG / шрифт / код |  |  | да / нет / проверить | да / нет | да / нет | титры / README / нет | ссылка, чек или файл лицензии | проверить |
| `Assets/Cards/JumboIndex/*.png` | card faces and backs (PNG) | saul / OpenGameArt | CC0 — https://opengameart.org/content/jumbo-index-playing-cards | да | нет | нет | не требуется | страница источника и `Assets/Cards/JumboIndex/README.md` | готово |
| `Assets/Cards/ClassicFourColor/*.svg` | card faces (SVG) | Heratexx / OpenGameArt | CC0 — https://opengameart.org/content/classic-4-color-poker-deck-svg | да | нет | нет | не требуется | страница источника и `Assets/Cards/ClassicFourColor/README.md` | готово |
| `Assets/Cards/CompactFourColor/*.png` | card faces (PNG) | scl / OpenGameArt | CC0 — https://opengameart.org/content/4-color-playing-cards | да | нет | нет | не требуется | страница источника и `Assets/Cards/CompactFourColor/README.md` | готово |
| `Assets/Cards/VectorClassic/*.png` кроме двух файлов `project_joker*.png` | card faces (high-resolution PNG export from vector originals) | Byron Knoll / OpenGameArt | CC0 — https://opengameart.org/content/playing-cards-vector-png | да | нет | нет | не требуется | страница источника и `Assets/Cards/VectorClassic/README.md` | готово |
| `Assets/Cards/VectorClassic/project_joker.png` | original Joker card illustration (PNG) | OpenAI ImageGen / Project Joker, 2026-07-26 | OpenAI Terms of Use — https://openai.com/policies/terms-of-use/ | да | нет | нет | не требуется | промпт и сведения в `Assets/Cards/VectorClassic/PROJECT_JOKER_README.md` | готово |
| `Assets/Cards/VectorClassic/project_joker_crisp.png` | edited original Joker card illustration (PNG) | OpenAI ImageGen / Project Joker, 2026-07-29 | OpenAI Terms of Use — https://openai.com/policies/terms-of-use/ | да | да, упрощены линии и очищены боковые поля | нет | не требуется | промпт и обработка в `Assets/Cards/VectorClassic/PROJECT_JOKER_CRISP_README.md` | готово |
| `Assets/Effects/Joker/laughing_jester.png` | original 2.5D Joker celebration overlay (RGBA PNG) | OpenAI ImageGen / Project Joker, 2026-07-29 | OpenAI Terms of Use — https://openai.com/policies/terms-of-use/ | да | да, chroma-key удалён и изображение уменьшено до 640×640 | нет | не требуется | финальный промпт и обработка в `Assets/Effects/Joker/README.md` | готово |
| `Assets/Effects/Joker/laughing_jester_middle_fingers.png` | edited 2.5D Joker celebration overlay (RGBA PNG) | OpenAI ImageGen / Project Joker, 2026-07-29 | OpenAI Terms of Use — https://openai.com/policies/terms-of-use/ | да | да, изменены жесты, очищен alpha-край и уменьшено до 640×640 | нет | не требуется | финальный промпт и обработка в `Assets/Effects/Joker/README.md` | готово |
| `Assets/Social/FluentEmoji3D/*.png` | 30 social reaction and gift images (3D-style PNG) | Microsoft / Fluent Emoji | MIT — https://github.com/microsoft/fluentui-emoji/blob/main/LICENSE | да | нет, исходные PNG сохранены без изменений | да | bundled license | официальный репозиторий, `Assets/Social/FluentEmoji3D/README.md` и `THIRD_PARTY_LICENSE.txt` | готово |
| `Assets/Audio/KenneyCasino/*.ogg` | игровые звуковые эффекты карт и фишек | Kenney Vleugels / Kenney.nl | CC0 1.0 — https://kenney.nl/assets/casino-audio | да | нет, выбранные OGG сохранены без изменений | нет | не требуется | страница источника, `Assets/Audio/KenneyCasino/README.md` и `LICENSE.txt` | готово |
| `Assets/Avatars/avatar_*.png` | four built-in player avatars (PNG) | Project Joker; исходное авторство нужно подтвердить | проверить | проверить | неизвестно | проверить | определить после подтверждения | коммит `72f54d7` и `Assets/Avatars/README.md`, но исходные материалы/разрешение не зафиксированы | проверить |
| `Assets/Soundboard/**/*.{mp3,ogg,wav}` | закрытый мемный саундпад | разные интернет-источники | не подтверждена пофайлово | не подтверждено | неизвестно | неизвестно | не определено | 42 файла без пофайловых ссылок и разрешений | только закрытые тесты; исключить из публичной сборки |
| `Assets/PublicSoundboard/**/*.{mp3,ogg,wav}` | публичный саундпад | добавляется пофайлово | только CC0, CC BY либо отдельное коммерческое разрешение | да после проверки | указывать | зависит от лицензии | `THIRD_PARTY_NOTICES.md` при необходимости | отдельная строка на каждый файл или единый проверенный набор | пока пусто |
| `icon.svg` | application icon | стандартная иконка Godot из нового проекта | не использовать как финальный бренд Project Joker | проверить | нет | проверить | не применимо | файл совпадает со стандартной иконкой Godot | заменить до публичной страницы и сборки |
| Godot Engine в экспортируемом EXE | игровой движок | Godot Engine contributors | MIT — https://godotengine.org/license/ | да | нет | да | `THIRD_PARTY_NOTICES.md` или экран лицензий | полный MIT-текст добавлен в `THIRD_PARTY_NOTICES.md` | готово |
| GodotSteam в Steam-шаблоне | интеграция Steamworks | GodotSteam contributors | MIT — https://godotsteam.com/ | да | нет | да | `THIRD_PARTY_NOTICES.md` | перед релизом скопировать точный notice из фактически используемого шаблона и записать его версию | проверить перед собственным App ID |

## Сводка первого аудита

- Четыре внешние карточные коллекции сгруппированы по источникам и уже имеют
  подтверждённый CC0.
- Два карточных Джокера и два праздничных эффекта ImageGen описаны отдельными
  промптами и строками реестра.
- Тридцать Fluent Emoji имеют локальную копию MIT-лицензии.
- Четыре встроенных аватара пока требуют подтверждения исходного авторства.
- Сорок два файла закрытого саундпада не имеют пофайлового подтверждения и
  запрещены для публичного PCK.
- Публичная папка саундпада пока пуста.
- Стандартная иконка Godot должна быть заменена собственным логотипом.
- Для Godot Engine добавлен notice; для конкретного Steam-шаблона GodotSteam
  notice сверяется при переходе на собственный App ID.

## Правила заполнения

- Учитывайте всё, что попадает в экспорт: карты, рубашки, аватары, стикеры, иконки, шрифты, музыку, эффекты, звуки саундпада и любые изображения интерфейса.
- Для открытых ассетов нужна лицензия, которая разрешает коммерческое использование, распространение внутри игры и нужные изменения. «Бесплатный» или «из открытого интернета» сам по себе не означает разрешение.
- Для AI-материалов сохраните сервис, дату генерации и действующие условия использования. Не используйте материалы, похожие на чужие узнаваемые бренды, персонажей или дизайн другой игры.
- Личная музыка и личные аватары игрока не входят в реестр, если они не копируются в `Assets` и не включаются в экспорт.
- Отдельно проверьте названия, логотипы и шрифты: до Steam-релиза нужно убедиться, что их использование не нарушает товарные знаки и лицензии.
