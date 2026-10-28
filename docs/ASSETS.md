# Grafiken und Klänge austauschen

Alle Bilder in SimLitic sind gewöhnliche PNG-Dateien. Die Platzhalter wurden prozedural „gemalt“ (`tools/artgen`), sind aber ganz normale Dateien – ein Künstler kann sie einzeln ersetzen, ohne Code anzufassen.

## Asset-IDs

Die ID eines Bildes ist sein Pfad unter `assets/` ohne Endung:

| Ordner | Inhalt | Beispiel |
|---|---|---|
| `buildings/<gebäude-id>` | Gebäude, eine Datei je Eintrag in `content/buildings.json` | `buildings/tent.png` |
| `goods/<gut-id>` | Warensymbole (HUD, Panels), je Eintrag in `content/goods.json` | `goods/berries.png` |
| `people/<stufen-id>`, `people/porter`, `people/scout` | Bewohner, Träger, Kundschafter | `people/hunters.png` |
| `nature/` | `tree_0–8`, `bush_0–3`, `rock_0–2`, `deposit_flint/copper/tin`, Berggipfel `peak_v<variante>_<schnee%>` | `nature/tree_4.png` |
| `brush/` | Pinselstriche für den gemalten Boden (`stroke_0–3`, `dab`) | |
| `ui/` | 9-Slice-Skins der Oberfläche (`paper`, `panel`, `panel_dark`, `button*`, `slot`, `leather`, `shell`) | `ui/button_hover.png` |
| `misc/` | `flag_rival`, `warning` | |

## Größe und Ankerpunkt

- Welt-Sprites werden in **doppelter Auflösung** gemalt und im Spiel mit 0,5 skaliert (scharf beim Hineinzoomen).
- Ein Bodenfeld ist im Spiel 64×32 px groß, im Bild also 128×64 px. Ein 2×2-Gebäude hat eine Grundfläche von 256×128 px im Bild.
- `assets/sprites.json` legt je ID den **Ankerpunkt** in Bildpixeln fest: die Stelle, die auf der unteren Spitze der Grundfläche steht. Fehlt ein Eintrag, gilt „unten mittig“.
- Wer ein Bild in anderer Größe liefert, passt nur den Anker in `sprites.json` an.

## UI-Skins

Die `ui/*.png` werden als 9-Slice gestreckt (Ränder bleiben, Mitte wird gedehnt). Die Randbreiten stehen in `scripts/ui/ui.gd` (`_tex_box`). Schriften: `assets/fonts/` (Amatic SC und Kalam, OFL-Lizenz liegt bei).

## Klänge und Musik

Fehlt eine Datei, erzeugt das Spiel einen Platzhalterklang. Lege eine Datei `assets/audio/<id>.ogg` (oder `.wav`/`.mp3`) ab, um ihn zu ersetzen:

`sfx_click`, `sfx_build`, `sfx_demolish`, `sfx_error`, `sfx_upgrade`, `sfx_tier`, `music_main`, `ambience_wind`

## Mods ohne neuen Build

Das Spiel schaut zuerst im Benutzerordner nach (`user://` ist unter Windows `%APPDATA%\Godot\app_userdata\SimLitic`, unter Linux `~/.local/share/godot/app_userdata/SimLitic`):

- `user://mods/assets/<id>.png` ersetzt ein Bild,
- `user://mods/content/<datei>.json` ersetzt eine Inhaltsdatei (z. B. `buildings.json`).

## Platzhalter neu erzeugen

```bash
npm install
npm run bake     # malt alle PNGs neu und schreibt assets/sprites.json
```

Achtung: `bake` überschreibt die Dateien in `assets/`. Eigene Grafiken vorher sichern oder den Generator für diese IDs anpassen (`tools/artgen/src/sprites.ts`).
