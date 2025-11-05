
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

local Window = Library.CreateLib("AutoFarm", "RJTheme3")

local Tab = Window:NewTab("Main")

local Section = Tab:NewSection("Auto Farm Settings")

local autoFarmEnabled = false
local farmConnection
local maxBackpack = 0
local currentPhase = "MINING" -- MINING, PROCESSING, BUILDING
local eHeld = false
local eConnection

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

local function stopRapidE()
    if eConnection then
        eConnection:Disconnect()
        eConnection = nil
    end
    eHeld = false
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

local function processAllStones()
    local stone, brick = getResources()
    
    if stone > 0 then
        if teleportToSawCoordinates() then
            startRapidE()
            return true
        end
    else
        stopRapidE()
        currentPhase = "BUILDING" left
        return false
    end
    return true
end

local function buildAllBricks()
    local stone, brick = getResources()
    
    if brick > 0 then
        pcall(function()
            game:GetService("ReplicatedStorage").Place:InvokeServer(workspace.Floors.Base.Example.Part)
        end)
        return true
    else
        currentPhase = "MINING"  bricks left
        return false 
    end
    return true
end

local function startAutoFarm()
    autoFarmEnabled = true
    
    farmConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not autoFarmEnabled then return end
        
        local character = game.Players.LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local stone, brick = getResources()
        
        -- Phase logic
        if currentPhase == "MINING" then
            stopRapidE() -- Останавливаем E при майнинге
            -- Mine until backpack is full
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

local function stopAutoFarm()
    autoFarmEnabled = false
    stopRapidE() 
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    currentPhase = "MINING"
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
    local farmStatus = currentPhase
    local eStatus = eHeld and " | E: RAPID FIRE 🔥" or " | E: off"
    
    if maxBackpack > 0 then
        if currentPhase == "MINING" then
            backpackStatus = " | Backpack: " .. total .. "/" .. maxBackpack
            farmStatus = "⛏️ MINING STONES"
        elseif currentPhase == "PROCESSING" then
            backpackStatus = " | BACKPACK FULL! ⚠️"
            farmStatus = "🔄 PROCESSING (RAPID E)"
        else
            backpackStatus = " | Backpack: " .. total .. "/" .. maxBackpack
            farmStatus = "🏗️ BUILDING ALL BRICKS"
        end
    end
    
    resourceText = "Stones: " .. stone .. " | Bricks: " .. brick .. backpackStatus .. " | " .. farmStatus .. eStatus
    resourceLabel:UpdateLabel(resourceText)
end)

local ManualSection = Tab:NewSection("Manual Controls")

ManualSection:NewButton("Start Rapid E at Saw", "Teleport to saw and RAPID E", function()
    if teleportToSawCoordinates() then
        startRapidE()
    end
end)

ManualSection:NewButton("Stop Rapid E", "Stop rapid E", function()
    stopRapidE()
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

print ("it was hot fix if not work im idk")
