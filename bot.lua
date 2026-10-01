-- ==========================================
-- LIVE SKIN BOT (FIXED DRAGGABLE NEON UI & ATOMIC SNEEZE)
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
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[BOT ERROR]: LocalPlayer не найден!")
    return
end

local botActive = false
local isSneezing = false
local lastChatTime = tick()
local lastResponseTime = 0 -- Дебаунс от двойных ответов в чате
local chatCooldown = math.random(10, 20)
local followingPlayer = nil
local spawnPosition = Vector3.new(0, 5, 0)

-- Таблица для корректного перевода кириллицы в нижний регистр
local cyrillicUpper = {
    ["А"]="а", ["Б"]="б", ["В"]="в", ["Г"]="г", ["Д"]="д", ["Е"]="е", ["Ё"]="ё",
    ["Ж"]="ж", ["З"]="з", ["И"]="и", ["Й"]="й", ["К"]="к", ["Л"]="л", ["М"]="м",
    ["Н"]="н", ["О"]="о", ["П"]="п", ["Р"]="р", ["С"]="с", ["Т"]="т", ["У"]="у",
    ["Ф"]="ф", ["Х"]="х", ["Ц"]="ц", ["Ч"]="ч", ["Ш"]="ш", ["Щ"]="щ", ["Ъ"]="ъ",
    ["Ы"]="ы", ["Ь"]="ь", ["Э"]="э", ["Ю"]="ю", ["Я"]="я"
}

local function cleanText(str)
    if not str then return "" end
    str = str:lower()
    for upperChar, lowerChar in pairs(cyrillicUpper) do
        str = str:gsub(upperChar, lowerChar)
    end
    return str
end

-- Настройка 3D звука чиха
local function setupSneezeSound(char)
    if not char then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        local oldSound = hrp:FindFirstChild("AtomicSneeze")
        if oldSound then oldSound:Destroy() end

        local sneezeSound = Instance.new("Sound")
        sneezeSound.Name = "AtomicSneeze"
        sneezeSound.SoundId = "rbxassetid://75348227771086"
        sneezeSound.Volume = 2.5
        sneezeSound.RollOffMaxDistance = 150 -- Слышно всем игрокам в радиусе 150 студов
        sneezeSound.RollOffMinDistance = 10
        sneezeSound.Parent = hrp
    end
end

-- Обновление позиции спавна
local function updateSpawnPosition()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local spawnPart = Workspace:FindFirstChild("SpawnLocation", true) or Workspace:FindFirstChild("Spawns", true)
        if spawnPart and spawnPart:IsA("BasePart") then
            spawnPosition = spawnPart.Position
        else
            spawnPosition = char.HumanoidRootPart.Position
        end
    end
end

if LocalPlayer.Character then 
    updateSpawnPosition() 
    setupSneezeSound(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    safeWait(1)
    updateSpawnPosition()
    setupSneezeSound(char)
end)

-- Фразы
local jokesList = {
    "Заходит бот в бар, а бармен ему: 'Служба поддержки в соседнем здании!'",
    "Почему программисты любят темную тему? Свет привлекает багов!",
    "Учитель: 'Иван, почему ты говоришь с ботом?' Иван: 'Он хотя бы меня слушает!'",
    "— Ты веришь в людей? — Не, это просто миф для школьников.",
    "Знаешь почему роботы не врут? Код не позволяет!",
    "Зашел бот в систему... а там вирусы праздник отмечают."
}

local greetingResponses = { "?", "Даров", "Досвидание", "Прив", "Здарова" }

local botIdentityPhrases = {
    "А ты тоже чтоли?",
    "Нет я болтик",
    "Ес оф корс"
}

local spawnReturnPhrases = {
    "Какой гений меня отправил в африку? Мне нравилось усебя быть..",
    "Надоела эта брукхейвенская рутина..",
    "ДА ЧТОЖ ТЫ ПОДЕЛАЕШЬ ТА БЛ",
    "Ох.. это не спавн?"
}

local randomPhrases = {
    "странно тут все..", "ПОЧЕМУ БЫТЬ БАШНЕЙ МОДНО?!?", "я видел ГОРАЗДО интересного чем этот сервер", "хмм...", 
    "Ой ой ой ненадо было кушать острый китайский латяо", "КУДА ЖМАТЬ ТО?!", "Ахэахав.. ой", ":/", "ее", "так себе местечко", 
    "Чат живой надеюсь?..", "Да я простой бот и че? Как будто мне жить даже нельзя тут", "Знаете.. иногда быть ботом трудно", 
    "ненадо было это кушать...", "СКУЧНААА", "Я не могу отвечать на ваши аргументы так что извините", "Обэмэ", 
    "Уменя черные точки вместо глаз..", 
    "Хотите послушать анекдот? Напишите в чат \"расскажи анекдот\" и расскажу", 
    ":0", "Ходилкин бродилкин", 
    "Рп действие занюхнул воздух", "Боты тоже как люди", "UwU", "Я.. я забыл куда идти", "Мир так жесток..",
    "Забавный факт: это и есть забавный факт",
    "Да емае ну бл ну.. ну бл :[",
    "Жить хочу",
    "Скучные тут все...",
    "Я не кому не ужин...",
    "Я во всем виноград",
    "😶",
    "🍞"
}

local seatReactionPhrases = { "че думал на меня это сработает? Жаль", "и не говорите что я простой бот который зашел сюда по фану", "ДОСТАЛ БЛ", "Нет.", "Не не такое не прокатит на мне", "Не чет не хочу извини брат", "..." }

local playerStarePhrases = { 
    "Знаешь.. иногда найти ту самую половинку не просто", "Все еще меняем скинчик м?", "🤨", "Афк? Думаю да..", 
    "Э ты че на нашем районе потерял?", "._.", "Я к тебе подходил уже или нет?..", "ПрЕвЕт МеЛкИй Че ДеЛаЕшЬ?", 
    "Выглядишь странно..", "АФИГЕТ Я ДАЖЕ НЕЗ КАК ТВОЙ СКИН ВЫГЛЯДИТ!", "Бу",
    "Вы игроки всегда так.. наряживаетесь?",
    "Кал переделывай",
    "Живой нет?"
}

-- Отправка сообщений в чат
local function sayMessage(text)
    if not text or text == "" then return end
    safeSpawn(function()
        pcall(function()
            local sent = false
            if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then 
                    channel:SendAsync(text)
                    sent = true
                end
            end
            if not sent then
                local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local sayReq = events and events:FindFirstChild("SayMessageRequest")
                if sayReq then sayReq:FireServer(text, "All") end
            end
        end)
    end)
end

-- Безопасная проверка приветствий (без сбоев паттернов UTF-8)
local function isGreeting(cleanMsg)
    local greetings = { "ку", "пр", "привет", "хай", "дратути", "здарова", "салам", "хеллоу", "здаров" }
    for word in cleanMsg:gmatch("[%wа-яёА-ЯЁ]+") do
        for _, g in ipairs(greetings) do
            if word == g then
                return true
            end
        end
    end
    return false
end

-- Безопасный Рэгдолл (без отваливания конечностей)
local function setRagdoll(char, active)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if active then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        hum.PlatformStand = true
    else
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

-- 💥 АТОМНЫЙ ЧИХ С ВЗЛЕТОМ
local function atomicSneeze()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hrp or not hum or isSneezing or not botActive then return end

    isSneezing = true

    -- Звук чиха
    local sound = hrp:FindFirstChild("AtomicSneeze")
    if sound then
        sound:Play()
    end

    -- Импульс взлета вверх
    hrp.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), 180, math.random(-15, 15))

    -- Включаем рэгдолл
    setRagdoll(char, true)

    safeWait(0.6)

    -- Ждем приземления
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char}

    local startTime = tick()
    while tick() - startTime < 8 do
        safeWait(0.1)
        local ray = Workspace:Raycast(hrp.Position, Vector3.new(0, -3.5, 0), rayParams)
        if ray or math.abs(hrp.AssemblyLinearVelocity.Y) < 1 then
            break
        end
    end

    safeWait(0.5)
    setRagdoll(char, false)
    isSneezing = false
end

-- Поиск опасности спереди
local function isThreatInFront(hrp)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pHrp = player.Character.HumanoidRootPart
            local localPos = hrp.CFrame:PointToObjectSpace(pHrp.Position)
            if localPos.Z < -1 and localPos.Z > -16 and math.abs(localPos.X) < 6 then
                return true
            end
        end
    end
    return false
end

-- Поиск ближайшего игрока
local function getNearestPlayer(minDist, maxDist)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    local nearest, closestDist = nil, maxDist or 50

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
            safeWait(0.8)
            hum:UnequipTools()
        end
    end
end

-- Перемещение
local function safeMoveTo(targetPos)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if math.random(1, 5) == 1 then hum.Jump = true end
    hum:MoveTo(targetPos)
end

-- ------------------------------------------
-- 1. СТИЛЬНАЯ UI КНОПКА (ИСПРАВЛЕННЫЙ DRAG & DROP)
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
    ToggleButton.Size = UDim2.new(0, 155, 0, 48)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.3, 0)
    
    ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25) 
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 16
    ToggleButton.Font = Enum.Font.FredokaOne
    ToggleButton.Active = true
    ToggleButton.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = ToggleButton

    local UIGradient = Instance.new("UIGradient")
    UIGradient.Parent = ToggleButton

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Thickness = 3
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = ToggleButton

    local styles = {
        On = {
            Text = "ИИ:включен!",
            Stroke = Color3.fromRGB(0, 255, 120),
            Gradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 80, 45)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 35, 20))
            })
        },
        Off = {
            Text = "ИИ:выключен!",
            Stroke = Color3.fromRGB(255, 60, 60),
            Gradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 20, 20)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 12, 12))
            })
        }
    }

    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function updateButtonUI(enabled)
        local targetStyle = enabled and styles.On or styles.Off
        ToggleButton.Text = targetStyle.Text
        
        TweenService:Create(UIStroke, tweenInfo, {Color = targetStyle.Stroke}):Play()
        TweenService:Create(UIGradient, tweenInfo, {Color = targetStyle.Gradient}):Play()
    end

    updateButtonUI(botActive)

    -- 🖐️ НАДЕЖНЫЙ МЕХАНИЗМ ПЕРЕТАСКИВАНИЯ (FIXED)
    local dragging = false
    local dragStart, startPos
    local hasDragged = false

    local function updateDrag(input)
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end

    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasDragged = false
            dragStart = input.Position
            startPos = ToggleButton.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if (input.Position - dragStart).Magnitude > 5 then
                hasDragged = true
            end
            updateDrag(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Переключение ИИ по клику
    ToggleButton.MouseButton1Click:Connect(function()
        if hasDragged then 
            hasDragged = false
            return 
        end
        
        botActive = not botActive
        updateButtonUI(botActive)
        
        if botActive then
            print("[BOT]: Активирован!")
        else
            followingPlayer = nil
            print("[BOT]: Деактивирован!")
        end
    end)
end

-- ------------------------------------------
-- 2. Защита от сидений
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
-- 3. ОБРАБОТЧИК СООБЩЕНИЙ ЧАТА
-- ------------------------------------------
local function processChatMessage(senderPlayer, msg)
    if not botActive or senderPlayer == LocalPlayer or isSneezing then return end
    
    if tick() - lastResponseTime < 2 then return end

    local cleanMsg = cleanText(msg)
    local senderChar = senderPlayer.Character
    local char = LocalPlayer.Character
    if not senderChar or not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local senderHrp = senderChar:FindFirstChild("HumanoidRootPart")
    if not hrp or not senderHrp then return end

    local dist = (senderHrp.Position - hrp.Position).Magnitude

    -- Вызов "ты бот"
    if cleanMsg:find("ты бот") or cleanMsg:find("ты ботик") then
        lastResponseTime = tick()
        sayMessage(botIdentityPhrases[math.random(#botIdentityPhrases)])
    -- Следование
    elseif cleanMsg:find("следуй") or cleanMsg:find("следу") or cleanMsg:find("идем за мной") or cleanMsg:find("иди за мной") or cleanMsg:find("за мной") then
        if dist <= 60 then
            lastResponseTime = tick()
            followingPlayer = senderPlayer
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
            sayMessage("оке")
        end
    elseif cleanMsg:find("хватит") or cleanMsg:find("отвянь") or cleanMsg:find("стоп") or cleanMsg:find("не иди") then
        if followingPlayer == senderPlayer then
            lastResponseTime = tick()
            followingPlayer = nil
            sayMessage("лан покеда")
        end
    -- Анекдот
    elseif cleanMsg:find("анекдот") or cleanMsg:find("расскажи") then
        if dist <= 60 then
            lastResponseTime = tick()
            sayMessage(jokesList[math.random(#jokesList)])
        end
    -- Приветствие
    elseif isGreeting(cleanMsg) and dist <= 40 then
        lastResponseTime = tick()
        sayMessage(greetingResponses[math.random(#greetingResponses)])
    end
end

-- Подключение слушателей чата
if TextChatService then
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        local textSource = textChatMessage.TextSource
        if textSource then
            local senderPlayer = Players:GetPlayerByUserId(textSource.UserId)
            if senderPlayer then
                processChatMessage(senderPlayer, textChatMessage.Text)
            end
        end
    end)
end

local function listenLegacyChat(player)
    player.Chatted:Connect(function(msg)
        processChatMessage(player, msg)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then listenLegacyChat(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then listenLegacyChat(p) end
end)

-- ------------------------------------------
-- 4. Главный цикл активного поведения
-- ------------------------------------------
safeSpawn(function()
    print("[BOT]: Главный поток поведения запущен!")
    while true do
        safeWait(0.2)

        if botActive and not isSneezing then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hum and hrp and hum.Health > 0 then

                -- 💥 ШАНС АТОМНОГО ЧИХА (Рандом 1 из 35 циклов)
                if math.random(1, 35) == 1 then
                    atomicSneeze()

                -- 0. УБЕГАНИЕ НАЗАД, ЕСЛИ СПЕРЕДИ ПРИБЛИЖАЮТСЯ
                elseif isThreatInFront(hrp) then
                    local escapeTarget = hrp.Position - (hrp.CFrame.LookVector * 18)
                    hum:MoveTo(escapeTarget)
                    if math.random(1, 2) == 1 then hum.Jump = true end
                    safeWait(1.2)

                -- 1. Режим следования за игроком
                elseif followingPlayer then
                    local targetChar = followingPlayer.Character
                    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                        local targetHrp = targetChar.HumanoidRootPart
                        if (targetHrp.Position - hrp.Position).Magnitude > 6 then
                            hum:MoveTo(targetHrp.Position)
                        end
                    else
                        followingPlayer = nil
                    end
                    safeWait(0.8)

                else
                    -- 2. ВОЗВРАТ НА СПАВН
                    local distFromSpawn = (hrp.Position - spawnPosition).Magnitude
                    local shouldReturnSpawn = distFromSpawn > 120 or (math.random(1, 20) == 20 and distFromSpawn > 50)

                    if shouldReturnSpawn then
                        safeMoveTo(spawnPosition + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6)))
                        if math.random(1, 2) == 1 then
                            sayMessage(spawnReturnPhrases[math.random(#spawnReturnPhrases)])
                        end
                        safeWait(math.random(3, 6))
                    else
                        -- 3. Обычное активное поведение
                        local actionChance = math.random(1, 10)

                        if actionChance == 1 then
                            -- Подход к ближайшему игроку
                            local targetChar = getNearestPlayer(0, 40)
                            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                                local tHrp = targetChar.HumanoidRootPart
                                safeMoveTo(tHrp.Position + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4)))
                                safeWait(1.5)

                                if hrp and tHrp then
                                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z))
                                    sayMessage(playerStarePhrases[math.random(#playerStarePhrases)])
                                end
                                safeWait(math.random(3, 6))
                            else
                                safeMoveTo(hrp.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
                                safeWait(math.random(2, 5))
                            end

                        elseif actionChance <= 6 then
                            -- Прогулка с паузой
                            safeMoveTo(hrp.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
                            safeWait(math.random(3, 7))

                        elseif actionChance <= 9 then
                            -- Стоит на месте
                            safeWait(math.random(4, 8))

                        else
                            -- Использование предмета
                            useRandomItem()
                            safeWait(math.random(2, 4))
                        end
                    end

                    -- Фоновый чат
                    if tick() - lastChatTime >= chatCooldown then
                        sayMessage(randomPhrases[math.random(#randomPhrases)])
                        lastChatTime = tick()
                        chatCooldown = math.random(12, 25)
                    end
                end
            end
        end
    end
end)

print("[BOT]: Скрипт с исправленной кнопкой и чатом успешно запущен!")
