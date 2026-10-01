-- ==========================================
-- LIVE SKIN BOT (FIXED THREAD YIELDING & MOVEMENT)
-- ==========================================

print("[BOT]: Запуск обновленного скрипта...")

local safeWait = function(t)
    return (task and task.wait or wait)(t or 0.1)
end

local safeSpawn = function(f, ...)
    return (task and task.spawn or function(fn, ...) return coroutine.wrap(fn)(...) end)(f, ...)
end

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

-- Обновление позиции спавна
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
                if channel then channel:SendAsync(text) end
            else
                local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local sayReq = events and events:FindFirstChild("SayMessageRequest")
                if sayReq then sayReq:FireServer(text, "All") end
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

-- Поиск игроков
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

-- Использование предметов
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
            safeWait(1)
            hum:UnequipTools()
        end
    end
end

-- Безопасное перемещение
local function safeMoveTo(targetPos)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if math.random(1, 3) == 1 then hum.Jump = true end
    hum:MoveTo(targetPos)
end

-- ------------------------------------------
-- 1. GUI
-- ------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if playerGui then
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
end

-- ------------------------------------------
-- 2. Логика защиты от седел
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

-- ------------------------------------------
-- 3. Слушатель чата
-- ------------------------------------------
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

-- ------------------------------------------
-- 4. Главная петля поведения (БЕЗ YIELD В PCALL)
-- ------------------------------------------
safeSpawn(function()
    print("[BOT]: Главный поток поведения запущен!")
    while true do
        safeWait(0.5)

        if botActive then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hum and hrp and hum.Health > 0 then
                -- 1. Режим следования
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
                    safeWait(1)
                else
                    -- 2. Обычное поведение
                    local actionChance = math.random(1, 10)

                    if actionChance <= 5 then
                        -- Случайный шаг
                        safeMoveTo(hrp.Position + Vector3.new(math.random(-25, 25), 0, math.random(-25, 25)))
                        safeWait(math.random(2, 4))

                    elseif actionChance <= 8 then
                        -- Попытка подойти к ближайшему игроку
                        local targetChar = getNearestPlayer(0, 40)
                        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                            safeMoveTo(targetChar.HumanoidRootPart.Position + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4)))
                            safeWait(2)
                            
                            local tHrp = targetChar:FindFirstChild("HumanoidRootPart")
                            if hrp and tHrp then
                                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z))
                                if math.random(1, 10) <= 7 then
                                    sayMessage(playerStarePhrases[math.random(#playerStarePhrases)])
                                end
                            end
                            safeWait(2)
                        else
                            -- Если людей рядом нет — просто прогуляться
                            safeMoveTo(hrp.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
                            safeWait(3)
                        end

                    else
                        -- Предмет из инвентаря
                        useRandomItem()
                        safeWait(2)
                    end

                    -- Автономный фоновый чат
                    if tick() - lastChatTime >= chatCooldown then
                        sayMessage(randomPhrases[math.random(#randomPhrases)])
                        lastChatTime = tick()
                        chatCooldown = math.random(15, 30)
                    end
                end
            end
        end
    end
end)

print("[BOT]: Скрипт успешно готов к работе!")
