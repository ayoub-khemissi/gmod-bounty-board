BountyBoard.Bounties = BountyBoard.Bounties or {}
BountyBoard.Cooldowns = BountyBoard.Cooldowns or {}

local SAVE_PATH = "bountyboard/bounties.json"
local CFG = BountyBoard.Config

-------------------------------------------------
-- Helpers
-------------------------------------------------

local function Log(msg)
    if CFG.LogToConsole then
        print(CFG.LogPrefix .. " " .. msg)
    end
end

local function GenerateID()
    return "BB_" .. os.time() .. "_" .. math.random(1000, 9999)
end

local function GetPlayerBySteamID(steamid)
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == steamid then return ply end
    end
    return nil
end

local function CountActiveBounties(steamid)
    local count = 0
    for _, b in pairs(BountyBoard.Bounties) do
        if b.placerSteamID == steamid and (b.status == "active" or b.status == "hunting") then
            count = count + 1
        end
    end
    return count
end

local function CountActiveHunts(steamid)
    local count = 0
    for _, b in pairs(BountyBoard.Bounties) do
        if b.hunterSteamID == steamid and b.status == "hunting" then
            count = count + 1
        end
    end
    return count
end

local function HasExistingBounty(targetSteamID)
    if CFG.AllowStackedBounties then return false end
    for _, b in pairs(BountyBoard.Bounties) do
        if b.targetSteamID == targetSteamID and (b.status == "active" or b.status == "hunting") then
            return true
        end
    end
    return false
end

local function CheckCooldown(ply, cooldownType)
    if CFG.AdminBypass and ply:IsAdmin() then return true end

    local key = ply:SteamID() .. "_" .. cooldownType
    local lastTime = BountyBoard.Cooldowns[key]
    if not lastTime then return true end

    local duration = cooldownType == "place" and CFG.PlaceCooldown or CFG.AcceptCooldown
    return (os.time() - lastTime) >= duration
end

local function SetCooldown(ply, cooldownType)
    BountyBoard.Cooldowns[ply:SteamID() .. "_" .. cooldownType] = os.time()
end

-------------------------------------------------
-- Permission checks
-------------------------------------------------

local function IsGroupAllowed(ply, allowedGroups)
    if #allowedGroups == 0 then return true end
    local group = ply:GetUserGroup()
    for _, g in ipairs(allowedGroups) do
        if g == group then return true end
    end
    return false
end

local function IsJobBlacklisted(ply, blacklistedJobs)
    if #blacklistedJobs == 0 then return false end
    local teamID = ply:Team()
    for _, jobName in ipairs(blacklistedJobs) do
        if _G[jobName] and teamID == _G[jobName] then return true end
    end
    return false
end

local function IsImmune(ply)
    -- Group immunity
    if #CFG.ImmuneGroups > 0 then
        local group = ply:GetUserGroup()
        for _, g in ipairs(CFG.ImmuneGroups) do
            if g == group then return true end
        end
    end
    -- Job immunity
    if #CFG.ImmuneJobs > 0 then
        local teamID = ply:Team()
        for _, jobName in ipairs(CFG.ImmuneJobs) do
            if _G[jobName] and teamID == _G[jobName] then return true end
        end
    end
    return false
end

local function CanPlace(ply)
    if CFG.AdminBypass and ply:IsAdmin() then return true end
    if not IsGroupAllowed(ply, CFG.AllowedGroupsPlace) then return false end
    if IsJobBlacklisted(ply, CFG.BlacklistedJobsPlace) then return false end
    return true
end

local function CanHunt(ply)
    if CFG.AdminBypass and ply:IsAdmin() then return true end
    if not IsGroupAllowed(ply, CFG.AllowedGroupsHunt) then return false end
    if IsJobBlacklisted(ply, CFG.BlacklistedJobsHunt) then return false end
    return true
end

-------------------------------------------------
-- Notification wrappers (respect config flags)
-------------------------------------------------

local function BroadcastMsg(msg, notifType, flag)
    if flag == false then return end
    BountyBoard.NotifyAll(msg, notifType)
end

local function NotifyIfEnabled(ply, msg, notifType, flag)
    if flag == false then return end
    if not IsValid(ply) then return end
    BountyBoard.NotifyPlayer(ply, msg, notifType)
end

-- Currency formatting shorthand
local function Cur(amount)
    return CFG.CurrencySymbol .. string.Comma(amount)
end

-------------------------------------------------
-- Persistence
-------------------------------------------------

function BountyBoard.Save()
    if not file.IsDir("bountyboard", "DATA") then
        file.CreateDir("bountyboard")
    end
    file.Write(SAVE_PATH, util.TableToJSON(BountyBoard.Bounties, true))
end

function BountyBoard.Load()
    if not file.Exists(SAVE_PATH, "DATA") then return end

    local raw = file.Read(SAVE_PATH, "DATA")
    if not raw or raw == "" then return end

    local data = util.JSONToTable(raw)
    if not data then return end

    BountyBoard.Bounties = data

    local now = os.time()
    for id, bounty in pairs(BountyBoard.Bounties) do
        if (bounty.status == "active" or bounty.status == "hunting") and bounty.expiresAt and bounty.expiresAt <= now then
            bounty.status = "expired"
        end
    end

    BountyBoard.Save()
    Log("Loaded " .. table.Count(BountyBoard.Bounties) .. " bounties from disk.")
end

-------------------------------------------------
-- Core: Place
-------------------------------------------------

function BountyBoard.PlaceBounty(placer, targetSteamID, amount, reason)
    if not IsValid(placer) then return end

    -- Permission check
    if not CanPlace(placer) then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrNotAllowed, "error")
        return
    end

    -- Min players check
    if #player.GetAll() < CFG.MinPlayersOnline then
        BountyBoard.NotifyPlayer(placer, string.format(BountyBoard.Lang.ErrMinPlayers, CFG.MinPlayersOnline), "error")
        return
    end

    -- Validate amount
    amount = math.floor(tonumber(amount) or 0)
    if amount < CFG.MinBounty then
        BountyBoard.NotifyPlayer(placer, string.format(BountyBoard.Lang.ErrMinAmount, CFG.CurrencySymbol, CFG.MinBounty), "error")
        return
    end
    if amount > CFG.MaxBounty then
        BountyBoard.NotifyPlayer(placer, string.format(BountyBoard.Lang.ErrMaxAmount, CFG.CurrencySymbol, CFG.MaxBounty), "error")
        return
    end

    -- Self-bounty check
    if not CFG.AllowSelfBounty and placer:SteamID() == targetSteamID then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrSelfBounty, "error")
        return
    end

    -- Max active bounties
    if CountActiveBounties(placer:SteamID()) >= CFG.MaxActiveBounties then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrMaxBounties, "error")
        return
    end

    -- Stacking check
    if HasExistingBounty(targetSteamID) then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrAlreadyBountied, "error")
        return
    end

    -- Cooldown
    if not CheckCooldown(placer, "place") then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrCooldownPlace, "error")
        return
    end

    -- DarkRP money
    if not placer:canAfford(amount) then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrCannotAfford, "error")
        return
    end

    -- Find and validate target
    local targetPly = GetPlayerBySteamID(targetSteamID)
    if not IsValid(targetPly) then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrInvalidPlayer, "error")
        return
    end

    -- Immunity check
    if IsImmune(targetPly) then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrImmune, "error")
        return
    end

    -- All checks passed — deduct money
    placer:addMoney(-amount)
    SetCooldown(placer, "place")

    -- Sanitize reason
    reason = reason or ""
    if #reason > CFG.MaxReasonLength then
        reason = string.sub(reason, 1, CFG.MaxReasonLength)
    end
    if reason == "" then
        reason = CFG.DefaultReason
    end

    -- Create bounty
    local id = GenerateID()
    local bounty = {
        id = id,
        targetSteamID = targetSteamID,
        targetName = targetPly:Nick(),
        placerSteamID = placer:SteamID(),
        placerName = placer:Nick(),
        amount = amount,
        reason = reason,
        timestamp = os.time(),
        expiresAt = os.time() + CFG.BountyDuration,
        status = "active",
        hunterSteamID = nil,
        hunterName = nil,
    }

    BountyBoard.Bounties[id] = bounty
    BountyBoard.Save()

    Log(placer:Nick() .. " placed a bounty of " .. Cur(amount) .. " on " .. targetPly:Nick())

    -- Notifications
    BroadcastMsg(string.format(BountyBoard.Lang.BountyPlaced, targetPly:Nick(), CFG.CurrencySymbol, string.Comma(amount)), "info", CFG.BroadcastNewBounty)
    NotifyIfEnabled(targetPly, string.format(BountyBoard.Lang.YouAreBountied, CFG.CurrencySymbol, string.Comma(amount)), "error", CFG.NotifyTarget)

    BountyBoard.BroadcastBountyUpdate(bounty, "add")
end

-------------------------------------------------
-- Core: Accept
-------------------------------------------------

function BountyBoard.AcceptBounty(hunter, bountyID)
    if not IsValid(hunter) then return end

    -- Permission check
    if not CanHunt(hunter) then
        BountyBoard.NotifyPlayer(hunter, BountyBoard.Lang.ErrNotAllowed, "error")
        return
    end

    local bounty = BountyBoard.Bounties[bountyID]
    if not bounty then
        BountyBoard.NotifyPlayer(hunter, BountyBoard.Lang.ErrBountyNotFound, "error")
        return
    end

    if bounty.status ~= "active" then
        BountyBoard.NotifyPlayer(hunter, BountyBoard.Lang.ErrAlreadyHunting, "error")
        return
    end

    -- Cannot hunt yourself
    if hunter:SteamID() == bounty.targetSteamID then
        BountyBoard.NotifyPlayer(hunter, BountyBoard.Lang.ErrSelfBounty, "error")
        return
    end

    -- Cannot hunt own bounty
    if not CFG.AllowHuntOwnBounty and hunter:SteamID() == bounty.placerSteamID then
        BountyBoard.NotifyPlayer(hunter, BountyBoard.Lang.ErrNotAllowed, "error")
        return
    end

    -- Max hunts
    if CountActiveHunts(hunter:SteamID()) >= CFG.MaxActiveHunts then
        BountyBoard.NotifyPlayer(hunter, BountyBoard.Lang.ErrMaxHunts, "error")
        return
    end

    -- Cooldown
    if not CheckCooldown(hunter, "accept") then
        BountyBoard.NotifyPlayer(hunter, BountyBoard.Lang.ErrCooldownAccept, "error")
        return
    end

    SetCooldown(hunter, "accept")

    bounty.status = "hunting"
    bounty.hunterSteamID = hunter:SteamID()
    bounty.hunterName = hunter:Nick()
    BountyBoard.Save()

    BountyBoard.StartTracking(bountyID)

    Log(hunter:Nick() .. " accepted bounty on " .. bounty.targetName .. " (" .. Cur(bounty.amount) .. ")")

    BroadcastMsg(string.format(BountyBoard.Lang.BountyAccepted, hunter:Nick(), bounty.targetName), "info", CFG.BroadcastAccepted)

    local targetPly = GetPlayerBySteamID(bounty.targetSteamID)
    NotifyIfEnabled(targetPly, string.format(BountyBoard.Lang.YouAreHunted, hunter:Nick()), "error", CFG.NotifyTargetOnHunt)

    BountyBoard.BroadcastBountyUpdate(bounty, "update")
end

-------------------------------------------------
-- Core: Complete
-------------------------------------------------

function BountyBoard.CompleteBounty(bountyID, killer)
    local bounty = BountyBoard.Bounties[bountyID]
    if not bounty or bounty.status ~= "hunting" then return end

    bounty.status = "completed"
    BountyBoard.Save()
    BountyBoard.StopTracking(bountyID)

    if IsValid(killer) then
        killer:addMoney(bounty.amount)
    end

    local killerName = IsValid(killer) and killer:Nick() or bounty.hunterName
    Log(killerName .. " completed bounty on " .. bounty.targetName .. " (" .. Cur(bounty.amount) .. ")")

    BroadcastMsg(string.format(BountyBoard.Lang.BountyCompleted, killerName, bounty.targetName, CFG.CurrencySymbol, string.Comma(bounty.amount)), "success", CFG.BroadcastCompleted)
    BountyBoard.BroadcastBountyUpdate(bounty, "update")
end

-------------------------------------------------
-- Core: Cancel
-------------------------------------------------

function BountyBoard.CancelBounty(placer, bountyID)
    if not IsValid(placer) then return end

    local bounty = BountyBoard.Bounties[bountyID]
    if not bounty then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrBountyNotFound, "error")
        return
    end

    if bounty.placerSteamID ~= placer:SteamID() and not (CFG.AdminBypass and placer:IsAdmin()) then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrNotYourBounty, "error")
        return
    end

    if bounty.status == "hunting" then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrCannotCancel, "error")
        return
    end

    if bounty.status ~= "active" then
        BountyBoard.NotifyPlayer(placer, BountyBoard.Lang.ErrBountyNotFound, "error")
        return
    end

    bounty.status = "canceled"
    BountyBoard.Save()

    -- Refund the original placer (not necessarily the admin canceling)
    local originalPlacer = GetPlayerBySteamID(bounty.placerSteamID)
    if IsValid(originalPlacer) then
        originalPlacer:addMoney(bounty.amount)
    end

    Log(placer:Nick() .. " canceled bounty on " .. bounty.targetName .. " (" .. Cur(bounty.amount) .. " refunded)")

    BountyBoard.NotifyAll(string.format(BountyBoard.Lang.BountyCanceled, bounty.targetName), "info")
    BountyBoard.NotifyPlayer(placer, string.format(BountyBoard.Lang.Refunded, CFG.CurrencySymbol, string.Comma(bounty.amount)), "success")
    BountyBoard.BroadcastBountyUpdate(bounty, "update")
end

-------------------------------------------------
-- Core: Expire
-------------------------------------------------

function BountyBoard.ExpireBounty(bountyID)
    local bounty = BountyBoard.Bounties[bountyID]
    if not bounty then return end

    bounty.status = "expired"
    BountyBoard.Save()
    BountyBoard.StopTracking(bountyID)

    local placer = GetPlayerBySteamID(bounty.placerSteamID)
    if IsValid(placer) then
        placer:addMoney(bounty.amount)
        BountyBoard.NotifyPlayer(placer, string.format(BountyBoard.Lang.BountyExpired, bounty.targetName, CFG.CurrencySymbol, string.Comma(bounty.amount)), "info")
    end

    Log("Bounty on " .. bounty.targetName .. " expired (" .. Cur(bounty.amount) .. " refunded)")
    BountyBoard.BroadcastBountyUpdate(bounty, "update")
end

-------------------------------------------------
-- Tracking
-------------------------------------------------

function BountyBoard.StartTracking(bountyID)
    local timerName = "BountyTrack_" .. bountyID
    timer.Create(timerName, CFG.TrackingInterval, 0, function()
        local bounty = BountyBoard.Bounties[bountyID]
        if not bounty or bounty.status ~= "hunting" then
            timer.Remove(timerName)
            return
        end
        local hunter = GetPlayerBySteamID(bounty.hunterSteamID)
        local target = GetPlayerBySteamID(bounty.targetSteamID)
        if not IsValid(hunter) or not IsValid(target) then return end
        if not target:Alive() then return end
        BountyBoard.SendTargetPosition(hunter, target:GetPos())
    end)
end

function BountyBoard.StopTracking(bountyID)
    local timerName = "BountyTrack_" .. bountyID
    if timer.Exists(timerName) then timer.Remove(timerName) end
end

-------------------------------------------------
-- Hooks
-------------------------------------------------

hook.Add("PlayerDeath", "BountyBoard_PlayerDeath", function(victim, inflictor, attacker)
    if not IsValid(victim) or not IsValid(attacker) then return end
    if not attacker:IsPlayer() or victim == attacker then return end

    local victimSID = victim:SteamID()
    local attackerSID = attacker:SteamID()

    for id, bounty in pairs(BountyBoard.Bounties) do
        if bounty.status == "hunting" and bounty.targetSteamID == victimSID and bounty.hunterSteamID == attackerSID then
            BountyBoard.CompleteBounty(id, attacker)
            break
        end
    end
end)

hook.Add("PlayerDisconnected", "BountyBoard_PlayerDisconnected", function(ply)
    local steamid = ply:SteamID()
    for id, bounty in pairs(BountyBoard.Bounties) do
        if bounty.status == "hunting" and bounty.hunterSteamID == steamid then
            BountyBoard.StopTracking(id)
        end
    end
end)

-------------------------------------------------
-- Expiration timer
-------------------------------------------------

timer.Create("BountyBoard_ExpirationCheck", CFG.ExpirationCheckInterval, 0, function()
    local now = os.time()
    for id, bounty in pairs(BountyBoard.Bounties) do
        if (bounty.status == "active" or bounty.status == "hunting") and bounty.expiresAt and bounty.expiresAt <= now then
            BountyBoard.ExpireBounty(id)
        end
    end
end)

-------------------------------------------------
-- Startup
-------------------------------------------------

BountyBoard.Load()

for id, bounty in pairs(BountyBoard.Bounties) do
    if bounty.status == "hunting" then
        BountyBoard.StartTracking(id)
    end
end
