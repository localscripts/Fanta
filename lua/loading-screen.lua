local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("ImageLabel")
frame.Size = UDim2.new(0, 100, 0, 100) -- Adjust size as needed
frame.Position = UDim2.new(0.5, -50, 0.5, -50) -- Centered
frame.BackgroundTransparency = 1
frame.Image = "http://www.roblox.com/asset/?id=132374178857621"
frame.ImageTransparency = 1 -- Start fully invisible
frame.Parent = gui

local tweenService = game:GetService("TweenService")

-- Adjustable speeds!
local spinSpeed = 0.55 -- Lower value = faster spin (e.g., 0.5 = 2 spins per second)
local fadeSpeed = 0.33 -- Duration of fade-in and fade-out
local displayTime = 3 -- Time before fading out

-- Fade-in effect
local fadeInTweenInfo = TweenInfo.new(fadeSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadeInTween = tweenService:Create(frame, fadeInTweenInfo, {ImageTransparency = 0})

-- Spin animation (speed adjustable)
local rotationTweenInfo = TweenInfo.new(spinSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1) -- Infinite spin
local rotationTween = tweenService:Create(frame, rotationTweenInfo, {Rotation = 360})

-- Play animations
fadeInTween:Play()
rotationTween:Play()

fadeInTween.Completed:Connect(function()
    -- Wait before fading out
    task.wait(displayTime)

    -- Fade out effect
    local fadeOutTweenInfo = TweenInfo.new(fadeSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeOutTween = tweenService:Create(frame, fadeOutTweenInfo, {ImageTransparency = 1})
    fadeOutTween:Play()

    fadeOutTween.Completed:Connect(function()
        gui:Destroy()
    end)
end)
