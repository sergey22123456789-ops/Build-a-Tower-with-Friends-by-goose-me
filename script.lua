local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

local Window = Library.CreateLib("AutoFarm", "RJTheme3")

local Tab = Window:NewTab("Main")

local Section = Tab:NewSection("Auto Farm Settings")

local autoFarmEnabled = false
local farmConnection
local maxBackpack = 0

Section:NewTextBox("Max Backpack", "Enter maximum backpack capacity", function(txt)
    maxBackpack = tonumber(txt) or 0
    print("Max backpack set: " .. maxBackpack)
end)

local function getResources()
    local player = game.Players.LocalPlayer
    local stones = player:FindFirstChild("Stones")
    local bricks = player:FindFirstChild("Bricks")
    
    local stoneValue = stones and stones.Value or 0
    local brickValue = bricks and bricks.Value or 0
    
    return stoneValue, brickValue
end

local function isBackpackFull()
    local stone, brick = getResources()
    local total = stone + brick
    return total >= maxBackpack
end

local function pressE()
    local virtualInput = game:GetService("VirtualInputManager")
    virtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    virtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function teleportToSawCoordinates()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(
            40.8491211, 3.00899982, -21.5196381,
            0.00261973077, 9.56846868e-09, 0.999996543,
            6.81581582e-08, 1, -9.74705827e-09,
            -0.999996543, 6.81834607e-08, 0.00261973077
        )
        return true
    end
    return false
end

local function teleportToStone()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(
            53.959671, 3.00266671, -21.616888,
            -0.00351829501, -0.00140307471, -0.999992847,
            0.000359030149, 0.999998927, -0.00140434643,
            0.999993742, -0.000363968458, -0.00351778767
        )
        return true
    end
    return false
end

local function startAutoFarm()
    autoFarmEnabled = true
    
    farmConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not autoFarmEnabled then return end
        
        local character = game.Players.LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local stone, brick = getResources()
        
        -- Check if backpack is full
        if isBackpackFull() then
            print("Backpack full! Cannot add more resources")
            return
        end
        
        if stone > 0 then
            -- If has stones, process them at coordinates
            if teleportToSawCoordinates() then
                pressE()
                wait(0.1)
            end
        else
            -- If no stones, farm new ones
            if teleportToStone() then
                pcall(function()
                    game:GetService("ReplicatedStorage").KickStone:InvokeServer(true)
                end)
                wait(0.1)
            end
        end
        
        if brick > 0 then
            pcall(function()
                game:GetService("ReplicatedStorage").Place:InvokeServer(workspace.Floors.Base.Example.Part)
            end)
        end
    end)
end

local function stopAutoFarm()
    autoFarmEnabled = false
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
end

Section:NewToggle("Auto Farm", "Enable smart auto farm", function(state)
    if state then
        if maxBackpack == 0 then
            Library:Notify("Please set max backpack first!")
            return
        end
        startAutoFarm()
    else
        stopAutoFarm()
    end
end)

local InfoSection = Tab:NewSection("Resource Info")

local resourceText = "Loading..."
local resourceLabel = InfoSection:NewLabel(resourceText)

game:GetService("RunService").Heartbeat:Connect(function()
    local stone, brick = getResources()
    local total = stone + brick
    local backpackStatus = ""
    
    if maxBackpack > 0 then
        if isBackpackFull() then
            backpackStatus = " | BACKPACK FULL! ⚠️"
        else
            backpackStatus = " | Backpack: " .. total .. "/" .. maxBackpack
        end
    end
    
    resourceText = "Stones: " .. stone .. " | Bricks: " .. brick .. backpackStatus
    resourceLabel:UpdateLabel(resourceText)
end)

local ManualSection = Tab:NewSection("Manual Controls")

ManualSection:NewButton("TP to Saw + E", "Teleport to saw coordinates and press E", function()
    if teleportToSawCoordinates() then
        pressE()
    end
end)

ManualSection:NewButton("TP to Stone", "Teleport to stone", function()
    teleportToStone()
end)

ManualSection:NewButton("Kick Stone", "Mine stone", function()
    pcall(function()
        game:GetService("ReplicatedStorage").KickStone:InvokeServer(true)
    end)
end)

ManualSection:NewButton("Build Part", "Build part", function()
    pcall(function()
        game:GetService("ReplicatedStorage").Place:InvokeServer(workspace.Floors.Base.Example.Part)
    end)
end)

print("AutoFarm loaded! Set max backpack capacity first.")
