BountyBoard.Notifications = BountyBoard.Notifications or {}

local NOTIF_W = 340
local NOTIF_H = 44
local MARGIN = 5
local FADE_IN = 0.25
local SHOW = 4.5
local FADE_OUT = 0.4
local MAX = 5

local typeColors = {
    info    = BountyBoard.Colors.Amber,
    error   = BountyBoard.Colors.Danger,
    success = BountyBoard.Colors.Success,
}

function BountyBoard.AddNotification(msg, t)
    table.insert(BountyBoard.Notifications, 1, { message = msg, type = t or "info", start = CurTime() })
    while #BountyBoard.Notifications > MAX do table.remove(BountyBoard.Notifications) end
end

hook.Add("HUDPaint", "BountyBoard_Notifications", function()
    local scrW = ScrW()
    local now = CurTime()
    local rm = {}

    for i, n in ipairs(BountyBoard.Notifications) do
        local el = now - n.start
        local life = FADE_IN + SHOW + FADE_OUT
        if el > life then table.insert(rm, i) continue end

        local a = 1
        if el < FADE_IN then a = el / FADE_IN
        elseif el > FADE_IN + SHOW then a = 1 - (el - FADE_IN - SHOW) / FADE_OUT end
        a = math.Clamp(a, 0, 1)

        local slide = el < FADE_IN and (1 - a) * 50 or 0
        local x = scrW - NOTIF_W - 12 + slide
        local y = 12 + (i - 1) * (NOTIF_H + MARGIN)
        local accent = typeColors[n.type] or typeColors.info

        -- Shadow
        draw.RoundedBox(8, x + 1, y + 2, NOTIF_W, NOTIF_H, ColorAlpha(BountyBoard.Colors.Black, a * 40))
        -- Bg
        draw.RoundedBox(8, x, y, NOTIF_W, NOTIF_H, ColorAlpha(BountyBoard.Colors.Card, a * 240))
        -- Left accent
        draw.RoundedBoxEx(8, x, y, 3, NOTIF_H, ColorAlpha(accent, a * 255), true, false, true, false)
        -- Text
        draw.SimpleText(n.message, "BB_Notif", x + 14, y + NOTIF_H / 2, ColorAlpha(BountyBoard.Colors.TextPrimary, a * 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    for i = #rm, 1, -1 do table.remove(BountyBoard.Notifications, rm[i]) end
end)

net.Receive("BountyBoard_Notify", function()
    local msg = net.ReadString()
    local notifType = net.ReadString()

    -- Validate notifType against whitelist
    local validTypes = { info = true, error = true, success = true, warning = true }
    if not validTypes[notifType] then notifType = "info" end

    if IsValid(BountyBoard.DHTML) then
        local safeMsg = string.gsub(msg, "\\", "\\\\")
        safeMsg = string.gsub(safeMsg, "'", "\\'")
        safeMsg = string.gsub(safeMsg, '"', '\\"')
        safeMsg = string.gsub(safeMsg, "\n", "\\n")
        safeMsg = string.gsub(safeMsg, "\r", "\\r")
        safeMsg = string.gsub(safeMsg, "</", "<\\/")
        BountyBoard.DHTML:QueueJavascript("showNotification('" .. safeMsg .. "', '" .. notifType .. "')")
    else
        BountyBoard.AddNotification(msg, notifType)
    end
end)
