if game.PlaceId == 2818280787 then
    
    local function removeEggAnim(x)
        if x == true then
        for _, obj in pairs(getgc(true)) do
            if typeof(obj) == "table" and rawget(obj, "OpenEgg") then
                obj.OpenEgg = function()
                end
            end
        end
    end
end


    function autorejoin(x)
        local ts, p = game:GetService("TeleportService"), game:GetService("Players").LocalPlayer

        while true do
            wait(x)
            pcall(
                function()
                    ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p)
                end
            )
        end
    end



    removeEggAnim(AutoRemoveEggAnimation)
    autorejoin(AutoRejoinInSeconds)
end
