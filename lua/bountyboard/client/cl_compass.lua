BountyBoard.TrackingPos = nil
local UNITS_PER_METER = 52.5

local function DrawArrow(cx, cy, angle, size, color)
    local poly = {
        { x = cx + math.cos(angle) * size, y = cy + math.sin(angle) * size },
        { x = cx + math.cos(angle + 2.4) * size * 0.4, y = cy + math.sin(angle + 2.4) * size * 0.4 },
        { x = cx + math.cos(angle + math.pi) * size * 0.12, y = cy + math.sin(angle + math.pi) * size * 0.12 },
        { x = cx + math.cos(angle - 2.4) * size * 0.4, y = cy + math.sin(angle - 2.4) * size * 0.4 },
    }
    surface.SetDrawColor(color)
    draw.NoTexture()
    surface.DrawPoly(poly)
end

local function DrawRing(cx, cy, r, t, segs, col)
    for i = 0, segs - 1 do
        local a1 = (i / segs) * math.pi * 2
        local a2 = ((i + 1) / segs) * math.pi * 2
        surface.SetDrawColor(col)
        draw.NoTexture()
        surface.DrawPoly({
            { x = cx + math.cos(a1) * r, y = cy + math.sin(a1) * r },
            { x = cx + math.cos(a2) * r, y = cy + math.sin(a2) * r },
            { x = cx + math.cos(a2) * (r - t), y = cy + math.sin(a2) * (r - t) },
            { x = cx + math.cos(a1) * (r - t), y = cy + math.sin(a1) * (r - t) },
        })
    end
end

hook.Add("HUDPaint", "BountyBoard_Compass", function()
    if not BountyBoard.TrackingPos then return end
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end

    local dir = BountyBoard.TrackingPos - lp:GetPos()
    local dist = dir:Length2D()
    local distM = math.Round(dist / UNITS_PER_METER)
    local relAngle = math.atan2(dir.y, dir.x) - math.rad(lp:EyeAngles().y)

    local scrH = ScrH()
    local cx, cy = 90, scrH - 90
    local sz = 120

    local pulse = dist < 2000 and math.abs(math.sin(CurTime() * 3)) or 0
    local px, py = cx - sz / 2, cy - sz / 2

    -- Shadow
    draw.RoundedBox(12, px + 2, py + 2, sz, sz, Color(0, 0, 0, 50))
    -- Background
    draw.RoundedBox(12, px, py, sz, sz, BountyBoard.Colors.Card)
    draw.RoundedBox(12, px, py, sz, 3, BountyBoard.Colors.Amber)

    -- Danger pulse
    if pulse > 0.01 then
        draw.RoundedBox(12, px, py, sz, sz, ColorAlpha(BountyBoard.Colors.Danger, pulse * 20))
    end

    -- Ring
    DrawRing(cx, cy + 4, 36, 1.5, 48, BountyBoard.Colors.Border)

    -- Arrow
    DrawArrow(cx, cy + 4, -relAngle + math.pi / 2, 20, BountyBoard.Colors.Amber)

    -- Center dot
    draw.RoundedBox(2, cx - 2, cy + 2, 4, 4, BountyBoard.Colors.Amber)

    -- Label
    draw.SimpleText(BountyBoard.Config.UI.CompassTarget, "BB_CompassSm", cx, py + 14, BountyBoard.Colors.Amber, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Distance
    draw.SimpleText(distM .. "m", "BB_Compass", cx, py + sz - 16, BountyBoard.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Nearby warning
    if dist < 1000 then
        local blink = math.abs(math.sin(CurTime() * 4))
        draw.SimpleText(BountyBoard.Config.UI.CompassNearby, "BB_CompassSm", cx, py + sz - 32, ColorAlpha(BountyBoard.Colors.Danger, blink * 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

net.Receive("BountyBoard_UpdatePosition", function()
    BountyBoard.TrackingPos = net.ReadVector()
end)
