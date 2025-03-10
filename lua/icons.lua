local groupID = 35623787
local Players = game:GetService("Players")

-- Map group rank to icon ID
local rankToIconID = {
    [1] = "http://www.roblox.com/asset/?id=86334114184370",   -- Free // Grey Fanta
    [2] = "http://www.roblox.com/asset/?id=132374178857621",  -- Premium // Black Fanta
    [3] = "http://www.roblox.com/asset/?id=134359082397174",  -- Extreme // Grape Fanta
    [255] = "http://www.roblox.com/asset/?id=93377408103568", -- Owner // Orange Fanta
}

local function updatePlayerIcon(player)
    local success, isInGroup = pcall(function()
        return player:IsInGroup(groupID)
    end)
    
    if success and isInGroup then
        wait(5)
        
        -- Get the player's rank in the group
        local rank = player:GetRankInGroup(groupID)
        
        -- Get the icon ID based on the rank
        local iconID = rankToIconID[rank] or "http://www.roblox.com/asset/?id=14629466041" -- Default icon if rank is not found
        
        local iconPath = "game:GetService(\"CoreGui\").RoactAppExperimentProvider.Children.OffsetFrame.PlayerScrollList.SizeOffsetFrame.ScrollingFrameContainer.ScrollingFrameClippingFrame.ScollingFrame.OffsetUndoFrame[\"p_" .. player.UserId .. "\"].ChildrenFrame.NameFrame.BGFrame.OverlayFrame.PlayerIcon"
        
        local success, icon = pcall(function()
            return loadstring("return " .. iconPath)()
        end)
        
        if success and icon then
            icon.Image = iconID
            icon.ImageRectOffset, icon.ImageRectSize = Vector2.new(0, 0), Vector2.new(0, 0)
        end
    end
end

local function onPlayerAdded(player)
    updatePlayerIcon(player)
end

-- Check existing players when the script starts
for _, player in pairs(Players:GetPlayers()) do
    updatePlayerIcon(player)
end

-- Recheck when a new player is added
Players.PlayerAdded:Connect(onPlayerAdded
