# SimLitic – Täler der Ersten

Ein handgemaltes Aufbau- und Wirtschaftsspiel in der Steinzeit, inspiriert von Anno 1800: Statt Inseln besiedelst du Täler zwischen den Bergen, statt Schiffen ziehen Kundschafter und Träger über Bergpfade. Dein Stamm durchläuft die Neolithische Revolution – vom Sammler über Jäger, Siedler und Handwerker bis zum Bauern mit Feldern, Vieh und Rad.

Das vollständige Spielkonzept steht in [docs/GDD.md](docs/GDD.md).

## Stand: Prototyp (Phase 1)

Spielbar:
- 3D-Bergwelt mit 7 Tälern zwischen echten Gipfeln, Seen, Wäldern, Fruchtbarkeiten und Lagerstätten; unerkundetes Land liegt im Nebel
- Anno-artige Kamera: schwenken, zoomen (flacher beim Hineinzoomen), drehen; Licht, Schatten, Rauch und Feuer
- 5 Bevölkerungsstufen mit Grund- und Luxusbedürfnissen, Aufstieg der Häuser, Einkommen in Muscheln
- 45 Gebäude, Produktionsketten, Arbeitskräfte, Einzugsbereiche, Pfade bauen und abreißen
- Kundschafter erkunden Bergpfade, Besiedlung weiterer Täler, Trägerrouten zwischen Tälern
- Fahrender Händler und ein rivalisierender Stamm (Handel, Geschenke)
- Ziele als Einführung, Hauptmenü, Neue Partie, Speichern/Laden, Pausemenü, Einstellungen (Grafik, Audio, Sprache DE/EN, Steuerung)

Noch nicht enthalten (siehe Roadmap im GDD): Multiplayer, Steam-Anbindung, Naturwunder, Religion, Jahreszeiten-Effekte, endgültige Grafiken und Musik.

## Starten

1. [Godot 4.4](https://godotengine.org/download) (Standard-Version, nicht .NET) installieren.
2. Godot öffnen → *Importieren* → `project.godot` wählen → *Ausführen* (F5).

Steuerung: WASD/Pfeile oder Rechtsklick ziehen (bzw. Linksklick auf freiem Boden) bewegt die Kamera, `Q`/`E` oder Mittelklick ziehen dreht sie, Mausrad zoomt, Linksklick wählt/baut, Rechtsklick bricht ab. `P` Pfad, `X` Abreißen, `1–9` Gebäude, `Tab` Stufe wechseln, `B` Bevölkerung, `M` Täler, `T` Handel, `H` zum Haupttal, Leertaste Pause, `F5` Schnellspeichern, `Esc` Menü.

## Tests

```bash
GODOT=/pfad/zu/godot tests/run.sh
```

Die Tests laufen ohne Fenster und prüfen Kartenerzeugung, Determinismus (Grundlage für Multiplayer), Wachstum und Aufstieg, Bauregeln, Erkundung/Trägerrouten und Speichern/Laden.

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
content/       Spielinhalte als JSON (Güter, Gebäude, Stufen, Täler, Rivalen) – zweisprachig
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
