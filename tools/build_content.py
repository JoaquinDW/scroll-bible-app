#!/usr/bin/env python3
"""Builds Lumen/Resources/content.json from public-domain Bible sources.

Usage: python3 tools/build_content.py <KJV.json> <SpaRV.json> <web_json_dir>
  KJV.json / SpaRV.json : github.com/scrollmapper/bible_databases (formats/json)
  web_json_dir          : npm package `world-english-bible` (package/json)

Scripture text is never typed by hand: it is always pulled from the source files.
Explanations and questions below are study aids written for Lumen (denomination-neutral).
To add a licensed translation later, add another loader and another key in `text`.
"""
import json, re, sys, os

kjv_path, rv_path, web_dir = sys.argv[1:4]
OUT = os.path.join(os.path.dirname(__file__), "..", "Lumen", "Resources", "content.json")

def load_sm(path):
    d = json.load(open(path, encoding="utf-8"))
    return {b["name"]: {c["chapter"]: {v["verse"]: v["text"] for v in c["verses"]} for c in b["chapters"]} for b in d["books"]}

KJV, RV = load_sm(kjv_path), load_sm(rv_path)
_web = {}
def web(book, ch, v):
    f = book.lower().replace(" ", "")
    if f not in _web:
        _web[f] = json.load(open(os.path.join(web_dir, f + ".json"), encoding="utf-8"))
    parts = [x["value"] for x in _web[f] if x.get("chapterNumber") == ch and x.get("verseNumber") == v and "value" in x]
    return " ".join(p.strip() for p in parts)

TITLE = re.compile(r"^(Al Músico principal[^.]*\.|Salmo de David[^.]*\.|Cántico gradual[^.]*\.|Salmo[^.]*\.|Masquil[^.]*\.|Michtam[^.]*\.)\s*", re.I)
TITLE_EN = re.compile(r"^(A Psalm of David\.|To the chief Musician[^.]*\.|A Song of degrees[^.]*\.)\s*")
def clean(t):
    t = re.sub(r"\s+", " ", t).strip()
    return t

def text(book, ch, v1, v2):
    out = {}
    for key, fn in (("KJV", lambda v: KJV[book][ch][v]), ("WEB", lambda v: web(book, ch, v)), ("RV1909", lambda v: RV[book][ch][v])):
        s = clean(" ".join(fn(v) for v in range(v1, v2 + 1)))
        for _ in range(3): s = (TITLE if key == "RV1909" else TITLE_EN).sub("", s)
        first = s.split(" ")[0]
        if len(first) > 1 and first.isupper():  # drop-cap style first words in RV1909
            s = first.capitalize() + s[len(first):]
        s = s[0].upper() + s[1:]
        out[key] = s
    return out

def L(en, es): return {"en": en, "es": es}

def verse(ch, v1, v2, scene, ex, ctx, ap, book="Psalms"):
    return {"type": "verse", "ref": {"book": "PSA", "chapter": ch, "verseStart": v1, "verseEnd": v2},
            "scene": scene, "text": text(book, ch, v1, v2), "explain": ex, "context": ctx, "apply": ap}

def choice(q, options, answer, note):
    return {"type": "choice", "question": q, "options": options, "answer": answer, "note": note}

def missing(ch, v, words, den, des):
    t = text("Psalms", ch, v, v); blanks = {}
    for k, w in words.items():
        pat = re.compile(r"\b" + re.escape(w) + r"\b", re.I)
        assert pat.search(t[k]), (k, w, t[k])
        opts = [w.lower()] + (des if k == "RV1909" else den)
        blanks[k] = {"prompt": pat.sub("_____", t[k], count=1), "answer": w.lower(), "options": sorted(opts)}
    return {"type": "missingWord", "ref": {"book": "PSA", "chapter": ch, "verseStart": v, "verseEnd": v}, "blanks": blanks}

def order(ch, vs):
    return {"type": "order", "ref": {"book": "PSA", "chapter": ch, "verseStart": vs[0], "verseEnd": vs[-1]},
            "pieces": [text("Psalms", ch, v, v) for v in vs]}

days = []
def day(title, summary, key, cards):
    days.append({"day": len(days) + 1, "title": title, "summary": summary, "keyCard": key, "cards": cards})

# ---------------------------------------------------------------- Day 1
day(L("The Shepherd", "El Pastor"), L("Psalm 23", "Salmo 23"), 0, [
 verse(23,1,1,"scene_meadow_day_01",
  L("David says God looks after him the way a shepherd looks after a sheep, so he trusts he will not lack what he truly needs.", "David dice que Dios lo cuida como un pastor cuida a su oveja, y por eso confía en que no le faltará lo que de verdad necesita."),
  L("David was a shepherd before he was a king. He knew a flock depends on its shepherd for food, water and safety.", "David fue pastor antes de ser rey. Sabía que un rebaño depende de su pastor para comer, beber y estar a salvo."),
  L("Tell God plainly one thing you need today.", "Dile a Dios con sencillez una cosa que necesitas hoy.")),
 verse(23,2,2,"scene_still_water_01",
  L("The shepherd leads the sheep to places where it can eat and rest without fear.", "El pastor lleva a la oveja a lugares donde puede comer y descansar sin miedo."),
  L("In the dry hills of Judea, green grass and calm water were rare. A good shepherd had to know where to find them.", "En las colinas secas de Judea, el pasto verde y el agua tranquila eran escasos. Un buen pastor debía saber dónde encontrarlos."),
  L("Take one unhurried minute today with your phone face down.", "Regálate hoy un minuto sin prisa, con el teléfono boca abajo.")),
 verse(23,3,3,"scene_meadow_path_01",
  L("God renews the psalmist's inner life and guides him along good paths, because that is who God is.", "Dios renueva la vida interior del salmista y lo guía por buenos caminos, porque así es Dios."),
  L("\"For his name's sake\" means the guidance rests on God's own character, not on how well the sheep performs.", "\"Por amor de su nombre\" significa que la guía descansa en el carácter de Dios, no en lo bien que lo haga la oveja."),
  L("Ask for guidance on one decision in front of you.", "Pide guía para una decisión que tienes por delante.")),
 missing(23,1,{"KJV":"shepherd","WEB":"shepherd","RV1909":"pastor"},["king","teacher","judge"],["rey","maestro","juez"]),
 verse(23,4,4,"scene_valley_dusk_01",
  L("Even in the darkest place the psalmist is not alone. The shepherd's presence is what takes away the fear.", "Aun en el lugar más oscuro el salmista no está solo. La presencia del pastor es lo que quita el temor."),
  L("Shepherds carried a rod to protect the flock and a staff to guide it. Both were signs that the shepherd was close.", "Los pastores llevaban una vara para proteger al rebaño y un cayado para guiarlo. Ambos eran señal de que el pastor estaba cerca."),
  L("Notice the psalm changes here from \"he\" to \"you\". Try speaking to God directly today.", "Fíjate que aquí el salmo pasa de \"él\" a \"tú\". Prueba hoy hablarle a Dios directamente.")),
 verse(23,5,5,"scene_table_evening_01",
  L("The picture changes from a shepherd to a generous host who welcomes, honors and provides more than enough.", "La imagen cambia de un pastor a un anfitrión generoso que recibe, honra y da más que suficiente."),
  L("Anointing a guest's head with oil was a gesture of welcome and honor in the ancient Near East.", "Ungir con aceite la cabeza de un invitado era un gesto de bienvenida y honor en el antiguo Cercano Oriente."),
  L("Write down one good thing you received this week.", "Anota una cosa buena que recibiste esta semana.")),
 verse(23,6,6,"scene_meadow_golden_01",
  L("The psalm ends with confidence: goodness and mercy stay with him, and his home is with God.", "El salmo termina con confianza: el bien y la misericordia lo acompañan, y su hogar está con Dios."),
  L("The Hebrew word for \"follow\" is a strong one. It can also be translated \"pursue\".", "La palabra hebrea para \"seguir\" es fuerte. También puede traducirse \"perseguir\"."),
  L("Read the whole psalm aloud once, slowly.", "Lee el salmo completo en voz alta una vez, despacio.")),
 order(23,[1,2,3]),
])

# ---------------------------------------------------------------- Day 2
day(L("Be still", "Estad quietos"), L("Psalm 46", "Salmo 46"), 5, [
 verse(46,1,1,"scene_sea_mist_01",
  L("God is described as a safe place and a source of strength, close at hand when trouble comes.", "Se describe a Dios como un lugar seguro y una fuente de fuerza, cercano cuando llega la angustia."),
  L("A refuge was a fortified place where people ran for safety when an enemy approached.", "Un refugio era un lugar fortificado al que la gente corría para ponerse a salvo cuando se acercaba un enemigo."),
  L("When worry rises today, repeat this verse once before doing anything else.", "Cuando hoy suba la preocupación, repite este versículo una vez antes de hacer otra cosa.")),
 verse(46,2,2,"scene_sea_storm_01",
  L("Because God is a refuge, the psalmist chooses not to fear even if the most solid things give way.", "Porque Dios es refugio, el salmista decide no temer aunque cedan las cosas más firmes."),
  L("Mountains were the ancient picture of what never moves. The sea was the picture of chaos.", "Los montes eran la imagen antigua de lo que nunca se mueve. El mar era la imagen del caos."),
  L("Name the thing that feels like it is shaking. Saying it is a first step.", "Ponle nombre a eso que sientes que tiembla. Decirlo es un primer paso.")),
 verse(46,5,5,"scene_city_dawn_01",
  L("God is present among his people, so they are held steady. Help comes as surely as morning.", "Dios está en medio de su pueblo, por eso se mantiene firme. La ayuda llega tan cierta como la mañana."),
  L("\"She\" is the city of God, Jerusalem. Dawn was when a besieged city learned whether it had survived the night.", "Se refiere a la ciudad de Dios, Jerusalén. Al amanecer una ciudad sitiada sabía si había sobrevivido a la noche."),
  L("Tomorrow morning, read one verse before opening any other app.", "Mañana por la mañana, lee un versículo antes de abrir cualquier otra aplicación.")),
 choice(L("In Psalm 46, what does the writer call God?", "En el Salmo 46, ¿cómo llama el escritor a Dios?"),
  [L("A refuge and strength", "Amparo y fortaleza"), L("A distant king", "Un rey lejano"), L("A storm on the sea", "Una tormenta en el mar")], 0,
  L("Verse 1 opens the psalm with this image.", "El versículo 1 abre el salmo con esta imagen.")),
 verse(46,7,7,"scene_hills_morning_01",
  L("This line is the chorus of the psalm: the Lord of all is with us and is our place of safety.", "Esta línea es el estribillo del salmo: el Señor de todo está con nosotros y es nuestro lugar seguro."),
  L("\"God of Jacob\" recalls a man with a troubled story whom God did not abandon.", "\"Dios de Jacob\" recuerda a un hombre con una historia difícil a quien Dios no abandonó."),
  L("Say the words \"with us\" slowly. Let that be today's short prayer.", "Di despacio las palabras \"con nosotros\". Que esa sea tu breve oración de hoy.")),
 verse(46,10,10,"scene_still_water_01",
  L("God calls people to stop striving and to recognize who he is.", "Dios llama a dejar de luchar y a reconocer quién es él."),
  L("The Hebrew verb can mean \"let go\" or \"cease\". It was first spoken into a scene of war and noise.", "El verbo hebreo puede significar \"soltar\" o \"cesar\". Se dijo primero en medio de una escena de guerra y ruido."),
  L("Sit for sixty seconds in silence. No music, no screen.", "Quédate sesenta segundos en silencio. Sin música, sin pantalla.")),
 verse(46,11,11,"scene_meadow_day_01",
  L("The psalm closes by repeating its chorus, so the reader leaves with this truth in mind.", "El salmo cierra repitiendo su estribillo, para que el lector se quede con esta verdad."),
  L("\"Selah\" probably marked a pause in the music, a moment to stop and think.", "\"Selah\" probablemente marcaba una pausa en la música, un momento para detenerse y pensar."),
  L("Choose one line from today to carry with you.", "Elige una línea de hoy para llevar contigo.")),
 missing(46,10,{"KJV":"still","WEB":"still","RV1909":"quietos"},["strong","ready","loud"],["fuertes","listos","alegres"]),
])

# ---------------------------------------------------------------- Day 3
day(L("Where help comes from", "De dónde viene el socorro"), L("Psalm 121", "Salmo 121"), 1, [
 verse(121,1,1,"scene_hills_morning_01",
  L("The traveler looks at the hills ahead and asks where help will come from.", "El viajero mira los montes que tiene delante y pregunta de dónde vendrá su socorro."),
  L("This is a pilgrim song, sung on the road up to Jerusalem. The hills could hide danger.", "Es un cántico de peregrinos, cantado en el camino de subida a Jerusalén. Los montes podían esconder peligros."),
  L("It is fine to begin with a question. Bring yours.", "Está bien empezar con una pregunta. Trae la tuya.")),
 verse(121,2,2,"scene_meadow_day_01",
  L("The answer: help comes from the Lord, the one who made everything.", "La respuesta: el socorro viene del Señor, el que hizo todas las cosas."),
  L("Calling God the maker of heaven and earth sets him above every hill and everything on it.", "Llamar a Dios hacedor de los cielos y la tierra lo pone por encima de cada monte y de todo lo que hay en él."),
  L("Look at the sky for a moment today and remember who made it.", "Mira hoy un momento el cielo y recuerda quién lo hizo.")),
 verse(121,3,3,"scene_meadow_path_01",
  L("God steadies the traveler's steps and stays attentive the whole way.", "Dios afirma los pasos del viajero y permanece atento todo el camino."),
  L("Mountain paths were steep and loose. One slip could end a journey.", "Los senderos de montaña eran empinados y sueltos. Un resbalón podía terminar el viaje."),
  L("Think of one step you are nervous to take, and ask for steadiness.", "Piensa en un paso que te pone nervioso dar, y pide firmeza.")),
 order(121,[1,2,3]),
 verse(121,4,4,"scene_night_stars_01",
  L("The one who watches over his people never drifts off.", "El que guarda a su pueblo nunca se duerme."),
  L("Travelers took turns keeping watch at night. The psalm says God needs no one to relieve him.", "Los viajeros se turnaban para vigilar de noche. El salmo dice que Dios no necesita relevo."),
  L("Tonight, let this verse be the last thing you read.", "Esta noche, que este versículo sea lo último que leas.")),
 verse(121,5,5,"scene_tree_shade_01",
  L("God is pictured as a keeper standing close enough to cast shade.", "Se describe a Dios como un guardador tan cercano que da sombra."),
  L("Under a desert sun, shade could be the difference between going on and collapsing.", "Bajo el sol del desierto, la sombra podía ser la diferencia entre seguir o desfallecer."),
  L("Where do you need shade today? Ask for it.", "¿Dónde necesitas sombra hoy? Pídela.")),
 verse(121,7,8,"scene_meadow_golden_01",
  L("The psalm ends with a wide promise of God's keeping over every departure and return.", "El salmo termina con una amplia promesa del cuidado de Dios sobre cada salida y cada regreso."),
  L("\"Going out and coming in\" was a Hebrew way of saying all of daily life.", "\"Salida y entrada\" era una forma hebrea de decir toda la vida diaria."),
  L("As you walk out the door today, recall this line.", "Al salir hoy por la puerta, recuerda esta línea.")),
 choice(L("According to Psalm 121, what does the keeper of Israel never do?", "Según el Salmo 121, ¿qué no hace nunca el que guarda a Israel?"),
  [L("Travel", "Viajar"), L("Slumber or sleep", "Adormecerse ni dormir"), L("Speak", "Hablar")], 1,
  L("See verse 4.", "Mira el versículo 4.")),
])

# ---------------------------------------------------------------- Day 4
day(L("When I am afraid", "En el día que temo"), L("Psalms 55, 56, 61, 62", "Salmos 55, 56, 61, 62"), 0, [
 verse(56,3,3,"scene_valley_dusk_01",
  L("David does not pretend he is never afraid. He says what he does when fear comes: he trusts.", "David no finge que nunca tiene miedo. Dice lo que hace cuando llega el temor: confía."),
  L("The heading of this psalm ties it to a time when David was seized by his enemies in Gath.", "El título de este salmo lo relaciona con el momento en que David fue apresado por sus enemigos en Gat."),
  L("Finish the sentence in your own words: \"When I am afraid, I will...\"", "Completa la frase con tus palabras: \"Cuando tengo miedo, voy a...\"")),
 verse(56,4,4,"scene_meadow_day_01",
  L("Trust in God and in what God has said puts human threats in proportion.", "Confiar en Dios y en lo que Dios ha dicho pone en su lugar las amenazas humanas."),
  L("\"Flesh\" here simply means mortal people, in contrast with God.", "\"La carne\" aquí significa sencillamente personas mortales, en contraste con Dios."),
  L("Whose opinion weighs on you most right now? Hold it next to this verse.", "¿La opinión de quién te pesa más ahora? Ponla al lado de este versículo.")),
 verse(56,8,8,"scene_night_stars_01",
  L("God has noticed every restless step and every tear. None of it is lost.", "Dios ha notado cada paso inquieto y cada lágrima. Nada de eso se pierde."),
  L("The image of collecting tears in a bottle is a poetic way of saying God keeps a careful record.", "La imagen de guardar lágrimas en una redoma es una forma poética de decir que Dios lleva cuenta cuidadosa."),
  L("If something has hurt lately, you can say so honestly in prayer.", "Si algo te ha dolido últimamente, puedes decirlo con honestidad en oración.")),
 missing(56,3,{"KJV":"trust","WEB":"trust","RV1909":"confío"},["hide","run","fight"],["huyo","callo","lucho"]),
 verse(55,22,22,"scene_sea_mist_01",
  L("The psalmist urges the reader to hand over what weighs on them, and says God will hold them up.", "El salmista anima al lector a entregar lo que le pesa, y dice que Dios lo sostendrá."),
  L("Psalm 55 was written after a close friend's betrayal. This line comes near the end of that pain.", "El Salmo 55 se escribió tras la traición de un amigo cercano. Esta línea llega casi al final de ese dolor."),
  L("Write your heaviest burden on paper, then pray it once and put the paper away.", "Escribe en un papel tu carga más pesada, ora por ella una vez y guarda el papel.")),
 verse(61,2,2,"scene_rock_high_01",
  L("From far away and worn out, the psalmist asks to be led to a place more solid than himself.", "Desde lejos y agotado, el salmista pide ser llevado a un lugar más firme que él mismo."),
  L("A high rock was a natural stronghold, out of reach of floods and attackers.", "Una peña alta era una fortaleza natural, fuera del alcance de inundaciones y atacantes."),
  L("Admit one thing that is too big for you. That is where this prayer starts.", "Reconoce una cosa que te queda grande. Ahí empieza esta oración.")),
 verse(62,8,8,"scene_meadow_golden_01",
  L("Everyone is invited to trust God at all times and to speak to him without holding back.", "Todos son invitados a confiar en Dios en todo tiempo y a hablarle sin guardarse nada."),
  L("\"Pour out your heart\" pictures emptying a vessel completely, like water.", "\"Derramad vuestro corazón\" describe vaciar por completo una vasija, como agua."),
  L("Spend two minutes telling God exactly how today went.", "Dedica dos minutos a contarle a Dios exactamente cómo fue tu día.")),
 choice(L("In Psalm 55:22, what are we told to do with a burden?", "En el Salmo 55:22, ¿qué se nos dice que hagamos con la carga?"),
  [L("Carry it quietly", "Llevarla en silencio"), L("Ignore it", "Ignorarla"), L("Cast it on the Lord", "Echarla sobre el Señor")], 2,
  L("The verse adds that he will sustain you.", "El versículo añade que él te sustentará.")),
])

# ---------------------------------------------------------------- Day 5
day(L("Light in the dark", "Luz en la oscuridad"), L("Psalms 27 and 139", "Salmos 27 y 139"), 0, [
 verse(27,1,1,"scene_meadow_day_01",
  L("With God as his light and safety, David asks who is left to be afraid of.", "Con Dios como su luz y salvación, David pregunta de quién habría de temer."),
  L("Light in Scripture often stands for guidance, life and God's presence.", "La luz en la Escritura suele representar guía, vida y la presencia de Dios."),
  L("Ask yourself gently: what am I afraid of today?", "Pregúntate con calma: ¿de qué tengo miedo hoy?")),
 verse(27,3,3,"scene_valley_dusk_01",
  L("Even surrounded by trouble, David says his confidence will hold.", "Aun rodeado de problemas, David dice que su confianza se mantendrá."),
  L("David spent years pursued by armies. This was not an abstract idea for him.", "David pasó años perseguido por ejércitos. Para él esto no era una idea abstracta."),
  L("Confidence here is a choice repeated daily. Make it once today.", "La confianza aquí es una decisión que se repite cada día. Tómala una vez hoy.")),
 verse(27,5,5,"scene_rock_high_01",
  L("In hard times God shelters him and sets him somewhere secure.", "En tiempos difíciles Dios lo resguarda y lo pone en un lugar seguro."),
  L("The \"pavilion\" or \"tabernacle\" recalls the tent where God's presence was worshiped.", "El \"tabernáculo\" recuerda la tienda donde se adoraba la presencia de Dios."),
  L("Picture one safe place. Thank God for it.", "Imagina un lugar seguro. Dale gracias a Dios por él.")),
 choice(L("How does Psalm 27:1 describe the Lord?", "¿Cómo describe el Salmo 27:1 al Señor?"),
  [L("My light and my salvation", "Mi luz y mi salvación"), L("My shadow", "Mi sombra"), L("My long road", "Mi largo camino")], 0,
  L("It is the first line of the psalm.", "Es la primera línea del salmo.")),
 verse(27,13,13,"scene_meadow_path_01",
  L("What kept David going was believing he would yet see God's goodness in this life.", "Lo que sostuvo a David fue creer que aún vería la bondad de Dios en esta vida."),
  L("\"The land of the living\" means here and now, not only the life to come.", "\"La tierra de los vivientes\" significa aquí y ahora, no solo la vida venidera."),
  L("Look for one sign of goodness before the day ends.", "Busca una señal de bondad antes de que termine el día.")),
 verse(27,14,14,"scene_hills_morning_01",
  L("The psalm closes with a call to wait for the Lord with courage.", "El salmo cierra con un llamado a esperar al Señor con valor."),
  L("In Hebrew, \"wait\" carries the sense of hoping with expectation, not passive delay.", "En hebreo, \"esperar\" tiene el sentido de aguardar con expectativa, no de una demora pasiva."),
  L("Is there something you are waiting on? Wait on it with God today.", "¿Hay algo que estás esperando? Espéralo hoy junto a Dios.")),
 verse(139,12,12,"scene_night_stars_01",
  L("Darkness does not hide anything from God. Night and day are alike to him.", "La oscuridad no esconde nada de Dios. Para él la noche y el día son iguales."),
  L("Psalm 139 is a meditation on how completely God knows and accompanies a person.", "El Salmo 139 es una meditación sobre cuán completamente Dios conoce y acompaña a una persona."),
  L("If tonight feels dark, read this verse once more before sleep.", "Si esta noche se siente oscura, lee este versículo una vez más antes de dormir.")),
 missing(27,1,{"KJV":"light","WEB":"light","RV1909":"luz"},["wall","song","road"],["muro","canto","senda"]),
])

# ---------------------------------------------------------------- Day 6
day(L("Near to the brokenhearted", "Cercano a los quebrantados"), L("Psalms 34, 94, 147", "Salmos 34, 94, 147"), 3, [
 verse(34,4,4,"scene_meadow_day_01",
  L("David looked for God, was answered, and was freed from his fears.", "David buscó a Dios, fue respondido y fue librado de sus temores."),
  L("The psalm is linked to a narrow escape, when David pretended to be mad to get away from a foreign king.", "El salmo se relaciona con un escape apurado, cuando David se fingió loco para huir de un rey extranjero."),
  L("Seeking can be as simple as one honest sentence. Say one.", "Buscar puede ser tan sencillo como una frase honesta. Di una.")),
 verse(34,8,8,"scene_table_evening_01",
  L("The reader is invited to experience God's goodness personally, not just hear about it.", "Se invita al lector a experimentar personalmente la bondad de Dios, no solo a oír de ella."),
  L("\"Taste\" is a deliberately physical word: find out for yourself.", "\"Gustad\" es una palabra intencionalmente física: compruébalo por ti mismo."),
  L("Recall one time you saw goodness in a hard season.", "Recuerda una vez en que viste bondad en una época difícil.")),
 verse(34,17,17,"scene_valley_dusk_01",
  L("When God's people cry out, he hears them.", "Cuando el pueblo de Dios clama, él lo oye."),
  L("The psalm is an acrostic in Hebrew: each verse begins with the next letter of the alphabet.", "El salmo es un acróstico en hebreo: cada versículo empieza con la siguiente letra del alfabeto."),
  L("You do not need polished words. A cry counts.", "No necesitas palabras pulidas. Un clamor cuenta.")),
 choice(L("In Psalm 34:8, what are we invited to do?", "En el Salmo 34:8, ¿a qué se nos invita?"),
  [L("Run and hide", "Correr y esconderse"), L("Taste and see that the Lord is good", "Gustar y ver que el Señor es bueno"), L("Count our mistakes", "Contar nuestros errores")], 1,
  L("An invitation to find out firsthand.", "Una invitación a comprobarlo de primera mano.")),
 verse(34,18,18,"scene_sea_mist_01",
  L("God draws close to people whose hearts are broken and whose spirits are crushed.", "Dios se acerca a quienes tienen el corazón quebrantado y el espíritu abatido."),
  L("Nearness is the point. The verse does not say the pain is small.", "La cercanía es lo central. El versículo no dice que el dolor sea pequeño."),
  L("Think of someone who is hurting and send them a kind message.", "Piensa en alguien que está sufriendo y envíale un mensaje amable.")),
 verse(94,19,19,"scene_tree_shade_01",
  L("When anxious thoughts multiply, God's comfort brings the psalmist joy.", "Cuando los pensamientos ansiosos se multiplican, el consuelo de Dios alegra al salmista."),
  L("Psalm 94 is a prayer about injustice. This verse is a quiet personal moment in the middle of it.", "El Salmo 94 es una oración sobre la injusticia. Este versículo es un momento personal y tranquilo en medio de ella."),
  L("List the thoughts crowding your mind, then read this verse over the list.", "Haz una lista de los pensamientos que se te agolpan y luego lee este versículo sobre la lista.")),
 verse(147,3,3,"scene_meadow_golden_01",
  L("God is pictured tending wounds, the way someone carefully bandages an injury.", "Se describe a Dios atendiendo heridas, como quien venda con cuidado una lesión."),
  L("The psalm was likely sung after the exile, when a scattered people were being gathered home.", "El salmo probablemente se cantó tras el exilio, cuando un pueblo disperso era reunido de vuelta a casa."),
  L("Healing is often slow. Be patient with yourself today.", "Sanar suele ser lento. Ten paciencia contigo hoy.")),
 missing(34,18,{"KJV":"broken","WEB":"broken","RV1909":"quebrantados"},["proud","busy","loud"],["orgullosos","ocupados","alegres"]),
])

# ---------------------------------------------------------------- Day 7
day(L("Rest, and morning", "Descanso y mañana"), L("Psalms 3, 4, 30, 91, 131, 143", "Salmos 3, 4, 30, 91, 131, 143"), 2, [
 verse(4,8,8,"scene_night_stars_01",
  L("David can lie down and sleep because his safety rests with God.", "David puede acostarse y dormir porque su seguridad descansa en Dios."),
  L("Psalm 4 is an evening prayer. It was sung with stringed instruments.", "El Salmo 4 es una oración de la tarde. Se cantaba con instrumentos de cuerda."),
  L("Make this your last thought tonight instead of one more scroll.", "Que este sea tu último pensamiento esta noche, en vez de seguir deslizando.")),
 verse(3,5,5,"scene_hills_morning_01",
  L("He slept, and he woke again, because the Lord kept him through the night.", "Durmió y volvió a despertar, porque el Señor lo sostuvo durante la noche."),
  L("The heading places this psalm when David fled from his son Absalom, one of the worst nights of his life.", "El título sitúa este salmo cuando David huía de su hijo Absalón, una de las peores noches de su vida."),
  L("Tomorrow, let \"I woke up\" be your first thank-you.", "Mañana, que \"desperté\" sea tu primer gracias.")),
 verse(30,5,5,"scene_city_dawn_01",
  L("Sorrow may stay for a night, but it does not have the last word. Joy arrives with morning.", "El lloro puede quedarse una noche, pero no tiene la última palabra. La alegría llega con la mañana."),
  L("Weeping is pictured as an overnight guest who leaves at daybreak.", "El lloro se describe como un huésped que pasa la noche y se va al amanecer."),
  L("If today was hard, remember that mornings keep coming.", "Si hoy fue difícil, recuerda que las mañanas siguen llegando.")),
 choice(L("What does Psalm 30:5 say comes in the morning?", "¿Qué dice el Salmo 30:5 que viene a la mañana?"),
  [L("Joy", "Alegría"), L("More weeping", "Más lloro"), L("Silence", "Silencio")], 0,
  L("Weeping may last a night, but joy comes in the morning.", "El lloro puede durar una noche, pero a la mañana viene la alegría.")),
 verse(143,8,8,"scene_meadow_path_01",
  L("A morning prayer: let me hear of your love, and show me which way to walk.", "Una oración de la mañana: hazme oír de tu amor y muéstrame por dónde andar."),
  L("Psalm 143 is a plea for help by someone who feels worn down and in need of direction.", "El Salmo 143 es un ruego de ayuda de alguien que se siente agotado y necesita dirección."),
  L("Pray this verse tomorrow before you check your notifications.", "Ora este versículo mañana antes de revisar tus notificaciones.")),
 verse(91,1,2,"scene_tree_shade_01",
  L("Whoever makes their home close to God lives under his protection and can call him a refuge.", "Quien hace su hogar cerca de Dios vive bajo su protección y puede llamarlo refugio."),
  L("\"Shadow\" pictures a traveler resting under a host's roof, or a chick under a wing.", "\"Sombra\" evoca a un viajero descansando bajo el techo de un anfitrión, o un polluelo bajo un ala."),
  L("Say verse 2 in the first person, as your own words.", "Di el versículo 2 en primera persona, como palabras tuyas.")),
 verse(131,2,2,"scene_meadow_golden_01",
  L("The psalmist has quieted himself, like a contented child resting with its mother.", "El salmista se ha aquietado, como un niño satisfecho que descansa con su madre."),
  L("One of the shortest psalms. It is about setting aside what is too great to grasp, and resting.", "Uno de los salmos más cortos. Trata de dejar a un lado lo que es demasiado grande para entender, y descansar."),
  L("You finished the week. Sit with that quiet for a moment.", "Terminaste la semana. Quédate un momento con esa quietud.")),
 missing(30,5,{"KJV":"morning","WEB":"morning","RV1909":"mañana"},["evening","winter","harvest"],["noche","sombra","cosecha"]),
])

content = {
 "version": 1,
 "translations": [
  {"id": "KJV", "name": "King James Version", "language": "en", "license": "publicDomain"},
  {"id": "WEB", "name": "World English Bible", "language": "en", "license": "publicDomain"},
  {"id": "RV1909", "name": "Reina-Valera 1909", "language": "es", "license": "publicDomain"},
 ],
 "journeys": [
  {"id": "psalms_anxiety", "asset": "journey_psalms", "terrain": "pasture", "seeded": True,
   "title": L("Psalms for Anxious Days", "Salmos para días de ansiedad"),
   "subtitle": L("Seven days in the Psalms", "Siete días en los Salmos"),
   "books": ["PSA"], "totalDays": 7, "days": days},
  {"id": "life_of_jesus", "asset": "journey_jesus", "terrain": "sea", "seeded": False,
   "title": L("Life of Jesus", "Vida de Jesús"), "subtitle": L("21 days in the Gospels", "21 días en los Evangelios"),
   "books": ["MAT", "MRK", "LUK", "JHN"], "totalDays": 21, "days": []},
  {"id": "genesis_14", "asset": "journey_genesis", "terrain": "desert", "seeded": False,
   "title": L("Genesis in 14 Days", "Génesis en 14 días"), "subtitle": L("From the garden to Joseph", "Del huerto a José"),
   "books": ["GEN"], "totalDays": 14, "days": []},
 ],
}
json.dump(content, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
for d in days:
    print("== Day", d["day"], d["title"]["en"])
    for c in d["cards"]:
        if c["type"] == "verse":
            r = c["ref"]; print(f'  {r["chapter"]}:{r["verseStart"]}-{r["verseEnd"]}')
            for k, v in c["text"].items(): print("     ", k, "|", v)
        elif c["type"] == "missingWord":
            for k, v in c["blanks"].items(): print("   ?", k, v["prompt"], v["options"])
print("scenes:", sorted({c["scene"] for d in days for c in d["cards"] if c["type"] == "verse"}))
