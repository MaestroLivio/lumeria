extends Node
## Audio procedurale e voice bank neurale pre-registrata.
## I file in assets/voices/<ruolo>/<sha256>.ogg sono inclusi nell'app: il gioco
## parla offline su macOS, Windows, Linux e ChromeOS, senza dipendere dalla
## sintesi vocale del sistema e senza voci con licenze non libere.
##
## Le voci sono quelle di "teacher-in-the-loop" (distillati di Kokoro-82M,
## licenza Apache-2.0): if_sara e im_nicola. Il timbro di ogni personaggio
## nasce da voce, tono e velocità, applicati una volta per tutte al momento
## della generazione della banca (tools/gen_voice_bank.py).

signal subtitle(text: String, seconds: float)

const SAMPLE_RATE := 22050
const MUSIC_LEN := 16.0

## Voce di base per ogni personaggio: le due voci italiane libere.
const ROLE_VOICE_NAME := {
	"narrator": "sara",
	"lino": "sara", "ora": "nicola", "pina": "sara", "tiko": "nicola",
	"fero": "sara", "milla": "nicola", "eco": "sara", "sila": "nicola",
	"bibi": "sara", "astra": "nicola",
	"uccello": "sara", "coniglio": "nicola", "gatto": "sara",
	"tarta": "nicola", "volpe": "sara", "riccio": "nicola",
	"amico1": "sara", "amico2": "nicola",
	"animale1": "sara", "animale2": "nicola", "animale3": "sara", "animale4": "nicola",
	"animale5": "sara", "animale6": "nicola", "animale7": "sara", "animale8": "nicola",
	"animale9": "sara", "animale10": "nicola",
}

## Tono e velocità per personaggio, usati dal generatore della banca:
## la stessa voce diventa un timbro riconoscibile (più acuto per gli
## uccellini, più grave per la tartaruga).
const ROLE_PITCH := {
	"narrator": 1.0,
	"lino": 1.0, "ora": 1.02, "pina": 1.14, "tiko": 1.10, "fero": 0.86,
	"milla": 0.90, "eco": 1.20, "sila": 0.82, "bibi": 1.06, "astra": 1.16,
	"uccello": 1.26, "coniglio": 1.12, "gatto": 1.18,
	"tarta": 0.80, "volpe": 1.05, "riccio": 0.88,
	"amico1": 1.08, "amico2": 1.15,
	"animale1": 1.12, "animale2": 1.26, "animale3": 1.16, "animale4": 1.05,
	"animale5": 0.88, "animale6": 0.80, "animale7": 1.12, "animale8": 1.24,
	"animale9": 1.16, "animale10": 1.05,
}

const ROLE_RATE := {
	"narrator": 0.86, "lino": 0.88, "ora": 0.9, "pina": 0.92, "tiko": 0.9,
	"fero": 0.82, "milla": 0.84, "eco": 0.94, "sila": 0.8, "bibi": 0.88,
	"astra": 0.92, "uccello": 0.96, "coniglio": 0.9, "gatto": 0.86,
	"tarta": 0.78, "volpe": 0.9, "riccio": 0.84,
	"amico1": 0.9, "amico2": 0.94,
}

## Voci pre-registrate: l'app non dipende dalla sintesi vocale del computer.
const VOICE_DIR := "res://assets/voices/"

var _music: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _voice_bank: Dictionary = {}
var _last_role := ""
var _last_text := ""
var _last_seconds := 0.0
var _region := 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 20261025
	_setup_players()
	call_deferred("_build_music")
	apply_settings()

func _setup_players() -> void:
	_music = AudioStreamPlayer.new()
	_music.name = "Musica"
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)
	_voice_player = AudioStreamPlayer.new()
	_voice_player.name = "Voce"
	_voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_voice_player)
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.name = "Sfx%d" % i
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_players.append(p)

## La banca vocale è inclusa nell'app: non serve interrogare il sistema.
## Se un testo non è in banca, restano i sottotitoli (mai una voce diversa).
func has_voice() -> bool:
	return true

## Due voci di base, molti timbri grazie a tono e velocità.
func voice_count() -> int:
	return 2

func apply_settings() -> void:
	if _music == null:
		return
	var muted := bool(Settings.get_setting("music_muted", false))
	_music.volume_db = -80.0 if muted else _linear_db(float(Settings.get_setting("audio_music", 62)))
	for p in _sfx_players:
		p.volume_db = _linear_db(float(Settings.get_setting("audio_sfx", 78)))
	if _voice_player:
		_voice_player.volume_db = _linear_db(float(Settings.get_setting("audio_voice", 88)))
	if _music.stream != null and not _music.playing and not muted:
		_music.play()

func _linear_db(value: float) -> float:
	var v := clampf(value / 100.0, 0.0, 1.0)
	if v <= 0.001:
		return -80.0
	return linear_to_db(v) - 4.0

func set_region(region: int) -> void:
	_region = region
	if _music:
		_music.pitch_scale = 0.92 + float(region % 10) * 0.013

func start_music() -> void:
	if _music and _music.stream and not _music.playing:
		_music.play()

func stop_music() -> void:
	if _music:
		_music.stop()

# ------------------------------------------------------------------ voce

func say(text: String, interrupt: bool = true, delay: float = 0.0) -> void:
	_speak(text, "narrator", interrupt, delay)

## Legge un testo con la voce di un personaggio specifico (custode o amico).
func say_as(role: String, text: String, interrupt: bool = true, delay: float = 0.0) -> void:
	_speak(text, role.to_lower(), interrupt, delay)

## Restituisce il file pre-registrato per quel ruolo e testo, se esiste.
## I file sono raggruppati per ruolo e nominati con l'impronta del testo.
func _bank_stream(role: String, text: String) -> AudioStream:
	var key := "%s|%s" % [role, text]
	if _voice_bank.has(key):
		return _voice_bank[key]
	var stream: AudioStream = null
	var paths: Array[String] = []
	if role != "narrator":
		paths.append("%s%s/%s.ogg" % [VOICE_DIR, role, text.sha256_text()])
	paths.append("%snarrator/%s.ogg" % [VOICE_DIR, text.sha256_text()])
	for path in paths:
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is AudioStream:
				stream = res
				break
	_voice_bank[key] = stream
	return stream

func _speak(text: String, role: String, interrupt: bool, delay: float) -> void:
	text = text.strip_edges()
	if text == "":
		return
	_last_text = text
	_last_role = role
	_last_seconds = _estimate_seconds(text)
	if delay > 0.0:
		await get_tree().create_timer(delay, true).timeout
	var vol := float(Settings.get_setting("audio_voice", 88))
	if interrupt:
		_stop_all_voice()
	# Unica fonte: la voce registrata e inclusa nell'app. Se manca, restano
	# i sottotitoli: nessuna voce di sistema, nessuna licenza da verificare.
	var bank: AudioStream = _bank_stream(role, text) if vol > 0.5 else null
	if bank != null:
		_last_seconds = maxf(1.2, bank.get_length())
		subtitle.emit(text, _last_seconds)
		_voice_player.stream = bank
		_voice_player.volume_db = _linear_db(vol)
		_voice_player.play()
		return
	subtitle.emit(text, _last_seconds)

func _stop_all_voice() -> void:
	if _voice_player and _voice_player.playing:
		_voice_player.stop()

func repeat_last() -> void:
	if _last_text == "":
		say("Ascoltiamo di nuovo insieme.", true)
		return
	if _last_role != "" and _last_role != "narrator":
		say_as(_last_role, _last_text, true)
	else:
		say(_last_text, true)

func stop_voice() -> void:
	_stop_all_voice()

func _estimate_seconds(text: String) -> float:
	var words := text.split(" ", false).size()
	return clampf(1.6 + float(words) * 0.44, 2.2, 14.0)

# ------------------------------------------------------------------ incidentali

func play_sfx(n: String, pitch: float = 1.0) -> void:
	if n == "":
		return
	var stream: AudioStream = _sfx_cache.get(n, null)
	if stream == null:
		stream = _make_sfx(n)
		if stream == null:
			return
		_sfx_cache[n] = stream
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.play()
			return
	_sfx_players[0].stream = stream
	_sfx_players[0].pitch_scale = pitch
	_sfx_players[0].play()

func play_note(index: int) -> void:
	var scale: Array[float] = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25]
	var f: float = scale[posmod(index, scale.size())]
	var key := "note_%d" % posmod(index, scale.size())
	if not _sfx_cache.has(key):
		_sfx_cache[key] = _tone_stream(f, f, 0.55, 0.5, 0.25)
	play_sfx(key)

func _make_sfx(n: String) -> AudioStream:
	match n:
		"pickup":
			return _chirp_stream([660.0, 880.0], 0.16, 0.55)
		"place":
			return _tone_stream(190.0, 140.0, 0.16, 0.55, 0.5)
		"correct":
			return _chirp_stream([523.25, 659.25, 783.99], 0.22, 0.5)
		"error":
			return _chirp_stream([392.0, 329.63, 261.63], 0.18, 0.32)
		"success":
			return _chirp_stream([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.2, 0.6)
		"fanfare":
			return _fanfare_stream()
		"click":
			return _tone_stream(760.0, 720.0, 0.055, 0.35, 0.15)
		"back":
			return _tone_stream(360.0, 300.0, 0.09, 0.3, 0.2)
		"firefly":
			return _chirp_stream([1046.5, 1318.5, 1568.0], 0.11, 0.4)
		"rune":
			return _chirp_stream([392.0, 523.25, 659.25, 880.0], 0.16, 0.55)
		"heart":
			return _chirp_stream([880.0, 1046.5], 0.12, 0.3)
		"stone":
			return _chirp_stream([659.25, 783.99, 987.77], 0.14, 0.4)
		"teleport":
			return _sweep_stream(220.0, 1320.0, 0.55, 0.35)
		"tick":
			return _tone_stream(880.0, 880.0, 0.03, 0.15, 0.2)
	return _tone_stream(440.0, 440.0, 0.1, 0.3, 0.2)

# ------------------------------------------------------------------ sintesi

func _silence(samples: int) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(samples)
	return a

func _append_note(buf: PackedFloat32Array, freq: float, dur: float, amp: float, wave: float = 0.0) -> void:
	var n := int(dur * SAMPLE_RATE)
	var start := buf.size()
	buf.resize(start + n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := minf(1.0, t / 0.012) * exp(-t * 3.4)
		var s := sin(TAU * freq * t)
		if wave > 0.0:
			s = lerpf(s, signf(s) * 0.7, wave)
		buf[start + i] = buf[start + i] + s * env * amp

func _chirp_stream(freqs: Array, dur_each: float, amp: float) -> AudioStreamWAV:
	var total := int(dur_each * float(freqs.size() + 1) * SAMPLE_RATE)
	var buf := _silence(total)
	var offset := 0
	for f in freqs:
		var n := int(dur_each * SAMPLE_RATE)
		for i in range(n):
			var t := float(i) / float(SAMPLE_RATE)
			var env := minf(1.0, t / 0.01) * exp(-t * 4.0)
			var s := sin(TAU * float(f) * t) * env * amp
			if offset + i < buf.size():
				buf[offset + i] += s
		offset += int(dur_each * 0.72 * SAMPLE_RATE)
	return _to_wav(buf)

## Fanfara di vittoria: arpeggio rapido e accordo che tiene, per festeggiare
## ogni pietra appena accesa.
func _fanfare_stream() -> AudioStreamWAV:
	var buf := _silence(int(1.6 * SAMPLE_RATE))
	for f in [523.25, 659.25, 783.99]:
		_add_note(buf, float(f), 0.0, 0.34, 0.22, 5.0)
	for f in [523.25, 659.25, 783.99, 1046.50]:
		_add_note(buf, float(f), 0.26, 1.15, 0.15, 2.0)
	_add_note(buf, 1567.98, 0.26, 0.85, 0.09, 2.6)
	return _to_wav(buf)

## Aggiunge una nota a un buffer già allocato. Lavorare nota per nota evita di
## ripassare ogni campione per ogni accordo: la colonna sonora si genera in
## un attimo senza bloccare l'avvio.
func _add_note(buf: PackedFloat32Array, freq: float, start: float, dur: float, amp: float,
		decay: float = 6.0, wave: float = 0.0) -> void:
	var first := maxi(0, int(start * SAMPLE_RATE))
	var count := int(dur * SAMPLE_RATE)
	var limit := mini(buf.size(), first + count)
	for i in range(first, limit):
		var t := float(i - first) / float(SAMPLE_RATE)
		var env := minf(1.0, t / 0.010) * exp(-t * decay)
		env *= clampf((dur - t) / 0.06, 0.0, 1.0)
		var s := sin(TAU * freq * t)
		if wave > 0.0:
			s = lerpf(s, sin(TAU * freq * 2.0 * t) * 0.35 + s * 0.65, wave)
		buf[i] += s * env * amp

## Breve fruscio ritmico: dà il passo alla musica senza strumenti campionati.
func _add_noise(buf: PackedFloat32Array, start: float, dur: float, amp: float) -> void:
	var first := maxi(0, int(start * SAMPLE_RATE))
	var count := int(dur * SAMPLE_RATE)
	var limit := mini(buf.size(), first + count)
	for i in range(first, limit):
		var t := float(i - first) / float(SAMPLE_RATE)
		var env := exp(-t * 58.0) * minf(1.0, t / 0.004)
		buf[i] += _rng.randf_range(-1.0, 1.0) * env * amp

func _tone_stream(f0: float, f1: float, dur: float, amp: float, decay: float) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var buf := _silence(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var k := t / maxf(dur, 0.001)
		var f := lerpf(f0, f1, k)
		var env := minf(1.0, t / 0.008) * exp(-t * (2.0 + decay * 8.0))
		buf[i] = sin(TAU * f * t) * env * amp
	return _to_wav(buf)

func _sweep_stream(f0: float, f1: float, dur: float, amp: float) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var buf := _silence(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var k := t / dur
		var f := lerpf(f0, f1, k * k)
		phase += TAU * f / float(SAMPLE_RATE)
		var env := sin(PI * k) * amp
		buf[i] = sin(phase) * env
	return _to_wav(buf)

func _to_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in range(buf.size()):
		var v := int(clampf(buf[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SAMPLE_RATE
	w.stereo = false
	w.data = bytes
	return w

func _build_music() -> void:
	if _music == null:
		return
	var stream := _make_music()
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(MUSIC_LEN * SAMPLE_RATE)
	_music.stream = stream
	apply_settings()
	if not bool(Settings.get_setting("music_muted", false)):
		_music.play()

## Colonna sonora di sedici secondi: otto battute a 120 BPM, giro luminoso
## Do–Sol–Lam–Fa, basso che saltella, arpeggio di ottavi, melodia pentatonica e
## un fruscio leggero sui tempi deboli. Allegra, ma senza mai coprire la voce.
func _make_music() -> AudioStreamWAV:
	var n := int(MUSIC_LEN * SAMPLE_RATE)
	var buf := _silence(n)
	var bar := MUSIC_LEN / 8.0
	var beat := bar * 0.25
	var chord_of: Array[int] = [0, 1, 2, 3, 0, 1, 3, 1]
	var chords: Array = [
		[261.63, 329.63, 392.00, 523.25],  # Do
		[246.94, 293.66, 392.00, 493.88],  # Sol
		[220.00, 261.63, 329.63, 440.00],  # La minore
		[174.61, 220.00, 261.63, 349.23],  # Fa
	]
	var bass_roots: Array[float] = [130.81, 98.00, 110.00, 87.31]
	var arp_order: Array[int] = [0, 1, 2, 3, 2, 1, 2, 3]
	# Melodia di quattro battute, ripetuta: una nota per tempo, -1 = pausa.
	var melody: Array[int] = [
		0, 2, 4, -1, 3, 2, 0, -1,
		2, 4, 5, 4, 2, 0, 2, -1,
		0, 2, 4, 5, 4, 2, 3, 2,
		0, -1, 1, 0, -1, -1, -1, -1,
	]
	var scale_n: Array[float] = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50]
	for b in range(8):
		var ci: int = chord_of[b]
		var chord: Array = chords[ci]
		var start := float(b) * bar
		# Accordo breve in levare: dà colore senza impastare il resto.
		for k in range(3):
			_add_note(buf, float(chord[k]) * 2.0, start, 0.50, 0.032, 4.6)
		# Basso saltellante: fondamentale, poi quinta.
		_add_note(buf, float(bass_roots[ci]), start, 0.32, 0.13, 6.0)
		_add_note(buf, float(bass_roots[ci]), start + beat * 2.0, 0.30, 0.10, 6.5)
		_add_note(buf, float(bass_roots[ci]) * 1.5, start + beat * 3.0, 0.20, 0.075, 8.0)
		# Arpeggio di ottavi: il motore ritmico del brano.
		for k in range(8):
			var af: float = float(chord[arp_order[k]]) * 2.0
			_add_note(buf, af, start + beat * 0.5 * float(k), 0.22, 0.042, 9.0, 0.35)
		# Controcanto acuto, molto leggero.
		for k in range(4):
			var hf: float = float(chord[(k + 2) % 4]) * 4.0
			_add_note(buf, hf, start + beat * float(k) + beat * 0.5, 0.16, 0.020, 12.0)
		# Melodia.
		for k in range(4):
			var mi: int = melody[(b * 4 + k) % melody.size()]
			if mi >= 0:
				_add_note(buf, scale_n[mi], start + beat * float(k), 0.40, 0.065, 3.2, 0.25)
		# Fruscio sui tempi deboli.
		for k in range(2):
			_add_noise(buf, start + beat * (0.5 + float(k) * 2.0), 0.05, 0.016)
	# dissolvenza di 0.8 s ai bordi per un loop pulito
	var fade := int(0.8 * SAMPLE_RATE)
	for i in range(fade):
		var k := float(i) / float(fade)
		buf[i] *= k
		buf[n - 1 - i] *= k
	# riverbero semplice a ritardo
	var delay := int(0.23 * SAMPLE_RATE)
	for i in range(delay, n):
		buf[i] += buf[i - delay] * 0.16
	# Livello uniforme: la musica si sente senza dover alzare il volume, ma
	# resta sotto la voce narrante.
	var peak := 0.0
	for i in range(n):
		peak = maxf(peak, absf(buf[i]))
	if peak > 0.0001:
		var k2 := 0.32 / peak
		for i in range(n):
			buf[i] *= k2
	return _to_wav(buf)
