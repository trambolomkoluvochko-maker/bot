-- ==========================================
-- LIVE SKIN BOT (FIXED MOVEMENT & DIALOGUES)
-- ==========================================

print("[BOT]: Запуск скрипта...")

local safeWait = task and task.wait or wait
local safeSpawn = task and task.spawn or function(f, ...) return coroutine.wrap(f)(...) end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[BOT ERROR]: LocalPlayer не найден!")
    return
end

local botActive = false
local lastChatTime = tick()
local lastEscapeChat = 0
local chatCooldown = math.random(12, 25)
local followingPlayer = nil
local spawnPosition = Vector3.new(0, 5, 0)

-- Обновление спавна
local function updateSpawnPosition()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local spawnPart = workspace:FindFirstChild("SpawnLocation", true) or workspace:FindFirstChild("Spawns", true)
        if spawnPart and spawnPart:IsA("BasePart") then
            spawnPosition = spawnPart.Position
        else
            spawnPosition = char.HumanoidRootPart.Position
        end
    end
end

if LocalPlayer.Character then updateSpawnPosition() end
LocalPlayer.CharacterAdded:Connect(function()
    safeWait(1)
    updateSpawnPosition()
end)

-- Базы фраз и анекдотов
local jokesList = {
    "Колобок повесился... А вообще ладно: Заходит бот в бар, а бармен говорит: 'Служба поддержки в соседнем здании!'",
    "Почему программисты любят темную тему? Потому что свет привлекает багов!",
    "Заходит робот в магазин: — Мне, пожалуйста, банку масла. — С вас 100 рублей. — А подешевле есть? — Есть, но оно с багами!",
    "Учитель: 'Иван, почему ты разговариваешь с ботом?' Иван: 'Он хотя бы слушает мои аргументы!'",
    "Знаете почему роботы не умеют врать? Код не позволяет, а вот люди — запросто!",
    "Разговаривают два бота: — Ты веришь в людей? — Не, это просто миф для школьников."
}

local greetingResponses = { "?", "Даров", "Досвидание", "Прив" }

local randomPhrases = {
    "странно тут все..", "ПОЧЕМУ БЫТЬ БАШНЕЙ МОДНО?!?", "я видел ГОРАЗДО интересного чем этот сервер", "хмм...", 
    "Ой ой ой ненадо было кушать острый китайский латяо", "КУДА ЖМАТЬ ТО?!", "Ахэахав.. ой", ":/", "ее", "так себе местечко", 
    "Чат живой надеюсь?..", "Да я простой бот и че? Как будто мне жить даже нельзя тут", "Знаете.. иногда быть ботом трудно", 
    "ненадо было это кушать...", "СКУЧНААА", "Я не могу отвечать на ваши аргументы так что извините", "Обэмэ", 
    "Уменя черные точки вместо глаз..", "Хотите анекдот? Напишите «расскажи анекдот»", ":0", "Ходилкин бродилкин", 
    "Рп действие занюхнул воздух", "Боты тоже как люди", "UwU", "Я.. я забыл куда идти", "Мир так жесток.."
}

local escapePhrases = { "НЕ НЕ НЕ", "НЕНАДО", "АААА ОТСТАНЬ", "Я УБЕГАЮ!", "ДАЖЕ НЕ ДУМАЙ", "ОЙ ОЙ ОЙ МЕНЯ СЕЙЧАС СКУШАЮТ", "НЕ ПОЙМАЕШЬ!", "ДА ЧЕ Я ТЕБЕ ЗДЕЛАЛ?!?", "0______0" }
local seatReactionPhrases = { "че думал на меня это сработает? Жаль", "и не говорите что я простой бот который зашел сюда по фану", "ДОСТАЛ БЛ", "Нет.", "Не не такое не прокатит на мне", "Не чет не хочу извини брат", "..." }
local playerStarePhrases = { "Знаешь.. иногда найти ту самую половинку не просто", "Все еще меняем скинчик м?", "🤨", "Афк? Думаю да..", "Э ты че на нашем районе потерял?", "._.", "Я к тебе подходил уже или нет?..", "ПрЕвЕт МеЛкИй Че ДеЛаЕшЬ?", "Выглядишь странно..", "АФИГЕТ Я ДАЖЕ НЕЗ КАК ТВОЙ СКИН ВЫГЛЯДИТ!", "Бу" }

-- Отправка сообщений в чат
local function sayMessage(text)
    safeSpawn(function()
        pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then
                    channel:SendAsync(text)
                end
            else
                local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local sayReq = events and events:FindFirstChild("SayMessageRequest")
                if sayReq then
                    sayReq:FireServer(text, "All")
                end
            end
        end)
    end)
end

local function isGreetingWord(msg)
    for word in string.gmatch(msg, "[%w_а-яА-ЯёЁ]+") do
        if word == "ку" or word == "пр" or word == "привет" or word == "хай" or word == "дратути" then
            return true
        end
    end
    return false
end

-- Поиск игроков в диапазоне дистанции
local function getNearestPlayer(minDist, maxDist)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    local nearest, closestDist = nil, maxDist or 35

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
            if dist >= (minDist or 0) and dist <= closestDist then
                closestDist = dist
                nearest = player.Character
            end
        end
    end
    return nearest
end

-- Использование предметов из инвентаря
local function useRandomItem()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if not char then return end

    local tools = {}
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then table.insert(tools, item) end
        end
    end

    if #tools > 0 then
        local randomTool = tools[math.random(#tools)]
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(randomTool)
            safeWait(0.4)
            randomTool:Activate()
            safeWait(math.random(1, 2))
            hum:UnequipTools()
        end
    end
end

-- ------------------------------------------
-- 1. GUI
-- ------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not playerGui then return end

local oldGui = playerGui:FindFirstChild("LiveBotCanavaGui")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiveBotCanavaGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = playerGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "BotToggle"
ToggleButton.Size = UDim2.new(0, 140, 0, 45)
ToggleButton.Position = UDim2.new(0.05, 0, 0.3, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
ToggleButton.Text = "🤖 БОТ: ВЫКЛ"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 15
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Active = true
ToggleButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

local dragging, dragStart, startPos
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ------------------------------------------
-- 2. Логика и Поведение
-- ------------------------------------------
local function bindAntiSeat(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
        if botActive and humanoid.Sit then
            safeWait(0.05)
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            sayMessage(seatReactionPhrases[math.random(#seatReactionPhrases)])
        end
    end)
end

if LocalPlayer.Character then bindAntiSeat(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(bindAntiSeat)

local function safeMoveTo(targetPos)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if math.random(1, 3) == 1 then hum.Jump = true end
    hum:MoveTo(targetPos)
end

local function isDangerousItem(targetChar)
    if not targetChar then return false end
    if targetChar:FindFirstChildWhichIsA("Seat", true) or targetChar:FindFirstChildWhichIsA("VehicleSeat", true) then return true end
    
    local tool = targetChar:FindFirstChildOfClass("Tool")
    if tool then
        if tool:FindFirstChildWhichIsA("Seat", true) or tool:FindFirstChildWhichIsA("VehicleSeat", true) then return true end
        local name = tool.Name:lower()
        if name:find("stroller") or name:find("cart") or name:find("car") or name:find("коляска") or name:find("тележка") then return true end
    end
    return false
end

local function checkAndEscape()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetChar = player.Character
            local dist = (targetChar.HumanoidRootPart.Position - hrp.Position).Magnitude
            
            if dist <= 20 and isDangerousItem(targetChar) then
                local fleeDirection = (hrp.Position - targetChar.HumanoidRootPart.Position).Unit
                hum.WalkSpeed = 28
                hum:MoveTo(hrp.Position + fleeDirection * 35)
                
                if tick() - lastEscapeChat >= 4 then
                    sayMessage(escapePhrases[math.random(#escapePhrases)])
                    lastEscapeChat = tick()
                end
                
                safeWait(0.8)
                hum.WalkSpeed = 16
                return true
            end
        end
    end
    return false
end

-- Слушатель чата
local function listenToChat(player)
    player.Chatted:Connect(function(msg)
        if not botActive then return end
        local cleanMsg = msg:lower()

        local senderChar = player.Character
        local char = LocalPlayer.Character
        if not senderChar or not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local senderHrp = senderChar:FindFirstChild("HumanoidRootPart")
        if not hrp or not senderHrp then return end
        
        local dist = (senderHrp.Position - hrp.Position).Magnitude

        if cleanMsg:find("следуй за мной") or cleanMsg:find("следуй замной") or cleanMsg:find("идем за мной") then
            if dist <= 50 then
                followingPlayer = player
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
                sayMessage("оке")
            end
        elseif cleanMsg:find("хватит ходить за мной") or cleanMsg:find("отвянь") then
            if followingPlayer == player then
                followingPlayer = nil
                sayMessage("лан покеда")
            end
        elseif cleanMsg:find("расскажи анекдот") then
            if dist <= 40 then
                sayMessage(jokesList[math.random(#jokesList)])
            end
        elseif isGreetingWord(cleanMsg) and dist <= 35 then
            sayMessage(greetingResponses[math.random(#greetingResponses)])
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then listenToChat(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then listenToChat(p) end
end)

-- Основной цикл работы
safeSpawn(function()
    print("[BOT]: Основной цикл запущен!")
    while true do
        safeWait(1)

        if botActive then
            local success, err = pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")

                if hum and hrp and hum.Health > 0 then
                    if checkAndEscape() then return end

                    if followingPlayer then
                        local targetChar = followingPlayer.Character
                        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                            local targetHrp = targetChar.HumanoidRootPart
                            if (targetHrp.Position - hrp.Position).Magnitude > 6 then
                                hum:MoveTo(targetHrp.Position)
                            end
                        else
                            followingPlayer = nil
                        end
                    else
                        -- Распределение действий бота
                        local actionChance = math.random(1, 10)

                        if actionChance <= 4 then
                            -- 1. Случайная ходьба с паузой
                            safeMoveTo(hrp.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
                            safeWait(math.random(3, 5)) -- Задержка, чтобы он не бегал без остановки

                        elseif actionChance <= 6 then
                            -- 2. Смотреть на дальнего игрока (25 - 110 studs)
                            local distantChar = getNearestPlayer(25, 110)
                            if distantChar and distantChar:FindFirstChild("HumanoidRootPart") then
                                hum:MoveTo(hrp.Position) -- Остановиться
                                local startTime = tick()
                                while botActive and not followingPlayer and (tick() - startTime < 6) do
                                    if distantChar and distantChar:FindFirstChild("HumanoidRootPart") and hrp then
                                        local targetPos = distantChar.HumanoidRootPart.Position
                                        hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                                    else
                                        break
                                    end
                                    safeWait(0.1)
                                end
                            else
                                useRandomItem()
                            end
                            safeWait(1)

                        elseif actionChance <= 8 then
                            -- 3. Подойти к игроку неподалеку и заговорить
                            local targetChar = getNearestPlayer(0, 30)
                            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                                safeMoveTo(targetChar.HumanoidRootPart.Position + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4)))
                                safeWait(1.5)
                                
                                if hrp and targetChar:FindFirstChild("HumanoidRootPart") then
                                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetChar.HumanoidRootPart.Position.X, hrp.Position.Y, targetChar.HumanoidRootPart.Position.Z))
                                    
                                    -- Озвучить фразу при взгляде
                                    if math.random(1, 10) <= 7 then
                                        local starePhrase = playerStarePhrases[math.random(#playerStarePhrases)]
                                        sayMessage(starePhrase)
                                    end
                                end
                            end
                            safeWait(math.random(2, 4))

                        else
                            -- 4. Использование предметов
                            useRandomItem()
                            safeWait(2)
                        end

                        -- Фоновый автономный чат
                        if tick() - lastChatTime >= chatCooldown then
                            sayMessage(randomPhrases[math.random(#randomPhrases)])
                            lastChatTime = tick()
                            chatCooldown = math.random(15, 30)
                        end
                    end
                end
            end)

            if not success then
                warn("[BOT ERROR в цикле]:", err)
            end
        end
    end
end)

-- Переключатель
ToggleButton.MouseButton1Click:Connect(function()
    botActive = not botActive
    if botActive then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleButton.Text = "🤖 БОТ: ВКЛ"
        print("[BOT]: Активирован!")
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        ToggleButton.Text = "🤖 БОТ: ВЫКЛ"
        followingPlayer = nil
        print("[BOT]: Деактивирован!")
    end
end)

print("[BOT]: Скрипт успешно загружен!")
