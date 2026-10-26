extends SceneTree

func _initialize() -> void:
	var out := {
		"regions": MissionData.REGION_NAMES,
		"custodians": MissionData.CUSTODIANS,
		"custodian_lines": MissionData.CUSTODIAN_LINES,
		"missions": [],
	}
	for m in MissionData.all():
		var item := {
			"id": str(m.get("id", "")),
			"title": str(m.get("title", "")),
			"instruction": str(m.get("instruction", "")),
			"success": str(m.get("success", "")),
			"hints": [],
			"cubes": [],
			"sockets": [],
		}
		for h in m.get("hints", []):
			item["hints"].append(str(h))
		for c in m.get("cubes", []):
			if not (c is Dictionary):
				continue
			var spoken := str(c.get("spoken", ""))
			if spoken == "":
				spoken = str(c.get("label", c.get("value", "")))
			if spoken != "":
				item["cubes"].append(spoken)
		for s in m.get("sockets", []):
			if not (s is Dictionary):
				continue
			var lab := str(s.get("hint_label", ""))
			if lab == "":
				lab = str(s.get("fixed_label", ""))
			if lab != "":
				item["sockets"].append(lab)
		out["missions"].append(item)
	var f := FileAccess.open("res://tools/voice_texts.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	print("VOICE_DUMP missions=%d" % out["missions"].size())
	quit(0)
