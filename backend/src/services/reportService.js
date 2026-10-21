import { supabaseAdmin } from '../config/supabase.js';
import { must } from '../utils/errors.js';
import { jakartaDate } from '../utils/date.js';

// ======================================================================
// Laporan Perkembangan (di aplikasi, khusus orang tua) & Pantau Langsung (web via QR).
// Sumber data: daily_usage, lesson_progress, story_progress, profiles, learning_events.
// ======================================================================

const DAY_NAMES = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
const STEP_NAMES = {
  intro: 'Kenalan huruf',
  find: 'Cari huruf',
  listenPick: 'Dengar & pilih',
  traceUpper: 'Menulis huruf besar',
  traceLower: 'Menulis huruf kecil',
  read: 'Baca huruf',
};
const TAB_NAMES = { 0: 'Belajar', 1: 'Dongeng', 2: 'Profil', 3: 'Pengaturan' };
const TAB_ACTIVITY = {
  0: 'Melihat daftar pelajaran',
  1: 'Memilih dongeng',
  2: 'Melihat halaman profil',
  3: 'Membuka pengaturan',
};

/** Kalimat perintah yang dilihat anak di layar untuk tiap jenis langkah. */
function stepPrompt(step, letter = '') {
  switch (step) {
    case 'intro': return `Ini huruf ${letter}`;
    case 'find': return `Carilah huruf ${letter}`;
    case 'listenPick': return `Huruf apa yang kamu dengar? (jawabannya ${letter})`;
    case 'traceUpper': return `Gambarkan huruf ${letter.toUpperCase()}`;
    case 'traceLower': return `Gambarkan huruf ${letter.toLowerCase()}`;
    case 'read': return `Baca huruf ${letter}`;
    default: return '';
  }
}
const STORY_MODES = {
  browse: '👀 Melihat-lihat halaman',
  listen: '🔊 Mendengarkan narasi',
  read: '🎤 Membaca sendiri (mikrofon)',
};

/** Awal hari (WIB) sebagai ISO UTC, untuk filter kolom timestamptz. */
const wibStart = (date) => new Date(`${date}T00:00:00+07:00`).toISOString();

function addDays(date, n) {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

/** 7 tanggal (Senin..Minggu) untuk minggu ke-[weekOffset] (0 = minggu ini, 1 = minggu lalu). */
function weekDates(weekOffset = 0) {
  const today = jakartaDate(0);
  const dow = new Date(`${today}T00:00:00Z`).getUTCDay(); // 0 = Minggu
  const monday = addDays(today, -((dow + 6) % 7) - 7 * weekOffset);
  return Array.from({ length: 7 }, (_, i) => addDays(monday, i));
}

const pct = (a, b) => (b === 0 ? 0 : Math.round((a / b) * 100));

/** Ubah satu kejadian menjadi teks yang mudah dibaca orang tua. null = tidak ditampilkan. */
export function describe(ev) {
  const d = ev.data || {};
  switch (ev.type) {
    case 'lesson_start':
      return { icon: '📘', text: `Mulai belajar "${d.title ?? 'lesson'}"` };
    case 'lesson_complete':
      return { icon: '🏆', text: `Selesai "${d.title ?? 'lesson'}" ${'⭐'.repeat(d.stars ?? 0)}` };
    case 'lesson_exit':
      return { icon: '🚪', text: `Keluar dari "${d.title ?? 'lesson'}" sebelum selesai` };
    case 'answer': {
      const step = STEP_NAMES[d.step] ?? 'Soal';
      if (d.correct) return { icon: '✅', text: `${step} ${d.letter ?? ''}: benar` };
      const picked = !d.picked
        ? ''
        : d.step === 'read' ? ` (terdengar "${d.picked}")` : ` (memilih ${d.picked})`;
      return { icon: '❌', text: `${step} ${d.letter ?? ''}: belum tepat${picked}` };
    }
    case 'story_open':
      return { icon: '📖', text: `Membuka dongeng "${d.title ?? ''}"` };
    case 'step':
      return d.note ? { icon: '📝', text: `${STEP_NAMES[d.step] ?? 'Soal'} ${d.letter ?? ''}: ${d.note}` } : null;
    case 'story_read':
      return d.good
        ? { icon: '🎤', text: `Membaca sendiri hal. ${(d.page ?? 0) + 1}: ${d.read}/${d.total} kata ✅` }
        : { icon: '🎤', text: `Membaca sendiri hal. ${(d.page ?? 0) + 1}: baru ${d.read}/${d.total} kata` };
    case 'story_complete':
      return { icon: '🌟', text: `Selesai membaca "${d.title ?? ''}" ${'⭐'.repeat(d.stars ?? 0)}` };
    case 'tab':
      return { icon: '👆', text: `Membuka menu ${TAB_NAMES[d.index] ?? d.name ?? ''}` };
    case 'app_open':
      return { icon: '📱', text: 'Membuka aplikasi Bebaca' };
    default:
      return null; // heartbeat, story_page: terlalu sering untuk ditampilkan
  }
}

async function loadProfile(userId) {
  const p = must(
    await supabaseAdmin
      .from('profiles')
      .select('nama, avatar_url, hari_berturut, last_study_date')
      .eq('id', userId)
      .maybeSingle(),
    undefined,
    'laporan: profil'
  );
  const alive = p && [jakartaDate(0), jakartaDate(-1)].includes(p.last_study_date);
  return {
    name: p?.nama ?? 'Anak',
    avatarUrl: p?.avatar_url ?? null,
    streak: alive ? p.hari_berturut : 0,
  };
}

/** Penguasaan huruf dari jawaban 30 hari terakhir. */
function letterStats(answers) {
  const map = new Map();
  for (const ev of answers) {
    const d = ev.data || {};
    if (!d.letter) continue;
    const letter = String(d.letter).toUpperCase();
    const s = map.get(letter) ?? { letter, total: 0, correct: 0, confusedWith: {} };
    s.total++;
    if (d.correct) s.correct++;
    else if (d.picked && String(d.picked).toUpperCase() !== letter) {
      const p = String(d.picked).toUpperCase();
      s.confusedWith[p] = (s.confusedWith[p] ?? 0) + 1;
    }
    map.set(letter, s);
  }
  return [...map.values()]
    .map((s) => {
      const accuracy = pct(s.correct, s.total);
      const top = Object.entries(s.confusedWith).sort((a, b) => b[1] - a[1])[0];
      return {
        letter: s.letter,
        total: s.total,
        accuracy,
        status:
          s.total >= 3 && accuracy >= 80 ? 'mastered' : s.total >= 2 && accuracy < 60 ? 'practice' : 'learning',
        confusedWith: top && top[1] >= 2 ? top[0] : null,
      };
    })
    .sort((a, b) => a.letter.localeCompare(b.letter));
}

function suggestions({ name, days, letters, lessonsDone, prevMinutes }) {
  const out = [];
  const minutes = days.reduce((t, d) => t + d.minutes, 0);
  const activeDays = days.filter((d) => d.minutes > 0).length;

  for (const l of letters.filter((x) => x.status === 'practice').slice(0, 2)) {
    out.push(
      l.confusedWith
        ? `Huruf ${l.letter} sering tertukar dengan ${l.confusedWith}. Ajak ${name} menulis ${l.letter} dan ${l.confusedWith} bergantian sambil menyebut bunyinya.`
        : `Huruf ${l.letter} masih sering salah (${l.accuracy}% benar). Coba ulangi lesson huruf ${l.letter} bersama ${name}.`
    );
  }
  if (activeDays <= 2) {
    out.push(`Minggu ini ${name} baru belajar ${activeDays} hari. Belajar sebentar tapi rutin (10 menit tiap sore) lebih efektif daripada lama sekali-sekali.`);
  } else if (prevMinutes > 0 && minutes > prevMinutes * 1.2) {
    out.push(`Waktu belajar naik dibanding minggu lalu (${prevMinutes} → ${minutes} menit). Beri pujian ya! 🎉`);
  }
  const mastered = letters.filter((x) => x.status === 'mastered');
  if (mastered.length >= 3) {
    out.push(`${name} sudah menguasai huruf ${mastered.map((x) => x.letter).join(', ')}. Coba minta ${name} menunjuk huruf itu di buku atau papan nama di sekitar rumah.`);
  }
  if (lessonsDone === 0 && minutes > 0) {
    out.push(`${name} sudah membuka aplikasi tapi belum menyelesaikan lesson minggu ini. Temani satu lesson sampai selesai agar ${name} merasakan berhasil.`);
  }
  if (out.length === 0) out.push(`${name} belajar dengan baik minggu ini. Pertahankan kebiasaannya! 👍`);
  return out.slice(0, 4);
}

/**
 * Laporan Perkembangan untuk satu minggu.
 * detailed = false (akun gratis): ringkasan & aktivitas saja; grafik/huruf/saran = Premium.
 */
export async function buildReport(userId, { detailed = true, weekOffset = 0 } = {}) {
  const dates = weekDates(weekOffset);
  const from = wibStart(dates[0]);
  const to = wibStart(addDays(dates[6], 1));
  const prev = weekDates(weekOffset + 1);

  const [profile, usageRes, prevUsageRes, lessonsRes, storiesRes, answersRes, recentRes] =
    await Promise.all([
      loadProfile(userId),
      supabaseAdmin.from('daily_usage').select('usage_date, minutes').eq('user_id', userId)
        .gte('usage_date', dates[0]).lte('usage_date', dates[6]),
      supabaseAdmin.from('daily_usage').select('minutes').eq('user_id', userId)
        .gte('usage_date', prev[0]).lte('usage_date', prev[6]),
      supabaseAdmin.from('lesson_progress').select('stars, completed_at, lessons(title)')
        .eq('user_id', userId).gte('completed_at', from).lt('completed_at', to),
      supabaseAdmin.from('story_progress').select('completed_at, updated_at, stars, stories(title)')
        .eq('user_id', userId).gte('updated_at', from).lt('updated_at', to),
      supabaseAdmin.from('learning_events').select('data, created_at').eq('user_id', userId)
        .eq('type', 'answer').gte('created_at', new Date(Date.now() - 30 * 86400000).toISOString())
        .order('created_at', { ascending: false }).limit(3000),
      supabaseAdmin.from('learning_events').select('type, data, created_at').eq('user_id', userId)
        .in('type', ['lesson_complete', 'lesson_start', 'story_complete', 'story_open'])
        .order('created_at', { ascending: false }).limit(15),
    ]);

  const usage = new Map(must(usageRes, undefined, 'laporan: waktu').map((u) => [u.usage_date, u.minutes]));
  const days = dates.map((date) => ({
    date,
    label: DAY_NAMES[new Date(`${date}T00:00:00Z`).getUTCDay()],
    minutes: usage.get(date) ?? 0,
  }));
  const prevMinutes = must(prevUsageRes, undefined, 'laporan: minggu lalu').reduce((t, u) => t + u.minutes, 0);

  const lessons = must(lessonsRes, undefined, 'laporan: lesson');
  const stories = must(storiesRes, undefined, 'laporan: dongeng');
  const answers = must(answersRes, undefined, 'laporan: jawaban');
  const weekAnswers = answers.filter((a) => a.created_at >= from && a.created_at < to);
  const letters = letterStats(answers);

  const summary = {
    minutes: days.reduce((t, d) => t + d.minutes, 0),
    prevMinutes,
    activeDays: days.filter((d) => d.minutes > 0).length,
    streak: profile.streak,
    lessonsCompleted: lessons.length,
    avgStars: lessons.length
      ? Math.round((lessons.reduce((t, l) => t + l.stars, 0) / lessons.length) * 10) / 10
      : 0,
    storiesRead: stories.filter((s) => s.completed_at && s.completed_at >= from).length,
    storiesOpened: stories.length,
    answers: weekAnswers.length,
    accuracy: pct(weekAnswers.filter((a) => a.data?.correct).length, weekAnswers.length),
  };

  const recent = must(recentRes, undefined, 'laporan: aktivitas')
    .map((ev) => ({ ...describe(ev), at: ev.created_at }))
    .filter((e) => e.text)
    .slice(0, 10);

  return {
    child: { name: profile.name, avatarUrl: profile.avatarUrl },
    week: { from: dates[0], to: dates[6], offset: weekOffset },
    summary,
    recent,
    detailed,
    // ---- Premium ----
    days: detailed ? days : null,
    letters: detailed ? letters : null,
    suggestions: detailed
      ? suggestions({ name: profile.name, days, letters, lessonsDone: lessons.length, prevMinutes })
      : null,
  };
}

/**
 * "Sedang apa" sekarang, sedetail mungkin, dari kejadian hari ini (urut terbaru dulu).
 * - lesson : langkah ke berapa, jenis soal, huruf, perintah, pilihan di layar (benar/salah yang
 *            dipilih), jumlah benar/salah di lesson ini, catatan (mis. mikrofon belum menangkap suara)
 * - dongeng: halaman ke berapa, kalimat yang sedang dibaca, mode (dengar/baca sendiri), hasil membaca
 * - menu   : layar yang sedang dibuka
 */
export function currentActivity(events) {
  const meaningful = events.find((e) => e.type !== 'heartbeat');
  if (!meaningful) return null;
  const since = (ev) => ev?.created_at ?? null;

  const startIdx = events.findIndex((e) => e.type === 'lesson_start');
  const endIdx = events.findIndex((e) => ['lesson_complete', 'lesson_exit'].includes(e.type));
  const storyIdx = events.findIndex((e) => e.type === 'story_open');
  const tabIdx = events.findIndex((e) => e.type === 'tab');
  // indeks lebih kecil = lebih baru. "Masih berjalan" = tidak ada kejadian penutup yang lebih baru.
  const newer = (i, j) => i >= 0 && i < j;

  // ---- lesson yang sedang berjalan
  const lessonRunning =
    startIdx >= 0 && !newer(endIdx, startIdx) && !newer(storyIdx, startIdx) && !newer(tabIdx, startIdx);
  if (lessonRunning) {
    const inLesson = events.slice(0, startIdx);
    const start = events[startIdx].data || {};
    const steps = inLesson.filter((e) => e.type === 'step');
    const cur = steps[0]?.data ?? { stepIndex: 0, steps: start.steps };
    const sameStep = (e) => (e.data?.stepIndex ?? -1) === cur.stepIndex;
    const options = steps.find((e) => sameStep(e) && Array.isArray(e.data.options))?.data.options ?? null;
    const note = steps.find((e) => sameStep(e) && e.data.note)?.data.note ?? null;
    const lessonAnswers = inLesson.filter((e) => e.type === 'answer');
    const stepAnswers = lessonAnswers.filter(sameStep);

    let optionStates = null;
    if (options) {
      const target = String(cur.letter ?? '').toUpperCase();
      let correctLeft = stepAnswers.filter((a) => a.data.correct).length;
      const wrong = new Set(
        stepAnswers.filter((a) => !a.data.correct).map((a) => String(a.data.picked ?? '').toUpperCase())
      );
      optionStates = options.map((o) => {
        const letter = String(o).toUpperCase();
        if (letter === target && correctLeft > 0) {
          correctLeft--;
          return { letter, state: 'correct' };
        }
        return { letter, state: wrong.has(letter) ? 'wrong' : '' };
      });
    }
    const last = stepAnswers[0];
    return {
      kind: 'lesson',
      title: start.title ?? cur.lessonTitle ?? 'Lesson',
      subtitle: start.unit ? `Unit ${start.unit}, Section ${start.section}` : null,
      step: (cur.stepIndex ?? 0) + 1,
      steps: cur.steps ?? start.steps ?? null,
      stepName: STEP_NAMES[cur.step] ?? null,
      letter: cur.letter ?? null,
      prompt: cur.step ? stepPrompt(cur.step, cur.letter ?? '') : null,
      options: optionStates,
      lastAnswer: last
        ? { correct: Boolean(last.data.correct), picked: last.data.picked ?? null, read: cur.step === 'read', at: last.created_at }
        : null,
      correct: lessonAnswers.filter((a) => a.data?.correct).length,
      wrong: lessonAnswers.filter((a) => !a.data?.correct).length,
      note,
      since: since(events[startIdx]),
    };
  }

  // ---- dongeng yang sedang dibaca
  const storyRunning =
    storyIdx >= 0 && !newer(tabIdx, storyIdx) && !newer(startIdx, storyIdx) &&
    !events.slice(0, storyIdx).some((e) => e.type === 'story_complete');
  if (storyRunning) {
    const inStory = events.slice(0, storyIdx);
    const open = events[storyIdx].data || {};
    const page = inStory.find((e) => e.type === 'story_page')?.data ?? {};
    const pageNo = page.page ?? open.page ?? 0;
    const read = inStory.find((e) => e.type === 'story_read' && e.data?.page === pageNo)?.data;
    return {
      kind: 'story',
      title: open.title ?? page.title ?? 'Dongeng',
      page: pageNo + 1,
      pages: page.pages ?? open.pages ?? null,
      text: page.text ?? null,
      mode: STORY_MODES[page.mode] ?? STORY_MODES.browse,
      readResult: read ? { read: read.read, total: read.total, good: Boolean(read.good) } : null,
      since: since(events[storyIdx]),
    };
  }

  // ---- sedang di menu / baru saja selesai
  if (meaningful.type === 'tab') {
    const i = meaningful.data?.index;
    return {
      kind: 'menu',
      title: `Menu ${TAB_NAMES[i] ?? meaningful.data?.name ?? ''}`,
      detail: TAB_ACTIVITY[i] ?? 'Sedang memilih',
      since: since(meaningful),
    };
  }
  const d = describe(meaningful);
  return d ? { kind: 'menu', title: d.text, detail: 'Baru saja', since: since(meaningful) } : null;
}

/** Data halaman Pantau Langsung: sedang apa sekarang + kejadian terbaru hari ini. */
export async function buildLiveSnapshot(userId) {
  const today = jakartaDate(0);
  const [profile, eventsRes, usageRes] = await Promise.all([
    loadProfile(userId),
    supabaseAdmin.from('learning_events').select('type, data, created_at').eq('user_id', userId)
      .gte('created_at', wibStart(today)).order('created_at', { ascending: false }).limit(200),
    supabaseAdmin.from('daily_usage').select('minutes').eq('user_id', userId)
      .eq('usage_date', today).maybeSingle(),
  ]);
  const events = must(eventsRes, undefined, 'pantau: kejadian');
  const lastAt = events[0]?.created_at ?? null;
  const online = lastAt ? Date.now() - Date.parse(lastAt) < 150_000 : false;

  const activity = currentActivity(events);

  const answers = events.filter((e) => e.type === 'answer');
  return {
    child: { name: profile.name, avatarUrl: profile.avatarUrl },
    online,
    lastSeen: lastAt,
    activity: online ? activity : null,
    today: {
      minutes: must(usageRes, undefined, 'pantau: waktu')?.minutes ?? 0,
      answers: answers.length,
      correct: answers.filter((a) => a.data?.correct).length,
      lessonsCompleted: events.filter((e) => e.type === 'lesson_complete').length,
      streak: profile.streak,
    },
    feed: events
      .map((ev) => ({ ...describe(ev), at: ev.created_at }))
      .filter((e) => e.text)
      .slice(0, 25),
  };
}
