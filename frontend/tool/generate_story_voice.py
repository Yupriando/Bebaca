#!/usr/bin/env python3
"""
Membuat suara AI untuk dongeng (ElevenLabs), lalu MENGUNGGAHNYA ke Supabase Storage
(bucket publik "narasi"). Aplikasi memutarnya langsung dari sana, jadi APK tetap kecil dan
dongeng baru langsung bersuara tanpa update aplikasi.

Yang direkam untuk tiap dongeng:
  - narasi tiap halaman Baca Bersama -> st_<kunci>.mp3 + st_<kunci>.json
    (.json = waktu mulai/selesai tiap kata, supaya kata yang dibaca menyala seperti karaoke)
  - "Pesan dari cerita ini", soal kuis, pertanyaan "Ayo ngobrol", dan arti "kata baru"
Teks diambil langsung dari Supabase (pakai backend/.env). Tidak perlu pip install.

API key ElevenLabs: isi variabel ELEVENLABS_API_KEY, atau tambahkan baris
  ELEVENLABS_API_KEY=sk_...   ke backend/.env (file itu tidak ikut ke GitHub).

Jalankan dari folder frontend (suara sama dengan rekaman lesson):
  python tool/generate_story_voice.py --voice <VOICE_ID> --model eleven_flash_v2_5
  Cek dulu biayanya     : --dry-run   (tidak merekam apa pun)
  Satu dongeng saja     : --title "Timun Mas"
  Rekam ulang           : --force
  Simpan di aplikasi    : --local     (cara lama: assets/stories & assets/voice, membuat APK besar)

Yang sudah ada (di aplikasi atau di Storage) dilewati, jadi kalau kuota habis di tengah jalan,
jalankan lagi bulan berikutnya untuk melanjutkan. Halaman yang belum punya rekaman tetap
dibacakan suara bawaan perangkat.
Cara memecah halaman HARUS sama dengan lib/features/stories/story_pages.dart.
"""
import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate_voice as gv  # noqa: E402  (request(), clip_key(), API key & alamat API ElevenLabs)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'assets', 'stories')
BACKEND_ENV = os.path.join(ROOT, '..', 'backend', '.env')
MAX_WORDS = 24
BUCKET = 'narasi'


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


def supabase():
    env = read_env(BACKEND_ENV)
    url, key = env.get('SUPABASE_URL'), env.get('SUPABASE_SERVICE_ROLE_KEY')
    if not url or not key:
        sys.exit(f'SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY tidak ditemukan di {os.path.normpath(BACKEND_ENV)}')
    return url.rstrip('/'), key


def sb_request(method, path, body=None, headers=None, raw=None):
    url, key = supabase()
    data = raw if raw is not None else (None if body is None else json.dumps(body).encode())
    req = urllib.request.Request(
        f'{url}{path}',
        data=data,
        method=method,
        headers={
            'apikey': key,
            'Authorization': f'Bearer {key}',
            **({'Content-Type': 'application/json'} if raw is None else {}),
            **(headers or {}),
        },
    )
    with urllib.request.urlopen(req, timeout=60) as res:
        return res.read()


def fetch_stories(title=None):
    def get(columns):
        query = f'select={columns}&content=not.is.null&order=title'
        if title:
            query += '&title=eq.' + urllib.parse.quote(title)
        return json.loads(sb_request('GET', f'/rest/v1/stories?{query}'))

    try:
        rows = get('title,content,moral,quiz,prompts,vocab,is_premium')
    except urllib.error.HTTPError as e:
        if e.code != 400:
            raise
        rows = get('title,content,moral,quiz,is_premium')  # migration 007 belum dijalankan
    # dongeng gratis direkam lebih dulu (kalau kuota habis, yang gratis sudah lengkap)
    return sorted(rows, key=lambda r: (bool(r.get('is_premium')), r['title']))


def ensure_bucket():
    try:
        sb_request('POST', '/storage/v1/bucket', {'id': BUCKET, 'name': BUCKET, 'public': True})
        print(f'Bucket "{BUCKET}" dibuat (publik).')
    except urllib.error.HTTPError as e:
        msg = e.read().decode(errors='ignore')
        if e.code not in (400, 409) or 'exist' not in msg.lower():
            raise


def list_bucket():
    """Semua nama file di bucket."""
    names, offset = [], 0
    while True:
        rows = json.loads(sb_request('POST', f'/storage/v1/object/list/{BUCKET}', {
            'prefix': '', 'limit': 1000, 'offset': offset, 'sortBy': {'column': 'name', 'order': 'asc'},
        }))
        names += [r['name'] for r in rows if r.get('name')]
        if len(rows) < 1000:
            return names
        offset += 1000


def upload(name, data, content_type, cache='max-age=31536000'):
    sb_request('POST', f'/storage/v1/object/{BUCKET}/{urllib.parse.quote(name)}', raw=data, headers={
        'Content-Type': content_type, 'x-upsert': 'true', 'cache-control': cache,
    })


def write_manifest():
    """manifest.json = daftar rekaman yang tersedia (dibaca aplikasi, lihat RemoteVoice)."""
    names = set(list_bucket())
    keys = sorted({
        n[:-4] for n in names
        if n.endswith('.mp3') and (not n.startswith('st_') or n[:-4] + '.json' in names)
    })
    upload('manifest.json', json.dumps(keys).encode(), 'application/json', cache='max-age=60')
    print(f'manifest.json diperbarui: {len(keys)} rekaman tersedia di Storage.')


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
        f'{gv.EL_API}/text-to-speech/{args.voice}/with-timestamps?output_format={args.format}',
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


def short_clip(text, api_key, args):
    body = {
        'text': text,
        'model_id': args.model,
        'voice_settings': {'stability': 0.55, 'similarity_boost': 0.8, 'style': 0.25,
                           'use_speaker_boost': True, 'speed': args.rate},
    }
    if 'v2_5' in args.model or 'v3' in args.model:
        body['language_code'] = 'id'
    return gv.request(
        f'{gv.EL_API}/text-to-speech/{args.voice}?output_format={args.format}',
        body,
        {'xi-api-key': api_key, 'Accept': 'audio/mpeg'},
    )


def fmt(n):
    return f'{n:,}'.replace(',', '.')


def extras_of(st):
    """Suara pendek dongeng: kalimatnya HARUS sama persis dengan yang diucapkan aplikasi
    (story_end_view.dart, story_reader_page.dart, vocab_dialog.dart)."""
    out = []
    if st.get('moral'):
        out.append(f"Pesan dari cerita ini. {st['moral']}")
    out += [q['question'] for q in (st.get('quiz') or []) if q.get('question')]
    out += [p['text'] for p in (st.get('prompts') or []) if p.get('text')]
    out += [f"{v['word']}. Artinya, {v['meaning']}" for v in (st.get('vocab') or []) if v.get('word')]
    return out


def main():
    sys.stdout.reconfigure(errors='replace')
    ap = argparse.ArgumentParser()
    ap.add_argument('--voice', help='voice ID ElevenLabs (lihat generate_voice.py --list-voices)')
    ap.add_argument('--model', default='eleven_flash_v2_5')
    ap.add_argument('--rate', type=float, default=0.9)
    ap.add_argument('--title', help='hanya dongeng dengan judul ini, mis. "Timun Mas"')
    ap.add_argument('--force', action='store_true', help='rekam ulang walau sudah ada')
    ap.add_argument('--local', action='store_true', help='simpan di aplikasi (assets) seperti dulu, bukan di Storage')
    ap.add_argument('--format', help='format audio ElevenLabs (bawaan: mp3_44100_64, atau _128 untuk --local)')
    ap.add_argument('--dry-run', action='store_true', help='hitung yang akan direkam & perkiraan karakter saja')
    args = ap.parse_args()
    args.format = args.format or ('mp3_44100_128' if args.local else 'mp3_44100_64')

    api_key = gv.api_key('ELEVENLABS_API_KEY')
    if not args.dry_run:
        if not api_key:
            sys.exit('Isi dulu ELEVENLABS_API_KEY (variabel lingkungan atau baris di backend/.env).')
        if not args.voice:
            sys.exit('Pilih suara: --voice <VOICE_ID> (lihat: python tool/generate_voice.py --list-voices)')

    stories = fetch_stories(args.title)
    if not stories:
        sys.exit('Tidak ada dongeng yang punya isi cerita' + (f' berjudul "{args.title}"' if args.title else '') + '.')

    bundled_pages = {f[:-4] for f in os.listdir(OUT) if f.endswith('.mp3')} if os.path.isdir(OUT) else set()
    bundled_clips = {f[:-4] for f in os.listdir(gv.OUT) if f.endswith('.mp3')} if os.path.isdir(gv.OUT) else set()
    in_storage = set()
    if not args.local:
        if not args.dry_run:
            ensure_bucket()
        try:
            in_storage = {n[:-4] for n in list_bucket() if n.endswith('.mp3')}
        except urllib.error.HTTPError:
            in_storage = set()  # bucket belum ada

    def exists(key, bundled):
        return not args.force and (key in bundled or key in in_storage)

    # ---- daftar pekerjaan
    jobs = []  # (judul, jenis, teks, kunci)
    for st in stories:
        for page in split_pages(st['content']):
            k = narration_key(page)
            if not exists(k, bundled_pages):
                jobs.append((st['title'], 'page', page, k))
        for text in extras_of(st):
            k = gv.clip_key(text)
            if not exists(k, bundled_clips):
                jobs.append((st['title'], 'clip', text, k))
    jobs = list({j[3]: j for j in jobs}.values())  # kalimat sama cukup sekali

    chars = sum(len(j[2]) for j in jobs)
    per_story = {}
    for j in jobs:
        per_story[j[0]] = per_story.get(j[0], 0) + len(j[2])
    print(f'{len(stories)} dongeng, {len(jobs)} rekaman baru (~{fmt(chars)} karakter).')
    if 'flash' in args.model or 'turbo' in args.model:
        print(f'Model {args.model}: 1 karakter = 0,5 kredit -> perkiraan ~{fmt(chars // 2)} kredit ElevenLabs.')
    if args.dry_run:
        for t, c in sorted(per_story.items()):
            print(f'  {t}: ~{c} karakter')
        return

    os.makedirs(OUT, exist_ok=True)
    made = done_chars = 0
    stopped = None
    try:
        for i, (title, kind, text, key) in enumerate(jobs, 1):
            try:
                if kind == 'page':
                    audio, timing = narrate(text, api_key, args)
                    if args.local:
                        open(os.path.join(OUT, key + '.mp3'), 'wb').write(audio)
                        json.dump(timing, open(os.path.join(OUT, key + '.json'), 'w', encoding='utf-8'), ensure_ascii=False)
                    else:
                        upload(key + '.json', json.dumps(timing, ensure_ascii=False).encode('utf-8'), 'application/json')
                        upload(key + '.mp3', audio, 'audio/mpeg')
                else:
                    audio = short_clip(text, api_key, args)
                    if args.local:
                        open(os.path.join(gv.OUT, key + '.mp3'), 'wb').write(audio)
                    else:
                        upload(key + '.mp3', audio, 'audio/mpeg')
            except urllib.error.HTTPError as e:
                detail = e.read().decode(errors='ignore')
                stopped = f'{e.code} {detail[:300]}'
                if e.code in (401, 402, 429) or 'quota' in detail.lower():
                    break  # kuota/izin habis: simpan yang sudah jadi, lanjutkan lain kali
                raise
            made += 1
            done_chars += len(text)
            print(f'  [{i}/{len(jobs)}] {title}: {"halaman" if kind == "page" else "suara"} -> {key}')
    finally:
        if not args.local and made:
            write_manifest()

    print(f'Selesai: {made} rekaman (~{fmt(done_chars)} karakter).')
    if stopped:
        print(f'Berhenti karena: {stopped}')
        print('Jalankan perintah yang sama lagi nanti untuk melanjutkan (yang sudah jadi tidak direkam ulang).')
        sys.exit(1)


if __name__ == '__main__':
    main()
