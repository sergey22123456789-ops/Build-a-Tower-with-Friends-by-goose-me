-- Library Link
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

-- Create UI Window
local Window = Library.CreateLib("AutoFarm", "RJTheme3")

-- Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Farm Settings")

-- Variables
local autoFarmEnabled = false
local farmConnection
local maxBackpack = 0
local currentPhase = "MINING"
local eHeld = false
local eConnection
local bulkBuildAmount = 10

-- Text box for max backpack input
MainSection:NewTextBox("Max Backpack", "Enter maximum backpack capacity", function(txt)
    maxBackpack = tonumber(txt) or 0
    print("Max backpack set: " .. maxBackpack)
end)

-- Text box for bulk build amount
MainSection:NewTextBox("Bulk Build Amount", "How many bricks to build at once (10-20)", function(txt)
    bulkBuildAmount = math.clamp(tonumber(txt) or 10, 1, 50)
    print("Bulk build amount set: " .. bulkBuildAmount)
end)

-- Function to get resources
local function getResources()
    local player = game.Players.LocalPlayer
    local stones = player:FindFirstChild("Stones")
    local bricks = player:FindFirstChild("Bricks")
    
    local stoneValue = stones and stones.Value or 0
    local brickValue = bricks and bricks.Value or 0
    
    return stoneValue, brickValue
end

-- Function to check if backpack is full
local function isBackpackFull()
    local stone, brick = getResources()
    local total = stone + brick
    return total >= maxBackpack
end

-- Function to hold E (rapid press instead of hold)
local function startRapidE()
    if eConnection then
        eConnection:Disconnect()
    end
    
    eConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local virtualInput = game:GetService("VirtualInputManager")
        virtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        virtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    eHeld = true
end

-- Function to stop rapid E
local function stopRapidE()
    if eConnection then
        eConnection:Disconnect()
        eConnection = nil
    end
    eHeld = false
end

-- Function to teleport to saw coordinates
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

-- Function to teleport to stone
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

-- Function to process ALL stones with rapid E
local function processAllStones()
    local stone, brick = getResources()
    
    if stone > 0 then
        if teleportToSawCoordinates() then
            startRapidE()
            return true
        end
    else
        stopRapidE()
        currentPhase = "BUILDING"
        return false
    end
    return true
end

-- Function for ultra-fast bulk building
local function ultraFastBulkBuild()
    local Part = workspace.Floors.Base.Parts.Part
    local PlaceEvent = game:GetService("ReplicatedStorage").Place
    local stone, brick = getResources()
    
    if brick >= bulkBuildAmount then
        for i = 1, bulkBuildAmount do
            pcall(function()
                PlaceEvent:InvokeServer(Part)
            end)
        end
        return true
    end
    return false
end

-- Function to build ALL bricks with bulk method
local function buildAllBricks()
    local stone, brick = getResources()
    
    if brick > 0 then
        ultraFastBulkBuild()
        return true
    else
        currentPhase = "MINING"
        return false
    end
end

-- Main auto farm function
local function startAutoFarm()
    autoFarmEnabled = true
    
    farmConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not autoFarmEnabled then return end
        
        local character = game.Players.LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local stone, brick = getResources()
        
        -- Phase logic
        if currentPhase == "MINING" then
            stopRapidE()
            if not isBackpackFull() then
                if teleportToStone() then
                    pcall(function()
                        game:GetService("ReplicatedStorage").KickStone:InvokeServer(true)
                    end)
                end
            else
                currentPhase = "PROCESSING"
            end
            
        elseif currentPhase == "PROCESSING" then
            processAllStones()
            
        elseif currentPhase == "BUILDING" then
            stopRapidE()
            buildAllBricks()
        end
        
        wait(0.1)
    end)
end

-- Stop function
local function stopAutoFarm()
    autoFarmEnabled = false
    stopRapidE()
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    currentPhase = "MINING"
end

-- Toggle button for auto farm
MainSection:NewToggle("Auto Farm", "Enable smart auto farm", function(state)
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

-- Info section
local InfoSection = MainTab:NewSection("Resource Info")
local resourceText = "Loading..."
local resourceLabel = InfoSection:NewLabel(resourceText)

-- Resource info update
game:GetService("RunService").Heartbeat:Connect(function()
    local stone, brick = getResources()
    local total = stone + brick
    local backpackStatus = ""
    local farmStatus = currentPhase
    local eStatus = eHeld and " | E: RAPID FIRE 🔥" or " | E: off"
    local buildInfo = " | Bulk: " .. bulkBuildAmount
    
    if maxBackpack > 0 then
        if currentPhase == "MINING" then
            backpackStatus = " | Backpack: " .. total .. "/" .. maxBackpack
            farmStatus = "⛏️ MINING STONES"
        elseif currentPhase == "PROCESSING" then
            backpackStatus = " | BACKPACK FULL! ⚠️"
            farmStatus = "🔄 PROCESSING (RAPID E)"
        else
            backpackStatus = " | Backpack: " .. total .. "/" .. maxBackpack
            farmStatus = "🏗️ BULK BUILDING x" .. bulkBuildAmount
        end
    end
    
    resourceText = "Stones: " .. stone .. " | Bricks: " .. brick .. backpackStatus .. " | " .. farmStatus .. eStatus .. buildInfo
    resourceLabel:UpdateLabel(resourceText)
end)

-- Manual controls section
local ManualSection = MainTab:NewSection("Manual Controls")

ManualSection:NewButton("Start Rapid E at Saw", "Teleport to saw and RAPID E", function()
    if teleportToSawCoordinates() then
        startRapidE()
    end
end)

ManualSection:NewButton("Stop Rapid E", "Stop rapid E", function()
    stopRapidE()
end)

ManualSection:NewButton("Bulk Build Now", "Build " .. bulkBuildAmount .. " bricks at once", function()
    ultraFastBulkBuild()
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
        game:GetService("ReplicatedStorage").Place:InvokeServer(workspace.Floors.Base.Parts.Part)
    end)
end)

-- Teleports Tab
local TeleportsTab = Window:NewTab("Teleports")
local TeleportsSection = TeleportsTab:NewSection("Locations")

-- Teleport functions
TeleportsSection:NewButton("Stone", "Teleport to stone", function()
    teleportToStone()
end)

TeleportsSection:NewButton("Saw", "Teleport to saw", function()
    teleportToSawCoordinates()
end)

TeleportsSection:NewButton("Base", "Teleport to base", function()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
    end
end)

TeleportsSection:NewButton("Spawn", "Teleport to spawn", function()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
    end
end)

-- Upgrades Tab
local UpgradesTab = Window:NewTab("Upgrades")
local UpgradesSection = UpgradesTab:NewSection("Multiplier Upgrades")

-- Upgrade functions
UpgradesSection:NewButton("Upgrade All Multipliers", "Upgrade Stone, Cutter and Place", function()
    local Upgrade = game:GetService("ReplicatedStorage").Upgrade
    for _,upgrade in pairs({"StoneMultiplier","CutterMultiplier","PlaceMultiplier"}) do
        pcall(function() Upgrade:InvokeServer(upgrade,1e-117,2) end)
    end
    Library:Notify("All multipliers upgraded!")
end)

UpgradesSection:NewButton("Stone Multiplier", "Upgrade stone multiplier", function()
    pcall(function()
        game:GetService("ReplicatedStorage").Upgrade:InvokeServer("StoneMultiplier",1e-117,2)
    end)
    Library:Notify("Stone multiplier upgraded!")
end)

UpgradesSection:NewButton("Cutter Multiplier", "Upgrade cutter multiplier", function()
    pcall(function()
        game:GetService("ReplicatedStorage").Upgrade:InvokeServer("CutterMultiplier",1e-117,2)
    end)
    Library:Notify("Cutter multiplier upgraded!")
end)

UpgradesSection:NewButton("Place Multiplier", "Upgrade place multiplier", function()
    pcall(function()
        game:GetService("ReplicatedStorage").Upgrade:InvokeServer("PlaceMultiplier",1e-117,2)
    end)
    Library:Notify("Place multiplier upgraded!")
end)

-- Enable saw permanently in background
spawn(function()
    while wait(0.5) do
        pcall(function()
            workspace.Saws.Saws:GetChildren()[7].Use.UsePP.Enabled = true
        end)
    end
end)
