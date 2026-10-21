// Spesifikasi OpenAPI 3.0 untuk Swagger UI (/docs).
// Kalau menambah/mengubah endpoint, update file ini juga.

const err = (description) => ({
  description,
  content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
});

const ok = (schemaRef, description = 'Berhasil') => ({
  description,
  content: { 'application/json': { schema: { $ref: schemaRef } } },
});

const uuidParam = (description) => ({
  name: 'id',
  in: 'path',
  required: true,
  description,
  schema: { type: 'string', format: 'uuid' },
});

const json = (schemaRef, example) => ({
  required: true,
  content: {
    'application/json': { schema: { $ref: schemaRef }, ...(example ? { example } : {}) },
  },
});

const common = {
  400: err('Data tidak valid'),
  401: err('Token tidak ada / tidak valid'),
};

export const openapi = {
  openapi: '3.0.3',
  info: {
    title: 'Bebaca API',
    version: '1.0.0',
    description: [
      'API backend aplikasi **Bebaca** (belajar baca untuk anak).',
      '',
      '### Cara mencoba di Swagger',
      '1. Jalankan **POST /api/auth/register** untuk membuat akun.',
      '2. Jalankan **POST /api/auth/login**, salin nilai `access_token` dari response.',
      '3. Klik tombol **Authorize** (kanan atas), tempel token tersebut, lalu **Authorize**.',
      '   (Cukup tempel token-nya saja, tanpa kata `Bearer`.)',
      '4. Sekarang semua endpoint bergembok bisa dicoba lewat **Try it out**.',
      '',
      'Semua error berbentuk `{ "message": "..." }`.',
    ].join('\n'),
  },
  servers: [{ url: '/', description: 'Server saat ini' }],
  tags: [
    { name: 'Auth', description: 'Register, login, refresh token, logout' },
    { name: 'Belajar', description: 'Unit, section, dan lesson' },
    { name: 'Dongeng', description: 'Kategori dan cerita' },
    { name: 'Profile', description: 'Data profil pengguna' },
    { name: 'Settings', description: 'Preferensi dan parental control' },
    { name: 'Orang Tua', description: 'Kejadian belajar, Laporan Perkembangan, tautan QR Pantau Langsung' },
    { name: 'Premium', description: 'Bebaca Premium (sementara mode simulasi, tanpa pembayaran)' },
    { name: 'System', description: 'Health check' },
  ],
  security: [{ bearerAuth: [] }],
  paths: {
    '/health': {
      get: {
        tags: ['System'],
        summary: 'Cek server hidup',
        security: [],
        responses: {
          200: {
            description: 'OK',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { status: { type: 'string', example: 'ok' } } },
              },
            },
          },
        },
      },
    },

    // ================= AUTH =================
    '/api/auth/register': {
      post: {
        tags: ['Auth'],
        summary: 'Buat akun baru',
        security: [],
        requestBody: json('#/components/schemas/RegisterRequest', {
          umur: 7,
          nama: 'Budi',
          email: 'budi@mail.com',
          password: 'rahasia123',
        }),
        responses: {
          201: ok('#/components/schemas/Message', 'Akun berhasil dibuat'),
          400: common[400],
          409: err('Email sudah terdaftar'),
          429: err('Terlalu banyak percobaan'),
        },
      },
    },
    '/api/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Login dengan email & password',
        security: [],
        requestBody: json('#/components/schemas/LoginRequest', {
          email: 'budi@mail.com',
          password: 'rahasia123',
        }),
        responses: {
          200: ok('#/components/schemas/Session', 'Login berhasil'),
          400: common[400],
          401: err('Email atau password salah'),
          429: err('Terlalu banyak percobaan'),
        },
      },
    },
    '/api/auth/refresh': {
      post: {
        tags: ['Auth'],
        summary: 'Perpanjang sesi memakai refresh_token',
        security: [],
        requestBody: json('#/components/schemas/RefreshRequest'),
        responses: {
          200: ok('#/components/schemas/Session', 'Sesi diperbarui'),
          400: common[400],
          401: err('Sesi berakhir, silakan login lagi'),
        },
      },
    },
    '/api/auth/logout': {
      post: {
        tags: ['Auth'],
        summary: 'Logout (mencabut sesi)',
        responses: {
          200: ok('#/components/schemas/Message', 'Berhasil logout'),
          401: common[401],
        },
      },
    },

    // ================= BELAJAR =================
    '/api/lessons': {
      get: {
        tags: ['Belajar'],
        summary: 'Daftar unit/section beserta status tiap lesson',
        description:
          'Status: `completed` (selesai), `unlocked` (lesson berikutnya, hanya satu), `locked` (terkunci).',
        responses: {
          200: {
            description: 'Daftar section berurutan',
            content: {
              'application/json': {
                schema: { type: 'array', items: { $ref: '#/components/schemas/LessonSection' } },
              },
            },
          },
          401: common[401],
        },
      },
    },
    '/api/lessons/{id}/complete': {
      post: {
        tags: ['Belajar'],
        summary: 'Tandai lesson selesai',
        description:
          'Memperbarui "materi terakhir" dan "hari belajar berturut-turut". Lesson yang masih terkunci ditolak (403).',
        parameters: [uuidParam('ID lesson (ambil dari GET /api/lessons)')],
        requestBody: {
          required: false,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CompleteRequest' },
              example: { stars: 3 },
            },
          },
        },
        responses: {
          200: ok('#/components/schemas/LessonCompleted', 'Lesson selesai'),
          400: common[400],
          401: common[401],
          402: err('Lesson khusus Bebaca Premium'),
          403: err('Lesson masih terkunci'),
          404: err('Lesson tidak ditemukan'),
        },
      },
    },

    // ================= DONGENG =================
    '/api/stories': {
      get: {
        tags: ['Dongeng'],
        summary: 'Daftar kategori beserta dongengnya',
        responses: {
          200: {
            description: 'Daftar kategori',
            content: {
              'application/json': {
                schema: { type: 'array', items: { $ref: '#/components/schemas/StoryCategory' } },
              },
            },
          },
          401: common[401],
        },
      },
    },
    '/api/stories/{id}': {
      get: {
        tags: ['Dongeng'],
        summary: 'Detail dongeng + isi cerita',
        parameters: [uuidParam('ID dongeng (ambil dari GET /api/stories)')],
        responses: {
          200: ok('#/components/schemas/StoryDetail'),
          400: common[400],
          401: common[401],
          402: err('Dongeng khusus Bebaca Premium'),
          404: err('Dongeng tidak ditemukan'),
        },
      },
    },

    '/api/stories/{id}/progress': {
      post: {
        tags: ['Dongeng'],
        summary: 'Simpan progres Baca Bersama (halaman terakhir, selesai, bintang)',
        parameters: [uuidParam('ID dongeng')],
        requestBody: json('#/components/schemas/StoryProgressUpdate', { page: 4 }),
        responses: {
          200: ok('#/components/schemas/StoryProgress'),
          400: common[400],
          401: common[401],
          402: err('Dongeng khusus Bebaca Premium'),
          404: err('Dongeng tidak ditemukan'),
        },
      },
    },

    // ================= PROFILE =================
    '/api/profile': {
      get: {
        tags: ['Profile'],
        summary: 'Ambil profil pengguna',
        responses: { 200: ok('#/components/schemas/Profile'), 401: common[401] },
      },
      put: {
        tags: ['Profile'],
        summary: 'Ubah profil (kirim field yang berubah saja)',
        requestBody: json('#/components/schemas/ProfileUpdate', {
          nama: 'Budi Santoso',
          tanggalLahir: '2019-05-17',
          tingkatKesulitan: 'Sedang',
        }),
        responses: {
          200: ok('#/components/schemas/Profile', 'Profil terbaru'),
          400: common[400],
          401: common[401],
        },
      },
    },

    '/api/profile/avatar': {
      post: {
        tags: ['Profile'],
        summary: 'Unggah / ganti foto profil',
        description:
          'Kirim sebagai multipart/form-data dengan field `avatar`. JPEG, PNG, atau WebP, maksimal 2 MB. Tipe file dicek dari isinya. Foto lama otomatis dihapus.',
        requestBody: {
          required: true,
          content: {
            'multipart/form-data': {
              schema: {
                type: 'object',
                required: ['avatar'],
                properties: { avatar: { type: 'string', format: 'binary' } },
              },
            },
          },
        },
        responses: {
          200: ok('#/components/schemas/Profile', 'Profil terbaru (avatarUrl berisi foto baru)'),
          400: err('File bukan gambar JPEG/PNG/WebP'),
          401: common[401],
          413: err('Ukuran foto melebihi 2 MB'),
        },
      },
      delete: {
        tags: ['Profile'],
        summary: 'Hapus foto profil',
        responses: { 200: ok('#/components/schemas/Profile', 'Profil terbaru'), 401: common[401] },
      },
    },

    // ================= SETTINGS =================
    '/api/settings': {
      get: {
        tags: ['Settings'],
        summary: 'Ambil pengaturan + waktu belajar hari ini',
        responses: { 200: ok('#/components/schemas/Settings'), 401: common[401] },
      },
      put: {
        tags: ['Settings'],
        summary: 'Ubah pengaturan (kirim field yang berubah saja)',
        requestBody: json('#/components/schemas/SettingsUpdate', {
          soundEffect: false,
          parentalControl: true,
          timeLimitMinutes: 45,
          curfew: '19:30',
        }),
        responses: {
          200: ok('#/components/schemas/Settings', 'Pengaturan terbaru'),
          400: common[400],
          401: common[401],
        },
      },
    },
    '/api/settings/usage': {
      post: {
        tags: ['Settings'],
        summary: 'Tambah waktu belajar hari ini (menit)',
        requestBody: json('#/components/schemas/UsageRequest', { minutes: 10 }),
        responses: {
          200: ok('#/components/schemas/Settings', 'Pengaturan terbaru (timespent ter-update)'),
          400: common[400],
          401: common[401],
        },
      },
    },

    '/api/settings/parent-pin': {
      put: {
        tags: ['Settings'],
        summary: 'Buat / ganti PIN orang tua (wajib password akun)',
        requestBody: json('#/components/schemas/ParentPinUpdate', { pin: '2580', password: 'rahasia123' }),
        responses: {
          200: ok('#/components/schemas/Settings', 'Pengaturan terbaru (hasParentPin: true)'),
          400: common[400],
          401: common[401],
          403: err('Password akun salah'),
          429: err('Terlalu banyak percobaan'),
        },
      },
    },
    '/api/settings/parent-pin/verify': {
      post: {
        tags: ['Settings'],
        summary: 'Cek PIN orang tua',
        requestBody: json('#/components/schemas/ParentPinVerify', { pin: '2580' }),
        responses: {
          200: { description: 'PIN benar' },
          400: common[400],
          401: common[401],
          403: err('PIN salah'),
          409: err('PIN belum dibuat'),
          429: err('Terlalu banyak percobaan'),
        },
      },
    },

    // ================= ORANG TUA =================
    '/api/events': {
      post: {
        tags: ['Orang Tua'],
        summary: 'Kirim kejadian belajar dari aplikasi anak (maks. 50 per kiriman)',
        requestBody: json('#/components/schemas/EventBatch', {
          events: [{ type: 'answer', data: { letter: 'B', step: 'find', correct: false, picked: 'D' } }],
        }),
        responses: { 200: { description: 'Tersimpan' }, 400: common[400], 401: common[401] },
      },
    },
    '/api/report': {
      get: {
        tags: ['Orang Tua'],
        summary: 'Laporan Perkembangan mingguan',
        description: 'Akun gratis: ringkasan & aktivitas. Premium: + grafik harian (days), penguasaan huruf (letters), saran.',
        parameters: [{ name: 'week', in: 'query', schema: { type: 'integer', minimum: 0, default: 0 }, description: '0 = minggu ini, 1 = minggu lalu' }],
        responses: { 200: { description: 'Laporan' }, 401: common[401] },
      },
    },
    '/api/report/monitor-link': {
      get: { tags: ['Orang Tua'], summary: 'Status tautan Pantau Langsung', responses: { 200: { description: '{ active }' }, 401: common[401] } },
      post: { tags: ['Orang Tua'], summary: 'Buat tautan/QR Pantau Langsung baru (yang lama tidak berlaku)', responses: { 200: { description: '{ active, url }' }, 401: common[401] } },
      delete: { tags: ['Orang Tua'], summary: 'Cabut akses Pantau Langsung', responses: { 200: { description: '{ active: false }' }, 401: common[401] } },
    },

    // ================= PREMIUM =================
    '/api/subscription': {
      get: {
        tags: ['Premium'],
        summary: 'Status langganan Bebaca Premium',
        responses: { 200: ok('#/components/schemas/Subscription'), 401: common[401] },
      },
    },
    '/api/subscription/activate': {
      post: {
        tags: ['Premium'],
        summary: '[Simulasi] Jadikan akun premium tanpa bayar',
        description: 'Mode uji coba, tidak tersedia saat NODE_ENV=production.',
        requestBody: json('#/components/schemas/ActivatePremium', { plan: 'yearly' }),
        responses: {
          200: ok('#/components/schemas/Subscription', 'Status langganan terbaru'),
          400: common[400],
          401: common[401],
          403: err('Mode simulasi dimatikan di produksi'),
        },
      },
    },
    '/api/subscription/deactivate': {
      post: {
        tags: ['Premium'],
        summary: '[Simulasi] Kembalikan akun ke gratis',
        description: 'Mode uji coba, tidak tersedia saat NODE_ENV=production.',
        responses: {
          200: ok('#/components/schemas/Subscription', 'Status langganan terbaru'),
          401: common[401],
          403: err('Mode simulasi dimatikan di produksi'),
        },
      },
    },
  },

  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Tempel `access_token` dari /api/auth/login (tanpa kata "Bearer").',
      },
    },
    schemas: {
      Error: {
        type: 'object',
        properties: {
          message: { type: 'string', example: 'Email tidak valid' },
          errors: {
            type: 'array',
            description: 'Hanya ada pada error validasi (400)',
            items: {
              type: 'object',
              properties: {
                field: { type: 'string', example: 'email' },
                message: { type: 'string', example: 'Email tidak valid' },
              },
            },
          },
        },
      },
      Message: {
        type: 'object',
        properties: { message: { type: 'string', example: 'Berhasil' } },
      },

      RegisterRequest: {
        type: 'object',
        required: ['umur', 'nama', 'email', 'password'],
        properties: {
          umur: { type: 'integer', minimum: 1, maximum: 120, example: 7 },
          nama: { type: 'string', maxLength: 60, example: 'Budi' },
          email: { type: 'string', format: 'email', example: 'budi@mail.com' },
          password: { type: 'string', minLength: 6, maxLength: 72, example: 'rahasia123' },
        },
      },
      LoginRequest: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email', example: 'budi@mail.com' },
          password: { type: 'string', example: 'rahasia123' },
        },
      },
      RefreshRequest: {
        type: 'object',
        required: ['refresh_token'],
        properties: { refresh_token: { type: 'string' } },
      },
      Session: {
        type: 'object',
        properties: {
          access_token: { type: 'string', description: 'Dipakai di header Authorization' },
          refresh_token: { type: 'string' },
          expires_at: { type: 'integer', description: 'Unix timestamp (detik)', example: 1760400000 },
          user: {
            type: 'object',
            properties: {
              id: { type: 'string', format: 'uuid' },
              email: { type: 'string', example: 'budi@mail.com' },
            },
          },
        },
      },

      Lesson: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          title: { type: 'string', example: 'Huruf A' },
          status: { type: 'string', enum: ['locked', 'unlocked', 'completed'] },
          kind: {
            type: 'string',
            enum: ['letter', 'review', 'quiz', 'challenge'],
            description: 'letter = belajar 1 huruf, review = latihan, quiz = kuis, challenge = tantangan baca',
          },
          letters: { type: 'array', items: { type: 'string' }, example: ['A'] },
          stars: { type: 'integer', minimum: 0, maximum: 3, description: 'Bintang terbaik (0 jika belum selesai)' },
        },
      },
      LessonSection: {
        type: 'object',
        properties: {
          unit: { type: 'integer', example: 1 },
          section: { type: 'integer', example: 1 },
          title: { type: 'string', example: 'Huruf Vokal' },
          guide: { type: 'string', nullable: true, description: 'Isi tombol "Panduan"' },
          isPremium: { type: 'boolean', description: 'Section khusus Premium' },
          premiumLocked: { type: 'boolean', description: 'true = user belum Premium, lesson tidak bisa dikerjakan' },
          lessons: { type: 'array', items: { $ref: '#/components/schemas/Lesson' } },
        },
      },
      CompleteRequest: {
        type: 'object',
        properties: {
          stars: { type: 'integer', minimum: 0, maximum: 3, example: 3, description: 'Bintang yang didapat (default 1)' },
        },
      },
      LessonCompleted: {
        type: 'object',
        properties: {
          message: { type: 'string', example: 'Lesson selesai' },
          hariBerturut: { type: 'integer', example: 3 },
          stars: { type: 'integer', example: 3, description: 'Bintang terbaik untuk lesson ini' },
        },
      },

      Story: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          title: { type: 'string', example: 'Malin Kundang' },
          coverUrl: { type: 'string', nullable: true },
          isPremium: { type: 'boolean' },
          locked: { type: 'boolean', description: 'true = premium & user belum berlangganan' },
          progress: { $ref: '#/components/schemas/StoryProgress' },
        },
      },
      StoryProgress: {
        type: 'object',
        nullable: true,
        properties: {
          lastPage: { type: 'integer', example: 3 },
          completed: { type: 'boolean' },
          stars: { type: 'integer', minimum: 0, maximum: 3 },
          updatedAt: { type: 'string', format: 'date-time' },
        },
      },
      StoryProgressUpdate: {
        type: 'object',
        required: ['page'],
        properties: {
          page: { type: 'integer', minimum: 0 },
          completed: { type: 'boolean' },
          stars: { type: 'integer', minimum: 0, maximum: 3 },
        },
      },
      StoryCategory: {
        type: 'object',
        properties: {
          name: { type: 'string', example: 'Dongeng tradisional' },
          stories: { type: 'array', items: { $ref: '#/components/schemas/Story' } },
        },
      },
      StoryDetail: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          title: { type: 'string' },
          coverUrl: { type: 'string', nullable: true },
          videoUrl: { type: 'string', nullable: true, description: 'URL video (mp4) - tampil di atas cerita' },
          content: { type: 'string', nullable: true, description: 'Isi cerita; pisahkan paragraf dengan baris kosong' },
          moral: { type: 'string', nullable: true, description: 'Pesan dari cerita ini' },
          quiz: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                question: { type: 'string' },
                options: { type: 'array', items: { type: 'string' } },
                answer: { type: 'integer', description: 'index jawaban benar' },
              },
            },
          },
          pageImages: { type: 'array', items: { type: 'string' }, description: 'Gambar per halaman Baca Bersama' },
          progress: { $ref: '#/components/schemas/StoryProgress' },
        },
      },

      Profile: {
        type: 'object',
        properties: {
          nama: { type: 'string', example: 'Budi' },
          email: { type: 'string', example: 'budi@mail.com' },
          tanggalLahir: { type: 'string', format: 'date', nullable: true, example: '2019-05-17' },
          umur: { type: 'integer', nullable: true, example: 7 },
          tingkatKesulitan: { type: 'string', enum: ['Mudah', 'Sedang', 'Sulit'] },
          hariBerturut: { type: 'integer', example: 3 },
          materiTerakhir: { type: 'string', nullable: true, example: 'Unit 1, Section 1 - Huruf A' },
          avatarUrl: { type: 'string', nullable: true },
        },
      },
      ProfileUpdate: {
        type: 'object',
        description: 'Minimal satu field',
        properties: {
          nama: { type: 'string', maxLength: 60 },
          tanggalLahir: {
            type: 'string',
            format: 'date',
            nullable: true,
            example: '2019-05-17',
            description: 'Jika diisi, umur dihitung otomatis. null = hapus tanggal lahir.',
          },
          umur: { type: 'integer', minimum: 1, maximum: 120, description: 'Dipakai jika tanpa tanggal lahir' },
          tingkatKesulitan: { type: 'string', enum: ['Mudah', 'Sedang', 'Sulit'] },
        },
      },

      Settings: {
        type: 'object',
        properties: {
          soundEffect: { type: 'boolean' },
          animation: { type: 'boolean' },
          listeningExercise: { type: 'boolean' },
          parentalControl: { type: 'boolean' },
          timespentMinutes: { type: 'integer', description: 'Waktu belajar hari ini', example: 20 },
          timeLimitMinutes: { type: 'integer', description: '0 = tanpa batas', example: 60 },
          curfew: { type: 'string', description: 'Format HH:mm', example: '20:00' },
          hasParentPin: { type: 'boolean', description: 'PIN orang tua sudah dibuat' },
        },
      },
      SettingsUpdate: {
        type: 'object',
        description: 'Minimal satu field',
        properties: {
          soundEffect: { type: 'boolean' },
          animation: { type: 'boolean' },
          listeningExercise: { type: 'boolean' },
          parentalControl: { type: 'boolean' },
          timeLimitMinutes: { type: 'integer', minimum: 0, maximum: 1440 },
          curfew: { type: 'string', example: '20:00' },
        },
      },
      Subscription: {
        type: 'object',
        properties: {
          isPremium: { type: 'boolean', example: true },
          plan: { type: 'string', enum: ['monthly', 'yearly'], nullable: true },
          expiresAt: { type: 'string', format: 'date-time', nullable: true },
          autoRenew: { type: 'boolean' },
          platform: { type: 'string', enum: ['android', 'ios', 'manual'], nullable: true },
        },
      },
      ActivatePremium: {
        type: 'object',
        required: ['plan'],
        properties: { plan: { type: 'string', enum: ['monthly', 'yearly'] } },
      },
      ParentPinUpdate: {
        type: 'object',
        required: ['pin', 'password'],
        properties: {
          pin: { type: 'string', pattern: '^\d{4}$', example: '2580' },
          password: { type: 'string', description: 'Password akun Bebaca' },
        },
      },
      ParentPinVerify: {
        type: 'object',
        required: ['pin'],
        properties: { pin: { type: 'string', pattern: '^\d{4}$', example: '2580' } },
      },
      EventBatch: {
        type: 'object',
        required: ['events'],
        properties: {
          events: {
            type: 'array',
            maxItems: 50,
            items: {
              type: 'object',
              required: ['type'],
              properties: {
                type: { type: 'string', enum: ['app_open', 'tab', 'heartbeat', 'lesson_start', 'step', 'answer', 'lesson_complete', 'lesson_exit', 'story_open', 'story_page', 'story_read', 'story_complete'] },
                data: { type: 'object' },
                at: { type: 'string', format: 'date-time' },
              },
            },
          },
        },
      },
      UsageRequest: {
        type: 'object',
        required: ['minutes'],
        properties: { minutes: { type: 'integer', minimum: 1, maximum: 600, example: 10 } },
      },
    },
  },
};
