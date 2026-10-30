# SimLitic – Game Design Document

> **Hinweis (v0.3):** Das aktuelle, ausführliche Spielkonzept steht im Dokument
> [Talherz – Spielkonzept](https://claude.ai/artifact/RkiA8pEtYnQFyAx8vxBPHL) (Figuren und Aufgaben,
> Aufwerten von Hand, Stimmung, Winter, Talherz, Krisen, Tempo-Ziele). Dieses Dokument bleibt die
> Grundlage für Welt, Stufen und Technik.

> Arbeitstitel: **Talherz – Täler der Ersten** (vorher SimLitic)
> Genre: Aufbau-Strategie / Wirtschaftssimulation (im Geiste von Anno 1800)
> Epoche: Jungpaläolithikum → Neolithische Revolution → frühe Kupfer-/Bronzezeit
> Plattform: PC (Steam), Windows / Linux / macOS (Steam Deck verifiziert als Ziel)
> Stand: Version 0.3 (spielbare Alpha mit Geschichte)

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

### 2.3 Berge, Pässe und Karawanen (Pendant zu Ozean, Schiffen und Seewegen)

Die Karte ist ein Ring aus 12 Tälern um das Startgebiet (Haupttal in der Mitte, sechs Täler im inneren Ring, fünf im äußeren). 21 Pässe verbinden die Täler; jeder Pass ist ein Sattel, der sich zwischen zwei Gipfeln hinaufzieht.

**Erkunden.** Jeder Pass liegt zunächst im Nebel. Ein Kundschafterlager schickt Kundschafter (Proviant: Fleisch und Muscheln) los; sie kommen über jeden Pass und decken das Tal dahinter auf.

**Hindernisse.** Viele Pässe sind für Lasten nicht begehbar, bis man ein Bauprojekt abgeschlossen hat. Erst dann können Karawanen ihn nutzen und erst dann kann man dahinter ein Tal gründen.

| Hindernis | Lösung | Ab Stufe | Kosten |
|---|---|---|---|
| Trampelpfad | – | sofort | – |
| Geröllhang | Steig anlegen | Sesshafte Sammler | Werkzeug, Holz |
| Wildfluss | Floßfähre | Dorfgemeinschaft | Seile, Holz |
| Schlucht | Seilbrücke | Dorfgemeinschaft | viele Seile, Holz |
| Gletscherpass | Steinmänner setzen | Erste Bauern | Fellkleidung, Werkzeug. Im Winter gesperrt, nie für Wagen |

Jeder offene Pass kann ab den Kupferzeitlichen Sippen zum **Bohlenweg** ausgebaut werden (Bretter + Kupferwerkzeug). Nur über Bohlenwege fahren Ochsenkarren.

**Karawanen** sind die Schiffe der Berge. Man stellt sie an einem **Rastplatz** auf, der am Fuß eines Passes stehen muss.

| Karawane | Ab Stufe | Plätze × Menge | Tempo | Besonderheit |
|---|---|---|---|---|
| Trägertrupp | Sesshafte Sammler | 2 × 10 | langsam | geht über jeden offenen Pass |
| Eselkarawane | Dorfgemeinschaft | 3 × 20 | schneller | Esel um 5000 v. Chr. domestiziert |
| Ochsenkarren | Kupferzeitliche Sippen | 4 × 40 | langsam | braucht Bohlenwege auf der ganzen Strecke |

Jede Karawane fährt eine **Route** mit bis zu 6 Halten (eigene Täler). An jedem Halt gibt es eine Liste „Laden“ und eine Liste „Abladen“. Jede geladene Ware belegt einen Platz. Wird ein Pass gesperrt (Winter), wartet die Karawane oder sucht einen anderen Weg.

**Jahreszeiten.** Ein Jahr hat vier Jahreszeiten zu je 2,5 Minuten. Im Winter liegt Schnee in den Tälern, Felder und Weiden arbeiten nur mit 30 % und Gletscherpässe sind zu. Im Herbst lohnt es sich also, Vorräte anzulegen.

**Haupttal-Prinzip.** Das Haupttal hat die meisten Fruchtbarkeiten, aber **keinen Feuerstein, kein Kupfer, keinen Flachs, keine Schafe und keine Trauben**. Schon die Sesshaften brauchen deshalb ein zweites Tal (die Feuersteinschlucht hinter dem einzigen offenen Pass) und eine Trägerroute. Ab da wächst die typische Anno-Logistik von selbst.

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

## 3. Bevölkerungsstufen – die Neolithische Revolution, wie sie wirklich ablief

Die Stufen folgen der Forschung zur Neolithisierung im Fruchtbaren Halbmond und in Europa. Der wichtigste Punkt: **Die Menschen wurden sesshaft, bevor sie Ackerbau betrieben** (Natufien). Getreide wurde jahrhundertelang wild geerntet, bevor es domestiziert wurde. Töpferei kam erst nach dem Ackerbau, Milch, Wolle und Wagen noch später („Revolution der Sekundärprodukte“), dann Kupfer und schließlich Bronze.

| # | Stufe | Zeit (ca.) | Haus | Grundbedürfnisse | Luxus | Neues Spielprinzip |
|---|---|---|---|---|---|---|
| 1 | **Wildbeuter** | 13 000 v. Chr. (Spätpaläolithikum) | Fellzelt | Beeren, Fleisch, Feuerstelle | Haselnüsse | Sammeln und Jagen im Wald; Pfade; Kundschafter |
| 2 | **Sesshafte Sammler** | 12 000 v. Chr. (Natufien) | Grubenhaus | Fisch, Wildgetreide-Brei, Fellkleidung, Schamane | Honig, Ahnenstätte | Mahlsteine für Wildgetreide; Feuerstein aus einem anderen Tal; Werkzeug; erste Karawanen und Steige |
| 3 | **Erste Bauern** | 9 000 v. Chr. (PPN, Göbekli Tepe) | Lehmziegelhaus | Brot, Fleisch, Fellkleidung, Kultplatz (T-Pfeiler) | Heilkräuter, Tanzplatz | Emmer wird gesät: Feld → Mühle → Backofen. Stroh + Lehm → Lehmziegel. Ziegen werden gehalten |
| 4 | **Dorfgemeinschaft** | 7 000 v. Chr. (Keramisches Neolithikum, Bandkeramik) | Langhaus | Brot, Keramik, Leinen, Kultplatz, Dorfplatz | Bier, Obsidianschmuck | Töpferofen; Flachs → Leinen und Seile; Seile öffnen Flüsse und Schluchten; Esel |
| 5 | **Kupferzeitliche Sippen** | 4 500 v. Chr. (Chalkolithikum) | Gehöft | Brot, Käse, Wollstoff, Kupferwerkzeug, Dorfplatz | Wein, Bronzeschmuck, Dolmen | Kupfererz + Holzkohle → Kupfer; Milch, Wolle; Rad, Bretter, Ochsenkarren, Bohlenwege. Ziel: **Bronze** (Kupfer + Zinn aus fernen Tälern) – das Ende der Steinzeit |

Die nächste Stufe wird freigeschaltet, sobald genug Bewohner der vorigen Stufe leben (60 / 100 / 150 / 200). Häuser steigen dann von selbst auf, wenn Grundbedürfnisse gedeckt sind und das Baumaterial im Lager liegt (Holz + Häute, Werkzeug, Lehmziegel, Keramik).

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

### 4.3 Produktionsketten

42 Waren, 58 Gebäude. Im Spiel zeigt das Fenster **Ketten (C)** für jede Stufe, wie viele Betriebe 100 Bewohner versorgen und in welchen Tälern die nötige Fruchtbarkeit liegt.

```
Wildbeuter:  Wald → Holzfäller → Holz · Sträucher → Beerensammler → Beeren · Rotwild → Jäger → Fleisch
             Wald → Fallensteller → Häute · Haselsträucher → Nusssammler → Haselnüsse
Sesshafte:   Fischgründe → Fischerplatz → Fisch · Wildgetreide → Ernte → Mahlplatz → Brei
             Häute → Gerberei → Fellkleidung · Feuerstein (Vorkommen) + Holz → Werkzeugmacher → Werkzeug
             Wildbienen → Zeidlerei → Honig
Bauern:      Emmerfeld → Emmer + Stroh · Emmer → Mühle → Mehl → Backofen (+Holz) → Brot
             Lehm + Stroh → Ziegelei → Lehmziegel · Mufflons → Ziegenhof → Fleisch + Häute · Kräuter
Dorf:        Lehm + Holz → Töpferofen → Keramik · Flachsfeld → Flachs → Webstuhl → Leinen / Seilerei → Seile
             Gerstenfeld → Mälzerei → Malz → Brauerei (+Keramik) → Bier · Obsidian → Schmuckmacher
Kupferzeit:  Kupfererz + Holzkohle → Schmelze → Kupfer → Kupferschmied (+Holz) → Kupferwerkzeug
             Auerochsen → Rinderhof → Milch → Käserei (+Keramik) → Käse · Mufflons → Schafhof → Wolle → Wollstoff
             Trauben → Kelter (+Keramik) → Wein · Holz → Zimmerei → Bretter → Wagner → Räder
             Kupfer + Zinn → Bronzegießer → Bronzeschmuck
```

Alle Ketten, Zeiten, Kosten und Bedarfe sind **datengetrieben** (`content/*.json`, erzeugt von `tools/content/generate.py`) und ohne Code änderbar.

### 4.4 Logistik

- **Lagerplatz** (Pendant zu Kontor) – Betriebe und Häuser müssen über Pfade an einen Lagerplatz angebunden sein.
- **Talweites Lager** (wie Anno): Jedes Tal hat einen Bestand; Arbeitskraft ist talweit.
- **Karawanen** bewegen Waren zwischen Tälern (siehe 2.3).

### 4.5 Handel

- **Händler vom Fluss** kommt regelmäßig mit wechselnden Preisen.
- **Rivalisierende Stämme** (Graufels, Weidenbach) handeln, wenn die Beziehung gut ist; Geschenke verbessern sie.

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
- **Darstellung:** Echtes 3D. Stilisierte Low-Poly-Modelle mit gemalten, leicht unregelmäßigen Farben (Vorbilder: *Dorfromantik*, *Townscaper*, *Anno 1800* in der Totalen). Berge aus einem Höhenmodell, Gelände und Wasser per Shader „gemalt“ (Pinselstriche, Fels an steilen Hängen, Schneekuppen). Unerkundetes Land liegt im Nebel.
- **Kamera:** Wie Anno: schräge Perspektive, Schwenken, Zoomen (beim Hineinzoomen flacher), Drehen.
- **UI:** Wie auf gegerbtes Leder und Rindenpapier gemalt. Symbole als Ocker-Piktogramme. Schrift: handschriftliche Display-Schrift (Amatic SC) + gut lesbare Fließtext-Schrift (Kalam).

### 11.2 Austauschbare Assets

Jedes Modell hat eine **ID**, die zugleich sein Pfad ist: `buildings/tent` → `res://assets/models/buildings/tent.glb`, `nature/conifer`, `people/hunters` … Liegt dort eine Datei, ersetzt sie den im Code gebauten Platzhalter – ohne Code anzufassen. Waren-Symbole und UI-Skins sind PNG-Dateien unter `assets/`. Spieler und Modder können zusätzlich Dateien unter `user://mods/models/`, `user://mods/assets/` und `user://mods/content/` ablegen; diese haben Vorrang. Klänge folgen demselben Prinzip (`res://assets/audio/<id>.ogg`). Details: `docs/ASSETS.md`.

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
| **Godot 4 (GDScript), GodotSteam** *(gewählt)* | Kostenlos und ohne Umsatzbeteiligung, 3D-Renderer mit Schatten, MultiMesh für große Wälder, glTF-Import aus Blender, Exporte für Windows/Linux/macOS/Steam Deck, Steam-Overlay, Achievements, Cloud und Networking über GodotSteam | GodotSteam muss als vorkompiliertes Plugin oder Editor-Build eingebunden werden |
| TypeScript + Electron | Sehr schnelle Iteration im Browser | Große Builds, Performance bei großen Siedlungen, Steam-Deck-Integration umständlicher |
| Unity / Unreal | Branchenstandard für 3D | Lizenzkosten/Komplexität, für ein kleines Team schwer |

**Begründung:** Godot bringt alles für ein stilisiertes 3D-Aufbauspiel mit und kostet nichts. Die Simulation (`scripts/sim`) kennt keine Grafik, läuft in festen Schritten (10 pro Sekunde) und ist deterministisch – Grundlage für Lockstep-Multiplayer und automatisierte Tests. Renderer: GL Compatibility, damit das Spiel auch auf schwacher Hardware und dem Steam Deck läuft; ein späterer Wechsel auf Forward+ (Umgebungsverdeckung, Volumennebel) ist eine Einstellung in `project.godot`.

### 13.2 Architektur

```
project.godot       Godot-Projekt (Autoloads: Content, Settings, Sfx)
content/            Spielinhalte als JSON (Güter, Gebäude, Stufen, Fruchtbarkeiten, Täler, Rivalen)
assets/             Austauschbare Modelle (models/*.glb), Symbole, UI-Skins, Schriften, Klänge
scripts/core/       Inhalte laden, Einstellungen, Audio, Spielstände
scripts/sim/        Deterministische Simulation: Karte, Wirtschaft, Logistik, Befehle, Ziele
scripts/view/       3D-Welt: Gelände, Wasser, Modelle, Nebel, Overlays, Kamera, Symbol-Renderer
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
| **1 – Prototyp** | GDD, Technik, spielbarer Vertical Slice, Menüs, Einstellungen, Speichern | erledigt |
| **2 – Kernspiel** | Historisch begründete 5 Stufen, 42 Waren, 58 Gebäude, 12 Täler, 21 Pässe mit Hindernissen, Karawanen mit Routen, Jahreszeiten, Kettenplaner, Ziele bis zur Bronze. Offen: Vorfälle, Erzähler, Feinbalancing der späten Stufen | Alpha |
| **2.5 – Geschichte des Tals** *(dieser Stand, v0.3)* | 11 Figuren mit 33 Aufgaben, Aufwerten von Hand, Stimmung, Zuzug, Winter/Feuerholz, Verderb, Wild, Talherz mit Festen, Geistern, Bräuchen und Kostbarkeiten, Krisen, Spielarten, Talherz-Look | Alpha |
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
| Einfluss | Ansehen | ✅ Gründungen, Bräuche |
| Expeditionen | Kundschafter | ✅ (vereinfacht) |
| Schiffe & Handelsrouten | Trägerzüge & Handelspfade | ✅ (vereinfacht) |
| Händler | Wandernder Händler | ✅ |
| KI-Gegner | Rivalenstämme | 🟡 wachsendes Tal + Handel |
| Neue Welt | Flusstiefland | ⏳ Phase 3 |
| Arktis (Hitze) | Gletscherpässe (Wärme) | ⏳ Phase 5 |
| Zeitung | Figuren-Sprüche am Bildrand | ✅ |
| Spezialisten/Items | Kostbarkeiten in Talherz-Nischen | ✅ |
| Weltausstellung, Zoo, Museum | Steinkreis, Tierhain, Ahnenhöhle | ⏳ Phase 3 |
| Feuer/Seuche/Unruhen | Feuer, Fieber, Wölfe, Hochwasser, Dürre, Kälte | ✅ |
| Elektrizität | Glut/Wärme-Netz (Gletscher) | ⏳ Phase 5 |
| Multiplayer | Lockstep über Steam | 🟡 Architektur |
| Blaupausenmodus | Planungsmodus | ⏳ Phase 2 |
| Statistiken | Bilanz-Panel | 🟡 einfach |
| Quests mit Figuren | Menschen des Tals mit Aufgaben | ✅ |
| Festivals / Attraktivität | Feste am Talherz, Stimmung | ✅ |
