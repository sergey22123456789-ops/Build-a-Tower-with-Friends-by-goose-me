-- Library Link
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

-- Create UI Window
local Window = Library.CreateLib("AutoFarm", "RJTheme3")

-- Tab
local Tab = Window:NewTab("Main")

-- Section
local Section = Tab:NewSection("Auto Farm Settings")

-- Variables
local autoFarmEnabled = false
local farmConnection
local maxBackpack = 0
local currentPhase = "MINING" -- MINING, PROCESSING, BUILDING
local eHeld = false
local eConnection

-- Text box for max backpack input
Section:NewTextBox("Max Backpack", "Enter maximum backpack capacity", function(txt)
    maxBackpack = tonumber(txt) or 0
    print("Max backpack set: " .. maxBackpack)
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
            startRapidE() -- Быстро нажимаем E пока есть камни
            return true -- Still processing
        end
    else
        stopRapidE() -- Останавливаем когда камней нет
        currentPhase = "BUILDING" -- Switch to building when no stones left
        return false -- Done processing
    end
    return true
end

-- Function to build ALL bricks
local function buildAllBricks()
    local stone, brick = getResources()
    
    if brick > 0 then
        pcall(function()
            game:GetService("ReplicatedStorage").Place:InvokeServer(workspace.Floors.Base.Example.Part)
        end)
        return true -- Still building
    else
        currentPhase = "MINING" -- Switch back to mining when no bricks left
        return false -- Done building
    end
    return true
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
            stopRapidE() -- Останавливаем E при майнинге
            -- Mine until backpack is full
            if not isBackpackFull() then
                if teleportToStone() then
                    pcall(function()
                        game:GetService("ReplicatedStorage").KickStone:InvokeServer(true)
                    end)
                end
            else
                currentPhase = "PROCESSING" -- Switch to processing when full
            end
            
        elseif currentPhase == "PROCESSING" then
            -- Process ALL stones first with rapid E
            processAllStones()
            
        elseif currentPhase == "BUILDING" then
            stopRapidE() -- Останавливаем E при строительстве
            -- Build ALL bricks
            buildAllBricks()
        end
        
        wait(0.1)
    end)
end

-- Stop function
local function stopAutoFarm()
    autoFarmEnabled = false
    stopRapidE() -- Останавливаем E при остановке
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    currentPhase = "MINING"
end

-- Toggle button for auto farm
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

-- Info section
local InfoSection = Tab:NewSection("Resource Info")

-- Label for resource display
local resourceText = "Loading..."
local resourceLabel = InfoSection:NewLabel(resourceText)

-- Resource info update
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

-- Manual controls section
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

print("AutoFarm loaded! Set max backpack capacity first.")
