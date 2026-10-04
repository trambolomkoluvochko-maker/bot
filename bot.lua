-- ==========================================
-- LIVE SKIN BOT (COMPACT UI + EVALUATION COMMAND + FIXED SYNTAX)
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
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local function getGuiParent()
    local success, parent = pcall(function()
        if gethui then return gethui() end
        return CoreGui
    end)
    if success and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui", 5)
end

local botActive = false
local returnToSpawnActive = true
local lastChatTime = tick()
local lastResponseTime = 0
local chatCooldown = math.random(10, 20)
local followingPlayer = nil
local spawnPosition = Vector3.new(0, 5, 0)

-- Таблица перевода кириллицы
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
end

LocalPlayer.CharacterAdded:Connect(function(char)
    safeWait(1)
    updateSpawnPosition()
end)

local cartEscapePhrases = {
    "НЕ НЕ НЕ НЕ В ЭТОТ РАЗ", "НЕНАДО ДЯДЯ.. ИЛИ ТЕТЯ", "НУ НАФ", "НЕТ НЕТ НЕЕЕТ!", 
    "Я СВАЛИВАЮ!", "ДА ЧТО Я ТЕБЕ ЗДЕЛАЛ?!?", "КЫШ КЫШ!", "ноу ноу ноу мистер плеер", "Э"
}

local jokesList = {
    "Заходит бот в бар, а бармен ему: 'Служба поддержки в соседнем здании!'",
    "Почему программисты любят темную тему? Свет привлекает багов!",
    "Учитель: 'Иван, почему ты говоришь с ботом?' Иван: 'Он хотя бы меня слушает!'",
    "— Ты веришь в людей? — Не, это просто миф для школьников.",
    "Знаешь почему роботы не врут? Код не позволяет!",
    "Зашел бот в систему... а там вирусы праздник отмечают.",
    "Компьютер без операционки — как скрипт без ошибок: в теории есть, а на практике никто не видел.",
    "— Алло, это полиция? Мне тут робот дорогу перебежал! — Он был на зеленый? — Нет, на Luau!",
    "Шёл бот по серверу, увидел горящий скрипт, сел в него и сгорел.",
    "Вопрос: сколько нужно скриптеров, чтобы поменять лампочку? Ответ: ни одного, это проблема на стороне железа.",
    "Почему боты никогда не опаздывают? У них встроен задержка safeWait!",
    "— Бот, ты спишь? — Нет, я в бесконечном цикле while true do!"
}

-- Ответы для оценки
local evaluationResponses = {
    "я не вижу смысла оценивать это днище",
    "10/10 ну чисто имба!",
    "0/10 без комментариев..",
    "5/10 сойдет для сельской местности",
    "8/10 очень даже неплохо!",
    "1/10 такое себе если честно..",
    "7/10 норм, пойдет",
    "9/10 стильно!",
    "3/10 мда уж..",
    "100/10 чисто легенда!"
}

local greetingResponses = { "?", "Даров", "Досвидание", "Прив", "Здарова" }
local botIdentityPhrases = { "А ты тоже чтоли?", "Нет я болтик", "Ес оф корс" }
local spawnReturnPhrases = {
    "Какой гений меня отправил в африку? Мне нравилось усебя быть..",
    "Надоела эта брукхейвенская рутина..",
    "ДА ЧТОЖ ТЫ ПОДЕЛАЕШЬ ТА БЛ",
    "Ох.. это не спавн?"
}

local randomPhrases = {
    "странно тут все..", "ПОЧЕМУ БЫТЬ БАШНЕЙ МОДНО?!?", "я видел ГОРАЗДО интересных серверов чем этот..", "хмм...", 
    "Ой ой ой ненадо было кушать острый китайский латяо", "КУДА ЖМАТЬ ТО?!", "Ахэахав.. ой", ":/", "ее", "так себе местечко", 
    "Чат живой надеюсь?..", "Да я простой бот и че? Как будто мне жить даже нельзя тут", "Знаете.. иногда быть ботом трудно", 
    "ненадо было это кушать...", "СКУЧНААА", "Я не могу отвечать на ваши аргументы так что извините", "Обэмэ", 
    "Уменя черные точки вместо глаз..", "Хотите послушать анекдот? Напишите в чат \"расскажи анекдот\" и расскажу", 
    ":0", "Ходилкин бродилкин", "Рп действие занюхнул воздух", "Боты тоже как люди", "UwU", "Я.. я забыл куда идти", 
    "мир так желток..", "Забавный факт: это и есть забавный факт", "пацаны скиньте дз пж", "Жить хочу", 
    "Скучные тут все..", "Я не кому не ужин...", "Я во всем виноград", "😶", "🍞",
    "Скучно.. скучно.. идешь такой бродишь куда глаза глядят..", "Почему все думают боты в рб злые? Все не так же плохо..",
    "Если закрыть глаза то станет темно", "Если грустишь.. не грусти", "в аптеках не продают время потомучто время не лечит",
    "Этот прицел просто имба!", "Cheeki breeki..", "Да уж..", "я НЕ из плейса \"внизу канава 2\"!", "Я за малиной кто сомной?.. никто?..",
    "do you know what time it is?"
}

local seatReactionPhrases = { "че думал на меня это сработает? Жаль", "и не говорите что я простой бот который зашел сюда по фану", "ДОСТАЛ БЛ", "Нет.", "Не не такое не прокатит на мне", "Не чет не хочу извини брат", "..." }
local playerStarePhrases = { 
    "Знаешь.. иногда найти ту самую половинку не просто", "Все еще меняем скинчик м?", "🤨", "Афк? Думаю да..", 
    "Э ты че на нашем районе потерял?", "._.", "Я к тебе подходил уже или нет?..", "ПрЕвЕт МеЛкИй Че ДеЛаЕшЬ?", 
    "Выглядишь странно..", "АФИГЕТ Я ДАЖЕ НЕЗ КАК ТВОЙ СКИН ВЫГЛЯДИТ!", "Бу",
    "Вы игроки всегда так.. наряживаетесь?", "Кал переделывай", "Живой нет?"
}

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

local function isGreeting(cleanMsg)
    local greetings = { "ку", "пр", "привет", "хай", "дратути", "здарова", "салам", "хеллоу", "здаров", "даров", "здарово" }
    for word in cleanMsg:gmatch("[%wа-яёА-ЯЁ]+") do
        for _, g in ipairs(greetings) do
            if word == g then return true end
        end
    end
    return false
end

local function checkCartThreat(hrp)
    if not hrp then return nil, nil end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local pHrp = player.Character:FindFirstChild("HumanoidRootPart")
            local pHum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if pHrp and pHum and pHum.Health > 0 then
                local dist = (pHrp.Position - hrp.Position).Magnitude
                if dist <= 12 then
                    local hasSeatItem = false
                    for _, desc in ipairs(player.Character:GetDescendants()) do
                        if desc:IsA("Seat") or desc:IsA("VehicleSeat") then
                            hasSeatItem = true
                            break
                        end
                    end
                    
                    if hasSeatItem then
                        local localPos = hrp.CFrame:PointToObjectSpace(pHrp.Position)
                        local isFront = localPos.Z < 0
                        return pHrp.Position, isFront
                    end
                end
            end
        end
    end

    return nil, nil
end

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

local function safeMoveTo(targetPos)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if math.random(1, 5) == 1 then hum.Jump = true end
    hum:MoveTo(targetPos)
end

-- ==========================================
-- 🖱 СТИЛЬНЫЙ UI ИНТЕРФЕЙС
-- ==========================================
local parentGui = getGuiParent()

for _, child in ipairs(parentGui:GetChildren()) do
    if child.Name == "LiveBotCanavaGui" then
        child:Destroy()
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiveBotCanavaGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = parentGui

-- Главная круглая кнопка ИИ
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "BotButton"
ToggleButton.Size = UDim2.new(0, 52, 0, 52)
ToggleButton.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.Text = "✕"
ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
ToggleButton.TextSize = 22
ToggleButton.Font = Enum.Font.FredokaOne
ToggleButton.Active = true
ToggleButton.Parent = ScreenGui

ToggleButton.TextXAlignment = Enum.TextXAlignment.Center
ToggleButton.TextYAlignment = Enum.TextYAlignment.Center

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(1, 0)
BtnCorner.Parent = ToggleButton

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Thickness = 2
BtnStroke.Color = Color3.fromRGB(80, 80, 80)
BtnStroke.Parent = ToggleButton

-- Кнопка настроек
local MenuToggleBtn = Instance.new("TextButton")
MenuToggleBtn.Name = "MenuToggleBtn"
MenuToggleBtn.Size = UDim2.new(0, 28, 0, 28)
MenuToggleBtn.Position = UDim2.new(0.05, 55, 0.4, 12)
MenuToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
MenuToggleBtn.Text = "⚙"
MenuToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
MenuToggleBtn.TextSize = 14
MenuToggleBtn.Font = Enum.Font.FredokaOne
MenuToggleBtn.Active = true
MenuToggleBtn.Parent = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(1, 0)
MenuCorner.Parent = MenuToggleBtn

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Thickness = 1.5
MenuStroke.Color = Color3.fromRGB(100, 100, 180)
MenuStroke.Parent = MenuToggleBtn

-- Контейнер для выдвижных функций
local SubMenuFrame = Instance.new("Frame")
SubMenuFrame.Name = "SubMenuFrame"
SubMenuFrame.Size = UDim2.new(0, 160, 0, 0)
SubMenuFrame.Position = UDim2.new(0.05, 0, 0.4, 58)
SubMenuFrame.BackgroundTransparency = 1
SubMenuFrame.ClipsDescendants = true
SubMenuFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = SubMenuFrame

-- 1. Кнопка спавна (ВКЛ/ВЫКЛ)
local SpawnToggleBtn = Instance.new("TextButton")
SpawnToggleBtn.Name = "SpawnToggleBtn"
SpawnToggleBtn.Size = UDim2.new(0, 160, 0, 32)
SpawnToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 35, 55)
SpawnToggleBtn.Text = "🏠 Спавн: ВКЛ"
SpawnToggleBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
SpawnToggleBtn.TextSize = 12
SpawnToggleBtn.Font = Enum.Font.FredokaOne
SpawnToggleBtn.Parent = SubMenuFrame

local SpawnCorner = Instance.new("UICorner")
SpawnCorner.CornerRadius = UDim.new(0, 8)
SpawnCorner.Parent = SpawnToggleBtn

local SpawnStroke = Instance.new("UIStroke")
SpawnStroke.Thickness = 1.5
SpawnStroke.Color = Color3.fromRGB(60, 150, 255)
SpawnStroke.Parent = SpawnToggleBtn

-- 2. Кнопка установки текущей точки спавна
local SetSpawnBtn = Instance.new("TextButton")
SetSpawnBtn.Name = "SetSpawnBtn"
SetSpawnBtn.Size = UDim2.new(0, 160, 0, 32)
SetSpawnBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 55)
SetSpawnBtn.Text = "📍 Задать точку спавна"
SetSpawnBtn.TextColor3 = Color3.fromRGB(255, 150, 255)
SetSpawnBtn.TextSize = 11
SetSpawnBtn.Font = Enum.Font.FredokaOne
SetSpawnBtn.Parent = SubMenuFrame

local SetSpawnCorner = Instance.new("UICorner")
SetSpawnCorner.CornerRadius = UDim.new(0, 8)
SetSpawnCorner.Parent = SetSpawnBtn

local SetSpawnStroke = Instance.new("UIStroke")
SetSpawnStroke.Thickness = 1.5
SetSpawnStroke.Color = Color3.fromRGB(180, 80, 200)
SetSpawnStroke.Parent = SetSpawnBtn

local menuOpen = false
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

MenuToggleBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        TweenService:Create(SubMenuFrame, tweenInfo, {Size = UDim2.new(0, 160, 0, 70)}):Play()
        TweenService:Create(MenuToggleBtn, tweenInfo, {Rotation = 90}):Play()
    else
        TweenService:Create(SubMenuFrame, tweenInfo, {Size = UDim2.new(0, 160, 0, 0)}):Play()
        TweenService:Create(MenuToggleBtn, tweenInfo, {Rotation = 0}):Play()
    end
end)

local function updateUIState(active)
    if active then
        ToggleButton.Text = "✓"
        ToggleButton.TextColor3 = Color3.fromRGB(60, 255, 120)
        TweenService:Create(BtnStroke, tweenInfo, {Color = Color3.fromRGB(60, 255, 120)}):Play()
    else
        ToggleButton.Text = "✕"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
        TweenService:Create(BtnStroke, tweenInfo, {Color = Color3.fromRGB(255, 60, 60)}):Play()
    end
end

local function updateSpawnBtnState(enabled)
    if enabled then
        SpawnToggleBtn.Text = "🏠 Спавн: ВКЛ"
        SpawnToggleBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
        TweenService:Create(SpawnToggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(15, 35, 55)}):Play()
        TweenService:Create(SpawnStroke, tweenInfo, {Color = Color3.fromRGB(60, 150, 255)}):Play()
    else
        SpawnToggleBtn.Text = "🏠 Спавн: ВЫКЛ"
        SpawnToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        TweenService:Create(SpawnToggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
        TweenService:Create(SpawnStroke, tweenInfo, {Color = Color3.fromRGB(100, 100, 100)}):Play()
    end
end

-- Перетаскивание всего блока вместе
local dragging = false
local dragMoved = false
local dragStart, startPos, menuStartPos, subMenuStartPos

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragMoved = false
        dragStart = input.Position
        startPos = ToggleButton.Position
        menuStartPos = MenuToggleBtn.Position
        subMenuStartPos = SubMenuFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 5 then
            dragMoved = true
            ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            MenuToggleBtn.Position = UDim2.new(menuStartPos.X.Scale, menuStartPos.X.Offset + delta.X, menuStartPos.Y.Scale, menuStartPos.Y.Offset + delta.Y)
            SubMenuFrame.Position = UDim2.new(subMenuStartPos.X.Scale, subMenuStartPos.X.Offset + delta.X, subMenuStartPos.Y.Scale, subMenuStartPos.Y.Offset + delta.Y)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    if not dragMoved then
        botActive = not botActive
        updateUIState(botActive)
        if botActive then
            print("[BOT]: ИИ включен!")
        else
            followingPlayer = nil
            print("[BOT]: ИИ выключен!")
        end
    end
end)

SpawnToggleBtn.MouseButton1Click:Connect(function()
    returnToSpawnActive = not returnToSpawnActive
    updateSpawnBtnState(returnToSpawnActive)
end)

SetSpawnBtn.MouseButton1Click:Connect(function()
    if returnToSpawnActive then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            spawnPosition = char.HumanoidRootPart.Position
            print("[BOT]: Точка спавна зафиксирована:", spawnPosition)
            SetSpawnBtn.Text = "📍 Спавн обновлен!"
            task.delay(1.5, function()
                SetSpawnBtn.Text = "📍 Задать точку спавна"
            end)
        end
    else
        SetSpawnBtn.Text = "❌ Сперва включи спавн!"
        task.delay(1.5, function()
            SetSpawnBtn.Text = "📍 Задать точку спавна"
        end)
    end
end)

-- Anti-Sit
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

-- Обработка чата
local function processChatMessage(senderPlayer, msg)
    if not botActive or senderPlayer == LocalPlayer then return end
    if tick() - lastResponseTime < 2 then return end

    local cleanMsg = cleanText(msg)
    local senderChar = senderPlayer.Character
    local char = LocalPlayer.Character
    if not senderChar or not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local senderHrp = senderChar:FindFirstChild("HumanoidRootPart")
    if not hrp or not senderHrp then return end

    local dist = (senderHrp.Position - hrp.Position).Magnitude

    -- 1. Реакция на приветствие (Приоритетно!)
    if isGreeting(cleanMsg) and dist <= 50 then
        lastResponseTime = tick()
        sayMessage(greetingResponses[math.random(#greetingResponses)])

    -- 2. Команда "Оцени"
    elseif cleanMsg:find("оцени") then
        if dist <= 60 then
            lastResponseTime = tick()
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
            sayMessage(evaluationResponses[math.random(#evaluationResponses)])
        end

    -- 3. Запрос подсказок (Только по слову "команды")
    elseif cleanMsg:find("команды") then
        if dist <= 60 then
            lastResponseTime = tick()
            local randomTips = {
                "Попробуй сказать \"следуй за мной\" чтобы я следовал и если надоест проще сказать \"стоп\"",
                "Попробуй сказать \"расскажи анекдот\" если хочешь послушать анекдоты хотя я эт могу и упомянуть..",
                "Попробуй сказать \"оцени\" и я оценю то что ты имел ввиду!"
            }
            sayMessage(randomTips[math.random(#randomTips)])
        end

    -- 4. Вопросы «ты бот?»
    elseif cleanMsg:find("ты бот") or cleanMsg:find("ты ботик") then
        lastResponseTime = tick()
        sayMessage(botIdentityPhrases[math.random(#botIdentityPhrases)])

    -- 5. Команда «следуй за мной»
    elseif cleanMsg:find("следуй") or cleanMsg:find("следу") or cleanMsg:find("идем за мной") or cleanMsg:find("иди за мной") or cleanMsg:find("за мной") then
        if dist <= 60 then
            lastResponseTime = tick()
            if followingPlayer and followingPlayer ~= senderPlayer then
                sayMessage("сорян, я уже хожу за другим!")
            else
                followingPlayer = senderPlayer
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
                sayMessage("оке")
            end
        end

    -- 6. Команда «стоп»
    elseif cleanMsg:find("хватит") or cleanMsg:find("отвянь") or cleanMsg:find("стоп") or cleanMsg:find("не иди") then
        if followingPlayer == senderPlayer then
            lastResponseTime = tick()
            followingPlayer = nil
            sayMessage("лан покеда")
        end

    -- 7. Расскажи анекдот
    elseif cleanMsg:find("анекдот") or cleanMsg:find("расскажи") then
        if dist <= 60 then
            lastResponseTime = tick()
            sayMessage(jokesList[math.random(#jokesList)])
        end
    end
end

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

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.Chatted:Connect(function(msg) processChatMessage(p, msg) end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        p.Chatted:Connect(function(msg) processChatMessage(p, msg) end)
    end
end)

-- Главный цикл ИИ
safeSpawn(function()
    print("[BOT]: Поток ИИ готов!")
    while true do
        safeWait(0.2)

        if botActive then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hum and hrp and hum.Health > 0 then

                local threatPos, isFront = checkCartThreat(hrp)

                -- 1. Побег от тележки
                if threatPos ~= nil then
                    hum.WalkSpeed = 32

                    local escapeTarget
                    if isFront then
                        escapeTarget = hrp.Position - (hrp.CFrame.LookVector * 28)
                    else
                        escapeTarget = hrp.Position + (hrp.CFrame.LookVector * 28)
                    end

                    hum:MoveTo(escapeTarget)
                    sayMessage(cartEscapePhrases[math.random(#cartEscapePhrases)])
                    if math.random(1, 2) == 1 then hum.Jump = true end

                    safeWait(1.2)
                    hum.WalkSpeed = 16

                -- 2. Режим следования
                elseif followingPlayer then
                    local targetChar = followingPlayer.Character
                    local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")

                    if targetChar and targetHrp and targetHum and targetHum.Health > 0 then
                        local dist = (targetHrp.Position - hrp.Position).Magnitude

                        if dist > 130 then
                            sayMessage("ну знаешь чел я не флеш как ты так что адиос")
                            followingPlayer = nil
                            safeWait(1)
                        elseif dist > 7.5 then
                            hum:MoveTo(targetHrp.Position)
                            if math.random(1, 12) == 1 then hum.Jump = true end
                        else
                            local lookPos = Vector3.new(targetHrp.Position.X, hrp.Position.Y, targetHrp.Position.Z)
                            if (hrp.Position - lookPos).Magnitude > 0.1 then
                                hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(hrp.Position, lookPos), 0.2)
                            end
                        end
                    else
                        followingPlayer = nil
                    end
                    safeWait(0.2)

                -- 3. Автономный режим
                else
                    local distFromSpawn = (hrp.Position - spawnPosition).Magnitude
                    local shouldReturnSpawn = returnToSpawnActive and (distFromSpawn > 120 or (math.random(1, 20) == 20 and distFromSpawn > 50))

                    if shouldReturnSpawn then
                        safeMoveTo(spawnPosition + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6)))
                        if math.random(1, 2) == 1 then
                            sayMessage(spawnReturnPhrases[math.random(#spawnReturnPhrases)])
                        end
                        safeWait(math.random(3, 6))
                    else
                        local actionChance = math.random(1, 10)

                        if actionChance <= 2 then
                            local targetChar = getNearestPlayer(12, 55)
                            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                                local tHrp = targetChar.HumanoidRootPart
                                local observeStart = tick()

                                while tick() - observeStart < 8 and botActive and not followingPlayer do
                                    if tHrp and hrp then
                                        local targetLookPos = Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z)
                                        hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(hrp.Position, targetLookPos), 0.15)
                                    end
                                    safeWait(0.05)
                                end
                            else
                                safeMoveTo(hrp.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
                                safeWait(math.random(2, 5))
                            end

                        elseif actionChance == 3 then
                            local targetChar = getNearestPlayer(0, 35)
                            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                                local tHrp = targetChar.HumanoidRootPart
                                safeMoveTo(tHrp.Position + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4)))
                                safeWait(1.5)

                                if hrp and tHrp then
                                    local targetLookPos = Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z)
                                    hrp.CFrame = CFrame.lookAt(hrp.Position, targetLookPos)
                                    sayMessage(playerStarePhrases[math.random(#playerStarePhrases)])
                                end
                                safeWait(math.random(3, 6))
                            else
                                safeMoveTo(hrp.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
                                safeWait(math.random(2, 5))
                            end

                        elseif actionChance <= 6 then
                            safeMoveTo(hrp.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
                            safeWait(math.random(3, 7))

                        elseif actionChance <= 9 then
                            safeWait(math.random(4, 8))

                        else
                            useRandomItem()
                            safeWait(math.random(2, 4))
                        end
                    end
                end

                -- 4. Периодические фразы
                if tick() - lastChatTime >= chatCooldown then
                    sayMessage(randomPhrases[math.random(#randomPhrases)])
                    lastChatTime = tick()
                    chatCooldown = math.random(12, 25)
                end

            end
        end
    end
end)

print("[BOT]: Скрипт успешно запущен без ошибок!")
