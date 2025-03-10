local function startLoader(icons, loader, loadingscreen, time)
    if icons == true then
        loadstring(game:HttpGet("https://fanta.voxlis.net/lua/icons.lua"))()
    end

    if loadingscreen == true then
        loadstring(game:HttpGet("https://fanta.voxlis.net/lua/loading-screen.lua"))()
    end

    if loader == true then
    wait(2)
        loadstring(game:HttpGet("https://fanta.voxlis.net/lua/loader.lua"))()
    end
end

startLoader(true, true, true, 5)
