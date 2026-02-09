# Bounty Board

A dynamic bounty system addon for **Garry's Mod DarkRP** servers. Players place bounties using in-game money, hunters accept contracts and track their targets with a compass HUD, and kills complete bounties for rewards.

---

## Features

- **Place bounties** on other players with DarkRP money
- **Accept & hunt** bounties with a real-time compass tracker
- **Modern DHTML UI** built with TailwindCSS and FontAwesome
- **Severity badges** (CRITICAL / HIGH / MID / LOW) based on bounty amount
- **Auto-expiration** with refund after configurable duration
- **Anti-abuse** protections: cooldowns, limits, self-bounty prevention, stacking control
- **Permission system**: group whitelist, job blacklist, immunity, admin bypass
- **Fully configurable**: theme colors, UI text, amounts, timers, and more
- **Data persistence**: bounties survive server restarts (JSON file)
- **Broadcast notifications**: customizable HUD toast notifications

---

## Installation

1. Download or clone this repository
2. Place the `bounty-board` folder into your server's `addons` directory:
   ```
   garrysmod/addons/bounty-board/
   ```
3. Restart your server (or change map)
4. The addon loads automatically — no extra steps required

### Requirements

- **Garry's Mod** dedicated server or listen server
- **DarkRP** gamemode (uses `ply:canAfford()`, `ply:addMoney()`)

---

## Usage

### Opening the menu

Players can open the Bounty Board using any of these chat commands:

| Command | Description |
|---------|-------------|
| `!bounty` | Open the bounty board |
| `/bounty` | Open the bounty board |
| `!bb` | Short alias |
| `/bb` | Short alias |
| `!wanted` | Alternative command |
| `/wanted` | Alternative command |

Or via console: `bountyboard_open`

### Placing a bounty

1. Open the Bounty Board
2. Go to the **Place Bounty** tab
3. Select a target player from the dropdown
4. Enter the bounty amount (minimum and maximum are configurable)
5. Optionally enter a reason
6. Click **Place Bounty**

The amount is deducted from your DarkRP wallet immediately.

### Accepting a bounty

1. Open the Bounty Board
2. Click on any active bounty card
3. In the detail modal, click **Accept Bounty**
4. A compass HUD will appear in the bottom-left corner guiding you toward the target
5. Kill the target to claim the reward

### Canceling a bounty

- Only the player who placed the bounty can cancel it
- A bounty can only be canceled if no hunter has accepted it yet
- The full amount is refunded upon cancellation

### Tracking compass

When you accept a bounty, a compass appears in the bottom-left of your screen showing:
- **Direction arrow** pointing toward the target's approximate position
- **Distance** in meters
- **NEARBY** warning when you're close

The position has a configurable random offset for fairness.

---

## Configuration

All settings are in a single file:

```
lua/bountyboard/shared/sh_config.lua
```

After editing, restart the server or change map to apply changes.

### General

| Setting | Default | Description |
|---------|---------|-------------|
| `CurrencySymbol` | `$` | Symbol shown in the UI |
| `CurrencyName` | `coins` | Currency name shown next to amounts |

### Bounty Amounts

| Setting | Default | Description |
|---------|---------|-------------|
| `MinBounty` | `1000` | Minimum amount to place a bounty |
| `MaxBounty` | `500000` | Maximum amount for a single bounty |
| `SeverityCritical` | `10000` | Amount threshold for CRITICAL badge |
| `SeverityHigh` | `5000` | Amount threshold for HIGH badge |
| `SeverityMid` | `2000` | Amount threshold for MID badge |

### Timers & Cooldowns

| Setting | Default | Description |
|---------|---------|-------------|
| `BountyDuration` | `1800` (30 min) | How long a bounty stays active before expiring |
| `PlaceCooldown` | `60` | Seconds between placing two bounties |
| `AcceptCooldown` | `30` | Seconds between accepting two bounties |
| `ExpirationCheckInterval` | `60` | How often the server checks for expired bounties |

### Tracking

| Setting | Default | Description |
|---------|---------|-------------|
| `TrackingInterval` | `3` | Seconds between compass position updates |
| `TrackingImprecision` | `500` | Random offset (Source units) added to target position. Higher = less precise. 0 = exact (not recommended) |

### Anti-Abuse Limits

| Setting | Default | Description |
|---------|---------|-------------|
| `MaxActiveBounties` | `3` | Max bounties a player can have placed at once |
| `MaxActiveHunts` | `2` | Max bounties a player can be hunting at once |
| `AllowSelfBounty` | `false` | Allow placing a bounty on yourself |
| `AllowHuntOwnBounty` | `false` | Allow accepting a bounty you placed |
| `AllowStackedBounties` | `false` | Allow multiple bounties on the same target |
| `MaxReasonLength` | `100` | Max characters for the reason field |
| `DefaultReason` | `No reason given` | Fallback reason when none is provided |

### Permissions

| Setting | Default | Description |
|---------|---------|-------------|
| `AllowedGroupsPlace` | `{}` | UserGroups allowed to place bounties. Empty = everyone |
| `AllowedGroupsHunt` | `{}` | UserGroups allowed to hunt bounties. Empty = everyone |
| `ImmuneGroups` | `{}` | UserGroups immune to bounties (cannot be targeted) |
| `ImmuneJobs` | `{}` | DarkRP job team names immune to bounties |
| `BlacklistedJobsPlace` | `{}` | DarkRP jobs that cannot place bounties |
| `BlacklistedJobsHunt` | `{}` | DarkRP jobs that cannot hunt bounties |
| `MinPlayersOnline` | `2` | Minimum players online to allow placing bounties |
| `AdminBypass` | `false` | Admins bypass all restrictions |

**Examples:**
```lua
-- Only VIPs and above can place bounties
BountyBoard.Config.AllowedGroupsPlace = {"superadmin", "admin", "vip"}

-- Police and Mayor are immune to bounties
BountyBoard.Config.ImmuneJobs = {"TEAM_POLICE", "TEAM_CHIEF", "TEAM_MAYOR"}

-- Hobos cannot place bounties
BountyBoard.Config.BlacklistedJobsPlace = {"TEAM_HOBO"}
```

### Notifications

| Setting | Default | Description |
|---------|---------|-------------|
| `BroadcastNewBounty` | `true` | Announce new bounties to all players |
| `BroadcastAccepted` | `true` | Announce when someone accepts a bounty |
| `BroadcastCompleted` | `true` | Announce when a bounty is completed |
| `NotifyTarget` | `true` | Notify the target when a bounty is placed on them |
| `NotifyTargetOnHunt` | `true` | Notify the target when someone starts hunting them |

### Logging

| Setting | Default | Description |
|---------|---------|-------------|
| `LogToConsole` | `true` | Print bounty events to server console |
| `LogPrefix` | `[BountyBoard]` | Prefix for console log messages |

### Chat Commands

```lua
BountyBoard.Config.ChatCommands = {
    "!bounty",
    "/bounty",
    "!bb",
    "/bb",
    "!wanted",
    "/wanted",
}
```

Add or remove commands as needed.

---

## UI Customization

### Theme Colors

All UI colors are configurable via `BountyBoard.Config.Theme`. Values are hex color codes **without** the `#`:

```lua
BountyBoard.Config.Theme = {
    BgPage      = "0f1117",     -- Main background
    BgCard      = "1a1c25",     -- Card background
    BgCardHover = "22242e",     -- Card hover
    Border      = "2a2d38",     -- Borders
    BorderHover = "363944",     -- Border on hover
    Accent      = "f59e0b",     -- Main accent color (amber)
    AccentHover = "d97706",     -- Accent on hover
    AccentLight = "fbbf24",     -- Light accent
    TextTitle   = "f59e0b",     -- Section titles (Active Bounties, Place a Bounty, My Bounties)
    TextPrimary = "ffffff",     -- Stat values, player names, input text
    TextSecondary = "9ca3af",   -- Subtitles, labels, secondary info
    Critical    = "ef4444",     -- CRITICAL badge (red)
    High        = "f97316",     -- HIGH badge (orange)
    Mid         = "f59e0b",     -- MID badge (amber)
    Low         = "eab308",     -- LOW badge (yellow)
    Success     = "22c55e",     -- Success notifications
    Danger      = "ef4444",     -- Error/wanted
    Info        = "3b82f6",     -- Info
}
```

**Light theme example:** If you switch to a white background, update text colors so they stay readable:
```lua
BountyBoard.Config.Theme.BgPage = "f5f5f5"
BountyBoard.Config.Theme.BgCard = "ffffff"
BountyBoard.Config.Theme.TextPrimary = "1a1a1a"
BountyBoard.Config.Theme.TextSecondary = "6b7280"
```

### HUD Colors

The compass and notifications use Lua `Color()` objects in `BountyBoard.Colors`. Update these to match your theme:

```lua
BountyBoard.Colors = {
    Bg            = Color(15, 17, 23),
    Card          = Color(26, 28, 37),
    Border        = Color(42, 45, 56),
    Amber         = Color(245, 158, 11),
    AmberDark     = Color(217, 119, 6),
    Danger        = Color(239, 68, 68),
    Success       = Color(34, 197, 94),
    TextPrimary   = Color(255, 255, 255),
    TextSecondary = Color(156, 163, 175),
    TextMuted     = Color(107, 114, 128),
    White         = Color(255, 255, 255),
    Black         = Color(0, 0, 0),
}
```

### UI Text / Translation

All visible text in the menu and HUD is in `BountyBoard.Config.UI`. Change the values to translate or rephrase:

```lua
BountyBoard.Config.UI = {
    Title           = "BOUNTY BOARD",
    Subtitle        = "HUNT &middot; TRACK &middot; COLLECT",
    TabActive       = "Active Bounties",
    TabPlace        = "Place Bounty",
    TabMy           = "My Bounties",
    ActiveTitle     = "Active Bounties",
    NoBounties      = "No active bounties...",
    PlacedBy        = "Placed by",
    PlaceTitle      = "Place a Bounty",
    -- ... see sh_config.lua for the full list
}
```

Notification messages are in `BountyBoard.Lang` with `%s` placeholders for dynamic values.

---

## File Structure

```
bounty-board/
├── addon.json                              -- Workshop metadata
├── README.md                               -- This file
└── lua/
    ├── autorun/
    │   └── bountyboard_init.lua            -- Loader
    └── bountyboard/
        ├── shared/
        │   └── sh_config.lua               -- All configuration
        ├── server/
        │   ├── sv_network.lua              -- Net strings & senders
        │   └── sv_bounties.lua             -- Bounty logic & persistence
        └── client/
            ├── cl_fonts.lua                -- HUD fonts
            ├── cl_notifications.lua        -- Toast notifications (HUD)
            ├── cl_compass.lua              -- Tracking compass (HUD)
            ├── cl_poster.lua               -- Legacy fallback
            └── cl_menu.lua                 -- Main DHTML menu
```

---

## Data Storage

Bounty data is saved to:
```
garrysmod/data/bountyboard/bounties.json
```

This file is automatically created and updated. Bounties persist across server restarts. Expired bounties are cleaned up on load.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Menu doesn't open | Check console for Lua errors. Ensure DarkRP is the active gamemode |
| "Not enough players online" | Reduce `MinPlayersOnline` in config or add more players |
| Bounty doesn't complete on kill | The hunter must be the one who kills the target |
| Compass doesn't appear | Compass only shows when you have an active hunt |
| UI looks broken | The DHTML panel needs internet access for TailwindCSS and FontAwesome CDNs |
