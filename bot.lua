-- ==========================================
-- LIVE SKIN BOT (ADVANCED AI + FOLLOW + GREETINGS)
-- ==========================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local botActive = false
local lastChatTime = tick()
local lastEscapeChat = 0
local chatCooldown = math.random(12, 25)

-- Переменная для режима следования
local followingPlayer = nil

-- Точка спавна
local spawnPosition = Vector3.new(0, 5, 0)

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
    task.wait(1)
    updateSpawnPosition()
end)

-- База анекдотов
local jokesList = {
    "Колобок повесился... А вообще ладно, вот нормальный: Заходит бот в бар, а бармен говорит: 'Служба поддержки в соседнем здании!'",
    "Почему программисты любят темную тему? Потому что свет привлекает багов!",
    "Заходит робот в магазин: — Мне, пожалуйста, банку масла. — С вас 100 рублей. — А подешевле есть? — Есть, но оно с багами!",
    "Учитель: 'Иван, почему ты разговариваешь с ботом?' Иван: 'Он хотя бы слушает мои аргументы!'",
    "Знаете почему роботы не умеют врать? Код не позволяет, а вот люди — запросто!",
    "Разговаривают два бота: — Ты веришь в людей? — Не, это просто миф для школьников."
}

-- Ответы на приветствия
local greetingResponses = {
    "?",
    "Даров",
    "Досвидание",
    "Прив"
}

-- Фразы для фонового чата (Idle)
local randomPhrases = {
    "странно тут все..",
    "ПОЧЕМУ БЫТЬ БАШНЕЙ МОДНО?!?",
    "я видел ГОРАЗДО интересного чем этот сервер",
    "хмм...",
    "Ой ой ой ненадо было кушать острый китайский латяо",
    "КУДА ЖМАТЬ ТО?!",
    "Ахэахав.. ой",
    ":/",
    "ее",
    "так себе местечко",
    "Чат живой надеюсь?..",
    "Да я простой бот и че? Как будто мне жить даже нельзя тут",
    "Знаете.. иногда быть ботом трудно",
    "ненадо было это кушать...",
    "СКУЧНААА",
    "Я не могу отвечать на ваши аргументы так что извините",
    "Обэмэ",
    "Уменя черные точки вместо глаз..",
    "Хотите анекдот? Напишите в чат \"<расскажи анекдот>\" и расскажу",
    ":0",
    "Ходилкин бродилкин",
    "Рп действие занюхнул воздух",
    "Боты тоже как люди",
    "UwU",
    "Я.. я забыл куда идти",
    "Мир так жесток.."
}

-- Фразы при побеге от тележек/колясок
local escapePhrases = {
    "НЕ НЕ НЕ",
    "НЕНАДО",
    "АААА ОТСТАНЬ",
    "Я УБЕГАЮ!",
    "ДАЖЕ НЕ ДУМАЙ",
    "ОЙ ОЙ ОЙ МЕНЯ СЕЙЧАС СКУШАЮТ",
    "НЕ ПОЙМАЕШЬ!",
    "ДА ЧЕ Я ТЕБЕ ЗДЕЛАЛ?!?",
    "0______0"
}

local seatReactionPhrases = {
    "че думал на меня это сработает? Жаль",
    "и не говорите что я простой бот который зашел сюда по фану",
    "ДОСТАЛ БЛ",
    "Нет.",
    "Не не такое не прокатит на мне",
    "Не чет не хочу извини брат",
    "..."
}

local playerStarePhrases = {
    "Знаешь.. иногда найти ту самую половинку не просто",
    "Все еще меняем скинчик м?",
    "🤨",
    "Афк? Думаю да..",
    "Э ты че на нашем районе потерял?",
    "._.",
    "Я к тебе подходил уже или нет?..",
    "ПрЕвЕт МеЛкИй Че ДеЛаЕшЬ?",
    "Выглядишь странно..",
    "АФИГЕТ Я ДАЖЕ НЕЗ КАК ТВОЙ СКИН ВЫГЛЯДИТ!",
    "Бу"
}

-- Функция отправки сообщений в чат
local function sayMessage(text)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:SendAsync(text)
            end
        else
            local sayReq = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
            if sayReq then
                sayReq:FireServer(text, "All")
            end
        end
    end)
end

-- Проверка приветствий на совпадение отдельных слов
local function isGreetingWord(msg)
    for word in string.gmatch(msg, "[%w_а-яА-ЯёЁ]+") do
        if word == "ку" or word == "пр" or word == "привет" or word == "хай" or word == "дратути" then
            return true
        end
    end
    return false
end

-- ------------------------------------------
-- 1. Перетаскиваемый GUI (Кнопка)
-- ------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiveBotCanavaGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "BotToggle"
ToggleButton.Size = UDim2.new(0, 150, 0, 50)
ToggleButton.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
ToggleButton.Text = "🤖 БОТ: ВЫКЛ"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Active = true
ToggleButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = ToggleButton

local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- ------------------------------------------
-- 2. Анти-сидение (0 секунд)
-- ------------------------------------------
local function bindAntiSeat(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
        if botActive and humanoid.Sit then
            task.wait(0.01)
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            
            local phrase = seatReactionPhrases[math.random(#seatReactionPhrases)]
            sayMessage(phrase)
        end
    end)
end

if LocalPlayer.Character then
    bindAntiSeat(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(bindAntiSeat)

-- ------------------------------------------
-- 3. Безопасная ходьба
-- ------------------------------------------
local function safeMoveTo(targetPos, maxWait)
    maxWait = maxWait or 4
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    if math.random(1, 3) == 1 then
        hum.Jump = true
    end

    hum:MoveTo(targetPos)

    local reached = false
    local conn = hum.MoveToFinished:Connect(function()
        reached = true
    end)

    local start = tick()
    local lastPos = hrp.Position

    while not reached and (tick() - start) < maxWait and botActive do
        task.wait(0.2)
        if (hrp.Position - lastPos).Magnitude < 0.15 and (tick() - start) > 1.2 then
            break
        end
        lastPos = hrp.Position
    end

    if conn then conn:Disconnect() end
end

-- ------------------------------------------
-- 4. Проверка: является ли предмет опасным
-- ------------------------------------------
local function isDangerousItem(targetChar)
    if not targetChar then return false end

    if targetChar:FindFirstChildWhichIsA("Seat", true) or targetChar:FindFirstChildWhichIsA("VehicleSeat", true) then
        return true
    end

    local tool = targetChar:FindFirstChildOfClass("Tool")
    if tool then
        if tool:FindFirstChildWhichIsA("Seat", true) or tool:FindFirstChildWhichIsA("VehicleSeat", true) then
            return true
        end

        local name = tool.Name:lower()
        if name:find("stroller") or name:find("cart") or name:find("car") or name:find("van") or name:find("bed") or name:find("couch") or name:find("коляска") or name:find("тележка") then
            return true
        end
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
            
            if dist <= 22 and isDangerousItem(targetChar) then
                local fleeDirection = (hrp.Position - targetChar.HumanoidRootPart.Position).Unit
                hum.WalkSpeed = 32
                hum:MoveTo(hrp.Position + fleeDirection * 40)
                
                if tick() - lastEscapeChat >= 4 then
                    local escapePhrase = escapePhrases[math.random(#escapePhrases)]
                    sayMessage(escapePhrase)
                    lastEscapeChat = tick()
                end
                
                task.wait(1)
                hum.WalkSpeed = 16
                return true
            end
        end
    end
    return false
end

local function getNearestPlayer(minDist, maxDist)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    local nearest, closestDist = nil, maxDist or 35

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
            if dist >= (minDist or 0) and dist < closestDist then
                closestDist = dist
                nearest = player.Character
            end
        end
    end
    return nearest
end

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
        char.Humanoid:EquipTool(randomTool)
        task.wait(0.4)
        randomTool:Activate()
        task.wait(math.random(1, 2))
        char.Humanoid:UnequipTools()
    end
end

-- ------------------------------------------
-- 5. Слушатель чата
-- ------------------------------------------
local function listenToChat(player)
    player.Chatted:Connect(function(msg)
        if not botActive then return end
        
        local cleanMsg = msg:lower()

        local senderChar = player.Character
        if not senderChar or not senderChar:FindFirstChild("HumanoidRootPart") then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = char.HumanoidRootPart
        local senderHrp = senderChar.HumanoidRootPart
        local dist = (senderHrp.Position - hrp.Position).Magnitude

        -- 1. Команда "следуй за мной"
        if cleanMsg:find("следуй замной") or cleanMsg:find("следуй за мной") or cleanMsg:find("идем замной") or cleanMsg:find("идем за мной") then
            if dist <= 50 then
                followingPlayer = player
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
                sayMessage("оке")
            end
            return
        end

        -- 2. Команда "хватит ходить за мной" / "отвянь"
        if cleanMsg:find("хватит ходить замной") or cleanMsg:find("хватит ходить за мной") or cleanMsg:find("отвянь") then
            if followingPlayer == player then
                followingPlayer = nil
                sayMessage("лан покеда")
            end
            return
        end

        -- 3. Реакция на "ты не бот"
        if cleanMsg:find("ты не бот") then
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
            task.wait(0.3)
            sayMessage("врун врунишка врун")
            return
        end

        -- 4. Реакция на "расскажи анекдот"
        if cleanMsg:find("расскажи анекдот") then
            if dist > 120 then
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
                sayMessage("не ну тыб хотябы  был где то виднее или мне что в африку бежать за тобой?")
            else
                if dist > 12 then
                    safeMoveTo(senderHrp.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3)), 4)
                end
                
                if hrp and senderHrp then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
                end
                
                task.wait(0.5)
                local randomJoke = jokesList[math.random(#jokesList)]
                sayMessage(randomJoke)
            end
            return
        end

        -- 5. Ответ на приветствие (работает ТОЛЬКО до 40 студов)
        if isGreetingWord(cleanMsg) and dist <= 40 then
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
            task.wait(0.3)
            local reply = greetingResponses[math.random(#greetingResponses)]
            sayMessage(reply)
            return
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
-- 6. Главный поток поведения бота
-- ------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.5)

        if botActive then
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")

                if hum and hrp and hum.Health > 0 then
                    if hum.Sit then hum.Sit = false end

                    local escaped = checkAndEscape()

                    if not escaped then
                        -- Проверка режима следования
                        if followingPlayer then
                            local targetChar = followingPlayer.Character
                            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and followingPlayer:IsDescendantOf(Players) then
                                local targetHrp = targetChar.HumanoidRootPart
                                local followDist = (targetHrp.Position - hrp.Position).Magnitude

                                if followDist > 6 then
                                    hum:MoveTo(targetHrp.Position)
                                end
                            else
                                followingPlayer = nil
                            end
                        else
                            -- Обычное поведение (когда ни за кем не идет)
                            local distFromSpawn = (hrp.Position - spawnPosition).Magnitude
                            if distFromSpawn > 160 then
                                safeMoveTo(spawnPosition + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)), 5)
                            else
                                local actionChance = math.random(1, 10)

                                if actionChance <= 5 then
                                    local randomOffset = Vector3.new(math.random(-25, 25), 0, math.random(-25, 25))
                                    safeMoveTo(hrp.Position + randomOffset, 3.5)

                                elseif actionChance <= 7 then
                                    local distantChar = getNearestPlayer(25, 110)
                                    if distantChar and distantChar:FindFirstChild("HumanoidRootPart") then
                                        hum:MoveTo(hrp.Position)
                                        local startTime = tick()
                                        while botActive and not followingPlayer and (tick() - startTime < 8) do
                                            if distantChar and distantChar:FindFirstChild("HumanoidRootPart") and hrp then
                                                local targetPos = distantChar.HumanoidRootPart.Position
                                                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                                            else
                                                break
                                            end
                                            task.wait(0.05)
                                        end
                                    else
                                        useRandomItem()
                                    end

                                elseif actionChance <= 8 then
                                    useRandomItem()

                                else
                                    local targetChar = getNearestPlayer(0, 30)
                                    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                                        safeMoveTo(targetChar.HumanoidRootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3)), 3)
                                        
                                        if hrp and targetChar:FindFirstChild("HumanoidRootPart") then
                                            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetChar.HumanoidRootPart.Position.X, hrp.Position.Y, targetChar.HumanoidRootPart.Position.Z))
                                            
                                            if math.random(1, 10) <= 6 then
                                                local starePhrase = playerStarePhrases[math.random(#playerStarePhrases)]
                                                sayMessage(starePhrase)
                                            end
                                        end
                                    end
                                end
                            end

                            -- Фоновый чат только в обычном режиме
                            if tick() - lastChatTime >= chatCooldown then
                                local phrase = randomPhrases[math.random(#randomPhrases)]
                                sayMessage(phrase)
                                lastChatTime = tick()
                                chatCooldown = math.random(12, 28)
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- Переключатель ВКЛ / ВЫКЛ
ToggleButton.MouseButton1Click:Connect(function()
    botActive = not botActive
    if botActive then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleButton.Text = "🤖 БОТ: ВКЛ"
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
        ToggleButton.Text = "🤖 БОТ: ВЫКЛ"
        followingPlayer = nil
    end
end)
