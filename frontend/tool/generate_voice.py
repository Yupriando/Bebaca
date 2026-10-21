#!/usr/bin/env python3
"""
Membuat rekaman suara AI (natural, logat Indonesia) untuk lesson -> assets/voice/*.mp3
Cukup dijalankan SEKALI; hasilnya ikut di aplikasi (offline, tanpa biaya saat dipakai anak).
Tidak perlu pip install apa pun.

=== ElevenLabs (bawaan) ===
  1. Daftar di elevenlabs.io -> klik profil -> API Keys -> Create API key
     (centang izin "Text to Speech" dan "Voices: Read").
  2. Pilih suara: menu Voices -> Voice Library -> filter Language: Indonesian ->
     pilih suara yang cocok untuk anak (mis. perempuan, hangat) -> "Add to my voices".
  3. Lihat ID suaranya:   python tool/generate_voice.py --list-voices
  4. Rekam:
     PowerShell: $env:ELEVENLABS_API_KEY="sk_..."; python tool/generate_voice.py --voice <VOICE_ID>
     bash      : ELEVENLABS_API_KEY=sk_... python3 tool/generate_voice.py --voice <VOICE_ID>
  Paket gratis ElevenLabs hanya untuk non-komersial; untuk aplikasi yang dijual,
  rekam dengan paket berbayar (Starter cukup) agar boleh dipakai komersial.

=== Google Cloud TTS (alternatif) ===
  $env:GOOGLE_TTS_API_KEY="AIza..."; python tool/generate_voice.py --provider google

Opsi lain: --force (rekam ulang semua), --only "ini huruf a" (coba 1 kalimat dulu),
           --letters (rekam ulang 26 huruf tunggal saja: a, be, ce, ...).

Daftar kalimat di bawah HARUS sama dengan yang diucapkan aplikasi
(lib/features/lesson/steps/*.dart dan SpeechService.letterName).
Kalimat yang tidak punya rekaman tetap dibacakan suara bawaan perangkat.
"""
import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'voice')

# sama dengan SpeechService._letterNames (dipakai untuk NAMA FILE)
LETTER_NAMES = {
    'A': 'a', 'B': 'be', 'C': 'ce', 'D': 'de', 'E': 'e', 'F': 'ef', 'G': 'ge',
    'H': 'ha', 'I': 'i', 'J': 'je', 'K': 'ka', 'L': 'el', 'M': 'em', 'N': 'en',
    'O': 'o', 'P': 'pe', 'Q': 'ki', 'R': 'er', 'S': 'es', 'T': 'te', 'U': 'u',
    'V': 've', 'W': 'we', 'X': 'eks', 'Y': 'ye', 'Z': 'zet',
}
# kalimat per huruf (intro_step, find_step, trace_step)
TEMPLATES = ['Ini huruf {}', 'Carilah huruf {}', 'Gambarkan huruf {}']
# kalimat tetap (listen_pick_step, read_step)
FIXED = ['Huruf apa yang kamu dengar?', 'Baca huruf ini']


def clip_key(text):
    """Sama dengan SpeechService.clipKey: 'Ini huruf a' -> 'ini_huruf_a'."""
    return re.sub(r'^_+|_+$', '', re.sub(r'[^a-z0-9]+', '_', text.lower()))


def spoken(name):
    """Ejaan pelafalan Indonesia untuk nama huruf, supaya AI tidak membaca ala Inggris.
    'be' -> 'bé', 'ef' -> 'éf', 'e' -> 'é'  (huruf 'a', 'i', 'o', 'u', 'ha', 'ka', 'ki' tetap)."""
    return name.replace('e', 'é')


# Huruf tunggal ("A.") terlalu pendek: AI menebak bahasa Inggris dan membacanya "ei".
# Kalimat Indonesia ini dikirim sebagai konteks (tidak ikut diucapkan) supaya logatnya Indonesia.
LETTER_CONTEXT = 'Ayo belajar membaca bersama. Sekarang dengarkan baik-baik, ini huruf'


def phrases():
    """[(teks untuk nama file, teks yang diucapkan AI)]"""
    out = [(n, spoken(n) + '.') for n in LETTER_NAMES.values()]
    for n in LETTER_NAMES.values():
        out += [(t.format(n), t.format(spoken(n)) + '.') for t in TEMPLATES]
    return out + [(t, t if t.endswith('?') else t + '.') for t in FIXED]


def request(url, body=None, headers=None):
    req = urllib.request.Request(
        url,
        data=None if body is None else json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', **(headers or {})},
        method='GET' if body is None else 'POST',
    )
    with urllib.request.urlopen(req, timeout=60) as res:
        return res.read()


# ---------------------------------------------------------------- ElevenLabs
EL_API = 'https://api.elevenlabs.io/v1'


def el_list(key):
    data = json.loads(request(f'{EL_API}/voices', headers={'xi-api-key': key}))
    for v in data.get('voices', []):
        labels = v.get('labels') or {}
        print(f"{v['voice_id']}  {v['name']}  {labels.get('language', '')} {labels.get('gender', '')} {labels.get('accent', '')}")


def el_say(text, key, args, context=None):
    body = {
        'text': text,
        'model_id': args.model,
        'voice_settings': {
            'stability': 0.55,        # lebih tinggi = lebih tenang & konsisten
            'similarity_boost': 0.8,
            'style': 0.25,            # sedikit ekspresif, ramah anak
            'use_speaker_boost': True,
            'speed': args.rate,
        },
    }
    if 'v2_5' in args.model or 'v3' in args.model:
        body['language_code'] = 'id'  # paksa bahasa Indonesia (model yang mendukung)
    if context and 'v3' not in args.model:
        body['previous_text'] = context  # konteks bahasa, tidak ikut diucapkan
    return request(
        f'{EL_API}/text-to-speech/{args.voice}?output_format=mp3_44100_128',
        body,
        {'xi-api-key': key, 'Accept': 'audio/mpeg'},
    )


# ---------------------------------------------------------------- Google
G_API = 'https://texttospeech.googleapis.com/v1'


def g_list(key):
    data = json.loads(request(f'{G_API}/voices?languageCode=id-ID&key={key}'))
    for v in data.get('voices', []):
        print(v['name'], v.get('ssmlGender', ''))


def g_say(text, key, args, context=None):
    body = {
        'input': {'text': text},
        'voice': {'languageCode': 'id-ID', 'name': args.voice},
        'audioConfig': {'audioEncoding': 'MP3', 'speakingRate': args.rate},
    }
    try:
        data = json.loads(request(f'{G_API}/text:synthesize?key={key}', body))
    except urllib.error.HTTPError as e:
        if e.code != 400:
            raise
        body['audioConfig'].pop('speakingRate')  # sebagian suara tidak mendukung pengaturan kecepatan
        data = json.loads(request(f'{G_API}/text:synthesize?key={key}', body))
    return base64.b64decode(data['audioContent'])


PROVIDERS = {
    'elevenlabs': ('ELEVENLABS_API_KEY', el_list, el_say),
    'google': ('GOOGLE_TTS_API_KEY', g_list, g_say),
}


def main():
    sys.stdout.reconfigure(errors='replace')  # terminal Windows kadang tidak bisa menampilkan 'é'
    ap = argparse.ArgumentParser()
    ap.add_argument('--provider', choices=PROVIDERS, default='elevenlabs')
    ap.add_argument('--voice', help='ElevenLabs: voice ID | Google: mis. id-ID-Chirp3-HD-Aoede')
    ap.add_argument('--model', default='eleven_multilingual_v2', help='model ElevenLabs')
    ap.add_argument('--rate', type=float, default=0.9, help='kecepatan bicara (1.0 = normal)')
    ap.add_argument('--force', action='store_true', help='rekam ulang walau file sudah ada')
    ap.add_argument('--only', help='rekam 1 kalimat saja, mis. "ini huruf a"')
    ap.add_argument('--letters', action='store_true', help='rekam ulang 26 huruf tunggal saja')
    ap.add_argument('--list-voices', action='store_true', help='tampilkan suara yang tersedia')
    args = ap.parse_args()

    env_name, list_voices, say = PROVIDERS[args.provider]
    key = os.environ.get(env_name)
    if not key:
        sys.exit(f'Isi dulu {env_name} (lihat petunjuk di atas file ini).')
    if args.list_voices:
        return list_voices(key)
    if not args.voice:
        if args.provider != 'google':
            sys.exit('Pilih suara dulu: --voice <VOICE_ID>  (lihat --list-voices)')
        args.voice = 'id-ID-Chirp3-HD-Aoede'

    items = phrases()
    if args.only:
        items = [p for p in items if clip_key(p[0]) == clip_key(args.only)]
        if not items:
            sys.exit(f'Kalimat "{args.only}" tidak ada di daftar.')
    letter_files = set(LETTER_NAMES.values())
    if args.letters:
        items = [p for p in items if p[0] in letter_files]

    os.makedirs(OUT, exist_ok=True)
    made = skipped = 0
    for file_text, say_text in items:
        path = os.path.join(OUT, clip_key(file_text) + '.mp3')
        if os.path.exists(path) and not (args.force or args.only or args.letters):
            skipped += 1
            continue
        try:
            context = LETTER_CONTEXT if file_text in letter_files else None
            audio = say(say_text, key, args, context)
        except urllib.error.HTTPError as e:
            sys.exit(f'Gagal untuk "{say_text}": {e.code} {e.read().decode(errors="ignore")}')
        with open(path, 'wb') as f:
            f.write(audio)
        made += 1
        print('ok', os.path.basename(path), '<-', say_text)
    print(f'Selesai: {made} direkam, {skipped} sudah ada. Folder: {os.path.normpath(OUT)}')


if __name__ == '__main__':
    main()
