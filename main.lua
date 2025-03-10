local function startLoader(icons, loader, time)
    if icons == true then
        loadstring(game:HttpGet("https://fanta.voxlis.net/lua/icons.lua"))()
    end

    if loader == true then
        wait(time)
        loadstring(game:HttpGet("https://fanta.voxlis.net/lua/loader.lua"))()
    end
end

startLoader(true, true, 5)
