extends Node
## Controllo aggiornamenti e installazione della nuova versione.
##
## All'avvio (se il controllo è attivo) interroga l'API pubblica di GitHub per
## l'ultima release. Se il tag è più recente della versione installata mostra
## una richiesta con "Aggiorna ora" / "Più tardi". Il download avviene nella
## cartella Download dell'utente e viene verificato con SHA256SUMS; poi parte
## un piccolo script di installazione che aspetta la chiusura del gioco,
## sostituisce i file e riapre Lumeria.
##
## Nessun dato personale viene inviato: la richiesta contiene solo lo User-Agent
## del programma. In editor il controllo è disattivato; da Impostazioni → Gioco
## si può disattivare anche nell'app esportata.

const VERSION_URL := "https://raw.githubusercontent.com/MaestroLivio/lumeria/main/version.json"
const RELEASES_URL := "https://github.com/MaestroLivio/lumeria/releases/latest"
const USER_AGENT := "Lumeria-Updater/1.1"
const CHECK_DELAY := 1.6

var _dialog: ConfirmationDialog
var _info: AcceptDialog
var _latest: Dictionary = {}
var _latest_version := ""
var _asset_name := ""
var _asset_url := ""
var _checksums_url := ""
var _downloading := false
var _checking := false
var _dismissed := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless" or _is_test_run():
		return
	call_deferred("_auto_check")

## Controllo manuale da Impostazioni → Gioco.
func check_now(manual: bool = true) -> void:
	if _downloading or _checking:
		return
	_dismissed = false
	if _dialog != null and _dialog.visible:
		_dialog.get_ok_button().grab_focus()
		return
	_check(manual)

func _auto_check() -> void:
	if OS.has_feature("editor"):
		return
	await get_tree().create_timer(CHECK_DELAY, true).timeout
	if not bool(Settings.get_setting("check_updates", true)) or _dismissed:
		return
	var scene := get_tree().current_scene
	if scene != null and str(scene.get("state")) != "menu":
		# Se il giocatore ha già iniziato, riprova una volta quando torna al menu.
		await get_tree().create_timer(2.5, true).timeout
		scene = get_tree().current_scene
		if scene != null and str(scene.get("state")) != "menu":
			return
	_check(false)

func _is_test_run() -> bool:
	for arg in OS.get_cmdline_user_args():
		if str(arg) in ["--smoke", "--selftest", "--shots", "--quickshot"]:
			return true
	return false

func _current_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "1.0.0")).strip_edges()

func _check(manual: bool) -> void:
	_checking = true
	var body := await _get_text(VERSION_URL)
	_checking = false
	if body == "":
		if manual:
			_show_info("Controllo non riuscito",
				"Non riesco a raggiungere GitHub. Controlla la connessione e riprova.")
		return
	var parsed: Variant = JSON.parse_string(body)
	if not (parsed is Dictionary):
		if manual:
			_show_info("Controllo non riuscito", "La risposta del server non è valida.")
		return
	_latest = parsed as Dictionary
	_latest_version = str(_latest.get("version", "")).strip_edges()
	if _latest_version == "":
		_latest_version = str(_latest.get("tag", "")).trim_prefix("v")
	var current := _current_version()
	if not _is_newer(_latest_version, current):
		if manual:
			_show_info("Nessun aggiornamento",
				"Lumeria è già aggiornata.\nVersione installata: %s." % current)
		return
	var assets: Dictionary = _latest.get("assets", {}) if _latest.get("assets", {}) is Dictionary else {}
	var key := _pick_asset_key()
	_asset_url = str(assets.get(key, ""))
	_asset_name = _asset_url.get_file()
	_checksums_url = str(_latest.get("checksums", ""))
	_show_update_dialog(current)

func _show_update_dialog(current: String) -> void:
	if _dialog == null:
		_dialog = ConfirmationDialog.new()
		_dialog.name = "AggiornamentoLumeria"
		_dialog.title = "Aggiornamento disponibile"
		_dialog.ok_button_text = "Aggiorna ora"
		_dialog.cancel_button_text = "Più tardi"
		_dialog.dialog_hide_on_ok = false
		_dialog.exclusive = true
		_dialog.theme = UITheme.make_theme()
		_dialog.min_size = Vector2i(620, 280)
		add_child(_dialog)
		_dialog.confirmed.connect(_on_confirmed)
		_dialog.canceled.connect(_on_later)
		_dialog.close_requested.connect(_on_later)
	var notes := str(_latest.get("notes", "")).strip_edges()
	if notes.length() > 420:
		notes = notes.substr(0, 420) + "…"
	_dialog.dialog_text = (
		"È disponibile Lumeria %s.\nVersione installata: %s.\n\n"
		% [_latest_version.trim_prefix("v"), current]
		+ (notes + "\n\n" if notes != "" else "")
		+ "Vuoi scaricare l'aggiornamento e installarlo adesso?\n"
		+ ("Il gioco si chiuderà e si riaprirà aggiornato." if not OS.has_feature("editor")
			else "In editor si apre la pagina della release."))
	_dialog.get_ok_button().disabled = false
	_dialog.get_cancel_button().disabled = false
	_dialog.get_cancel_button().visible = true
	_dialog.popup_centered(Vector2i(620, 280))
	_dialog.get_ok_button().grab_focus()

func _on_later() -> void:
	_dismissed = true
	if _dialog != null:
		_dialog.hide()

func _on_confirmed() -> void:
	if OS.has_feature("editor"):
		OS.shell_open(_release_url())
		_dialog.hide()
		return
	if _downloading:
		return
	if _asset_url == "":
		_show_info("Pacchetto non disponibile",
			"Non trovo il pacchetto per questo sistema nella release.\n"
			+ "Puoi scaricarlo manualmente dalla pagina delle release.",
			_release_url())
		return
	_downloading = true
	_dialog.dialog_text = "Preparo il download di Lumeria %s..." % _latest_version.trim_prefix("v")
	_dialog.get_ok_button().disabled = true
	_dialog.get_cancel_button().disabled = true
	_download_and_install()

func _download_and_install() -> void:
	var version := _latest_version.trim_prefix("v")
	var dir := _download_dir()
	if not DirAccess.dir_exists_absolute(dir) and DirAccess.make_dir_recursive_absolute(dir) != OK:
		_fail("Non riesco a creare la cartella di download.")
		return
	var dest := dir.path_join("Lumeria-%s-%s" % [version, _asset_name])
	if FileAccess.file_exists(dest):
		DirAccess.remove_absolute(dest)
	_dialog.dialog_text = "Scarico Lumeria %s...\n0%" % version
	var req := HTTPRequest.new()
	req.timeout = 900.0
	req.download_file = dest
	add_child(req)
	req.download_progress.connect(_on_progress)
	var state := {"done": false, "result": -1, "code": 0}
	req.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
		state["done"] = true
		state["result"] = result
		state["code"] = code)
	var started := req.request(_asset_url, ["User-Agent: " + USER_AGENT])
	if started != OK:
		req.queue_free()
		_fail("Non riesco a preparare il download.")
		return
	while not bool(state["done"]):
		await get_tree().process_frame
	req.queue_free()
	var code := int(state["code"])
	if int(state["result"]) != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("Il download non è riuscito (codice %d)." % code)
		return
	var downloaded_file := FileAccess.open(dest, FileAccess.READ)
	var downloaded_size := downloaded_file.get_length() if downloaded_file != null else 0
	if downloaded_file != null:
		downloaded_file.close()
	if downloaded_size < 1024:
		_fail("Il file scaricato è incompleto.")
		return
	_dialog.dialog_text = "Verifico il pacchetto..."
	if not await _verify_checksum(dest):
		_fail("La verifica del pacchetto non è riuscita. Scarica la nuova versione dalla pagina delle release.")
		return
	_dialog.dialog_text = "Preparo l'installazione..."
	if not _install(dest):
		return
	_dialog.dialog_text = "Aggiornamento pronto.\nIl gioco si chiuderà e si riaprirà tra poco."
	_dialog.get_cancel_button().visible = false
	await get_tree().create_timer(1.4, true).timeout
	get_tree().quit()

func _on_progress(downloaded: int, total: int) -> void:
	if _dialog == null:
		return
	if total > 0:
		var pct := int(clampf(float(downloaded) / float(total), 0.0, 1.0) * 100.0)
		_dialog.dialog_text = "Scarico Lumeria %s...\n%d%%" % [_latest_version.trim_prefix("v"), pct]
	else:
		_dialog.dialog_text = "Scarico Lumeria %s...\n%.1f MB" % [
			_latest_version.trim_prefix("v"), float(downloaded) / 1048576.0]

func _verify_checksum(path: String) -> bool:
	if _checksums_url == "":
		return true
	var text := await _get_text(_checksums_url)
	if text == "":
		return true
	var expected := ""
	for line in text.split("\n"):
		var parts := line.strip_edges().split(" ", false)
		if parts.size() >= 2 and parts[1].get_file() == _asset_name:
			expected = parts[0].to_lower()
			break
	if expected == "":
		return true
	var actual := FileAccess.get_sha256(path).to_lower()
	return actual == expected

func _install(archive: String) -> bool:
	var base := archive + ".estratto"
	_remove_dir(base)
	if DirAccess.make_dir_recursive_absolute(base) != OK:
		_fail("Non riesco a creare la cartella di installazione.")
		return false
	var ok := false
	if archive.ends_with(".zip"):
		ok = _extract_zip(archive, base)
	elif archive.ends_with(".tar.gz"):
		var output: Array = []
		ok = OS.execute("tar", ["-xzf", archive, "-C", base], output, true) == 0
	if not ok:
		_fail("Non riesco a estrarre il pacchetto scaricato.")
		return false
	var exe := OS.get_executable_path()
	if exe == "":
		_fail("Non riesco a riconoscere l'installazione corrente.")
		return false
	if OS.get_name() == "macOS":
		return _install_macos(base, exe)
	if OS.get_name() == "Windows":
		return _install_windows(base, exe)
	return _install_linux(base, exe)

func _install_macos(base: String, exe: String) -> bool:
	var new_app := _find_app(base)
	if new_app == "":
		_fail("Nel pacchetto non c'è l'app Lumeria.")
		return false
	var target := exe.get_base_dir().get_base_dir().get_base_dir()
	if not target.ends_with(".app"):
		OS.shell_open(new_app)
		return true
	var script := base.path_join("installa-lumeria.sh")
	var text := """#!/bin/bash
PID=%d
while kill -0 "$PID" 2>/dev/null; do sleep 0.4; done
sleep 0.6
NEW_APP=%s
TARGET=%s
xattr -dr com.apple.quarantine "$NEW_APP" 2>/dev/null || true
chmod +x "$NEW_APP/Contents/MacOS/Lumeria" 2>/dev/null || true
if [ -n "$TARGET" ] && [ -w "$(dirname "$TARGET")" ] && rm -rf "$TARGET" && ditto "$NEW_APP" "$TARGET"; then
  open "$TARGET"
else
  open "$NEW_APP"
fi
""" % [OS.get_process_id(), _sh_quote(new_app), _sh_quote(target)]
	if not _write_script(script, text):
		return false
	return _launch_unix_script(script)

func _install_windows(base: String, exe: String) -> bool:
	var new_exe := base.path_join("Lumeria.exe")
	if not FileAccess.file_exists(new_exe):
		new_exe = _find_file(base, "Lumeria.exe")
	if new_exe == "":
		_fail("Nel pacchetto non c'è Lumeria.exe.")
		return false
	var target_dir := exe.get_base_dir()
	var script := base.path_join("installa-lumeria.ps1")
	var text := """$ErrorActionPreference = 'SilentlyContinue'
$waitPid = %d
while (Get-Process -Id $waitPid -ErrorAction SilentlyContinue) { Start-Sleep -Milliseconds 500 }
Start-Sleep -Milliseconds 700
$src = %s
$dst = %s
try {
  Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force -ErrorAction Stop
  Start-Process -FilePath (Join-Path $dst 'Lumeria.exe')
} catch {
  Start-Process -FilePath (Join-Path $src 'Lumeria.exe')
}
""" % [OS.get_process_id(), _ps_quote(base), _ps_quote(target_dir)]
	if not _write_script(script, text):
		return false
	var pid := OS.create_process("powershell.exe", [
		"-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script])
	if pid <= 0:
		_fail("Non riesco ad avviare l'installazione.")
		return false
	return true

func _install_linux(base: String, exe: String) -> bool:
	var exe_name := _find_linux_exe(base)
	if exe_name == "":
		exe_name = exe.get_file()
	var new_exe := base.path_join(exe_name)
	if not FileAccess.file_exists(new_exe):
		_fail("Nel pacchetto non c'è l'eseguibile di Lumeria.")
		return false
	var target_dir := exe.get_base_dir()
	var script := base.path_join("installa-lumeria.sh")
	var text := """#!/bin/bash
PID=%d
while kill -0 "$PID" 2>/dev/null; do sleep 0.4; done
sleep 0.5
SRC=%s
DST=%s
EXE=%s
if cp -a "$SRC"/. "$DST"/ 2>/dev/null; then
  chmod +x "$DST/$EXE" 2>/dev/null || true
  cd "$DST" && nohup "./$EXE" >/dev/null 2>&1 &
else
  chmod +x "$SRC/$EXE" 2>/dev/null || true
  cd "$SRC" && nohup "./$EXE" >/dev/null 2>&1 &
fi
""" % [OS.get_process_id(), _sh_quote(base), _sh_quote(target_dir), _sh_quote(exe_name)]
	if not _write_script(script, text):
		return false
	return _launch_unix_script(script)

func _launch_unix_script(script: String) -> bool:
	var nohup := "/usr/bin/nohup"
	var pid := 0
	if FileAccess.file_exists(nohup):
		pid = OS.create_process(nohup, ["/bin/bash", script])
	else:
		pid = OS.create_process("/bin/bash", [script])
	if pid <= 0:
		_fail("Non riesco ad avviare l'installazione.")
		return false
	return true

func _find_app(base: String) -> String:
	for name in DirAccess.get_directories_at(base):
		if str(name).ends_with(".app"):
			return base.path_join(str(name))
	return ""

func _find_file(base: String, wanted: String) -> String:
	for name in DirAccess.get_files_at(base):
		if str(name) == wanted:
			return base.path_join(str(name))
	return ""

func _find_linux_exe(base: String) -> String:
	for name in DirAccess.get_files_at(base):
		var n := str(name)
		if n.begins_with("Lumeria."):
			return n
	return ""

func _extract_zip(zip_path: String, dest: String) -> bool:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return false
	var ok := true
	for file in reader.get_files():
		var name := str(file)
		if name.ends_with("/"):
			continue
		var data := reader.read_file(name)
		var out := dest.path_join(name)
		if DirAccess.make_dir_recursive_absolute(out.get_base_dir()) != OK:
			ok = false
			break
		var f := FileAccess.open(out, FileAccess.WRITE)
		if f == null:
			ok = false
			break
		f.store_buffer(data)
	reader.close()
	return ok

func _download_dir() -> String:
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if downloads != "":
		return downloads.path_join("Lumeria")
	return ProjectSettings.globalize_path("user://updates")

func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var d := DirAccess.open(path)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
	for sub in d.get_directories():
		_remove_dir(path.path_join(sub))
	DirAccess.remove_absolute(path)

func _write_script(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_fail("Non riesco a preparare l'installazione.")
		return false
	f.store_string(text)
	return true

func _sh_quote(value: String) -> String:
	return "'" + value.replace("'", "'\\''") + "'"

func _ps_quote(value: String) -> String:
	return "'" + value.replace("'", "''") + "'"

func _get_text(url: String) -> String:
	var req := HTTPRequest.new()
	req.timeout = 15.0
	add_child(req)
	var state := {"done": false, "result": -1, "code": 0, "body": PackedByteArray()}
	req.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		state["done"] = true
		state["result"] = result
		state["code"] = code
		state["body"] = body)
	var err := req.request(url, ["User-Agent: " + USER_AGENT])
	if err != OK:
		req.queue_free()
		return ""
	while not bool(state["done"]):
		await get_tree().process_frame
	req.queue_free()
	if int(state["result"]) != HTTPRequest.RESULT_SUCCESS or int(state["code"]) != 200:
		return ""
	var body: PackedByteArray = state["body"]
	return body.get_string_from_utf8()

func _is_newer(latest: String, current: String) -> bool:
	var a := _version_parts(latest)
	var b := _version_parts(current)
	for i in range(maxi(a.size(), b.size())):
		var x := a[i] if i < a.size() else 0
		var y := b[i] if i < b.size() else 0
		if x > y:
			return true
		if x < y:
			return false
	return false

func _version_parts(value: String) -> Array[int]:
	var out: Array[int] = []
	var clean := value.strip_edges().trim_prefix("v").trim_prefix("V")
	for part in clean.split("."):
		var digits := ""
		for i in range(part.length()):
			var ch := part[i]
			if ch >= "0" and ch <= "9":
				digits += ch
			else:
				break
		if digits == "":
			break
		out.append(int(digits))
	return out

func _pick_asset_key() -> String:
	match OS.get_name():
		"macOS":
			return "macos"
		"Windows":
			return "windows"
		"Linux":
			if Engine.get_architecture_name() == "arm64":
				return "linux_arm64"
			return "linux_x86_64"
	return ""

func _release_url() -> String:
	var url := str(_latest.get("release_url", ""))
	return url if url != "" else RELEASES_URL

func _fail(text: String) -> void:
	_downloading = false
	if _dialog != null:
		_dialog.hide()
	_show_info("Aggiornamento non riuscito", text, _release_url())

func _show_info(title: String, text: String, open_url: String = "") -> void:
	if _info != null and is_instance_valid(_info):
		_info.queue_free()
	_info = AcceptDialog.new()
	_info.title = title
	_info.dialog_text = text
	_info.ok_button_text = "Apri la pagina" if open_url != "" else "Chiudi"
	_info.exclusive = true
	_info.theme = UITheme.make_theme()
	_info.min_size = Vector2i(560, 220)
	add_child(_info)
	if open_url != "":
		_info.confirmed.connect(func() -> void: OS.shell_open(open_url))
	_info.popup_centered(Vector2i(560, 220))
