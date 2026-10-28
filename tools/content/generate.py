import json
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "content") + "/"
def T(de, en): return {"de": de, "en": en}

goods = [
 # id, de, en, value, color, glyph
 ("wood","Holz","Wood",4,"#8a5a32","log"),
 ("berries","Beeren","Berries",5,"#7a2348","berries"),
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

def need(i,k,c=None,r=None,inc=0):
    d={"id":i,"kind":k}
    if c is not None: d["consumption"]=c
    if r is not None: d["residents"]=r
    d["income"]=inc
    return d
tiers = [
 {"id":"foragers","name":T("Wildbeuter","Foragers"),"age":T("Späte Altsteinzeit · um 13.000 v. Chr.","Late Palaeolithic · c. 13,000 BC"),
  "house":"tent","baseResidents":1,"color":"#9a7a4a","unlock":None,"upgradeCost":{},
  "intro":T("Kleine Gruppen ziehen den Herden und den Jahreszeiten hinterher. Jagd, Beeren, Feuer – mehr braucht es nicht.","Small bands follow the herds and the seasons. Hunting, berries, fire – nothing more is needed."),
  "history":T("Bis vor rund 12.000 Jahren lebten alle Menschen als Jäger und Sammler. Sie kannten Hunderte essbare Pflanzen, aber sie pflanzten nichts an.","Until about 12,000 years ago all humans lived as hunter-gatherers. They knew hundreds of edible plants, but planted none."),
  "needs":[need("berries","basic",0.07,1,0.8),need("meat","basic",0.05,1,0.8),need("fireplace","service",None,1,0.4),need("nuts","luxury",0.04,None,1.0)]},
 {"id":"sedentary","name":T("Sesshafte Sammler","Settled Foragers"),"age":T("Natufien · um 12.000 v. Chr.","Natufian · c. 12,000 BC"),
  "house":"hut","baseResidents":2,"color":"#8a5a2a","unlock":{"tier":"foragers","population":60},"upgradeCost":{"wood":2,"hides":1},
  "intro":T("Wo wildes Getreide dicht steht, lohnt es sich zu bleiben. Runde Grubenhäuser, Sicheln aus Feuerstein, Vorratsgruben – und die Toten werden unter dem Haus bestattet.","Where wild cereals grow thick, it pays to stay. Round pit houses, flint sickles, storage pits – and the dead are buried beneath the house."),
  "history":T("Sesshaftigkeit kam vor dem Ackerbau: Die Natufier in der Levante lebten das ganze Jahr in Dörfern, ernteten aber noch wildes Getreide.","Settling down came before farming: the Natufians of the Levant lived in villages all year round but still harvested wild cereals."),
  "needs":[need("fish","basic",0.06,2,1.0),need("porridge","basic",0.06,2,1.2),need("furs","basic",0.03,1,1.2),need("shaman","service",None,1,0.5),need("honey","luxury",0.03,None,1.6),need("ancestors","service-luxury",None,None,1.0)]},
 {"id":"farmers","name":T("Erste Bauern","First Farmers"),"age":T("Frühes Neolithikum · um 9.000 v. Chr.","Early Neolithic · c. 9,000 BC"),
  "house":"cottage","baseResidents":3,"color":"#a0603a","unlock":{"tier":"sedentary","population":100},"upgradeCost":{"wood":2,"tools":2},
  "intro":T("Aus Sammeln wird Säen: Emmer und Gerste werden angebaut, Ziegen und Schafe gezähmt. Eckige Lehmziegelhäuser drängen sich aneinander.","Gathering turns into sowing: emmer and barley are cultivated, goats and sheep tamed. Rectangular mud-brick houses crowd together."),
  "history":T("Zuerst wurden Pflanzen domestiziert (um 9500 v. Chr.), wenig später Ziegen und Schafe. Keramik gab es noch nicht – man spricht vom präkeramischen Neolithikum.","Plants were domesticated first (c. 9500 BC), goats and sheep a little later. There was no pottery yet – the Pre-Pottery Neolithic."),
  "needs":[need("bread","basic",0.07,3,1.5),need("meat","basic",0.05,2,1.2),need("furs","basic",0.03,2,1.3),need("shrine","service",None,2,0.7),need("herbs","luxury",0.03,None,2.0),need("dance","service-luxury",None,None,1.2)]},
 {"id":"villagers","name":T("Dorfgemeinschaft","Village Folk"),"age":T("Keramisches Neolithikum · um 7.000 v. Chr.","Pottery Neolithic · c. 7,000 BC"),
  "house":"longhouse","baseResidents":4,"color":"#8a4a3a","unlock":{"tier":"farmers","population":150},"upgradeCost":{"bricks":2,"tools":1},
  "intro":T("Töpfe aus gebranntem Ton, Leinen vom Webstuhl, Bier aus Gerste. Dörfer wachsen zu Hunderten Menschen, Obsidian wird über weite Wege gehandelt.","Pots of fired clay, linen from the loom, beer from barley. Villages grow to hundreds of people, obsidian travels far along trade paths."),
  "history":T("Um 7000 v. Chr. verbreitet sich Keramik. Siedlungen wie Çatalhöyük zählen Tausende Bewohner; Flachs wird zu Leinen verwebt.","Around 7000 BC pottery spreads. Settlements like Çatalhöyük number thousands; flax is woven into linen."),
  "needs":[need("bread","basic",0.06,3,1.6),need("pottery","basic",0.03,3,2.0),need("linen","basic",0.03,3,2.0),need("shrine","service",None,2,0.8),need("square","service",None,1,0.6),need("beer","luxury",0.04,None,2.6),need("jewelry","luxury",0.02,None,3.0)]},
 {"id":"chieftains","name":T("Kupferzeitliche Sippen","Copper Age Clans"),"age":T("Kupferzeit · um 4.500 v. Chr.","Copper Age · c. 4,500 BC"),
  "house":"farmstead","baseResidents":5,"color":"#b07a3a","unlock":{"tier":"villagers","population":200},"upgradeCost":{"bricks":3,"pottery":2},
  "intro":T("Kupfer wird geschmolzen, Rinder ziehen den Hakenpflug, Schafe geben Wolle, Kühe Milch. Mit dem Rad beginnt eine neue Zeit – und am Horizont glänzt die Bronze.","Copper is smelted, oxen pull the ard, sheep give wool and cows milk. The wheel starts a new era – and bronze gleams on the horizon."),
  "history":T("Die ‚Revolution der Sekundärprodukte‘: Tiere werden nicht nur gegessen, sondern gemolken, geschoren und eingespannt. Um 3500 v. Chr. erscheint das Rad, kurz danach die Bronze aus Kupfer und Zinn.","The 'secondary products revolution': animals are not only eaten but milked, shorn and harnessed. The wheel appears around 3500 BC, bronze from copper and tin shortly after."),
  "needs":[need("bread","basic",0.05,2,1.5),need("cheese","basic",0.05,3,2.2),need("woolcloth","basic",0.03,3,2.4),need("coppertools","basic",0.02,3,2.6),need("square","service",None,2,0.8),need("wine","luxury",0.03,None,3.2),need("bronzeware","luxury",0.015,None,4.5),need("megalith","service-luxury",None,None,2.0)]},
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

house("tent","Fellzelt","Hide Tent","tent","#b48a5c","foragers",True,{"wood":1},("Wohnstatt der Wildbeuter. Steigt zum Grubenhaus auf, sobald Sesshafte Sammler freigeschaltet und die Grundbedürfnisse gedeckt sind.","Home of the foragers. Upgrades to a pit house once settled foragers are unlocked and basic needs are met."))
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
# T2
prod("fisher","Fischerplatz","Fishing Spot",2,"fisher","#5f8ea0","sedentary",{"shells":120,"wood":6},6,("sedentary",3),20,None,{"fish":1},("Reusen und Speere am Ufer.","Fish traps and spears at the shore."),{"fertility":"fish","nearWater":1})
prod("graingatherer","Wildgetreide-Ernte","Wild Grain Harvest",2,"basket","#c9a24a","sedentary",{"shells":120,"wood":6},6,("sedentary",4),20,None,{"wildgrain":1},("Erntet wilde Gerste und Einkorn mit Feuersteinsicheln.","Harvests wild barley and einkorn with flint sickles."),{"fertility":"wildgrain"})
prod("grinder","Mahlplatz","Grinding Place",2,"quern","#b89a6a","sedentary",{"shells":120,"wood":6},6,("sedentary",3),20,{"wildgrain":1},{"porridge":1},("Mahlsteine machen aus Körnern Brei.","Grinding stones turn grain into porridge."))
prod("tanner","Gerberei","Tannery",2,"rack","#6b4a2e","sedentary",{"shells":120,"wood":6},6,("sedentary",3),30,{"hides":1},{"furs":1},("Gerbt Häute zu warmer Kleidung.","Tans hides into warm clothing."))
prod("flintquarry","Feuersteinbruch","Flint Quarry",2,"pit","#4d5560","sedentary",{"shells":150,"wood":8},8,("sedentary",4),20,None,{"flint":1},("Muss auf einem Feuersteinvorkommen stehen.","Must stand on a flint deposit."),{"deposit":"flint"})
prod("toolmaker","Werkzeugmacher","Toolmaker",2,"workshop","#5b6168","sedentary",{"shells":150,"wood":8},8,("sedentary",3),30,{"flint":1,"wood":1},{"tools":1},("Schlägt Klingen und Beile – Baumaterial ab den Ersten Bauern.","Knaps blades and axes – a building material from the First Farmers on."))
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
prod("potter","Töpferei","Pottery Kiln",2,"kiln","#c0703e","villagers",{"shells":300,"bricks":4,"tools":2},12,("villagers",4),30,{"clay":1,"wood":1},{"pottery":1},("Brennt Gefäße aus Ton.","Fires vessels of clay."))
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
