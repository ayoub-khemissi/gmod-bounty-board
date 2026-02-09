--[[
    ============================================================
    BOUNTY BOARD — Configuration
    ============================================================

    Modify the values below to customize the addon for your server.
    All settings are commented — read carefully before changing.

    After editing, restart the server or run: bountyboard_reload

    ============================================================
]]

BountyBoard = BountyBoard or {}
BountyBoard.Config = BountyBoard.Config or {}

--[[------------------------------------------------------------
    GENERAL
--------------------------------------------------------------]]

-- Currency symbol displayed in the UI (cosmetic only)
BountyBoard.Config.CurrencySymbol = "$"

-- Currency name displayed next to amounts (e.g. "coins", "dollars", "credits")
BountyBoard.Config.CurrencyName = "coins"

--[[------------------------------------------------------------
    BOUNTY AMOUNTS
--------------------------------------------------------------]]

-- Minimum amount required to place a bounty
BountyBoard.Config.MinBounty = 1000

-- Maximum amount allowed for a single bounty
BountyBoard.Config.MaxBounty = 500000

-- Amount thresholds for severity badges in the UI
-- Bounties above these amounts will show CRITICAL / HIGH / MID / LOW
BountyBoard.Config.SeverityCritical = 10000
BountyBoard.Config.SeverityHigh = 5000
BountyBoard.Config.SeverityMid = 2000

--[[------------------------------------------------------------
    TIMERS & COOLDOWNS (in seconds)
--------------------------------------------------------------]]

-- How long a bounty stays active before it expires and gets refunded
BountyBoard.Config.BountyDuration = 1800 -- 30 minutes

-- Cooldown between placing two bounties (per player)
BountyBoard.Config.PlaceCooldown = 60

-- Cooldown between accepting two bounties (per player)
BountyBoard.Config.AcceptCooldown = 30

-- How often the server checks for expired bounties
BountyBoard.Config.ExpirationCheckInterval = 60

--[[------------------------------------------------------------
    TRACKING (compass HUD for hunters)
--------------------------------------------------------------]]

-- Seconds between position updates sent to the hunter
BountyBoard.Config.TrackingInterval = 3

-- Random offset in Source units added to the target's real position
-- Higher = less precise compass, more fair for the target
-- 0 = exact position (not recommended)
BountyBoard.Config.TrackingImprecision = 500

--[[------------------------------------------------------------
    ANTI-ABUSE LIMITS
--------------------------------------------------------------]]

-- Max bounties a single player can have placed at the same time
BountyBoard.Config.MaxActiveBounties = 3

-- Max bounties a single player can be hunting at the same time
BountyBoard.Config.MaxActiveHunts = 2

-- Allow a player to place a bounty on themselves
BountyBoard.Config.AllowSelfBounty = false

-- Allow a player to accept a bounty they placed themselves
BountyBoard.Config.AllowHuntOwnBounty = false

-- Allow stacking: multiple bounties on the same target at once
-- If false, only one active bounty per target is allowed
BountyBoard.Config.AllowStackedBounties = false

-- Maximum characters for the bounty reason field
BountyBoard.Config.MaxReasonLength = 100

-- Default reason when none is provided
BountyBoard.Config.DefaultReason = "No reason given"

--[[------------------------------------------------------------
    PERMISSIONS
--------------------------------------------------------------]]

-- UserGroups that are allowed to place bounties
-- Empty table = everyone can place bounties
-- Example: {"superadmin", "admin", "vip", "user"}
BountyBoard.Config.AllowedGroupsPlace = {}

-- UserGroups that are allowed to accept/hunt bounties
-- Empty table = everyone can hunt
BountyBoard.Config.AllowedGroupsHunt = {}

-- UserGroups immune to bounties (cannot be targeted)
-- Example: {"superadmin", "admin"}
BountyBoard.Config.ImmuneGroups = {}

-- DarkRP jobs (exact team name) immune to bounties
-- Example: {"TEAM_MAYOR", "TEAM_POLICE", "TEAM_CHIEF"}
BountyBoard.Config.ImmuneJobs = {}

-- DarkRP jobs that CANNOT place bounties
-- Example: {"TEAM_HOBO"}
BountyBoard.Config.BlacklistedJobsPlace = {}

-- DarkRP jobs that CANNOT hunt bounties
-- Example: {"TEAM_POLICE", "TEAM_CHIEF"}
BountyBoard.Config.BlacklistedJobsHunt = {}

-- Minimum number of players online to allow placing bounties
-- Useful to prevent abuse on empty servers
BountyBoard.Config.MinPlayersOnline = 2

-- Admin override: admins bypass all restrictions (cooldowns, limits, etc.)
-- Uses ply:IsAdmin()
BountyBoard.Config.AdminBypass = false

--[[------------------------------------------------------------
    NOTIFICATIONS
--------------------------------------------------------------]]

-- Broadcast bounty events to ALL players
-- If false, only involved players are notified
BountyBoard.Config.BroadcastNewBounty = true
BountyBoard.Config.BroadcastAccepted = true
BountyBoard.Config.BroadcastCompleted = true

-- Notify the target when a bounty is placed on them
BountyBoard.Config.NotifyTarget = true

-- Notify the target when someone starts hunting them
BountyBoard.Config.NotifyTargetOnHunt = true

--[[------------------------------------------------------------
    LOGGING
--------------------------------------------------------------]]

-- Print bounty events to server console
BountyBoard.Config.LogToConsole = true

-- Prefix for console log messages
BountyBoard.Config.LogPrefix = "[BountyBoard]"

--[[------------------------------------------------------------
    CHAT COMMANDS
--------------------------------------------------------------]]

-- Commands that open the bounty board menu
-- Add or remove as needed
BountyBoard.Config.ChatCommands = {
    "!bounty",
    "/bounty",
    "!bb",
    "/bb",
    "!wanted",
    "/wanted",
}

--[[------------------------------------------------------------
    HUNTER RANKS
    Ranks based on bountiesCompleted.
    Format: { kills = <threshold>, name = "<rank name>", icon = "<fontawesome icon>" }
    Must be sorted from lowest to highest kills.
--------------------------------------------------------------]]

BountyBoard.Config.Ranks = {
    { kills = 0,   name = "Rookie",       icon = "fa-seedling" },
    { kills = 5,   name = "Tracker",      icon = "fa-binoculars" },
    { kills = 15,  name = "Stalker",      icon = "fa-eye" },
    { kills = 30,  name = "Hunter",       icon = "fa-crosshairs" },
    { kills = 50,  name = "Slayer",       icon = "fa-skull" },
    { kills = 75,  name = "Executioner",  icon = "fa-skull-crossbones" },
    { kills = 100, name = "Legendary",    icon = "fa-crown" },
}

--[[------------------------------------------------------------
    UI THEME (DHTML / Tailwind colors)
    These are injected into the HTML template.
    Use hex color codes WITHOUT the #
--------------------------------------------------------------]]

BountyBoard.Config.Theme = {
    -- Page & panels
    BgPage      = "0f1117",     -- Main background
    BgCard      = "1a1c25",     -- Card background
    BgCardHover = "22242e",     -- Card hover background
    BgInput     = "1a1c25",     -- Input fields background
    Border      = "2a2d38",     -- Default borders
    BorderHover = "363944",     -- Border on hover

    -- Accent (main brand color)
    Accent      = "f59e0b",     -- Amber — buttons, active tab, highlights
    AccentHover = "d97706",     -- Darker amber on hover
    AccentLight = "fbbf24",     -- Lighter amber for secondary elements

    -- Severity badge colors
    Critical    = "ef4444",     -- Red
    High        = "f97316",     -- Orange
    Mid         = "f59e0b",     -- Amber
    Low         = "eab308",     -- Yellow

    -- Text colors
    TextTitle   = "f59e0b",     -- Section titles (Active Bounties, Place a Bounty, My Bounties)
    TextPrimary = "ffffff",     -- Stat values, player names, input text
    TextSecondary = "9ca3af",   -- Subtitles, labels, secondary info

    -- Status colors
    Success     = "22c55e",     -- Green (completion)
    Danger      = "ef4444",     -- Red (wanted, errors)
    Info        = "3b82f6",     -- Blue (info)
}

--[[------------------------------------------------------------
    UI TEXT (change wording, translate, etc.)
    Used both in DHTML menu and Lua HUD/notifications
--------------------------------------------------------------]]

BountyBoard.Config.UI = {
    -- Header
    Title           = "BOUNTY BOARD",
    Subtitle        = "HUNT &middot; TRACK &middot; COLLECT",

    -- Tabs
    TabActive       = "Active Bounties",
    TabPlace        = "Place Bounty",
    TabLeaderboard  = "Leaderboard",
    TabMy           = "My Bounties",

    -- Active Bounties page
    ActiveTitle     = "Active Bounties",
    NoBounties      = "No active bounties...",
    PlacedBy        = "Placed by",

    -- Place Bounty page
    PlaceTitle      = "Place a Bounty",
    FieldTarget     = "Target Player",
    FieldAmount     = "Bounty Amount",
    FieldReason     = "Reason",
    PlaceholderTarget = "Select a player...",
    PlaceholderAmount = "1000",
    PlaceholderReason = "Why do you want this player hunted?",
    SubmitButton    = "Place Bounty",
    ErrNoTarget     = "Please select a target player.",
    ErrAmountMin    = "Minimum bounty amount is %s.",
    ErrAmountMax    = "Maximum bounty amount is %s.",

    -- Leaderboard page
    LeaderboardTitle = "Leaderboard",
    LbTopHunters    = "Top Hunters",
    LbTopEarners    = "Top Earners",
    LbTopSpenders   = "Top Spenders",
    LbRank          = "#",
    LbPlayer        = "Player",
    LbValue         = "Value",
    LbYourPosition  = "Your position",
    LbNoData        = "No data yet...",

    -- My Bounties page
    MyTitle         = "My Bounties",
    StatPlaced      = "Placed",
    StatCompleted   = "Completed",
    StatSurvived    = "Survived",
    StatEarned      = "Total Earned",
    StatSpent       = "Total Spent",
    StatBestStreak  = "Best Streak",
    StatTracking    = "Tracking",
    SectionRank     = "HUNTER RANK",
    SectionPlaced   = "BOUNTIES PLACED",
    SectionTracking = "TRACKING",
    NoPlaced        = "No bounties placed.",
    NoTracking      = "No active hunts.",

    -- Modal (bounty detail)
    Wanted          = "WANTED",
    DeadOrAlive     = "DEAD OR ALIVE",
    AcceptButton    = "Accept Bounty",
    CancelButton    = "Cancel Bounty",
    CloseButton     = "Close",
    CoinsReward     = "coins reward",
    LabelStatus     = "Status",
    LabelPlacedBy   = "Placed by",
    LabelHunter     = "Hunter",
    LabelDate       = "Date",

    -- Compass HUD
    CompassTarget   = "TARGET",
    CompassNearby   = "NEARBY",
}

--[[------------------------------------------------------------
    NOTIFICATION MESSAGES
    %s placeholders are filled in order by the code.
--------------------------------------------------------------]]

BountyBoard.Lang = {
    -- Broadcasts
    BountyPlaced    = "New bounty placed on %s for %s%s!",
    BountyAccepted  = "%s is now hunting %s!",
    BountyCompleted = "%s has claimed the bounty on %s! (%s%s)",
    BountyExpired   = "Bounty on %s has expired. Refunded %s%s.",
    BountyCanceled  = "Bounty on %s has been canceled.",

    -- Personal notifications
    YouAreBountied  = "A bounty of %s%s has been placed on your head!",
    YouAreHunted    = "%s is now hunting you!",
    Refunded        = "Refunded %s%s.",

    -- Error messages
    ErrCannotAfford     = "You cannot afford this bounty!",
    ErrMinAmount        = "Minimum bounty amount is %s%s.",
    ErrMaxAmount        = "Maximum bounty amount is %s%s.",
    ErrMaxBounties      = "You have reached the maximum number of active bounties!",
    ErrMaxHunts         = "You have reached the maximum number of active hunts!",
    ErrSelfBounty       = "You cannot place a bounty on yourself!",
    ErrAlreadyBountied  = "This player already has an active bounty!",
    ErrAlreadyHunting   = "This bounty is already being hunted!",
    ErrCooldownPlace    = "You must wait before placing another bounty!",
    ErrCooldownAccept   = "You must wait before accepting another bounty!",
    ErrNotYourBounty    = "This is not your bounty!",
    ErrBountyNotFound   = "Bounty not found!",
    ErrCannotCancel     = "Cannot cancel a bounty that is being hunted!",
    ErrInvalidPlayer    = "Invalid player selected!",
    ErrNotAllowed       = "You are not allowed to do this!",
    ErrImmune           = "This player cannot be targeted!",
    ErrMinPlayers       = "Not enough players online (minimum: %s).",
}

--[[------------------------------------------------------------
    HUD COLORS (Lua-drawn compass & notifications)
    Only change these if you also changed Theme colors above.
--------------------------------------------------------------]]

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
