# Modelle, Grafiken und Klänge austauschen

Die Welt von SimLitic ist 3D. Alle Modelle sind derzeit stilisierte Low-Poly-Platzhalter, die im Code aus einfachen Formen gebaut werden (`scripts/view/models.gd`). Jedes Modell kann einzeln durch eine Datei ersetzt werden – ohne Code anzufassen.

## 3D-Modelle

Das Spiel sucht für jede Modell-ID zuerst eine Datei und baut nur, wenn keine da ist, den Platzhalter:

| ID | Datei (eine davon) | Wofür |
|---|---|---|
| `buildings/<gebäude-id>` | `assets/models/buildings/tent.glb` | Gebäude, je Eintrag in `content/buildings.json` |
| `nature/conifer`, `nature/broadleaf` | `assets/models/nature/conifer.glb` | Nadel- und Laubbäume (tausendfach instanziert) |
| `nature/bush`, `nature/hazel`, `nature/rock` | | Beerensträucher, Haselsträucher, Felsen |
| `nature/deposit_flint`, `_copper`, `_tin` | | Lagerstätten (2×2 Felder) |
| `people/<stufen-id>`, `people/porter`, `people/scout` | `assets/models/people/hunters.glb` | Bewohner, Träger, Kundschafter |
| `misc/warning` | | Warnzeichen über Gebäuden |

Erlaubte Formate: `.glb`, `.gltf`, `.tscn`, `.scn`. Für Bäume, Büsche, Felsen und Menschen wird das erste Mesh der Datei verwendet; Gebäude dürfen ganze Szenen sein (mit Animationen, Lichtern usw.).

**Maßstab und Ausrichtung**
- 1 Spielfeld = 1 Einheit (in Blender 1 m). Ein 2×2-Gebäude hat eine Grundfläche von 2 × 2 m, ein 3×3-Gebäude 3 × 3 m.
- Der Ursprung liegt **unten in der Mitte der Grundfläche**; das Modell steht auf y = 0.
- Die Tür zeigt nach **+Z** (in Blender: −Y, der glTF-Export dreht das richtig). Das Spiel dreht das Gebäude automatisch zur nächsten Straße.
- Stil: matte Farben, wenig Glanz, gerne Vertex-Farben oder handgemalte Texturen.

Die Symbole im Baumenü werden beim Spielstart aus den Modellen gerendert (`scripts/view/icon_baker.gd`), passen also automatisch zu ausgetauschten Modellen.

## Gelände, Wasser, Licht

Gelände und Wasser werden von Shadern gemalt (`scripts/view/shaders/`). Die Farben stehen dort als Parameter (Gras je Tal in `scripts/view/palette.gd`, Fels, Schnee, Pfade, Nebel). Licht, Nebel und Farbstimmung: `_setup_environment()` in `scripts/view/world_view.gd`.

## 2D-Bilder

Waren-Symbole (`assets/goods/<gut-id>.png`), die UI-Skins (`assets/ui/`) und die Rauch-Textur (`assets/brush/dab.png`) sind PNG-Dateien: gleiche Datei ersetzen, fertig. `assets/buildings/*.png` dienen nur noch als Ersatz-Symbole, falls das Rendern der Modelle nicht möglich ist. Die Ordner `assets/nature/` und `assets/people/` stammen aus der früheren 2D-Fassung und werden nicht mehr verwendet.

## UI-Skins

Die `ui/*.png` werden als 9-Slice gestreckt (Ränder bleiben, Mitte wird gedehnt). Die Randbreiten stehen in `scripts/ui/ui.gd` (`_tex_box`). Schriften: `assets/fonts/` (Amatic SC und Kalam, OFL-Lizenz liegt bei).

## Klänge und Musik

Fehlt eine Datei, erzeugt das Spiel einen Platzhalterklang. Lege eine Datei `assets/audio/<id>.ogg` (oder `.wav`/`.mp3`) ab, um ihn zu ersetzen:

`sfx_click`, `sfx_build`, `sfx_demolish`, `sfx_error`, `sfx_upgrade`, `sfx_tier`, `music_main`, `ambience_wind`

## Mods ohne neuen Build

Das Spiel schaut zuerst im Benutzerordner nach (`user://` ist unter Windows `%APPDATA%\Godot\app_userdata\SimLitic`, unter Linux `~/.local/share/godot/app_userdata/SimLitic`):

- `user://mods/models/<id>.glb` ersetzt ein 3D-Modell,
- `user://mods/assets/<id>.png` ersetzt ein Bild,
- `user://mods/content/<datei>.json` ersetzt eine Inhaltsdatei (z. B. `buildings.json`).

## 2D-Platzhalter neu erzeugen

```bash
npm install
npm run bake     # malt die 2D-Platzhalter (Symbole, UI) neu
```

Achtung: `bake` überschreibt die Dateien in `assets/`. Eigene Grafiken vorher sichern oder den Generator für diese IDs anpassen (`tools/artgen/src/sprites.ts`).
