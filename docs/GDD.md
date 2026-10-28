# SimLitic – Game Design Document

> Arbeitstitel: **SimLitic – Täler der Ersten**
> Genre: Aufbau-Strategie / Wirtschaftssimulation (im Geiste von Anno 1800)
> Epoche: Jungpaläolithikum → Neolithische Revolution → frühe Kupfer-/Bronzezeit
> Plattform: PC (Steam), Windows / Linux / macOS (Steam Deck verifiziert als Ziel)
> Stand: Version 0.1 (Konzeptphase + spielbarer Prototyp)

---

## 1. Vision in einem Satz

Du führst einen kleinen Stamm umherziehender Sammler durch die größte Umwälzung der Menschheitsgeschichte – vom Beerensammeln bis zum Ackerbau mit Pflug und Rad – und baust dabei ein Netz aus Bergtälern auf, die über schmale Pfade ein blühendes **Haupttal** versorgen.

### 1.1 Design-Säulen

1. **Planen wie in Anno.** Jedes Haus, jede Kette, jeder Weg zählt. Platz in Tälern ist knapp, Einzugsradien und Wege bestimmen, ob eine Siedlung funktioniert.
2. **Aufstieg durch Bedürfnisse.** Bewohner steigen nur auf, wenn ihre Grund- und Luxusbedürfnisse gedeckt sind. Wer aufsteigt, schaltet neue Gebäude, Werkzeuge und Mechaniken frei.
3. **Täler statt Inseln.** Jedes Tal hat eigene Fruchtbarkeiten, eigenes Klima und eigene Gefahren. Kein Tal kann alles. Die Berge dazwischen sind Logistik, Grenze und Abenteuer zugleich.
4. **Die Zeit verändert die Welt.** Was Sammler brauchen (Beeren, Wild), brauchen Bauern nicht mehr. Wer aufsteigt, verändert, welche Täler wertvoll sind.
5. **Handgemalt und lebendig.** Warme, gemalte Welt mit sichtbaren Pinselstrichen; Menschen laufen sichtbar Wege, Träger ziehen über Pässe, Rauch steigt aus Feuerstellen.

### 1.2 Zielgruppe

Fans von Anno 1800/117, Pharaoh, Banished, Farthest Frontier, The Settlers. Spieler, die lange Partien, Optimierung und schöne, ruhige Aufbauwelten mögen. Sekundär: Geschichtsinteressierte.

---

## 2. Die Welt: Täler, Berge, Pfade

### 2.1 Täler (Pendant zu Anno-Inseln)

Eine Karte besteht aus 6–20 Tälern, getrennt durch Bergmassive. Jedes Tal hat:

| Eigenschaft | Beschreibung |
|---|---|
| **Größe** | Klein / Mittel / Groß / Gewaltig (bebaubare Fläche) |
| **Biom** | Waldtal, Flusstal, Seental, Hochtal, Steppental, Küstental, Gletschertal |
| **Fruchtbarkeiten** | 2–5 aus der Liste unten. Bestimmen, welche Rohstoffketten möglich sind |
| **Vorkommen** | Feste Abbaustellen (Feuerstein, Lehmgrube, Kupferader, Salzquelle) mit endlicher oder sich erholender Ergiebigkeit |
| **Wasser** | Bach, Fluss, See oder trocken – bestimmt Fischerei und spätere Bewässerung |
| **Gefahren** | Raubtiere, Überschwemmung, Kälte, Steinschlag |
| **Naturwunder** | Seltenes Sonderfeld (siehe Kap. 8) |

### 2.2 Fruchtbarkeiten

Fruchtbarkeiten sind ein Kernkonzept: Sie sind **zeitgebunden**.

| Fruchtbarkeit | Wichtig für | Später |
|---|---|---|
| Beerensträucher | Sammler (Beeren) | verliert Bedeutung, später Beerenwein (Luxus) |
| Rehwild | Sammler/Jäger (Fleisch, Häute) | wird von Viehzucht ersetzt |
| Großwild (Wisente) | Jäger (Fleisch, Knochen, Felle) | ausgerottet bei Überjagung |
| Fischgründe | Fischer | bleibt relevant |
| Haselnüsse | Sammler (Nüsse) | Ölpressen |
| Wildgetreide | Siedler (Sammelkorn) | **Grundlage für Ackerbau** |
| Wildschafe/-ziegen | Hirten | **Grundlage für Viehzucht** |
| Lehmboden | Töpfer, Lehmhäuser | bleibt relevant |
| Flachs | Weber | bleibt relevant |
| Honigbienen | Luxus (Met) | bleibt relevant |
| Kräuter | Schamanen (Heilmittel) | bleibt relevant |

**Überjagung/Übersammlung:** Wild- und Beerenfruchtbarkeiten haben eine Regenerationsrate. Wer zu viele Jäger in ein Tal setzt, senkt den Wildbestand (sichtbar: weniger Tiere). Das zwingt Sammler-Stämme zum Expandieren – und ist historisch einer der Treiber der Sesshaftwerdung.

### 2.3 Berge und Pfade (Pendant zu Ozean, Schiffen und Seewegen)

- Täler sind über **Pfade** verbunden. Ein Pfad ist zunächst im **Nebel**.
- **Kundschafter** (Pendant zu Expeditionen) erkunden Pfade. Eine Erkundung dauert, hat Ereignisse mit Entscheidungen (Lawine, Höhle, fremder Stamm) und Risiken.
- Pfade haben **Stufen**: Trampelpfad → befestigter Pfad (Steinstufen) → Saumpfad für Packtiere → Karrenweg (benötigt Rad). Jede Stufe erhöht Tragkraft und Geschwindigkeit.
- **Pässe** können im Winter zuschneien (Jahreszeiten, Kap. 9).
- **Trägerzüge** (Pendant zu Schiffen): Gruppen aus Trägern, später Packtiere (Ziegen, Esel, Ochsen) und Karren. Sie folgen **Handelspfaden** (Pendant zu Handelsrouten) zwischen den Lagerplätzen zweier Täler.
- **Haupttal-Prinzip:** Das Haupttal ist dicht bebaut und beherbergt die höchsten Stufen. Neben-Täler sind Rohstoff- und Nahrungsprovinzen. Das erzeugt die typische Anno-Logistik.

### 2.4 Weitere „Welten“ (Pendant zur Neuen Welt, Arktis, Enbesa)

| Anno 1800 | SimLitic | Besonderheit |
|---|---|---|
| Alte Welt | **Die Mittelberge** | Startregion, gemäßigtes Klima |
| Neue Welt | **Das Flusstiefland** | Eigene Bevölkerung (Flussvolk) mit eigenen Bedürfnissen. Liefert Schilf, Salz, Bernstein, Kakao-Äquivalent: **Honig & Met** |
| Arktis | **Die Gletscherpässe** | Kälte-Mechanik: Häuser brauchen Feuer/Torf-Wärme im Radius. Obsidian, Mammutelfenbein |
| Kap Trelawney | **Das Seeufer** | Zweite Startregion für Fortgeschrittene |
| Enbesa | **Die Steppe** | Pferde, Nomaden, Kupfer; diplomatische Partnerregion |

Jede Region ist eine eigene Karte (Session). Wechsel über Fernpfade mit langen Reisezeiten.

---

## 3. Bevölkerungsstufen

Jede Stufe hat **Wohnhaus**, **Arbeitskraft**, **Grundbedürfnisse** (Aufstieg + Bevölkerung) und **Luxusbedürfnisse** (Muscheleinnahmen + Zufriedenheit). Pendant zu Bauern → Arbeiter → Handwerker → Ingenieure → Investoren.

| # | Stufe | Werkzeugzeit | Wohnhaus | Grundbedürfnisse | Luxus | Schaltet frei |
|---|---|---|---|---|---|---|
| 1 | **Sammler** | Altsteinzeit (Geröllgeräte) | Fellzelt | Beeren, Feuerstelle (Dienst) | Muschelketten | Holzfäller, Beerensammler, Feuerstelle, Lagerplatz, Trampelpfad |
| 2 | **Jäger** | Mittelsteinzeit (Mikrolithen, Bogen) | Rindenhütte | Fleisch, Fellkleidung, Schamanenplatz (Dienst) | Federschmuck, Höhlenmalerei (Dienst) | Jäger, Gerber, Feuersteinschläger, Kundschafter |
| 3 | **Siedler** | Frühneolithikum (geschliffene Beile) | Lehm-Flechtwerkhaus | Fisch, Steinwerkzeug, Tongefäße | Beerenwein, Ritualtanz (Dienst) | Fischer, Lehmgrube, Töpferei, Brennofen, Handelspfade |
| 4 | **Handwerker** | Neolithikum (Kupfer) | Langhaus | Sammelkorn-Brei, Leinengewand, Heilkräuter | Met, Kupferschmuck, Steinkreis-Fest | Weber, Flachsfeld, Kräutersammler, Kupferschmelze, Imker |
| 5 | **Bauern** | Kupfer-/frühe Bronzezeit | Gehöft | Brot, Wollmantel, Milch & Käse, Bronzewerkzeug | Bier, Ochsenkarren, Großes Monument | **Ackerbau, Viehzucht, Rad, Pflug**, Karrenwege |

**Werkzeugzeiten** sind die sichtbare „Epochen“-Leiter. Jeder Stufenaufstieg zeigt eine gemalte Epochen-Karte („Die Zeit der Jäger beginnt“) und einen Tutorial-Hinweis zu den neuen Mechaniken.

### 3.1 Bedürfnis-Mechanik (wie Anno)

- **Grundbedürfnisse** erhöhen die Bewohnerzahl pro Haus und sind Voraussetzung für den Aufstieg.
- **Luxusbedürfnisse** geben Muscheln (Einkommen) und Zufriedenheit, aber keine Bewohner.
- **Dienstbedürfnisse** werden über Einzugsradien von Gebäuden gedeckt (Feuerstelle, Schamanenplatz).
- Unzufriedenheit → Stufenweise Folgen: Abwanderung, Streiks (Arbeitskraft sinkt), Unruhen (Brandstiftung).
- **Aufstiegsmaterial**: Ein Aufstieg kostet Baumaterial (z. B. Fellzelt → Rindenhütte: 2 Holz, 2 Felle).
- **Abstieg** möglich bei langfristigem Mangel (optional, Schwierigkeitsgrad).

### 3.2 Arbeitskraft

Jeder Betrieb verlangt Arbeitskraft einer bestimmten Stufe. Die Arbeitskraft ist **talweit**. Wer alle Sammler zu Jägern macht, hat niemanden mehr für Beeren – das klassische Anno-Spannungsfeld, das zu gemischten Siedlungen zwingt.

### 3.3 Fremdes Volk: Das Flussvolk (Pendant Neue Welt)

Zwei Stufen (Fischer-Schilfvolk → Flusshändler), eigene Bedürfnisse (Räucherfisch, Schilfmatten, Salz). Liefert dem Haupttal Exklusivgüter (Salz, Bernstein, Honig) über lange Fernpfade.

---

## 4. Wirtschaft

### 4.1 Währung: Muscheln

Historisch belegt: Muscheln und Schneckenhäuser wurden über hunderte Kilometer gehandelt. **Muscheln** sind die Hauptwährung (Pendant zu Gold).

- **Einnahmen:** Bewohner zahlen Muscheln, wenn ihre Bedürfnisse erfüllt sind (Basis + Bonus pro Luxusgut).
- **Ausgaben:** Unterhalt für Betriebe, Bau einzelner Gebäude, Kundschafter, Handel.

### 4.2 Ansehen (Pendant zu Einfluss)

Ansehen wächst mit Gesamtbevölkerung und Naturwundern. Es limitiert: Anzahl Handelspfade, Kundschafter, besiedelte Täler, Gestaltungselemente (Totems, Steinsetzungen) und diplomatische Optionen.

### 4.3 Produktionsketten (Auszug)

```
Sammler:   Beerensträucher ─▶ Beerensammler ─▶ Beeren
           Wald ─▶ Holzfäller ─▶ Holz
Jäger:     Rehwild ─▶ Jäger ─▶ Fleisch + Häute ─▶ Gerber ─▶ Fellkleidung
           Feuerstein-Vorkommen ─▶ Feuersteinbruch ─▶ Feuerstein ┐
           Holz ───────────────────────────────────────────────┴▶ Werkzeugmacher ─▶ Steinwerkzeug
Siedler:   Fischgründe ─▶ Fischer ─▶ Fisch
           Lehmboden ─▶ Lehmgrube ─▶ Lehm ─▶ Töpfer (+Holz) ─▶ Tongefäße
           Beeren ─▶ Gärgrube ─▶ Beerenwein
Handwerker: Wildgetreide ─▶ Kornsammler ─▶ Korn ─▶ Breiküche (+Tongefäße) ─▶ Brei
           Flachs ─▶ Flachsfeld ─▶ Flachs ─▶ Weber ─▶ Leinengewand
           Kupfererz + Holzkohle ─▶ Kupferschmelze ─▶ Kupfer ─▶ Schmuckmacher
Bauern:    Acker ─▶ Getreidefeld ─▶ Getreide ─▶ Mahlstein ─▶ Mehl ─▶ Backofen ─▶ Brot
           Weide ─▶ Schafhof ─▶ Wolle ─▶ Weber ─▶ Wollmantel
           Weide ─▶ Kuhhof ─▶ Milch ─▶ Käserei ─▶ Käse
           Kupfer + Zinn ─▶ Bronzegießer ─▶ Bronzewerkzeug
           Getreide ─▶ Brauer ─▶ Bier
           Holz + Bronzewerkzeug ─▶ Stellmacher ─▶ Räder ─▶ Karren
```

Alle Ketten, Zeiten, Kosten und Bedarfe sind **datengetrieben** (`content/*.json`) und ohne Code änderbar.

### 4.4 Logistik

- **Lagerplatz** (Pendant zu Kontor/Lagerhaus) definiert das Einzugsgebiet. Betriebe müssen über Pfade an einen Lagerplatz angebunden sein.
- **Träger** laufen sichtbar zwischen Betrieben und Lagerplatz; lange Wege senken die Effizienz.
- **Talweites Lager** (wie Anno): Alle angebundenen Lager eines Tals teilen sich einen Bestand.

### 4.5 Handel

- **Wandernde Händler** (Pendant zu Archibald Blake/Händlern): kaufen und verkaufen mit Preisen, die von Angebot und Nachfrage abhängen.
- **Handelspfade** zwischen eigenen Tälern: Gut, Menge, Laden/Entladen pro Station.
- **Handel mit NPC-Stämmen:** Verträge (Handelsabkommen, Bündnis), Tributforderungen.

---

## 5. Gegner und Diplomatie

### 5.1 NPC-Rivalen (Pendant zu KI-Gegnern)

Jeder Rivale hat Persönlichkeit, Startstufe, Ziele und Sprachbausteine (gemalte Porträts):

| Rivale | Charakter | Spielweise |
|---|---|---|
| **Aruk der Graue** | Ältester eines Bergstamms | Defensiv, baut Steinkreise, handelt gern Feuerstein |
| **Mira Flusstochter** | Händlerin | Wirtschaftlich, expandiert entlang von Flusstälern |
| **Die Wolfsbrüder** | Kriegerisch | Beanspruchen Pässe, fordern Tribut |
| **Ylva die Seherin** | Spirituell | Kontrolliert Naturwunder, Religionsfokus |

Plus **Raubnomaden** (Pendant zu Piraten): Überfallen Trägerzüge auf Pfaden; können bestochen oder vertrieben werden.

### 5.2 Diplomatie

Stufen: Feindschaft – Waffenstillstand – Frieden – Handelsabkommen – Bündnis. Aktionen: Geschenke (Güter), Heiratsbündnis (Bevölkerungsaustausch), gemeinsames Fest.

### 5.3 Konflikt

Bewusst **leichter als Anno**: Konflikte drehen sich um Pässe und Täler. Palisaden, Wachtürme an Pfaden, Kriegertrupps (Speer, Bogen, später Kupferaxt). Ein Tal wird übernommen, indem man seinen Lagerplatz einnimmt. Konfliktmodus ist in den Spieloptionen abschaltbar (friedliche Partie).

---

## 6. Ereignisse und Erzähler

- **Lagerfeuer-Erzähler** (Pendant zur Zeitung): Zwischen Jahreszeiten erzählt eine Stammesälteste von Ereignissen. Man darf eine „Geschichte“ wählen, die einen temporären Effekt gibt (z. B. „Die Mutigen Jäger“: +10 % Jagd, −5 % Zufriedenheit der Sammler).
- **Vorfälle** (Pendant zu Feuer, Seuche, Unruhen): Buschfeuer, Krankheit, Wolfsangriff, Überschwemmung. Gegenmaßnahmen: Wasserträger, Heiler, Wachen.
- **Quests**: Kleine Aufträge von Bewohnern, Rivalen und Naturgeistern (Finde das verlorene Kind, Bringe 20 Felle zum Wolfsstamm …).

---

## 7. Experten und Talismane (Pendant zu Spezialisten und Items)

- **Kundige** (Spezialisten): Meisterjäger, Kräuterfrau, Flint-Meister, Sternendeuter. In einem **Ältestenrat** (Pendant zum Rathaus/Gewerkschaft) eingesetzt beeinflussen sie Gebäude im Radius.
- **Talismane** (Items): In Gebäuden eingesetzt, z. B. „Bärenzahnamulett“: +25 % Produktivität für Jäger. Gewonnen über Erkundungen, Quests, Handel.

---

## 8. Naturwunder und Religion

### 8.1 Naturwunder

Seltene, einzigartige Kartenfelder. Wer sie im Einzugsgebiet erschließt, erhält starke Boni und **Pilger** (Pendant zum Tourismus).

| Wunder | Effekt |
|---|---|
| **Die Heilige Quelle** | Gesundheit +, keine Seuchen im Tal |
| **Der Uralte Baum** | Holzfäller +50 %, Ansehen + |
| **Die Sternenhöhle** | Höhlenmalereien zählen doppelt, Forschung von Ritualen |
| **Der Feuerberg** (ruhender Vulkan) | Obsidian, fruchtbare Böden, Ausbruchsrisiko |
| **Der Singende Wasserfall** | Zufriedenheit aller Stufen im Radius + |

### 8.2 Religion: Glaubenswege

Jede Siedlung wählt im Laufe des Spiels einen **Glaubensweg** und schaltet Rituale frei (Pendant zu Monumenten/Weltausstellung, aber mit Strategie-Entscheidung):

1. **Animismus – Weg der Geister** (Sammler/Jäger): Bonus auf Fruchtbarkeitsregeneration, Tiergeister-Rituale.
2. **Ahnenkult – Weg der Ahnen** (Siedler): Großsteingräber (Dolmen), Bonus auf Zufriedenheit und Ansehen.
3. **Erdmutter – Weg der Fruchtbarkeit** (Handwerker/Bauern): Ernte-Boni, Fruchtbarkeit von Feldern.
4. **Sonne und Sterne – Weg des Himmels** (Bauern): Steinkreise als Kalender; Jahreszeiten-Vorhersage, Bonus gegen Winter.

Glaubenspunkte („Mana“) entstehen durch Rituale (Dienstgebäude) und werden in **Segnungen** ausgegeben (temporäre Talweit-Effekte).

### 8.3 Monumente (Pendant zu Weltausstellung, Zoo, Museum, Botanischer Garten)

| Anno 1800 | SimLitic |
|---|---|
| Weltausstellung | **Großer Steinkreis** – Mehrstufiger Monumentalbau, später Feste mit Belohnungen |
| Zoo | **Tierhain** – Sammle Tierfetische aus allen Regionen |
| Museum | **Ahnenhöhle** – Sammle Artefakte aus Erkundungen |
| Botanischer Garten | **Kräutergarten der Seherin** |
| Palast | **Häuptlingshalle** mit Ministerien-Äquivalent („Ratsplätze“) |

---

## 9. Eigene Neuerungen

- **Jahreszeiten:** Frühling (Wachstum), Sommer (Höhe der Sammelzeit), Herbst (Ernte, Wanderung des Wilds), Winter (Pässe zu, Wärmebedarf, Vorratshaltung). Nahrung verdirbt ohne Tongefäße → Töpferei wird zur Schlüsseltechnologie (historisch korrekt).
- **Wanderndes Wild:** Rehherden wechseln mit den Jahreszeiten das Tal. Jägerstämme profitieren von mehreren Tälern.
- **Domestizierung:** Wer Wildschafe/-getreide lange genug nutzt, kann sie domestizieren → Die Fruchtbarkeit wird transportabel (Felder und Weiden in jedem Tal mit passendem Boden).
- **Wissensbaum der Werkzeuge:** Schmal und an Stufen gekoppelt; Forschung durch „Wissende“ an der Feuerstelle (kein separates Forschungsinstitut, sondern Geschichten und Erfahrung).

---

## 10. Multiplayer

- **Koop** (gemeinsame Siedlung, geteiltes Lager) und **Versus** (bis zu 4 Spieler + KI).
- Technisch: **Deterministische Lockstep-Simulation**. Alle Spieleraktionen sind Befehle (`Command`), die mit Tick-Nummer verteilt werden. Die Simulation nutzt einen festen Takt und einen eigenen Zufallsgenerator mit Seed → identischer Zustand auf allen Rechnern; Prüfsummen erkennen Desyncs.
- Transport: Steam Networking Sockets (P2P, NAT-Traversal), Lobbys und Einladungen über Steam Matchmaking.
- Speichern/Laden von Multiplayer-Partien, Wiedereinstieg nach Verbindungsabbruch.

Im Prototyp ist die Befehlsarchitektur bereits umgesetzt (alle Eingaben laufen über `sim/commands.ts`), der Netzwerktransport folgt in Phase 4.

---

## 11. Präsentation

### 11.1 Art Direction: „Gemalte Erde“

- **Stil:** Stilisiert, handgemalt, warm. Vorbilder: Gouache-Illustrationen, Kinderbuch-Malerei, prähistorische Höhlenmalerei als Akzent (UI-Symbole im Ocker-/Kohle-Stil).
- **Palette:** Ocker, gebrannte Siena, Moosgrün, Schiefer-Blaugrau, Knochenweiß, Holzkohle. Wenig gesättigte Grundtöne, satte Akzente bei Feuer, Beeren und Wasser.
- **Formen:** Leicht unregelmäßige Konturen, sichtbare Pinselstriche, Papierstruktur. Keine perfekten geometrischen Formen.
- **Kamera:** Isometrische 2.5D-Ansicht (im Prototyp 2D-iso; Ziel: gemalte Sprites in mehreren Zoomstufen).
- **UI:** Wie auf gegerbtes Leder und Rindenpapier gemalt. Symbole als Ocker-Piktogramme. Schrift: handschriftliche Display-Schrift (Amatic SC) + gut lesbare Fließtext-Schrift (Kalam).

### 11.2 Austauschbare Assets

Jedes Bild hat eine **Asset-ID**, die zugleich sein Pfad ist: `buildings/tent` → `res://assets/buildings/tent.png`, `goods/berries`, `nature/tree_3`, `ui/button` … Wer eine PNG-Datei mit gleichem Namen ersetzt, tauscht die Grafik aus, ohne Code anzufassen. Ankerpunkte (wo ein Sprite „auf dem Boden steht“) stehen in `assets/sprites.json`. Spieler und Modder können zusätzlich Dateien unter `user://mods/assets/` und `user://mods/content/` ablegen; diese haben Vorrang. Klänge folgen demselben Prinzip (`res://assets/audio/<id>.ogg`). Details: `docs/ASSETS.md`.

### 11.3 Audio

Ruhige Musik mit Trommeln, Knochenflöte, Obertongesang; Musik wechselt nach Bevölkerungsstufe. Umgebungsgeräusche pro Biom. Rückmeldungen (Bau, Aufstieg, Mangel) als kurze, organische Klänge. Ebenfalls über das Asset-Manifest austauschbar.

---

## 12. Menüs und Einstellungen

- **Hauptmenü:** Fortsetzen, Neue Partie, Laden, Mehrspieler, Einstellungen, Credits, Beenden.
- **Neue Partie:** Startbedingungen (Muscheln, Täler, Fruchtbarkeits-Verteilung), Rivalen (Anzahl, Schwierigkeit), Konflikt ein/aus, Kartengröße, Seed.
- **Einstellungen:**
  - Grafik: Fenster/Vollbild, Auflösung, UI-Skalierung, Qualitätsstufe (Partikel, Wolkenschatten), FPS-Limit
  - Audio: Gesamt, Musik, Effekte, Umgebung
  - Spiel: Sprache, Autosave-Intervall, Kanten-Scrollen, Scrollgeschwindigkeit, Tutorial-Hinweise
  - Steuerung: Tastenbelegung
  - Barrierefreiheit: Farbenblind-Modus, Textgröße
- **Pausemenü:** Fortsetzen, Speichern, Laden, Einstellungen, Hauptmenü.
- **Lokalisierung:** Deutsch und Englisch zum Start. Inhaltstexte stehen zweisprachig in `content/*.json` (`{"de": …, "en": …}`), Oberflächentexte über `Content.L(de, en)`; vor Release Umstieg auf Godot-Übersetzungsdateien (CSV/PO) für weitere Sprachen.

---

## 13. Technik

### 13.1 Entscheidung: Godot 4 + GDScript + GodotSteam

| Option | Pro | Contra |
|---|---|---|
| **Godot 4 (GDScript), GodotSteam** *(gewählt)* | Kostenlos und ohne Umsatzbeteiligung, schlanker 2D-Renderer mit Y-Sortierung und Partikeln, Exporte für Windows/Linux/macOS/Steam Deck, Steam-Overlay, Achievements, Cloud und Networking über GodotSteam, später 3D möglich | GodotSteam muss als vorkompiliertes Plugin oder Editor-Build eingebunden werden |
| TypeScript + Electron | Sehr schnelle Iteration im Browser | Große Builds, Performance bei großen Siedlungen, Steam-Deck-Integration umständlicher |
| Unity / Unreal | Branchenstandard für 3D | Lizenzkosten/Komplexität, für ein kleines Team schwer |

**Begründung:** Für ein gemaltes 2.5D-Aufbauspiel (Ästhetik wie *Pharaoh: A New Era* oder *Dorfromantik*) reicht ein 2D-Renderer. Die Simulation (`scripts/sim`) kennt keine Grafik, läuft in festen Schritten (10 pro Sekunde) und ist deterministisch – Grundlage für Lockstep-Multiplayer und automatisierte Tests. Renderer: GL Compatibility, damit das Spiel auch auf schwacher Hardware und dem Steam Deck läuft.

### 13.2 Architektur

```
project.godot       Godot-Projekt (Autoloads: Content, Settings, Sfx)
content/            Spielinhalte als JSON (Güter, Gebäude, Stufen, Fruchtbarkeiten, Täler, Rivalen)
assets/             Austauschbare PNGs, Schriften, Klänge, sprites.json (Anker)
scripts/core/       Inhalte laden, Einstellungen, Audio, Spielstände
scripts/sim/        Deterministische Simulation: Karte, Wirtschaft, Logistik, Befehle, Ziele
scripts/view/       Isometrische Welt: gemalter Boden, Sprites, Nebel, Overlays, Kamera
scripts/ui/         Theme, HUD, Panels
scripts/main.gd     Menüs, Spielsitzungen
tests/              Headless-Simulationstests
tools/artgen/       Generator für die gemalten Platzhalter-Grafiken
```

### 13.3 Steam-Anforderungen (Checkliste für Release)

- Steamworks: App-ID, Achievements, Cloud-Saves, Overlay, Rich Presence
- Steam Deck: Controller-Steuerung, 1280×800 lesbare UI
- Store: Capsule-Art, Trailer, Screenshots, Beschreibung (DE/EN)
- Altersfreigabe (IARC), Preisgestaltung, Datenschutzerklärung
- Rechtliches: Assetlizenzen dokumentiert, Schriftlizenzen (OFL) beigelegt

---

## 14. Roadmap

| Phase | Inhalt | Ergebnis |
|---|---|---|
| **1 – Prototyp** *(dieser Stand)* | GDD, Technik, spielbarer Vertical Slice: 1 Region, 3 Täler, Stufen 1–5 als Daten, Produktionsketten, Bedürfnisse, Aufstieg, Pfade, Kundschafter, Trägerrouten, NPC-Händler, Rivale, Menüs, Einstellungen, Speichern | Als Desktop-Build (Godot) spielbar |
| **2 – Kernspiel** | Träger-Simulation, Jahreszeiten, Vorfälle, Erzähler, Quests, Balancing aller 5 Stufen, Tutorial-Kampagne | Alpha |
| **3 – Inhalt & Kunst** | Professionelle gemalte Assets (Künstler), Musik, Flusstiefland-Region, Naturwunder, Religion, Monumente | Beta, Steam „Demnächst“-Seite |
| **4 – Multiplayer & Steam** | Steam-Networking-Lockstep, Lobbys, Achievements, Cloud-Saves, Steam Deck | Early Access |
| **5 – Release** | Gletscherpässe, Steppe, Diplomatie/Konflikt-Feinschliff, Lokalisierung, Performance | 1.0 |

Ein Spiel im Umfang von Anno 1800 entsteht dort mit Teams von über 100 Menschen über Jahre. Realistisch ist ein fokussiertes, poliertes Spiel mit dem Kern von Anno – und einer klaren eigenen Identität.

---

## 15. Funktionsabgleich Anno 1800 → SimLitic

| Anno 1800 | SimLitic | Status Prototyp |
|---|---|---|
| Inseln | Täler | ✅ |
| Fruchtbarkeiten | Fruchtbarkeiten (zeitgebunden, regenerierend) | ✅ (ohne Regeneration) |
| Kontor / Lagerhaus | Lagerplatz | ✅ |
| Straßen | Pfade | ✅ |
| Marktplatz, Kirche usw. | Feuerstelle, Schamanenplatz usw. | ✅ |
| Bevölkerungsstufen | 5 Stufen Sammler → Bauern | ✅ |
| Bedarf/Luxus | Grund-/Luxus-/Dienstbedürfnisse | ✅ |
| Arbeitskraft | Arbeitskraft talweit | ✅ |
| Gold / Steuern | Muscheln | ✅ |
| Einfluss | Ansehen | 🟡 Anzeige |
| Expeditionen | Kundschafter | ✅ (vereinfacht) |
| Schiffe & Handelsrouten | Trägerzüge & Handelspfade | ✅ (vereinfacht) |
| Händler | Wandernder Händler | ✅ |
| KI-Gegner | Rivalenstämme | 🟡 wachsendes Tal + Handel |
| Neue Welt | Flusstiefland | ⏳ Phase 3 |
| Arktis (Hitze) | Gletscherpässe (Wärme) | ⏳ Phase 5 |
| Zeitung | Lagerfeuer-Erzähler | ⏳ Phase 2 |
| Spezialisten/Items | Kundige/Talismane | ⏳ Phase 2 |
| Weltausstellung, Zoo, Museum | Steinkreis, Tierhain, Ahnenhöhle | ⏳ Phase 3 |
| Feuer/Seuche/Unruhen | Buschfeuer/Krankheit/Unruhen | ⏳ Phase 2 |
| Elektrizität | Glut/Wärme-Netz (Gletscher) | ⏳ Phase 5 |
| Multiplayer | Lockstep über Steam | 🟡 Architektur |
| Blaupausenmodus | Planungsmodus | ⏳ Phase 2 |
| Statistiken | Bilanz-Panel | 🟡 einfach |
