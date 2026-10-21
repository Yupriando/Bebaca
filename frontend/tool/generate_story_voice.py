#!/usr/bin/env python3
"""
Membuat narasi AI untuk "Baca Bersama" -> assets/stories/<kunci>.mp3 + <kunci>.json
(.json = waktu mulai/selesai tiap kata, supaya kata yang dibaca bisa menyala seperti karaoke).
Sekaligus merekam "Pesan dari cerita ini" & soal kuis -> assets/voice/ (dipakai SpeechService.speak).
Teks dongeng diambil langsung dari Supabase (pakai backend/.env). Tidak perlu pip install.

Jalankan dari folder frontend (suara sama dengan rekaman lesson):
  PowerShell: $env:ELEVENLABS_API_KEY="sk_..."
              python tool/generate_story_voice.py --voice <VOICE_ID> --model eleven_flash_v2_5
  Satu dongeng saja : --title "Malin Kundang"
  Rekam ulang semua : --force

Halaman yang belum punya narasi tetap dibacakan suara bawaan perangkat.
Cara memecah halaman HARUS sama dengan lib/features/stories/story_pages.dart.
"""
import argparse
import base64
import json
import os
import re
import sys
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate_voice as gv  # noqa: E402  (request() & alamat API ElevenLabs)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'assets', 'stories')
BACKEND_ENV = os.path.join(ROOT, '..', 'backend', '.env')
MAX_WORDS = 24


# ---------------------------------------------------------------- sama dengan story_pages.dart
def words_of(text):
    return re.findall(r'\S+', text)


def split_pages(content, max_words=MAX_WORDS):
    pages = []
    for p in re.split(r'\n\s*\n', content or ''):
        p = re.sub(r'\s+', ' ', p.strip())
        if not p:
            continue
        sentences = [s.strip() for s in re.findall(r'[^.!?]+(?:[.!?]+["”]?|$)\s*', p) if s.strip()]
        current = ''
        for s in sentences:
            nxt = s if not current else f'{current} {s}'
            if current and len(words_of(nxt)) > max_words:
                pages.append(current)
                current = s
            else:
                current = nxt
        if current:
            pages.append(current)
    return pages


def narration_key(text):
    h = 0x811C9DC5
    for b in text.encode('utf-8'):
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return f'st_{h:08x}'


# ---------------------------------------------------------------- Supabase
def read_env(path):
    env = {}
    if os.path.exists(path):
        for line in open(path, encoding='utf-8'):
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, v = line.split('=', 1)
                env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def fetch_stories(title=None):
    env = read_env(BACKEND_ENV)
    url, key = env.get('SUPABASE_URL'), env.get('SUPABASE_SERVICE_ROLE_KEY')
    if not url or not key:
        sys.exit(f'SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY tidak ditemukan di {os.path.normpath(BACKEND_ENV)}')
    query = 'select=title,content,moral,quiz&content=not.is.null&order=title'
    if title:
        query += '&title=eq.' + urllib.parse.quote(title)
    req = urllib.request.Request(
        f'{url}/rest/v1/stories?{query}',
        headers={'apikey': key, 'Authorization': f'Bearer {key}'},
    )
    with urllib.request.urlopen(req, timeout=30) as res:
        return json.loads(res.read())


# ---------------------------------------------------------------- ElevenLabs
def narrate(text, api_key, args):
    body = {
        'text': text,
        'model_id': args.model,
        'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.8,
            'style': 0.35,          # sedikit lebih ekspresif untuk bercerita
            'use_speaker_boost': True,
            'speed': args.rate,
        },
    }
    if 'v2_5' in args.model or 'v3' in args.model:
        body['language_code'] = 'id'
    data = json.loads(gv.request(
        f'{gv.EL_API}/text-to-speech/{args.voice}/with-timestamps?output_format=mp3_44100_128',
        body,
        {'xi-api-key': api_key},
    ))
    audio = base64.b64decode(data['audio_base64'])
    al = data.get('alignment') or data.get('normalized_alignment') or {}
    starts = al.get('character_start_times_seconds') or []
    ends = al.get('character_end_times_seconds') or []

    words = []
    for m in re.finditer(r'\S+', text):
        s = starts[m.start()] if m.start() < len(starts) else (words[-1][1] if words else 0)
        e = ends[m.end() - 1] if m.end() - 1 < len(ends) else s
        words.append([round(s, 3), round(e, 3)])
    return audio, {'text': text, 'words': words}


def main():
    sys.stdout.reconfigure(errors='replace')
    ap = argparse.ArgumentParser()
    ap.add_argument('--voice', required=True, help='voice ID ElevenLabs (lihat generate_voice.py --list-voices)')
    ap.add_argument('--model', default='eleven_flash_v2_5')
    ap.add_argument('--rate', type=float, default=0.9)
    ap.add_argument('--title', help='hanya dongeng dengan judul ini, mis. "Malin Kundang"')
    ap.add_argument('--force', action='store_true')
    args = ap.parse_args()

    api_key = os.environ.get('ELEVENLABS_API_KEY')
    if not api_key:
        sys.exit('Isi dulu ELEVENLABS_API_KEY.')

    stories = fetch_stories(args.title)
    if not stories:
        sys.exit('Tidak ada dongeng yang punya isi cerita' + (f' berjudul "{args.title}"' if args.title else '') + '.')

    os.makedirs(OUT, exist_ok=True)
    made = skipped = chars = 0
    for st in stories:
        pages = split_pages(st['content'])
        print(f"== {st['title']} ({len(pages)} halaman)")
        for i, page in enumerate(pages):
            key = narration_key(page)
            mp3, js = os.path.join(OUT, key + '.mp3'), os.path.join(OUT, key + '.json')
            if os.path.exists(mp3) and os.path.exists(js) and not args.force:
                skipped += 1
                continue
            try:
                audio, timing = narrate(page, api_key, args)
            except urllib.error.HTTPError as e:
                sys.exit(f'Gagal di halaman {i + 1}: {e.code} {e.read().decode(errors="ignore")}')
            open(mp3, 'wb').write(audio)
            json.dump(timing, open(js, 'w', encoding='utf-8'), ensure_ascii=False)
            made += 1
            chars += len(page)
            print(f'  ok hal. {i + 1} -> {key}')

        # pesan moral & soal kuis: kalimat sama persis dengan yang diucapkan story_end_view.dart
        extra = []
        if st.get('moral'):
            extra.append(f"Pesan dari cerita ini. {st['moral']}")
        extra += [q['question'] for q in (st.get('quiz') or []) if q.get('question')]
        for text in extra:
            path = os.path.join(gv.OUT, gv.clip_key(text) + '.mp3')
            if os.path.exists(path) and not args.force:
                skipped += 1
                continue
            try:
                audio = gv.el_say(text, api_key, args)
            except urllib.error.HTTPError as e:
                sys.exit(f'Gagal untuk "{text}": {e.code} {e.read().decode(errors="ignore")}')
            open(path, 'wb').write(audio)
            made += 1
            chars += len(text)
            print(f'  ok suara: {text[:50]}')
    print(f'Selesai: {made} halaman direkam (~{chars} karakter), {skipped} sudah ada.')


if __name__ == '__main__':
    main()
