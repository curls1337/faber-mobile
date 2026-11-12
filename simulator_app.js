(() => {
  'use strict';

  const STORAGE_KEY = 'faber_mobile_sim_v1';

  const ROLES = {
    superadmin: { id: 'superadmin', label: '👑 Superadmin', desc: 'Akses penuh Swarm, Terminal, SOUL.md & Server' },
    operator: { id: 'operator', label: '⚡ Operator', desc: 'Akses Code Studio, Swarm & Monitoring Agen' },
    viewer: { id: 'viewer', label: '👁️ Client', desc: 'Preview Staging & Media Library (Read-Only)' }
  };

  const TAB_TITLES = {
    chat: 'Chat & Swarm',
    studio: 'Proyek & Code Studio',
    waroffice: '16 Agen & War Office',
    media: 'Media Library',
    system: 'Automations & System'
  };

  const DEFAULT_PROJECTS = [
    {
      slug: 'bca',
      name: 'BCA Wealth Portal',
      type: 'Staging App',
      status: 'live',
      url: 'https://webui.5nod.com/staging/bca/',
      branch: 'main',
      uptime: '99.98%',
      score: 97,
      files: {
        'index.html': '<!DOCTYPE html>\n<html lang="id">\n<head><title>BCA Wealth Portal</title></head>\n<body>\n  <main id="app">Dashboard Prioritas</main>\n</body>\n</html>',
        'app.js': 'export async function fetchPortfolio() {\n  const res = await fetch("/api/portfolio");\n  return res.json();\n}',
        'site.json': '{\n  "slug": "bca",\n  "public": true,\n  "category": "fintech"\n}'
      }
    },
    {
      slug: 'hermes-super-ai',
      name: 'Hermes Super AI',
      type: 'Cloud App',
      status: 'live',
      url: 'https://webui.5nod.com/staging/hermes-super-ai/',
      branch: 'prod',
      uptime: '99.95%',
      score: 99,
      files: {
        'index.html': '<div class="hermes-shell">Hermes Multi-Agent Orchestrator</div>',
        'orchestrator.ts': 'export const runSwarm = async (task: string) => {\n  return { status: "dispatched", agents: 16 };\n};',
        'site.json': '{\n  "slug": "hermes-super-ai",\n  "public": false,\n  "category": "ai-platform"\n}'
      }
    },
    {
      slug: 'spatial-3d-home',
      name: 'Spatial 3D Home',
      type: 'Staging App',
      status: 'building',
      url: 'https://webui.5nod.com/staging/spatial-3d-home/',
      branch: 'feat/webxr',
      uptime: '99.80%',
      score: 94,
      files: {
        'index.html': '<canvas id="xr-scene"></canvas>',
        'scene.js': 'import * as THREE from "three";\nconst scene = new THREE.Scene();\nscene.fog = new THREE.FogExp2(0x090d16, 0.02);',
        'site.json': '{\n  "slug": "spatial-3d-home",\n  "public": true,\n  "category": "spatial-3d"\n}'
      }
    },
    {
      slug: '_server',
      name: '_server (Core VPS)',
      type: 'Infrastructure',
      status: 'live',
      url: 'https://webui.5nod.com/',
      branch: 'systemd',
      uptime: '42d 11h',
      score: 100,
      files: {
        'ecosystem.config.js': 'module.exports = {\n  apps: [{ name: "faber-webui", script: "server.js", instances: 2 }]\n};',
        'nginx.conf': 'server {\n  listen 443 ssl http2;\n  server_name webui.5nod.com;\n}',
        '.env.example': 'PORT=3100\nNODE_ENV=production\nWAR_OFFICE_WS=wss://webui.5nod.com/ws'
      }
    }
  ];

  const DEFAULT_AGENTS = [
    { id: 'team-orchestrator', name: 'Orchestrator', role: 'Swarm Commander', status: 'working', task: 'Koordinasi sprint faber-mobile', model: 'gemini-3.8-flash', soul: '# SOUL.md — Orchestrator\nKoordinasikan 16 spesialis dengan delegasi paralel, verifikasi artifact nyata, dan jaga kualitas rilis.' },
    { id: 'team-architect', name: 'Architect', role: 'System Architect', status: 'online', task: 'Review kontrak API /api/bootstrap', model: 'claude-3.7-sonnet', soul: '# SOUL.md — Architect\nRancang arsitektur modular, batas layanan jelas, dan kontrak REST/WebSocket yang tangguh.' },
    { id: 'team-engineer', name: 'Engineer', role: 'Full-Stack Builder', status: 'working', task: 'Build VisionOS Mobile Simulator', model: 'gemini-3.8-flash', soul: '# SOUL.md — Engineer\nBangun kode bersih, multi-file terstruktur, dan selalu jalankan verifikasi sintaks serta runtime.' },
    { id: 'team-ui-ux', name: 'UI/UX Designer', role: 'VisionOS Design', status: 'online', task: 'Kalibrasi Liquid Glass blur & spacing', model: 'gpt-4.1', soul: '# SOUL.md — UI/UX\nUtamakan estetika Apple VisionOS Liquid Glass, safe-area iPhone, dan kontras tipografi tinggi.' },
    { id: 'team-qa-security', name: 'QA & Security', role: 'Audit & PenTest', status: 'online', task: 'Validasi RBAC & XSS sanitization', model: 'claude-3.7-sonnet', soul: '# SOUL.md — QA & Security\nVerifikasi setiap build dengan evidence aktual. Tolak klaim tanpa bukti uji.' },
    { id: 'team-devops', name: 'DevOps', role: 'CI/CD & VPS Ops', status: 'working', task: 'Monitor GitHub Actions .ipa/.apk', model: 'gemini-3.8-flash', soul: '# SOUL.md — DevOps\nOtomatiskan pipeline CI/CD, zero-downtime deploy, dan pemantauan resource VPS.' },
    { id: 'team-product', name: 'Product Lead', role: 'BRD & Roadmap', status: 'idle', task: 'Menunggu review backlog v1.1', model: 'gpt-4.1', soul: '# SOUL.md — Product Lead\nTerjemahkan kebutuhan bisnis menjadi acceptance criteria yang terukur.' },
    { id: 'team-mobile', name: 'Mobile Specialist', role: 'Flutter & SwiftUI', status: 'working', task: 'Sinkronisasi 5-tab Flutter client', model: 'gemini-3.8-flash', soul: '# SOUL.md — Mobile Specialist\nPastikan pengalaman 60fps di iOS & Android dengan gesture native.' },
    { id: 'team-backend', name: 'Backend API', role: 'Node & Postgres', status: 'online', task: 'Optimasi endpoint /api/sites/tree', model: 'gpt-4.1', soul: '# SOUL.md — Backend API\nBangun REST API idempoten, rate-limited, dan aman dari injeksi.' },
    { id: 'team-frontend', name: 'Frontend Web', role: 'SPA & PWA', status: 'online', task: 'Tuning service worker & cache', model: 'gemini-3.8-flash', soul: '# SOUL.md — Frontend Web\nOptimalkan LCP, aksesibilitas, dan responsivitas layar mobile hingga desktop.' },
    { id: 'team-data', name: 'Data Engineer', role: 'Telemetry & Metrics', status: 'idle', task: 'Agregasi log VPS harian', model: 'gemini-2.5-pro', soul: '# SOUL.md — Data Engineer\nJaga integritas pipeline telemetri dan metrik sistem real-time.' },
    { id: 'team-ai-ml', name: 'AI/ML Ops', role: 'Model Routing', status: 'online', task: 'Evaluasi latensi 9route', model: 'claude-3.7-sonnet', soul: '# SOUL.md — AI/ML Ops\nOptimalkan routing model, token budget, dan akurasi tool-calling.' },
    { id: 'team-researcher', name: 'Researcher', role: 'Tech Radar', status: 'idle', task: 'Riset iOS 18 WebKit API', model: 'gemini-2.5-pro', soul: '# SOUL.md — Researcher\nKumpulkan referensi teknis terverifikasi sebelum keputusan implementasi.' },
    { id: 'team-copywriter', name: 'Copywriter', role: 'Microcopy & Docs', status: 'online', task: 'Finalisasi README & release notes', model: 'gpt-4.1', soul: '# SOUL.md — Copywriter\nTulis mikro-kopi antarmuka yang ringkas, jelas, dan berorientasi aksi.' },
    { id: 'team-reviewer', name: 'Code Reviewer', role: 'Static Analysis', status: 'online', task: 'Cek lint & modularitas JS', model: 'claude-3.7-sonnet', soul: '# SOUL.md — Code Reviewer\nTinjau perubahan kode secara objektif, fokus pada bug, keamanan, dan maintainability.' },
    { id: 'team-ops', name: 'SRE / Ops', role: 'Incident Guard', status: 'online', task: 'Health check 5nod.com 24/7', model: 'gemini-3.8-flash', soul: '# SOUL.md — SRE / Ops\nJaga SLA 99.9%, alert dini anomali RAM/CPU, dan pemulihan otomatis.' }
  ];

  const DEFAULT_MEDIA = [
    { id: 'm1', type: 'gambar', title: 'VisionOS Liquid Glass Spec', meta: 'PNG • 1179×2556 • 1.8 MB', date: 'Hari ini, 09:15', gradient: 'linear-gradient(135deg, #4f46e5, #06b6d4)', icon: '🖼️', desc: 'Mockup resolusi retina iPhone 16 Pro dengan material Graphite Frost & Dynamic Island.' },
    { id: 'm2', type: 'video', title: 'Swarm Handover Demo 60fps', meta: 'MP4 • 00:42 • 14.2 MB', date: 'Hari ini, 08:40', gradient: 'linear-gradient(135deg, #7c3aed, #ec4899)', icon: '🎬', desc: 'Rekaman interaksi 16 agen saat melakukan deploy otomatis ke staging webui.5nod.com.' },
    { id: 'm3', type: 'audio', title: 'Morning War Office Briefing', meta: 'MP3 • 01:18 • TTS Neural', date: 'Kemarin, 18:20', gradient: 'linear-gradient(135deg, #059669, #0ea5e9)', icon: '🎧', desc: 'Ringkasan suara status VPS, build .ipa/.apk, dan metrik proyek aktif.' },
    { id: 'm4', type: 'pdf', title: 'Arsitektur Faber Mobile v1.0', meta: 'PDF • 12 Halaman • 2.4 MB', date: 'Kemarin, 14:05', gradient: 'linear-gradient(135deg, #d97706, #ef4444)', icon: '📄', desc: 'Spesifikasi teknis REST API, WebSocket War Office, dan skema keamanan RBAC.' },
    { id: 'm5', type: 'gambar', title: 'Bento Telemetry Dark OLED', meta: 'WEBP • 1080×1920 • 640 KB', date: '2 hari lalu', gradient: 'linear-gradient(135deg, #1d4ed8, #312e81)', icon: '📊', desc: 'Desain komponen grafik CPU, RAM, dan status cron job untuk layar System.' },
    { id: 'm6', type: 'audio', title: 'Alert Sound: Deploy Sukses', meta: 'WAV • 00:04 • Haptic Cue', date: '3 hari lalu', gradient: 'linear-gradient(135deg, #0d9488, #22c55e)', icon: '🔊', desc: 'Efek audio konfirmasi saat pipeline GitHub Actions selesai merilis artifact.' }
  ];

  const DEFAULT_CRONS = [
    { id: 'c1', name: 'Sync Staging Tree', schedule: '*/15 * * * *', active: true, lastRun: '2 menit lalu • OK' },
    { id: 'c2', name: 'VPS Telemetry Snapshot', schedule: '*/5 * * * *', active: true, lastRun: '45 detik lalu • OK' },
    { id: 'c3', name: 'Nightly Security Audit', schedule: '0 2 * * *', active: true, lastRun: '02:00 UTC • Passed' },
    { id: 'c4', name: 'Prune Build Cache', schedule: '0 4 * * 0', active: false, lastRun: 'Minggu lalu • Skipped' }
  ];

  const DEFAULT_SKILLS = [
    { id: 'ios-liquid-glass-pwa', name: 'ios-liquid-glass-pwa', desc: 'Safe-area & VisionOS glass tokens', active: true },
    { id: 'mobile-github-ci-factory', name: 'mobile-github-ci-factory', desc: 'Remote build .ipa & .apk', active: true },
    { id: 'team-engineer-core', name: 'team-engineer-core', desc: 'Full-stack & simulator verification', active: true },
    { id: 'webui-spa-deploy', name: 'webui-spa-performance-and-deploy', desc: 'Cache busting & staging deploy', active: true }
  ];

  const DEFAULT_CHATS = {
    bca: [
      { sender: 'agent', author: 'Orchestrator', time: '09:38', text: 'Swarm aktif pada proyek `bca`. 3 agen memantau endpoint portfolio & audit keamanan.' },
      { sender: 'user', author: 'Anda', time: '09:39', text: 'Cek kesiapan staging dan status QA terbaru.' },
      { sender: 'agent', author: 'QA & Security', time: '09:40', text: 'Staging `bca` sehat (HTTP 200, Lighthouse 97). RBAC & header CSP terverifikasi.' }
    ],
    'hermes-super-ai': [
      { sender: 'agent', author: 'AI/ML Ops', time: '09:30', text: '9route latency stabil di 142ms. 16 spesialis siap menerima delegasi.' }
    ],
    'spatial-3d-home': [
      { sender: 'agent', author: 'Frontend Web', time: '09:12', text: 'Branch `feat/webxr` sedang build shader Liquid Glass untuk scene ruang tamu.' }
    ],
    _server: [
      { sender: 'agent', author: 'SRE / Ops', time: '09:41', text: 'VPS webui.5nod.com uptime 42 hari. RAM 58% terpakai, PM2 cluster online.' }
    ]
  };

  function loadPersisted() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : {};
    } catch (_) {
      return {};
    }
  }

  const saved = loadPersisted();

  const state = {
    activeTab: saved.activeTab || 'chat',
    role: saved.role || 'superadmin',
    device: saved.device || 'ios',
    serverUrl: saved.serverUrl || (window.location.hostname.includes('5nod.com') ? window.location.origin : 'https://webui.5nod.com'),
    apiConnected: false,
    apiModeLabel: 'Demo Sandbox (Fallback)',
    lastSync: null,
    selectedProject: saved.selectedProject || 'bca',
    studioSubTab: 'preview',
    selectedFile: null,
    projects: DEFAULT_PROJECTS,
    agents: saved.agents || DEFAULT_AGENTS,
    agentFilter: 'all',
    agentQuery: '',
    mediaFilter: 'all',
    mediaItems: DEFAULT_MEDIA,
    crons: saved.crons || DEFAULT_CRONS,
    skills: saved.skills || DEFAULT_SKILLS,
    chats: saved.chats || DEFAULT_CHATS,
    terminalLog: [
      'faber@vps-5nod:~$ pm2 status',
      '┌────┬─────────────────┬─────────┬──────┬───────────┐',
      '│ id │ name            │ mode    │ cpu  │ memory    │',
      '├────┼─────────────────┼─────────┼──────┼───────────┤',
      '│ 0  │ faber-webui     │ cluster │ 2.4% │ 148.2 MB  │',
      '│ 1  │ war-office-ws   │ fork    │ 0.8% │  84.6 MB  │',
      '└────┴─────────────────┴─────────┴──────┴───────────┘',
      'Ketik perintah (help, ls, git status, free -h, clear)...'
    ],
    telemetry: {
      cpu: 24,
      ramUsed: 9.3,
      ramTotal: 16.0,
      disk: 41,
      uptime: '42d 11h 18m'
    },
    audioPlayingId: null,
    audioProgress: 34
  };

  function persistState() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({
        activeTab: state.activeTab,
        role: state.role,
        device: state.device,
        serverUrl: state.serverUrl,
        selectedProject: state.selectedProject,
        agents: state.agents,
        crons: state.crons,
        skills: state.skills,
        chats: state.chats
      }));
    } catch (_) {
      // Ignore quota errors
    }
  }

  // DOM References
  const appMain = document.getElementById('appMain');
  const headerTitle = document.getElementById('headerTitle');
  const headerKickerText = document.getElementById('headerKickerText');
  const headerConnDot = document.getElementById('headerConnDot');
  const deckConnDot = document.getElementById('deckConnDot');
  const deckApiLabel = document.getElementById('deckApiLabel');
  const headerRoleBadge = document.getElementById('headerRoleBadge');
  const ptrCapsule = document.getElementById('ptrCapsule');
  const toastPill = document.getElementById('toastPill');
  const modalBackdrop = document.getElementById('modalBackdrop');
  const modalSheet = document.getElementById('modalSheet');
  const dynamicIsland = document.getElementById('dynamicIsland');
  const diText = document.getElementById('diText');

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  let toastTimer = null;
  function showToast(msg, isWarn = false) {
    toastPill.textContent = msg;
    toastPill.style.background = isWarn ? 'rgba(245, 158, 11, 0.94)' : 'rgba(16, 185, 129, 0.94)';
    toastPill.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastPill.classList.remove('show'), 2200);
  }

  function updateClock() {
    const el = document.getElementById('iosClock');
    if (!el) return;
    const now = new Date();
    const hh = String(now.getHours()).padStart(2, '0');
    const mm = String(now.getMinutes()).padStart(2, '0');
    el.textContent = `${hh}:${mm}`;
  }

  function updateConnectionUI() {
    const isLive = state.apiConnected;
    headerConnDot.classList.toggle('amber', !isLive);
    deckConnDot.classList.toggle('amber', !isLive);
    headerKickerText.textContent = isLive
      ? `FABER STUDIO • LIVE (${new URL(state.serverUrl).host})`
      : 'FABER STUDIO • DEMO SANDBOX';
    deckApiLabel.textContent = isLive ? 'Terhubung ke API Live' : 'Demo Sandbox (Auth/Offline Fallback)';
    headerRoleBadge.textContent = ROLES[state.role].label;

    document.querySelectorAll('#deckRoleRow .deck-btn').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.role === state.role);
    });
  }

  async function fetchJsonWithTimeout(url, timeoutMs = 3000) {
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const res = await fetch(url, { credentials: 'include', signal: controller.signal });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } finally {
      clearTimeout(id);
    }
  }

  async function syncWithFaberApi(showFeedback = false) {
    ptrCapsule.classList.add('show');
    const base = state.serverUrl.replace(/\/+$/, '');
    let connectedAny = false;

    try {
      const [boot, tree, war] = await Promise.allSettled([
        fetchJsonWithTimeout(`${base}/api/bootstrap`),
        fetchJsonWithTimeout(`${base}/api/sites/tree`),
        fetchJsonWithTimeout(`${base}/api/war-office/state`)
      ]);

      if (boot.status === 'fulfilled' && boot.value) {
        connectedAny = true;
        if (boot.value.telemetry) {
          state.telemetry = { ...state.telemetry, ...boot.value.telemetry };
        }
      }

      if (tree.status === 'fulfilled' && tree.value) {
        connectedAny = true;
        const rawSites = Array.isArray(tree.value) ? tree.value : (tree.value.sites || tree.value.projects || []);
        if (rawSites.length > 0) {
          const mapped = rawSites.slice(0, 12).map((s) => ({
            slug: s.slug || s.name || 'app',
            name: s.title || s.name || s.slug || 'Faber App',
            type: s.type || 'Staging App',
            status: s.status || 'live',
            url: s.url || `${base}/staging/${s.slug || s.name}/`,
            branch: s.branch || 'main',
            uptime: s.uptime || '99.9%',
            score: s.score || 96,
            files: DEFAULT_PROJECTS[0].files
          }));
          state.projects = mapped;
        }
      }

      if (war.status === 'fulfilled' && war.value) {
        connectedAny = true;
        const rawAgents = Array.isArray(war.value) ? war.value : (war.value.agents || []);
        if (rawAgents.length > 0) {
          state.agents = rawAgents.slice(0, 16).map((a, idx) => ({
            id: a.id || `agent-${idx + 1}`,
            name: a.name || a.id || `Agent ${idx + 1}`,
            role: a.role || 'Specialist',
            status: a.status || 'online',
            task: a.task || a.currentTask || 'Standby di War Office',
            model: a.model || 'gemini-3.8-flash',
            soul: a.soul || `# SOUL.md — ${a.name || a.id}\nSpesialis aktif di Faber Studio War Office.`
          }));
        }
      }
    } catch (_) {
      connectedAny = false;
    }

    state.apiConnected = connectedAny;
    state.lastSync = new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
    setTimeout(() => ptrCapsule.classList.remove('show'), 450);

    updateConnectionUI();
    renderActiveTab();

    if (showFeedback) {
      showToast(
        connectedAny ? 'Tersinkronisasi dengan API Live' : 'Mode Demo Sandbox aktif (belum login)',
        !connectedAny
      );
    }
  }

  function setActiveTab(tab) {
    if (!TAB_TITLES[tab]) return;
    state.activeTab = tab;
    persistState();
    headerTitle.textContent = TAB_TITLES[tab];

    document.querySelectorAll('.bottom-tabbar .tab-item').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.tab === tab);
    });
    document.querySelectorAll('#deckTabRow .deck-btn').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.tab === tab);
    });

    appMain.scrollTop = 0;
    renderActiveTab();
  }

  function setRole(roleId) {
    if (!ROLES[roleId]) return;
    state.role = roleId;
    persistState();
    updateConnectionUI();
    renderActiveTab();
    showToast(`Role aktif: ${ROLES[roleId].label}`);
  }

  function openModal(htmlContent) {
    modalSheet.innerHTML = `<div class="sheet-handle"></div>${htmlContent}`;
    modalBackdrop.classList.add('open');
  }

  function closeModal() {
    modalBackdrop.classList.remove('open');
    modalSheet.innerHTML = '';
  }

  // ==================== TAB 1: CHAT & SWARM ====================
  function renderChatTab() {
    const projOptions = ['bca', 'hermes-super-ai', 'spatial-3d-home', '_server'];
    const msgs = state.chats[state.selectedProject] || [];
    const workingCount = state.agents.filter((a) => a.status === 'working').length;
    const isReadOnly = state.role === 'viewer';

    appMain.innerHTML = `
      <div class="glass-card glass-hero">
        <div style="display:flex;justify-content:space-between;align-items:center;gap:8px;">
          <div>
            <div style="font-size:11px;color:#c7d2fe;font-weight:600;">SWARM ORCHESTRATOR</div>
            <div style="font-size:16px;font-weight:700;margin-top:2px;">${workingCount} Agen Bekerja • 16 Total</div>
          </div>
          <span class="badge badge-emerald">● Live Swarm</span>
        </div>
        <div style="font-size:12px;color:var(--text-secondary);margin-top:8px;">
          Pilih workspace proyek lalu kirim instruksi langsung ke tim spesialis.
        </div>
      </div>

      <div class="section-row">
        <span class="section-title">Workspace Proyek</span>
        <span style="font-size:11px;color:var(--accent-cyan);font-family:var(--font-mono);">${escapeHtml(state.selectedProject)}</span>
      </div>

      <div class="chip-scroll" id="chatProjectChips">
        ${projOptions.map((slug) => `
          <button class="chip ${state.selectedProject === slug ? 'active' : ''}" data-proj="${slug}">
            ${slug === '_server' ? '🖥️ _server' : `📁 ${slug}`}
          </button>
        `).join('')}
      </div>

      <div class="chat-list" id="chatList">
        ${msgs.map((m) => `
          <div class="msg-row ${m.sender}">
            <div class="msg-meta">${escapeHtml(m.author)} • ${escapeHtml(m.time)}</div>
            <div class="msg-bubble">${escapeHtml(m.text)}</div>
          </div>
        `).join('')}
      </div>

      <div class="chip-scroll" id="quickPromptChips">
        <button class="chip" data-prompt="Audit Keamanan">🛡️ Audit Keamanan</button>
        <button class="chip" data-prompt="Deploy Staging">🚀 Deploy Staging</button>
        <button class="chip" data-prompt="Status 16 Agen">🤖 Status 16 Agen</button>
      </div>

      <div class="composer-box">
        <input
          type="text"
          id="chatInput"
          class="composer-input"
          placeholder="${isReadOnly ? 'Mode Client (Read-Only)' : `Instruksi ke swarm ${state.selectedProject}...`}"
          ${isReadOnly ? 'disabled' : ''}
        />
        <button class="send-btn" id="chatSendBtn" title="Kirim Instruksi" ${isReadOnly ? 'disabled style="opacity:0.45"' : ''}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
        </button>
      </div>
    `;

    document.querySelectorAll('#chatProjectChips .chip').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.selectedProject = btn.dataset.proj;
        persistState();
        renderChatTab();
      });
    });

    document.querySelectorAll('#quickPromptChips .chip').forEach((btn) => {
      btn.addEventListener('click', () => {
        if (isReadOnly) {
          showToast('Mode Client bersifat Read-Only', true);
          return;
        }
        sendSwarmMessage(btn.dataset.prompt);
      });
    });

    const input = document.getElementById('chatInput');
    const sendBtn = document.getElementById('chatSendBtn');
    const triggerSend = () => {
      const val = input.value.trim();
      if (!val) return;
      input.value = '';
      sendSwarmMessage(val);
    };
    sendBtn.addEventListener('click', triggerSend);
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') triggerSend();
    });
  }

  function sendSwarmMessage(text) {
    const slug = state.selectedProject;
    if (!state.chats[slug]) state.chats[slug] = [];
    const nowTime = new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });

    state.chats[slug].push({ sender: 'user', author: 'Anda', time: nowTime, text });
    persistState();
    renderChatTab();

    diText.textContent = `Swarm → ${slug}`;
    dynamicIsland.classList.add('expanded');

    setTimeout(() => {
      const replyTime = new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
      let replyAuthor = 'Orchestrator';
      let replyText = `Instruksi "${text}" diterima untuk ${slug}. Engineer & QA sedang memverifikasi artifact.`;

      if (text.toLowerCase().includes('keamanan') || text.toLowerCase().includes('audit')) {
        replyAuthor = 'QA & Security';
        replyText = `Audit ${slug} selesai: 0 celah kritis, RBAC guard aktif, header CSP & TLS valid.`;
      } else if (text.toLowerCase().includes('deploy')) {
        replyAuthor = 'DevOps';
        replyText = `Pipeline staging ${slug} sukses! Preview tersedia di webui.5nod.com/staging/${slug}/`;
      } else if (text.toLowerCase().includes('agen')) {
        replyAuthor = 'War Office';
        const working = state.agents.filter((a) => a.status === 'working').length;
        replyText = `Status 16 Agen: ${working} Working, ${16 - working} Online/Idle. Latensi rata-rata 138ms.`;
      }

      state.chats[slug].push({ sender: 'agent', author: replyAuthor, time: replyTime, text: replyText });
      persistState();
      if (state.activeTab === 'chat') {
        renderChatTab();
        appMain.scrollTop = appMain.scrollHeight;
      }
      setTimeout(() => {
        dynamicIsland.classList.remove('expanded');
        diText.textContent = 'Swarm Ready';
      }, 1500);
    }, 550);
  }

  // ==================== TAB 2: PROYEK & CODE STUDIO ====================
  function renderStudioTab() {
    const currentProj = state.projects.find((p) => p.slug === state.selectedProject) || state.projects[0];
    const fileNames = Object.keys(currentProj.files || {});
    if (!state.selectedFile || !currentProj.files[state.selectedFile]) {
      state.selectedFile = fileNames[0] || 'index.html';
    }
    const isReadOnly = state.role === 'viewer';

    let subContent = '';

    if (state.studioSubTab === 'preview') {
      subContent = `
        <div class="glass-card">
          <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:8px;">
            <div>
              <div style="font-size:15px;font-weight:700;">${escapeHtml(currentProj.name)}</div>
              <div style="font-size:11px;color:var(--accent-cyan);font-family:var(--font-mono);margin-top:2px;">${escapeHtml(currentProj.url)}</div>
            </div>
            <span class="badge ${currentProj.status === 'live' ? 'badge-emerald' : 'badge-amber'}">${escapeHtml(currentProj.status.toUpperCase())}</span>
          </div>
          <div class="bento-2" style="margin-top:12px;margin-bottom:0;">
            <div class="bento-tile" style="padding:10px;">
              <div style="font-size:10px;color:var(--text-muted);">LIGHTHOUSE</div>
              <div style="font-size:18px;font-weight:700;color:var(--emerald);margin-top:2px;">${currentProj.score}/100</div>
            </div>
            <div class="bento-tile" style="padding:10px;">
              <div style="font-size:10px;color:var(--text-muted);">BRANCH / UPTIME</div>
              <div style="font-size:13px;font-weight:700;margin-top:4px;">${escapeHtml(currentProj.branch)} • ${escapeHtml(currentProj.uptime)}</div>
            </div>
          </div>
          <div style="display:flex;gap:8px;margin-top:12px;">
            <button class="btn-primary" style="flex:1;" id="openPreviewBtn">🌐 Buka Staging URL</button>
            <button class="btn-ghost" id="switchToCodeBtn">📝 Edit Kode</button>
          </div>
        </div>
      `;
    } else if (state.studioSubTab === 'editor') {
      const codeContent = currentProj.files[state.selectedFile] || '';
      subContent = `
        <div class="chip-scroll" id="fileChips">
          ${fileNames.map((fn) => `
            <button class="chip ${state.selectedFile === fn ? 'active' : ''}" data-file="${escapeHtml(fn)}">📄 ${escapeHtml(fn)}</button>
          `).join('')}
        </div>
        <textarea class="code-area" id="codeEditorArea" ${isReadOnly ? 'readonly' : ''}>${escapeHtml(codeContent)}</textarea>
        <div style="display:flex;justify-content:space-between;align-items:center;margin-top:10px;gap:8px;">
          <span style="font-size:11px;color:var(--text-muted);">${isReadOnly ? 'Read-Only (Client)' : 'Siap disimpan ke workspace'}</span>
          <button class="btn-primary" id="saveCodeBtn" ${isReadOnly ? 'disabled style="opacity:0.45"' : ''}>💾 Simpan File</button>
        </div>
      `;
    } else {
      subContent = `
        <div class="terminal-box" id="terminalOutput">${escapeHtml(state.terminalLog.join('\n'))}</div>
        <div class="chip-scroll" id="termQuickCmds">
          <button class="chip" data-cmd="pm2 status">pm2 status</button>
          <button class="chip" data-cmd="git status">git status</button>
          <button class="chip" data-cmd="free -h">free -h</button>
          <button class="chip" data-cmd="clear">clear</button>
        </div>
        <div class="composer-box">
          <span style="color:var(--accent-cyan);font-family:var(--font-mono);font-size:12px;">$</span>
          <input type="text" id="terminalInput" class="composer-input" style="font-family:var(--font-mono);font-size:12px;" placeholder="${isReadOnly ? 'Terminal terkunci untuk Client' : 'Jalankan perintah VPS...'}" ${isReadOnly ? 'disabled' : ''} />
          <button class="send-btn" id="terminalRunBtn" ${isReadOnly ? 'disabled style="opacity:0.45"' : ''}>▶</button>
        </div>
      `;
    }

    appMain.innerHTML = `
      <div class="section-row" style="margin-top:4px;">
        <span class="section-title">Staging & Cloud Apps (${state.projects.length})</span>
      </div>

      <div class="chip-scroll" id="studioProjChips">
        ${state.projects.map((p) => `
          <button class="chip ${p.slug === currentProj.slug ? 'active' : ''}" data-slug="${escapeHtml(p.slug)}">
            ${p.status === 'live' ? '🟢' : '🟡'} ${escapeHtml(p.slug)}
          </button>
        `).join('')}
      </div>

      <div class="segmented" id="studioSeg">
        <button class="seg-btn ${state.studioSubTab === 'preview' ? 'active' : ''}" data-sub="preview">Preview</button>
        <button class="seg-btn ${state.studioSubTab === 'editor' ? 'active' : ''}" data-sub="editor">Code Editor</button>
        <button class="seg-btn ${state.studioSubTab === 'terminal' ? 'active' : ''}" data-sub="terminal">Terminal VPS</button>
      </div>

      ${subContent}
    `;

    document.querySelectorAll('#studioProjChips .chip').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.selectedProject = btn.dataset.slug;
        state.selectedFile = null;
        persistState();
        renderStudioTab();
      });
    });

    document.querySelectorAll('#studioSeg .seg-btn').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.studioSubTab = btn.dataset.sub;
        renderStudioTab();
      });
    });

    if (state.studioSubTab === 'preview') {
      document.getElementById('openPreviewBtn').addEventListener('click', () => {
        window.open(currentProj.url, '_blank', 'noopener,noreferrer');
      });
      document.getElementById('switchToCodeBtn').addEventListener('click', () => {
        state.studioSubTab = 'editor';
        renderStudioTab();
      });
    } else if (state.studioSubTab === 'editor') {
      document.querySelectorAll('#fileChips .chip').forEach((btn) => {
        btn.addEventListener('click', () => {
          state.selectedFile = btn.dataset.file;
          renderStudioTab();
        });
      });
      document.getElementById('saveCodeBtn').addEventListener('click', () => {
        const val = document.getElementById('codeEditorArea').value;
        currentProj.files[state.selectedFile] = val;
        showToast(`Disimpan: ${state.selectedFile}`);
      });
    } else {
      const termOut = document.getElementById('terminalOutput');
      termOut.scrollTop = termOut.scrollHeight;
      const runCmd = (cmd) => {
        const c = cmd.trim();
        if (!c) return;
        if (c === 'clear') {
          state.terminalLog = ['faber@vps-5nod:~$ # Terminal dibersihkan'];
          renderStudioTab();
          return;
        }
        state.terminalLog.push(`faber@vps-5nod:~$ ${c}`);
        if (c === 'help') {
          state.terminalLog.push('Perintah tersedia: pm2 status, git status, free -h, ls, uname -a, clear');
        } else if (c === 'git status') {
          state.terminalLog.push(`On branch ${currentProj.branch}\nnothing to commit, working tree clean`);
        } else if (c === 'free -h') {
          state.terminalLog.push(`Mem: ${state.telemetry.ramTotal}Gi total, ${state.telemetry.ramUsed}Gi used, ${(state.telemetry.ramTotal - state.telemetry.ramUsed).toFixed(1)}Gi free`);
        } else if (c === 'ls') {
          state.terminalLog.push(Object.keys(currentProj.files || {}).join('  '));
        } else if (c === 'pm2 status') {
          state.terminalLog.push('faber-webui [online] • 0 restarts • CPU 2.4%');
        } else {
          state.terminalLog.push(`Executed '${c}' (exit code 0)`);
        }
        renderStudioTab();
      };

      document.querySelectorAll('#termQuickCmds .chip').forEach((btn) => {
        btn.addEventListener('click', () => {
          if (isReadOnly) return showToast('Terminal terkunci untuk Client', true);
          runCmd(btn.dataset.cmd);
        });
      });

      const tInput = document.getElementById('terminalInput');
      const tBtn = document.getElementById('terminalRunBtn');
      tBtn.addEventListener('click', () => runCmd(tInput.value));
      tInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') runCmd(tInput.value);
      });
    }
  }

  // ==================== TAB 3: 16 AGEN & WAR OFFICE ====================
  function renderWarOfficeTab() {
    const filtered = state.agents.filter((a) => {
      const matchStatus = state.agentFilter === 'all' || a.status === state.agentFilter;
      const q = state.agentQuery.trim().toLowerCase();
      const matchQ = !q || a.name.toLowerCase().includes(q) || a.role.toLowerCase().includes(q) || a.task.toLowerCase().includes(q);
      return matchStatus && matchQ;
    });

    const workingCount = state.agents.filter((a) => a.status === 'working').length;
    const onlineCount = state.agents.filter((a) => a.status === 'online').length;

    appMain.innerHTML = `
      <div class="bento-2">
        <div class="bento-tile">
          <div style="font-size:10px;color:var(--text-muted);font-weight:700;">WORKING NOW</div>
          <div style="font-size:22px;font-weight:700;color:var(--accent-cyan);margin-top:2px;">${workingCount} Agen</div>
        </div>
        <div class="bento-tile">
          <div style="font-size:10px;color:var(--text-muted);font-weight:700;">STANDBY / ONLINE</div>
          <div style="font-size:22px;font-weight:700;color:var(--emerald);margin-top:2px;">${onlineCount} Agen</div>
        </div>
      </div>

      <input type="text" id="agentSearchInput" class="field-input" style="margin-bottom:10px;" placeholder="Cari 16 spesialis (mis. Engineer, Security)..." value="${escapeHtml(state.agentQuery)}" />

      <div class="chip-scroll" id="agentFilterChips">
        <button class="chip ${state.agentFilter === 'all' ? 'active' : ''}" data-filter="all">Semua (${state.agents.length})</button>
        <button class="chip ${state.agentFilter === 'working' ? 'active' : ''}" data-filter="working">⚡ Working</button>
        <button class="chip ${state.agentFilter === 'online' ? 'active' : ''}" data-filter="online">🟢 Online</button>
        <button class="chip ${state.agentFilter === 'idle' ? 'active' : ''}" data-filter="idle">🌙 Idle</button>
      </div>

      <div id="agentList">
        ${filtered.map((a) => {
          const badgeClass = a.status === 'working' ? 'badge-indigo' : (a.status === 'online' ? 'badge-emerald' : 'badge-slate');
          return `
            <div class="glass-card" style="padding:12px;margin-bottom:9px;cursor:pointer;" data-agent-id="${escapeHtml(a.id)}">
              <div style="display:flex;justify-content:space-between;align-items:center;gap:8px;">
                <div>
                  <div style="font-size:14px;font-weight:700;">${escapeHtml(a.name)}</div>
                  <div style="font-size:11px;color:var(--text-secondary);">${escapeHtml(a.role)} • <span style="font-family:var(--font-mono);">${escapeHtml(a.model)}</span></div>
                </div>
                <span class="badge ${badgeClass}">${escapeHtml(a.status.toUpperCase())}</span>
              </div>
              <div style="font-size:12px;color:var(--text-primary);margin-top:8px;opacity:0.9;">
                📌 ${escapeHtml(a.task)}
              </div>
              <div style="font-size:10.5px;color:var(--accent-cyan);margin-top:6px;font-weight:600;">
                Tap untuk edit SOUL.md →
              </div>
            </div>
          `;
        }).join('')}
      </div>
    `;

    document.getElementById('agentSearchInput').addEventListener('input', (e) => {
      state.agentQuery = e.target.value;
      renderWarOfficeTab();
      const el = document.getElementById('agentSearchInput');
      el.focus();
      el.setSelectionRange(el.value.length, el.value.length);
    });

    document.querySelectorAll('#agentFilterChips .chip').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.agentFilter = btn.dataset.filter;
        renderWarOfficeTab();
      });
    });

    document.querySelectorAll('#agentList .glass-card').forEach((card) => {
      card.addEventListener('click', () => openAgentSoulModal(card.dataset.agentId));
    });
  }

  function openAgentSoulModal(agentId) {
    const agent = state.agents.find((a) => a.id === agentId);
    if (!agent) return;
    const isReadOnly = state.role !== 'superadmin';

    openModal(`
      <div style="display:flex;justify-content:space-between;align-items:center;">
        <div>
          <div style="font-size:16px;font-weight:700;">Edit SOUL.md — ${escapeHtml(agent.name)}</div>
          <div style="font-size:11px;color:var(--text-secondary);">${escapeHtml(agent.id)} • ${escapeHtml(agent.role)}</div>
        </div>
        <button class="btn-ghost" style="padding:6px 10px;font-size:12px;" id="closeSoulModalBtn">✕</button>
      </div>
      <textarea id="soulTextarea" class="code-area" style="min-height:190px;" ${isReadOnly ? 'readonly' : ''}>${escapeHtml(agent.soul)}</textarea>
      <div style="font-size:11px;color:var(--text-muted);">
        ${isReadOnly ? 'Hanya Superadmin yang dapat mengubah SOUL.md agen.' : 'Perubahan SOUL.md langsung tersimpan di memori sesi & localStorage.'}
      </div>
      <div style="display:flex;gap:8px;">
        <button class="btn-ghost" style="flex:1;" id="cancelSoulBtn">Tutup</button>
        <button class="btn-primary" style="flex:1;" id="saveSoulBtn" ${isReadOnly ? 'disabled style="opacity:0.45"' : ''}>💾 Simpan SOUL.md</button>
      </div>
    `);

    document.getElementById('closeSoulModalBtn').addEventListener('click', closeModal);
    document.getElementById('cancelSoulBtn').addEventListener('click', closeModal);
    document.getElementById('saveSoulBtn').addEventListener('click', () => {
      agent.soul = document.getElementById('soulTextarea').value;
      persistState();
      closeModal();
      showToast(`SOUL.md ${agent.name} diperbarui`);
    });
  }

  // ==================== TAB 4: MEDIA LIBRARY ====================
  function renderMediaTab() {
    const filters = [
      { id: 'all', label: 'Semua' },
      { id: 'gambar', label: 'Gambar' },
      { id: 'video', label: 'Video' },
      { id: 'audio', label: 'Audio' },
      { id: 'pdf', label: 'PDF' }
    ];

    const items = state.mediaItems.filter((m) => state.mediaFilter === 'all' || m.type === state.mediaFilter);

    appMain.innerHTML = `
      <div class="chip-scroll" id="mediaFilterChips">
        ${filters.map((f) => `
          <button class="chip ${state.mediaFilter === f.id ? 'active' : ''}" data-type="${f.id}">${f.label}</button>
        `).join('')}
      </div>

      <div class="media-grid" id="mediaGrid">
        ${items.map((m) => `
          <div class="media-card" data-media-id="${m.id}">
            <div class="media-thumb" style="background:${m.gradient};">
              <span>${m.icon}</span>
              <span class="badge badge-slate" style="position:absolute;top:8px;right:8px;background:rgba(0,0,0,0.45);color:#fff;">${escapeHtml(m.type.toUpperCase())}</span>
            </div>
            <div class="media-body">
              <div style="font-size:12.5px;font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${escapeHtml(m.title)}</div>
              <div style="font-size:10px;color:var(--text-secondary);margin-top:3px;">${escapeHtml(m.meta)}</div>
              <div style="font-size:10px;color:var(--text-muted);margin-top:2px;">${escapeHtml(m.date)}</div>
            </div>
          </div>
        `).join('')}
      </div>
    `;

    document.querySelectorAll('#mediaFilterChips .chip').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.mediaFilter = btn.dataset.type;
        renderMediaTab();
      });
    });

    document.querySelectorAll('#mediaGrid .media-card').forEach((card) => {
      card.addEventListener('click', () => openMediaPlayerModal(card.dataset.mediaId));
    });
  }

  function openMediaPlayerModal(mediaId) {
    const item = state.mediaItems.find((m) => m.id === mediaId);
    if (!item) return;

    const isPlayable = item.type === 'audio' || item.type === 'video';
    const isPlaying = state.audioPlayingId === item.id;

    openModal(`
      <div style="display:flex;justify-content:space-between;align-items:center;">
        <span class="badge badge-indigo">${escapeHtml(item.type.toUpperCase())} PLAYER</span>
        <button class="btn-ghost" style="padding:6px 10px;font-size:12px;" id="closeMediaBtn">✕</button>
      </div>
      <div style="height:150px;border-radius:18px;background:${item.gradient};display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;">
        <div style="font-size:44px;">${item.icon}</div>
        <div style="font-size:12px;font-weight:600;background:rgba(0,0,0,0.45);padding:4px 10px;border-radius:999px;">
          ${isPlayable ? (isPlaying ? '▶ Sedang Diputar...' : '⏸ Siap Diputar') : escapeHtml(item.meta)}
        </div>
      </div>
      <div>
        <div style="font-size:16px;font-weight:700;">${escapeHtml(item.title)}</div>
        <div style="font-size:12px;color:var(--text-secondary);margin-top:4px;line-height:1.45;">${escapeHtml(item.desc)}</div>
      </div>
      ${isPlayable ? `
        <div>
          <div class="progress-track"><div class="progress-fill" id="mediaProgressFill" style="width:${state.audioProgress}%"></div></div>
          <div style="display:flex;justify-content:space-between;font-size:10px;color:var(--text-muted);margin-top:4px;">
            <span>00:${String(Math.floor(state.audioProgress * 0.45)).padStart(2, '0')}</span>
            <span>${escapeHtml(item.meta.split('•')[1] || '01:00')}</span>
          </div>
        </div>
        <div style="display:flex;gap:8px;">
          <button class="btn-primary" style="flex:1;" id="togglePlayBtn">${isPlaying ? '⏸ Jeda Pemutar' : '▶ Putar Media'}</button>
        </div>
      ` : `
        <button class="btn-primary" id="downloadMediaBtn">⬇ Unduh / Buka Dokumen</button>
      `}
    `);

    document.getElementById('closeMediaBtn').addEventListener('click', closeModal);
    const playBtn = document.getElementById('togglePlayBtn');
    if (playBtn) {
      playBtn.addEventListener('click', () => {
        state.audioPlayingId = state.audioPlayingId === item.id ? null : item.id;
        state.audioProgress = (state.audioProgress + 18) % 100 || 20;
        openMediaPlayerModal(item.id);
      });
    }
    const dlBtn = document.getElementById('downloadMediaBtn');
    if (dlBtn) {
      dlBtn.addEventListener('click', () => {
        showToast(`Membuka ${item.title}`);
        closeModal();
      });
    }
  }

  // ==================== TAB 5: AUTOMATIONS & SYSTEM ====================
  function renderSystemTab() {
    const t = state.telemetry;
    const ramPct = Math.round((t.ramUsed / t.ramTotal) * 100);
    const isAdmin = state.role === 'superadmin';

    appMain.innerHTML = `
      <div class="section-row" style="margin-top:4px;">
        <span class="section-title">VPS Telemetry (5nod.com)</span>
        <span class="badge badge-emerald">Uptime ${escapeHtml(t.uptime)}</span>
      </div>

      <div class="bento-2">
        <div class="bento-tile">
          <div style="display:flex;justify-content:space-between;font-size:11px;color:var(--text-secondary);">
            <span>CPU Load</span>
            <strong style="color:#fff;">${t.cpu}%</strong>
          </div>
          <div class="progress-track"><div class="progress-fill" style="width:${t.cpu}%"></div></div>
        </div>
        <div class="bento-tile">
          <div style="display:flex;justify-content:space-between;font-size:11px;color:var(--text-secondary);">
            <span>RAM Usage</span>
            <strong style="color:#fff;">${t.ramUsed}/${t.ramTotal} GB</strong>
          </div>
          <div class="progress-track"><div class="progress-fill" style="width:${ramPct}%"></div></div>
        </div>
      </div>

      <div class="section-row">
        <span class="section-title">Cron Jobs (${state.crons.length})</span>
      </div>
      <div class="glass-card" style="padding:10px 12px;">
        ${state.crons.map((c) => `
          <div style="display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-bottom:0.5px solid rgba(255,255,255,0.08);">
            <div>
              <div style="font-size:13px;font-weight:600;">${escapeHtml(c.name)}</div>
              <div style="font-size:10.5px;color:var(--text-muted);font-family:var(--font-mono);">${escapeHtml(c.schedule)} • ${escapeHtml(c.lastRun)}</div>
            </div>
            <button class="switch ${c.active ? 'on' : ''}" data-cron-id="${c.id}" aria-label="Toggle Cron"></button>
          </div>
        `).join('')}
      </div>

      <div class="section-row">
        <span class="section-title">Installed Skills</span>
      </div>
      <div class="glass-card" style="padding:10px 12px;">
        ${state.skills.map((sk) => `
          <div style="display:flex;justify-content:space-between;align-items:center;padding:7px 0;border-bottom:0.5px solid rgba(255,255,255,0.08);">
            <div>
              <div style="font-size:12.5px;font-weight:600;color:var(--accent-cyan);">${escapeHtml(sk.name)}</div>
              <div style="font-size:11px;color:var(--text-secondary);">${escapeHtml(sk.desc)}</div>
            </div>
            <button class="switch ${sk.active ? 'on' : ''}" data-skill-id="${sk.id}" aria-label="Toggle Skill"></button>
          </div>
        `).join('')}
      </div>

      <div class="section-row">
        <span class="section-title">Server Endpoint & Role</span>
      </div>
      <div class="glass-card">
        <label style="font-size:11px;color:var(--text-secondary);display:block;margin-bottom:6px;">URL Server Faber Studio</label>
        <input type="url" id="serverUrlInput" class="field-input" value="${escapeHtml(state.serverUrl)}" ${!isAdmin ? 'readonly' : ''} />
        <div style="display:flex;gap:8px;margin-top:10px;">
          <button class="btn-primary" style="flex:1;" id="saveServerBtn">Simpan & Test API</button>
        </div>
      </div>
    `;

    document.querySelectorAll('[data-cron-id]').forEach((sw) => {
      sw.addEventListener('click', () => {
        if (!isAdmin) return showToast('Hanya Superadmin dapat ubah Cron', true);
        const cron = state.crons.find((x) => x.id === sw.dataset.cronId);
        if (cron) {
          cron.active = !cron.active;
          persistState();
          renderSystemTab();
          showToast(`${cron.name}: ${cron.active ? 'Aktif' : 'Dijeda'}`);
        }
      });
    });

    document.querySelectorAll('[data-skill-id]').forEach((sw) => {
      sw.addEventListener('click', () => {
        if (!isAdmin) return showToast('Hanya Superadmin dapat ubah Skill', true);
        const skill = state.skills.find((x) => x.id === sw.dataset.skillId);
        if (skill) {
          skill.active = !skill.active;
          persistState();
          renderSystemTab();
          showToast(`Skill ${skill.name}: ${skill.active ? 'Enabled' : 'Disabled'}`);
        }
      });
    });

    document.getElementById('saveServerBtn').addEventListener('click', () => {
      const val = document.getElementById('serverUrlInput').value.trim();
      if (val) {
        state.serverUrl = val;
        persistState();
        syncWithFaberApi(true);
      }
    });
  }

  function renderActiveTab() {
    switch (state.activeTab) {
      case 'chat': return renderChatTab();
      case 'studio': return renderStudioTab();
      case 'waroffice': return renderWarOfficeTab();
      case 'media': return renderMediaTab();
      case 'system': return renderSystemTab();
      default: return renderChatTab();
    }
  }

  // ==================== EVENT BINDINGS ====================
  document.querySelectorAll('.bottom-tabbar .tab-item').forEach((btn) => {
    btn.addEventListener('click', () => setActiveTab(btn.dataset.tab));
  });

  document.querySelectorAll('#deckTabRow .deck-btn').forEach((btn) => {
    btn.addEventListener('click', () => setActiveTab(btn.dataset.tab));
  });

  document.querySelectorAll('#deckRoleRow .deck-btn').forEach((btn) => {
    btn.addEventListener('click', () => setRole(btn.dataset.role));
  });

  function setDevice(deviceId) {
    state.device = deviceId === 'android' ? 'android' : 'ios';
    const shell = document.querySelector('.iphone-shell');
    if (shell) shell.classList.toggle('is-android', state.device === 'android');
    document.querySelectorAll('#deckDeviceRow .deck-btn').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.device === state.device);
    });
    persistState();
    showToast(state.device === 'android' ? 'Frame: Android Material 3' : 'Frame: iPhone 16 Pro iOS');
  }

  document.querySelectorAll('#deckDeviceRow .deck-btn').forEach((btn) => {
    btn.addEventListener('click', () => setDevice(btn.dataset.device));
  });

  document.getElementById('headerRefreshBtn').addEventListener('click', () => syncWithFaberApi(true));
  document.getElementById('deckSyncBtn').addEventListener('click', () => syncWithFaberApi(true));

  headerRoleBadge.addEventListener('click', () => {
    openModal(`
      <div style="display:flex;justify-content:space-between;align-items:center;">
        <div style="font-size:16px;font-weight:700;">Quick Switch Role (RBAC)</div>
        <button class="btn-ghost" style="padding:6px 10px;font-size:12px;" id="closeRoleModalBtn">✕</button>
      </div>
      ${Object.values(ROLES).map((r) => `
        <button class="glass-card" style="width:100%;text-align:left;cursor:pointer;margin-bottom:8px;border-color:${state.role === r.id ? 'rgba(129,140,248,0.8)' : 'var(--glass-border)'};" data-pick-role="${r.id}">
          <div style="font-size:14px;font-weight:700;color:#fff;">${r.label} ${state.role === r.id ? '✓' : ''}</div>
          <div style="font-size:11.5px;color:var(--text-secondary);margin-top:3px;">${r.desc}</div>
        </button>
      `).join('')}
    `);
    document.getElementById('closeRoleModalBtn').addEventListener('click', closeModal);
    document.querySelectorAll('[data-pick-role]').forEach((btn) => {
      btn.addEventListener('click', () => {
        setRole(btn.dataset.pickRole);
        closeModal();
      });
    });
  });

  modalBackdrop.addEventListener('click', (e) => {
    if (e.target === modalBackdrop) closeModal();
  });

  dynamicIsland.addEventListener('click', () => {
    dynamicIsland.classList.toggle('expanded');
  });

  document.addEventListener('keydown', (e) => {
    if (['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName)) return;
    const map = { '1': 'chat', '2': 'studio', '3': 'waroffice', '4': 'media', '5': 'system' };
    if (map[e.key]) setActiveTab(map[e.key]);
  });

  // Boot
  updateClock();
  setInterval(updateClock, 30000);
  setDevice(state.device);
  updateConnectionUI();
  setActiveTab(state.activeTab);
  syncWithFaberApi(false);
})();
