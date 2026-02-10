BountyBoard.CachedBounties = BountyBoard.CachedBounties or {}
BountyBoard.MenuFrame = nil
BountyBoard.DHTML = nil

-- Properly escape a string for safe embedding inside a JS string literal
local function SafeJSString(str)
    str = str or ""
    str = string.gsub(str, "\\", "\\\\")
    str = string.gsub(str, "'", "\\'")
    str = string.gsub(str, '"', '\\"')
    str = string.gsub(str, "\n", "\\n")
    str = string.gsub(str, "\r", "\\r")
    str = string.gsub(str, "</", "<\\/")
    return str
end

-------------------------------------------------
-- HTML Template
-------------------------------------------------

local HTML_TEMPLATE = [==[
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<script src="https://cdn.tailwindcss.com"></script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<script>
tailwind.config = {
    theme: {
        extend: {
            colors: {
                'bb': {
                    'bg': '#{{BgPage}}',
                    'card': '#{{BgCard}}',
                    'card2': '#{{BgCardHover}}',
                    'border': '#{{Border}}',
                    'border2': '#{{BorderHover}}',
                    'amber': '#{{Accent}}',
                    'amberdark': '#{{AccentHover}}',
                    'amberlight': '#{{AccentLight}}',
                    'title': '#{{TextTitle}}',
                    'text': '#{{TextPrimary}}',
                    'text2': '#{{TextSecondary}}',
                }
            }
        }
    }
}
</script>
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap');
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; outline: none !important; }
    *:focus, *:focus-visible, *:active { outline: none !important; box-shadow: none !important; -webkit-tap-highlight-color: transparent; }
    body { background: transparent; font-family: 'Inter', sans-serif; color: #{{TextPrimary}}; overflow: hidden; }
    ::-webkit-scrollbar { width: 4px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #{{Border}}; border-radius: 4px; }
    ::-webkit-scrollbar-thumb:hover { background: #{{BorderHover}}; }
    @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
    @keyframes slideUp { from { opacity: 0; transform: translateY(30px) scale(0.97); } to { opacity: 1; transform: translateY(0) scale(1); } }
    @keyframes overlayIn { from { opacity: 0; } to { opacity: 1; } }
    select option { background: #{{BgCard}}; color: #{{TextPrimary}}; }
    @keyframes toastIn { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
    @keyframes toastOut { from { transform: translateX(0); opacity: 1; } to { transform: translateX(100%); opacity: 0; } }
    .toast-in { animation: toastIn 0.25s ease forwards; }
    .toast-out { animation: toastOut 0.3s ease forwards; }
</style>
</head>
<body>

<div id="app" class="h-screen flex flex-col animate-[overlayIn_0.2s_ease]" style="background: rgba(0,0,0,0.8);">
  <div class="max-w-7xl w-full mx-auto flex flex-col flex-1 overflow-hidden">

    <!-- Header (logo + tabs + close) -->
    <div class="flex items-center justify-between px-8 py-4 border-b border-white/10">
        <div class="flex items-center gap-3 shrink-0">
            <div class="w-10 h-10 rounded-full bg-bb-amber/20 flex items-center justify-center">
                <i class="fa-solid fa-fire text-bb-amber text-lg"></i>
            </div>
            <div>
                <h1 class="text-xl font-extrabold text-bb-amber tracking-wide leading-tight">{{Title}}</h1>
                <p class="text-[10px] text-bb-text2 tracking-widest">{{Subtitle}}</p>
            </div>
        </div>
        <div class="flex items-center gap-1">
            <button class="rounded-full bg-bb-amber text-bb-bg border border-bb-amber px-4 py-1.5 text-sm font-semibold flex items-center gap-2 transition-all duration-150 hover:opacity-90" onclick="switchTab('active')" id="tab-active">
                <i class="fa-solid fa-crosshairs text-xs"></i> {{TabActive}}
            </button>
            <button class="rounded-full bg-bb-card text-bb-text2 border border-bb-border px-4 py-1.5 text-sm font-medium flex items-center gap-2 transition-all duration-150 hover:bg-bb-card2 hover:text-bb-text hover:border-bb-border2" onclick="switchTab('place')" id="tab-place">
                <i class="fa-solid fa-circle-plus text-xs"></i> {{TabPlace}}
            </button>
            <button class="rounded-full bg-bb-card text-bb-text2 border border-bb-border px-4 py-1.5 text-sm font-medium flex items-center gap-2 transition-all duration-150 hover:bg-bb-card2 hover:text-bb-text hover:border-bb-border2" onclick="switchTab('leaderboard')" id="tab-leaderboard">
                <i class="fa-solid fa-trophy text-xs"></i> {{TabLeaderboard}}
            </button>
            <button class="rounded-full bg-bb-card text-bb-text2 border border-bb-border px-4 py-1.5 text-sm font-medium flex items-center gap-2 transition-all duration-150 hover:bg-bb-card2 hover:text-bb-text hover:border-bb-border2" onclick="switchTab('my')" id="tab-my">
                <i class="fa-solid fa-user text-xs"></i> {{TabMy}}
            </button>
        </div>
        <button onclick="bb.closeMenu()" class="w-9 h-9 rounded-lg flex items-center justify-center bg-black text-white hover:bg-white hover:text-black transition shrink-0">
            <i class="fa-solid fa-xmark text-lg"></i>
        </button>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-hidden">

        <!-- Active Bounties -->
        <div id="page-active" class="h-full overflow-y-auto px-8 py-6">
            <div class="flex items-center justify-between mb-5">
                <h2 class="text-lg font-bold text-bb-title flex items-center gap-2">
                    <i class="fa-solid fa-crosshairs text-bb-amber text-sm"></i> {{ActiveTitle}}
                </h2>
                <span id="bounty-count" class="bg-green-500/20 text-green-400 text-xs font-bold px-2.5 py-0.5 rounded-full">0</span>
            </div>
            <div id="bounty-grid" class="grid grid-cols-3 gap-5">
            </div>
            <div id="no-bounties" class="hidden text-center text-bb-text2 py-20">
                <i class="fa-solid fa-ghost text-5xl mb-4 block"></i>
                <p class="text-sm">{{NoBounties}}</p>
            </div>
        </div>

        <!-- Place Bounty -->
        <div id="page-place" class="h-full overflow-y-auto px-8 py-6 hidden">
            <div class="max-w-4xl mx-auto flex gap-8">
                <!-- Left: Form -->
                <div class="flex-1">
                    <h2 class="text-lg font-bold text-bb-title flex items-center gap-2 mb-6">
                        <i class="fa-solid fa-circle-plus text-bb-amber text-sm"></i> {{PlaceTitle}}
                    </h2>
                    <div class="border border-bb-border rounded-xl p-6 border-l-4 border-l-bb-amber bg-bb-card/50">

                        <div class="mb-6">
                            <label class="block text-sm font-semibold text-bb-text2 mb-2">{{FieldTarget}}</label>
                            <select id="target-select" class="w-full bg-bb-card border border-bb-border rounded-lg px-4 py-3 text-sm text-bb-text transition-colors duration-150 focus:border-bb-amber">
                                <option value="">{{PlaceholderTarget}}</option>
                            </select>
                        </div>

                        <div class="mb-6">
                            <label class="block text-sm font-semibold text-bb-text2 mb-2">{{FieldAmount}}</label>
                            <input id="amount-input" type="number" min="{{MinBounty}}" max="{{MaxBounty}}" step="1" value="{{MinBounty}}" placeholder="{{PlaceholderAmount}}" class="w-full bg-bb-card border border-bb-border rounded-lg px-4 py-3 text-sm text-bb-text transition-colors duration-150 focus:border-bb-amber" />
                        </div>

                        <div class="mb-6">
                            <label class="block text-sm font-semibold text-bb-text2 mb-2">{{FieldReason}}</label>
                            <textarea id="reason-input" rows="3" placeholder="{{PlaceholderReason}}" class="w-full bg-bb-card border border-bb-border rounded-lg px-4 py-3 text-sm text-bb-text resize-none transition-colors duration-150 focus:border-bb-amber"></textarea>
                        </div>


                        <button onclick="submitBounty()" class="w-full bg-bb-amber text-bb-bg font-bold py-3 rounded-lg text-sm flex items-center justify-center gap-2 transition-all duration-150 hover:bg-bb-amberdark active:scale-[0.98]">
                            <i class="fa-solid fa-paper-plane"></i> {{SubmitButton}}
                        </button>
                    </div>
                </div>

                <!-- Right: Player Preview -->
                <div id="player-preview" class="w-72 hidden">
                    <h2 class="text-lg font-bold text-bb-title flex items-center gap-2 mb-6">
                        <i class="fa-solid fa-eye text-bb-amber text-sm"></i> Preview
                    </h2>
                    <div class="border border-bb-border rounded-xl bg-bb-card/50 overflow-hidden">
                        <div id="model-zone" class="h-64 bg-bb-bg/30 relative">
                            <div class="absolute inset-0 flex items-center justify-center text-bb-text2 text-xs">
                                <i class="fa-solid fa-spinner fa-spin mr-2"></i> Loading...
                            </div>
                        </div>
                        <div class="p-4 border-t border-bb-border">
                            <div id="preview-name" class="text-lg font-bold text-bb-text"></div>
                            <div id="preview-job" class="text-sm text-bb-text2 mt-1"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Leaderboard -->
        <div id="page-leaderboard" class="h-full overflow-y-auto px-8 py-6 hidden">
            <div class="flex items-center justify-between mb-5">
                <h2 class="text-lg font-bold text-bb-title flex items-center gap-2">
                    <i class="fa-solid fa-trophy text-bb-amber text-sm"></i> {{LeaderboardTitle}}
                </h2>
                <button onclick="refreshLeaderboard()" id="btn-refresh-lb" class="px-3 py-1.5 rounded-lg text-xs font-bold bg-white text-gray-900 border border-white/80 hover:bg-gray-100 transition flex items-center gap-1.5">
                    <i class="fa-solid fa-arrows-rotate text-[10px]"></i> Refresh
                </button>
            </div>

            <!-- Category pills -->
            <div class="flex gap-2 mb-6">
                <button onclick="switchLeaderboardCategory('bountiesCompleted')" id="lb-pill-bountiesCompleted" class="px-4 py-1.5 rounded-full text-sm font-semibold bg-bb-amber text-bb-bg border border-bb-amber transition-all duration-150">
                    <i class="fa-solid fa-crosshairs text-xs mr-1"></i> {{LbTopHunters}}
                </button>
                <button onclick="switchLeaderboardCategory('totalEarned')" id="lb-pill-totalEarned" class="px-4 py-1.5 rounded-full text-sm font-medium bg-bb-card text-bb-text2 border border-bb-border transition-all duration-150 hover:bg-bb-card2 hover:text-bb-text hover:border-bb-border2">
                    <i class="fa-solid fa-coins text-xs mr-1"></i> {{LbTopEarners}}
                </button>
                <button onclick="switchLeaderboardCategory('totalSpent')" id="lb-pill-totalSpent" class="px-4 py-1.5 rounded-full text-sm font-medium bg-bb-card text-bb-text2 border border-bb-border transition-all duration-150 hover:bg-bb-card2 hover:text-bb-text hover:border-bb-border2">
                    <i class="fa-solid fa-hand-holding-dollar text-xs mr-1"></i> {{LbTopSpenders}}
                </button>
            </div>

            <!-- Leaderboard table -->
            <div id="lb-table" class="space-y-2"></div>
            <div id="lb-no-data" class="hidden text-center text-bb-text2 py-16">
                <i class="fa-solid fa-chart-simple text-4xl mb-4 block"></i>
                <p class="text-sm">{{LbNoData}}</p>
            </div>

            <!-- Player position (if not in top 10) -->
            <div id="lb-my-position" class="hidden mt-4 border-t border-bb-border pt-4"></div>
        </div>

        <!-- My Bounties -->
        <div id="page-my" class="h-full overflow-y-auto px-8 py-6 hidden">
            <div class="flex items-center justify-between mb-5">
                <h2 class="text-lg font-bold text-bb-title flex items-center gap-2">
                    <i class="fa-solid fa-user text-bb-amber text-sm"></i> {{MyTitle}}
                </h2>
                <button onclick="refreshMyStats()" id="btn-refresh-my" class="px-3 py-1.5 rounded-lg text-xs font-bold bg-white text-gray-900 border border-white/80 hover:bg-gray-100 transition flex items-center gap-1.5">
                    <i class="fa-solid fa-arrows-rotate text-[10px]"></i> Refresh
                </button>
            </div>

            <!-- Persistent Stats (3x2 grid) -->
            <div class="grid grid-cols-3 gap-4 mb-6">
                <div class="border border-bb-border border-l-4 border-l-bb-amber rounded-lg p-4 text-center bg-bb-card/50">
                    <div id="stat-placed" class="text-2xl font-bold text-bb-text">0</div>
                    <div class="text-xs text-bb-text2 mt-1">{{StatPlaced}}</div>
                </div>
                <div class="border border-bb-border border-l-4 border-l-bb-amber rounded-lg p-4 text-center bg-bb-card/50">
                    <div id="stat-completed" class="text-2xl font-bold text-bb-text">0</div>
                    <div class="text-xs text-bb-text2 mt-1">{{StatCompleted}}</div>
                </div>
                <div class="border border-bb-border border-l-4 border-l-bb-amber rounded-lg p-4 text-center bg-bb-card/50">
                    <div id="stat-survived" class="text-2xl font-bold text-bb-text">0</div>
                    <div class="text-xs text-bb-text2 mt-1">{{StatSurvived}}</div>
                </div>
                <div class="border border-bb-border border-l-4 border-l-bb-amber rounded-lg p-4 text-center bg-bb-card/50">
                    <div id="stat-earned" class="text-2xl font-bold text-bb-amber">0</div>
                    <div class="text-xs text-bb-text2 mt-1">{{StatEarned}}</div>
                </div>
                <div class="border border-bb-border border-l-4 border-l-bb-amber rounded-lg p-4 text-center bg-bb-card/50">
                    <div id="stat-spent" class="text-2xl font-bold text-bb-amber">0</div>
                    <div class="text-xs text-bb-text2 mt-1">{{StatSpent}}</div>
                </div>
                <div class="border border-bb-border border-l-4 border-l-bb-amber rounded-lg p-4 text-center bg-bb-card/50">
                    <div id="stat-streak" class="text-2xl font-bold text-bb-text">0</div>
                    <div class="text-xs text-bb-text2 mt-1">{{StatBestStreak}}</div>
                </div>
            </div>

            <!-- Hunter Rank -->
            <h3 class="text-xs font-bold text-bb-text2 tracking-wider mb-3 flex items-center gap-2">
                <i class="fa-solid fa-medal text-bb-amber"></i> {{SectionRank}}
            </h3>
            <div id="rank-section" class="border border-bb-border rounded-xl p-5 bg-bb-card/50 mb-6">
                <div class="flex items-center gap-4 mb-3">
                    <div id="rank-icon" class="w-12 h-12 rounded-full bg-bb-amber/20 flex items-center justify-center">
                        <i class="fa-solid fa-seedling text-bb-amber text-xl"></i>
                    </div>
                    <div>
                        <div id="rank-name" class="text-lg font-bold text-bb-amber">Rookie</div>
                        <div id="rank-progress-text" class="text-xs text-bb-text2">0 / 5 kills to next rank</div>
                    </div>
                </div>
                <div class="w-full bg-bb-bg rounded-full h-2.5 overflow-hidden">
                    <div id="rank-progress-bar" class="h-full bg-bb-amber rounded-full transition-all duration-500" style="width: 0%"></div>
                </div>
            </div>

            <!-- Placed -->
            <h3 class="text-xs font-bold text-bb-text2 tracking-wider mb-3 flex items-center gap-2">
                <i class="fa-solid fa-circle-plus text-bb-amber"></i> {{SectionPlaced}}
            </h3>
            <div id="my-placed" class="space-y-2 mb-6"></div>
            <div id="no-placed" class="hidden text-bb-text2 text-sm pl-2 mb-6">{{NoPlaced}}</div>

            <!-- Tracking -->
            <h3 class="text-xs font-bold text-bb-text2 tracking-wider mb-3 flex items-center gap-2">
                <i class="fa-solid fa-eye text-bb-amber"></i> {{SectionTracking}}
            </h3>
            <div id="my-tracking" class="space-y-2 mb-4"></div>
            <div id="no-tracking" class="hidden text-bb-text2 text-sm pl-2">{{NoTracking}}</div>
        </div>

    </div>
  </div>
</div>

<!-- Toast notifications -->
<div id="toast-container" class="fixed top-4 right-4 flex flex-col gap-2 z-[9999] max-w-sm"></div>

<!-- Modal overlay -->
<div id="modal" class="hidden fixed inset-0 bg-black/60 z-50 flex items-center justify-center animate-[fadeIn_0.15s_ease]" onclick="closeModal(event)">
    <div id="modal-card" class="animate-[slideUp_0.2s_ease] bg-bb-card border border-bb-border rounded-2xl w-[380px] overflow-hidden" onclick="event.stopPropagation()">
    </div>
</div>

<script>
// --- Config (injected from Lua) ---
const CFG_SEVERITY_CRITICAL = {{SeverityCritical}};
const CFG_SEVERITY_HIGH = {{SeverityHigh}};
const CFG_SEVERITY_MID = {{SeverityMid}};
const CFG_CURRENCY_SYMBOL = '{{CurrencySymbol}}';
const CFG_CURRENCY_NAME = '{{CurrencyName}}';
const CFG_DEFAULT_REASON = '{{DefaultReason}}';
const CFG_MIN_BOUNTY = {{MinBounty}};
const CFG_MAX_BOUNTY = {{MaxBounty}};

const CFG_UI = {
    placedBy: '{{PlacedBy}}',
    wanted: '{{Wanted}}',
    deadOrAlive: '{{DeadOrAlive}}',
    acceptButton: '{{AcceptButton}}',
    cancelButton: '{{CancelButton}}',
    closeButton: '{{CloseButton}}',
    coinsReward: '{{CoinsReward}}',
    labelStatus: '{{LabelStatus}}',
    labelPlacedBy: '{{LabelPlacedBy}}',
    labelHunter: '{{LabelHunter}}',
    labelDate: '{{LabelDate}}',
    placeholderTarget: '{{PlaceholderTarget}}',
    errNoTarget: '{{ErrNoTarget}}',
    errAmountMin: '{{ErrAmountMin}}',
    errAmountMax: '{{ErrAmountMax}}',
    lbYourPosition: '{{LbYourPosition}}',
    lbNoData: '{{LbNoData}}',
};

// --- State ---
let bounties = {};
let players = [];
let localSteamID = '';
let currentTab = 'active';
let playerStats = {};
let leaderboardData = {};
let leaderboardPlayerRank = 0;
let leaderboardPlayerValue = 0;
let currentLbCategory = 'bountiesCompleted';

const ICONS = ['fa-skull-crossbones','fa-bolt-lightning','fa-ghost','fa-dragon','fa-fire-flame-curved','fa-shield-halved','fa-gem','fa-crown','fa-star','fa-crosshairs','fa-wand-sparkles','fa-hat-wizard'];
const ICON_COLORS = ['#ef4444','#f59e0b','#8b5cf6','#06b6d4','#22c55e','#ec4899','#3b82f6','#f97316','#a855f7','#14b8a6','#eab308','#6366f1'];

function hashStr(s) { let h = 0; for (let i = 0; i < s.length; i++) { h = ((h << 5) - h) + s.charCodeAt(i); h |= 0; } return Math.abs(h); }
function getIcon(name) { return ICONS[hashStr(name) % ICONS.length]; }
function getColor(name) { return ICON_COLORS[hashStr(name) % ICON_COLORS.length]; }

function getSeverity(amount) {
    if (amount >= CFG_SEVERITY_CRITICAL) return { label: 'CRITICAL', cls: 'text-red-400' };
    if (amount >= CFG_SEVERITY_HIGH) return { label: 'HIGH', cls: 'text-orange-400' };
    if (amount >= CFG_SEVERITY_MID) return { label: 'MID', cls: 'text-amber-400' };
    return { label: 'LOW', cls: 'text-yellow-500/70' };
}

function formatNumber(n) { return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ','); }
function formatDate(ts) { let d = new Date(ts * 1000); return d.getFullYear() + '-' + String(d.getMonth()+1).padStart(2,'0') + '-' + String(d.getDate()).padStart(2,'0'); }

// --- Tabs ---
const TAB_ACTIVE_CLS = ['bg-bb-amber','text-bb-bg','border-bb-amber','font-semibold'];
const TAB_INACTIVE_CLS = ['bg-bb-card','text-bb-text2','border-bb-border','font-medium','hover:bg-bb-card2','hover:text-bb-text','hover:border-bb-border2'];

function switchTab(tab) {
    currentTab = tab;
    ['active','place','leaderboard','my'].forEach(t => {
        document.getElementById('page-' + t).classList.toggle('hidden', t !== tab);
        let btn = document.getElementById('tab-' + t);
        if (t === tab) {
            TAB_INACTIVE_CLS.forEach(c => btn.classList.remove(c));
            TAB_ACTIVE_CLS.forEach(c => btn.classList.add(c));
        } else {
            TAB_ACTIVE_CLS.forEach(c => btn.classList.remove(c));
            TAB_INACTIVE_CLS.forEach(c => btn.classList.add(c));
        }
    });
    if (tab === 'leaderboard') {
        bb.requestLeaderboard(currentLbCategory);
    }
    if (tab === 'my') {
        bb.requestStats();
    }
}

// --- Render ---
function renderActive() {
    let list = Object.values(bounties).filter(b => b.status === 'active' || b.status === 'hunting');
    list.sort((a, b) => (b.amount || 0) - (a.amount || 0));

    document.getElementById('bounty-count').textContent = list.length;
    let grid = document.getElementById('bounty-grid');
    let noEl = document.getElementById('no-bounties');

    if (list.length === 0) {
        grid.innerHTML = '';
        noEl.classList.remove('hidden');
        return;
    }
    noEl.classList.add('hidden');

    grid.innerHTML = list.map(b => {
        let sev = getSeverity(b.amount);
        let icon = getIcon(b.targetName || '');
        let color = getColor(b.targetName || '');
        let placerLabel = b.placerSteamID === localSteamID ? '<b>You</b>' : ('<b>' + escHtml(b.placerName || 'Unknown') + '</b>');
        return `
        <div class="border border-bb-border border-l-4 border-l-bb-amber rounded-xl p-5 bg-bb-card cursor-pointer transition-all duration-150 hover:border-bb-amber hover:bg-bb-card2" onclick="openBounty('${escAttr(b.id)}')">
            <div class="flex items-start justify-between mb-3">
                <div class="flex items-center gap-3">
                    <div class="w-12 h-12 rounded-full flex items-center justify-center" style="background:${color}20">
                        <i class="fa-solid ${icon} text-lg" style="color:${color}"></i>
                    </div>
                    <div>
                        <div class="font-bold text-bb-text">${escHtml(b.targetName || 'Unknown')}</div>
                        <div class="text-xs text-bb-text2 mt-0.5">${escHtml(b.reason || '')}</div>
                    </div>
                </div>
                <span class="text-[10px] font-bold ${sev.cls}">${sev.label}</span>
            </div>
            <div class="flex items-center justify-between mt-3 text-xs">
                <span class="text-bb-amber font-bold"><i class="fa-solid fa-coins mr-1"></i>${formatNumber(b.amount)} <span class="text-bb-text2 font-normal">${CFG_CURRENCY_NAME}</span></span>
                <span class="text-bb-text2"><i class="fa-regular fa-clock mr-1"></i>${formatDate(b.timestamp)}</span>
            </div>
            <div class="border-t border-bb-border mt-3 pt-2 text-[11px] text-bb-text2">${CFG_UI.placedBy} ${placerLabel}</div>
        </div>`;
    }).join('');
}

function renderMyBounties() {
    let all = Object.values(bounties);
    let placed = all.filter(b => b.placerSteamID === localSteamID && (b.status === 'active' || b.status === 'hunting'));
    let tracking = all.filter(b => b.hunterSteamID === localSteamID && b.status === 'hunting');

    // Placed list
    let placedEl = document.getElementById('my-placed');
    let noPlaced = document.getElementById('no-placed');
    if (placed.length === 0) { placedEl.innerHTML = ''; noPlaced.classList.remove('hidden'); }
    else {
        noPlaced.classList.add('hidden');
        placedEl.innerHTML = placed.map(b => myBountyRow(b, false)).join('');
    }

    // Tracking list
    let trackEl = document.getElementById('my-tracking');
    let noTrack = document.getElementById('no-tracking');
    if (tracking.length === 0) { trackEl.innerHTML = ''; noTrack.classList.remove('hidden'); }
    else {
        noTrack.classList.add('hidden');
        trackEl.innerHTML = tracking.map(b => myBountyRow(b, true)).join('');
    }
}

function myBountyRow(b, isTracking) {
    let sev = getSeverity(b.amount);
    let icon = getIcon(b.targetName || '');
    let color = getColor(b.targetName || '');
    let borderColor = isTracking ? 'border-l-bb-amberlight' : 'border-l-bb-amber';
    return `
    <div class="flex items-center justify-between border border-bb-border ${borderColor} border-l-4 rounded-lg px-4 py-3 bg-bb-card cursor-pointer transition-all duration-150 hover:border-bb-amber hover:bg-bb-card2" onclick="openBounty('${escAttr(b.id)}')">
        <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-full flex items-center justify-center" style="background:${color}20">
                <i class="fa-solid ${icon} text-sm" style="color:${color}"></i>
            </div>
            <div>
                <div class="font-bold text-sm text-bb-text">${escHtml(b.targetName || 'Unknown')}</div>
                <div class="text-xs text-bb-text2">${escHtml(b.reason || '')}</div>
            </div>
        </div>
        <div class="text-right">
            <div class="text-bb-amber font-bold text-sm">${formatNumber(b.amount)}</div>
            <div class="text-[10px] font-bold ${sev.cls}">${sev.label}</div>
        </div>
    </div>`;
}

// --- Modal ---
function openBounty(id) {
    let b = bounties[id];
    if (!b) return;
    let sev = getSeverity(b.amount);
    let icon = getIcon(b.targetName || '');
    let color = getColor(b.targetName || '');

    let buttons = '';
    if (b.status === 'active' && b.placerSteamID !== localSteamID && b.targetSteamID !== localSteamID) {
        buttons += `<button onclick="acceptBounty('${escAttr(b.id)}')" class="w-full bg-bb-amber text-bb-bg font-bold py-3 rounded-lg text-sm flex items-center justify-center gap-2 transition-all duration-150 hover:bg-bb-amberdark active:scale-[0.98]"><i class="fa-solid fa-crosshairs"></i> ${CFG_UI.acceptButton}</button>`;
    }
    if (b.status === 'active' && b.placerSteamID === localSteamID) {
        buttons += `<button onclick="cancelBounty('${escAttr(b.id)}')" class="w-full border border-red-500/30 text-red-400 font-bold py-3 rounded-lg text-sm hover:bg-red-500/10 transition flex items-center justify-center gap-2"><i class="fa-solid fa-ban"></i> ${CFG_UI.cancelButton}</button>`;
    }

    let hunterHtml = '';
    if (b.status === 'hunting' && b.hunterName) {
        hunterHtml = `<div class="flex items-center justify-between text-sm"><span class="text-bb-text2">${CFG_UI.labelHunter}</span><span class="text-bb-amber font-semibold">${escHtml(b.hunterName)}</span></div>`;
    }

    document.getElementById('modal-card').innerHTML = `
        <div class="bg-red-500/10 px-6 py-5 text-center border-b border-bb-border">
            <div class="text-3xl font-black text-red-400 tracking-wider">${CFG_UI.wanted}</div>
            <div class="text-[10px] text-bb-text2 tracking-widest mt-1">${CFG_UI.deadOrAlive}</div>
        </div>
        <div class="px-6 py-5">
            <div class="flex flex-col items-center mb-5">
                <div class="w-20 h-20 rounded-full flex items-center justify-center mb-3" style="background:${color}20; border: 2px solid ${color}40">
                    <i class="fa-solid ${icon} text-3xl" style="color:${color}"></i>
                </div>
                <div class="text-xl font-bold">${escHtml(b.targetName || 'Unknown')}</div>
                <div class="text-xs text-bb-text2 mt-1">${escHtml(b.reason || CFG_DEFAULT_REASON)}</div>
            </div>
            <div class="text-center mb-5">
                <div class="text-3xl font-black text-bb-amber"><i class="fa-solid fa-coins mr-1 text-xl"></i>${formatNumber(b.amount)}</div>
                <div class="text-xs text-bb-text2 mt-1">${CFG_UI.coinsReward}</div>
            </div>
            <div class="space-y-2 mb-5 bg-bb-bg/50 rounded-lg p-3 text-sm">
                <div class="flex items-center justify-between"><span class="text-bb-text2">${CFG_UI.labelStatus}</span><span class="font-bold ${sev.cls}">${b.status === 'hunting' ? 'HUNTING' : sev.label}</span></div>
                <div class="flex items-center justify-between"><span class="text-bb-text2">${CFG_UI.labelPlacedBy}</span><span class="font-semibold text-bb-text">${b.placerSteamID === localSteamID ? 'You' : escHtml(b.placerName || 'Unknown')}</span></div>
                ${hunterHtml}
                <div class="flex items-center justify-between"><span class="text-bb-text2">${CFG_UI.labelDate}</span><span class="text-bb-text2">${formatDate(b.timestamp)}</span></div>
            </div>
            <div class="space-y-2">
                ${buttons}
                <button onclick="closeModal()" class="w-full text-bb-text2 hover:text-bb-text font-medium py-2 text-sm transition">${CFG_UI.closeButton}</button>
            </div>
        </div>
    `;
    document.getElementById('modal').classList.remove('hidden');
}

function closeModal(e) {
    if (e && e.target && e.target.id !== 'modal') return;
    document.getElementById('modal').classList.add('hidden');
}

// --- Actions (call Lua) ---
function showFormError(msg) {
    showNotification(msg, 'error');
}
function hideFormError() {
    // no-op: toasts auto-dismiss
}

function submitBounty() {
    hideFormError();
    let steamid = document.getElementById('target-select').value;
    let amount = parseInt(document.getElementById('amount-input').value) || 0;
    let reason = document.getElementById('reason-input').value;

    if (!steamid) { showFormError(CFG_UI.errNoTarget); return; }
    if (amount < CFG_MIN_BOUNTY) { showFormError(CFG_UI.errAmountMin.replace('%s', formatNumber(CFG_MIN_BOUNTY) + ' ' + CFG_CURRENCY_NAME)); return; }
    if (amount > CFG_MAX_BOUNTY) { showFormError(CFG_UI.errAmountMax.replace('%s', formatNumber(CFG_MAX_BOUNTY) + ' ' + CFG_CURRENCY_NAME)); return; }

    bb.placeBounty(steamid, String(amount), reason || '');
}
function acceptBounty(id) { bb.acceptBounty(id); closeModal(); }
function cancelBounty(id) { bb.cancelBounty(id); closeModal(); }

// --- Ranks ---
const RANKS = {{RanksJSON}};

function getRank(kills) {
    let rank = RANKS[0];
    for (let i = RANKS.length - 1; i >= 0; i--) {
        if (kills >= RANKS[i].kills) { rank = RANKS[i]; break; }
    }
    return rank;
}

function getNextRank(kills) {
    for (let i = 0; i < RANKS.length; i++) {
        if (kills < RANKS[i].kills) return RANKS[i];
    }
    return null;
}

// --- Refresh ---
function refreshMyStats() {
    let icon = document.querySelector('#btn-refresh-my i');
    icon.classList.add('animate-spin');
    bb.requestStats();
    bb.refreshBounties();
    setTimeout(() => { icon.classList.remove('animate-spin'); }, 1000);
}

function refreshLeaderboard() {
    let icon = document.querySelector('#btn-refresh-lb i');
    icon.classList.add('animate-spin');
    bb.requestLeaderboard(currentLbCategory);
    setTimeout(() => { icon.classList.remove('animate-spin'); }, 1000);
}

// --- Leaderboard ---
function switchLeaderboardCategory(cat) {
    currentLbCategory = cat;
    ['bountiesCompleted','totalEarned','totalSpent'].forEach(c => {
        let pill = document.getElementById('lb-pill-' + c);
        if (c === cat) {
            pill.className = 'px-4 py-1.5 rounded-full text-sm font-semibold bg-bb-amber text-bb-bg border border-bb-amber transition-all duration-150';
        } else {
            pill.className = 'px-4 py-1.5 rounded-full text-sm font-medium bg-bb-card text-bb-text2 border border-bb-border transition-all duration-150 hover:bg-bb-card2 hover:text-bb-text hover:border-bb-border2';
        }
    });
    bb.requestLeaderboard(cat);
}

function renderLeaderboard(entries, myRank, myValue) {
    let table = document.getElementById('lb-table');
    let noData = document.getElementById('lb-no-data');
    let myPos = document.getElementById('lb-my-position');

    if (!entries || entries.length === 0) {
        table.innerHTML = '';
        noData.classList.remove('hidden');
        myPos.classList.add('hidden');
        return;
    }
    noData.classList.add('hidden');

    let isValueMoney = (currentLbCategory === 'totalEarned' || currentLbCategory === 'totalSpent');

    table.innerHTML = entries.map(e => {
        let medalColor = '';
        let medalIcon = '';
        if (e.rank === 1) { medalColor = 'text-yellow-400'; medalIcon = 'fa-trophy'; }
        else if (e.rank === 2) { medalColor = 'text-gray-300'; medalIcon = 'fa-medal'; }
        else if (e.rank === 3) { medalColor = 'text-amber-600'; medalIcon = 'fa-medal'; }

        let rank = getRank(e.bountiesCompleted || 0);
        let isLocal = (e.steamid === localSteamID);
        let borderCls = isLocal ? 'border-bb-amber' : 'border-bb-border';
        let valDisplay = isValueMoney ? (CFG_CURRENCY_SYMBOL + formatNumber(e.value)) : formatNumber(e.value);

        return `
        <div class="flex items-center justify-between border ${borderCls} rounded-lg px-5 py-3 bg-bb-card/50 transition-all duration-150 hover:bg-bb-card2">
            <div class="flex items-center gap-4">
                <div class="w-8 text-center font-bold text-lg ${medalColor || 'text-bb-text2'}">
                    ${medalIcon ? '<i class="fa-solid ' + medalIcon + '"></i>' : '#' + e.rank}
                </div>
                <div>
                    <div class="font-bold text-bb-text ${isLocal ? 'text-bb-amber' : ''}">${escHtml(e.name || 'Unknown')}</div>
                    <div class="text-[10px] text-bb-text2 flex items-center gap-1">
                        <i class="fa-solid ${rank.icon} text-bb-amber"></i> ${rank.name}
                    </div>
                </div>
            </div>
            <div class="text-bb-amber font-bold text-lg">${valDisplay}</div>
        </div>`;
    }).join('');

    // Player position if not in top
    let inTop = entries.some(e => e.steamid === localSteamID);
    if (!inTop && myRank > 0) {
        let valDisplay = isValueMoney ? (CFG_CURRENCY_SYMBOL + formatNumber(myValue)) : formatNumber(myValue);
        myPos.innerHTML = `
        <div class="flex items-center justify-between border border-bb-amber rounded-lg px-5 py-3 bg-bb-card/50">
            <div class="flex items-center gap-4">
                <div class="w-8 text-center font-bold text-lg text-bb-text2">#${myRank}</div>
                <div class="font-bold text-bb-amber">${CFG_UI.lbYourPosition}</div>
            </div>
            <div class="text-bb-amber font-bold text-lg">${valDisplay}</div>
        </div>`;
        myPos.classList.remove('hidden');
    } else {
        myPos.classList.add('hidden');
    }
}

// --- Stats & Rank display ---
function renderMyStats() {
    let s = playerStats;
    document.getElementById('stat-placed').textContent = formatNumber(s.bountiesPlaced || 0);
    document.getElementById('stat-completed').textContent = formatNumber(s.bountiesCompleted || 0);
    document.getElementById('stat-survived').textContent = formatNumber(s.bountiesSurvived || 0);
    document.getElementById('stat-earned').textContent = CFG_CURRENCY_SYMBOL + formatNumber(s.totalEarned || 0);
    document.getElementById('stat-spent').textContent = CFG_CURRENCY_SYMBOL + formatNumber(s.totalSpent || 0);
    document.getElementById('stat-streak').textContent = formatNumber(s.bestStreak || 0);

    // Rank
    let kills = s.bountiesCompleted || 0;
    let rank = getRank(kills);
    let next = getNextRank(kills);

    document.getElementById('rank-icon').innerHTML = '<i class="fa-solid ' + rank.icon + ' text-bb-amber text-xl"></i>';
    document.getElementById('rank-name').textContent = rank.name;

    if (next) {
        let progress = ((kills - rank.kills) / (next.kills - rank.kills)) * 100;
        document.getElementById('rank-progress-bar').style.width = Math.min(progress, 100) + '%';
        document.getElementById('rank-progress-text').textContent = kills + ' / ' + next.kills + ' kills to next rank';
    } else {
        document.getElementById('rank-progress-bar').style.width = '100%';
        document.getElementById('rank-progress-text').textContent = 'Max rank achieved!';
    }
}

// --- Data injection (called from Lua) ---
function setBounties(json) {
    let arr = JSON.parse(json);
    bounties = {};
    arr.forEach(b => { bounties[b.id] = b; });
    renderActive();
    renderMyBounties();
}

function updateBounty(json, action) {
    let b = JSON.parse(json);
    if (action === 'add' || action === 'update') bounties[b.id] = b;
    else if (action === 'remove') delete bounties[b.id];
    renderActive();
    renderMyBounties();
}

function setPlayers(json) {
    players = JSON.parse(json);
    let sel = document.getElementById('target-select');
    sel.innerHTML = '<option value="">' + CFG_UI.placeholderTarget + '</option>';
    players.forEach(p => {
        sel.innerHTML += '<option value="' + escAttr(p.steamid) + '">' + escHtml(p.name) + '</option>';
    });
}

function setLocalSteamID(id) { localSteamID = id; }

function setStats(json) {
    playerStats = JSON.parse(json);
    renderMyStats();
}

function setLeaderboard(json, category, myRank, myValue) {
    let entries = JSON.parse(json);
    leaderboardData = entries;
    leaderboardPlayerRank = myRank;
    leaderboardPlayerValue = myValue;
    renderLeaderboard(entries, myRank, myValue);
}

// --- Player Preview ---
function updatePreview() {
    let steamid = document.getElementById('target-select').value;
    let preview = document.getElementById('player-preview');
    if (!steamid) {
        preview.classList.add('hidden');
        bb.hideModel();
        return;
    }
    let p = players.find(pl => pl.steamid === steamid);
    if (!p) {
        preview.classList.add('hidden');
        bb.hideModel();
        return;
    }
    document.getElementById('preview-name').textContent = p.name;
    document.getElementById('preview-job').textContent = p.job || '';
    preview.classList.remove('hidden');

    requestAnimationFrame(function() {
        let zone = document.getElementById('model-zone');
        let rect = zone.getBoundingClientRect();
        bb.showModel(p.model || '', String(Math.round(rect.left)), String(Math.round(rect.top)), String(Math.round(rect.width)), String(Math.round(rect.height)));
    });
}

document.getElementById('target-select').addEventListener('change', updatePreview);

// --- Close on ESC ---
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') bb.closeMenu();
});

// --- Notifications (in-panel toasts) ---
const TOAST_ICONS = {
    error:   'fa-circle-exclamation',
    success: 'fa-circle-check',
    warning: 'fa-triangle-exclamation',
    info:    'fa-circle-info',
};
const TOAST_COLORS = {
    error:   { bg: 'bg-red-500/15', border: 'border-red-500/30', text: 'text-red-400', icon: 'text-red-400' },
    success: { bg: 'bg-emerald-500/15', border: 'border-emerald-500/30', text: 'text-emerald-400', icon: 'text-emerald-400' },
    warning: { bg: 'bg-amber-500/15', border: 'border-amber-500/30', text: 'text-amber-400', icon: 'text-amber-400' },
    info:    { bg: 'bg-blue-500/15', border: 'border-blue-500/30', text: 'text-blue-400', icon: 'text-blue-400' },
};

function showNotification(msg, type) {
    type = type || 'info';
    const c = TOAST_COLORS[type] || TOAST_COLORS.info;
    const icon = TOAST_ICONS[type] || TOAST_ICONS.info;
    const container = document.getElementById('toast-container');

    const el = document.createElement('div');
    el.className = `flex items-center gap-3 px-4 py-3 rounded-lg border ${c.bg} ${c.border} backdrop-blur-sm toast-in`;
    const iconEl = document.createElement('i');
    iconEl.className = `fa-solid ${icon} ${c.icon} text-base shrink-0`;
    const spanEl = document.createElement('span');
    spanEl.className = `${c.text} text-sm font-medium`;
    spanEl.textContent = msg;
    el.appendChild(iconEl);
    el.appendChild(spanEl);

    container.appendChild(el);

    // Keep max 5
    while (container.children.length > 5) container.removeChild(container.firstChild);

    setTimeout(() => {
        el.classList.remove('toast-in');
        el.classList.add('toast-out');
        el.addEventListener('animationend', () => el.remove());
    }, 4500);
}

// --- Util ---
function escHtml(s) { let d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
function escAttr(s) { return s.replace(/'/g, '&#39;').replace(/"/g, '&quot;'); }
</script>
</body>
</html>
]==]

-------------------------------------------------
-- Template replacement: {{Key}} -> config value
-------------------------------------------------

local function BuildHTML()
    local replacements = {}

    -- Theme colors
    for k, v in pairs(BountyBoard.Config.Theme) do
        replacements[k] = v
    end

    -- UI text
    for k, v in pairs(BountyBoard.Config.UI) do
        replacements[k] = v
    end

    -- Extra config values used in JS
    replacements["CurrencySymbol"] = BountyBoard.Config.CurrencySymbol
    replacements["CurrencyName"] = BountyBoard.Config.CurrencyName
    replacements["DefaultReason"] = BountyBoard.Config.DefaultReason
    replacements["SeverityCritical"] = tostring(BountyBoard.Config.SeverityCritical)
    replacements["SeverityHigh"] = tostring(BountyBoard.Config.SeverityHigh)
    replacements["SeverityMid"] = tostring(BountyBoard.Config.SeverityMid)
    replacements["MinBounty"] = tostring(BountyBoard.Config.MinBounty)
    replacements["MaxBounty"] = tostring(BountyBoard.Config.MaxBounty)

    -- Build ranks JSON for JS (replaced separately due to special characters)
    local ranksJSON = util.TableToJSON(BountyBoard.Config.Ranks)

    local html = HTML_TEMPLATE
    html = string.Replace(html, "{{RanksJSON}}", ranksJSON)
    html = string.gsub(html, "{{(%w+)}}", function(key)
        return replacements[key] or key
    end)

    return html
end

-------------------------------------------------
-- Open menu
-------------------------------------------------

function BountyBoard.OpenMenu()
    if IsValid(BountyBoard.MenuFrame) then
        BountyBoard.MenuFrame:Close()
        BountyBoard.MenuFrame = nil
        BountyBoard.DHTML = nil
        BountyBoard.ModelPanel = nil
    end

    net.Start("BountyBoard_RequestBounties")
    net.SendToServer()

    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:DockPadding(0, 0, 0, 0)
    frame.Paint = function() end
    BountyBoard.MenuFrame = frame

    hook.Add("PlayerBindPress", "BountyBoard_BlockESC", function(_, bind)
        if string.find(bind, "cancelselect") and IsValid(frame) then
            frame:Close()
            return true
        end
    end)

    frame.OnClose = function()
        hook.Remove("PlayerBindPress", "BountyBoard_BlockESC")
    end

    local dhtml = vgui.Create("DHTML", frame)
    dhtml:SetPos(0, 0)
    dhtml:SetSize(ScrW(), ScrH())
    dhtml:SetAllowLua(false)
    BountyBoard.DHTML = dhtml

    -- Expose Lua functions to JS
    dhtml:AddFunction("bb", "closeMenu", function()
        if IsValid(frame) then
            frame:Close()
            timer.Simple(0, function() gui.HideGameUI() end)
        end
    end)

    dhtml:AddFunction("bb", "placeBounty", function(steamid, amount, reason)
        net.Start("BountyBoard_PlaceBounty")
            net.WriteString(steamid or "")
            net.WriteInt(math.floor(tonumber(amount) or 0), 32)
            net.WriteString(reason or "")
        net.SendToServer()
    end)

    dhtml:AddFunction("bb", "acceptBounty", function(id)
        net.Start("BountyBoard_AcceptBounty")
            net.WriteString(id or "")
        net.SendToServer()
    end)

    dhtml:AddFunction("bb", "cancelBounty", function(id)
        net.Start("BountyBoard_CancelBounty")
            net.WriteString(id or "")
        net.SendToServer()
    end)

    dhtml:AddFunction("bb", "requestStats", function()
        net.Start("BountyBoard_RequestStats")
        net.SendToServer()
    end)

    dhtml:AddFunction("bb", "requestLeaderboard", function(category)
        net.Start("BountyBoard_RequestLeaderboard")
            net.WriteString(category or "bountiesCompleted")
        net.SendToServer()
    end)

    dhtml:AddFunction("bb", "refreshBounties", function()
        net.Start("BountyBoard_RequestBounties")
        net.SendToServer()
    end)

    -- 3D Model Preview Panel
    local modelPanel = vgui.Create("DModelPanel", frame)
    modelPanel:SetVisible(false)
    modelPanel:SetFOV(28)
    modelPanel:SetAnimated(true)
    modelPanel.LayoutEntity = function(self, ent)
        if IsValid(ent) then
            ent:SetAngles(Angle(0, ent:GetAngles().y + 0.3, 0))
        end
    end
    modelPanel:SetPaintBorderEnabled(false)
    modelPanel:SetPaintBackgroundEnabled(false)
    BountyBoard.ModelPanel = modelPanel

    dhtml:AddFunction("bb", "showModel", function(mdl, x, y, w, h)
        if not IsValid(modelPanel) then return end
        x = tonumber(x) or 0
        y = tonumber(y) or 0
        w = tonumber(w) or 200
        h = tonumber(h) or 256

        modelPanel:SetPos(x, y)
        modelPanel:SetSize(w, h)
        modelPanel:SetModel(mdl)
        modelPanel:SetVisible(true)

        -- Auto-position camera
        local ent = modelPanel:GetEntity()
        if IsValid(ent) then
            local mn, mx = ent:GetRenderBounds()
            local center = (mn + mx) * 0.5
            local size = mx - mn
            local maxDim = math.max(size.x, size.y, size.z)

            modelPanel:SetCamPos(center + Vector(maxDim * 0.8, maxDim * 0.8, maxDim * 0.3))
            modelPanel:SetLookAt(center + Vector(0, 0, size.z * 0.1))
        end
    end)

    dhtml:AddFunction("bb", "hideModel", function()
        if IsValid(modelPanel) then
            modelPanel:SetVisible(false)
        end
    end)

    dhtml:SetHTML(BuildHTML())
    dhtml:RequestFocus()

    -- Wait for page to load, then inject data
    dhtml:QueueJavascript("setLocalSteamID('" .. LocalPlayer():SteamID() .. "')")
    BountyBoard.RefreshDHTML()
    BountyBoard.InjectPlayers()
end

-------------------------------------------------
-- Data injection helpers
-------------------------------------------------

function BountyBoard.RefreshDHTML()
    if not IsValid(BountyBoard.DHTML) then return end

    local list = {}
    for _, b in pairs(BountyBoard.CachedBounties) do
        table.insert(list, b)
    end

    local json = util.TableToJSON(list)
    BountyBoard.DHTML:QueueJavascript("setBounties('" .. SafeJSString(json) .. "')")
end

function BountyBoard.InjectPlayers()
    if not IsValid(BountyBoard.DHTML) then return end

    local list = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= LocalPlayer() then
            table.insert(list, {
                name = ply:Nick(),
                steamid = ply:SteamID(),
                model = ply:GetModel(),
                job = ply.getDarkRPVar and ply:getDarkRPVar("job") or ""
            })
        end
    end

    local json = util.TableToJSON(list)
    BountyBoard.DHTML:QueueJavascript("setPlayers('" .. SafeJSString(json) .. "')")
end

function BountyBoard.UpdateDHTML(bounty, action)
    if not IsValid(BountyBoard.DHTML) then return end

    local json = util.TableToJSON(bounty)
    BountyBoard.DHTML:QueueJavascript("updateBounty('" .. SafeJSString(json) .. "', '" .. SafeJSString(action) .. "')")
end

-------------------------------------------------
-- Net receivers
-------------------------------------------------

net.Receive("BountyBoard_SendBounties", function()
    local bounties = net.ReadTable()
    BountyBoard.CachedBounties = {}
    for _, b in ipairs(bounties) do
        BountyBoard.CachedBounties[b.id] = b
    end
    BountyBoard.RefreshDHTML()
end)

net.Receive("BountyBoard_SendStats", function()
    local stats = net.ReadTable()
    if not IsValid(BountyBoard.DHTML) then return end

    local json = util.TableToJSON(stats)
    BountyBoard.DHTML:QueueJavascript("setStats('" .. SafeJSString(json) .. "')")
end)

net.Receive("BountyBoard_SendLeaderboard", function()
    local category = net.ReadString()
    local entries = net.ReadTable()
    local myRank = net.ReadUInt(16)
    local myValue = net.ReadUInt(32)

    if not IsValid(BountyBoard.DHTML) then return end

    local json = util.TableToJSON(entries)
    BountyBoard.DHTML:QueueJavascript("setLeaderboard('" .. SafeJSString(json) .. "', '" .. SafeJSString(category) .. "', " .. tonumber(myRank) .. ", " .. tonumber(myValue) .. ")")
end)

net.Receive("BountyBoard_BountyUpdate", function()
    local action = net.ReadString()
    local bounty = net.ReadTable()

    if action == "add" or action == "update" then
        BountyBoard.CachedBounties[bounty.id] = bounty
    elseif action == "remove" then
        BountyBoard.CachedBounties[bounty.id] = nil
    end

    -- Clear tracking if hunt ended
    local lp = LocalPlayer()
    if IsValid(lp) and bounty.hunterSteamID == lp:SteamID() then
        if bounty.status == "completed" or bounty.status == "expired" or bounty.status == "canceled" then
            BountyBoard.TrackingPos = nil
        end
    end

    BountyBoard.UpdateDHTML(bounty, action)
end)

-------------------------------------------------
-- Chat commands
-------------------------------------------------

hook.Add("OnPlayerChat", "BountyBoard_ChatCommands", function(ply, text)
    if ply ~= LocalPlayer() then return end
    text = string.lower(string.Trim(text))
    for _, cmd in ipairs(BountyBoard.Config.ChatCommands) do
        if text == cmd then
            BountyBoard.OpenMenu()
            return true
        end
    end
end)

concommand.Add("bountyboard_open", function()
    BountyBoard.OpenMenu()
end)
