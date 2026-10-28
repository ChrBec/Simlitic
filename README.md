# SimLitic – Täler der Ersten

Ein stilisiertes 3D-Aufbau- und Wirtschaftsspiel in der Steinzeit, inspiriert von Anno 1800: Statt Inseln besiedelst du Täler zwischen den Bergen, statt Schiffen ziehen Karawanen über Pässe. Dein Stamm durchläuft die Neolithische Revolution so, wie sie wirklich ablief – erst sesshaft, dann Ackerbau, dann Keramik, Milch, Wolle, Rad und Kupfer, bis zur Bronze.

Das vollständige Spielkonzept steht in [docs/GDD.md](docs/GDD.md).

## Stand: Kernspiel (Phase 2)

Spielbar:
- 3D-Bergwelt mit 12 Tälern (Haupttal plus zwei Ringe) und 21 Pässen; unerkundetes Land liegt im Nebel
- 5 historisch begründete Stufen: Wildbeuter → Sesshafte Sammler (Natufien) → Erste Bauern → Dorfgemeinschaft → Kupferzeitliche Sippen
- 42 Waren, 58 Gebäude, Ketten mit bis zu vier Stufen (z. B. Emmerfeld → Mühle → Backofen, Erz + Holzkohle → Schmelze → Kupferschmied)
- Pässe mit Hindernissen (Geröllhang, Wildfluss, Schlucht, Gletscher), die man mit Steigen, Fähren, Seilbrücken und Steinmännern überwindet, plus Bohlenwege für Ochsenkarren
- Karawanen als „Schiffe der Berge“: Trägertrupp, Eselkarawane, Ochsenkarren mit Routen, Ladeplätzen und Laden/Abladen je Halt
- Jahreszeiten mit Winter: Schnee, Felder ruhen, Gletscherpässe gesperrt
- Kettenplaner (wie viele Betriebe für 100 Bewohner, wo liegt die Fruchtbarkeit), Warenbilanz, 23 Ziele bis zur Bronze
- Fahrender Händler, zwei rivalisierende Stämme (Handel, Geschenke), Hauptmenü, Speichern/Laden, Einstellungen (DE/EN)

Noch nicht enthalten (siehe Roadmap im GDD): Multiplayer, Steam-Anbindung, Naturwunder, Religion, Vorfälle, endgültige Grafiken und Musik.

## Starten

1. [Godot 4.4](https://godotengine.org/download) (Standard-Version, nicht .NET) installieren.
2. Godot öffnen → *Importieren* → `project.godot` wählen → *Ausführen* (F5).

Steuerung: WASD/Pfeile oder Rechtsklick ziehen (bzw. Linksklick auf freiem Boden) bewegt die Kamera, `Q`/`E` oder Mittelklick ziehen dreht sie, Mausrad zoomt, Linksklick wählt/baut, Rechtsklick bricht ab. `P` Pfad, `X` Abreißen, `1–9` Gebäude, `Tab` Stufe wechseln, `B` Bevölkerung, `C` Produktionsketten, `M` Täler & Pässe, `K` Karawanen, `T` Handel, `H` zum Haupttal, Leertaste Pause, `F5` Schnellspeichern, `Esc` Menü.

## Tests

```bash
GODOT=/pfad/zu/godot tests/run.sh
```

Die Tests laufen ohne Fenster und prüfen Kartenerzeugung, Determinismus (Grundlage für Multiplayer), Wachstum und Aufstieg, Bauregeln, Erkundung, Pass-Hindernisse, Karawanen, Winter, die Stimmigkeit aller Inhalte (jede Ware hat einen Erzeuger, jede Fruchtbarkeit ein Tal) und Speichern/Laden.

Werkzeuge für Entwickler: `tools/mapdump.tscn` (Karte als PNG), `tools/balance.tscn` (Testspieler mit Wirtschaftsprotokoll), `tools/content/generate.py` (erzeugt `content/*.json`), `npm run bake:goods` (Waren-Symbole).

Screenshot eines laufenden Spiels (braucht `xvfb-run`):

```bash
GODOT=/pfad/zu/godot tools/shot.sh bild.png --demo --panel=population
```

## Grafiken austauschen

Alle 3D-Modelle sind vorerst im Code gebaute, stilisierte Low-Poly-Platzhalter. Jedes lässt sich durch eine eigene Datei ersetzen, z. B. `assets/models/buildings/tent.glb` (aus Blender exportiert) – ohne Code anzufassen. Die Symbole im Baumenü werden automatisch aus den Modellen gerendert. Details zu Maßstab, Ausrichtung, Klängen und Mods: [docs/ASSETS.md](docs/ASSETS.md).

## Exportieren (Steam)

`export_presets.cfg` enthält Vorlagen für Windows und Linux. In Godot: *Projekt → Exportieren*, Export-Vorlagen installieren, exportieren. Die Ausgabe landet in `build/`.

Für Steam fehlt noch die Anbindung über [GodotSteam](https://godotsteam.com/) (Overlay, Achievements, Cloud-Saves, Lobbys) – das ist Phase 4 der Roadmap.

## Projektaufbau

```
content/       Spielinhalte als JSON (Güter, Gebäude, Stufen, Täler, Pässe, Hindernisse, Karawanen, Rivalen) – zweisprachig
assets/        Austauschbare 3D-Modelle (.glb), Symbole, UI-Skins, Schriften, Klänge
scripts/sim/   Deterministische Simulation (ohne Grafik)
scripts/view/  3D-Welt: Gelände, Modelle, Kamera, Shader
scripts/ui/    Theme, HUD, Panels
scripts/main.gd  Menüs und Spielsitzungen
tests/         Headless-Tests
tools/artgen/  Generator der gemalten Platzhalter-Grafiken
```

## Lizenzen

Schriften: Amatic SC und Kalam unter SIL Open Font License (`assets/fonts/OFL-*.txt`). Alle übrigen Platzhalter-Grafiken und Klänge werden vom Projekt selbst erzeugt.
