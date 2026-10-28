#!/usr/bin/env python3
"""Genera la voice bank neurale pre-registrata di Lumeria.

Ogni file e' un OGG mono 22050 Hz nominato con lo SHA-256 del testo, dentro
assets/voices/<ruolo>/. Il gioco lo trova a runtime con ResourceLoader.exists()
e lo riproduce senza dipendere dalla sintesi vocale del sistema.

Le voci sono quelle di "teacher-in-the-loop" (distillati di Kokoro-82M,
licenza Apache-2.0): if_sara e im_nicola. Il timbro di ogni personaggio nasce
da voce, tono e velocita' (ROLE_VOICE_NAME / ROLE_PITCH / ROLE_RATE in
scripts/core/audio.gd), applicati qui una volta per tutte.

Uso:
    python tools/gen_voice_bank.py [--dry] [--jobs N]

Richiede ffmpeg e oggenc (Homebrew) per la conversione. Il modello ONNX viene
scaricato una sola volta nella cache di Hugging Face.
"""

import argparse
import concurrent.futures
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "voices")
OGGENC = "/opt/homebrew/bin/oggenc"
FFMPEG = "/opt/homebrew/bin/ffmpeg"

VOICE_FOR_ROLE = {}
PITCH = {}
RATE = {}
VOICES = {}


def read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return f.read()


def parse_const(name):
    src = read("scripts/core/audio.gd")
    block = re.search(r"const %s := \{(.*?)\n\}" % name, src, re.S)
    if not block:
        raise SystemExit("%s non trovato in audio.gd" % name)
    return block.group(1)


def parse_voice_config():
    for role, voice in re.findall(r'"([a-z0-9_]+)":\s*"([a-z]+)"', parse_const("ROLE_VOICE_NAME")):
        VOICE_FOR_ROLE[role] = voice
    for role, value in re.findall(r'"([a-z0-9_]+)":\s*([0-9.]+)', parse_const("ROLE_PITCH")):
        PITCH[role] = float(value)
    for role, value in re.findall(r'"([a-z0-9_]+)":\s*([0-9.]+)', parse_const("ROLE_RATE")):
        RATE[role] = float(value)


def unescape(s):
    return (s.replace('\\"', '"').replace("\\n", "\n")
             .replace("\\t", "\t").replace("\\\\", "\\"))


def static_say_texts():
    """Tutti i testi passati direttamente ad Audio.say("...") o say_as(..., "...")."""
    texts = set()
    pattern = re.compile(r'Audio\.(?:say|say_as)\((?:[^,()]*,)?\s*"((?:[^"\\]|\\.)*)"')
    for base, _dirs, files in os.walk(os.path.join(ROOT, "scripts")):
        for name in files:
            if not name.endswith(".gd"):
                continue
            with open(os.path.join(base, name), encoding="utf-8") as f:
                for m in pattern.finditer(f.read()):
                    text = unescape(m.group(1))
                    if "%" in text or not text.strip():
                        continue
                    texts.add(text)
    return texts


def tutorial_texts():
    src = read("scripts/ui/tutorial_page.gd")
    return set(unescape(x) for x in re.findall(r'"voice":\s*"((?:[^"\\]|\\.)*)"', src))


def npc_greetings():
    """Ritorna [(ruolo, testo)] per i personaggi del mondo."""
    src = read("scripts/world/world_builder.gd")
    out = []
    arr = re.search(r"var animals := \[(.*?)\n\t\]", src, re.S)
    if arr:
        entries = re.findall(r'\{\s*"name".*?"greeting":\s*"(.*?)"\s*\}', arr.group(1), re.S)
        for i, greeting in enumerate(entries):
            out.append(("animale%d" % (i + 1), unescape(greeting)))
    for block in re.findall(r"_spawn_npc\(\{(.*?)\}\)", src, re.S):
        voice = re.search(r'"voice":\s*"((?:[^"\\]|\\.)*)"', block)
        greeting = re.search(r'"greeting":\s*"((?:[^"\\]|\\.)*)"', block)
        if voice and greeting:
            out.append((unescape(voice.group(1)), unescape(greeting.group(1))))
    return out


def mission_texts():
    data = json.load(open(os.path.join(ROOT, "tools", "voice_texts.json"), encoding="utf-8"))
    narrator = set()
    for m in data["missions"]:
        title = m.get("title", "").strip()
        instr = m.get("instruction", "").strip()
        if title and instr:
            narrator.add("%s. %s" % (title, instr))
        if title:
            narrator.add(title)
        if instr:
            narrator.add(instr)
        for h in m.get("hints", []):
            if h.strip():
                narrator.add(h.strip())
        if m.get("success", "").strip():
            narrator.add(m["success"].strip())
        for c in m.get("cubes", []):
            if c.strip():
                narrator.add(c.strip())
        for s in m.get("sockets", []):
            if s.strip():
                narrator.add(s.strip())
                narrator.add("%s. Incastro vuoto." % s.strip())
    # Diario: una riga per regione e per numero di pietre accese.
    for i, region in enumerate(data["regions"]):
        custodian = data["custodians"][i]
        line = data["custodian_lines"][i]
        for done in range(11):
            narrator.add("%s. Custode %s. %s. Pietre magiche accese: %d su dieci." % (
                region, custodian, line, done))
    # Diario: ogni singola missione, accesa o ancora da accendere.
    for j, m in enumerate(data["missions"]):
        narrator.add("Pietra magica numero %d. %s. Accesa." % (j + 1, m.get("title", "")))
        narrator.add("Pietra magica numero %d. %s. Ancora da accendere. La trovi nel mondo." % (
            j + 1, m.get("title", "")))
    # Guardaroba: i nomi dei colori variano con l'indice.
    for i in range(1, 9):
        narrator.add("Colore %d" % i)
    return narrator


def build_jobs():
    narrator = mission_texts() | static_say_texts() | tutorial_texts()
    narrator |= {
        "Scegli prima un cubo dal banco.",
        "Questo cesto è pieno. Prendi un altro posto.",
        "Qui forse va un altro cubo. Proviamo insieme.",
        "Guarda questo cubo e questo incastro: stanno bene insieme.",
        "Qui puoi provare liberamente: nessuna soluzione, solo scoperte.",
        "Pietra magica accesa!",
    }
    jobs = {("narrator", t) for t in narrator if t.strip()}
    src = read("scripts/data/mission_data.gd")
    custodians = re.search(r"const CUSTODIANS := \[(.*?)\]", src, re.S)
    lines = re.search(r"const CUSTODIAN_LINES := \[(.*?)\]", src, re.S)
    if custodians and lines:
        cs = re.findall(r'"([^"]+)"', custodians.group(1))
        ls = re.findall(r'"((?:[^"\\]|\\.)*)"', lines.group(1))
        for c, l in zip(cs, ls):
            jobs.add((c.lower(), unescape(l)))
    for role, text in npc_greetings():
        jobs.add((role, text))
    return sorted(jobs)


def _dest_for(role, text):
    """Percorso OGG atteso per un testo, o "" se il file non esiste ancora."""
    dest = os.path.join(OUT, role, hashlib.sha256(text.encode("utf-8")).hexdigest() + ".ogg")
    return dest if os.path.exists(dest) else ""


def _init_worker():
    from titl import Voice
    for short, model in (("sara", "if_sara"), ("nicola", "im_nicola")):
        VOICES[short] = Voice.from_pretrained(model, quantized=True)


def synth(job):
    role, text = job
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
    dest_dir = os.path.join(OUT, role)
    dest = os.path.join(dest_dir, digest + ".ogg")
    os.makedirs(dest_dir, exist_ok=True)
    short = VOICE_FOR_ROLE.get(role, "sara")
    voice = VOICES.get(short)
    if voice is None:
        return ("fail", role, text)
    rate = RATE.get(role, 0.88)
    pitch = PITCH.get(role, 1.0)
    fd, wav = tempfile.mkstemp(prefix="lumeria_", suffix=".wav")
    os.close(fd)
    try:
        audio = voice(text, speed=rate)
        from titl import write_wav
        write_wav(wav, audio)
        if pitch != 1.0:
            pitched = wav + ".p.wav"
            subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-i", wav,
                            "-filter:a", "asetrate=24000*%.4f,aresample=24000,atempo=%.6f" % (
                                pitch, 1.0 / pitch), pitched],
                           check=True, capture_output=True, timeout=120)
            os.replace(pitched, wav)
        subprocess.run([OGGENC, "-q", "4", "--resample", "22050", "-o", dest, wav],
                       check=True, capture_output=True, timeout=120)
        return ("ok", role, text)
    except Exception as exc:  # noqa: BLE001 - un testo fallito non ferma la banca
        print("  FALLITO %s: %s (%s)" % (role, text[:60], exc), flush=True)
        return ("fail", role, text)
    finally:
        for p in (wav, wav + ".p.wav"):
            if os.path.exists(p):
                os.remove(p)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--missing", action="store_true",
                    help="genera solo i testi che non hanno ancora il loro OGG, senza "
                         "riscrivere i file esistenti (stessa voce, nessun ritocco al resto)")
    args = ap.parse_args()
    parse_voice_config()
    all_jobs = build_jobs()
    print("voice bank: %d testi unici" % len(all_jobs))
    jobs = all_jobs
    if args.missing:
        jobs = [j for j in all_jobs if not _dest_for(j[0], j[1])]
        print("voice bank: %d già presenti, %d da generare" % (
            len(all_jobs) - len(jobs), len(jobs)))
    counts = {}
    for role, _ in jobs:
        counts[role] = counts.get(role, 0) + 1
    for role in sorted(counts):
        print("  %-12s %4d  (%s, pitch %.2f, rate %.2f)" % (
            role, counts[role], VOICE_FOR_ROLE.get(role, "sara"),
            PITCH.get(role, 1.0), RATE.get(role, 0.88)))
    if args.dry:
        for role, text in jobs:
            print("    %-10s %s" % (role, text))
        return 0
    if not os.path.exists(OGGENC):
        raise SystemExit("oggenc non trovato: brew install vorbis-tools")
    made = 0
    failed = []
    expected = set()
    for role, text in all_jobs:
        expected.add(os.path.join(OUT, role, hashlib.sha256(text.encode("utf-8")).hexdigest() + ".ogg"))
    with concurrent.futures.ProcessPoolExecutor(
            max_workers=args.jobs, initializer=_init_worker) as pool:
        for status, role, text in pool.map(synth, jobs):
            if status == "fail":
                failed.append((role, text))
            else:
                made += 1
            if made and made % 50 == 0:
                print("  ... %d/%d" % (made + len(failed), len(jobs)), flush=True)
    # Rimuove i file di voci vecchie o di testi non più usati.
    removed = 0
    for base, _dirs, files in os.walk(OUT):
        for name in files:
            if not name.endswith(".ogg"):
                continue
            path = os.path.join(base, name)
            if path not in expected:
                os.remove(path)
                imp = path + ".import"
                if os.path.exists(imp):
                    os.remove(imp)
                removed += 1
    total = 0
    size = 0
    for base, _dirs, files in os.walk(OUT):
        for name in files:
            if name.endswith(".ogg"):
                total += 1
                size += os.path.getsize(os.path.join(base, name))
    print("voice bank: generati %d, rimossi %d, falliti %d" % (made, removed, len(failed)))
    for role, text in failed:
        print("  FALLITO %s: %s" % (role, text))
    print("voice bank: %d file OGG, %.1f MB" % (total, size / 1024 / 1024))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
