extends SceneTree
## Verifica la voice bank pre-registrata: ogni OGG deve essere importato e
## caricabile, e il lookup usato da Audio._bank_stream deve trovarlo.
## Uso:
##   godot --headless --path . --script tests/voice_bank.gd

func _initialize() -> void:
	await process_frame
	var dirs: Array[String] = ["narrator"]
	for role in ["lino", "ora", "pina", "tiko", "fero", "milla", "eco", "sila", "bibi", "astra",
			"coniglio", "uccello", "gatto", "tarta", "volpe", "riccio", "amico1", "amico2"]:
		dirs.append(role)
	for i in range(1, 11):
		dirs.append("animale%d" % i)
	var total := 0
	var loaded := 0
	var bad: Array[String] = []
	var seconds := 0.0
	for role in dirs:
		var path := "res://assets/voices/%s" % role
		var d := DirAccess.open(path)
		if d == null:
			bad.append("manca la cartella " + role)
			continue
		for file in d.get_files():
			if not file.ends_with(".ogg"):
				continue
			total += 1
			var res_path := path + "/" + file
			if not ResourceLoader.exists(res_path):
				bad.append("non importato " + res_path)
				continue
			var stream = load(res_path)
			if stream is AudioStream:
				loaded += 1
				seconds += stream.get_length()
			else:
				bad.append("non audio " + res_path)
	print("VOICEBANK files=%d loaded=%d minuti=%.1f problemi=%d" % [
		total, loaded, seconds / 60.0, bad.size()])
	for b in bad.slice(0, 20):
		print(" - " + b)
	# Controllo diretto del lookup usato dal gioco, senza avviare l'autoload.
	var script: Script = load("res://scripts/core/audio.gd")
	var audio: Node = script.new()
	var samples := [
		["narrator", "Benvenuto a Lumeria. Segui le luci: ogni regione nasconde dieci pietre magiche."],
		["narrator", "Metti ogni fiore nell'aiuola del suo colore."],
		["narrator", "La porta dei tre colori. Metti ogni fiore nell'aiuola del suo colore."],
		["narrator", "Hai riunito i fiori dello stesso colore: tre, tre e tre!"],
		["narrator", "Guarda il colore del fiore e il colore dell'aiuola."],
		["narrator", "Fiore rosso"],
		["lino", "Guarda! Le forme si sono mescolate. Aiutami a ritrovare le somiglianze!"],
		["tarta", "Piano piano si va lontano! Vuoi fare due passi con me?"],
		["animale2", "Ascolta come fischia il vento tra le foglie!"],
		["narrator", "Benvenuto a Lumeria! Cento pietre magiche luminose aspettano di essere riaccese. Qui nessuno perde e nessuno ha fretta."],
	]
	var found := 0
	for s in samples:
		var stream = audio._bank_stream(s[0], s[1])
		if stream != null:
			found += 1
		else:
			print(" - lookup fallito: %s / %s" % [s[0], s[1]])
	print("VOICEBANK lookup=%d/%d" % [found, samples.size()])
	# Copertura completa dei testi delle missioni: se un testo cambia senza
	# rigenerare la banca, il test lo segnala subito.
	var mission_texts := 0
	var mission_missing: Array[String] = []
	for m in MissionData.all():
		var texts: Array[String] = []
		var title := str(m.get("title", ""))
		var instr := str(m.get("instruction", ""))
		if title != "" and instr != "":
			texts.append("%s. %s" % [title, instr])
		if title != "":
			texts.append(title)
		if instr != "":
			texts.append(instr)
		for h in m.get("hints", []):
			if str(h).strip_edges() != "":
				texts.append(str(h))
		if str(m.get("success", "")).strip_edges() != "":
			texts.append(str(m.get("success", "")))
		for c in m.get("cubes", []):
			if not (c is Dictionary):
				continue
			var spoken := str(c.get("spoken", ""))
			if spoken == "":
				spoken = str(c.get("label", c.get("value", "")))
			if spoken != "":
				texts.append(spoken)
		for so in m.get("sockets", []):
			if not (so is Dictionary):
				continue
			var lab := str(so.get("hint_label", ""))
			if lab == "":
				lab = str(so.get("fixed_label", ""))
			if lab != "":
				texts.append(lab)
				texts.append("%s. Incastro vuoto." % lab)
		for t in texts:
			mission_texts += 1
			if audio._bank_stream("narrator", t) == null:
				mission_missing.append("%s: %s" % [str(m.get("id", "")), t])
	for i in range(MissionData.CUSTODIAN_LINES.size()):
		var role := str(MissionData.CUSTODIANS[i]).to_lower()
		mission_texts += 1
		if audio._bank_stream(role, str(MissionData.CUSTODIAN_LINES[i])) == null:
			mission_missing.append("%s: %s" % [role, str(MissionData.CUSTODIAN_LINES[i])])
	print("VOICEBANK missioni=%d mancanti=%d" % [mission_texts, mission_missing.size()])
	for mm in mission_missing.slice(0, 10):
		print(" - manca: " + mm)
	var ok := bad.is_empty() and found == samples.size() and mission_missing.is_empty()
	audio.free()
	print("VOICEBANK %s" % ("OK" if ok else "FALLITO"))
	quit(0 if ok else 1)
