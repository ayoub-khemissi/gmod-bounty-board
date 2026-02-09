BountyBoard.Stats = BountyBoard.Stats or {}

local STATS_PATH = "bountyboard/stats.json"
local CFG = BountyBoard.Config

local STAT_DEFAULTS = {
    bountiesPlaced = 0,
    bountiesCompleted = 0,
    bountiesSurvived = 0,
    totalEarned = 0,
    totalSpent = 0,
    highestBounty = 0,
    currentStreak = 0,
    bestStreak = 0,
    deaths = 0,
}

-------------------------------------------------
-- Persistence
-------------------------------------------------

function BountyBoard.SaveStats()
    if not file.IsDir("bountyboard", "DATA") then
        file.CreateDir("bountyboard")
    end
    file.Write(STATS_PATH, util.TableToJSON(BountyBoard.Stats, true))
end

function BountyBoard.LoadStats()
    if not file.Exists(STATS_PATH, "DATA") then return end

    local raw = file.Read(STATS_PATH, "DATA")
    if not raw or raw == "" then return end

    local data = util.JSONToTable(raw)
    if not data then return end

    BountyBoard.Stats = data
    print(CFG.LogPrefix .. " Loaded stats for " .. table.Count(BountyBoard.Stats) .. " players.")
end

-------------------------------------------------
-- Accessors
-------------------------------------------------

function BountyBoard.GetStats(steamid)
    if not BountyBoard.Stats[steamid] then
        BountyBoard.Stats[steamid] = table.Copy(STAT_DEFAULTS)
    end
    -- Ensure all keys exist (migration safety)
    for k, v in pairs(STAT_DEFAULTS) do
        if BountyBoard.Stats[steamid][k] == nil then
            BountyBoard.Stats[steamid][k] = v
        end
    end
    return BountyBoard.Stats[steamid]
end

function BountyBoard.UpdateStat(steamid, key, delta)
    local stats = BountyBoard.GetStats(steamid)
    stats[key] = (stats[key] or 0) + delta
    BountyBoard.SaveStats()
end

function BountyBoard.SetStat(steamid, key, value)
    local stats = BountyBoard.GetStats(steamid)
    stats[key] = value
    BountyBoard.SaveStats()
end

-------------------------------------------------
-- Leaderboard
-------------------------------------------------

function BountyBoard.GetLeaderboard(category, limit)
    limit = limit or 10
    local entries = {}

    for steamid, stats in pairs(BountyBoard.Stats) do
        local val = stats[category] or 0
        if val > 0 then
            table.insert(entries, {
                steamid = steamid,
                name = stats.name or steamid,
                value = val,
                bountiesCompleted = stats.bountiesCompleted or 0,
            })
        end
    end

    table.sort(entries, function(a, b) return a.value > b.value end)

    local result = {}
    for i = 1, math.min(limit, #entries) do
        result[i] = entries[i]
        result[i].rank = i
    end

    return result, entries
end

-------------------------------------------------
-- Name tracking (keep player names updated)
-------------------------------------------------

hook.Add("PlayerInitialSpawn", "BountyBoard_TrackName", function(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        local stats = BountyBoard.GetStats(ply:SteamID())
        stats.name = ply:Nick()
        BountyBoard.SaveStats()
    end)
end)

-------------------------------------------------
-- Startup
-------------------------------------------------

BountyBoard.LoadStats()
