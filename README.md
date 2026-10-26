# Lumeria — Le cento pietre magiche del sapere

Gioco educativo 3D in italiano per bambini di **5–7 anni**. Si esplora un mondo
low-poly colorato, senza combattimenti, timer o penalità, e si risolvono **100
missioni** divise in **10 regioni**. Ogni missione accende una pietra magica; completandole
tutte si apre la **Stella delle Possibilità**.

- Motore: **Godot 4.7.2** (Forward+)
- Lingua: **italiano**
- Modalità: **offline**, nessun account, nessuna pubblicità, nessun tracciamento
- Input: **gamepad prima di tutto**, ma tastiera e mouse funzionano sempre
- Avvio: **finestra ridimensionabile 1280×720** (minimo 960×540)

## Scarica

Le build pronte per macOS, Windows, Linux e ChromeOS sono nella pagina
[Releases](https://github.com/MaestroLivio/lumeria/releases/latest).

---

## Avvio rapido

### Applicazione macOS pronta

```bash
open build/Lumeria.app
```

L'app è firmata **ad-hoc** e contiene un binario universale (Apple Silicon + Intel).
La stessa build è disponibile anche come archivio in `build/Lumeria-macOS.zip`.
Se il file viene scaricato da internet, macOS potrebbe chiedere conferma al primo
avvio: usa *Apri* dal menu contestuale oppure

```bash
xattr -dr com.apple.quarantine build/Lumeria.app
```

### Dal sorgente

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Aprire la cartella del progetto con Godot 4.7.2 e premere **F5** produce lo stesso
risultato.

---

## Comandi

### Gamepad (consigliato)

| Azione | Pulsante |
|---|---|
| Camminare | Stick sinistro / D-pad |
| Ruotare la camera | Stick destro |
| Prendere o posare un cubo | **A** |
| Aiuto | **X** |
| Ascoltare di nuovo | **Y** |
| Indietro / pausa missione | **B** |
| Pausa | **START** |
| Diario | **BACK** |
| Cambiare sezione nei menu | **LB / RB** |
| Confermare nei menu | **A** |
| Tornare indietro nei menu | **B** |

I simboli dei pulsanti possono essere mostrati come Xbox, PlayStation o Nintendo
in *Impostazioni → Comandi*.

Nelle missioni il personaggio **cammina liberamente** sul tavolo e sul banco:
avvicinati a una cassa e premi **A** per prenderla, poi avvicinati alla pedana
e premi **A** per posarla. **B** rimette la cassa al banco; se non hai nulla in
mano, apre l'uscita dalla missione.

### Tastiera e mouse

| Azione | Tasto |
|---|---|
| Camminare | **WASD** o frecce |
| Ruotare la camera | trascinare con il tasto sinistro del mouse |
| Prendere o posare | **E**, **Invio** o **Spazio** |
| Aiuto | **H** |
| Ascoltare | **Tab** o **L** |
| Zoom camera | **+ / -** |
| Pausa | **P** o **Esc** |
| Diario | **J** |
| Cambiare sezione nei menu | **Q / R** |

La camera non cattura il puntatore: il mouse resta sempre visibile e la finestra
può essere ridimensionata o spostata in qualsiasi momento.

---

## Il gioco

### Hub e mondo

Si parte dalla fontana dell'**Hub di Lumeria**. Le dieci regioni sono sempre
aperte e raggiungibili a piedi; la mappa permette anche il viaggio rapido.

| # | Regione | Custode | Ambito |
|---|---|---|---|
| 1 | Bosco delle Somiglianze | Lino | forme, colori, raggruppamenti |
| 2 | Sentieri del Vento | Ora | posizioni, direzioni, sequenze |
| 3 | Giardino delle Quantità | Pina | numeri 0–10, conteggio |
| 4 | Ferrovia delle Serie | Tiko | ordine, pattern, successioni |
| 5 | Officina delle Stelle | Fero | addizioni e sottrazioni entro 10 |
| 6 | Valle delle Misure | Milla | lunghezze, confronti, misure |
| 7 | Biblioteca dei Suoni | Eco | suoni, ritmo, associazione simbolo |
| 8 | Mulino delle Sillabe | Sila | sillabe e parole |
| 9 | Città delle Parole | Bibi | lettere, rime, categorie |
| 10 | Torre delle Cento Luci | Astra | missioni composite e finali |

Ogni regione ha dieci stazioni-missione. La missione 100 è il finale narrativo
multidominio. Le missioni già risolte possono essere rigiocate liberamente.

I **28 abitanti** di Lumeria animano il mondo: i dieci **custodi** (uno per
regione), dieci **amici animali** che accompagnano le rispettive radure e otto
**amici dell'Hub** (sei animali e due bambini). Vagano, si fermano a guardarti e
saltano quando salutano. Il mondo è più ampio e arioso: tra l'Hub e le regioni si
attraversa prato aperto, e dentro ogni radura le dieci postazioni sono
distanziate per camminare comodamente anche correndo. I **cartelli** sono fissi,
stampati su entrambe le facciate e leggibili sia arrivando sia tornando
indietro; una luce calda li accende man mano che ti avvicini. Festoni colorati e
palloncini rendono la piazza festosa.

### Tipi di attività

Le missioni usano incastri, cubi con numeri, lettere, sillabe, forme, corde,
colori e piccoli percorsi. Il gioco non richiede di saper leggere: ogni consegna
importante è **ascoltabile** e accompagnata da icone. Non esistono risposte
sbagliate punite: si può sempre riprovare, e l'aiuto è sempre disponibile.

Alcune missioni aggiungono una **vetrina laterale** con gli oggetti da contare
(fino a 29 icone) oppure una **mappa del percorso** con partenza, meta e celle
bloccate. Gli incastri dei percorsi ricevono automaticamente i numeri dei passi.

Le risposte non restano nell'ordine in cui sono state scritte: i **cubi del
banco** vengono mescolati per ogni missione (con un ordine stabile per quella
missione), così non si può indovinare per posizione. Quando prendi un cubo, una
**anteprima 3D** lo mostra in basso a destra, illuminato da un raggio e da raggi
dorati, mentre gira lentamente: sai sempre che cosa hai in mano mentre scegli
l'incastro.

Nelle missioni si **cammina liberamente** sul tavolo, sulla passerella e sul
banco delle casse, con lo stick sinistro, il D-pad o WASD. È sempre il
**personaggio** a prendere le casse e a posarle: avvicinati a una cassa e premi
**A** per prenderla, portala vicino alla pedana e premi **A** per posarla.
Anche il ripensamento è un gesto: **B** riporta il personaggio al banco e
rimette la cassa dove l'aveva presa.

Le **lunghezze** non sono più due piastre uguali: corde, nastri e travi sono
barre disegnate in proporzione, con una **tacca per ogni unità** e le estremità
arrotondate. Una corda da 6 unità è davvero tre volte una corda da 2. Le
**altezze** usano torri a blocchi sovrapposti, con una riga chiara tra un blocco
e l'altro e un'asta graduata accanto: si contano a vista, senza leggere numeri.
Anche i funghi delle seriazioni cambiano solo in altezza, non in larghezza.

### Progressi

- 100 pietre magiche, 10 per regione
- lucciole, creature e pietre musicali incontrate nel mondo
- salvataggio locale automatico in `user://lumeria_save.json`
- nessun nome, nessun profilo, nessun dato inviato in rete

---

## Impostazioni

Il menu **Impostazioni** è completo e navigabile solo con il gamepad.

- **Audio** — musica, effetti, voce narrante, mute, prova voce e prova suoni
- **Video** — finestra / senza bordi / schermo intero, risoluzione, VSync,
  **intensità del bagliore** (0–150%, predefinita al 55%), qualità Essenziale /
  Bilanciata / Massima
- **Accessibilità** — dimensione del testo, sottotitoli, alto contrasto,
  riduzione del movimento, niente flash, contorni spessi, frequenza degli aiuti,
  modalità guidata; la camera facilitata si attiva da **Camera**
- **Camera** — sensibilità, inseguimento o orbita, inversione asse Y,
  ricentraggio dolce, **camera facilitata** nelle missioni (attiva di default:
  segue dolcemente il personaggio dopo il primo passo, mantenendo il tavolo
  inquadrato)
- **Comandi** — zona morta, vibrazione, solo D-pad, simboli del controller,
  test interattivo del gamepad
- **Gioco** — percorso suggerito, modalità classe, tutorial, azzeramento
  progressi con doppia conferma
- **Docente** — riepilogo locale, esportazione/importazione dei progressi,
  azzeramento protetto

Le modifiche si applicano subito e restano salvate sul dispositivo. Il pulsante
*Ripristina* rimette i valori iniziali senza toccare i progressi.

---

## Accessibilità e privacy

- Nessun testo obbligatorio per giocare: voce, icone, colori e forme.
- La voce è **pre-registrata e inclusa nell'app**: una banca di frammenti
  neurali in `assets/voices/` (1.367 frammenti, circa un'ora e mezza di parlato). Il gioco parla anche
  su un computer senza voci di sistema installate e non usa la sintesi vocale
  del sistema operativo.
- Le voci sono **teacher-in-the-loop** (distillati di Kokoro-82M, licenza
  **Apache-2.0**): le due voci italiane `if_sara` e `im_nicola`. I personaggi si
  distinguono per **voce, tono e velocità**, applicati alla generazione della
  banca. Se un testo non è in banca, restano i sottotitoli: non viene mai usata
  una voce diversa o con licenza non libera.
- Alto contrasto, testo ingrandibile, contorni spessi, riduzione del movimento,
  niente flash.
- Aiuti senza penalità e senza limite di tentativi.
- Nessuna connessione, nessun account, nessuna telemetria, nessuna pubblicità.
- I dati restano in `~/Library/Application Support/Godot/app_userdata/Lumeria/`
  (versione editor) o nella cartella dati dell'app esportata.

---

## Struttura del progetto

```
scenes/main.tscn                 scena di avvio (unica scena scritta a mano)
scripts/main.gd                  orchestrazione, viaggio rapido, modalità test
scripts/core/                    impostazioni, salvataggio, audio e voce
scripts/data/mission_data.gd     catalogo completo delle 100 missioni
scripts/missions/                tavolo 3D, cubi, incastri, valutatore
scripts/world/                   mondo, giocatore, camera, stazioni, avatar, custodi
scripts/world/npc.gd            28 personaggi che vagano e salutano (voci per ruolo)
scripts/ui/                      menu, HUD, mappa, diario, guardaroba, docente
assets/models/                   14 modelli low-poly .glb generati con Blender
assets/voices/                   banca voci neurali pre-registrate (OGG, per ruolo)
assets/shaders/                  prato procedurale e ombra di contatto
tools/blender_assets.py          generatore headless dei modelli Blender
tools/gen_voice_bank.py          generatore della banca voci (Kokoro distillato)
tools/dump_voice_texts.gd        esporta i testi delle missioni per la banca voci
tests/validate_catalog.gd        test headless di catalogo e valutatore
tests/mission_layout.gd          layout del tavolo: 100 missioni, zero sovrapposizioni
tests/voice_bank.gd              voice bank: OGG importati, caricabili e trovati dal lookup
tests/mission_shots.gd           catture prima/dopo di singole missioni
tests/asset_gallery.gd           galleria di controllo dei modelli .glb
tests/avatar_portrait.gd         ritratti di controllo dell'avatar (viso, schiena)
screenshots/                     catture di verifica (23 immagini)
export_presets.cfg               preset macOS, Windows, Linux x86_64/ARM64
THIRD_PARTY_NOTICES.md           licenze di voci, Kokoro, Godot e modelli
build/Lumeria.app                applicazione esportata
```

Il mondo, le icone SVG, i materiali e i suoni sono generati a runtime; alberi,
casette, fontana, lanterne, panche, pozzo, casse e barili sono modelli low-poly
`.glb` prodotti con Blender e caricati da `ModelLibrary`. Il prato usa uno shader
procedurale in coordinate mondo e i fiori sono disegnati con MultiMesh.

Per rigenerare i modelli (Blender 5.2 o successivo):

```bash
/Applications/Blender.app/Contents/MacOS/Blender -b --python tools/blender_assets.py
```

Gli asset hanno l'origine a terra e la facciata verso **-Z** (il forward di
Godot). Dopo la generazione va rilanciato l'import dell'editor:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import
```

---

## Test e verifiche

Eseguiti su macOS con Godot 4.7.2.

```bash
# Catalogo: 100 missioni, struttura dati, soluzione di ogni missione
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script tests/validate_catalog.gd
# → Missioni caricate: 100 · risolte 100/100 · TEST OK

# Avvio, mondo, stazioni, apertura missione
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -- --smoke
# → SMOKE stations=100 specials=4 missions=100 · SMOKE OK

# 100 missioni aperte e risolte con le interazioni reali della scena
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -- --selftest
# → SELFTEST risolte=100 finale=true stazioni=100 · SELFTEST OK

# Tavolo: cubi dentro il proprio incastro, senza sovrapposizioni né fuori piastra
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script tests/mission_layout.gd
# → LAYOUT missioni=100 problemi=0 · LAYOUT OK

# Voice bank: 1.367 OGG importati, caricabili e trovati dal lookup
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script tests/voice_bank.gd
# → VOICEBANK files=1367 loaded=1367 · missioni=1682 mancanti=0 · VOICEBANK OK
```

Per rigenerare le catture (23 immagini in `screenshots/`):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --shots
```

La modalità `--shots` verifica anche il layout a 960×540 e salva in
`~/Library/Application Support/Godot/app_userdata/Lumeria/screenshots/`.

Per iterare sulla grafica senza rifare tutte le catture:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --quickshot
```

Salva menu, mondo, guardaroba, regione, missione, vittoria e camminata
(`q_*.png`) nella stessa cartella. Per controllare i modelli uno accanto
all'altro:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/asset_gallery.gd
```

Per controllare l'avatar senza interfaccia attorno:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/avatar_portrait.gd
```

Per vedere una missione specifica prima e dopo la soluzione:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . \
  --script tests/mission_shots.gd -- 001 009 097
```

All'uscita Godot può stampare un avviso `ObjectDB instances were leaked`: sono
risorse RefCounted ancora vive durante la chiusura del processo, non un errore
di gioco e non influiscono sul salvataggio.

### Rigenerare la banca vocale

Dopo aver modificato i testi delle missioni:

```bash
# 1. esporta i testi dal catalogo
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script tools/dump_voice_texts.gd
# 2. sintetizza le voci (serve Python 3.10–3.12, ffmpeg e oggenc)
#    crea un ambiente dedicato, per esempio:
#    uv venv --python 3.12 .venv-titl
#    uv pip install --python .venv-titl/bin/python teacher-in-the-loop
.venv-titl/bin/python tools/gen_voice_bank.py --jobs 6
# 3. reimporta gli OGG in Godot
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
```

Lo script elimina i frammenti non più usati, quindi la banca resta allineata ai
testi. Le voci sono `if_sara` e `im_nicola` di teacher-in-the-loop (Kokoro
distillato, Apache-2.0): vedi `THIRD_PARTY_NOTICES.md`.

---

## Distribuzioni

I preset sono pronti in `export_presets.cfg` per **macOS**, **Windows**,
**Linux** (x86_64 e ARM64) e **ChromeOS** tramite l'ambiente Linux di ChromeOS
(Crostini). Ogni build include il `.pck` nel binario: una sola cartella da
copiare, senza file esterni.

```bash
# macOS universale (Apple Silicon + Intel), firma ad-hoc
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --export-release "macOS" "build/Lumeria.app"

# Windows 64-bit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --export-release "Windows" "build/windows/Lumeria.exe"

# Linux 64-bit (anche ChromeOS con Linux attivo)
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --export-release "Linux" "build/linux/Lumeria.x86_64"

# Linux ARM64 (Chromebook ARM con Linux)
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --export-release "Linux ARM64" "build/linux-arm64/Lumeria.arm64"
```

### macOS

L'app è firmata **ad-hoc** e contiene un binario universale. Se il file viene
scaricato da internet, macOS può chiedere conferma al primo avvio: usa *Apri*
dal menu contestuale oppure

```bash
xattr -dr com.apple.quarantine build/Lumeria.app
```

Per distribuire fuori dal proprio Mac serve una firma Developer ID e la
notarizzazione Apple.

### Windows

Copia la cartella `build/windows/` su un PC Windows 10/11 e avvia `Lumeria.exe`.
Non serve installare nulla. Se SmartScreen avverte che l'app non è firmata,
scegli *Ulteriori informazioni → Esegui comunque*: è un avviso standard per i
programmi senza certificato commerciale.

### Linux

Copia `build/linux/` su un PC Linux con driver Vulkan, dai i permessi e avvia:

```bash
chmod +x Lumeria.x86_64
./Lumeria.x86_64
```

Se il computer non ha Vulkan, avvia in modalità compatibile:

```bash
./Lumeria.x86_64 --rendering-method gl_compatibility --rendering-driver opengl3
```

### ChromeOS

La via più semplice è l'**ambiente Linux di ChromeOS** (Impostazioni → Informazioni
su ChromeOS → Ambiente di sviluppo Linux). Nella finestra Linux copia il
contenuto di `build/linux/`, poi:

```bash
chmod +x Lumeria.x86_64
./Lumeria.x86_64
```

Se il computer non ha Vulkan, avvia in modalità compatibile:

```bash
./Lumeria.x86_64 --rendering-method gl_compatibility --rendering-driver opengl3
```

Nella cartella `build/chromeos/` c'è anche `Lumeria.desktop`, da copiare in
`~/.local/share/applications/` per avere l'icona nel launcher Linux. Su un
Chromebook ARM usa la build `linux-arm64/`. La build Linux è la via consigliata
per ChromeOS perché non richiede lo sblocco del dispositivo.

Gli archivi distribuibili si creano con:

```bash
tools/make_distributions.sh
```

Lo script esporta tutte le piattaforme, firma il bundle macOS fuori da iCloud e
crea `Lumeria-macOS.zip`, `Lumeria-Windows.zip`, `Lumeria-Linux.tar.gz`,
`Lumeria-Linux-ARM64.tar.gz` e `Lumeria-ChromeOS.zip` in `build/`.

---

## Grafica

- Cielo procedurale con sole, foschia calda e ombre morbide a quattro split.
- Prato con shader procedurale (chiazze, fili, macchie secche) e fiori MultiMesh.
- Dieci sentieri di terra collegano l'Hub alle regioni; le radure sono delimitate
  da anelli colorati distesi a terra invece che da piattaforme piatte, e la piazza
  dell'Hub ha cornici in pietra e venti pietre magiche incassate nel selciato.
- Modelli Blender low-poly per alberi (quercia, pino, acero, betulla), cespugli,
  rocce, funghi, casette, pozzo, fontana, lanterna, panca, cassa e barile.
- Avatar procedurale rinnovato: capelli, orecchie, guance, zaino e pietra magica sul petto,
  con tre corpi e quattro copricapi. Guarda verso **-Z**: camminando mostra la
  schiena alla camera, mentre il guardaroba lo ruota per mostrare il viso.
- I **28 abitanti** (dieci custodi, dieci animali di regione, sei animali e due
  bambini nell'Hub) sono **personaggi animati** che vagano, si fermano a
  guardarti e saltellano quando salutano; i festoni e i palloncini dell'Hub
  danno un'aria di festa.
- I cartelli delle postazioni e delle regioni sono **fissi e a doppia faccia**:
  icona, codice e titolo sono stampati su entrambi i lati, con la copia
  posteriore ruotata di 180°, e si leggono senza inseguire la camera. Una luce
  progressiva li accende quando il giocatore si avvicina.
- Tavolo delle missioni con piano in legno, vetrine, mappa del percorso,
  illuminazione calda e vignettatura. Il cubo in mano appare in un
  **palcoscenico 3D** con raggio di luce, raggi dorati, alone e rotazione lenta.
- Colori sRGB convertiti in lineare: i materiali non risultano più slavati.
- Qualità Essenziale / Bilanciata / Massima regola risoluzione 3D, MSAA, ombre,
  SSAO e glow; il cambio è immediato anche a partita in corso.
- Il bagliore parte da un valore **tenue** (55%) e si regola con lo slider
  *Intensità del bagliore* in Video: da spento a 150%, applicato subito a
  materiali emissivi, lanterne, cartelli e ambiente.

## Screenshot

Le immagini in `screenshots/` coprono menu, impostazioni (1280×720 e 960×540),
mondo, regione, missioni rappresentative, vittoria, mappa, diario, guardaroba,
tutorial, finale, pausa, pannello docente, laboratorio e le missioni con vetrina
o percorso.

---

## Limitazioni note

- I testi dinamici non pre-registrati compaiono come sottotitoli: non viene mai
  usata la sintesi vocale del sistema operativo. I testi principali, le missioni,
  il diario e i personaggi sono sempre nella voice bank inclusa.
- La firma ad-hoc non sostituisce la notarizzazione per la distribuzione pubblica.
- Le catture sono a 1280×720 logici; su schermo Retina il PNG è 2560×1440
  (la `03_impostazioni_960.png` è a 960×540 logici).
- Il gioco è progettato per un singolo giocatore locale; non ci sono funzioni
  online, classifiche o sincronizzazione.
