import json
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "content") + "/"
def T(de, en): return {"de": de, "en": en}

goods = [
 # id, de, en, value, color, glyph
 ("wood","Holz","Wood",4,"#8a5a32","log"),
 ("berries","Beeren","Berries",5,"#7a2348","berries"),
 ("stone","Feldsteine","Fieldstones",3,"#9c93ab","stone"),
 ("meat","Fleisch","Meat",9,"#a33a2c","meat"),
 ("hides","Häute","Hides",7,"#b48a5c","hide"),
 ("nuts","Haselnüsse","Hazelnuts",10,"#a8743a","nut"),
 ("fish","Fisch","Fish",8,"#5f8ea0","fish"),
 ("wildgrain","Wildgetreide","Wild Grain",6,"#c9a24a","grain"),
 ("porridge","Getreidebrei","Grain Porridge",12,"#b89a6a","bowl"),
 ("furs","Fellkleidung","Fur Clothing",18,"#6b4a2e","cloth"),
 ("flint","Feuerstein","Flint",7,"#4d5560","stone"),
 ("tools","Steinwerkzeug","Stone Tools",16,"#5b6168","axe"),
 ("honey","Honig","Honey",22,"#e0a12c","drop"),
 ("emmer","Emmer","Emmer Wheat",7,"#d6b04e","grain"),
 ("straw","Stroh","Straw",3,"#e6d08a","grain"),
 ("flour","Mehl","Flour",12,"#efe4cc","bowl"),
 ("bread","Fladenbrot","Flatbread",20,"#c48a44","bread"),
 ("clay","Lehm","Clay",4,"#b0683c","lump"),
 ("bricks","Lehmziegel","Mud Bricks",14,"#a8643a","bar"),
 ("herbs","Kräuter","Herbs",18,"#4f7a3a","leaf"),
 ("pottery","Keramik","Pottery",24,"#c0703e","pot"),
 ("flax","Flachs","Flax",8,"#8aa070","leaf"),
 ("linen","Leinen","Linen",28,"#e2d6b8","cloth"),
 ("rope","Seile","Rope",14,"#b89a6a","ring"),
 ("barley","Gerste","Barley",7,"#c8a860","grain"),
 ("malt","Malz","Malt",10,"#a8743a","grain"),
 ("beer","Bier","Beer",34,"#c78a1c","pot"),
 ("obsidian","Obsidian","Obsidian",16,"#2a2a34","stone"),
 ("jewelry","Obsidianschmuck","Obsidian Jewellery",48,"#3a3048","ring"),
 ("copperore","Kupfererz","Copper Ore",12,"#4f8a7a","stone"),
 ("charcoal","Holzkohle","Charcoal",8,"#2e2a28","lump"),
 ("copper","Kupfer","Copper",30,"#c06a3a","bar"),
 ("coppertools","Kupfergeräte","Copper Tools",42,"#b0602e","axe"),
 ("milk","Milch","Milk",10,"#f2efe6","drop"),
 ("cheese","Käse","Cheese",32,"#e8c860","bread"),
 ("wool","Wolle","Wool",10,"#e8e0d0","cloth"),
 ("woolcloth","Wollkleidung","Woollen Clothing",40,"#7a5a8a","cloth"),
 ("grapes","Trauben","Grapes",10,"#5a1838","berries"),
 ("wine","Wein","Wine",52,"#6a1838","pot"),
 ("planks","Bretter","Planks",14,"#b08050","log"),
 ("wheels","Räder","Wheels",60,"#8a6a46","wheel"),
 ("tin","Zinn","Tin",30,"#9aa4a8","bar"),
 ("bronzeware","Bronzeschmuck","Bronze Finery",120,"#a87a34","ring"),
]
json.dump([{"id":g[0],"name":T(g[1],g[2]),"value":g[3],"color":g[4],"glyph":g[5]} for g in goods], open(OUT+"goods.json","w"), ensure_ascii=False, indent=1)

fert = [("berries","Beerensträucher","Berry Bushes","#7a2348"),("hazel","Haselsträucher","Hazel","#a8743a"),
 ("deer","Rotwild","Red Deer","#9a6a3a"),("fish","Fischgründe","Fishing Grounds","#5f8ea0"),("clay","Lehmboden","Clay Soil","#b0683c"),
 ("wildgrain","Wildes Getreide","Wild Cereals","#c9a24a"),("flax","Wilder Flachs","Wild Flax","#8aa070"),("herbs","Heilkräuter","Herbs","#4f7a3a"),
 ("honey","Wildbienen","Wild Bees","#e0a12c"),("aurochs","Auerochsen","Aurochs","#5a3a2a"),("mouflon","Wildschafe & Wildziegen","Wild Sheep & Goats","#d8cbb0"),
 ("grapes","Wilde Reben","Wild Vines","#5a1838")]
json.dump([{"id":f[0],"name":T(f[1],f[2]),"color":f[3]} for f in fert], open(OUT+"fertilities.json","w"), ensure_ascii=False, indent=1)

def need(i,k,c=None,r=None,inc=0,at=0):
    """A need of a tier. `at`: the need only matters once this many people of the tier live in all valleys
    (Anno-style: new wishes appear as the population grows)."""
    d={"id":i,"kind":k}
    if c is not None: d["consumption"]=c
    if r is not None: d["residents"]=r
    d["income"]=inc
    if at: d["at"]=at
    return d
tiers = [
 {"id":"foragers","name":T("Wildbeuter","Foragers"),"age":T("Späte Altsteinzeit · um 13.000 v. Chr.","Late Palaeolithic · c. 13,000 BC"),
  "house":"tent","baseResidents":1,"color":"#9a7a4a","upgradeCost":{},
  "intro":T("Kleine Gruppen ziehen den Herden und den Jahreszeiten hinterher. Jagd, Beeren, Feuer – mehr braucht es nicht.","Small bands follow the herds and the seasons. Hunting, berries, fire – nothing more is needed."),
  "history":T("Bis vor rund 12.000 Jahren lebten alle Menschen als Jäger und Sammler. Sie kannten Hunderte essbare Pflanzen, aber sie pflanzten nichts an.","Until about 12,000 years ago all humans lived as hunter-gatherers. They knew hundreds of edible plants, but planted none."),
  "needs":[need("berries","basic",0.07,1,0.55),need("fireplace","service",None,1,0.3),need("meat","basic",0.05,1,0.55,12),need("nuts","luxury",0.04,None,0.7,30)]},
 {"id":"sedentary","name":T("Sesshafte Sammler","Settled Foragers"),"age":T("Natufien · um 12.000 v. Chr.","Natufian · c. 12,000 BC"),
  "house":"hut","baseResidents":2,"color":"#8a5a2a","upgradeCost":{"wood":4,"hides":2,"stone":2},
  "intro":T("Wo wildes Getreide dicht steht, lohnt es sich zu bleiben. Runde Grubenhäuser, Sicheln aus Feuerstein, Vorratsgruben – und die Toten werden unter dem Haus bestattet.","Where wild cereals grow thick, it pays to stay. Round pit houses, flint sickles, storage pits – and the dead are buried beneath the house."),
  "history":T("Sesshaftigkeit kam vor dem Ackerbau: Die Natufier in der Levante lebten das ganze Jahr in Dörfern, ernteten aber noch wildes Getreide.","Settling down came before farming: the Natufians of the Levant lived in villages all year round but still harvested wild cereals."),
  "needs":[need("meat","basic",0.05,1,0.6),need("porridge","basic",0.06,2,0.7),need("fish","basic",0.05,1,0.6,10),need("furs","basic",0.03,1,0.7,20),need("shaman","service",None,1,0.3,40),need("ancestors","service-luxury",None,None,0.6,40),need("honey","luxury",0.03,None,1.0,60)]},
 {"id":"farmers","name":T("Erste Bauern","First Farmers"),"age":T("Frühes Neolithikum · um 9.000 v. Chr.","Early Neolithic · c. 9,000 BC"),
  "house":"cottage","baseResidents":3,"color":"#a0603a","upgradeCost":{"wood":4,"tools":3,"stone":3},
  "intro":T("Aus Sammeln wird Säen: Emmer und Gerste werden angebaut, Ziegen und Schafe gezähmt. Eckige Lehmziegelhäuser drängen sich aneinander.","Gathering turns into sowing: emmer and barley are cultivated, goats and sheep tamed. Rectangular mud-brick houses crowd together."),
  "history":T("Zuerst wurden Pflanzen domestiziert (um 9500 v. Chr.), wenig später Ziegen und Schafe. Keramik gab es noch nicht – man spricht vom präkeramischen Neolithikum.","Plants were domesticated first (c. 9500 BC), goats and sheep a little later. There was no pottery yet – the Pre-Pottery Neolithic."),
  "needs":[need("meat","basic",0.05,2,0.85),need("furs","basic",0.03,2,0.9),need("bread","basic",0.07,3,1.05,1),need("shrine","service",None,2,0.5,60),need("herbs","luxury",0.03,None,1.4,60),need("dance","service-luxury",None,None,0.85,100)]},
 {"id":"villagers","name":T("Dorfgemeinschaft","Village Folk"),"age":T("Keramisches Neolithikum · um 7.000 v. Chr.","Pottery Neolithic · c. 7,000 BC"),
  "house":"longhouse","baseResidents":4,"color":"#8a4a3a","upgradeCost":{"bricks":5,"tools":2,"wood":2},
  "intro":T("Töpfe aus gebranntem Ton, Leinen vom Webstuhl, Bier aus Gerste. Dörfer wachsen zu Hunderten Menschen, Obsidian wird über weite Wege gehandelt.","Pots of fired clay, linen from the loom, beer from barley. Villages grow to hundreds of people, obsidian travels far along trade paths."),
  "history":T("Um 7000 v. Chr. verbreitet sich Keramik. Siedlungen wie Çatalhöyük zählen Tausende Bewohner; Flachs wird zu Leinen verwebt.","Around 7000 BC pottery spreads. Settlements like Çatalhöyük number thousands; flax is woven into linen."),
  "needs":[need("bread","basic",0.06,3,1.6),need("pottery","basic",0.03,3,2.0),need("shrine","service",None,2,0.8),need("linen","basic",0.03,3,2.0,20),need("square","service",None,1,0.6,1),need("beer","luxury",0.04,None,2.6,50),need("jewelry","luxury",0.02,None,3.0,150)]},
 {"id":"chieftains","name":T("Kupferzeitliche Sippen","Copper Age Clans"),"age":T("Kupferzeit · um 4.500 v. Chr.","Copper Age · c. 4,500 BC"),
  "house":"farmstead","baseResidents":5,"color":"#b07a3a","upgradeCost":{"bricks":6,"pottery":3},
  "intro":T("Kupfer wird geschmolzen, Rinder ziehen den Hakenpflug, Schafe geben Wolle, Kühe Milch. Mit dem Rad beginnt eine neue Zeit – und am Horizont glänzt die Bronze.","Copper is smelted, oxen pull the ard, sheep give wool and cows milk. The wheel starts a new era – and bronze gleams on the horizon."),
  "history":T("Die ‚Revolution der Sekundärprodukte‘: Tiere werden nicht nur gegessen, sondern gemolken, geschoren und eingespannt. Um 3500 v. Chr. erscheint das Rad, kurz danach die Bronze aus Kupfer und Zinn.","The 'secondary products revolution': animals are not only eaten but milked, shorn and harnessed. The wheel appears around 3500 BC, bronze from copper and tin shortly after."),
  "needs":[need("bread","basic",0.05,2,1.5),need("coppertools","basic",0.02,3,2.6),need("square","service",None,2,0.8),need("cheese","basic",0.05,3,2.2,30),need("woolcloth","basic",0.03,3,2.4,60),need("wine","luxury",0.03,None,3.2,100),need("bronzeware","luxury",0.015,None,4.5,150),need("megalith","service-luxury",None,None,2.0,200)]},
]
json.dump(tiers, open(OUT+"tiers.json","w"), ensure_ascii=False, indent=1)

B=[]
def b(id,de,en,cat,size,style,accent,tier,cost,upkeep=0,desc=("",""),**kw):
    d={"id":id,"name":T(de,en),"category":cat,"size":[size,size],"style":style,"accent":accent,"unlockTier":tier,"cost":cost,"upkeep":upkeep}
    d.update(kw); d["desc"]=T(*desc); B.append(d)
def prod(id,de,en,size,style,accent,tier,cost,upkeep,wf,cycle,inputs,outputs,desc,req=None):
    kw={"workforce":{"tier":wf[0],"amount":wf[1]},"cycle":cycle,"outputs":outputs}
    if inputs: kw["inputs"]=inputs
    if req: kw["requires"]=req
    b(id,de,en,"production",size,style,accent,tier,cost,upkeep,desc,**kw)
def serv(id,de,en,size,style,accent,tier,cost,upkeep,sid,radius,desc,wf=None):
    kw={"service":{"id":sid,"radius":radius}}
    b(id,de,en,"service",size,style,accent,tier,cost,upkeep,desc,**kw)
def house(id,de,en,style,accent,tier,buildable,cost,desc):
    kw={}
    if not buildable: kw["buildable"]=False
    b(id,de,en,"residence",2,style,accent,tier,cost,0,desc,**kw)
    B[-1]["tier"]=tier

b("storage","Lagerplatz","Storage Yard","infrastructure",3,"storage","#8a5a32","foragers",{"shells":300,"wood":20},0,
  ("Herz eines Tals: Alle Betriebe müssen über Pfade mit ihm verbunden sein. In einem neuen Tal gründet er die Siedlung – dafür muss ein begehbarer Pfad dorthin führen.","Heart of a valley: every workplace must connect to it by paths. In a new valley it founds the settlement – which needs a passable path leading there."))
b("path","Trampelpfad","Footpath","infrastructure",1,"path","#a88a5a","foragers",{"shells":2},0,("Verbindet Häuser und Betriebe mit dem Lagerplatz.","Connects homes and workplaces to the storage yard."))
b("scout","Kundschafterlager","Scout Camp","infrastructure",2,"scout","#3a6a8a","foragers",{"shells":150,"wood":8},5,("Schickt Kundschafter über unbekannte Bergpfade (Proviant: 5 Fleisch). Kundschafter überwinden jedes Hindernis – Karawanen nicht.","Sends scouts across unknown mountain paths (provisions: 5 meat). Scouts cross any obstacle – caravans do not."))
b("caravanpost","Rastplatz","Caravan Camp","infrastructure",3,"caravan","#a8743a","sedentary",{"shells":400,"wood":12,"hides":4},10,
  ("Ausgangspunkt der Karawanen – das Gegenstück zu Hafen und Werft. Muss nahe am Fuß eines Bergpfads liegen. Hier werden Trägertrupps, Eselkarawanen und Ochsenkarren ausgerüstet.","Home of the caravans – the counterpart to harbour and shipyard. Must lie near the foot of a mountain path. Porter teams, donkey trains and ox carts are equipped here."),
  requires={"nearPass":4})

house("tent","Fellkuppel","Hide Dome","tent","#b48a5c","foragers",True,{"wood":3},("Runde Kuppel aus Weidenruten und Häuten – Wohnstatt der Wildbeuter. Du wertest sie selbst zum Grubenhaus auf, sobald die Sesshaften freigeschaltet sind, die Bewohner zufrieden sind und Holz, Häute und Feldsteine im Lager liegen.","Round dome of willow rods and hides – home of the foragers. You upgrade it yourself to a pit house once settled foragers are unlocked, the residents are content and wood, hides and fieldstones are in storage."))
house("hut","Grubenhaus","Pit House","hut","#7a5a3a","sedentary",False,{},("Rundes, halb eingetieftes Haus der Natufier mit Steinfundament.","Round, half-sunken Natufian house with a stone footing."))
house("cottage","Lehmziegelhaus","Mud-Brick House","mudhouse","#c08a5a","farmers",False,{},("Eckiges Haus aus luftgetrockneten Lehmziegeln mit Flachdach.","Rectangular house of sun-dried mud bricks with a flat roof."))
house("longhouse","Langhaus","Longhouse","longhouse","#9a7a4a","villagers",False,{},("Großes Haus für eine ganze Familie samt Vorräten.","Large house for a whole family and its stores."))
house("farmstead","Gehöft","Farmstead","farmstead","#8a6a3a","chieftains",False,{},("Hof mit Stall und Speicher – der Sitz einer kupferzeitlichen Sippe.","Farm with byre and granary – seat of a Copper Age clan."))

# services
serv("fireplace","Lagerfeuer","Campfire",2,"fire","#e0702a","foragers",{"shells":60,"wood":4},4,"fireplace",10,("Wärme, Licht und Geschichten. Versorgt die Zelte im Umkreis.","Warmth, light and stories. Serves the tents around it."))
serv("shaman","Schamanenplatz","Shaman's Place",2,"totem","#5a3a6a","sedentary",{"shells":150,"wood":8,"hides":2},10,"shaman",13,("Heilkunde und Geisterglaube.","Healing lore and the spirit world."))
serv("ancestors","Ahnenstätte","Ancestor Shrine",2,"mound","#7a6a5a","sedentary",{"shells":250,"wood":10,"tools":2},12,"ancestors",12,("Hier ehrt man die Toten – die Natufier bestatteten sie unter den Häusern und schmückten Schädel.","Here the dead are honoured – Natufians buried them beneath their houses and adorned skulls."))
serv("shrine","Heiligtum","Sanctuary",3,"tpillars","#8a7a6a","farmers",{"shells":400,"wood":10,"tools":4},18,"shrine",16,("Ein Kreis aus T-förmigen Steinpfeilern mit Tierreliefs, wie am Göbekli Tepe.","A ring of T-shaped stone pillars carved with animals, as at Göbekli Tepe."))
serv("dance","Festplatz","Feasting Ground",2,"dance","#c0502a","farmers",{"shells":300,"wood":8,"tools":2},12,"dance",13,("Gemeinsame Feste mit Musik und Tanz stärken das Dorf.","Shared feasts with music and dance bind the village."))
serv("square","Dorfplatz","Village Square",3,"square","#8a7a4a","villagers",{"shells":500,"bricks":8,"tools":4},20,"square",17,("Treffpunkt, Tauschplatz, Brunnen.","Meeting place, barter ground, well."))
serv("megalith","Großsteingrab","Megalithic Tomb",3,"dolmen","#7a7a7a","chieftains",{"shells":1200,"bricks":10,"coppertools":4},40,"megalith",20,("Riesige Steine für die Ahnen der Sippe – sichtbar über das ganze Tal.","Giant stones for the clan's ancestors – visible across the whole valley."))

# production T1
prod("woodcutter","Holzfäller","Woodcutter",2,"workshop","#8a5a32","foragers",{"shells":50,"wood":2},5,("foragers",3),15,None,{"wood":1},("Fällt Bäume im Umkreis.","Fells trees nearby."),{"nature":{"kind":"tree","radius":4,"min":6}})
prod("berrygatherer","Beerensammler","Berry Gatherer",2,"basket","#7a2348","foragers",{"shells":40,"wood":2},3,("foragers",3),20,None,{"berries":1},("Sammelt Beeren an den Sträuchern.","Picks berries from the bushes."),{"fertility":"berries","nature":{"kind":"bush","radius":4,"min":4}})
prod("hunter","Jagdlager","Hunting Camp",2,"lean","#a33a2c","foragers",{"shells":60,"wood":3},5,("foragers",4),24,None,{"meat":1},("Jäger pirschen im Wald.","Hunters stalk the forest."),{"fertility":"deer","nature":{"kind":"tree","radius":5,"min":6}})
prod("trapper","Fallensteller","Trapper",2,"rack","#b48a5c","foragers",{"shells":60,"wood":3},4,("foragers",3),30,None,{"hides":1},("Fängt Pelztiere für Häute.","Traps animals for hides."),{"nature":{"kind":"tree","radius":5,"min":5}})
prod("nutgatherer","Haselsammler","Hazel Gatherer",2,"basket","#a8743a","foragers",{"shells":60,"wood":3},4,("foragers",3),30,None,{"nuts":1},("Sammelt Haselnüsse.","Gathers hazelnuts."),{"fertility":"hazel","nature":{"kind":"bush","radius":4,"min":3}})
prod("stonegatherer","Steinsammler","Stone Gatherer",2,"stones","#9c93ab","foragers",{"shells":60,"wood":4},3,("foragers",2),24,None,{"stone":1},("Liest Feldsteine am Fuß der Berge auf – für Herdringe, Fundamente und das Grubenhaus.","Gathers fieldstones at the foot of the mountains – for hearth rings, footings and the pit house."),{"nearMountain":3})
# T2
prod("fisher","Fischerplatz","Fishing Spot",2,"fisher","#5f8ea0","sedentary",{"shells":120,"wood":6},6,("sedentary",3),20,None,{"fish":1},("Reusen und Speere am Ufer.","Fish traps and spears at the shore."),{"fertility":"fish","nearWater":1})
prod("graingatherer","Wildgetreide-Ernte","Wild Grain Harvest",2,"basket","#c9a24a","sedentary",{"shells":120,"wood":6},6,("sedentary",4),20,None,{"wildgrain":1},("Erntet wilde Gerste und Einkorn mit Feuersteinsicheln.","Harvests wild barley and einkorn with flint sickles."),{"fertility":"wildgrain"})
prod("grinder","Mahlplatz","Grinding Place",2,"quern","#b89a6a","sedentary",{"shells":120,"wood":6},6,("sedentary",3),20,{"wildgrain":1},{"porridge":1},("Mahlsteine machen aus Körnern Brei.","Grinding stones turn grain into porridge."))
prod("tanner","Gerberei","Tannery",2,"rack","#6b4a2e","sedentary",{"shells":120,"wood":6},6,("sedentary",3),30,{"hides":1},{"furs":1},("Gerbt Häute zu warmer Kleidung.","Tans hides into warm clothing."))
prod("flintquarry","Feuersteinbruch","Flint Quarry",2,"pit","#4d5560","sedentary",{"shells":150,"wood":8},8,("foragers",3),20,None,{"flint":1},("Muss auf einem Feuersteinvorkommen stehen. Feuerstein schlagen konnten schon die Wildbeuter.","Must stand on a flint deposit. Foragers already knew how to knap flint."),{"deposit":"flint"})
prod("toolmaker","Werkzeugmacher","Toolmaker",2,"workshop","#5b6168","sedentary",{"shells":150,"wood":8},8,("foragers",3),30,{"flint":1,"wood":1},{"tools":1},("Schlägt Klingen und Beile – Baumaterial ab den Ersten Bauern.","Knaps blades and axes – a building material from the First Farmers on."))
prod("beekeeper","Zeidlerei","Honey Hunter",2,"basket","#e0a12c","sedentary",{"shells":150,"wood":6},6,("sedentary",2),40,None,{"honey":1},("Sammelt Honig wilder Bienen in hohlen Bäumen.","Collects wild honey from hollow trees."),{"fertility":"honey","nature":{"kind":"tree","radius":4,"min":4}})
# T3
prod("emmerfield","Emmerfeld","Emmer Field",3,"field","#d6b04e","farmers",{"shells":200,"wood":6,"tools":2},8,("farmers",4),30,None,{"emmer":1,"straw":1},("Domestizierter Weizen – braucht wildes Getreide als Fruchtbarkeit.","Domesticated wheat – needs wild cereals as a fertility."),{"fertility":"wildgrain"})
prod("mill","Mahlsteinhaus","Quern House",2,"quern","#efe4cc","farmers",{"shells":200,"wood":6,"tools":2},8,("farmers",3),20,{"emmer":1},{"flour":1},("Mahlt Emmer zu Mehl.","Grinds emmer into flour."))
prod("bakery","Backofen","Bread Oven",2,"kiln","#c48a44","farmers",{"shells":200,"wood":6,"tools":2},8,("farmers",3),30,{"flour":1,"wood":1},{"bread":2},("Bäckt Fladenbrot auf heißen Steinen.","Bakes flatbread on hot stones."))
prod("goatfarm","Ziegenpferch","Goat Pen",3,"pasture","#d8cbb0","farmers",{"shells":200,"wood":8,"tools":2},8,("farmers",3),40,None,{"meat":1,"hides":1},("Gezähmte Ziegen liefern Fleisch und Häute – braucht Wildziegen im Tal.","Tamed goats give meat and hides – needs wild goats in the valley."),{"fertility":"mouflon"})
prod("claypit","Lehmgrube","Clay Pit",2,"pit","#b0683c","farmers",{"shells":150,"wood":6},6,("farmers",3),20,None,{"clay":1},("Sticht Lehm.","Digs clay."),{"fertility":"clay"})
prod("brickmaker","Ziegelstreicher","Brick Maker",2,"rack","#a8643a","farmers",{"shells":200,"wood":6,"tools":2},8,("farmers",3),30,{"clay":1,"straw":1},{"bricks":1},("Formt Lehm und Stroh zu Ziegeln und trocknet sie in der Sonne.","Shapes clay and straw into bricks and dries them in the sun."))
prod("herbalist","Kräutergarten","Herb Garden",2,"basket","#4f7a3a","farmers",{"shells":200,"wood":6,"tools":2},8,("farmers",2),30,None,{"herbs":1},("Heil- und Würzkräuter.","Healing and seasoning herbs."),{"fertility":"herbs"})
# T4
prod("potter","Töpferei","Pottery Kiln",2,"kiln","#c0703e","farmers",{"shells":300,"bricks":4,"tools":2},12,("farmers",4),30,{"clay":1,"wood":1},{"pottery":1},("Brennt Gefäße aus Ton.","Fires vessels of clay."))
prod("flaxfield","Flachsfeld","Flax Field",3,"field","#8aa070","villagers",{"shells":250,"wood":6,"tools":2},8,("villagers",3),30,None,{"flax":1},("Braucht wilden Flachs als Fruchtbarkeit.","Needs wild flax as a fertility."),{"fertility":"flax"})
prod("weaver","Webstube","Loom House",2,"loom","#e2d6b8","villagers",{"shells":300,"bricks":4,"tools":2},12,("villagers",4),30,{"flax":1},{"linen":1},("Webt Leinen auf dem Gewichtswebstuhl.","Weaves linen on the warp-weighted loom."))
prod("ropemaker","Seilerei","Ropewalk",2,"rack","#b89a6a","villagers",{"shells":250,"bricks":2,"tools":2},10,("villagers",3),30,{"flax":1},{"rope":2},("Dreht Seile – für Brücken, Fähren und Karawanen.","Twists rope – for bridges, ferries and caravans."))
prod("barleyfield","Gerstenfeld","Barley Field",3,"field","#c8a860","villagers",{"shells":250,"wood":6,"tools":2},8,("villagers",3),30,None,{"barley":1},("Braucht wildes Getreide als Fruchtbarkeit.","Needs wild cereals as a fertility."),{"fertility":"wildgrain"})
prod("malthouse","Mälzerei","Malt House",2,"rack","#a8743a","villagers",{"shells":250,"bricks":3,"tools":2},10,("villagers",3),20,{"barley":1},{"malt":1},("Lässt Gerste keimen und darrt sie.","Sprouts and kilns barley."))
prod("brewery","Brauhaus","Brewhouse",2,"kiln","#c78a1c","villagers",{"shells":350,"bricks":4,"tools":2},14,("villagers",3),40,{"malt":1,"pottery":1},{"beer":2},("Braut Bier in großen Tonkrügen.","Brews beer in large clay jars."))
prod("obsidianquarry","Obsidianabbau","Obsidian Diggings",2,"pit","#2a2a34","villagers",{"shells":300,"bricks":2,"tools":3},12,("villagers",3),30,None,{"obsidian":1},("Muss auf einem Obsidianvorkommen stehen.","Must stand on an obsidian deposit."),{"deposit":"obsidian"})
prod("jeweler","Schmuckschleifer","Bead Maker",2,"workshop","#3a3048","villagers",{"shells":400,"bricks":4,"tools":2},14,("villagers",2),40,{"obsidian":1},{"jewelry":1},("Schleift Obsidian zu Spiegeln und Perlen.","Grinds obsidian into mirrors and beads."))
# T5
prod("coppermine","Kupferbergwerk","Copper Mine",2,"pit","#4f8a7a","chieftains",{"shells":500,"bricks":6,"tools":4},16,("villagers",4),30,None,{"copperore":1},("Muss auf einem Kupfervorkommen stehen.","Must stand on a copper deposit."),{"deposit":"copper"})
prod("charcoal","Köhlerei","Charcoal Burner",2,"kiln","#2e2a28","chieftains",{"shells":300,"bricks":4,"tools":2},10,("villagers",3),30,{"wood":2},{"charcoal":1},("Verkohlt Holz im Meiler.","Turns wood into charcoal in a clamp."),{"nature":{"kind":"tree","radius":4,"min":4}})
prod("smelter","Schmelzofen","Smelting Furnace",2,"kiln","#c06a3a","chieftains",{"shells":600,"bricks":8,"tools":4},18,("chieftains",3),40,{"copperore":1,"charcoal":1},{"copper":1},("Schmilzt Kupfer aus dem Erz.","Smelts copper from the ore."))
prod("coppersmith","Kupferschmiede","Coppersmith",2,"workshop","#b0602e","chieftains",{"shells":600,"bricks":8,"tools":4},18,("chieftains",3),40,{"copper":1,"wood":1},{"coppertools":1},("Treibt Beile, Ahlen und Dolche aus Kupfer.","Hammers axes, awls and daggers from copper."))
prod("cattlefarm","Rinderweide","Cattle Pasture",3,"pasture","#7a5a3a","chieftains",{"shells":500,"bricks":4,"tools":4},14,("villagers",3),30,None,{"milk":1},("Gezähmte Auerochsen geben Milch – braucht Auerochsen im Tal.","Tamed aurochs give milk – needs aurochs in the valley."),{"fertility":"aurochs"})
prod("dairy","Käserei","Cheese Dairy",2,"kiln","#e8c860","chieftains",{"shells":500,"bricks":6,"tools":2},14,("chieftains",3),40,{"milk":1,"pottery":1},{"cheese":2},("Lässt Milch in Siebgefäßen zu Käse reifen.","Turns milk into cheese in strainer pots."))
prod("sheepfarm","Schafweide","Sheep Pasture",3,"pasture","#e8e0d0","chieftains",{"shells":500,"bricks":4,"tools":4},14,("villagers",3),30,None,{"wool":1},("Wollschafe – braucht Wildschafe im Tal.","Wool sheep – needs wild sheep in the valley."),{"fertility":"mouflon"})
prod("woolweaver","Wollweberei","Wool Weaver",2,"loom","#7a5a8a","chieftains",{"shells":600,"bricks":6,"tools":4},16,("chieftains",3),40,{"wool":1},{"woolcloth":1},("Spinnt und webt Wolle.","Spins and weaves wool."))
prod("vineyard","Rebgarten","Vineyard",3,"field","#5a1838","chieftains",{"shells":500,"bricks":4,"tools":4},12,("villagers",3),40,None,{"grapes":1},("Braucht wilde Reben als Fruchtbarkeit.","Needs wild vines as a fertility."),{"fertility":"grapes"})
prod("winery","Kelterei","Wine Press",2,"kiln","#6a1838","chieftains",{"shells":700,"bricks":6,"tools":4},18,("chieftains",3),40,{"grapes":1,"pottery":1},{"wine":1},("Keltert Wein und füllt ihn in Krüge.","Presses wine and fills it into jars."))
prod("carpenter","Zimmerei","Carpenter",2,"workshop","#b08050","chieftains",{"shells":500,"bricks":6,"tools":4},14,("chieftains",2),30,{"wood":2,"coppertools":0.25},{"planks":2},("Spaltet Bretter mit Kupferbeilen – für Bohlenwege und Wagen.","Splits planks with copper axes – for plank roads and carts."))
prod("wheelwright","Stellmacher","Wheelwright",2,"workshop","#8a6a46","chieftains",{"shells":800,"bricks":6,"coppertools":2},20,("chieftains",3),60,{"planks":2,"coppertools":0.5},{"wheels":1},("Baut Scheibenräder – die neueste Erfindung!","Builds disc wheels – the latest invention!"))
prod("tinmine","Zinnbergwerk","Tin Mine",2,"pit","#9aa4a8","chieftains",{"shells":700,"bricks":6,"coppertools":2},20,("villagers",4),40,None,{"tin":1},("Muss auf einem Zinnvorkommen stehen. Zinn ist selten – nur hinter dem Gletscher.","Must stand on a tin deposit. Tin is rare – only beyond the glacier."),{"deposit":"tin"})
prod("bronzesmith","Bronzegießer","Bronze Caster",2,"kiln","#a87a34","chieftains",{"shells":1500,"bricks":10,"coppertools":4},30,("chieftains",4),60,{"copper":1,"tin":1},{"bronzeware":1},("Legiert Kupfer mit Zinn – die Bronzezeit beginnt.","Alloys copper with tin – the Bronze Age begins."))

# special, storage and decoration buildings
b("hearth","Talherz","Valley Heart","special",3,"hearth","#c0602e","foragers",{"shells":100,"wood":10},0,
  ("Das Herz deines Tals: ein großer Herdring aus bemalten Steinen. Hier feiert ihr Feste, hier ruhen eure Kostbarkeiten (3 Nischen) – und hier versammeln sich die Ältesten. Nur eines je Tal.","The heart of your valley: a great hearth ring of painted stones. Here you hold festivals, here your treasures rest (3 niches) – and here the elders gather. Only one per valley."),
  unique=True,beauty={"value":4,"radius":9})
b("storagepit","Vorratsgrube","Storage Pit","storage",2,"storepit","#a8743a","foragers",{"shells":60,"wood":4,"stone":4},2,
  ("Eine mit Steinen ausgekleidete Grube unter einem Deckel aus Ästen. +20 Lagerplatz je Ware im Tal; Beeren verderben nur halb so schnell.","A stone-lined pit under a lid of branches. +20 storage per good in the valley; berries spoil only half as fast."),
  store={"cap":20,"protect":["berries"]})
b("smokehouse","Räucherhütte","Smokehouse","storage",2,"smoke","#8a5a3a","foragers",{"shells":80,"wood":6,"stone":2},3,
  ("Über schwelendem Feuer halten sich Fleisch und Fisch viel länger: Sie verderben im ganzen Tal nur halb so schnell.","Over smouldering fire meat and fish keep much longer: in the whole valley they spoil only half as fast."),
  store={"cap":0,"protect":["meat","fish"]})
b("granary","Speicher auf Stelzen","Stilted Granary","storage",2,"granary","#c9a24a","farmers",{"shells":200,"wood":8,"bricks":2},4,
  ("Auf Stelzen, damit keine Maus hinaufkommt. +20 Lagerplatz je Ware; Nüsse und Getreide verderben nur halb so schnell.","On stilts so no mouse gets in. +20 storage per good; nuts and grain spoil only half as fast."),
  store={"cap":20,"protect":["nuts","wildgrain","emmer","barley","flour","porridge","bread"]})
b("gardenbed","Blütenwiese","Flower Patch","decoration",1,"flowers","#d26a8a","foragers",{"shells":20,"stone":1},0,
  ("Wilde Blumen, mit Steinen eingefasst. Schönheit hebt die Stimmung der Häuser im Umkreis.","Wild flowers framed by stones. Beauty lifts the mood of homes nearby."),
  beauty={"value":2,"radius":5})
b("paintedstone","Bemalter Stein","Painted Stone","decoration",1,"menhir","#c0602e","villagers",{"shells":40,"stone":3},0,
  ("Ein aufrechter Stein mit Ocker-Spiralen und Handabdrücken.","An upright stone with ochre spirals and handprints."),
  beauty={"value":3,"radius":6})
b("totempost","Ahnenpfahl","Ancestor Post","decoration",1,"post","#8a3a32","villagers",{"shells":60,"wood":4},0,
  ("Ein geschnitzter Pfahl mit den Zeichen der Sippen.","A carved post bearing the signs of the clans."),
  beauty={"value":4,"radius":6})
prod("trialbed","Versuchsbeet","Trial Plot",2,"field","#d6b04e","sedentary",{"shells":120,"wood":4,"stone":2},2,("sedentary",2),75,None,{"emmer":1},
  ("Selas Experiment: die dicksten Körner zurückbehalten und aussäen. Wächst im Frühling, reift im Herbst, ruht im Winter.","Sela's experiment: keep back the fattest grains and sow them. Grows in spring, ripens in autumn, rests in winter."),{"fertility":"wildgrain"})

# Which buildings are available from the start, which open at a population mark of their tier,
# and which a character hands over with a quest (see quests below).
UNLOCK = {
 "storage":{"start":True},"path":{"start":True},
 "gardenbed":{"pop":["foragers",20]},
 "fisher":{"pop":["sedentary",10]},"tanner":{"pop":["sedentary",20]},"beekeeper":{"pop":["sedentary",60]},
 "emmerfield":{"pop":["farmers",1]},"mill":{"pop":["farmers",1]},"bakery":{"pop":["farmers",1]},"granary":{"pop":["farmers",1]},
 "claypit":{"pop":["farmers",20]},"brickmaker":{"pop":["farmers",20]},"herbalist":{"pop":["farmers",60]},"shrine":{"pop":["farmers",60]},"dance":{"pop":["farmers",100]},
 "flaxfield":{"pop":["villagers",20]},"weaver":{"pop":["villagers",20]},"barleyfield":{"pop":["villagers",50]},"malthouse":{"pop":["villagers",50]},
 "brewery":{"pop":["villagers",50]},"ropemaker":{"pop":["villagers",80]},"obsidianquarry":{"pop":["villagers",150]},"jeweler":{"pop":["villagers",150]},
 "coppersmith":{"pop":["chieftains",1]},"cattlefarm":{"pop":["chieftains",30]},"dairy":{"pop":["chieftains",30]},"sheepfarm":{"pop":["chieftains",60]},
 "woolweaver":{"pop":["chieftains",60]},"vineyard":{"pop":["chieftains",100]},"winery":{"pop":["chieftains",100]},"carpenter":{"pop":["chieftains",150]},
 "wheelwright":{"pop":["chieftains",150]},"megalith":{"pop":["chieftains",200]},
}
# Production groups drive seasons, spirits, items and customs.
GROUP = {
 "woodcutter":"wood","berrygatherer":"gather","nutgatherer":"gather","graingatherer":"gather","beekeeper":"gather","herbalist":"gather","stonegatherer":"stone",
 "hunter":"hunt","trapper":"hunt","fisher":"fish","emmerfield":"field","barleyfield":"field","flaxfield":"field","vineyard":"field","trialbed":"field",
 "goatfarm":"pasture","cattlefarm":"pasture","sheepfarm":"pasture","grinder":"mill","mill":"mill",
}
NOISE = {"tanner":5,"charcoal":5,"smelter":6,"potter":4,"coppersmith":5,"bronzesmith":6,"brickmaker":3}
for d in B:
    if d["id"] in UNLOCK: d["unlock"]=UNLOCK[d["id"]]
    if d["id"] in GROUP: d["group"]=GROUP[d["id"]]
    elif d["category"]=="production": d["group"]="workshop"
    if d["id"] in NOISE: d["noise"]={"value":NOISE[d["id"]],"radius":5}
json.dump(B, open(OUT+"buildings.json","w"), ensure_ascii=False, indent=1)

V = [
 {"id":"main","name":T("Tal der Ersten","Valley of the First"),"size":1.55,"home":True,"ring":0,"angle":0,
  "fertilities":["berries","hazel","deer","fish","clay","wildgrain"],"deposits":[],"water":"lake"},
 {"id":"flint","name":T("Feuersteinschlucht","Flint Gorge"),"size":1.0,"ring":1,"angle":0,"fertilities":["deer","herbs","berries"],"deposits":["flint","flint","flint"],"water":"stream"},
 {"id":"bees","name":T("Bienental","Bee Valley"),"size":1.1,"ring":1,"angle":60,"fertilities":["honey","wildgrain","berries","fish"],"deposits":["copper"],"water":"lake"},
 {"id":"flax","name":T("Flachsaue","Flax Meadow"),"size":1.15,"ring":1,"angle":120,"fertilities":["flax","clay","fish","hazel"],"deposits":[],"water":"stream"},
 {"id":"aurochs","name":T("Auerochsenweide","Aurochs Pasture"),"size":1.2,"ring":1,"angle":180,"fertilities":["aurochs","wildgrain","deer","clay"],"deposits":["copper","copper"],"water":"stream"},
 {"id":"rival","name":T("Graufels","Greyrock"),"size":1.05,"ring":1,"angle":240,"rival":"aruk","fertilities":["berries","deer","fish","clay"],"deposits":["flint"],"water":"lake"},
 {"id":"mouflon","name":T("Mufflonhänge","Mouflon Slopes"),"size":1.05,"ring":1,"angle":300,"fertilities":["mouflon","herbs","hazel"],"deposits":["copper","copper"],"water":"none"},
 {"id":"obsidian","name":T("Feuerberg","Fire Mountain"),"size":0.95,"ring":2,"angle":330,"fertilities":["herbs","mouflon"],"deposits":["obsidian","obsidian"],"water":"none"},
 {"id":"vine","name":T("Rebenhang","Vine Slope"),"size":1.0,"ring":2,"angle":90,"fertilities":["grapes","honey","clay"],"deposits":[],"water":"stream"},
 {"id":"mira","name":T("Weidenbach","Willow Brook"),"size":1.05,"ring":2,"angle":150,"rival":"mira","fertilities":["fish","flax","aurochs"],"deposits":[],"water":"lake"},
 {"id":"tin","name":T("Zinnklamm","Tin Ravine"),"size":0.95,"ring":2,"angle":210,"fertilities":["mouflon"],"deposits":["tin","tin","tin","copper"],"water":"none"},
 {"id":"mist","name":T("Nebelkessel","Mist Cauldron"),"size":1.0,"ring":2,"angle":270,"fertilities":["herbs","honey","flax","wildgrain","grapes"],"deposits":["tin"],"water":"lake"},
]
json.dump(V, open(OUT+"valleys.json","w"), ensure_ascii=False, indent=1)

P = [["main","flint","none"],["main","bees","scree"],["main","flax","scree"],["main","aurochs","gorge"],["main","mouflon","scree"],
 ["flint","bees","none"],["bees","flax","river"],["flax","aurochs","none"],["aurochs","rival","scree"],["rival","mouflon","none"],["mouflon","flint","none"],
 ["flint","obsidian","gorge"],["mouflon","obsidian","scree"],["bees","vine","none"],["flax","vine","river"],["flax","mira","scree"],["aurochs","mira","none"],
 ["aurochs","tin","glacier"],["rival","tin","glacier"],["rival","mist","scree"],["mouflon","mist","river"]]
json.dump([{"a":p[0],"b":p[1],"obstacle":p[2]} for p in P], open(OUT+"passes.json","w"), ensure_ascii=False, indent=1)

O = [
 {"id":"none","name":T("Trampelpfad","Trail"),"fix":None,"desc":T("Ein offener Pfad – begehbar, sobald er erkundet ist.","An open trail – passable once explored.")},
 {"id":"scree","name":T("Geröllhang","Scree Slope"),"fix":T("Steig anlegen","Cut a Stairway"),"unlockTier":"sedentary","cost":{"shells":300,"tools":8,"wood":15},"time":40,
  "desc":T("Loses Geröll: Erst ein in den Fels gehauener Steig macht ihn für Lasten begehbar.","Loose scree: only steps cut into the rock make it passable with loads.")},
 {"id":"river","name":T("Wildfluss","Torrent"),"fix":T("Floßfähre bauen","Build a Raft Ferry"),"unlockTier":"villagers","cost":{"shells":400,"wood":25,"rope":6},"time":45,
  "desc":T("Ein reißender Fluss quert den Pfad. Mit einem Seilfloß können Karawanen übersetzen.","A raging river crosses the path. A rope-guided raft lets caravans across.")},
 {"id":"gorge","name":T("Schlucht","Gorge"),"fix":T("Seilbrücke spannen","Span a Rope Bridge"),"unlockTier":"villagers","cost":{"shells":600,"wood":20,"rope":15},"time":60,
  "desc":T("Eine tiefe Klamm. Nur eine Seilbrücke führt hinüber.","A deep chasm. Only a rope bridge leads across.")},
 {"id":"glacier","name":T("Gletscherpass","Glacier Pass"),"fix":T("Steinmänner setzen","Mark with Cairns"),"unlockTier":"farmers","cost":{"shells":500,"furs":10,"tools":6},"time":50,"winter_closed":True,"no_wagons":True,
  "desc":T("Eis und Schnee. Mit Steinmännern markiert, im Winter dennoch gesperrt. Kein Wagen kommt hier hinauf.","Ice and snow. Even marked with cairns it closes in winter. No cart can climb it.")},
]
json.dump(O, open(OUT+"obstacles.json","w"), ensure_ascii=False, indent=1)

C = [
 {"id":"porters","name":T("Trägertrupp","Porter Team"),"unlockTier":"sedentary","slots":2,"capacity":10,"speed":2.0,"upkeep":8,"cost":{"shells":250,"hides":4,"wood":6},
  "desc":T("Menschen mit Kiepen und Tragegestellen. Langsam, aber sie kommen überall hin.","People with back baskets and frames. Slow, but they go anywhere.")},
 {"id":"donkeys","name":T("Eselkarawane","Donkey Train"),"unlockTier":"villagers","slots":3,"capacity":20,"speed":2.6,"upkeep":15,"cost":{"shells":600,"rope":6,"linen":4},
  "desc":T("Gezähmte Esel tragen mehr und schneller – um 5000 v. Chr. eine Neuheit.","Tamed donkeys carry more, faster – a novelty around 5000 BC.")},
 {"id":"oxcart","name":T("Ochsenkarren","Ox Cart"),"unlockTier":"chieftains","slots":4,"capacity":40,"speed":1.7,"upkeep":25,"cost":{"shells":1200,"wheels":4,"planks":6},"wagon":True,
  "desc":T("Das Rad! Riesige Ladung, aber nur über ausgebaute Bohlenwege.","The wheel! Huge loads, but only over built plank roads.")},
]
json.dump(C, open(OUT+"caravans.json","w"), ensure_ascii=False, indent=1)

R = [
 {"id":"aruk","name":T("Aruk der Graue","Aruk the Grey"),"color":"#6a7a8a",
  "greeting":T("Ihr seid weit gegangen, Fremde. Die Berge gehören niemandem – aber Graufels gehört uns.","You have walked far, strangers. The mountains belong to no one – but Greyrock is ours."),
  "sells":["flint","fish","meat","tools","pottery"],"buys":["nuts","furs","honey","beer","jewelry"]},
 {"id":"mira","name":T("Mira vom Weidenbach","Mira of Willow Brook"),"color":"#4a8a6a",
  "greeting":T("Willkommen am Bach! Wir haben Flachs, Fisch und Rinder – und hören gern Neuigkeiten von jenseits der Berge.","Welcome to the brook! We have flax, fish and cattle – and love news from beyond the mountains."),
  "sells":["fish","flax","linen","milk","rope"],"buys":["bread","tools","herbs","wine","coppertools"]},
]
json.dump(R, open(OUT+"rivals.json","w"), ensure_ascii=False, indent=1)
print(len(goods), len(B), len(V), len(P))

# ---------------------------------------------------------------- people of the valley
# Characters walk into the valley when their moment comes, stand there with a "!" and hand out quests.
def ch(id,de,en,tde,ten,cloth,hair,skin,extra,home,arrive,greet):
    return {"id":id,"name":T(de,en),"title":T(tde,ten),"cloth":cloth,"hair":hair,"skin":skin,"extra":extra,"home":home,"arrive":arrive,"greeting":T(*greet)}
CH = [
 ch("ama","Ama","Ama","die Älteste","the Elder","#9a3a2c","#e6dfd2","#a8724a",["staff","cloak"],"hearth",{"type":"start"},
    ("Kinder, seht euch dieses Tal an! Wasser, Wild, Beeren an jedem Hang. Hier rasten wir – vielleicht für länger.","Children, look at this valley! Water, game, berries on every slope. We rest here – perhaps for longer.")),
 ch("borr","Borr","Borr","der Jäger","the Hunter","#6b4a2e","#3a2a1e","#9a643e",["spear","dog"],"hunter",{"type":"pop","n":12},
    ("Ich bin Borr, und der Zottel hier ist Fenn. Frische Hirschspuren am Waldrand – wer jagen kann, wird hier satt.","I'm Borr, and this shaggy one is Fenn. Fresh deer tracks at the forest edge – whoever can hunt will eat well here.")),
 ch("sela","Sela","Sela","die Sammlerin","the Gatherer","#5f7a3a","#5a3a22","#b07a50",["basket"],"berrygatherer",{"type":"pop","n":30},
    ("Ich bin Sela. Ich kenne jede Pflanze dieser Hänge – und jede, die man besser nicht isst.","I'm Sela. I know every plant on these slopes – and every one you'd better not eat.")),
 ch("nuri","Nuri","Nuri","die Kundschafterin","the Scout","#3a6a8a","#2a1e18","#8a5a3a",["feather","spear"],"scout",{"type":"pop","n":45},
    ("Nuri. Ich war auf jedem Grat, den man von hier sieht. Dahinter liegen noch viel mehr Täler.","Nuri. I've been on every ridge you can see from here. Beyond them lie many more valleys.")),
 ch("oro","Oro","Oro","der Steinschläger","the Knapper","#5b6168","#8a7a6a","#a06a44",["axe"],"toolmaker",{"type":"houses","tier":"sedentary","n":1},
    ("Oro. Ich habe gehört, ihr baut feste Häuser. Feste Häuser brauchen scharfe Klingen.","Oro. I heard you build solid houses. Solid houses need sharp blades.")),
 ch("ilun","Ilun","Ilun","die Seherin","the Seer","#5a3a6a","#1e1a1e","#9a6a48",["antlers"],"shaman",{"type":"pop","tier":"sedentary","n":40},
    ("Ilun. Ich habe euer Feuer im Traum gesehen. Die Geister dieses Tals sind neugierig auf euch.","Ilun. I saw your fire in a dream. The spirits of this valley are curious about you.")),
 ch("tamo","Tamo","Tamo","der Händler","the Trader","#a8743a","#2a1e18","#7a4a2e",["pack","shells"],"caravanpost",{"type":"pop","tier":"sedentary","n":80},
    ("Tamo, von der Küste! Muscheln, Bernstein, Geschichten – was braucht ihr?","Tamo, from the coast! Shells, amber, stories – what do you need?")),
 ch("enna","Enna","Enna","die Hirtin","the Herder","#d8c8a8","#6a4a2a","#b07a50",["staff","goat"],"goatfarm",{"type":"pop","tier":"farmers","n":40},
    ("Enna. Meine Ziegen fressen euch nicht die Felder weg – versprochen. Fast.","Enna. My goats won't eat your fields – promise. Almost.")),
 ch("hesa","Hesa","Hesa","die Töpferin","the Potter","#c0703e","#3a2418","#a8724a",["pot"],"potter",{"type":"pop","tier":"farmers","n":150},
    ("Hesa. Euer Lehm ist gut. Mit Feuer wird daraus etwas, das nicht mehr zerfällt.","Hesa. Your clay is good. With fire it becomes something that never falls apart again.")),
 ch("garan","Garan","Garan","der Baumeister","the Builder","#a8643a","#4a3020","#9a643e",["axe","cloak"],"square",{"type":"houses","tier":"villagers","n":1},
    ("Garan. Ein Langhaus! Endlich jemand, der in Balken denkt. Euer Dorf braucht eine Mitte.","Garan. A longhouse! Finally someone who thinks in beams. Your village needs a centre.")),
 ch("kural","Kural","Kural","der Fremde","the Stranger","#4f8a7a","#c8b8a0","#8a5a3a",["copper","cloak"],"smelter",{"type":"pop","tier":"villagers","n":200},
    ("Ich bin Kural, von weit hinter den Bergen. Ich bringe euch etwas, das glänzt wie die Abendsonne.","I am Kural, from far beyond the mountains. I bring you something that shines like the evening sun.")),
]
json.dump(CH, open(OUT+"characters.json","w"), ensure_ascii=False, indent=1)

def G(type,**kw):
    d={"type":type}; d.update(kw); return d
def q(id,char,tde,ten,text,goals,done,unlock=None,reward=None,after=None,when=None,**kw):
    d={"id":id,"char":char,"title":T(tde,ten),"text":T(*text),"goals":goals,"done":T(*done),"unlock":unlock or [],"reward":reward or {},"after":after or [],"when":when or []}
    d.update(kw); return d
Q = [
 # --- Ama: the main thread and all thresholds
 q("ama_heart","ama","Ein Herz für das Tal","A Heart for the Valley",
   ("Wir sind lange gewandert, über Schnee und Geröll. Dieses Tal soll uns tragen. Bevor wir Zelte schlagen, braucht es ein Herz: einen Herdring, an dem wir uns versammeln. Bau das Talherz – mitten ins Tal, wo alle es sehen.",
    "We have walked a long way, over snow and scree. This valley shall carry us. Before we pitch tents we need a heart: a hearth ring where we gather. Build the Valley Heart – in the middle, where all can see it."),
   [G("build",building="hearth",n=1)],("Das Feuer brennt. Jetzt sind wir angekommen.","The fire burns. Now we have arrived."),
   unlock=["hearth"],reward={"unlock":["tent"],"shells":100}),
 q("ama_roof","ama","Ein Dach über dem Kopf","A Roof Overhead",
   ("Die Nächte sind kalt, und die Kinder schlafen im Gras. Spannt Häute über Weidenruten – vier Kuppeln für den Anfang. Und vergiss die Pfade nicht: Wer keinen Weg zum Lagerplatz hat, bekommt nichts ab.",
    "The nights are cold and the children sleep in the grass. Stretch hides over willow rods – four domes to begin with. And don't forget the paths: whoever has no way to the storage yard gets nothing."),
   [G("build",building="tent",n=4)],("Vier Kuppeln! Jetzt brauchen wir Holz und etwas im Magen.","Four domes! Now we need wood and something to eat."),
   after=["ama_heart"],reward={"unlock":["woodcutter","berrygatherer"],"shells":100}),
 q("ama_baskets","ama","Volle Körbe","Full Baskets",
   ("Hunger ist ein schlechter Gast. Schick Sammler zu den Beerensträuchern und Holzfäller an den Waldrand. Wenn die Körbe voll sind, zeige ich dir, wie man ein Feuer für alle hütet.",
    "Hunger is a bad guest. Send gatherers to the berry bushes and woodcutters to the forest edge. When the baskets are full I'll show you how to keep a fire for everyone."),
   [G("stock",good="berries",n=15),G("stock",good="wood",n=15)],("Gut gemacht. Hier – so legt man ein Lagerfeuer an, das die ganze Nacht brennt.","Well done. Here – this is how to lay a campfire that burns all night."),
   after=["ama_roof"],reward={"unlock":["fireplace"],"shells":150}),
 q("ama_warmth","ama","Wärme für alle","Warmth for Everyone",
   ("Ein Lagerfeuer wärmt nur die, die nah genug sitzen. Leg es so, dass sechs Kuppeln seinen Schein abbekommen. Dann erzählen wir uns abends Geschichten – und vielleicht hören andere davon.",
    "A campfire only warms those who sit close enough. Place it so six domes catch its glow. Then we'll tell stories in the evening – and perhaps others will hear of it."),
   [G("served",service="fireplace",n=6)],("Hörst du das Lachen am Feuer? So zieht man Menschen an. Bald kommen mehr – und mit ihnen neues Wissen.","Do you hear the laughter at the fire? That's how you draw people in. Soon more will come – and new knowledge with them."),
   after=["ama_baskets"],reward={"shells":200,"prestige":5}),
 q("ama_beauty","ama","Blumen zwischen den Kuppeln","Flowers between the Domes",
   ("Die Leute sagen, unser Lager sei grau. Pflanzt Blüten zwischen die Kuppeln – wer Schönes sieht, bleibt gern. Schönheit hebt die Stimmung, und gute Stimmung lockt Zuzügler.",
    "People say our camp is grey. Plant flowers between the domes – whoever sees beauty likes to stay. Beauty lifts the mood, and good mood draws newcomers."),
   [G("build",building="gardenbed",n=3)],("Viel schöner! Siehst du, wie die Kinder dazwischen spielen?","Much nicer! See how the children play among them?"),
   after=["ama_warmth"],when=[G("pop",n=20)],reward={"prestige":5,"shells":100}),
 q("ama_feast","ama","Das erste Fest","The First Feast",
   ("Ein Stamm, der nicht feiert, zerfällt. Sammle Fleisch, Beeren und Holz und lade alle ans Talherz ein: ein Herdfest! Danach erzähle ich dir von unseren Bräuchen.",
    "A tribe that never celebrates falls apart. Gather meat, berries and wood and invite everyone to the Valley Heart: a hearth feast! Afterwards I'll tell you about our customs."),
   [G("festival",festival="herdfest")],("Was für eine Nacht! Nimm diese Knochenflöte und leg sie in eine Nische des Talherzens. Und denk über unsere Bräuche nach – sie geben uns Halt.","What a night! Take this bone flute and lay it in a niche of the Valley Heart. And think about our customs – they hold us together."),
   after=["ama_warmth"],when=[G("pop",n=25)],festivals=["herdfest"],reward={"items":["flute"],"customs":1,"prestige":5}),
 q("ama_custom","ama","Was uns zusammenhält","What Holds Us Together",
   ("Jeder Stamm hat seine Bräuche. Manche teilen alles am Herd, andere ehren die Ahnen, wieder andere nehmen jeden Gast auf. Wähle am Talherz einen Brauch – jeder hat seinen Preis.",
    "Every tribe has its customs. Some share everything at the hearth, others honour the ancestors, others again welcome every guest. Choose a custom at the Valley Heart – each has its price."),
   [G("custom",n=1)],("So sei es. Ein Brauch ist wie ein Pfad: Je öfter man ihn geht, desto fester wird er.","So be it. A custom is like a path: the more often it's walked, the firmer it gets."),
   after=["ama_feast"],reward={"prestige":5}),
 q("ama_stay","ama","Bleiben","Staying",
   ("Wir sind Wanderer, seit es Menschen gibt. Aber dieses Tal … Sela sagt, das wilde Korn reicht für alle, wenn wir bleiben. Beweisen wir es: achtzig von uns, ein Winter mit vollen Vorratsgruben – hundertzwanzig Körbe Nahrung, wenn der erste Schnee fällt – und zehn Feldsteine für die ersten festen Häuser. Dann bleiben wir.",
    "We have been wanderers since there were people. But this valley … Sela says the wild grain is enough for all if we stay. Let's prove it: eighty of us, a winter with full storage pits – a hundred and twenty baskets of food when the first snow falls – and ten fieldstones for the first solid houses. Then we stay."),
   [G("pop",tier="foragers",n=80),G("winter_food",n=120),G("deliver",good="stone",n=10)],("Wir bleiben. Bau Grubenhäuser mit Steinfundament – wer will, zieht aus den Kuppeln um.","We stay. Build pit houses on stone footings – whoever wishes moves out of the domes."),
   after=["ama_feast","sela_autumn","nuri_beyond"],when=[G("pop",n=50)],threshold=True,festivals=["harvestfest"],reward={"tier":"sedentary","prestige":10}),
 q("ama_huts","ama","Steinerne Ringe","Rings of Stone",
   ("Ein Grubenhaus entsteht nicht von allein. Klick eine zufriedene Kuppel an und wähle »Aufwerten«, wenn Holz, Häute und Feldsteine im Lager liegen. Ein Pfeil über dem Dach zeigt dir, wer bereit ist. Wertet fünf Kuppeln auf.",
    "A pit house doesn't build itself. Click a content dome and choose \"Upgrade\" when wood, hides and fieldstones are in storage. An arrow above the roof shows who is ready. Upgrade five domes."),
   [G("houses",tier="sedentary",n=5)],("Fünf feste Häuser! Bald wollen die Leute auch anderes essen als Fleisch – frag Sela nach dem wilden Korn.","Five solid houses! Soon people will want more than meat – ask Sela about the wild grain."),
   after=["ama_stay"],reward={"shells":300}),
 q("ama_sow","ama","Säen","Sowing",
   ("Selas Beet trägt. Aber Ilun hat im Rauch einen Winter gesehen, so kalt wie keiner zuvor – die Große Kälte. Wenn wir die überstehen, mit hundertzwanzig Sesshaften und dicken Holzstapeln, dann säen wir im Frühling auf ganzen Feldern.",
    "Sela's plot bears grain. But Ilun saw a winter in the smoke, colder than any before – the Great Cold. If we survive it, with a hundred and twenty settled folk and thick woodpiles, we will sow whole fields in spring."),
   [G("pop",tier="sedentary",n=120),G("survive",what="cold")],("Wir haben die Kälte überstanden. Jetzt säen wir! Die Zeit der Bauern beginnt.","We survived the cold. Now we sow! The age of farmers begins."),
   after=["sela_seed"],when=[G("pop",tier="sedentary",n=80)],threshold=True,festivals=["springfest"],reward={"tier":"farmers","prestige":15}),
 q("ama_vessel","ama","Das erste Gefäß","The First Vessel",
   ("Hesas Töpfe halten Wasser, Brei und Saatgut, ohne dass Mäuse daran kommen. Ein Dorf, das Vorräte in Ton aufbewahrt, kann wachsen wie keines zuvor. Zweihundert Bauern, zwanzig Gefäße und dreißig Lehmziegel – dann bauen wir Langhäuser.",
    "Hesa's pots hold water, porridge and seed corn out of the mice's reach. A village that stores in clay can grow like none before. Two hundred farmers, twenty vessels and thirty mud bricks – then we build longhouses."),
   [G("pop",tier="farmers",n=200),G("deliver",good="pottery",n=20),G("deliver",good="bricks",n=30)],("Langhäuser! Unser Dorf ist jetzt größer als jedes Lager, das ich als Kind gesehen habe.","Longhouses! Our village is now bigger than any camp I saw as a child."),
   after=["hesa_pot"],when=[G("pop",tier="farmers",n=120)],threshold=True,reward={"tier":"villagers","prestige":20}),
 q("ama_ore","ama","Das grüne Erz","The Green Ore",
   ("Kural sagt, im grünen Stein steckt ein Metall, das man gießen kann. Ich bin alt, aber ich will es sehen: dreihundert Dörfler und ein Probeguss – zehn Barren Kupfer am Talherz.",
    "Kural says the green stone holds a metal that can be poured. I am old, but I want to see it: three hundred villagers and a trial casting – ten bars of copper at the Valley Heart."),
   [G("pop",tier="villagers",n=300),G("deliver",good="copper",n=10)],("Es glänzt wie die Abendsonne … Die Sippen werden davon noch in tausend Jahren erzählen.","It shines like the evening sun … The clans will still speak of this in a thousand years."),
   after=["kural_ore"],threshold=True,reward={"tier":"chieftains","prestige":25}),
 q("ama_final","ama","Das große Talherz-Fest","The Great Valley Heart Feast",
   ("Sieh, was aus dem Lager am See geworden ist. Lass uns ein Fest feiern, von dem man jenseits aller Berge hört: zweihundertfünfzig Sippenleute und zwanzig Stücke Bronzeschmuck für die Gäste.",
    "Look what has become of the camp by the lake. Let us hold a feast heard of beyond all mountains: two hundred and fifty clansfolk and twenty pieces of bronze finery for the guests."),
   [G("pop",tier="chieftains",n=250),G("deliver",good="bronzeware",n=20)],("Die Steinzeit endet hier, an unserem Herd. Danke, dass du uns geführt hast.","The Stone Age ends here, at our hearth. Thank you for leading us."),
   after=["kural_bronze"],threshold=True,reward={"win":True,"prestige":50}),
 # --- Borr: hunting, wildlife, winter meat
 q("borr_tracks","borr","Spuren im Wald","Tracks in the Forest",
   ("Gib mir ein Jagdlager am Waldrand, dann bringe ich Fleisch. Aber merk dir eins: Wer zu viel jagt, jagt bald gar nichts mehr. Das Wild braucht Zeit, um nachzuwachsen.",
    "Give me a hunting camp at the forest edge and I'll bring meat. But remember: whoever hunts too much soon hunts nothing at all. The game needs time to recover."),
   [G("build",building="hunter",n=1)],("Der erste Hirsch! Heute Abend gibt's Fleisch am Feuer.","The first deer! Tonight there's meat at the fire."),
   unlock=["hunter"],reward={"shells":150}),
 q("borr_fenn","borr","Fenn ist weg","Fenn Is Gone",
   ("Fenn! Er ist einer Fährte nachgelaufen und nicht zurückgekommen. Hilf mir suchen – irgendwo im Wald muss er sein. Halte Ausschau und klick ihn an, wenn du ihn siehst.",
    "Fenn! He ran after a scent and never came back. Help me look – he must be somewhere in the forest. Keep an eye out and click him when you see him."),
   [G("find",what="fenn")],("Da ist er ja, der Dummkopf! Nimm sein altes Halsband als Dank – leg es ins Talherz, dann jagen wir besser.","There he is, the fool! Take his old collar as thanks – lay it in the Valley Heart and we'll hunt better."),
   after=["borr_tracks"],reward={"items":["collar"]}),
 q("borr_hides","borr","Häute für den Winter","Hides for Winter",
   ("Der Winter kommt, und dann gibt's keine Beeren mehr – nur was wir eingelagert haben und was wir jagen. Ein Fallensteller bringt Häute, eine Räucherhütte hält das Fleisch länger frisch.",
    "Winter is coming, and then there are no berries – only what we stored and what we hunt. A trapper brings hides, a smokehouse keeps the meat fresh longer."),
   [G("stock",good="hides",n=10),G("build",building="smokehouse",n=1)],("So überstehen wir die Kälte. Und aus den Häuten werden später feste Dächer.","That's how we'll get through the cold. And later the hides will make solid roofs."),
   after=["borr_fenn"],when=[G("pop",n=18)],unlock=["trapper","smokehouse"],reward={"shells":200}),
 q("borr_balance","borr","Das Wild schonen","Sparing the Game",
   ("Drei Jagdlager und trotzdem genug Wild im Wald – das ist die Kunst. Halte den Wildbestand im Haupttal über sechzig von hundert. Notfalls lass ein Lager ruhen.",
    "Three hunting camps and still enough game in the forest – that is the art. Keep the main valley's game above sixty in a hundred. If need be, let a camp rest."),
   [G("build",building="hunter",n=3),G("game",n=60)],("Siehst du die Kälber am Waldrand? So bleibt das Tal reich.","See the calves at the forest edge? That's how the valley stays rich."),
   after=["borr_hides"],when=[G("tier",tier="sedentary")],reward={"prestige":8,"shells":250}),
 # --- Sela: plants, storage, wild grain, the first seeds
 q("sela_autumn","sela","Was der Herbst schenkt","Autumn's Gifts",
   ("Im Herbst tragen die Haselsträucher schwer, und am Fuß der Berge liegen Steine, aus denen man Vorratsgruben baut. Beeren verderben schnell – in einer Grube halten sie doppelt so lang. Bau eine Vorratsgrube und lagere zehn Haselnüsse ein.",
    "In autumn the hazels bear heavily, and at the foot of the mountains lie stones to build storage pits. Berries spoil quickly – in a pit they keep twice as long. Build a storage pit and store ten hazelnuts."),
   [G("build",building="storagepit",n=1),G("stock",good="nuts",n=10)],("Nüsse halten fast ewig. Damit kommen wir durch jeden Winter.","Nuts keep almost forever. With them we'll get through any winter."),
   unlock=["nutgatherer","stonegatherer","storagepit"],reward={"shells":200}),
 q("sela_grain","sela","Das wilde Korn","The Wild Grain",
   ("Siehst du die Halme am Ufer? Wilde Gerste, wildes Einkorn. Mit Feuersteinsicheln ernten wir sie, auf Mahlsteinen wird Brei daraus. Das ist der Grund, warum wir bleiben können. Koche fünfzehn Töpfe Brei.",
    "See the stalks by the shore? Wild barley, wild einkorn. We harvest them with flint sickles and grind porridge on querns. That's why we can stay. Cook fifteen pots of porridge."),
   [G("produce",good="porridge",n=15)],("Warmer Brei im Winter – die Alten weinen fast vor Freude.","Warm porridge in winter – the old ones nearly weep with joy."),
   after=["sela_autumn"],when=[G("tier",tier="sedentary")],unlock=["graingatherer","grinder"],reward={"shells":300,"prestige":5}),
 q("sela_seed","sela","Das Versuchsbeet","The Trial Plot",
   ("Mir ist etwas aufgefallen: Wo Körner auf die Erde fallen, wachsen im nächsten Jahr neue Halme. Was, wenn wir die dicksten Körner zurückbehalten und selbst in die Erde legen? Gib mir ein kleines Beet. Im Frühling säen, im Herbst ernten – fünf Garben Emmer.",
    "I've noticed something: where grains fall on the earth, new stalks grow the next year. What if we keep back the fattest grains and put them in the earth ourselves? Give me a small plot. Sow in spring, harvest in autumn – five sheaves of emmer."),
   [G("produce",good="emmer",n=5)],("Es wächst! Und die Körner sitzen fester als bei den wilden Halmen. Ama muss das sehen. Nimm meine Sichel – sie hat schon tausend Halme geschnitten.","It grows! And the grains sit firmer than on the wild stalks. Ama must see this. Take my sickle – it has cut a thousand stalks."),
   after=["sela_grain"],when=[G("pop",tier="sedentary",n=50)],unlock=["trialbed"],reward={"items":["sickle"],"prestige":10}),
 # --- Nuri: passes and valleys
 q("nuri_beyond","nuri","Hinter den Bergen","Beyond the Mountains",
   ("Gib mir ein Kundschafterlager und Proviant – fünf Fleisch –, und ich finde die Pfade über die Berge. Manche sind offen, andere versperren Geröll, Schluchten oder Eis.",
    "Give me a scout camp and provisions – five meat – and I'll find the paths across the mountains. Some are open, others blocked by scree, gorges or ice."),
   [G("explore",n=1)],("Hinter dem Grat liegt ein ganzes Tal! Wir sind nicht allein auf der Welt.","Beyond the ridge lies a whole valley! We're not alone in the world."),
   unlock=["scout"],reward={"shells":200,"prestige":5}),
 q("nuri_found","nuri","Ein zweites Feuer","A Second Fire",
   ("Die Feuersteinschlucht liegt nur einen Tagesmarsch entfernt. Gründe dort einen Lagerplatz, und wir haben Feuerstein, so viel wir wollen. Das kostet Ansehen – die anderen Sippen müssen sehen, dass wir ein Tal halten können.",
    "Flint Gorge is only a day's walk away. Found a storage yard there and we'll have all the flint we want. It costs prestige – the other clans must see that we can hold a valley."),
   [G("valleys",n=2)],("Zwei Feuer, ein Stamm. Jetzt braucht es Träger, die zwischen den Tälern laufen.","Two fires, one tribe. Now we need porters to walk between the valleys."),
   after=["nuri_beyond"],when=[G("tier",tier="sedentary")],reward={"shells":300}),
 q("nuri_rival","nuri","Fremde Feuer","Foreign Fires",
   ("Nachts sehe ich Rauch hinter dem Graufels. Andere Menschen! Finde den Pfad zu ihnen. Ob Freund oder Feind – wir sollten es wissen, bevor sie uns finden.",
    "At night I see smoke beyond Greyrock. Other people! Find the path to them. Friend or foe – we should know before they find us."),
   [G("contact",n=1)],("Aruk der Graue. Stolz und misstrauisch – aber er handelt.","Aruk the Grey. Proud and wary – but he trades."),
   after=["nuri_found"],reward={"prestige":8}),
 # --- Oro: flint and tools
 q("oro_flint","oro","Der Klang des Feuersteins","The Ring of Flint",
   ("Für Grubenhäuser reichen Feldsteine – aber wer Bauernhäuser will, braucht gute Werkzeuge. Feuerstein gibt es in der Feuersteinschlucht. Bau dort einen Steinbruch und eine Werkstatt und schlag fünf Werkzeuge.",
    "Fieldstones are enough for pit houses – but whoever wants farmhouses needs good tools. Flint lies in Flint Gorge. Build a quarry and a workshop there and knap five tools."),
   [G("produce",good="tools",n=5)],("Hörst du, wie sie klingen? Gute Klingen singen, wenn man sie anschlägt.","Hear how they ring? Good blades sing when struck."),
   unlock=["flintquarry","toolmaker"],reward={"shells":300,"prestige":5}),
 # --- Ilun: spirits, the sick, the solstice
 q("ilun_spirits","ilun","Die Stimme der Ahnen","The Voice of the Ancestors",
   ("Ein Schamanenplatz heilt Kranke und hält die Geister freundlich. Und zur Wintersonnwende dürfen wir einen von ihnen um seinen Segen bitten – den Hirschgeist, die Erdmutter, den Fluss oder das Feuer.",
    "A shaman's place heals the sick and keeps the spirits friendly. And at the winter solstice we may ask one of them for a blessing – the deer spirit, the earth mother, the river or the fire."),
   [G("build",building="shaman",n=1)],("Die Ahnen nicken. Trag dieses Amulett aus Bernstein ins Talherz – es hält Krankheiten fern.","The ancestors nod. Bring this amber amulet to the Valley Heart – it keeps sickness away."),
   unlock=["shaman","ancestors"],festivals=["solstice"],reward={"items":["amber"],"prestige":5}),
 q("ilun_solstice","ilun","Die lange Nacht","The Long Night",
   ("Wenn die Nacht am längsten ist, entzünden wir alle Feuer des Tals und wählen einen Schutzgeist für das kommende Jahr. Halte die Wintersonnwende am Talherz.",
    "When the night is longest we light every fire in the valley and choose a guardian spirit for the year to come. Hold the winter solstice at the Valley Heart."),
   [G("festival",festival="solstice")],("Der Geist hat geantwortet. Er wird uns ein Jahr lang begleiten.","The spirit has answered. It will walk with us for a year."),
   after=["ilun_spirits"],reward={"prestige":10}),
 # --- Tamo: trade, caravans, a choice
 q("tamo_trade","tamo","Muscheln vom Meer","Shells from the Sea",
   ("Ihr habt Häute und Feuerstein, das ist gut. Baut einen Rastplatz am Fuß eines Passes und stellt einen Trägertrupp mit einer Route über zwei Täler auf. Dann kommen auch die Flusshändler zu euch.",
    "You have hides and flint, that's good. Build a caravan camp at the foot of a pass and hire a porter team with a route through two valleys. Then the river traders will come to you too."),
   [G("caravan",n=1)],("Ware, die läuft, ist Ware, die wächst! Ab jetzt schauen die Flusshändler regelmäßig vorbei.","Goods that move are goods that grow! From now on the river traders will drop by regularly."),
   unlock=["caravanpost"],flags=["trade"],reward={"shells":400}),
 q("tamo_deal","tamo","Ein Tauschangebot","A Trade Offer",
   ("Ich habe zwei Schätze im Gepäck. Für fünfzehn Fellkleider gebe ich dir einen: den Mahlstein aus Basalt – damit mahlt ihr schneller – oder den Armreif aus Spondylus-Muschel, für den die Leute gern mehr Muscheln zahlen. Du musst dich entscheiden.",
    "I carry two treasures. For fifteen fur garments I'll give you one: the basalt quern – you'll grind faster – or the spondylus shell bracelet, for which people gladly pay more shells. You must choose."),
   [G("deliver",good="furs",n=15)],("Ein guter Tausch – für uns beide.","A good trade – for both of us."),
   after=["tamo_trade"],choices=[{"label":T("Basaltmahlstein","Basalt Quern"),"reward":{"items":["quern"]}},{"label":T("Spondylus-Armreif","Spondylus Bracelet"),"reward":{"items":["spondylus"]}}]),
 # --- Enna, Hesa, Garan, Kural
 q("enna_goats","enna","Die zahmen Ziegen","The Tame Goats",
   ("Wilde Ziegen fliehen, zahme bleiben. Bau einen Pferch, dann haben wir Fleisch und Häute, ohne dass Borr das Wild leerjagen muss.",
    "Wild goats flee, tame ones stay. Build a pen and we'll have meat and hides without Borr emptying the forest."),
   [G("build",building="goatfarm",n=1)],("Hörst du sie meckern? Musik in meinen Ohren.","Hear them bleat? Music to my ears."),
   unlock=["goatfarm"],reward={"shells":300,"prestige":5}),
 q("hesa_pot","hesa","Ton und Feuer","Clay and Fire",
   ("Lehm, Wasser, ein heißer Ofen – und Geduld. Bau eine Töpferei und brenne zehn Gefäße. Damit verdirbt euch nichts mehr.",
    "Clay, water, a hot kiln – and patience. Build a pottery and fire ten vessels. Then nothing will spoil on you any more."),
   [G("produce",good="pottery",n=10)],("Sieh dir diese Wand an – dünn wie ein Blatt und hart wie Stein.","Look at this wall – thin as a leaf and hard as stone."),
   unlock=["potter"],reward={"prestige":10,"shells":400}),
 q("garan_square","garan","Eine Mitte für das Dorf","A Centre for the Village",
   ("Ein Dorf ohne Platz ist nur ein Haufen Häuser. Leg einen Dorfplatz an und stell zwei bemalte Steine auf – dann wissen alle, wo sie sich treffen.",
    "A village without a square is just a heap of houses. Lay out a village square and raise two painted stones – then everyone knows where to meet."),
   [G("build",building="square",n=1),G("build",building="paintedstone",n=2)],("Jetzt ist es ein Dorf. Nimm diesen Spiegel aus Obsidian – wer hineinsieht, sieht die Festgäste von morgen.","Now it's a village. Take this obsidian mirror – whoever looks in sees tomorrow's feast guests."),
   unlock=["square","paintedstone","totempost"],reward={"items":["mirror"],"prestige":10}),
 q("kural_ore","kural","Das grüne Erz","The Green Ore",
   ("In euren Bergen steckt grüner Stein. Grabt ihn aus, verkohlt Holz zu Holzkohle und schmelzt ihn im Ofen – heraus fließt Kupfer. Gieß fünf Barren.",
    "Your mountains hold green stone. Dig it out, turn wood into charcoal and smelt it in a furnace – out flows copper. Cast five bars."),
   [G("produce",good="copper",n=5)],("Ihr habt es geschafft. Nimm dieses Beil – Kupfer schneidet Holz wie Butter.","You did it. Take this axe – copper cuts wood like butter."),
   unlock=["coppermine","charcoal","smelter"],reward={"items":["copperaxe"],"prestige":10}),
 q("kural_bronze","kural","Kupfer und Zinn","Copper and Tin",
   ("Kupfer ist weich. Aber mischt man es mit Zinn, wird es hart und golden. Zinn gibt es nur hinter dem Gletscher. Gieß drei Stücke Bronzeschmuck.",
    "Copper is soft. But mix it with tin and it turns hard and golden. Tin lies only beyond the glacier. Cast three pieces of bronze finery."),
   [G("produce",good="bronzeware",n=3)],("Bronze. Die Welt wird nie mehr dieselbe sein.","Bronze. The world will never be the same."),
   after=["kural_ore"],when=[G("tier",tier="chieftains")],unlock=["tinmine","bronzesmith"],reward={"prestige":20}),
]
json.dump(Q, open(OUT+"quests.json","w"), ensure_ascii=False, indent=1)

# Quest-given buildings are locked until their quest hands them over.
for qq in Q:
    for bid in qq["unlock"] + qq["reward"].get("unlock",[]):
        for d in B:
            if d["id"]==bid: d["unlock"]={"quest":qq["id"]}
json.dump(B, open(OUT+"buildings.json","w"), ensure_ascii=False, indent=1)

# ---------------------------------------------------------------- treasures, customs, festivals, spirits
def it(id,de,en,dde,den,effect,color):
    return {"id":id,"name":T(de,en),"desc":T(dde,den),"effect":effect,"color":color}
ITEMS = [
 it("collar","Fenns Halsband","Fenn's Collar","Jagdlager und Fallensteller im Tal +20 %.","Hunting camps and trappers in the valley +20%.",{"hunt":0.2},"#8a5a32"),
 it("flute","Knöcherne Flöte","Bone Flute","Stimmung im Tal +5.","Mood in the valley +5.",{"mood":5},"#efe4cc"),
 it("sickle","Sichel mit Sichelglanz","Polished Sickle","Sammler und Felder im Tal +15 %.","Gatherers and fields in the valley +15%.",{"gather":0.15,"field":0.15},"#c9a24a"),
 it("quern","Basaltmahlstein","Basalt Quern","Mahlplätze und Mühlen im Tal +25 %.","Grinding places and mills in the valley +25%.",{"mill":0.25},"#4a4440"),
 it("amber","Bernsteinamulett","Amber Amulet","Krankheiten treffen das Tal nur halb so oft.","Sickness strikes the valley only half as often.",{"illness":-0.5},"#e0a12c"),
 it("wolftooth","Wolfszahnkette","Wolf-Tooth Necklace","Keine Wölfe mehr im Tal.","No more wolves in the valley.",{"no_wolves":1},"#efe4cc"),
 it("spondylus","Spondylus-Armreif","Spondylus Bracelet","Einnahmen im Tal +10 %.","Income in the valley +10%.",{"income":0.1},"#c0503a"),
 it("mirror","Obsidianspiegel","Obsidian Mirror","Jedes Fest im Tal bringt +2 Ansehen.","Every festival in the valley yields +2 prestige.",{"fest_prestige":2},"#2a2a34"),
 it("copperaxe","Kupferbeil","Copper Axe","Holzfäller im Tal +30 %.","Woodcutters in the valley +30%.",{"wood":0.3},"#c06a3a"),
]
json.dump(ITEMS, open(OUT+"items.json","w"), ensure_ascii=False, indent=1)

def cu(id,de,en,dde,den,effect):
    return {"id":id,"name":T(de,en),"desc":T(dde,den),"effect":effect}
CUSTOMS = [
 cu("share","Teilen am Herd","Sharing at the Hearth","Vorräte verderben 25 % langsamer, Einnahmen −10 %.","Stores spoil 25% slower, income −10%.",{"spoil":-0.25,"income":-0.1}),
 cu("huntrest","Jagdruhe im Frühling","Spring Hunting Truce","Wild wächst doppelt so schnell nach, aber Jäger ruhen im Frühling.","Game regrows twice as fast, but hunters rest in spring.",{"regrow":1.0,"spring_hunt":-1.0}),
 cu("guests","Gastrecht","Right of Guests","Zuzug +30 %, Nahrungsverbrauch +10 %.","Immigration +30%, food use +10%.",{"imm":0.3,"food_use":0.1}),
 cu("ancestors","Ahnenehre","Honouring the Ancestors","Stimmung +8, Unterhalt +15 %.","Mood +8, upkeep +15%.",{"mood":8,"upkeep":0.15}),
 cu("harvest","Gemeinsame Ernte","Common Harvest","Sammler +15 %, Stimmung −5.","Gatherers +15%, mood −5.",{"gather":0.15,"mood":-5}),
 cu("calendar","Festkalender","Feast Calendar","Feste kosten 30 % weniger, Produktion −5 %.","Festivals cost 30% less, production −5%.",{"fest_cost":-0.3,"all":-0.05}),
 cu("tradepeace","Tauschfrieden","Barter Peace","Händler zahlen 15 % mehr, Einnahmen −5 %.","Traders pay 15% more, income −5%.",{"price":0.15,"income":-0.05}),
 cu("kinlaw","Sippenrecht","Clan Law","Einnahmen +15 %, Zuzug −20 %.","Income +15%, immigration −20%.",{"income":0.15,"imm":-0.2}),
]
json.dump(CUSTOMS, open(OUT+"customs.json","w"), ensure_ascii=False, indent=1)

FESTIVALS = [
 {"id":"herdfest","name":T("Herdfest","Hearth Feast"),"season":-1,"cost":{"meat":20,"berries":20,"wood":10},"effect":{"mood":15},"prestige":5,
  "desc":T("Ein Abend für alle am Talherz. Stimmung +15 eine Jahreszeit lang.","An evening for everyone at the Valley Heart. Mood +15 for a season.")},
 {"id":"solstice","name":T("Wintersonnwende","Winter Solstice"),"season":3,"cost":{"wood":30,"meat":20,"nuts":10},"effect":{"mood":15,"freeze":-0.5},"prestige":5,"spirit":True,
  "desc":T("Alle Feuer brennen in der längsten Nacht. Stimmung +15, Kälte halbiert – und du wählst einen Schutzgeist für ein Jahr.","Every fire burns in the longest night. Mood +15, cold halved – and you choose a guardian spirit for a year.")},
 {"id":"harvestfest","name":T("Erntefest","Harvest Feast"),"season":2,"cost":{"porridge":30,"honey":10},"effect":{"mood":15,"imm":0.25},"prestige":8,
  "desc":T("Dank für das wilde Korn. Stimmung +15, Zuzug +25 %.","Thanks for the wild grain. Mood +15, immigration +25%.")},
 {"id":"springfest","name":T("Frühlingsfest","Spring Feast"),"season":0,"cost":{"bread":20,"herbs":10},"effect":{"mood":10,"imm":0.5},"prestige":8,
  "desc":T("Saat und Neubeginn. Stimmung +10, Geburten +50 %.","Seed and new beginnings. Mood +10, births +50%.")},
]
json.dump(FESTIVALS, open(OUT+"festivals.json","w"), ensure_ascii=False, indent=1)

SPIRITS = [
 {"id":"deer","name":T("Hirschgeist","Deer Spirit"),"desc":T("Jagd +20 %, Wild wächst schneller nach.","Hunting +20%, game regrows faster."),"effect":{"hunt":0.2,"regrow":0.5},"color":"#9a6a3a"},
 {"id":"earth","name":T("Erdmutter","Earth Mother"),"desc":T("Sammler und Felder +15 %.","Gatherers and fields +15%."),"effect":{"gather":0.15,"field":0.15},"color":"#5f7a3a"},
 {"id":"river","name":T("Flussgeist","River Spirit"),"desc":T("Fischfang +20 %, keine Hochwasser.","Fishing +20%, no floods."),"effect":{"fish":0.2,"no_flood":1},"color":"#3a6a8a"},
 {"id":"fire","name":T("Feuergeist","Fire Spirit"),"desc":T("Werkstätten +15 %, seltener Brände.","Workshops +15%, fewer fires."),"effect":{"workshop":0.15,"fire":-0.5},"color":"#c0602e"},
]
json.dump(SPIRITS, open(OUT+"spirits.json","w"), ensure_ascii=False, indent=1)
