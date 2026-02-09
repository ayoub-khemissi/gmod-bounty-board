BountyBoard = BountyBoard or {}

-- Shared
include("bountyboard/shared/sh_config.lua")

if SERVER then
    -- Send client files
    AddCSLuaFile("bountyboard/shared/sh_config.lua")
    AddCSLuaFile("bountyboard/client/cl_fonts.lua")
    AddCSLuaFile("bountyboard/client/cl_notifications.lua")
    AddCSLuaFile("bountyboard/client/cl_compass.lua")
    AddCSLuaFile("bountyboard/client/cl_poster.lua")
    AddCSLuaFile("bountyboard/client/cl_menu.lua")

    -- Include server files
    include("bountyboard/server/sv_network.lua")
    include("bountyboard/server/sv_stats.lua")
    include("bountyboard/server/sv_bounties.lua")

    print("[BountyBoard] Server loaded successfully!")
end

if CLIENT then
    include("bountyboard/client/cl_fonts.lua")
    include("bountyboard/client/cl_notifications.lua")
    include("bountyboard/client/cl_compass.lua")
    include("bountyboard/client/cl_poster.lua")
    include("bountyboard/client/cl_menu.lua")

    print("[BountyBoard] Client loaded successfully!")
end
