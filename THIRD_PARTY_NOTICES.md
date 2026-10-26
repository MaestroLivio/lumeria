# Licenze di terze parti

## Voci neurali — teacher-in-the-loop / Kokoro-82M

La banca vocale in `assets/voices/` è stata generata con **teacher-in-the-loop**
di MithrilMan, un insieme di voci distillate da **Kokoro-82M**.

- Progetto: https://huggingface.co/MithrilMan/teacher-in-the-loop
- Codice e pesi: licenza **Apache License 2.0**
- Voci usate: `if_sara` e `im_nicola` (italiano)
- Testo della licenza: https://www.apache.org/licenses/LICENSE-2.0

Le voci sono state sintetizzate offline sui testi del gioco e convertite in OGG.
Il gioco non include il modello ONNX né esegue sintesi a runtime: riproduce solo
i frammenti audio pre-registrati.

## Kokoro-82M

Kokoro-82M è distribuito con licenza Apache License 2.0.

- Progetto: https://huggingface.co/hexgrad/Kokoro-82M
- Testo della licenza: https://www.apache.org/licenses/LICENSE-2.0

## Godot Engine

Il gioco è realizzato con **Godot Engine 4.7.2**, distribuito con licenza MIT.

- Progetto: https://godotengine.org
- Testo della licenza: https://godotengine.org/license

## Modelli 3D

I modelli `.glb` in `assets/models/` sono generati proceduralmente con Blender
per questo progetto e non contengono asset di terze parti.
