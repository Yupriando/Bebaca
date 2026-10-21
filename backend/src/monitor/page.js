// Halaman web "Pantau Langsung" untuk HP orang tua (dibuka dari scan QR).
// Disimpan sebagai teks di modul JS supaya otomatis ikut ter-deploy di Vercel.

export const PAGE_HTML = `<!doctype html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<meta name="theme-color" content="#50A5DB">
<title>Pantau Belajar · Bebaca</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Itim&display=swap" rel="stylesheet">
<style>
  :root { --blue:#50A5DB; --ink:#1A1033; --muted:#6B6B6B; --bg:#F4FAFF; --card:#fff; --green:#2E9E5B; --red:#E5533D; --gold:#FFB300; }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--bg); color:var(--ink); font-family:'Itim', system-ui, sans-serif; }
  header { background:var(--blue); color:#fff; padding:18px 16px 26px; }
  .brand { font-size:15px; opacity:.9; letter-spacing:.3px; }
  .child { display:flex; align-items:center; gap:12px; margin-top:10px; }
  .avatar { width:56px; height:56px; border-radius:50%; background:#fff; object-fit:cover; flex:none;
            display:flex; align-items:center; justify-content:center; font-size:28px; color:var(--blue); }
  .name { font-size:26px; font-weight:bold; line-height:1.1; }
  .status { display:inline-flex; align-items:center; gap:6px; margin-top:4px; font-size:15px;
            background:rgba(255,255,255,.2); padding:3px 10px; border-radius:20px; }
  .dot { width:10px; height:10px; border-radius:50%; background:#cfd8dc; }
  .dot.on { background:#7CFC9A; box-shadow:0 0 0 0 rgba(124,252,154,.8); animation:pulse 1.6s infinite; }
  @keyframes pulse { 70% { box-shadow:0 0 0 10px rgba(124,252,154,0); } 100% { box-shadow:0 0 0 0 rgba(124,252,154,0); } }
  main { max-width:640px; margin:-14px auto 0; padding:0 14px 30px; }
  .card { background:var(--card); border-radius:20px; padding:16px; margin-bottom:12px; box-shadow:0 2px 8px rgba(0,0,0,.06); }
  .label { font-size:14px; color:var(--muted); }
  .now-title { font-size:24px; font-weight:bold; margin-top:4px; }
  .now-detail { font-size:17px; color:var(--muted); }
  .idle { font-size:18px; color:var(--muted); }
  .stats { display:grid; grid-template-columns:repeat(2,1fr); gap:10px; }
  .stat { background:var(--card); border-radius:18px; padding:12px; box-shadow:0 2px 8px rgba(0,0,0,.06); }
  .stat b { display:block; font-size:28px; }
  .feed { list-style:none; margin:0; padding:0; }
  .feed li { display:flex; gap:10px; padding:9px 0; border-bottom:1px solid #eef2f5; font-size:17px; }
  .feed li:last-child { border-bottom:none; }
  .feed .ic { width:26px; text-align:center; flex:none; }
  .feed .t { flex:1; }
  .feed .time { color:var(--muted); font-size:14px; white-space:nowrap; }
  .new { animation:flash 1.2s ease-out; }
  @keyframes flash { from { background:#FFF3C4; } to { background:transparent; } }
  .live { margin-left:6px; font-size:13px; background:#FFD54F; color:#5A3A00; padding:1px 8px; border-radius:10px; display:none; }
  .live.on { display:inline-block; }
  .error { text-align:center; padding:60px 20px; font-size:20px; }
  footer { text-align:center; color:var(--muted); font-size:13px; padding:10px 16px 24px; }
</style>
</head>
<body data-sb-url="__SB_URL__" data-sb-key="__SB_KEY__">
<header>
  <div class="brand">📚 Bebaca · Pantau Belajar</div>
  <div class="child">
    <div class="avatar" id="avatar">🙂</div>
    <div>
      <div class="name" id="name">Memuat...</div>
      <div class="status"><span class="dot" id="dot"></span><span id="status">Menghubungkan...</span><span class="live" id="live">⚡ Langsung</span></div>
    </div>
  </div>
</header>
<main id="main">
  <div class="card">
    <div class="label">Sedang apa sekarang</div>
    <div id="now"><div class="idle">Memuat...</div></div>
  </div>
  <div class="stats">
    <div class="stat"><span class="label">⏱ Belajar hari ini</span><b id="minutes">-</b></div>
    <div class="stat"><span class="label">✅ Jawaban benar</span><b id="correct">-</b></div>
    <div class="stat"><span class="label">🏆 Lesson selesai</span><b id="lessons">-</b></div>
    <div class="stat"><span class="label">🔥 Hari beruntun</span><b id="streak">-</b></div>
  </div>
  <div class="card" style="margin-top:12px">
    <div class="label">Aktivitas hari ini</div>
    <ul class="feed" id="feed"></ul>
  </div>
</main>
<footer>Diperbarui otomatis secara langsung. Hanya aktivitas belajar yang ditampilkan,<br>bukan isi layar, foto, atau suara anak.</footer>
<script src="__SB_JS__"></script>
<script src="/pantau/app.js"></script>
</body>
</html>`;

export const PAGE_JS = `(() => {
  const token = location.pathname.split('/').filter(Boolean).pop();
  const $ = (id) => document.getElementById(id);
  let seen = new Set();
  let first = true;
  let timer = null;
  let live = false; // tersambung ke realtime?
  let pending = null;
  let last = null;

  const ago = (iso) => {
    if (!iso) return '';
    const s = Math.max(0, Math.round((Date.now() - Date.parse(iso)) / 1000));
    if (s < 60) return 'baru saja';
    if (s < 3600) return Math.floor(s / 60) + ' mnt lalu';
    return new Date(iso).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
  };

  function el(tag, cls, text) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text; // textContent: aman dari kode berbahaya
    return e;
  }

  function render(d) {
    $('name').textContent = d.child.name;
    document.title = 'Pantau ' + d.child.name + ' · Bebaca';
    const av = $('avatar');
    if (d.child.avatarUrl && !av.querySelector('img')) {
      av.textContent = '';
      const img = el('img', 'avatar');
      img.src = d.child.avatarUrl;
      img.alt = '';
      av.appendChild(img);
    }
    $('dot').className = 'dot' + (d.online ? ' on' : '');
    $('status').textContent = d.online
      ? 'Sedang memakai Bebaca'
      : d.lastSeen ? 'Tidak aktif · terakhir ' + ago(d.lastSeen) : 'Belum membuka Bebaca hari ini';

    const now = $('now');
    now.textContent = '';
    if (d.activity) {
      const icon = d.activity.kind === 'lesson' ? '📘 ' : d.activity.kind === 'story' ? '📖 ' : '👆 ';
      now.appendChild(el('div', 'now-title', icon + d.activity.title));
      now.appendChild(el('div', 'now-detail', d.activity.detail));
    } else {
      now.appendChild(el('div', 'idle', d.online ? 'Membuka aplikasi' : 'Sedang tidak belajar'));
    }

    $('minutes').textContent = d.today.minutes + ' mnt';
    $('correct').textContent = d.today.answers ? d.today.correct + '/' + d.today.answers : '-';
    $('lessons').textContent = d.today.lessonsCompleted;
    $('streak').textContent = d.today.streak + ' hari';

    const feed = $('feed');
    feed.textContent = '';
    if (!d.feed.length) feed.appendChild(el('li', null, 'Belum ada aktivitas hari ini.'));
    for (const f of d.feed) {
      const key = f.at + f.text;
      const li = el('li', !first && !seen.has(key) ? 'new' : null);
      li.appendChild(el('span', 'ic', f.icon));
      li.appendChild(el('span', 't', f.text));
      li.appendChild(el('span', 'time', ago(f.at)));
      feed.appendChild(li);
      seen.add(key);
    }
    first = false;
    last = d;
  }

  // teks "x menit lalu" tetap segar walau belum ada data baru
  function tickAgo() {
    if (!last) return;
    document.querySelectorAll('.feed .time').forEach((e, i) => {
      if (last.feed[i]) e.textContent = ago(last.feed[i].at);
    });
    if (!last.online && last.lastSeen) $('status').textContent = 'Tidak aktif · terakhir ' + ago(last.lastSeen);
  }

  function showError(msg) {
    clearInterval(timer);
    live = false;
    const main = $('main');
    main.textContent = '';
    main.appendChild(el('div', 'error', msg));
    $('name').textContent = 'Bebaca';
    $('status').textContent = 'Tidak tersambung';
  }

  async function load() {
    if (document.hidden) return;
    try {
      const r = await fetch('/pantau/' + encodeURIComponent(token) + '/data', { cache: 'no-store' });
      if (r.status === 404) return showError('Tautan ini sudah tidak berlaku. Buka Bebaca di HP anak → Pengaturan → Pantau dari HP Orang Tua, lalu scan QR yang baru.');
      if (!r.ok) throw new Error();
      render(await r.json());
    } catch (_) {
      $('status').textContent = 'Koneksi terputus, mencoba lagi...';
    }
  }

  // Ambil data: segera saat ada sinyal realtime (digabung bila beruntun)
  function soon() {
    if (pending) return;
    pending = setTimeout(() => { pending = null; load(); }, 250);
  }

  // Cadangan: tanpa realtime ambil tiap 3 detik; dengan realtime cukup tiap 20 detik
  function schedule() {
    clearInterval(timer);
    timer = setInterval(load, live ? 20000 : 3000);
  }

  async function connectRealtime() {
    const url = document.body.dataset.sbUrl, key = document.body.dataset.sbKey;
    if (!window.supabase || !url || !key || !crypto.subtle) return;
    const bytes = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token));
    const hash = [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, '0')).join('');
    const client = window.supabase.createClient(url, key, { auth: { persistSession: false } });
    client
      .channel('pantau-' + hash.slice(0, 32))
      .on('broadcast', { event: 'update' }, soon)
      .subscribe((status) => {
        live = status === 'SUBSCRIBED';
        $('live').className = 'live' + (live ? ' on' : '');
        schedule();
        if (live) soon(); // susul data yang mungkin terlewat saat menyambung
      });
  }

  load();
  schedule();
  setInterval(tickAgo, 10000);
  connectRealtime().catch(() => {});
  document.addEventListener('visibilitychange', load);
})();`;
