-- Poster is now handled as a modal inside the DHTML menu (cl_menu.lua)
-- This file provides a standalone fallback that just opens the main menu.

function BountyBoard.OpenPoster(bounty)
    if not bounty then return end
    BountyBoard.OpenMenu()
end
