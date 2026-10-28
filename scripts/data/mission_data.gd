class_name MissionData
extends RefCounted
## Catalogo machine-readable delle 100 missioni.
## Ogni voce è dati + vincoli semantici; nessun puzzle è hardcoded nella scena.

const REGION_NAMES := [
	"Bosco delle Somiglianze",
	"Sentieri del Vento",
	"Giardino delle Quantità",
	"Ferrovia delle Serie",
	"Officina delle Stelle",
	"Valle delle Misure",
	"Biblioteca dei Suoni",
	"Mulino delle Sillabe",
	"Città delle Parole",
	"Torre delle Cento Luci",
]

const REGION_ICONS := [
	"leaf", "freccia", "flower", "train", "star",
	"trave", "nota", "nota", "casa", "star",
]

const REGION_COLORS := [
	Color("#6FAE6A"), Color("#7EC8E3"), Color("#E8A65A"), Color("#C96A4A"), Color("#7E8CD6"),
	Color("#B98A55"), Color("#8E7CC3"), Color("#E9748A"), Color("#5FA8D3"), Color("#F2C24B"),
]

const CUSTODIANS := ["Lino", "Ora", "Pina", "Tiko", "Fero", "Milla", "Eco", "Sila", "Bibi", "Astra"]

const CUSTODIAN_LINES := [
	"Guarda! Le forme si sono mescolate. Aiutami a ritrovare le somiglianze!",
	"Il vento non sa più dove andare. Mettiamo in ordine le sue indicazioni!",
	"Ogni seme aspetta il suo numero. Li contiamo insieme?",
	"I vagoni aspettano il numero giusto. Troviamo il loro ordine!",
	"Le macchine amano mettere insieme e togliere. Proviamo con le stelle!",
	"Un ponte può essere corto o lungo. Scopriamo come confrontarlo!",
	"Ascolta: ogni suono ha un simbolo. Metti il cubo sulla campana!",
	"Le parole hanno piccoli battiti. Ritroviamo le sillabe!",
	"La città cerca le sue insegne. Con i cubi possiamo ricostruirle!",
	"Ogni scoperta che hai fatto può aiutarti qui. Accendiamo la Stella!",
]

const COLORS := {
	"rosso": Color("#D95C5C"),
	"blu": Color("#4C86C6"),
	"giallo": Color("#F2C24B"),
	"verde": Color("#6DBE6D"),
	"viola": Color("#9B7BC4"),
	"arancio": Color("#E8944A"),
	"teal": Color("#4FB3A9"),
	"rosa": Color("#E88BA5"),
	"marrone": Color("#9A6B4D"),
	"grigio": Color("#9AA3AD"),
	"avorio": Color("#F7F2E7"),
	"oro": Color("#E8B84A"),
	"legno": Color("#D8B98A"),
	"scuro": Color("#4A4A5A"),
}

static func all() -> Array:
	var out: Array = []
	out.append_array(_r1())
	out.append_array(_r2())
	out.append_array(_r3())
	out.append_array(_r4())
	out.append_array(_r5())
	out.append_array(_r6())
	out.append_array(_r7())
	out.append_array(_r8())
	out.append_array(_r9())
	out.append_array(_r10())
	return out

static func by_id(id: String) -> Dictionary:
	for m in all():
		if m["id"] == id:
			return m
	return {}

static func region_missions(region: int) -> Array:
	var out: Array = []
	for m in all():
		if int(m["region"]) == region:
			out.append(m)
	return out

static func M(id: String, region: int, title: String, objective: String, instruction: String,
		kind: String, cubes: Array, sockets: Array, hints: Array, success: String,
		extra: Dictionary = {}) -> Dictionary:
	var d := {
		"id": id,
		"region": region,
		"title": title,
		"objective": objective,
		"instruction": instruction,
		"kind": kind,
		"cubes": cubes,
		"sockets": sockets,
		"hints": hints,
		"success": success,
		"version": 1,
		"dependencies": [] if id.ends_with("1") else ["%03d" % (int(id) - 1)],
	}
	d.merge(extra, true)
	return d

static func C(id: String, value: String, opts: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "value": str(value), "color": "legno"}
	d.merge(opts, true)
	if not d.has("spoken") or str(d["spoken"]) == "":
		d["spoken"] = str(d.get("label", str(value)))
	return d

static func NUM(id: String, n: int, opts: Dictionary = {}) -> Dictionary:
	var o := opts.duplicate(true)
	o["label"] = str(n)
	o["color"] = o.get("color", "avorio")
	return C(id, str(n), o)

static func LET(id: String, l: String, opts: Dictionary = {}) -> Dictionary:
	var o := opts.duplicate(true)
	o["label"] = l
	o["color"] = o.get("color", "avorio")
	if not o.has("spoken"):
		o["spoken"] = l
	return C(id, l, o)

static func SYL(id: String, s: String, opts: Dictionary = {}) -> Dictionary:
	var o := opts.duplicate(true)
	o["label"] = s
	o["color"] = o.get("color", "teal")
	return C(id, s, o)

static func WORD(id: String, w: String, opts: Dictionary = {}) -> Dictionary:
	var o := opts.duplicate(true)
	o["label"] = w
	o["color"] = o.get("color", "avorio")
	return C(id, w, o)

static func SYM(id: String, s: String, spoken: String) -> Dictionary:
	return LET(id, s, {"spoken": spoken, "icon": "maggiore" if s == ">" else ("minore" if s == "<" else "uguale")})

static func S(id: String, accepts: Variant, opts: Dictionary = {}) -> Dictionary:
	var acc: Array = []
	if accepts is Array:
		acc = accepts.duplicate()
	elif str(accepts) != "":
		acc = [str(accepts)]
	var d := {"id": id, "accepts": acc}
	d.merge(opts, true)
	return d

static func F(id: String, value: String, opts: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "accepts": [], "fixed": str(value)}
	d.merge(opts, true)
	if not d.has("fixed_label") and not d.has("fixed_icon"):
		d["fixed_label"] = str(value)
	return d

static func D(icon: String, count: int, color: String = "oro", label: String = "") -> Dictionary:
	return {"icon": icon, "count": count, "color": color, "label": label}

static func _three_hints(a: String, b: String, c: String) -> Array:
	return [a, b, c]

# ================================================================== REGIONE 1
static func _r1() -> Array:
	var out: Array = []

	out.append(M("001", 1, "La porta dei tre colori",
		"Discriminazione e raggruppamento per colore.",
		"Metti ogni fiore nell'aiuola del suo colore.",
		"group",
		[
			C("f1", "rosso", {"icon": "flower", "color": "rosso", "spoken": "Fiore rosso"}),
			C("f2", "rosso", {"icon": "flower", "color": "rosso", "spoken": "Fiore rosso"}),
			C("f3", "rosso", {"icon": "flower", "color": "rosso", "spoken": "Fiore rosso"}),
			C("f4", "blu", {"icon": "flower", "color": "blu", "spoken": "Fiore blu"}),
			C("f5", "blu", {"icon": "flower", "color": "blu", "spoken": "Fiore blu"}),
			C("f6", "blu", {"icon": "flower", "color": "blu", "spoken": "Fiore blu"}),
			C("f7", "giallo", {"icon": "flower", "color": "giallo", "spoken": "Fiore giallo"}),
			C("f8", "giallo", {"icon": "flower", "color": "giallo", "spoken": "Fiore giallo"}),
			C("f9", "giallo", {"icon": "flower", "color": "giallo", "spoken": "Fiore giallo"}),
		],
		[
			S("ar1", "rosso", {"group": "rosso", "hint_icon": "flower", "hint_color": "rosso"}),
			S("ar2", "rosso", {"group": "rosso", "hint_icon": "flower", "hint_color": "rosso"}),
			S("ar3", "rosso", {"group": "rosso", "hint_icon": "flower", "hint_color": "rosso"}),
			S("ab1", "blu", {"group": "blu", "hint_icon": "flower", "hint_color": "blu"}),
			S("ab2", "blu", {"group": "blu", "hint_icon": "flower", "hint_color": "blu"}),
			S("ab3", "blu", {"group": "blu", "hint_icon": "flower", "hint_color": "blu"}),
			S("ag1", "giallo", {"group": "giallo", "hint_icon": "flower", "hint_color": "giallo"}),
			S("ag2", "giallo", {"group": "giallo", "hint_icon": "flower", "hint_color": "giallo"}),
			S("ag3", "giallo", {"group": "giallo", "hint_icon": "flower", "hint_color": "giallo"}),
		],
		_three_hints("Guarda il colore del fiore e il colore dell'aiuola.",
			"I fiori rossi stanno tutti insieme, i blu insieme, i gialli insieme.",
			"Prendi un fiore rosso e portalo all'aiuola rossa. Poi continua con gli altri."),
		"Hai riunito i fiori dello stesso colore: tre, tre e tre!",
		{"groups": {"rosso": {"rosso": 3}, "blu": {"blu": 3}, "giallo": {"giallo": 3}}, "effect": "porta"}))

	out.append(M("002", 1, "Le case delle forme",
		"Riconoscere cerchio, quadrato e triangolo.",
		"Ogni casetta vuole due forme uguali. Guarda la forma, non il colore.",
		"group",
		[
			C("c1", "cerchio", {"icon": "circle", "color": "rosso", "spoken": "Cerchio rosso"}),
			C("c2", "cerchio", {"icon": "circle", "color": "blu", "spoken": "Cerchio blu"}),
			C("c3", "quadrato", {"icon": "square", "color": "giallo", "spoken": "Quadrato giallo"}),
			C("c4", "quadrato", {"icon": "square", "color": "verde", "spoken": "Quadrato verde"}),
			C("c5", "triangolo", {"icon": "triangle", "color": "viola", "spoken": "Triangolo viola"}),
			C("c6", "triangolo", {"icon": "triangle", "color": "arancio", "spoken": "Triangolo arancio"}),
		],
		[
			S("cc1", "cerchio", {"group": "cerchio", "hint_icon": "circle", "hint_color": "grigio"}),
			S("cc2", "cerchio", {"group": "cerchio", "hint_icon": "circle", "hint_color": "grigio"}),
			S("cq1", "quadrato", {"group": "quadrato", "hint_icon": "square", "hint_color": "grigio"}),
			S("cq2", "quadrato", {"group": "quadrato", "hint_icon": "square", "hint_color": "grigio"}),
			S("ct1", "triangolo", {"group": "triangolo", "hint_icon": "triangle", "hint_color": "grigio"}),
			S("ct2", "triangolo", {"group": "triangolo", "hint_icon": "triangle", "hint_color": "grigio"}),
		],
		_three_hints("Guarda la forma disegnata sulla casetta.",
			"Il colore non conta: conta la forma.",
			"Metti i due cerchi nella casa del cerchio, i due quadrati nella casa del quadrato e i due triangoli nella casa del triangolo."),
		"Le case hanno le loro finestre: due cerchi, due quadrati, due triangoli!",
		{"groups": {"cerchio": {"cerchio": 2}, "quadrato": {"quadrato": 2}, "triangolo": {"triangolo": 2}}, "effect": "finestre"}))

	out.append(M("003", 1, "Il gemello nascosto",
		"Identificare uguaglianze e differenze visive.",
		"Trova il gemello del cubo modello: stessa figura e stesso colore.",
		"match",
		[
			C("s1", "stella_verde", {"icon": "star", "color": "verde", "spoken": "Stella verde a cinque punte"}),
			C("s2", "stella_blu", {"icon": "star", "color": "blu", "spoken": "Stella blu"}),
			C("s3", "stella_4", {"icon": "star4", "color": "verde", "spoken": "Stella verde a quattro punte"}),
			C("s4", "fiore_verde", {"icon": "flower", "color": "verde", "spoken": "Fiore verde"}),
			C("s5", "stella_gialla", {"icon": "star", "color": "giallo", "spoken": "Stella gialla"}),
		],
		[
			S("copia", "stella_verde", {"hint_icon": "star", "hint_color": "verde", "hint_label": "COPIA"}),
		],
		_three_hints("Guarda bene il cubo modello: forma e colore.",
			"Cerca una stella verde con cinque punte.",
			"La stella verde a cinque punte è il gemello: mettila sul piedistallo COPIA."),
		"Stessa forma, stesso colore: hai trovato il gemello!",
		{"display": [D("star", 1, "verde", "MODELLO")], "effect": "sentiero"}))

	out.append(M("004", 1, "Le foglie differenti",
		"Riconoscere l'elemento non appartenente a una categoria.",
		"Metti la conchiglia nella pedana DIVERSA, poi porta le tre foglie nella cesta.",
		"match",
		[
			C("l1", "foglia", {"icon": "leaf", "color": "verde", "spoken": "Foglia verde"}),
			C("l2", "foglia", {"icon": "leaf", "color": "giallo", "spoken": "Foglia gialla"}),
			C("l3", "foglia", {"icon": "leaf", "color": "arancio", "spoken": "Foglia arancio"}),
			C("l4", "conchiglia", {"icon": "shell", "color": "rosa", "spoken": "Conchiglia"}),
		],
		[
			S("diverso", "conchiglia", {"hint_icon": "diverso", "hint_label": "DIVERSA"}),
			S("cesta1", "foglia", {"group": "cesta", "hint_icon": "leaf", "hint_color": "verde"}),
			S("cesta2", "foglia", {"group": "cesta", "hint_icon": "leaf", "hint_color": "verde"}),
			S("cesta3", "foglia", {"group": "cesta", "hint_icon": "leaf", "hint_color": "verde"}),
		],
		_three_hints("Tre oggetti sono foglie. Uno non lo è.",
			"Guarda la forma: la conchiglia non è una foglia.",
			"Metti la conchiglia in DIVERSA e tutte e tre le foglie nella cesta."),
		"La conchiglia è diversa, le foglie sono tutte insieme. Una farfalla è arrivata!",
		{"groups": {"cesta": {"foglia": 3}}, "effect": "farfalla"}))

	out.append(M("005", 1, "I due cestini",
		"Classificare per due categorie semantiche familiari.",
		"Metti il cibo nel cesto CIBO e i giocattoli nel cesto GIOCATTOLI.",
		"group",
		[
			C("mela", "mela", {"icon": "apple", "spoken": "Mela"}),
			C("pera", "pera", {"icon": "pear", "spoken": "Pera"}),
			C("banana", "banana", {"icon": "banana", "spoken": "Banana"}),
			C("palla", "palla", {"icon": "ball", "color": "blu", "spoken": "Palla"}),
			C("trottola", "trottola", {"icon": "top", "color": "rosso", "spoken": "Trottola"}),
			C("trenino", "trenino", {"icon": "train", "color": "verde", "spoken": "Trenino"}),
		],
		[
			S("c1", ["mela", "pera", "banana"], {"group": "cibo", "hint_icon": "cibo", "hint_color": "arancio"}),
			S("c2", ["mela", "pera", "banana"], {"group": "cibo", "hint_icon": "cibo", "hint_color": "arancio"}),
			S("c3", ["mela", "pera", "banana"], {"group": "cibo", "hint_icon": "cibo", "hint_color": "arancio"}),
			S("g1", ["palla", "trottola", "trenino"], {"group": "gioco", "hint_icon": "gioco", "hint_color": "viola"}),
			S("g2", ["palla", "trottola", "trenino"], {"group": "gioco", "hint_icon": "gioco", "hint_color": "viola"}),
			S("g3", ["palla", "trottola", "trenino"], {"group": "gioco", "hint_icon": "gioco", "hint_color": "viola"}),
		],
		_three_hints("Alcuni oggetti si mangiano, altri si usano per giocare.",
			"Mela, pera e banana sono cibo. Palla, trottola e trenino sono giocattoli.",
			"Metti i tre cibi nel cesto CIBO e i tre giocattoli nel cesto GIOCATTOLI."),
		"Hai diviso il cibo dai giochi: tre e tre!",
		{"groups": {"cibo": {"mela": 1, "pera": 1, "banana": 1}, "gioco": {"palla": 1, "trottola": 1, "trenino": 1}}, "effect": "lanterne"}))

	out.append(M("006", 1, "Le perle in fila",
		"Riconoscere e completare una sequenza alternata AB.",
		"La collana continua con un ritmo: cerchio, quadrato, cerchio, quadrato… cosa manca?",
		"pattern",
		[
			C("p1", "cerchio", {"icon": "circle", "color": "oro", "spoken": "Cerchio"}),
			C("p2", "quadrato", {"icon": "square", "color": "teal", "spoken": "Quadrato"}),
			C("p3", "triangolo", {"icon": "triangle", "color": "rosa", "spoken": "Triangolo"}),
		],
		[
			F("f1", "cerchio", {"fixed_icon": "circle", "fixed_color": "oro"}),
			F("f2", "quadrato", {"fixed_icon": "square", "fixed_color": "teal"}),
			F("f3", "cerchio", {"fixed_icon": "circle", "fixed_color": "oro"}),
			F("f4", "quadrato", {"fixed_icon": "square", "fixed_color": "teal"}),
			S("vuoto", "cerchio", {"hint_label": "?"}),
		],
		_three_hints("Guarda il ritmo: cerchio, quadrato, cerchio, quadrato.",
			"Dopo un quadrato torna il cerchio.",
			"La quinta perla è un cerchio. Mettilo nell'ultimo incastro."),
		"Cerchio, quadrato, cerchio, quadrato, cerchio: la collana è completa!",
		{"effect": "collana"}))

	out.append(M("007", 1, "La danza delle tre foglie",
		"Continuare un pattern ABC.",
		"Il ramo segue un ritmo di tre colori: rosso, blu, giallo. Cosa viene dopo?",
		"pattern",
		[
			C("r", "rosso", {"icon": "flower", "color": "rosso", "spoken": "Rosso"}),
			C("b", "blu", {"icon": "flower", "color": "blu", "spoken": "Blu"}),
			C("g", "giallo", {"icon": "flower", "color": "giallo", "spoken": "Giallo"}),
		],
		[
			F("f1", "rosso", {"fixed_icon": "flower", "fixed_color": "rosso"}),
			F("f2", "blu", {"fixed_icon": "flower", "fixed_color": "blu"}),
			F("f3", "giallo", {"fixed_icon": "flower", "fixed_color": "giallo"}),
			F("f4", "rosso", {"fixed_icon": "flower", "fixed_color": "rosso"}),
			F("f5", "blu", {"fixed_icon": "flower", "fixed_color": "blu"}),
			S("vuoto", "giallo", {"hint_label": "?"}),
		],
		_three_hints("Il ritmo è rosso, blu, giallo e poi ricomincia.",
			"Dopo il rosso e il blu arriva il giallo.",
			"La sesta posizione vuole il giallo."),
		"Rosso, blu, giallo: il ramo fiorisce con il ritmo giusto!",
		{"effect": "fioritura"}))

	out.append(M("008", 1, "Il tavolo dei due indizi",
		"Classificazione per due attributi contemporanei.",
		"Ogni pedana vuole due cubi con la stessa forma e lo stesso colore.",
		"group",
		[
			C("cr1", "cr", {"icon": "circle", "color": "rosso", "spoken": "Cerchio rosso"}),
			C("cr2", "cr", {"icon": "circle", "color": "rosso", "spoken": "Cerchio rosso"}),
			C("cb1", "cb", {"icon": "circle", "color": "blu", "spoken": "Cerchio blu"}),
			C("cb2", "cb", {"icon": "circle", "color": "blu", "spoken": "Cerchio blu"}),
			C("sr1", "sr", {"icon": "square", "color": "rosso", "spoken": "Quadrato rosso"}),
			C("sr2", "sr", {"icon": "square", "color": "rosso", "spoken": "Quadrato rosso"}),
			C("sb1", "sb", {"icon": "square", "color": "blu", "spoken": "Quadrato blu"}),
			C("sb2", "sb", {"icon": "square", "color": "blu", "spoken": "Quadrato blu"}),
		],
		[
			S("g1", "cr", {"group": "cr", "hint_icon": "circle", "hint_color": "rosso"}),
			S("g2", "cr", {"group": "cr", "hint_icon": "circle", "hint_color": "rosso"}),
			S("g3", "cb", {"group": "cb", "hint_icon": "circle", "hint_color": "blu"}),
			S("g4", "cb", {"group": "cb", "hint_icon": "circle", "hint_color": "blu"}),
			S("g5", "sr", {"group": "sr", "hint_icon": "square", "hint_color": "rosso"}),
			S("g6", "sr", {"group": "sr", "hint_icon": "square", "hint_color": "rosso"}),
			S("g7", "sb", {"group": "sb", "hint_icon": "square", "hint_color": "blu"}),
			S("g8", "sb", {"group": "sb", "hint_icon": "square", "hint_color": "blu"}),
		],
		_three_hints("Guarda due cose insieme: la forma e il colore.",
			"Il cerchio rosso va con il cerchio rosso, non con il quadrato rosso.",
			"Ci sono due cubi per ogni coppia: cerchio rosso, cerchio blu, quadrato rosso, quadrato blu."),
		"Due indizi insieme: forma e colore! Quattro gruppi completi.",
		{"groups": {"cr": {"cr": 2}, "cb": {"cb": 2}, "sr": {"sr": 2}, "sb": {"sb": 2}}, "effect": "alberelli"}))

	out.append(M("009", 1, "I funghi dal più piccolo",
		"Seriazione di grandezze discrete.",
		"Metti i funghi dal più basso al più alto.",
		"sequence",
		[
			C("m1", "1", {"icon": "fungo", "spoken": "Fungo piccolo", "scale": 0.62}),
			C("m2", "2", {"icon": "fungo", "spoken": "Fungo un po' più alto", "scale": 0.78}),
			C("m3", "3", {"icon": "fungo", "spoken": "Fungo medio", "scale": 0.9}),
			C("m4", "4", {"icon": "fungo", "spoken": "Fungo alto", "scale": 1.0}),
			C("m5", "5", {"icon": "fungo", "spoken": "Fungo il più alto", "scale": 1.12}),
		],
		[
			S("p1", "1", {"hint_label": ""}), S("p2", "2", {"hint_label": ""}),
			S("p3", "3", {"hint_label": ""}), S("p4", "4", {"hint_label": ""}),
			S("p5", "5", {"hint_label": ""}),
		],
		_three_hints("Guarda l'altezza dei funghi.",
			"Il primo posto è per il fungo più basso.",
			"Metti i funghi in ordine: il più piccolo, poi via via i più alti."),
		"Dal più basso al più alto: la scalinata è cresciuta!",
		{"effect": "scalinata"}))

	out.append(M("010", 1, "La radice maestra",
		"Integrare classificazione e pattern.",
		"Completa la sequenza e porta un cerchio e un quadrato nei due cestini.",
		"composite",
		[
			C("cr", "cerchio_rosso", {"icon": "circle", "color": "rosso", "spoken": "Cerchio rosso"}),
			C("sb", "quadrato_blu", {"icon": "square", "color": "blu", "spoken": "Quadrato blu"}),
			C("cb", "cerchio_blu", {"icon": "circle", "color": "blu", "spoken": "Cerchio blu"}),
			C("sr", "quadrato_rosso", {"icon": "square", "color": "rosso", "spoken": "Quadrato rosso"}),
			C("cg", "cerchio_giallo", {"icon": "circle", "color": "giallo", "spoken": "Cerchio giallo"}),
			C("sg", "quadrato_giallo", {"icon": "square", "color": "giallo", "spoken": "Quadrato giallo"}),
		],
		[
			F("s1", "cerchio_rosso", {"fixed_icon": "circle", "fixed_color": "rosso"}),
			F("s2", "quadrato_blu", {"fixed_icon": "square", "fixed_color": "blu"}),
			F("s3", "cerchio_rosso", {"fixed_icon": "circle", "fixed_color": "rosso"}),
			S("s4", "quadrato_blu", {"hint_label": "?"}),
			S("cesta_c", ["cerchio_blu", "cerchio_giallo"], {"hint_icon": "cesta", "hint_label": "CERCHIO"}),
			S("cesta_s", ["quadrato_rosso", "quadrato_giallo"], {"hint_icon": "cesta", "hint_label": "QUADRATO"}),
		],
		_three_hints("La sequenza alterna cerchio rosso e quadrato blu.",
			"Dopo il cerchio rosso arriva il quadrato blu.",
			"Il quarto incastro vuole il quadrato blu. Poi metti un cerchio e un quadrato nei cestini."),
		"Sequenza e cestini: la prima Radice della Chiarezza si accende!",
		{"effect": "radice", "subs": {"sequenza": ["s4"], "cesti": ["cesta_c", "cesta_s"]}}))

	return out

# ================================================================== REGIONE 2
static func _r2() -> Array:
	var out: Array = []

	out.append(M("011", 2, "Davanti alla fontana",
		"Relazioni spaziali davanti/dietro.",
		"Metti il sole davanti alla fontana e la luna dietro.",
		"match",
		[
			C("sole", "sole", {"icon": "sun", "color": "giallo", "spoken": "Sole"}),
			C("luna", "luna", {"icon": "moon", "color": "blu", "spoken": "Luna"}),
		],
		[
			S("davanti", "sole", {"hint_icon": "davanti", "hint_label": "DAVANTI"}),
			S("dietro", "luna", {"hint_icon": "dietro", "hint_label": "DIETRO"}),
		],
		_three_hints("La freccia sul terreno indica il davanti.",
			"Il sole sta dove punta la freccia, la luna dalla parte opposta.",
			"Metti il sole in DAVANTI e la luna in DIETRO."),
		"Davanti e dietro: la ruota del vento comincia a girare!",
		{"effect": "ruota"}))

	out.append(M("012", 2, "I lati del ponte",
		"Relazioni destra/sinistra in un sistema di riferimento visibile.",
		"Il pupazzo ha il guanto rosso sulla sua mano destra. Metti la mano a destra e il piede a sinistra.",
		"match",
		[
			C("mano", "mano", {"icon": "hand", "color": "arancio", "spoken": "Mano"}),
			C("piede", "piede", {"icon": "foot", "color": "blu", "spoken": "Piede"}),
		],
		[
			S("destra", "mano", {"hint_icon": "destra", "hint_label": "DESTRA"}),
			S("sinistra", "piede", {"hint_icon": "sinistra", "hint_label": "SINISTRA"}),
		],
		_three_hints("Guarda il guanto rosso: è sulla mano destra del pupazzo.",
			"Il cubo MANO va dal lato del guanto rosso.",
			"Mano a destra, piede a sinistra."),
		"Il ponte ha i suoi due lati: una campana risuona!",
		{"effect": "campana"}))

	out.append(M("013", 2, "Sopra e sotto",
		"Orientamento verticale.",
		"Metti l'uccello sulla mensola SOPRA e la talpa in quella SOTTO.",
		"match",
		[
			C("uccello", "uccello", {"icon": "bird", "color": "blu", "spoken": "Uccello"}),
			C("talpa", "talpa", {"icon": "mole", "color": "marrone", "spoken": "Talpa"}),
		],
		[
			S("sopra", "uccello", {"hint_icon": "sopra", "hint_label": "SOPRA"}),
			S("sotto", "talpa", {"hint_icon": "sotto", "hint_label": "SOTTO"}),
		],
		_three_hints("L'uccello vola in alto. La talpa scava in basso.",
			"La mensola alta è per l'uccello.",
			"Uccello SOPRA, talpa SOTTO."),
		"L'uccello in alto, la talpa in basso: il passaggio si apre!",
		{"effect": "passaggio"}))

	out.append(M("014", 2, "Dentro o fuori?",
		"Contenimento e confini spaziali.",
		"Metti la pecora DENTRO il recinto e l'aquilone FUORI.",
		"match",
		[
			C("pecora", "pecora", {"icon": "sheep", "color": "avorio", "spoken": "Pecora"}),
			C("aquilone", "aquilone", {"icon": "kite", "color": "rosso", "spoken": "Aquilone"}),
		],
		[
			S("dentro", "pecora", {"hint_icon": "dentro", "hint_label": "DENTRO"}),
			S("fuori", "aquilone", {"hint_icon": "fuori", "hint_label": "FUORI"}),
		],
		_three_hints("DENTRO significa dentro il recinto. FUORI significa fuori.",
			"La pecora resta nel prato chiuso.",
			"Pecora DENTRO, aquilone FUORI."),
		"La pecora è al sicuro dentro, l'aquilone vola fuori. Sbocciano le margherite!",
		{"effect": "margherite"}))

	out.append(M("015", 2, "Vicino e lontano",
		"Distanza relativa da un punto di riferimento.",
		"Il faro è al centro. Metti la candela VICINO al faro e la nave LONTANO.",
		"match",
		[
			C("candela", "candela", {"icon": "candle", "color": "giallo", "spoken": "Candela"}),
			C("nave", "nave", {"icon": "ship", "color": "blu", "spoken": "Nave"}),
		],
		[
			S("vicino", "candela", {"hint_icon": "vicino", "hint_label": "VICINO"}),
			S("lontano", "nave", {"hint_icon": "lontano", "hint_label": "LONTANO"}),
		],
		_three_hints("Guarda dove sono i due ripiani rispetto al faro.",
			"Il ripiano vicino è a due passi dal faro.",
			"Candela VICINO, nave LONTANO."),
		"Il faro si accende: vicino e lontano ora si vedono bene!",
		{"effect": "faro"}))

	out.append(M("016", 2, "Il sentiero delle frecce",
		"Eseguire un percorso di due istruzioni.",
		"Guida l'animaletto alla mela: prima SU, poi DESTRA.",
		"route",
		[
			C("su", "SU", {"icon": "arrow_up", "color": "verde", "spoken": "Su"}),
			C("destra", "DESTRA", {"icon": "arrow_right", "color": "arancio", "spoken": "Destra"}),
		],
		[
			S("step1", ""), S("step2", ""),
		],
		_three_hints("L'animaletto deve salire e poi andare a destra.",
			"Il primo passo è SU.",
			"Metti SU nel primo incastro e DESTRA nel secondo."),
		"Su, destra: l'animaletto ha raggiunto la mela!",
		{"route": {"size": 3, "start": [1, 2], "goal": [2, 1], "blocked": [],
			"sockets": ["step1", "step2"], "solution": ["SU", "DESTRA"]}, "effect": "mela"}))

	out.append(M("017", 2, "La strada che gira",
		"Comprendere orientamento e rotazione semplice.",
		"Il carro deve arrivare in alto a destra senza passare dal centro chiuso. Programma quattro passi.",
		"route",
		[
			C("su1", "SU", {"icon": "arrow_up", "color": "verde", "spoken": "Su"}),
			C("su2", "SU", {"icon": "arrow_up", "color": "verde", "spoken": "Su"}),
			C("de1", "DESTRA", {"icon": "arrow_right", "color": "arancio", "spoken": "Destra"}),
			C("de2", "DESTRA", {"icon": "arrow_right", "color": "arancio", "spoken": "Destra"}),
			C("giu", "GIÙ", {"icon": "arrow_down", "color": "rosa", "spoken": "Giù"}),
		],
		[
			S("step1", ""), S("step2", ""), S("step3", ""), S("step4", ""),
		],
		_three_hints("Il centro è chiuso: sali lungo la colonna di sinistra.",
			"Servono due passi SU e due passi DESTRA.",
			"Metti SU, SU, DESTRA, DESTRA."),
		"Il carro del vento ha trovato la strada senza il centro!",
		{"route": {"size": 3, "start": [0, 2], "goal": [2, 0], "blocked": [[1, 1]],
			"sockets": ["step1", "step2", "step3", "step4"], "solution": ["SU", "SU", "DESTRA", "DESTRA"]}, "effect": "carro"}))

	out.append(M("018", 2, "Prima, durante, dopo",
		"Ordinare tre eventi quotidiani.",
		"Metti in ordine: prima il seme, poi il germoglio, poi il fiore.",
		"sequence",
		[
			C("seme", "seme", {"icon": "seed", "color": "marrone", "spoken": "Seme"}),
			C("germoglio", "germoglio", {"icon": "germoglio", "color": "verde", "spoken": "Germoglio"}),
			C("fiore", "fiore", {"icon": "flower", "color": "rosa", "spoken": "Fiore"}),
		],
		[
			S("p1", "seme", {"hint_label": "1"}), S("p2", "germoglio", {"hint_label": "2"}),
			S("p3", "fiore", {"hint_label": "3"}),
		],
		_three_hints("Come cresce una pianta? Prima il seme.",
			"Il germoglio viene dopo il seme e prima del fiore.",
			"Seme, germoglio, fiore: questo è l'ordine."),
		"Seme, germoglio, fiore: il giardino respira!",
		{"effect": "giardino", "display": [D("seed", 1, "marrone"), D("germoglio", 1, "verde"), D("flower", 1, "rosa")]}))

	out.append(M("019", 2, "Il giorno del sole",
		"Sequenza temporale prevedibile.",
		"Metti in ordine la giornata: mattino, mezzogiorno, tramonto, notte.",
		"sequence",
		[
			C("mattino", "mattino", {"icon": "sunrise", "color": "giallo", "spoken": "Mattino"}),
			C("mezzogiorno", "mezzogiorno", {"icon": "sun", "color": "oro", "spoken": "Mezzogiorno"}),
			C("tramonto", "tramonto", {"icon": "sunset", "color": "arancio", "spoken": "Tramonto"}),
			C("notte", "notte", {"icon": "night", "color": "blu", "spoken": "Notte"}),
		],
		[
			S("p1", "mattino", {"hint_label": "1"}), S("p2", "mezzogiorno", {"hint_label": "2"}),
			S("p3", "tramonto", {"hint_label": "3"}), S("p4", "notte", {"hint_label": "4"}),
		],
		_three_hints("Il sole sorge al mattino.",
			"Dopo il mattino arriva mezzogiorno, poi il tramonto.",
			"Mattino, mezzogiorno, tramonto, notte."),
		"Il cielo ha ritrovato il suo giro: il vento apre la rotta!",
		{"effect": "cielo"}))

	out.append(M("020", 2, "La bussola delle quattro prove",
		"Integrare posizioni, contenimento e sequenza.",
		"Metti la nuvola SOPRA, il sasso SOTTO, la farfalla DENTRO. Poi guida la luce: SU, DESTRA.",
		"composite",
		[
			C("nuvola", "nuvola", {"icon": "cloud", "color": "avorio", "spoken": "Nuvola"}),
			C("sasso", "sasso", {"icon": "rock", "color": "grigio", "spoken": "Sasso"}),
			C("farfalla", "farfalla", {"icon": "butterfly", "color": "rosa", "spoken": "Farfalla"}),
			C("su", "SU", {"icon": "arrow_up", "color": "verde", "spoken": "Su"}),
			C("destra", "DESTRA", {"icon": "arrow_right", "color": "arancio", "spoken": "Destra"}),
		],
		[
			S("sopra", "nuvola", {"hint_icon": "sopra", "hint_label": "SOPRA"}),
			S("sotto", "sasso", {"hint_icon": "sotto", "hint_label": "SOTTO"}),
			S("dentro", "farfalla", {"hint_icon": "dentro", "hint_label": "DENTRO"}),
			S("r1", ""), S("r2", ""),
		],
		_three_hints("Tre oggetti hanno un posto. La luce ha due passi.",
			"Nuvola in alto, sasso in basso, farfalla dentro il portale.",
			"Nuvola SOPRA, sasso SOTTO, farfalla DENTRO; poi SU e DESTRA."),
		"Posizioni e percorso: la Bussola di Ora illumina la seconda regione!",
		{"route": {"size": 2, "start": [0, 1], "goal": [1, 0], "blocked": [],
			"sockets": ["r1", "r2"], "solution": ["SU", "DESTRA"]},
			"subs": {"posizioni": ["sopra", "sotto", "dentro"], "percorso": ["r1", "r2"]}, "effect": "bussola"}))

	return out

# ================================================================== REGIONE 3
static func _r3() -> Array:
	var out: Array = []

	out.append(M("021", 3, "Uno per ciascuno",
		"Corrispondenza biunivoca.",
		"Ogni coniglietto vuole una carota. Metti una carota in ogni casetta.",
		"match",
		[
			C("car1", "carota", {"icon": "carrot", "spoken": "Carota"}),
			C("car2", "carota", {"icon": "carrot", "spoken": "Carota"}),
			C("car3", "carota", {"icon": "carrot", "spoken": "Carota"}),
			C("car4", "carota", {"icon": "carrot", "spoken": "Carota"}),
			C("palla1", "palla", {"icon": "ball", "color": "blu", "spoken": "Palla"}),
			C("palla2", "palla", {"icon": "ball", "color": "rosso", "spoken": "Palla"}),
		],
		[
			S("casa1", "carota", {"hint_icon": "rabbit"}), S("casa2", "carota", {"hint_icon": "rabbit"}),
			S("casa3", "carota", {"hint_icon": "rabbit"}), S("casa4", "carota", {"hint_icon": "rabbit"}),
		],
		_three_hints("Ci sono quattro coniglietti e quattro carote.",
			"Una carota per ogni casetta.",
			"Metti una carota in ciascuna delle quattro case. Le palle non servono."),
		"Una carota per ciascuno: uno, due, tre, quattro!",
		{"display": [D("rabbit", 4, "avorio"), D("carrot", 4, "arancio")], "effect": "casette"}))

	out.append(M("022", 3, "Il prato del tre",
		"Contare oggetti fino a tre.",
		"Conta le coccinelle e metti il numero giusto nella pedana NUMERO.",
		"cardinality",
		[NUM("n1", 1), NUM("n2", 2), NUM("n3", 3)],
		[S("numero", "3", {"hint_label": "?"})],
		_three_hints("Tocca ogni coccinella con gli occhi: una, due, tre.",
			"Il numero viene dopo il due.",
			"Ci sono tre coccinelle: metti il cubo 3."),
		"Tre coccinelle, numero tre: i fiori spuntano!",
		{"display": [D("ladybug", 3, "rosso")], "effect": "fiori"}))

	out.append(M("023", 3, "Le cinque campanelle",
		"Riconoscere cardinalità cinque.",
		"Conta le campane e metti il numero giusto.",
		"cardinality",
		[NUM("n4", 4), NUM("n5", 5), NUM("n6", 6)],
		[S("numero", "5", {"hint_label": "?"})],
		_three_hints("Conta le campane una volta sola.",
			"Le campane sono quattro più una.",
			"Ci sono cinque campane: metti il cubo 5."),
		"Cinque campane: risuona un accordo nella biblioteca!",
		{"display": [D("bell", 5, "oro")], "effect": "accordo"}))

	out.append(M("024", 3, "Zero lucciole",
		"Comprendere la quantità zero.",
		"Una lanterna è vuota, l'altra ha due lucciole. Metti 0 e 2 al posto giusto.",
		"match",
		[NUM("n0", 0), NUM("n2", 2)],
		[
			S("vuota", "0", {"hint_icon": "lantern_empty"}),
			S("piena", "2", {"hint_icon": "lantern_full"}),
		],
		_three_hints("Guarda dentro le lanterne.",
			"La lanterna vuota non ha nessuna lucciola: zero.",
			"Metti 0 sulla lanterna vuota e 2 su quella con due lucciole."),
		"Zero significa nessuna lucciola. La lanterna vuota ora emette una luce gentile!",
		{"display": [D("lantern_empty", 1, "grigio"), D("firefly", 2, "giallo")], "effect": "luce"}))

	out.append(M("025", 3, "Il dado della fortuna",
		"Riconoscimento rapido di configurazioni 1–6.",
		"Guarda i puntini del dado e abbina la cifra giusta. Puoi contarli!",
		"match",
		[NUM("n2", 2), NUM("n4", 4), NUM("n6", 6), NUM("n3", 3)],
		[
			S("d2", "2", {"hint_icon": "dado2"}),
			S("d4", "4", {"hint_icon": "dado4"}),
			S("d6", "6", {"hint_icon": "dado6"}),
		],
		_three_hints("Conta i puntini di ogni dado.",
			"Due puntini, quattro puntini, sei puntini.",
			"Metti 2 sul dado con due puntini, 4 su quello con quattro, 6 su quello con sei."),
		"I dadi hanno trovato le loro cifre: tre fontane si accendono!",
		{"effect": "fontane"}))

	out.append(M("026", 3, "Le mani contano",
		"Associare dita, quantità e cifra.",
		"Guarda quante dita sono alzate e metti la cifra corrispondente.",
		"match",
		[NUM("n1", 1), NUM("n3", 3), NUM("n5", 5), NUM("n4", 4)],
		[
			S("m1", "1", {"hint_icon": "mano1"}),
			S("m3", "3", {"hint_icon": "mano3"}),
			S("m5", "5", {"hint_icon": "mano5"}),
		],
		_three_hints("Conta le dita alzate, una per una.",
			"La mano con tre dita vuole il numero tre.",
			"1 con una mano, 3 con tre dita, 5 con cinque dita."),
		"Le dita e i numeri si sono incontrati: nasce l'albero delle mani!",
		{"effect": "albero"}))

	out.append(M("027", 3, "Gli otto semi",
		"Contare fino a otto con strategia.",
		"Conta gli otto semi e scegli il numero giusto.",
		"cardinality",
		[NUM("n6", 6), NUM("n7", 7), NUM("n8", 8), NUM("n9", 9)],
		[S("numero", "8", {"hint_label": "?"})],
		_three_hints("I semi sono in due file da quattro.",
			"Quattro più quattro fa otto.",
			"Ci sono otto semi: metti il cubo 8."),
		"Otto semi, due file da quattro: l'orto è verde!",
		{"display": [D("seed", 8, "marrone")], "effect": "orto"}))

	out.append(M("028", 3, "Il vaso del dieci",
		"Contare fino a dieci e associare 10.",
		"Il telaio ha due file da cinque gemme. Quante gemme ci sono?",
		"cardinality",
		[NUM("n9", 9), NUM("n10", 10), NUM("n11", 11)],
		[S("numero", "10", {"hint_label": "?"})],
		_three_hints("Guarda le due file da cinque.",
			"Cinque più cinque fa dieci.",
			"Ci sono dieci gemme: metti il cubo 10."),
		"Due cinquine fanno dieci: il vaso illumina la piazza!",
		{"display": [D("gem", 10, "teal")], "effect": "vaso"}))

	out.append(M("029", 3, "Più, meno, uguale",
		"Confrontare quantità concrete piccole.",
		"Confronta i gruppi: 3 mele e 5 pere, poi 4 fiori e 4 sassi.",
		"compare",
		[
			C("piu", "piu", {"label": "PIÙ", "icon": "piu", "color": "verde", "spoken": "Più"}),
			C("meno", "meno", {"label": "MENO", "icon": "meno", "color": "arancio", "spoken": "Meno"}),
			C("uguale", "uguale", {"label": "UGUALE", "icon": "uguale", "color": "blu", "spoken": "Uguale"}),
		],
		[
			S("primo", "meno", {"hint_label": "3  ?  5", "hint_icon": "apple"}),
			S("secondo", "uguale", {"hint_label": "4  ?  4", "hint_icon": "flower"}),
		],
		_three_hints("Guarda quale gruppo ha meno oggetti.",
			"Tre è meno di cinque. Quattro è uguale a quattro.",
			"Prima pedana: MENO. Seconda pedana: UGUALE."),
		"3 è meno di 5, 4 è uguale a 4: Pina apre due cassetti!",
		{"display": [D("apple", 3, "rosso"), D("pear", 5, "verde"),
			D("flower", 4, "rosa"), D("rock", 4, "grigio")], "effect": "cassetti"}))

	out.append(M("030", 3, "Il grande orto dei numeri",
		"Integrare corrispondenza e cifre 0–10.",
		"Ogni aiuola ha un colore. Conta i semi e metti la cifra giusta.",
		"match",
		[
			NUM("n0", 0), NUM("n2", 2), NUM("n5", 5), NUM("n6", 6),
			NUM("n8", 8), NUM("n10", 10),
		],
		[
			S("a0", "0", {"hint_label": "?"}),
			S("a2", "2", {"hint_label": "?"}),
			S("a6", "6", {"hint_label": "?"}),
			S("a10", "10", {"hint_label": "?"}),
		],
		_three_hints("Conta i semi di ogni aiuola, una aiuola alla volta.",
			"La prima è vuota: zero. La seconda ha due semi.",
			"0, 2, 6, 10: metti queste cifre nelle aiuole."),
		"Vuoto, due, sei, dieci: germoglia la Pietra Magica del Giardino!",
		{"display": [D("prato", 1, "verde", "0"), D("seed", 2, "marrone", "2"),
			D("seed", 6, "marrone", "6"), D("seed", 10, "marrone", "10")], "effect": "runa_giardino"}))

	return out


# ================================================================== REGIONE 4
static func _r4() -> Array:
	var out: Array = []

	out.append(M("031", 4, "Il trenino da uno a cinque",
		"Ordinare 1–5.",
		"La locomotiva parte per prima. Metti i vagoni in ordine da 1 a 5.",
		"sequence",
		[NUM("n1", 1), NUM("n2", 2), NUM("n3", 3), NUM("n4", 4), NUM("n5", 5)],
		[
			S("v1", "1", {"hint_icon": "train"}), S("v2", "2", {"hint_icon": "train"}),
			S("v3", "3", {"hint_icon": "train"}), S("v4", "4", {"hint_icon": "train"}),
			S("v5", "5", {"hint_icon": "train"}),
		],
		_three_hints("Il treno parte dalla locomotiva e cresce di uno.",
			"Dopo il due viene il tre.",
			"Uno, due, tre, quattro, cinque: questo è l'ordine."),
		"Il trenino ha i suoi vagoni in fila: parte piano piano!",
		{"effect": "treno"}))

	out.append(M("032", 4, "Il numero perduto",
		"Numero precedente/successivo entro 10.",
		"La fila è 4, 5, vuoto, 7. Quale numero manca?",
		"match",
		[NUM("n3", 3), NUM("n6", 6), NUM("n8", 8)],
		[
			F("f4", "4"), F("f5", "5"), S("vuoto", "6", {"hint_label": "?"}), F("f7", "7"),
		],
		_three_hints("Ogni numero è uno in più del precedente.",
			"Dopo il cinque arriva il sei.",
			"Manca il 6: mettilo tra il 5 e il 7."),
		"Il numero perduto è tornato: il treno conta quattro, cinque, sei, sette!",
		{"effect": "vagone"}))

	out.append(M("033", 4, "Il binario all'indietro",
		"Ordine decrescente entro 5.",
		"Il treno va all'indietro: 5, vuoto, 3. Quale numero manca?",
		"match",
		[NUM("n4", 4), NUM("n2", 2), NUM("n6", 6)],
		[
			F("f5", "5"), S("vuoto", "4", {"hint_label": "?"}), F("f3", "3"),
		],
		_three_hints("Il treno scende: cinque, quattro, tre.",
			"Tra il 5 e il 3 c'è il 4.",
			"Metti il 4 nel vagone vuoto."),
		"Cinque, quattro, tre: il binario d'argento si accende!",
		{"effect": "binario"}))

	out.append(M("034", 4, "Tra sette e nove",
		"Numero intermedio entro 10.",
		"Le torri sono 7, vuoto, 9. Quale numero sta in mezzo?",
		"match",
		[NUM("n6", 6), NUM("n8", 8), NUM("n10", 10)],
		[
			F("f7", "7"), S("vuoto", "8", {"hint_label": "?"}), F("f9", "9"),
		],
		_three_hints("Tra il 7 e il 9 c'è un numero.",
			"Sette più uno fa otto.",
			"Metti l'8 tra il 7 e il 9."),
		"Il ponte si allunga: sette, otto, nove!",
		{"effect": "ponte"}))

	out.append(M("035", 4, "Le due montagne",
		"Confrontare numeri usando quantità e simboli.",
		"Una montagna ha 4 pietre, l'altra 6. Metti il simbolo giusto tra 4 e 6.",
		"compare",
		[SYM("gt", ">", "Maggiore"), SYM("lt", "<", "Minore"), SYM("eq", "=", "Uguale")],
		[
			S("confronto", "<", {"hint_label": "4  ?  6"}),
		],
		_three_hints("Quattro è meno di sei.",
			"Il simbolo con la punta verso sinistra si legge MENO.",
			"Tra 4 e 6 va il simbolo minore: <."),
		"Quattro è meno di sei: la montagna più alta risplende!",
		{"display": [D("rock", 4, "grigio"), D("rock", 6, "grigio")], "effect": "montagna"}))

	out.append(M("036", 4, "Un altro confronto",
		"Confronti tra 8, 3 e 5.",
		"Guarda i due pannelli: 8 ? 3 e 5 ? 5. Scegli i simboli.",
		"compare",
		[
			SYM("gt1", ">", "Maggiore"), SYM("gt2", ">", "Maggiore"),
			SYM("lt1", "<", "Minore"), SYM("lt2", "<", "Minore"),
			SYM("eq1", "=", "Uguale"), SYM("eq2", "=", "Uguale"),
		],
		[
			S("p1", ">", {"hint_label": "8  ?  3"}),
			S("p2", "=", {"hint_label": "5  ?  5"}),
		],
		_three_hints("Otto è più di tre. Cinque è uguale a cinque.",
			"Il simbolo con la punta verso il numero più piccolo indica il maggiore.",
			"8 > 3 e 5 = 5."),
		"8 è maggiore di 3, 5 è uguale a 5: due semafori diventano verdi!",
		{"effect": "semafori"}))

	out.append(M("037", 4, "Da dieci a quindici",
		"Estendere una sequenza fino a 15.",
		"La fila è 10, 11, vuoto, 13, vuoto, 15. Completa i due vagoni.",
		"match",
		[NUM("n12", 12), NUM("n14", 14), NUM("n16", 16), NUM("n9", 9)],
		[
			F("f10", "10"), F("f11", "11"), S("v12", "12", {"hint_label": "?"}),
			F("f13", "13"), S("v14", "14", {"hint_label": "?"}), F("f15", "15"),
		],
		_three_hints("La fila cresce di uno.",
			"Dopo l'11 viene il 12.",
			"Nel terzo vagone va 12, nel quinto va 14."),
		"Dieci, undici, dodici, tredici, quattordici, quindici: il trenino fischia!",
		{"effect": "fischio"}))

	out.append(M("038", 4, "Due decine in viaggio",
		"Associare 10+unità ai numeri 11–19.",
		"Un vagone ha dieci palline più due, l'altro dieci più sette. Abbina i numeri.",
		"match",
		[NUM("n12", 12), NUM("n17", 17), NUM("n11", 11), NUM("n19", 19)],
		[
			S("m12", "12", {"hint_label": "10 + 2"}),
			S("m17", "17", {"hint_label": "10 + 7"}),
		],
		_three_hints("Dieci più due fa dodici.",
			"Dieci più sette fa diciassette.",
			"Metti 12 con 10 + 2 e 17 con 10 + 7."),
		"Dieci e due, dieci e sette: due rotaie riemergono!",
		{"display": [D("pallino", 10, "oro"), D("pallino", 2, "teal"),
			D("pallino", 10, "oro"), D("pallino", 7, "rosa")], "effect": "rotaie"}))

	out.append(M("039", 4, "Il traguardo venti",
		"Ordinare numeri 16–20.",
		"I vagoni devono andare da 16 a 20. Mettili in ordine.",
		"sequence",
		[NUM("n16", 16), NUM("n17", 17), NUM("n18", 18), NUM("n19", 19), NUM("n20", 20)],
		[
			S("v16", "16", {"hint_icon": "train"}), S("v17", "17", {"hint_icon": "train"}),
			S("v18", "18", {"hint_icon": "train"}), S("v19", "19", {"hint_icon": "train"}),
			S("v20", "20", {"hint_icon": "train"}),
		],
		_three_hints("La locomotiva indica la partenza: 16.",
			"Ogni numero è uno in più del precedente.",
			"16, 17, 18, 19, 20."),
		"Il treno raggiunge la stazione: sedici, diciassette, diciotto, diciannove, venti!",
		{"effect": "stazione"}))

	out.append(M("040", 4, "La stazione delle differenze",
		"Integrare sequenze e confronto numerico.",
		"Completa la fila 6, 7, vuoto, 9 e il confronto 12 ? 15.",
		"composite",
		[NUM("n8", 8), NUM("n10", 10), NUM("n11", 11), SYM("gt", ">", "Maggiore"),
			SYM("lt", "<", "Minore"), SYM("eq", "=", "Uguale")],
		[
			F("f6", "6"), F("f7", "7"), S("v8", "8", {"hint_label": "?"}), F("f9", "9"),
			S("confronto", "<", {"hint_label": "12  ?  15"}),
		],
		_three_hints("Nella fila manca il numero dopo il 7.",
			"Dodici è meno di quindici.",
			"Metti 8 nella fila e < nel confronto."),
		"Sequenza e confronto: si illumina la grande Pietra Magica dei Binari!",
		{"subs": {"sequenza": ["v8"], "confronto": ["confronto"]}, "effect": "runa_binari"}))

	return out

# ================================================================== REGIONE 5
static func _r5() -> Array:
	var out: Array = []

	out.append(M("041", 5, "La macchina che unisce",
		"Addizione concreta entro 5.",
		"Due stelle e una stella: quante stelle in tutto? Metti i numeri nella macchina.",
		"arithmetic",
		[NUM("n2", 2), NUM("n1", 1), NUM("n3", 3), NUM("n4", 4)],
		[
			S("in1", "2", {"hint_label": "2"}), F("plus", "+"),
			S("in2", "1", {"hint_label": "1"}), F("eq", "="),
			S("out", "3", {"hint_label": "?"}),
		],
		_three_hints("Guarda le stelle: due e una.",
			"Due più una fa tre.",
			"Metti 2 nel primo ingresso, 1 nel secondo e 3 all'uscita."),
		"Due più una fa tre: il primo ingranaggio si accende!",
		{"arithmetic": {"a": 2, "b": 1, "op": "+", "input_sockets": ["in1", "in2"], "result_socket": "out", "result": 3},
			"display": [D("star", 2, "oro"), D("star", 1, "oro")], "effect": "ingranaggio"}))

	out.append(M("042", 5, "Due e due",
		"Composizione di 4 in due parti.",
		"Due farfalle e altre due farfalle: quante farfalle insieme?",
		"arithmetic",
		[NUM("a2", 2), NUM("b2", 2), NUM("n4", 4), NUM("n3", 3), NUM("n5", 5)],
		[
			S("in1", "2", {"hint_label": "2"}), F("plus", "+"),
			S("in2", "2", {"hint_label": "2"}), F("eq", "="),
			S("out", "4", {"hint_label": "?"}),
		],
		_three_hints("Ogni piattaforma ha due farfalle.",
			"Due più due fa quattro.",
			"Metti 2 e 2 negli ingressi e 4 all'uscita."),
		"Due e due fanno quattro: la macchina produce quattro ali!",
		{"arithmetic": {"a": 2, "b": 2, "op": "+", "input_sockets": ["in1", "in2"], "result_socket": "out", "result": 4},
			"display": [D("butterfly", 2, "rosa"), D("butterfly", 2, "blu")], "effect": "ali"}))

	out.append(M("043", 5, "Gli amici del cinque",
		"Composizioni complementari di 5.",
		"Il telaio ha cinque celle e tre gemme. Quante ne mancano? Poi costruisci 3 + 2 = 5.",
		"arithmetic",
		[NUM("n1", 1), NUM("m2a", 2), NUM("m2b", 2), NUM("n3", 3), NUM("n5", 5)],
		[
			S("manca", "2", {"hint_label": "?"}), F("sep", "|"),
			S("in1", "3", {"hint_label": "3"}), F("plus", "+"),
			S("in2", "2", {"hint_label": "2"}), F("eq", "="),
			S("out", "5", {"hint_label": "?"}),
		],
		_three_hints("Il telaio ha cinque posti e tre sono pieni.",
			"Per arrivare a cinque mancano due gemme.",
			"Metti 2 nello spazio mancante, poi 3 + 2 = 5."),
		"Tre più due fa cinque: il cristallo verde si accende!",
		{"arithmetic": {"a": 3, "b": 2, "op": "+", "input_sockets": ["in1", "in2"], "result_socket": "out", "result": 5},
			"display": [D("gem", 3, "verde")], "effect": "cristallo"}))

	out.append(M("044", 5, "Lo zero non cambia",
		"Identità dell'addizione con zero.",
		"Quattro stelle e un vassoio vuoto: quante stelle restano? Costruisci 4 + 0 = 4.",
		"arithmetic",
		[NUM("a4", 4), NUM("n0", 0), NUM("n5", 5), NUM("b4", 4)],
		[
			S("in1", "4", {"hint_label": "4"}), F("plus", "+"),
			S("in2", "0", {"hint_label": "0"}), F("eq", "="),
			S("out", "4", {"hint_label": "?"}),
		],
		_three_hints("Il vassoio vuoto contiene zero stelle.",
			"Aggiungere zero non cambia la quantità.",
			"Fai 4 + 0 = 4."),
		"Aggiungo zero: resta quattro. Un filo di luce attraversa l'officina!",
		{"arithmetic": {"a": 4, "b": 0, "op": "+", "input_sockets": ["in1", "in2"], "result_socket": "out", "result": 4},
			"display": [D("star", 4, "oro"), D("pallino", 0, "legno")], "effect": "filo"}))

	out.append(M("045", 5, "Lo stesso totale",
		"Commutatività intuitiva.",
		"Due macchine: 1 + 3 e 3 + 1. Metti il risultato in entrambe le uscite.",
		"match",
		[NUM("r1", 4), NUM("r2", 4), NUM("n3", 3), NUM("n5", 5)],
		[
			F("m1a", "1"), F("m1b", "+"), F("m1c", "3"), F("m1d", "="),
			S("out1", "4", {"hint_label": "?"}),
			F("m2a", "3"), F("m2b", "+"), F("m2c", "1"), F("m2d", "="),
			S("out2", "4", {"hint_label": "?"}),
		],
		_three_hints("Le due macchine hanno gli stessi gruppi, cambiati di posto.",
			"Uno più tre fa quattro. Tre più uno fa quattro.",
			"Metti un 4 in ciascuna uscita."),
		"Uno più tre e tre più uno: sempre quattro! Il doppio ingranaggio gira.",
		{"display": [D("star", 1, "oro"), D("star", 3, "oro"), D("star", 3, "oro"), D("star", 1, "oro")], "effect": "doppio_ingranaggio"}))

	out.append(M("046", 5, "Le sette lucciole",
		"Addizione entro 10 con supporto visivo.",
		"Quattro lucciole e tre lucciole: quante in tutto? Metti il risultato.",
		"arithmetic",
		[NUM("n6", 6), NUM("n7", 7), NUM("n8", 8)],
		[
			F("a4", "4"), F("plus", "+"), F("b3", "3"), F("eq", "="),
			S("out", "7", {"hint_label": "?"}),
		],
		_three_hints("Conta tutte le lucciole insieme.",
			"Quattro più tre fa sette.",
			"Metti 7 nel risultato."),
		"Quattro più tre fa sette: il laboratorio emette sette raggi!",
		{"display": [D("firefly", 4, "giallo"), D("firefly", 3, "giallo")], "effect": "raggi"}))

	out.append(M("047", 5, "Le stelle che vanno via",
		"Sottrazione concreta entro 5.",
		"Cinque stelle, due volano via. Quante restano?",
		"arithmetic",
		[NUM("n2", 2), NUM("n3", 3), NUM("n4", 4)],
		[
			F("a5", "5"), F("minus", "-"), F("b2", "2"), F("eq", "="),
			S("out", "3", {"hint_label": "?"}),
		],
		_three_hints("Guarda le stelle che restano dopo che due volano via.",
			"Togli due da cinque: restano tre.",
			"Metti 3 nel risultato."),
		"Cinque meno due fa tre: il tubo dell'officina si ripara!",
		{"display": [D("star", 5, "oro"), D("firefly", 2, "blu")], "effect": "tubo"}))

	out.append(M("048", 5, "Dove sono finite?",
		"Sottrazione 8−3 illustrata.",
		"Otto pietre, tre attraversano il portale. Quante restano di qua?",
		"arithmetic",
		[NUM("n4", 4), NUM("n5", 5), NUM("n6", 6)],
		[
			F("a8", "8"), F("minus", "-"), F("b3", "3"), F("eq", "="),
			S("out", "5", {"hint_label": "?"}),
		],
		_three_hints("Le tre pietre sono ancora visibili nella cesta.",
			"Cinque pietre più tre fanno otto.",
			"Metti 5 nel risultato."),
		"Otto meno tre fa cinque: la fontana torna a funzionare!",
		{"display": [D("rock", 8, "grigio"), D("rock", 3, "marrone")], "effect": "fontana"}))

	out.append(M("049", 5, "Il pacco per Nubi",
		"Problema additivo contestualizzato.",
		"Nubi ha un pacco con 3 biscotti e uno con 2 biscotti. Quanti biscotti in tutto?",
		"arithmetic",
		[NUM("n4", 4), NUM("n5", 5), NUM("n6", 6)],
		[
			F("a3", "3"), F("plus", "+"), F("b2", "2"), F("eq", "="),
			S("out", "5", {"hint_label": "?"}),
		],
		_three_hints("Unisci i biscotti dei due pacchi.",
			"Tre più due fa cinque.",
			"Metti 5 nel vassoio del risultato."),
		"Tre più due fa cinque: Nubi condivide i biscotti con gli amici!",
		{"display": [D("biscotto", 3, "marrone"), D("biscotto", 2, "marrone")], "effect": "biscotti"}))

	out.append(M("050", 5, "Il cuore dell'officina",
		"Integrare somma e sottrazione entro 10.",
		"Due macchine: 6 + 2 e 7 − 4. Metti i due risultati.",
		"composite",
		[NUM("n8", 8), NUM("n3", 3), NUM("n6", 6), NUM("n4", 4)],
		[
			F("a6", "6"), F("plus", "+"), F("b2", "2"), F("eq", "="),
			S("out1", "8", {"hint_label": "?"}),
			F("a7", "7"), F("minus", "-"), F("b4", "4"), F("eq2", "="),
			S("out2", "3", {"hint_label": "?"}),
		],
		_three_hints("Sei più due fa otto. Sette meno quattro fa tre.",
			"La prima uscita vuole un numero più grande del 7.",
			"Metti 8 nella prima uscita e 3 nella seconda."),
		"Otto e tre: la Pietra Magica dell'Officina si accende!",
		{"subs": {"somma": ["out1"], "differenza": ["out2"]},
			"display": [D("star", 6, "oro"), D("star", 2, "oro"), D("star", 7, "oro"), D("star", 4, "blu")],
			"effect": "runa_officina"}))

	return out

# ================================================================== REGIONE 6
static func _r6() -> Array:
	var out: Array = []

	out.append(M("051", 6, "Il ponte più lungo",
		"Confrontare due lunghezze con estremi allineati.",
		"Guarda le due travi. Metti LUNGO sulla trave lunga e CORTO sulla corta.",
		"match",
		[
			C("lungo", "lungo", {"label": "LUNGO", "icon": "lungo", "color": "verde", "spoken": "Lungo"}),
			C("corto", "corto", {"label": "CORTO", "icon": "corto", "color": "arancio", "spoken": "Corto"}),
		],
		[
			S("trave5", "lungo", {"bar": {"length": 5, "color": "marrone"}}),
			S("trave3", "corto", {"bar": {"length": 3, "color": "marrone"}}),
		],
		_three_hints("Le due travi partono dallo stesso punto.",
			"La trave che arriva più lontano è lunga.",
			"Metti LUNGO sulla trave da cinque e CORTO su quella da tre."),
		"La trave lunga e quella corta: un ponte si distende sull'acqua!",
		{"effect": "ponte"}))

	out.append(M("052", 6, "Tre nastri",
		"Ordinare tre lunghezze crescenti.",
		"Metti i nastri dal più corto al più lungo.",
		"sequence",
		[
			C("n2", "corda2", {"label": "2", "icon": "nastro", "color": "rosa", "spoken": "Nastro corto",
				"bar": {"length": 2, "color": "rosa"}}),
			C("n4", "corda4", {"label": "4", "icon": "nastro", "color": "teal", "spoken": "Nastro medio",
				"bar": {"length": 4, "color": "teal"}}),
			C("n6", "corda6", {"label": "6", "icon": "nastro", "color": "viola", "spoken": "Nastro lungo",
				"bar": {"length": 6, "color": "viola"}}),
		],
		[
			S("p1", "corda2", {"hint_label": "1", "hint_icon": "nastro"}),
			S("p2", "corda4", {"hint_label": "2", "hint_icon": "nastro"}),
			S("p3", "corda6", {"hint_label": "3", "hint_icon": "nastro"}),
		],
		_three_hints("Confronta i nastri dalla stessa estremità.",
			"Il nastro corto va per primo.",
			"Corto, medio, lungo: 2, 4, 6."),
		"Corto, medio, lungo: una bandiera si alza al vento!",
		{"effect": "bandiera"}))

	out.append(M("053", 6, "Torre alta, torre bassa",
		"Distinguere altezza da larghezza.",
		"Guarda l'altezza delle torri: metti ALTA accanto alla più alta e BASSA accanto alla più bassa.",
		"match",
		[
			C("alta", "alta", {"label": "ALTA", "icon": "alta", "color": "blu", "spoken": "Alta"}),
			C("bassa", "bassa", {"label": "BASSA", "icon": "bassa", "color": "arancio", "spoken": "Bassa"}),
			C("larga", "larga", {"label": "LARGA", "icon": "larga", "color": "grigio", "spoken": "Larga"}),
		],
		[
			S("torre1", "alta", {"hint_icon": "torre", "tower": {"units": 6, "color": "blu"}}),
			S("torre2", "bassa", {"hint_icon": "torre", "tower": {"units": 3, "color": "arancio"}}),
		],
		_three_hints("Qui guardiamo quanto sono alte, non quanto sono larghe.",
			"La torre più alta arriva più su.",
			"ALTA sulla torre alta, BASSA sulla torre bassa. LARGA non serve."),
		"Alta e bassa: una scala si apre nella valle!",
		{"display": [D("torre", 2, "blu")], "effect": "scala"}))

	out.append(M("054", 6, "Le corde gemelle",
		"Uguaglianza di lunghezze.",
		"Due corde sono lunghe uguali, una è più lunga. Metti = tra le gemelle e la corda diversa sulla pedana.",
		"composite",
		[
			C("eq", "=", {"label": "=", "icon": "uguale", "color": "blu", "spoken": "Uguale"}),
			C("neq", "≠", {"label": "≠", "icon": "diverso", "color": "rosso", "spoken": "Diverso"}),
			C("corda6", "corda6", {"icon": "corda", "color": "viola", "spoken": "Corda lunga",
				"bar": {"length": 6, "color": "viola"}}),
		],
		[
			F("cordaA", "", {"fixed_icon": "corda", "fixed_color": "rosa", "bar": {"length": 4, "color": "rosa"}}),
			S("uguali", "=", {"hint_label": "?"}),
			F("cordaB", "", {"fixed_icon": "corda", "fixed_color": "teal", "bar": {"length": 4, "color": "teal"}}),
			S("diversa", "corda6", {"hint_label": "DIVERSA"}),
		],
		_three_hints("Guarda le estremità delle corde.",
			"Due corde finiscono nello stesso punto: sono uguali.",
			"Metti = tra le due corde uguali e la corda da 6 sulla pedana DIVERSA."),
		"Le corde gemelle hanno il loro segno: il tessitore regala una corda magica!",
		{"subs": {"uguali": ["uguali"], "diversa": ["diversa"]}, "effect": "corda"}))

	out.append(M("055", 6, "Misura con i mattoncini",
		"Usare unità di misura non convenzionali.",
		"La tavola è lunga quattro mattoncini. Coprila con quattro mattoncini uguali.",
		"measurement",
		[
			C("m1", "mattone", {"icon": "mattoncino", "color": "arancio", "spoken": "Mattoncino"}),
			C("m2", "mattone", {"icon": "mattoncino", "color": "arancio", "spoken": "Mattoncino"}),
			C("m3", "mattone", {"icon": "mattoncino", "color": "arancio", "spoken": "Mattoncino"}),
			C("m4", "mattone", {"icon": "mattoncino", "color": "arancio", "spoken": "Mattoncino"}),
			C("m5", "mattone", {"icon": "mattoncino", "color": "arancio", "spoken": "Mattoncino"}),
		],
		[
			S("u1", "mattone", {"hint_icon": "mattoncino"}), S("u2", "mattone", {"hint_icon": "mattoncino"}),
			S("u3", "mattone", {"hint_icon": "mattoncino"}), S("u4", "mattone", {"hint_icon": "mattoncino"}),
		],
		_three_hints("La tavola ha quattro sedi uguali.",
			"Un mattoncino per ogni sede.",
			"Metti quattro mattoncini nelle quattro sedi. Uno resta fuori."),
		"Quattro mattoncini, quattro sedi: la tavola è misurata!",
		{"effect": "tavola"}))

	out.append(M("056", 6, "La strada da sei passi",
		"Misurare con la stessa unità ripetuta.",
		"La strada è lunga sei passi. Copri le sei sedi e metti il numero 6.",
		"measurement",
		[
			C("p1", "passo", {"icon": "orma", "color": "marrone", "spoken": "Passo"}),
			C("p2", "passo", {"icon": "orma", "color": "marrone", "spoken": "Passo"}),
			C("p3", "passo", {"icon": "orma", "color": "marrone", "spoken": "Passo"}),
			C("p4", "passo", {"icon": "orma", "color": "marrone", "spoken": "Passo"}),
			C("p5", "passo", {"icon": "orma", "color": "marrone", "spoken": "Passo"}),
			C("p6", "passo", {"icon": "orma", "color": "marrone", "spoken": "Passo"}),
			C("p7", "passo", {"icon": "orma", "color": "marrone", "spoken": "Passo"}),
			C("p8", "passo", {"icon": "orma", "color": "marrone", "spoken": "Passo"}),
			NUM("n6", 6),
		],
		[
			S("u1", "passo", {"hint_icon": "orma"}), S("u2", "passo", {"hint_icon": "orma"}),
			S("u3", "passo", {"hint_icon": "orma"}), S("u4", "passo", {"hint_icon": "orma"}),
			S("u5", "passo", {"hint_icon": "orma"}), S("u6", "passo", {"hint_icon": "orma"}),
			S("numero", "6", {"hint_label": "?"}),
		],
		_three_hints("Sei sedi, sei passi.",
			"Riempi tutte le sedi una dopo l'altra.",
			"Usa sei impronte e metti il numero 6 nell'indicatore."),
		"Sei passi: il ponticello sorge sopra il ruscello!",
		{"effect": "ponticello"}))

	out.append(M("057", 6, "Il righello dei giganti",
		"Comprendere che misurare richiede unità omogenee.",
		"Il ponte è lungo quattro unità uguali. Usa solo i cubi-unità, non quelli doppi.",
		"measurement",
		[
			C("u1", "unita", {"icon": "trave", "color": "teal", "spoken": "Unità"}),
			C("u2", "unita", {"icon": "trave", "color": "teal", "spoken": "Unità"}),
			C("u3", "unita", {"icon": "trave", "color": "teal", "spoken": "Unità"}),
			C("u4", "unita", {"icon": "trave", "color": "teal", "spoken": "Unità"}),
			C("d1", "doppio", {"icon": "trave", "color": "rosa", "spoken": "Unità doppia",
				"bar": {"length": 2, "color": "rosa"}}),
			C("d2", "doppio", {"icon": "trave", "color": "rosa", "spoken": "Unità doppia",
				"bar": {"length": 2, "color": "rosa"}}),
		],
		[
			S("u1s", "unita", {"hint_icon": "trave"}), S("u2s", "unita", {"hint_icon": "trave"}),
			S("u3s", "unita", {"hint_icon": "trave"}), S("u4s", "unita", {"hint_icon": "trave"}),
		],
		_three_hints("Per misurare serve sempre la stessa unità.",
			"I cubi doppi sono più lunghi: non vanno bene qui.",
			"Riempi le quattro sedi con quattro cubi-unità uguali."),
		"Quattro unità uguali: ora la misura è giusta! Un nuovo ponte si attiva.",
		{"effect": "righello"}))

	out.append(M("058", 6, "I barattoli pieni",
		"Confrontare capacità in modo intuitivo.",
		"Guarda i due barattoli: uno ha più liquido. Metti PIÙ PIENO e MENO PIENO.",
		"match",
		[
			C("piu", "piu_pieno", {"label": "PIÙ PIENO", "icon": "piu_pieno", "color": "blu", "spoken": "Più pieno"}),
			C("meno", "meno_pieno", {"label": "MENO PIENO", "icon": "meno_pieno", "color": "arancio", "spoken": "Meno pieno"}),
		],
		[
			S("poco", "meno_pieno", {"hint_icon": "barattolo"}),
			S("molto", "piu_pieno", {"hint_icon": "barattolo"}),
		],
		_three_hints("Guarda il livello del liquido nei barattoli.",
			"Il barattolo con il liquido più alto è più pieno.",
			"PIÙ PIENO sul barattolo pieno, MENO PIENO sull'altro."),
		"Il livello dell'acqua è chiaro: la fontana zampilla!",
		{"display": [D("barattolo", 1, "blu"), D("piu_pieno", 1, "blu")], "effect": "zampillo"}))

	out.append(M("059", 6, "La bilancia equilibrata",
		"Confrontare pesi con bilancia visuale.",
		"Guarda la bilancia: un piatto è più basso. Metti PESANTE e LEGGERO.",
		"match",
		[
			C("pesante", "pesante", {"label": "PESANTE", "icon": "pesante", "color": "grigio", "spoken": "Pesante"}),
			C("leggero", "leggero", {"label": "LEGGERO", "icon": "leggero", "color": "avorio", "spoken": "Leggero"}),
		],
		[
			S("piatto_basso", "pesante", {"hint_icon": "bilancia"}),
			S("piatto_alto", "leggero", {"hint_icon": "bilancia"}),
		],
		_three_hints("Il piatto che va più in basso contiene il peso maggiore.",
			"Non guardare la grandezza: guarda la bilancia.",
			"PESANTE sul piatto basso, LEGGERO su quello alto."),
		"La bilancia ha deciso: Milla alza la sua bandierina!",
		{"display": [D("rock", 5, "grigio"), D("rock", 2, "marrone")], "effect": "bandierina"}))

	out.append(M("060", 6, "Il mercato delle misure",
		"Integrare confronto, ordine e misura.",
		"Ordina le corde dalla più corta alla più lunga e copri la tavola con quattro unità.",
		"composite",
		[
			C("c2", "corda2", {"icon": "corda", "color": "rosa", "spoken": "Corda corta",
				"bar": {"length": 2, "color": "rosa"}}),
			C("c3", "corda3", {"icon": "corda", "color": "teal", "spoken": "Corda media",
				"bar": {"length": 3, "color": "teal"}}),
			C("c5", "corda5", {"icon": "corda", "color": "viola", "spoken": "Corda lunga",
				"bar": {"length": 5, "color": "viola"}}),
			C("u1", "unita", {"icon": "trave", "color": "arancio", "spoken": "Unità"}),
			C("u2", "unita", {"icon": "trave", "color": "arancio", "spoken": "Unità"}),
			C("u3", "unita", {"icon": "trave", "color": "arancio", "spoken": "Unità"}),
			C("u4", "unita", {"icon": "trave", "color": "arancio", "spoken": "Unità"}),
		],
		[
			S("corda1", "corda2", {"hint_label": "1", "hint_icon": "corda"}),
			S("corda2s", "corda3", {"hint_label": "2", "hint_icon": "corda"}),
			S("corda3s", "corda5", {"hint_label": "3", "hint_icon": "corda"}),
			S("m1", "unita", {"hint_icon": "trave"}), S("m2", "unita", {"hint_icon": "trave"}),
			S("m3", "unita", {"hint_icon": "trave"}), S("m4", "unita", {"hint_icon": "trave"}),
		],
		_three_hints("Prima ordina le tre corde, poi misura la tavola.",
			"Le corde vanno 2, 3, 5.",
			"Corda corta, media, lunga; poi quattro unità nelle quattro sedi."),
		"Ordine e misura: la Pietra Magica delle Misure illumina la valle!",
		{"subs": {"corde": ["corda1", "corda2s", "corda3s"], "tavola": ["m1", "m2", "m3", "m4"]}, "effect": "runa_misure"}))

	return out

# ================================================================== REGIONE 7
static func _r7() -> Array:
	var out: Array = []

	out.append(M("061", 7, "La campana che fa A",
		"Riconoscere la vocale A attraverso il suono.",
		"Ascolta la campana: fa /a/. Metti il cubo A sulla campana che suona.",
		"match",
		[
			LET("a", "A", {"spoken": "A", "label": "A"}),
			LET("e", "E", {"spoken": "E", "label": "E"}),
			LET("o", "O", {"spoken": "O", "label": "O"}),
		],
		[
			S("campana_a", "A", {"hint_icon": "bell", "hint_label": "A"}),
		],
		_three_hints("Ascolta bene: la campana canta /a/.",
			"A è la prima lettera. La bocca si apre: aaaa.",
			"Metti il cubo A sulla campana illuminata."),
		"La campana ha ritrovato la sua voce: A!",
		{"display": [D("ape", 1, "giallo"), D("bell", 1, "oro")], "effect": "campana",
			"listen": "a"}))

	out.append(M("062", 7, "Le altre vocali",
		"Riconoscere E, I, O, U.",
		"Quattro campane cantano /e/, /i/, /o/, /u/. Metti ogni vocale sulla sua campana.",
		"match",
		[
			LET("e", "E", {"spoken": "E"}), LET("i", "I", {"spoken": "I"}),
			LET("o", "O", {"spoken": "O"}), LET("u", "U", {"spoken": "U"}),
			LET("a", "A", {"spoken": "A"}),
		],
		[
			S("c_e", "E", {"hint_icon": "bell", "hint_label": "E"}),
			S("c_i", "I", {"hint_icon": "bell", "hint_label": "I"}),
			S("c_o", "O", {"hint_icon": "bell", "hint_label": "O"}),
			S("c_u", "U", {"hint_icon": "bell", "hint_label": "U"}),
		],
		_three_hints("Ogni campana ha un suono diverso.",
			"Ascolta una campana alla volta e ripeti il suono.",
			"E con /e/, I con /i/, O con /o/, U con /u/. A non serve."),
		"Quattro campane, quattro voci: la biblioteca canta!",
		{"display": [D("bell", 1, "rosa"), D("bell", 1, "teal"), D("bell", 1, "blu"), D("bell", 1, "viola")],
			"effect": "coro_vocali"}))

	out.append(M("063", 7, "La lettera che ascolto",
		"Associare suono e grafema con due opzioni.",
		"Due portali pronunciano /m/ e /p/. Metti M nel portale /m/ e P nel portale /p/.",
		"match",
		[
			LET("m", "M", {"spoken": "M"}), LET("p", "P", {"spoken": "P"}),
		],
		[
			S("porta_m", "M", {"hint_icon": "porta", "hint_label": "/m/"}),
			S("porta_p", "P", {"hint_icon": "porta", "hint_label": "/p/"}),
		],
		_three_hints("Il primo portale fa /m/, come l'inizio di MANO.",
			"Il secondo portale fa /p/, come l'inizio di PANE.",
			"M nella porta /m/, P nella porta /p/."),
		"Le porte si aprono: /m/ e /p/ hanno la loro lettera!",
		{"display": [D("hand", 1, "avorio"), D("pane", 1, "oro")], "effect": "portali"}))

	out.append(M("064", 7, "L'eco di MARE",
		"Riconoscere la lettera iniziale di una parola nota.",
		"Eco dice MARE. Quale lettera senti all'inizio? Completa la parola.",
		"sequence",
		[
			LET("m", "M", {"spoken": "M"}), LET("p", "P", {"spoken": "P"}),
			LET("s", "S", {"spoken": "S"}),
		],
		[
			S("iniziale", "M", {"hint_label": "?"}),
			F("a", "A"), F("r", "R"), F("e", "E"),
		],
		_three_hints("Ascolta l'inizio di MARE: mmm.",
			"La prima lettera ha le labbra chiuse: M.",
			"Metti M nel primo incastro. Poi la parola è MARE."),
		"MARE! La conchiglia sonora torna a cantare.",
		{"display": [D("onda", 3, "teal"), D("shell", 1, "rosa")], "effect": "conchiglia",
			"listen": "MARE"}))

	out.append(M("065", 7, "L'eco di SOLE",
		"Riconoscere il suono iniziale S.",
		"Ascolta SOLE. Quale lettera inizia la parola?",
		"sequence",
		[
			LET("l", "L", {"spoken": "L"}), LET("s", "S", {"spoken": "S"}),
			LET("t", "T", {"spoken": "T"}),
		],
		[
			S("iniziale", "S", {"hint_label": "?"}),
			F("o", "O"), F("l", "L"), F("e", "E"),
		],
		_three_hints("Ascolta l'inizio: ssss come un serpente.",
			"SOLE comincia con S.",
			"Metti S nel primo incastro."),
		"SOLE splende: la biblioteca si riempie di luce.",
		{"display": [D("sun", 1, "oro"), D("serpente", 1, "verde")], "effect": "sole_pagine"}))

	out.append(M("066", 7, "Voci che iniziano uguale",
		"Individuare parole con lo stesso suono iniziale.",
		"MANO comincia con /m/. Quale altra parola comincia con /m/?",
		"match",
		[
			C("mano", "mano", {"icon": "hand", "spoken": "Mano"}),
			C("mela", "mela", {"icon": "apple", "spoken": "Mela"}),
			C("sole", "sole", {"icon": "sun", "spoken": "Sole"}),
			C("cane", "cane", {"icon": "cane", "spoken": "Cane"}),
		],
		[
			S("campione", "mano", {"hint_icon": "hand", "hint_label": "MANO"}),
			S("compagna", "mela", {"hint_label": "?"}),
		],
		_three_hints("Ascolta l'inizio di MANO: mmm.",
			"MELA comincia con lo stesso suono: mmm.",
			"Metti MELA accanto a MANO. SOLE e CANE restano al banco."),
		"MANO e MELA: due parole che iniziano uguale!",
		{"display": [D("hand", 1, "avorio"), D("apple", 1, "rosso")], "effect": "eco_doppia"}))

	out.append(M("067", 7, "La coda delle parole",
		"Riconoscere parole in rima mediante l'ascolto.",
		"Eco dice PANE. Quale parola finisce con lo stesso suono?",
		"match",
		[
			C("cane", "cane", {"icon": "cane", "spoken": "Cane"}),
			C("mare", "mare", {"icon": "onda", "spoken": "Mare"}),
			C("luna", "luna", {"icon": "moon", "spoken": "Luna"}),
		],
		[
			S("rima", "cane", {"hint_icon": "pane", "hint_label": "PANE"}),
		],
		_three_hints("PANE e CANE finiscono con lo stesso suono: -ane.",
			"Ascolta la coda: pa-NE, ca-NE.",
			"Metti CANE accanto a PANE."),
		"PANE e CANE: la rima fa cantare il gufo!",
		{"display": [D("pane", 1, "oro"), D("cane", 1, "marrone"), D("gufo", 1, "grigio")],
			"effect": "gufo"}))

	out.append(M("068", 7, "Le parole corte e lunghe",
		"Sensibilità alla lunghezza fonologica in sillabe.",
		"SOLE ha due battiti, FARFALLA ne ha tre. Porta le parole sulla pedana giusta.",
		"match",
		[
			C("sole", "sole", {"icon": "sun", "spoken": "Sole"}),
			C("farfalla", "farfalla", {"icon": "butterfly", "spoken": "Farfalla"}),
		],
		[
			S("due", "sole", {"hint_icon": "mano2", "hint_label": "DUE BATTITI"}),
			S("tre", "farfalla", {"hint_icon": "mano3", "hint_label": "TRE BATTITI"}),
		],
		_three_hints("Batti le mani mentre dici la parola.",
			"SO-LE: due battiti. FAR-FAL-LA: tre battiti.",
			"SOLE sui due battiti, FARFALLA sui tre battiti."),
		"Due battiti, tre battiti: il tamburo riparte!",
		{"display": [D("sun", 1, "oro"), D("butterfly", 1, "rosa")], "effect": "tamburo"}))

	out.append(M("069", 7, "Cinque vocali in coro",
		"Discriminare e ordinare la sequenza vocalica.",
		"Ascolta il coro: A, E, I, O, U. Metti le vocali nell'ordine giusto.",
		"sequence",
		[
			LET("a", "A", {"spoken": "A"}), LET("e", "E", {"spoken": "E"}),
			LET("i", "I", {"spoken": "I"}), LET("o", "O", {"spoken": "O"}),
			LET("u", "U", {"spoken": "U"}),
		],
		[
			S("p1", "A", {"hint_label": "1"}), S("p2", "E", {"hint_label": "2"}),
			S("p3", "I", {"hint_label": "3"}), S("p4", "O", {"hint_label": "4"}),
			S("p5", "U", {"hint_label": "5"}),
		],
		_three_hints("Il coro canta sempre nello stesso ordine.",
			"Prima A, poi E, poi I.",
			"A, E, I, O, U: cinque vocali in fila."),
		"Le cinque vocali cantano insieme: il coro della biblioteca è nato!",
		{"display": [D("nota", 5, "viola")], "effect": "coro_libreria"}))

	out.append(M("070", 7, "Il libro delle prime lettere",
		"Combinare lettera iniziale e vocali.",
		"Tre libri mostrano APE, OCA, UVA. Metti la vocale iniziale giusta su ogni libro.",
		"match",
		[
			LET("a", "A", {"spoken": "A"}), LET("o", "O", {"spoken": "O"}),
			LET("u", "U", {"spoken": "U"}), LET("e", "E", {"spoken": "E"}),
			LET("i", "I", {"spoken": "I"}),
		],
		[
			S("ape", "A", {"hint_icon": "ape", "hint_label": "APE"}),
			S("oca", "O", {"hint_icon": "oca", "hint_label": "OCA"}),
			S("uva", "U", {"hint_icon": "uva", "hint_label": "UVA"}),
		],
		_three_hints("Ascolta l'inizio di ogni parola.",
			"APE comincia con A, OCA con O, UVA con U.",
			"A sul libro dell'ape, O su quello dell'oca, U su quello dell'uva."),
		"APE, OCA, UVA: la Pietra Magica dei Suoni si accende!",
		{"display": [D("ape", 1, "giallo"), D("oca", 1, "avorio"), D("uva", 1, "viola")],
			"effect": "runa_suoni"}))

	return out

# ================================================================== REGIONE 8
static func _r8() -> Array:
	var out: Array = []

	out.append(M("071", 8, "Il battito di LUNA",
		"Segmentare una parola bisillabica.",
		"Sila dice LU-NA. Metti le due sillabe sulle pale del mulino, in ordine.",
		"sequence",
		[
			SYL("lu", "LU", {"spoken": "Lu"}), SYL("na", "NA", {"spoken": "Na"}),
			SYL("ma", "MA", {"spoken": "Ma"}),
		],
		[
			S("p1", "LU", {"hint_icon": "moon", "hint_label": "1"}),
			S("p2", "NA", {"hint_icon": "moon", "hint_label": "2"}),
		],
		_three_hints("Batti due volte: LU-NA.",
			"La prima pala vuole LU, la seconda NA.",
			"LU poi NA: si legge LUNA."),
		"LU-NA: la luna illumina il mulino!",
		{"display": [D("moon", 1, "blu"), D("nota", 2, "viola")], "effect": "pala_luna",
			"listen": "LUNA"}))

	out.append(M("072", 8, "La parola PANE",
		"Comporre una parola bisillabica CV.",
		"Guarda il pane. Metti PA e NE nei due incastri, in ordine.",
		"sequence",
		[
			SYL("pa", "PA", {"spoken": "Pa"}), SYL("ne", "NE", {"spoken": "Ne"}),
			SYL("la", "LA", {"spoken": "La"}),
		],
		[
			S("p1", "PA", {"hint_icon": "pane", "hint_label": "1"}),
			S("p2", "NE", {"hint_icon": "pane", "hint_label": "2"}),
		],
		_three_hints("Ascolta: PA-NE.",
			"Prima PA, poi NE.",
			"PA nel primo incastro, NE nel secondo. È PANE!"),
		"PA-NE: il forno si accende e il pane profuma!",
		{"display": [D("pane", 2, "oro")], "effect": "forno", "listen": "PANE"}))

	out.append(M("073", 8, "Il sole delle sillabe",
		"Sintesi sillabica con distrattore.",
		"SOLE si divide in SO-LE. Scegli le due sillabe giuste.",
		"sequence",
		[
			SYL("so", "SO", {"spoken": "So"}), SYL("le", "LE", {"spoken": "Le"}),
			SYL("me", "ME", {"spoken": "Me"}),
		],
		[
			S("p1", "SO", {"hint_icon": "sun", "hint_label": "1"}),
			S("p2", "LE", {"hint_icon": "sun", "hint_label": "2"}),
		],
		_three_hints("Ascolta: SO-LE.",
			"La prima sillaba è SO, non ME.",
			"SO poi LE: il sole splende."),
		"SO-LE: un girasole sboccia davanti al mulino!",
		{"display": [D("sun", 1, "oro"), D("flower", 1, "giallo")], "effect": "girasole"}))

	out.append(M("074", 8, "La casa sul colle",
		"Comporre la parola CASA.",
		"La casetta ha due incastri. Metti CA e SA nell'ordine giusto.",
		"sequence",
		[
			SYL("ca", "CA", {"spoken": "Ca"}), SYL("sa", "SA", {"spoken": "Sa"}),
			SYL("ma", "MA", {"spoken": "Ma"}),
		],
		[
			S("p1", "CA", {"hint_icon": "casa", "hint_label": "1"}),
			S("p2", "SA", {"hint_icon": "casa", "hint_label": "2"}),
		],
		_three_hints("Ascolta: CA-SA.",
			"La casa si divide in due metà: CA e SA.",
			"CA nel primo incastro, SA nel secondo. È CASA!"),
		"CA-SA: si apre una finestra sul colle!",
		{"display": [D("casa", 1, "arancio")], "effect": "finestra_casa", "listen": "CASA"}))

	out.append(M("075", 8, "Un treno chiamato TOPO",
		"Segmentare e sintetizzare TO-PO.",
		"Il topolino vuole due vagoni: TO e PO. Mettili in ordine.",
		"sequence",
		[
			SYL("to", "TO", {"spoken": "To"}), SYL("po", "PO", {"spoken": "Po"}),
			SYL("pa", "PA", {"spoken": "Pa"}),
		],
		[
			S("p1", "TO", {"hint_icon": "topo", "hint_label": "1"}),
			S("p2", "PO", {"hint_icon": "topo", "hint_label": "2"}),
		],
		_three_hints("Ascolta: TO-PO.",
			"Il primo vagone è TO.",
			"TO poi PO: il topolino sale a bordo!"),
		"TO-PO: il trenino fischia e parte!",
		{"display": [D("topo", 1, "grigio"), D("train", 1, "verde")], "effect": "treno_topo"}))

	out.append(M("076", 8, "La nave nel porto",
		"Discriminare tra NA e NE.",
		"Sila dice NA-VE. Metti NA e VE nei due incastri; NE è un distrattore.",
		"sequence",
		[
			SYL("na", "NA", {"spoken": "Na"}), SYL("ve", "VE", {"spoken": "Ve"}),
			SYL("ne", "NE", {"spoken": "Ne"}), SYL("ma", "MA", {"spoken": "Ma"}),
		],
		[
			S("p1", "NA", {"hint_icon": "ship", "hint_label": "1"}),
			S("p2", "VE", {"hint_icon": "ship", "hint_label": "2"}),
		],
		_three_hints("Ascolta bene la prima sillaba: NA.",
			"La seconda sillaba è VE, non NE.",
			"NA poi VE: si legge NAVE."),
		"NA-VE: il veliero salpa dal porto!",
		{"display": [D("ship", 2, "blu")], "effect": "veliero", "listen": "NAVE"}))

	out.append(M("077", 8, "Il mondo delle MA",
		"Associare sillabe CV a un modello orale.",
		"Tre campane suonano MA, ME, MI. Metti ogni sillaba sulla campana che la canta.",
		"match",
		[
			SYL("ma", "MA", {"spoken": "Ma"}), SYL("me", "ME", {"spoken": "Me"}),
			SYL("mi", "MI", {"spoken": "Mi"}), SYL("mo", "MO", {"spoken": "Mo"}),
		],
		[
			S("c_ma", "MA", {"hint_icon": "bell", "hint_label": "MA"}),
			S("c_me", "ME", {"hint_icon": "bell", "hint_label": "ME"}),
			S("c_mi", "MI", {"hint_icon": "bell", "hint_label": "MI"}),
		],
		_three_hints("La M resta uguale, cambia la vocale.",
			"MA, ME, MI: ascolta la vocale finale.",
			"MA con MA, ME con ME, MI con MI. MO non serve."),
		"MA, ME, MI: tre molle fanno girare il mulino!",
		{"display": [D("bell", 3, "teal"), D("molla", 3, "grigio")], "effect": "molle"}))

	out.append(M("078", 8, "Due battiti, una parola",
		"Riconoscere le sillabe iniziali in parole note.",
		"MARE comincia con MA, MELA con ME. Metti ogni sillaba sulla sua immagine.",
		"match",
		[
			SYL("ma", "MA", {"spoken": "Ma"}), SYL("me", "ME", {"spoken": "Me"}),
			SYL("mo", "MO", {"spoken": "Mo"}),
		],
		[
			S("mare", "MA", {"hint_icon": "onda", "hint_label": "MARE"}),
			S("mela", "ME", {"hint_icon": "apple", "hint_label": "MELA"}),
		],
		_three_hints("Ascolta il primo battito di MARE: MA.",
			"ME-LA comincia con ME.",
			"MA su MARE, ME su MELA. MO non serve."),
		"MA-RE e ME-LA: due raggi di luce uniscono sillaba e immagine!",
		{"display": [D("onda", 1, "blu"), D("apple", 1, "rosso"), D("flower", 2, "rosa")],
			"effect": "raggi_fiori"}))

	out.append(M("079", 8, "Tre passi per FARFALLA",
		"Segmentare una parola trisillabica.",
		"FARFALLA fa FAR-FAL-LA. Metti le tre sillabe sul ponticello in ordine.",
		"sequence",
		[
			SYL("far", "FAR", {"spoken": "Far"}), SYL("fal", "FAL", {"spoken": "Fal"}),
			SYL("la", "LA", {"spoken": "La"}), SYL("fa", "FA", {"spoken": "Fa"}),
		],
		[
			S("p1", "FAR", {"hint_icon": "butterfly", "hint_label": "1"}),
			S("p2", "FAL", {"hint_icon": "butterfly", "hint_label": "2"}),
			S("p3", "LA", {"hint_icon": "butterfly", "hint_label": "3"}),
		],
		_three_hints("Batti tre volte: FAR-FAL-LA.",
			"La prima sillaba è FAR, poi FAL.",
			"FAR, FAL, LA: tre passi per FARFALLA."),
		"FAR-FAL-LA: una farfalla gigante apre le ali!",
		{"display": [D("butterfly", 1, "rosa"), D("flower", 3, "viola")], "effect": "farfalla_gigante"}))

	out.append(M("080", 8, "La ruota delle sillabe",
		"Integrare composizione e discriminazione.",
		"Due ruote: forma LUNA con LU+NA e PANE con PA+NE.",
		"composite",
		[
			SYL("lu", "LU", {"spoken": "Lu"}), SYL("na", "NA", {"spoken": "Na"}),
			SYL("pa", "PA", {"spoken": "Pa"}), SYL("ne", "NE", {"spoken": "Ne"}),
		],
		[
			S("r1a", "LU", {"hint_icon": "moon", "hint_label": "1"}),
			S("r1b", "NA", {"hint_icon": "moon", "hint_label": "2"}),
			S("r2a", "PA", {"hint_icon": "pane", "hint_label": "1"}),
			S("r2b", "NE", {"hint_icon": "pane", "hint_label": "2"}),
		],
		_three_hints("Una ruota forma LUNA, l'altra forma PANE.",
			"LU-NA per la luna, PA-NE per il pane.",
			"Completa le due ruote nell'ordine che preferisci."),
		"Le due ruote girano: la Pietra Magica delle Sillabe riaccende il mulino!",
		{"display": [D("moon", 1, "blu"), D("pane", 1, "oro")], "effect": "runa_sillabe",
			"subs": {"luna": ["r1a", "r1b"], "pane": ["r2a", "r2b"]}}))

	return out

# ================================================================== REGIONE 9
static func _r9() -> Array:
	var out: Array = []

	out.append(M("081", 9, "L'insegna del sole",
		"Ricostruire una parola semplice con le lettere.",
		"L'insegna dice SOLE. Metti S, O, L, E nelle quattro caselle in ordine.",
		"sequence",
		[
			LET("s", "S", {"spoken": "S"}), LET("o", "O", {"spoken": "O"}),
			LET("l", "L", {"spoken": "L"}), LET("e", "E", {"spoken": "E"}),
		],
		[
			S("p1", "S", {"hint_icon": "sun", "hint_label": "1"}),
			S("p2", "O", {"hint_icon": "sun", "hint_label": "2"}),
			S("p3", "L", {"hint_icon": "sun", "hint_label": "3"}),
			S("p4", "E", {"hint_icon": "sun", "hint_label": "4"}),
		],
		_three_hints("SOLE è già diviso in SO-LE.",
			"Le lettere sono S, O, L, E.",
			"S, O, L, E: si legge SOLE."),
		"S-O-L-E: la prima via della città si illumina!",
		{"display": [D("sun", 1, "oro")], "effect": "insegna_sole", "listen": "SOLE"}))

	out.append(M("082", 9, "La casa di Bibi",
		"Ricostruire la parola CASA.",
		"Bibi ha perso l'insegna di casa. Metti C, A, S, A nelle caselle.",
		"sequence",
		[
			LET("c", "C", {"spoken": "C"}), LET("a1", "A", {"spoken": "A"}),
			LET("s", "S", {"spoken": "S"}), LET("a2", "A", {"spoken": "A"}),
		],
		[
			S("p1", "C", {"hint_icon": "casa", "hint_label": "1"}),
			S("p2", "A", {"hint_icon": "casa", "hint_label": "2"}),
			S("p3", "S", {"hint_icon": "casa", "hint_label": "3"}),
			S("p4", "A", {"hint_icon": "casa", "hint_label": "4"}),
		],
		_three_hints("La casa si divide in CA e SA.",
			"Servono due A: una dopo C e una alla fine.",
			"C, A, S, A: si legge CASA."),
		"C-A-S-A: la porta di casa si apre!",
		{"display": [D("casa", 1, "arancio")], "effect": "porta_casa", "listen": "CASA"}))

	out.append(M("083", 9, "La parola amica",
		"Associare parola scritta e immagine.",
		"Tre piedistalli mostrano SOLE, LUNA e PANE. Metti ogni parola sulla sua immagine.",
		"match",
		[
			WORD("sole", "SOLE", {"icon": "sun", "color": "oro", "spoken": "Sole"}),
			WORD("luna", "LUNA", {"icon": "moon", "color": "blu", "spoken": "Luna"}),
			WORD("pane", "PANE", {"icon": "pane", "color": "arancio", "spoken": "Pane"}),
		],
		[
			S("img_sole", "SOLE", {"hint_icon": "sun", "hint_label": "SOLE"}),
			S("img_luna", "LUNA", {"hint_icon": "moon", "hint_label": "LUNA"}),
			S("img_pane", "PANE", {"hint_icon": "pane", "hint_label": "PANE"}),
		],
		_three_hints("Guarda l'immagine e ascolta la parola.",
			"SOLE è la parola del sole, LUNA quella della luna.",
			"SOLE con il sole, LUNA con la luna, PANE con il pane."),
		"Parole e immagini si incontrano: tre finestre si aprono!",
		{"display": [D("sun", 1, "oro"), D("moon", 1, "blu"), D("pane", 1, "arancio")],
			"effect": "tre_finestre"}))

	out.append(M("084", 9, "Quale lettera manca?",
		"Completare una parola semplice.",
		"Il cartello dice M _ R E. Quale lettera manca per formare MARE?",
		"sequence",
		[
			LET("a", "A", {"spoken": "A"}), LET("e", "E", {"spoken": "E"}),
			LET("i", "I", {"spoken": "I"}),
		],
		[
			F("m", "M"), S("manca", "A", {"hint_label": "?"}), F("r", "R"), F("e", "E"),
		],
		_three_hints("Ascolta la parola: MA-RE.",
			"Dopo la M senti il suono A.",
			"Metti A nello spazio vuoto: MARE."),
		"MARE: il livello del mare sale e la città si specchia!",
		{"display": [D("onda", 3, "blu")], "effect": "mare_alto", "listen": "MARE"}))

	out.append(M("085", 9, "Il paniere della P",
		"Categorizzare per fonema iniziale.",
		"Tre parole cominciano con P, tre no. Metti ogni parola nel paniere giusto.",
		"group",
		[
			C("pane", "pane", {"icon": "pane", "spoken": "Pane"}),
			C("pera", "pera", {"icon": "pear", "spoken": "Pera"}),
			C("palla", "palla", {"icon": "ball", "color": "rossa", "spoken": "Palla"}),
			C("mela", "mela", {"icon": "apple", "spoken": "Mela"}),
			C("sole", "sole", {"icon": "sun", "spoken": "Sole"}),
			C("luna", "luna", {"icon": "moon", "spoken": "Luna"}),
		],
		[
			S("p1", ["pane", "pera", "palla"], {"group": "p", "hint_icon": "cesta", "hint_label": "P"}),
			S("p2", ["pane", "pera", "palla"], {"group": "p", "hint_icon": "cesta", "hint_label": "P"}),
			S("p3", ["pane", "pera", "palla"], {"group": "p", "hint_icon": "cesta", "hint_label": "P"}),
			S("n1", ["mela", "sole", "luna"], {"group": "non_p", "hint_icon": "cesta", "hint_label": "NON P"}),
			S("n2", ["mela", "sole", "luna"], {"group": "non_p", "hint_icon": "cesta", "hint_label": "NON P"}),
			S("n3", ["mela", "sole", "luna"], {"group": "non_p", "hint_icon": "cesta", "hint_label": "NON P"}),
		],
		_three_hints("Ascolta il primo suono di ogni parola.",
			"PANE, PERA e PALLA cominciano con P.",
			"Tre nel paniere P, tre nel paniere NON P."),
		"Tre con P, tre senza: il mercato si anima!",
		{"display": [D("cesta", 2, "marrone"), D("pane", 1, "oro")], "effect": "mercato",
			"groups": {"p": {"pane": 1, "pera": 1, "palla": 1},
				"non_p": {"mela": 1, "sole": 1, "luna": 1}}}))

	out.append(M("086", 9, "Il cartello degli animali",
		"Ricostruire due parole familiari.",
		"Due cartelli: CANE e TOPO. Ricomponi entrambe le parole con le lettere giuste.",
		"composite",
		[
			LET("c", "C", {"spoken": "C"}), LET("a", "A", {"spoken": "A"}),
			LET("n", "N", {"spoken": "N"}), LET("e", "E", {"spoken": "E"}),
			LET("t", "T", {"spoken": "T"}), LET("o1", "O", {"spoken": "O"}),
			LET("p", "P", {"spoken": "P"}), LET("o2", "O", {"spoken": "O"}),
		],
		[
			S("c1", "C"), S("c2", "A"), S("c3", "N"), S("c4", "E"),
			S("t1", "T"), S("t2", "O"), S("t3", "P"), S("t4", "O"),
		],
		_three_hints("CANE si divide in CA-NE. TOPO in TO-PO.",
			"C, A, N, E per il cane; T, O, P, O per il topo.",
			"Servono due O diverse per TOPO: nessun cubo si riusa."),
		"CANE e TOPO: due animaletti ringraziano Bibi!",
		{"display": [D("cane", 1, "marrone"), D("topo", 1, "grigio")], "effect": "animali",
			"subs": {"cane": ["c1", "c2", "c3", "c4"], "topo": ["t1", "t2", "t3", "t4"]}}))

	out.append(M("087", 9, "Piccolo o grande?",
		"Comprendere opposti lessicali in contesto.",
		"Il topolino è piccolo, l'orso è grande. Metti le parole sulle porte giuste.",
		"match",
		[
			C("piccolo", "piccolo", {"label": "PICCOLO", "icon": "topo", "color": "grigio", "spoken": "Piccolo"}),
			C("grande", "grande", {"label": "GRANDE", "icon": "orso", "color": "marrone", "spoken": "Grande"}),
		],
		[
			S("porta_topo", "piccolo", {"hint_icon": "topo", "hint_label": "PICCOLO"}),
			S("porta_orso", "grande", {"hint_icon": "orso", "hint_label": "GRANDE"}),
		],
		_three_hints("Guarda la dimensione degli animali.",
			"Il topolino è piccolo, l'orso è grande.",
			"PICCOLO con il topolino, GRANDE con l'orso."),
		"Piccolo e grande: la piazza delle proporzioni si apre!",
		{"display": [D("topo", 1, "grigio"), D("orso", 1, "marrone")], "effect": "piazza"}))

	out.append(M("088", 9, "Il negozio delle categorie",
		"Catalogare immagini e parole semplici.",
		"Sei oggetti: tre da mangiare, tre per giocare. Mettili nei negozi giusti.",
		"group",
		[
			C("mela", "mela", {"icon": "apple", "spoken": "Mela"}),
			C("pera", "pera", {"icon": "pear", "spoken": "Pera"}),
			C("pane", "pane", {"icon": "pane", "spoken": "Pane"}),
			C("palla", "palla", {"icon": "ball", "color": "blu", "spoken": "Palla"}),
			C("treno", "treno", {"icon": "train", "color": "verde", "spoken": "Treno"}),
			C("trottola", "trottola", {"icon": "top", "color": "rosso", "spoken": "Trottola"}),
		],
		[
			S("m1", ["mela", "pera", "pane"], {"group": "mangiare", "hint_icon": "cibo", "hint_label": "DA MANGIARE"}),
			S("m2", ["mela", "pera", "pane"], {"group": "mangiare", "hint_icon": "cibo", "hint_label": "DA MANGIARE"}),
			S("m3", ["mela", "pera", "pane"], {"group": "mangiare", "hint_icon": "cibo", "hint_label": "DA MANGIARE"}),
			S("g1", ["palla", "treno", "trottola"], {"group": "giocare", "hint_icon": "gioco", "hint_label": "PER GIOCARE"}),
			S("g2", ["palla", "treno", "trottola"], {"group": "giocare", "hint_icon": "gioco", "hint_label": "PER GIOCARE"}),
			S("g3", ["palla", "treno", "trottola"], {"group": "giocare", "hint_icon": "gioco", "hint_label": "PER GIOCARE"}),
		],
		_three_hints("Alcuni oggetti si mangiano, altri servono per giocare.",
			"Mela, pera e pane sono cibo. Palla, treno e trottola sono giochi.",
			"Tre nel negozio DA MANGIARE, tre nel negozio PER GIOCARE."),
		"Due negozi pieni: la città si riempie di voci!",
		{"display": [D("cibo", 1, "verde"), D("gioco", 1, "blu")], "effect": "negozi",
			"groups": {"mangiare": {"mela": 1, "pera": 1, "pane": 1},
				"giocare": {"palla": 1, "treno": 1, "trottola": 1}}}))

	out.append(M("089", 9, "Le parole in rima",
		"Riconoscere rime e abbinare coppie di parole.",
		"PANE fa rima con CANE, LUNA con UNA. Metti ogni parola accanto alla sua rima.",
		"match",
		[
			WORD("cane", "CANE", {"icon": "cane", "spoken": "Cane"}),
			WORD("una", "UNA", {"icon": "star", "color": "oro", "spoken": "Una"}),
		],
		[
			F("pane", "PANE", {"fixed_icon": "pane", "fixed_color": "oro"}),
			S("rima_pane", "CANE", {"hint_icon": "pane", "hint_label": "PANE"}),
			F("luna", "LUNA", {"fixed_icon": "moon", "fixed_color": "blu"}),
			S("rima_luna", "UNA", {"hint_icon": "moon", "hint_label": "LUNA"}),
		],
		_three_hints("Ascolta la coda delle parole: -ane, -una.",
			"PANE e CANE finiscono uguale. LUNA e UNA finiscono uguale.",
			"CANE accanto a PANE, UNA accanto a LUNA."),
		"Due rime, due campane: la città canta!",
		{"display": [D("bell", 2, "oro"), D("moon", 1, "blu")], "effect": "campane_rima"}))

	out.append(M("090", 9, "La festa delle insegne",
		"Combinare scrittura guidata, immagine e suoni.",
		"Due insegne incomplete: SO_E e _ANE. Metti la lettera giusta in ciascuna.",
		"composite",
		[
			LET("l", "L", {"spoken": "L"}), LET("p", "P", {"spoken": "P"}),
			LET("m", "M", {"spoken": "M"}), LET("c", "C", {"spoken": "C"}),
		],
		[
			F("s", "S"), F("o", "O"), S("so_e", "L", {"hint_label": "?"}), F("e", "E"),
			S("pane_a", "P", {"hint_label": "?"}), F("a", "A"), F("n", "N"), F("e2", "E"),
		],
		_three_hints("La prima insegna è SO_E: manca una lettera.",
			"SOLE vuole L. PANE vuole P.",
			"Metti L in SO_E e P in _ANE."),
		"SOLE e PANE: la Pietra Magica delle Parole accende la città!",
		{"display": [D("sun", 1, "oro"), D("pane", 1, "oro")], "effect": "runa_parole",
			"subs": {"sole": ["s", "o", "so_e", "e"], "pane": ["pane_a", "a", "n", "e2"]}}))

	return out

# ================================================================== REGIONE 10
static func _r10() -> Array:
	var out: Array = []

	out.append(M("091", 10, "L'atrio delle forme",
		"Trasferire classificazione e sequenza.",
		"Completa la sequenza rosso cerchio, blu quadrato, rosso cerchio… e ordina gli altri cubi nei cesti.",
		"composite",
		[
			C("qb", "quadrato_blu", {"icon": "square", "color": "blu", "spoken": "Quadrato blu"}),
			C("cg", "cerchio_giallo", {"icon": "circle", "color": "giallo", "spoken": "Cerchio giallo"}),
			C("sg", "quadrato_giallo", {"icon": "square", "color": "giallo", "spoken": "Quadrato giallo"}),
		],
		[
			F("s1", "cerchio_rosso", {"fixed_icon": "circle", "fixed_color": "rosso"}),
			F("s2", "quadrato_blu", {"fixed_icon": "square", "fixed_color": "blu"}),
			F("s3", "cerchio_rosso", {"fixed_icon": "circle", "fixed_color": "rosso"}),
			S("s4", "quadrato_blu", {"hint_label": "?"}),
			S("cesta_c", "cerchio_giallo", {"group": "cerchio", "capacity": 1, "hint_icon": "cesta", "hint_label": "CERCHIO"}),
			S("cesta_q", "quadrato_giallo", {"group": "quadrato", "capacity": 1, "hint_icon": "cesta", "hint_label": "QUADRATO"}),
		],
		_three_hints("La sequenza alterna cerchio rosso e quadrato blu.",
			"Dopo il terzo incastro torna il quadrato blu.",
			"Il quarto incastro vuole il quadrato blu; poi un cerchio e un quadrato nei cesti."),
		"Sequenza e cesti: il primo piano della torre si illumina!",
		{"display": [D("circle", 2, "rosso"), D("square", 2, "blu")], "effect": "piano_primo",
			"subs": {"sequenza": ["s4"], "cesti": ["cesta_c", "cesta_q"]}}))

	out.append(M("092", 10, "La scala dei numeri",
		"Ordinare, individuare il numero mancante e confrontare.",
		"Completa la scala 7, 8, vuoto, 10 e il confronto 9 ? 6.",
		"composite",
		[
			NUM("n9", 9), NUM("n11", 11), NUM("n5", 5),
			SYM("gt", ">", "Maggiore"), SYM("lt", "<", "Minore"), SYM("eq", "=", "Uguale"),
		],
		[
			F("g7", "7"), F("g8", "8"), S("g9", "9", {"hint_label": "?"}), F("g10", "10"),
			S("confronto", ">", {"hint_label": "9  ?  6"}),
		],
		_three_hints("La scala cresce di uno: 7, 8, ?, 10.",
			"Dopo l'8 viene il 9.",
			"Metti 9 nel gradino vuoto e > nel confronto, perché 9 è più di 6."),
		"Nove sul gradino, maggiore nel confronto: la torre sale!",
		{"display": [D("gradino", 4, "grigio"), D("pallino", 9, "oro")], "effect": "scala_torre",
			"subs": {"scala": ["g9"], "confronto": ["confronto"]}}))

	out.append(M("093", 10, "Il corridoio di quattro salti",
		"Orientarsi mediante la programmazione di passi.",
		"Porta la luce dall'angolo in basso a sinistra a quello in alto a destra in quattro passi.",
		"route",
		[
			C("su1", "SU", {"icon": "arrow_up", "color": "verde", "spoken": "Su"}),
			C("su2", "SU", {"icon": "arrow_up", "color": "verde", "spoken": "Su"}),
			C("de1", "DESTRA", {"icon": "arrow_right", "color": "arancio", "spoken": "Destra"}),
			C("de2", "DESTRA", {"icon": "arrow_right", "color": "arancio", "spoken": "Destra"}),
			C("giu", "GIÙ", {"icon": "arrow_down", "color": "rosa", "spoken": "Giù"}),
		],
		[
			S("step1", ""), S("step2", ""), S("step3", ""), S("step4", ""),
		],
		_three_hints("Il centro è chiuso: non puoi tagliare in diagonale.",
			"Servono due passi SU e due passi DESTRA.",
			"SU, SU, DESTRA, DESTRA porta la luce in alto a destra."),
		"Quattro salti: la luce raggiunge il piano successivo!",
		{"route": {"size": 3, "start": [0, 2], "goal": [2, 0], "blocked": [[1, 1]],
			"sockets": ["step1", "step2", "step3", "step4"],
			"solution": ["SU", "SU", "DESTRA", "DESTRA"]}, "effect": "corridoio_luce"}))

	out.append(M("094", 10, "La sala dei sei cristalli",
		"Somme e quantità da 0 a 10.",
		"Due casse hanno 2 e 4 cristalli. Metti i numeri delle casse e il totale.",
		"arithmetic",
		[
			NUM("n2", 2), NUM("n4", 4), NUM("n5", 5), NUM("n6", 6), NUM("n7", 7),
		],
		[
			S("cassa_a", "2", {"hint_icon": "gem", "hint_label": "2"}),
			F("plus", "+"),
			S("cassa_b", "4", {"hint_icon": "gem", "hint_label": "4"}),
			F("eq", "="),
			S("out", "6", {"hint_label": "?"}),
		],
		_three_hints("Conta i cristalli di ogni cassa.",
			"Due più quattro fa sei.",
			"Metti 2 e 4 nelle casse, poi 6 nel risultato."),
		"Due più quattro fa sei: sei specchi si riaccendono!",
		{"display": [D("gem", 2, "teal"), D("gem", 4, "blu")], "effect": "specchi",
			"subs": {"ingressi": ["cassa_a", "cassa_b"], "uscita": ["out"]}}))

	out.append(M("095", 10, "Il ponte misurato",
		"Misurare una lunghezza e scegliere il numero.",
		"Il ponte è lungo cinque unità. Copri tutte le sedi e scegli il numero giusto.",
		"measurement",
		[
			C("u1", "unita", {"label": "1", "icon": "cubetto", "color": "legno", "spoken": "Unità"}),
			C("u2", "unita", {"label": "1", "icon": "cubetto", "color": "legno", "spoken": "Unità"}),
			C("u3", "unita", {"label": "1", "icon": "cubetto", "color": "legno", "spoken": "Unità"}),
			C("u4", "unita", {"label": "1", "icon": "cubetto", "color": "legno", "spoken": "Unità"}),
			C("u5", "unita", {"label": "1", "icon": "cubetto", "color": "legno", "spoken": "Unità"}),
			NUM("n4", 4), NUM("n5", 5), NUM("n6", 6),
		],
		[
			S("p1", "unita"), S("p2", "unita"), S("p3", "unita"),
			S("p4", "unita"), S("p5", "unita"),
			S("risposta", "5", {"hint_label": "?"}),
		],
		_three_hints("Metti un cubo-unità in ogni sede del ponte.",
			"Le sedi sono cinque.",
			"Cinque unità, cinque sedi: il numero è 5."),
		"Cinque unità contigue: il ponte porta alla biblioteca della torre!",
		{"display": [D("cubetto", 5, "legno")], "effect": "ponte_torre",
			"measure": {"target": 5, "sockets": ["p1", "p2", "p3", "p4", "p5"]}}))

	out.append(M("096", 10, "La finestra della luna",
		"Riconoscere sillabe e ricomporre la parola.",
		"Prima forma LU-NA con le sillabe, poi L-U-N-A con le lettere.",
		"composite",
		[
			SYL("lu", "LU", {"spoken": "Lu"}), SYL("na", "NA", {"spoken": "Na"}),
			LET("l", "L", {"spoken": "L"}), LET("u", "U", {"spoken": "U"}),
			LET("n", "N", {"spoken": "N"}), LET("a", "A", {"spoken": "A"}),
		],
		[
			S("sil1", "LU", {"hint_icon": "moon", "hint_label": "1"}),
			S("sil2", "NA", {"hint_icon": "moon", "hint_label": "2"}),
			S("let1", "L", {"hint_icon": "moon", "hint_label": "L"}),
			S("let2", "U", {"hint_icon": "moon", "hint_label": "U"}),
			S("let3", "N", {"hint_icon": "moon", "hint_label": "N"}),
			S("let4", "A", {"hint_icon": "moon", "hint_label": "A"}),
		],
		_three_hints("Due sillabe formano LUNA, quattro lettere la scrivono.",
			"LU-NA con le sillabe; L-U-N-A con le lettere.",
			"Completa prima le sillabe, poi le lettere."),
		"LU-NA e L-U-N-A: la finestra fa entrare la luce della luna!",
		{"display": [D("moon", 1, "blu"), D("stella_finale", 1, "oro")], "effect": "finestra_luna",
			"subs": {"sillabe": ["sil1", "sil2"], "lettere": ["let1", "let2", "let3", "let4"]}}))

	out.append(M("097", 10, "Il laboratorio delle differenze",
		"Classificare con due criteri e numerare gli insiemi.",
		"Dividi i sei cubi per colore e forma, poi metti il numero giusto su ogni cesto.",
		"composite",
		[
			C("rc1", "rosso_cerchio", {"icon": "circle", "color": "rosso", "spoken": "Rosso cerchio"}),
			C("rc2", "rosso_cerchio", {"icon": "circle", "color": "rosso", "spoken": "Rosso cerchio"}),
			C("rc3", "rosso_cerchio", {"icon": "circle", "color": "rosso", "spoken": "Rosso cerchio"}),
			C("bs1", "blu_quadrato", {"icon": "square", "color": "blu", "spoken": "Blu quadrato"}),
			C("bs2", "blu_quadrato", {"icon": "square", "color": "blu", "spoken": "Blu quadrato"}),
			C("rs1", "rosso_quadrato", {"icon": "square", "color": "rosso", "spoken": "Rosso quadrato"}),
			NUM("n1", 1), NUM("n2", 2), NUM("n3", 3),
		],
		[
			S("cesto_rc", "rosso_cerchio", {"group": "rc", "capacity": 3, "hint_icon": "cesta", "hint_label": "ROSSO CERCHIO"}),
			S("cesto_bs", "blu_quadrato", {"group": "bs", "capacity": 2, "hint_icon": "cesta", "hint_label": "BLU QUADRATO"}),
			S("cesto_rs", "rosso_quadrato", {"group": "rs", "capacity": 1, "hint_icon": "cesta", "hint_label": "ROSSO QUADRATO"}),
			S("num_rc", "3", {"hint_label": "?"}), S("num_bs", "2", {"hint_label": "?"}),
			S("num_rs", "1", {"hint_label": "?"}),
		],
		_three_hints("Guarda due cose insieme: colore e forma.",
			"Ci sono tre cerchi rossi, due quadrati blu e un quadrato rosso.",
			"Tre nel cesto rosso cerchio, due nel blu quadrato, uno nel rosso quadrato; poi 3, 2, 1."),
		"Colore e forma, quantità e numero: la settima luce si accende!",
		{"display": [D("circle", 3, "rosso"), D("square", 2, "blu"), D("square", 1, "rosso")],
			"effect": "settima_luce",
			"groups": {"rc": {"rosso_cerchio": 3}, "bs": {"blu_quadrato": 2},
				"rs": {"rosso_quadrato": 1}},
			"subs": {"cesti": ["cesto_rc", "cesto_bs", "cesto_rs"],
				"numeri": ["num_rc", "num_bs", "num_rs"]}}))

	out.append(M("098", 10, "Il messaggio delle tre parole",
		"Abbinare sillabe, parole e immagini.",
		"Ricomponi SOLE, CASA e PANE con le loro sillabe. Puoi completarle nell'ordine che vuoi.",
		"composite",
		[
			SYL("so", "SO", {"spoken": "So"}), SYL("le", "LE", {"spoken": "Le"}),
			SYL("ca", "CA", {"spoken": "Ca"}), SYL("sa", "SA", {"spoken": "Sa"}),
			SYL("pa", "PA", {"spoken": "Pa"}), SYL("ne", "NE", {"spoken": "Ne"}),
		],
		[
			S("sole1", "SO", {"hint_icon": "sun", "hint_label": "SOLE"}),
			S("sole2", "LE", {"hint_icon": "sun", "hint_label": "SOLE"}),
			S("casa1", "CA", {"hint_icon": "casa", "hint_label": "CASA"}),
			S("casa2", "SA", {"hint_icon": "casa", "hint_label": "CASA"}),
			S("pane1", "PA", {"hint_icon": "pane", "hint_label": "PANE"}),
			S("pane2", "NE", {"hint_icon": "pane", "hint_label": "PANE"}),
		],
		_three_hints("Ogni leggio vuole due sillabe.",
			"SO-LE, CA-SA, PA-NE.",
			"Completa i tre leggii nell'ordine che preferisci."),
		"SOLE, CASA, PANE: l'osservatorio si apre!",
		{"display": [D("sun", 1, "oro"), D("casa", 1, "arancio"), D("pane", 1, "oro")],
			"effect": "osservatorio",
			"subs": {"sole": ["sole1", "sole2"], "casa": ["casa1", "casa2"],
				"pane": ["pane1", "pane2"]}}))

	out.append(M("099", 10, "Le quattro chiavi",
		"Integrare classificazione, conteggio, misura e ascolto.",
		"Quattro stazioni: la forma, le gemme, il nastro più lungo e la parola MARE.",
		"composite",
		[
			C("triangolo", "triangolo", {"icon": "triangle", "color": "viola", "spoken": "Triangolo"}),
			C("cerchio", "cerchio", {"icon": "circle", "color": "verde", "spoken": "Cerchio"}),
			C("quadrato", "quadrato", {"icon": "square", "color": "arancio", "spoken": "Quadrato"}),
			C("gemme5", "gemme5", {"icon": "gem", "count": 5, "label": "5", "color": "teal", "spoken": "Cinque gemme"}),
			C("corda2", "corda2", {"icon": "nastro", "color": "rosa", "spoken": "Nastro corto",
				"bar": {"length": 2, "color": "rosa"}}),
			C("corda4", "corda4", {"icon": "nastro", "color": "teal", "spoken": "Nastro lungo",
				"bar": {"length": 4, "color": "teal"}}),
			SYL("ma", "MA", {"spoken": "Ma"}), SYL("re", "RE", {"spoken": "Re"}),
			SYL("ra", "RA", {"spoken": "Ra"}),
		],
		[
			S("forma", "triangolo", {"hint_icon": "triangle", "hint_label": "TRIANGOLO"}),
			S("gemme", "gemme5", {"hint_icon": "gem", "hint_label": "5"}),
			S("lungo", "corda4", {"hint_icon": "nastro", "hint_label": "PIÙ LUNGO"}),
			S("w1", "MA", {"hint_icon": "onda", "hint_label": "1"}),
			S("w2", "RE", {"hint_icon": "onda", "hint_label": "2"}),
		],
		_three_hints("Ogni stazione ha il suo cubo e il suo incastro.",
			"La forma è il triangolo; le gemme sono cinque; il nastro lungo è quello da quattro.",
			"Triangolo, cinque gemme, nastro lungo, poi MA-RE."),
		"Quattro serrature si aprono: la torre è quasi accesa!",
		{"display": [D("triangle", 1, "viola"), D("gem", 5, "teal"), D("nastro", 1, "teal"), D("onda", 2, "blu")],
			"effect": "quattro_chiavi",
			"subs": {"forma": ["forma"], "gemme": ["gemme"], "misura": ["lungo"], "parola": ["w1", "w2"]}}))

	out.append(M("100", 10, "La Stella delle Possibilità",
		"Trasferire in un finale narrativo multidominio.",
		"Completa i cinque altari: la scala, l'addizione, la parola, la corda e le forme.",
		"composite",
		[
			NUM("n3", 3), NUM("n5", 5),
			SYL("pa", "PA", {"spoken": "Pa"}), SYL("ne", "NE", {"spoken": "Ne"}),
			C("corda3", "corda3", {"icon": "corda", "color": "giallo", "spoken": "Corda corta",
				"bar": {"length": 3, "color": "giallo"}}),
			C("corda5", "corda5", {"icon": "corda", "color": "viola", "spoken": "Corda lunga",
				"bar": {"length": 5, "color": "viola"}}),
			C("cerchio", "cerchio", {"icon": "circle", "color": "teal", "spoken": "Cerchio"}),
			C("triangolo", "triangolo", {"icon": "triangle", "color": "rosa", "spoken": "Triangolo"}),
		],
		[
			F("s1", "1"), F("s2", "2"), S("s3", "3", {"hint_label": "?"}), F("s4", "4"),
			F("a2", "2"), F("plus", "+"), F("b3", "3"), F("eq", "="),
			S("somma", "5", {"hint_label": "?"}),
			S("sill1", "PA", {"hint_icon": "pane", "hint_label": "1"}),
			S("sill2", "NE", {"hint_icon": "pane", "hint_label": "2"}),
			S("corda", "corda5", {"hint_icon": "corda", "hint_label": "PIÙ LUNGA"}),
			S("forma_c", "cerchio", {"hint_icon": "circle", "hint_label": "CERCHIO"}),
			S("forma_t", "triangolo", {"hint_icon": "triangle", "hint_label": "TRIANGOLO"}),
		],
		_three_hints("Cinque altari, cinque piccole prove.",
			"Nella scala manca il 3; 2+3 fa 5; la parola è PA-NE.",
			"La corda più lunga è quella da 5; cerchio con cerchio, triangolo con triangolo."),
		"Le cento pietre magiche brillano insieme: la Stella delle Possibilità è accesa!",
		{"display": [D("stella_finale", 1, "oro"), D("nota", 10, "viola")],
			"effect": "stella_finale",
			"subs": {"scala": ["s3"], "somma": ["somma"], "parola": ["sill1", "sill2"],
				"corda": ["corda"], "forme": ["forma_c", "forma_t"]}}))

	return out
