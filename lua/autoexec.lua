if game.PlaceId == 2818280787 then
    local function removeEggAnim()
        for _, obj in pairs(getgc(true)) do
            if typeof(obj) == "table" and rawget(obj, "OpenEgg") then
                obj.OpenEgg = function() end
            end
        end
    end

    local function autorejoin(x)
        local ts, p = game:GetService("TeleportService"), game:GetService("Players").LocalPlayer

        coroutine.wrap(function()
            while true do
                wait(x)
                pcall(function()
                    ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p)
                end)
            end
        end)()
    end

    -- Execute functions
    if AutoRemoveEggAnimation then
        removeEggAnim()
    end
    autorejoin(AutoRejoinInSeconds)
end
