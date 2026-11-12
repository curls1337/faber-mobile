# Faber Studio Mobile — VisionOS Interactive Simulator & Mobile Client

Aplikasi mobile **iOS (`.ipa`) & Android (`.apk`)** resmi untuk ekosistem **Faber Studio**, lengkap dengan **Interactive Mobile Web Simulator (`index.html` + `simulator_app.js`)** yang tayang sebagai preview 1:1 di `https://webui.5nod.com/staging/faber-mobile/`.

## Fitur Utama (5 Layar VisionOS Liquid Glass / Graphite Frost)

0. **Dual-Device Frame Switcher (iOS & Android)**
   - Mendukung switch 1-klik antara **iPhone 16 Pro (Titanium Bezel & Dynamic Island)** dan **Android (Material 3 Bezel & Punch Hole Camera)**.
   - Sesuai standar komersial skill `mobile-premium-ui-ux` untuk memvalidasi ergonomi safe-area dan gesture bar di kedua sistem operasi.

1. **Chat & Swarm**
   - Pemilihan workspace proyek (`bca`, `hermes-super-ai`, `spatial-3d-home`, `_server`).
   - Pengiriman instruksi langsung ke multi-agen swarm beserta status aktivitas *real-time* di Dynamic Island.
2. **Proyek & Code Studio**
   - Daftar Staging & Cloud Apps tersinkron dengan `/api/sites/tree`.
   - 3 sub-tab terintegrasi: **Preview** (Lighthouse & URL), **Code Editor** (edit & simpan file workspace), dan **Terminal VPS** (`pm2 status`, `git status`, `free -h`).
3. **16 Agen & War Office**
   - Daftar 16 spesialis Faber Studio (`working`, `online`, `idle`) dengan pencarian dan filter status.
   - **Modal Sheet Edit `SOUL.md`** untuk memodifikasi instruksi inti tiap agen.
4. **Media Library**
   - Filter media (`Semua`, `Gambar`, `Video`, `Audio`, `PDF`).
   - Pemutar media interaktif (*Audio/Video Player*, pratinjau dokumen & gambar).
5. **Automations & System**
   - Telemetri VPS (*CPU Load*, *RAM Usage*, *Uptime*).
   - Kontrol toggle **Cron Jobs** dan **Installed Skills**.
   - Pengaturan **Server Endpoint URL** serta **Quick Switch Role RBAC** (`👑 Superadmin`, `⚡ Operator`, `👁️ Client`).

## Integrasi API & Fallback Elegan

Saat dibuka di domain `webui.5nod.com` (atau server yang terkonfigurasi), simulator otomatis memanggil:
- `GET /api/bootstrap`
- `GET /api/sites/tree`
- `GET /api/war-office/state`

Jika sesi belum login (`401`/`403`) atau diakses secara offline/sandbox, simulator otomatis beralih ke **Demo Sandbox** dengan *seed data* realistis dan persistensi `localStorage` tanpa error.

## Struktur Direktori

```text
faber-mobile/
├── index.html          # Frame iPhone 16 Pro VisionOS Liquid Glass + Control Deck
├── simulator_app.js    # State management, 5 tab interaktif, API sync & RBAC
├── site.json           # Metadata staging Faber Studio
├── README.md           # Dokumentasi proyek
└── mobile/             # Proyek Flutter iOS & Android
    └── pubspec.yaml
```

## Verifikasi Lokal

Pastikan sintaks JavaScript valid sebelum deploy:

```bash
node --check simulator_app.js
```

Untuk preview lokal via HTTP static server:

```bash
npx serve . -p 4173
```
