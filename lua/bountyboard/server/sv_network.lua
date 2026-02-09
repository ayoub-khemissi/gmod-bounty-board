-- Network strings
util.AddNetworkString("BountyBoard_RequestBounties")
util.AddNetworkString("BountyBoard_SendBounties")
util.AddNetworkString("BountyBoard_PlaceBounty")
util.AddNetworkString("BountyBoard_AcceptBounty")
util.AddNetworkString("BountyBoard_CancelBounty")
util.AddNetworkString("BountyBoard_UpdatePosition")
util.AddNetworkString("BountyBoard_Notify")
util.AddNetworkString("BountyBoard_BountyUpdate")
util.AddNetworkString("BountyBoard_RequestStats")
util.AddNetworkString("BountyBoard_SendStats")
util.AddNetworkString("BountyBoard_RequestLeaderboard")
util.AddNetworkString("BountyBoard_SendLeaderboard")

-------------------------------------------------
-- Sender helpers
-------------------------------------------------

function BountyBoard.NotifyPlayer(ply, msg, notifType)
    notifType = notifType or "info"
    net.Start("BountyBoard_Notify")
        net.WriteString(msg)
        net.WriteString(notifType)
    net.Send(ply)
end

function BountyBoard.NotifyAll(msg, notifType)
    notifType = notifType or "info"
    net.Start("BountyBoard_Notify")
        net.WriteString(msg)
        net.WriteString(notifType)
    net.Broadcast()
end

function BountyBoard.BroadcastBountyUpdate(bounty, action)
    net.Start("BountyBoard_BountyUpdate")
        net.WriteString(action)
        net.WriteTable(BountyBoard.SanitizeBounty(bounty))
    net.Broadcast()
end

function BountyBoard.SendBounties(ply)
    local sanitized = {}
    for id, bounty in pairs(BountyBoard.Bounties) do
        if bounty.status == "active" or bounty.status == "hunting" then
            table.insert(sanitized, BountyBoard.SanitizeBounty(bounty))
        end
    end

    net.Start("BountyBoard_SendBounties")
        net.WriteTable(sanitized)
    net.Send(ply)
end

function BountyBoard.SendTargetPosition(hunter, targetPos)
    -- Add random offset for imprecision
    local offset = Vector(
        math.random(-BountyBoard.Config.TrackingImprecision, BountyBoard.Config.TrackingImprecision),
        math.random(-BountyBoard.Config.TrackingImprecision, BountyBoard.Config.TrackingImprecision),
        0
    )
    local imprecisePos = targetPos + offset

    net.Start("BountyBoard_UpdatePosition")
        net.WriteVector(imprecisePos)
    net.Send(hunter)
end

-- Strip internal data before sending to clients
function BountyBoard.SanitizeBounty(bounty)
    return {
        id = bounty.id,
        targetSteamID = bounty.targetSteamID,
        targetName = bounty.targetName,
        placerSteamID = bounty.placerSteamID,
        placerName = bounty.placerName,
        amount = bounty.amount,
        reason = bounty.reason,
        timestamp = bounty.timestamp,
        expiresAt = bounty.expiresAt,
        status = bounty.status,
        hunterSteamID = bounty.hunterSteamID,
        hunterName = bounty.hunterName,
    }
end

-------------------------------------------------
-- Receivers
-------------------------------------------------

net.Receive("BountyBoard_RequestBounties", function(len, ply)
    BountyBoard.SendBounties(ply)
end)

net.Receive("BountyBoard_PlaceBounty", function(len, ply)
    local targetSteamID = net.ReadString()
    local amount = net.ReadInt(32)
    local reason = net.ReadString()

    BountyBoard.PlaceBounty(ply, targetSteamID, amount, reason)
end)

net.Receive("BountyBoard_AcceptBounty", function(len, ply)
    local bountyID = net.ReadString()

    BountyBoard.AcceptBounty(ply, bountyID)
end)

net.Receive("BountyBoard_CancelBounty", function(len, ply)
    local bountyID = net.ReadString()

    BountyBoard.CancelBounty(ply, bountyID)
end)

-------------------------------------------------
-- Stats & Leaderboard
-------------------------------------------------

function BountyBoard.SendPlayerStats(ply)
    local stats = BountyBoard.GetStats(ply:SteamID())
    net.Start("BountyBoard_SendStats")
        net.WriteTable(stats)
    net.Send(ply)
end

function BountyBoard.SendLeaderboard(ply, category)
    local top, allEntries = BountyBoard.GetLeaderboard(category, 10)

    -- Find player position if not in top 10
    local playerRank = 0
    local playerValue = 0
    local plySID = ply:SteamID()
    for i, entry in ipairs(allEntries) do
        if entry.steamid == plySID then
            playerRank = i
            playerValue = entry.value
            break
        end
    end

    net.Start("BountyBoard_SendLeaderboard")
        net.WriteString(category)
        net.WriteTable(top)
        net.WriteUInt(playerRank, 16)
        net.WriteUInt(playerValue, 32)
    net.Send(ply)
end

net.Receive("BountyBoard_RequestStats", function(len, ply)
    BountyBoard.SendPlayerStats(ply)
end)

net.Receive("BountyBoard_RequestLeaderboard", function(len, ply)
    local category = net.ReadString()
    -- Validate category
    local valid = { bountiesCompleted = true, totalEarned = true, totalSpent = true }
    if not valid[category] then category = "bountiesCompleted" end
    BountyBoard.SendLeaderboard(ply, category)
end)
