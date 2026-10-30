# Talherz – Täler der Ersten

Ein stilisiertes 3D-Aufbau- und Wirtschaftsspiel in der Steinzeit, inspiriert von Anno 1800: Statt Inseln besiedelst du Täler zwischen den Bergen, statt Schiffen ziehen Karawanen über Pässe. Dein Stamm durchläuft die Neolithische Revolution so, wie sie wirklich ablief – erst sesshaft, dann Ackerbau, dann Keramik, Milch, Wolle, Rad und Kupfer, bis zur Bronze. (Projekt- und Repository-Name: SimLitic.)

Das Spielkonzept (v0.3, als Abschlussarbeit ausgearbeitet): [Talherz – Spielkonzept](https://claude.ai/artifact/RkiA8pEtYnQFyAx8vxBPHL). Das ältere Grundlagen-Dokument steht in [docs/GDD.md](docs/GDD.md).

## Stand: Version 0.3 – die Geschichte des Tals

Neu in 0.3:
- **Figuren statt Freischalt-Liste:** 11 Menschen (Ama die Älteste, Borr der Jäger mit Hund Fenn, Sela, Nuri, Oro, Ilun, Tamo, Enna, Hesa, Garan, Kural) kommen über die Berge ins Tal, stehen sichtbar neben ihrem Gebäude und tragen ein „!“, wenn sie eine Aufgabe haben. Anklicken öffnet den Dialog mit Porträt. 33 Aufgaben schalten Gebäude, Feste, Bräuche und Kostbarkeiten frei; Amas Schwellen-Aufgaben öffnen die nächste Zeit.
- **Aufwerten von Hand:** Häuser steigen nicht mehr selbst auf. Ein grüner Pfeil zeigt bereite Häuser; Aufwerten kostet Baumaterial (Holz, Häute, Feldsteine …) und lässt sich je Haus sperren.
- **Bedürfnisse wachsen mit dem Dorf** (wie Anno: neue Wünsche ab 12, 30, 60 … Bewohnern), Stimmung (Schönheit, Lärm, Hunger, Kälte, Feste), Zuzug abhängig von der Stimmung.
- **Winter mit Folgen:** Feuerholz je Haus, Verderb von Vorräten (Vorratsgruben, Räucherhaus, Kornspeicher schützen), Wild und Fisch werden knapp, gefällte Bäume wachsen erst nach zwei Jahren nach.
- **Das Talherz:** Feste (Herdfest, Sonnwende, Erntefest, Frühlingsfest), Geister des Tals, drei Nischen für Kostbarkeiten, Bräuche mit Vor- und Nachteilen.
- **Krisen und Glück** ab dem dritten Jahr: Wölfe, Fieber, Feuer, Hochwasser, Dürre, Kälteeinbruch – abwendbar, wenn man vorgesorgt hat.
- **Spielarten:** Lagerfeuer, Talherz, Bergwinter, Eiszeit, Sandkasten.
- **Neuer Look nach dem Talherz-Design:** Gouache-Licht in weichen Stufen, lila Fels, ockerner Dorfboden, türkises Wasser, Fellkuppeln mit Flicken, Jahreszeiten (Frühlingsgrün, Herbstlaub, Schnee auf Dächern), Pergament-HUD mit Jahreszeitkarte, Vorratskarte, Ortskarte und runden Knöpfen.
- **Tempo:** Ein einfacher Testspieler erreicht die zweite Zeit nach rund 27 Minuten (vorher 5).

Aus 0.2 vorhanden: 3D-Bergwelt mit 12 Tälern und 21 Pässen, 5 historische Stufen, 43 Waren, 66 Gebäude, Pass-Hindernisse, Karawanen, Händler, Rivalen, Speichern/Laden, Einstellungen (DE/EN).

Noch nicht enthalten (siehe Konzept, Kapitel 17): Multiplayer, Steam-Anbindung, Expeditionen ins Flusstiefland, Wunder, endgültige Grafiken und Musik.

## Starten

1. [Godot 4.4](https://godotengine.org/download) (Standard-Version, nicht .NET) installieren.
2. Godot öffnen → *Importieren* → `project.godot` wählen → *Ausführen* (F5).

Steuerung: WASD/Pfeile oder Rechtsklick ziehen (bzw. Linksklick auf freiem Boden) bewegt die Kamera, `Q`/`E` oder Mittelklick ziehen dreht sie, Mausrad zoomt, Linksklick wählt/baut (auch Figuren und Funde in der Welt), Rechtsklick bricht ab. `P` Pfad, `X` Abreißen, `1–9` Gebäude, `Tab` Stufe wechseln, `J` Aufgaben, `H` Talherz, `B` Bevölkerung, `C` Produktionsketten, `M` Täler & Pässe, `K` Karawanen, `T` Handel, Leertaste Pause, `F5` Schnellspeichern, `Esc` Menü.

## Tests

```bash
GODOT=/pfad/zu/godot tests/run.sh
```

Die Tests laufen ohne Fenster und prüfen Kartenerzeugung, Determinismus samt Geschichte und Krisen (Grundlage für Multiplayer), den Einstieg über Amas Aufgaben, das Tempo (keine zweite Zeit in den ersten 12 Minuten), Aufwerten von Hand, Winter/Feuerholz/Verderb/Wild, Feste und Kostbarkeiten, Bauregeln, Erkundung, Pass-Hindernisse, Karawanen, die Stimmigkeit aller Inhalte (jede Ware hat einen Erzeuger, jedes Gebäude lässt sich freischalten, jede Aufgabe verweist auf Vorhandenes) und Speichern/Laden.

Werkzeuge für Entwickler: `tools/mapdump.tscn` (Karte als PNG), `tools/balance.tscn` (ein Testspieler folgt den Aufgaben und protokolliert jede Minute, wann welche Zeit beginnt: `-- --minutes=90 --seed=42 --mode=talherz`), `tools/content/generate.py` (erzeugt `content/*.json`), `npm run bake:goods` (Waren-Symbole).

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
content/       Spielinhalte als JSON (Güter, Gebäude, Stufen, Täler, Pässe, Hindernisse, Karawanen, Rivalen,
               Figuren, Aufgaben, Kostbarkeiten, Bräuche, Feste, Geister) – zweisprachig
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
