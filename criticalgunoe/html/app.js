const hud = document.getElementById('hud');
const arenaEl = document.getElementById('arena');
const statusEl = document.getElementById('status');
const levelEl = document.getElementById('level');
const weaponEl = document.getElementById('weapon');
const playersEl = document.getElementById('players');
const timerEl = document.getElementById('timer');
const barEl = document.getElementById('bar');
const killsEl = document.getElementById('kills');
const deathsEl = document.getElementById('deaths');
const streakEl = document.getElementById('streak');
const scoreboardEl = document.getElementById('scoreboard');
const countdownEl = document.getElementById('countdown');
const killfeedEl = document.getElementById('killfeed');
const toastsEl = document.getElementById('toasts');
const menuEl = document.getElementById('menu');
const arenasEl = document.getElementById('arenas');

let timerInterval = null;
let endsAt = null;

function post(name, data = {}) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  }).catch(() => {});
}

function setHudVisible(visible) {
  hud.classList.toggle('hidden', !visible);
}

function formatTime(ms) {
  const secondsTotal = Math.max(0, Math.floor(ms / 1000));
  const minutes = String(Math.floor(secondsTotal / 60)).padStart(2, '0');
  const seconds = String(secondsTotal % 60).padStart(2, '0');
  return `${minutes}:${seconds}`;
}

function refreshTimer() {
  timerEl.textContent = endsAt ? formatTime(endsAt - Date.now()) : '--:--';
}

function showToast(payload = {}) {
  const item = document.createElement('div');
  item.className = `toast ${payload.kind || payload.type || 'info'}`;
  item.textContent = payload.message || '';
  toastsEl.appendChild(item);

  setTimeout(() => item.remove(), 4500);
}

function renderState(payload = {}) {
  const inMatch = payload.inMatch !== false && payload.status && payload.status !== 'idle';
  setHudVisible(Boolean(inMatch));

  if (!inMatch) {
    endsAt = null;
    refreshTimer();
    return;
  }

  const level = payload.level || 1;
  const maxLevel = payload.maxLevel || 1;
  const progress = Math.min(100, Math.max(0, (level / maxLevel) * 100));

  arenaEl.textContent = payload.arena?.label || 'GunGame';
  statusEl.textContent = payload.status || 'waiting';
  levelEl.textContent = `Level ${level}/${maxLevel}`;
  weaponEl.textContent = payload.weapon?.label || '-';
  playersEl.textContent = `${payload.playerCount || 0}/${payload.requiredPlayers || 0} spelers`;
  killsEl.textContent = payload.kills || 0;
  deathsEl.textContent = payload.deaths || 0;
  streakEl.textContent = payload.streak || 0;
  barEl.style.width = `${progress}%`;

  if (payload.timeRemainingMs) {
    endsAt = Date.now() + payload.timeRemainingMs;
    clearInterval(timerInterval);
    timerInterval = setInterval(refreshTimer, 1000);
  } else {
    endsAt = null;
  }

  refreshTimer();
}

function renderScoreboard(rows = []) {
  scoreboardEl.innerHTML = '';

  rows.slice(0, 8).forEach((row, index) => {
    const item = document.createElement('li');
    item.className = 'score-row';
    item.innerHTML = `
      <span class="rank">#${index + 1}</span>
      <span class="name"></span>
      <span class="level">${row.level}/${row.maxLevel}</span>
      <span class="kd">${row.kills}/${row.deaths}</span>
    `;
    item.querySelector('.name').textContent = row.name || `ID ${row.id}`;
    scoreboardEl.appendChild(item);
  });
}

function showCountdown(payload = {}) {
  const seconds = payload.seconds;

  if (seconds === null || seconds === undefined || seconds < 0) {
    countdownEl.classList.add('hidden');
    countdownEl.innerHTML = '';
    return;
  }

  countdownEl.innerHTML = `
    <div class="count-number">${seconds}</div>
    <div class="count-label">Start</div>
  `;
  countdownEl.classList.remove('hidden');

  if (seconds === 0) {
    setTimeout(() => {
      countdownEl.classList.add('hidden');
      countdownEl.innerHTML = '';
    }, 900);
  }
}

function addFeed(payload = {}) {
  const item = document.createElement('div');
  item.className = 'feed-item';
  item.textContent = payload.message || '';
  killfeedEl.prepend(item);

  setTimeout(() => item.remove(), 7000);
}

function renderMenu(payload = {}) {
  const open = payload.open !== false;
  menuEl.classList.toggle('hidden', !open);
  arenasEl.innerHTML = '';

  (payload.arenas || []).forEach((arena) => {
    const button = document.createElement('button');
    button.className = 'arena';
    button.type = 'button';
    button.innerHTML = `
      <strong></strong>
      <span>${arena.id}</span>
      <small>Radius ${Math.round(arena.radius || 0)}m</small>
    `;
    button.querySelector('strong').textContent = arena.label || arena.id;
    button.addEventListener('click', () => post('join', { arena: arena.id }));
    arenasEl.appendChild(button);
  });
}

function finish(payload = {}) {
  if (payload.winnerName) {
    showToast({
      kind: 'success',
      message: `${payload.winnerName} wint ${payload.arena?.label || 'GunGame'}!`,
    });
  }

  if (payload.scoreboard) {
    renderScoreboard(payload.scoreboard);
  }
}

document.getElementById('close').addEventListener('click', () => post('close'));
document.getElementById('leave').addEventListener('click', () => post('leave'));

window.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    post('close');
  }
});

window.addEventListener('message', (event) => {
  const message = event.data || {};
  const payload = message.payload || {};

  if (message.action === 'state') {
    renderState(payload);
  } else if (message.action === 'scoreboard') {
    renderScoreboard(payload);
  } else if (message.action === 'countdown') {
    showCountdown(payload);
  } else if (message.action === 'feed') {
    addFeed(payload);
  } else if (message.action === 'toast') {
    showToast(payload);
  } else if (message.action === 'menu') {
    renderMenu(payload);
  } else if (message.action === 'finish') {
    finish(payload);
  } else if (message.action === 'hide') {
    setHudVisible(false);
    showCountdown({ seconds: null });
  }
});
