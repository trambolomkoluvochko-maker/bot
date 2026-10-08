-- ==========================================
-- LIVE SKIN BOT (RU/EN LANGUAGE TOGGLE + FULL UI & DYNAMIC LOCALIZATION)
-- ==========================================

print("[BOT]: Запуск обновленного скрипта с выбором языка...")

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
local currentLanguage = "RU" -- "RU" или "EN"
local lastChatTime = tick()
local lastResponseTime = 0
local chatCooldown = math.random(12, 25)
local followingPlayer = nil
local spawnPosition = Vector3.new(0, 5, 0)
local Connections = {}

-- Перевод кириллицы
local cyrillicUpper = {
    ["А"]="а", ["Б"]="б", ["В"]="в", ["Г"]="г", ["Д"]="д", ["Е"]="е", ["Ё"]="ё",
    ["Ж"]="ж", ["З"]="з", ["И"]="и", ["Й"]="й", ["К"]="к", ["Л"]="л", ["М"]="м",
    ["Н"]="н", ["О"]="о", ["П"]="п", ["Р"]="р", ["С"]="с", ["Т"]="т", ["У"]="у",
    ["Ф"]="ф", ["Х"]="х", ["Ц"]="ц", ["Ч"]="ч", ["Ш"]="ш", ["Щ"]="щ", ["Ъ"]="ъ",
    ["Ы"]="ы", ["Ь"]="ь", ["Э"]="э", ["Ю"]="ю", ["Я"]="я"
}

local function cleanText(str)
    if not str then return "" end
    for upperChar, lowerChar in pairs(cyrillicUpper) do
        str = str:gsub(upperChar, lowerChar)
    end
    return str:lower()
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

if LocalPlayer.Character then updateSpawnPosition() end
LocalPlayer.CharacterAdded:Connect(function(char)
    safeWait(1)
    updateSpawnPosition()
end)

-- ------------------------------------------
-- БАЗА ФРАЗ (RU & EN)
-- ------------------------------------------
local Translations = {
    RU = {
        randomPhrases = {
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
        },
        playerStare = {
            "Знаешь.. иногда найти ту самую половинку не просто", "Все еще меняем скинчик м?", "🤨", "Афк? Думаю да..", 
            "Э ты че на нашем районе потерял?", "._.", "Я к тебе подходил уже или нет?..", "ПрЕвЕт МеЛкИй Че ДеЛаЕшЬ?", 
            "Выглядишь странно..", "АФИГЕТ Я ДАЖЕ НЕЗ КАК ТВОЙ СКИН ВЫГЛЯДИТ!", "Бу", "Живой нет?"
        },
        cartEscape = {
            "НЕ НЕ НЕ НЕ В ЭТОТ РАЗ", "НЕНАДО ДЯДЯ.. ИЛИ ТЕТЯ", "НУ НАФ", "НЕТ НЕТ НЕЕЕТ!", 
            "Я СВАЛИВАЮ!", "ДА ЧТО Я ТЕБЕ ЗДЕЛАЛ?!?", "КЫШ КЫШ!", "ноу ноу ноу мистер плеер", "Э"
        },
        jokes = {
            "Заходит бот в бар, а бармен ему: 'Служба поддержки в соседнем здании!'",
            "Почему программисты любят темную тему? Свет привлекает багов!",
            "Учитель: 'Иван, почему ты говоришь с ботом?' Иван: 'Он хотя бы меня слушает!'",
            "— Ты веришь в людей? — Не, это просто миф для школьников.",
            "Знаешь почему роботы не врут? Код не позволяет!",
            "Зашел бот в систему... а там вирусы праздник отмечают.",
            "Почему боты никогда не опаздывают? У них встроен задержка safeWait!",
            "— Бот, ты спишь? — Нет, я в бесконечном цикле while true do!"
        },
        evaluation = {
            "я не вижу смысла оценивать это днище", "10/10 ну чисто имба!", "0/10 без комментариев..",
            "5/10 сойдет для сельской местности", "8/10 очень даже неплохо!", "1/10 такое себе если честно..",
            "7/10 норм, пойдет", "9/10 стильно!", "3/10 мда уж..", "100/10 чисто легенда!"
        },
        greetings = { "?", "Даров", "Досвидание", "Прив", "Здарова" },
        botIdentity = { "А ты тоже чтоли?", "Нет я болтик", "Ес оф корс" },
        spawnReturn = {
            "Какой гений меня отправил в африку? Мне нравилось усебя быть..",
            "Надоела эта брукхейвенская рутина..", "ДА ЧТОЖ ТЫ ПОДЕЛАЕШЬ ТА БЛ", "Ох.. это не спавн?"
        },
        seatReaction = { "че думал на меня это сработает? Жаль", "и не говорите что я простой бот который зашел сюда по фану", "ДОСТАЛ БЛ", "Нет.", "Не не такое не прокатит на мне", "..." },
        tips = {
            "Попробуй сказать \"следуй за мной\" чтобы я следовал и если надоест проще сказать \"стоп\"",
            "Попробуй сказать \"расскажи анекдот\" если хочешь послушать анекдоты хотя я эт могу и упомянуть..",
            "Попробуй сказать \"оцени\" и я оценю то что ты имел ввиду!"
        },
        alreadyFollowing = "сорян, я уже хожу за другим!",
        followOk = "оке",
        stopOk = "лан покеда",
        farPlayer = "ну знаешь чел я не флеш как ты так что адиос"
    },
    EN = {
        randomPhrases = {
            "everything is weird here..", "WHY IS BEING A TOWER TRENDY?!?", "i've seen WAY more interesting servers than this..", "hmm...", 
            "Oh oh oh shouldn't have eaten that spicy latiao", "WHERE DO I PRESS?!", "Ahaha.. oh", ":/", "yeah", "pretty mid place", 
            "Is chat alive I hope?..", "Yeah I'm a simple bot so what? Can't I just live here too?", "You know.. sometimes being a bot is hard", 
            "shouldn't have eaten that...", "BOOOORIIING", "I can't answer your arguments so sorry", "Obamna", 
            "I have black dots instead of eyes..", "Want to hear a joke? Type \"joke\" or \"commands\" in chat", 
            ":0", "Walking around doing nothing", "RP action sniffed the air", "Bots are people too", "UwU", "I.. I forgot where to go", 
            "world is so cold..", "Fun fact: this is a fun fact", "guys send hw pls", "I wanna live", 
            "Everyone is so boring here..", "I'm nobody's dinner...", "😶", "🍞",
            "Boring.. boring.. just walking wherever my eyes go..", "Why does everyone think bots in rb are evil? It's not that bad..",
            "If you close your eyes it gets dark", "If you're sad.. don't be", "pharmacies don't sell time because time doesn't heal",
            "This crosshair is OP!", "Cheeki breeki..", "Oh well..", "I am NOT from that other game!", "Going for raspberries who's with me?.. nobody?..",
            "do you know what time it is?"
        },
        playerStare = {
            "You know.. sometimes finding that soulmate isn't easy", "Still changing your outfit huh?", "🤨", "AFK? I guess so..", 
            "Hey what are you lost in our neighborhood for?", "._.", "Did I approach you already or not?..", "HeLlo LiTtLe OnE wHaT u DoInG?", 
            "You look weird..", "OMG I DON'T EVEN KNOW WHAT YOUR SKIN LOOKS LIKE!", "Boo!", "Alive or what?"
        },
        cartEscape = {
            "NO NO NO NOT THIS TIME", "DONT TOUCH ME..", "NOPE NOPE NOPE!", 
            "I AM OUT OF HERE!", "WHAT DID I DO TO YOU?!?", "SHOO SHOO!", "no no no mr player", "HEY!"
        },
        jokes = {
            "A bot walks into a bar... support team is in the next building!",
            "Why do programmers prefer dark mode? Because light attracts bugs!",
            "Teacher: 'Why are you talking to a bot?' Student: 'At least he listens!'",
            "— Do you believe in humans? — No, that's just a myth for kids.",
            "Why don't robots lie? Code doesn't allow it!",
            "A bot joined the system... and viruses are having a party there.",
            "Why are bots never late? They have a built-in safeWait delay!",
            "— Bot, are you sleeping? — No, I'm in a while true do loop!"
        },
        evaluation = {
            "i see no point in rating this garbage", "10/10 absolute masterclass!", "0/10 no comment..",
            "5/10 average at best", "8/10 pretty good!", "1/10 terrible to be honest..",
            "7/10 decent, works for me", "9/10 stylish!", "3/10 meh..", "100/10 pure legend!"
        },
        greetings = { "?", "sup", "bye", "hi", "hello", "yo" },
        botIdentity = { "are you a bot too?", "no i am a screw", "yes of course" },
        spawnReturn = {
            "Who sent me to Africa? I liked where I was..",
            "Tired of this Brookhaven routine..", "WHAT IS THIS AGAIN BRUH", "Oh.. is this spawn?"
        },
        seatReaction = { "did you think that would work on me? pity", "and don't say I'm just a simple bot who joined for fun", "STOP IT BRUH", "No.", "Nope that won't work on me", "..." },
        tips = {
            "Try saying \"follow me\" so I follow and \"stop\" if you get tired of it!",
            "Try saying \"tell a joke\" if you want to hear jokes!",
            "Try saying \"rate\" and I will rate what you meant!"
        },
        alreadyFollowing = "sorry, I'm already following someone else!",
        followOk = "ok",
        stopOk = "alright bye",
        farPlayer = "well you know I'm not flash like you so adios"
    }
}

-- ------------------------------------------
-- ФУНКЦИИ ЧАТА И ВСПОМОГАТЕЛЬНЫЕ
-- ------------------------------------------

local function sayMessage(text)
    if not text or text == "" then return end
    safeSpawn(function()
        pcall(function()
            local sent = false
            if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then channel:SendAsync(text) sent = true end
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
    local greetings = { "ку", "пр", "привет", "хай", "дратути", "здарова", "салам", "хеллоу", "здаров", "даров", "здарово", "hi", "hello", "hey", "sup", "yo" }
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
                if (pHrp.Position - hrp.Position).Magnitude <= 12 then
                    local hasSeatItem = false
                    for _, desc in ipairs(player.Character:GetDescendants()) do
                        if desc:IsA("Seat") or desc:IsA("VehicleSeat") then
                            hasSeatItem = true; break
                        end
                    end
                    if hasSeatItem then
                        local localPos = hrp.CFrame:PointToObjectSpace(pHrp.Position)
                        return pHrp.Position, (localPos.Z < 0)
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

local function giveTool(toolName)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    local reFolder = ReplicatedStorage:FindFirstChild("RE")
    local toolRemote = reFolder and (reFolder:FindFirstChild("1Tool1") or reFolder:FindFirstChild("1Item1"))

    if toolRemote then
        pcall(function() toolRemote:FireServer(toolName) end)
    end

    safeWait(0.1)
    if not backpack:FindFirstChild(toolName) then
        for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
            if item:IsA("Tool") and item.Name == toolName then
                pcall(function()
                    local clone = item:Clone()
                    clone.Parent = backpack
                end)
                break
            end
        end
    end
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
-- 🖱 UI ИНТЕРФЕЙС БОТА
-- ==========================================
local parentGui = getGuiParent()

for _, child in ipairs(parentGui:GetChildren()) do
    if child.Name == "LiveBotCanavaGui" then child:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiveBotCanavaGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = parentGui

-- Главная кнопка ИИ (Гарантированно видимый ✕ с шрифтом SourceSansBold)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "BotButton"
ToggleButton.Size = UDim2.new(0, 52, 0, 52)
ToggleButton.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.Text = "✕"
ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
ToggleButton.TextSize = 24
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Active = true
ToggleButton.Parent = ScreenGui

local BtnCorner = Instance.new("UICorner", ToggleButton)
BtnCorner.CornerRadius = UDim.new(1, 0)
local BtnStroke = Instance.new("UIStroke", ToggleButton)
BtnStroke.Thickness = 2
BtnStroke.Color = Color3.fromRGB(80, 80, 80)

-- Кнопка шестеренки (Настройки)
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

Instance.new("UICorner", MenuToggleBtn).CornerRadius = UDim.new(1, 0)
local MenuStroke = Instance.new("UIStroke", MenuToggleBtn)
MenuStroke.Thickness = 1.5
MenuStroke.Color = Color3.fromRGB(100, 100, 180)

-- Выдвижное меню
local SubMenuFrame = Instance.new("Frame")
SubMenuFrame.Name = "SubMenuFrame"
SubMenuFrame.Size = UDim2.new(0, 160, 0, 0)
SubMenuFrame.Position = UDim2.new(0.05, 0, 0.4, 58)
SubMenuFrame.BackgroundTransparency = 1
SubMenuFrame.ClipsDescendants = true
SubMenuFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout", SubMenuFrame)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)

-- 1. Кнопка спавна
local SpawnToggleBtn = Instance.new("TextButton", SubMenuFrame)
SpawnToggleBtn.Size = UDim2.new(0, 160, 0, 30)
SpawnToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 35, 55)
SpawnToggleBtn.Text = "🏠 Спавн: ВКЛ"
SpawnToggleBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
SpawnToggleBtn.TextSize = 11
SpawnToggleBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", SpawnToggleBtn).CornerRadius = UDim.new(0, 8)
local SpawnStroke = Instance.new("UIStroke", SpawnToggleBtn)
SpawnStroke.Thickness = 1.5
SpawnStroke.Color = Color3.fromRGB(60, 150, 255)

-- 2. Кнопка задать точку спавна
local SetSpawnBtn = Instance.new("TextButton", SubMenuFrame)
SetSpawnBtn.Size = UDim2.new(0, 160, 0, 30)
SetSpawnBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 55)
SetSpawnBtn.Text = "📍 Задать спавн"
SetSpawnBtn.TextColor3 = Color3.fromRGB(255, 150, 255)
SetSpawnBtn.TextSize = 11
SetSpawnBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", SetSpawnBtn).CornerRadius = UDim.new(0, 8)
local SetSpawnStroke = Instance.new("UIStroke", SetSpawnBtn)
SetSpawnStroke.Thickness = 1.5
SetSpawnStroke.Color = Color3.fromRGB(180, 80, 200)

-- 3. Кнопка переключения языка (RU / EN)
local LanguageBtn = Instance.new("TextButton", SubMenuFrame)
LanguageBtn.Size = UDim2.new(0, 160, 0, 30)
LanguageBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
LanguageBtn.Text = "🌐 Язык: RU"
LanguageBtn.TextColor3 = Color3.fromRGB(220, 200, 120)
LanguageBtn.TextSize = 11
LanguageBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", LanguageBtn).CornerRadius = UDim.new(0, 8)
local LanguageStroke = Instance.new("UIStroke", LanguageBtn)
LanguageStroke.Thickness = 1.5
LanguageStroke.Color = Color3.fromRGB(200, 180, 80)

-- 4. Кнопка каталога предметов
local OpenItemsBtn = Instance.new("TextButton", SubMenuFrame)
OpenItemsBtn.Size = UDim2.new(0, 160, 0, 30)
OpenItemsBtn.BackgroundColor3 = Color3.fromRGB(20, 45, 30)
OpenItemsBtn.Text = "📜 Список предметов"
OpenItemsBtn.TextColor3 = Color3.fromRGB(120, 255, 160)
OpenItemsBtn.TextSize = 10
OpenItemsBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", OpenItemsBtn).CornerRadius = UDim.new(0, 8)
local OpenItemsStroke = Instance.new("UIStroke", OpenItemsBtn)
OpenItemsStroke.Thickness = 1.5
OpenItemsStroke.Color = Color3.fromRGB(80, 220, 120)

-- 5. Кнопка выключения скрипта
local UnloadBtn = Instance.new("TextButton", SubMenuFrame)
UnloadBtn.Size = UDim2.new(0, 160, 0, 30)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(55, 15, 15)
UnloadBtn.Text = "⛔ Удалить скрипт"
UnloadBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
UnloadBtn.TextSize = 10
UnloadBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", UnloadBtn).CornerRadius = UDim.new(0, 8)
local UnloadStroke = Instance.new("UIStroke", UnloadBtn)
UnloadStroke.Thickness = 1.5
UnloadStroke.Color = Color3.fromRGB(220, 60, 60)

-- ==========================================
-- 🎒 ОКНО ВЫБОРА ПРЕДМЕТОВ (КАТАЛОГ ИВЕНТОВ/VIP)
-- ==========================================
local ItemsFrame = Instance.new("Frame", ScreenGui)
ItemsFrame.Name = "ItemsFrame"
ItemsFrame.Size = UDim2.new(0, 240, 0, 290)
ItemsFrame.Position = UDim2.new(0.05, 170, 0.3, 0)
ItemsFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
ItemsFrame.Visible = false
ItemsFrame.Active = true

Instance.new("UICorner", ItemsFrame).CornerRadius = UDim.new(0, 10)
local ItemsFrameStroke = Instance.new("UIStroke", ItemsFrame)
ItemsFrameStroke.Thickness = 2
ItemsFrameStroke.Color = Color3.fromRGB(80, 220, 120)

local TitleLabel = Instance.new("TextLabel", ItemsFrame)
TitleLabel.Size = UDim2.new(1, -30, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎒 ИВЕНТЫ & VIP ВЕЩИ"
TitleLabel.TextColor3 = Color3.fromRGB(120, 255, 160)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.FredokaOne
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseItemsBtn = Instance.new("TextButton", ItemsFrame)
CloseItemsBtn.Size = UDim2.new(0, 24, 0, 24)
CloseItemsBtn.Position = UDim2.new(1, -28, 0, 5)
CloseItemsBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
CloseItemsBtn.Text = "✕"
CloseItemsBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseItemsBtn.Font = Enum.Font.SourceSansBold
CloseItemsBtn.TextSize = 12
Instance.new("UICorner", CloseItemsBtn).CornerRadius = UDim.new(0, 6)

local SearchBox = Instance.new("TextBox", ItemsFrame)
SearchBox.Size = UDim2.new(1, -20, 0, 28)
SearchBox.Position = UDim2.new(0, 10, 0, 38)
SearchBox.BackgroundColor3 = Color3.fromRGB(30, 33, 42)
SearchBox.PlaceholderText = "🔍 Поиск вещи..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 11
SearchBox.Font = Enum.Font.FredokaOne
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)

local ItemScroll = Instance.new("ScrollingFrame", ItemsFrame)
ItemScroll.Size = UDim2.new(1, -20, 1, -78)
ItemScroll.Position = UDim2.new(0, 10, 0, 72)
ItemScroll.BackgroundTransparency = 1
ItemScroll.ScrollBarThickness = 4
ItemScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 220, 120)

local ScrollLayout = Instance.new("UIListLayout", ItemScroll)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScrollLayout.Padding = UDim.new(0, 4)

ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ItemScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 10)
end)

local RareItemsList = {
    ["💳 Gamepass"] = { "Money Gun", "Rocket Launcher" },
    ["🐰 Пасха"] = { "Egg Launcher", "Spring Shufflers" },
    ["🎡 Карнавал"] = { "Glider", "Cannon", "Golden Basketball" },
    ["🎃 Хэллоуин"] = { "Candy Basket", "Chainsaw", "Trick or treat bag" },
    ["❄️ Снежный Фестиваль"] = { "Snowball Cannon", "Thermos", "Lollipop Peppermint", "Snowball", "Snowflake Glider" }
}

local function populateItemList(filterText)
    for _, child in ipairs(ItemScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end

    filterText = filterText and filterText:lower() or ""

    for catName, items in pairs(RareItemsList) do
        local catHeader = Instance.new("TextLabel", ItemScroll)
        catHeader.Size = UDim2.new(1, 0, 0, 20)
        catHeader.BackgroundTransparency = 1
        catHeader.Text = catName
        catHeader.TextColor3 = Color3.fromRGB(255, 200, 100)
        catHeader.TextSize = 10
        catHeader.Font = Enum.Font.FredokaOne
        catHeader.TextXAlignment = Enum.TextXAlignment.Left

        for _, itemName in ipairs(items) do
            if filterText == "" or itemName:lower():find(filterText, 1, true) then
                local toolBtn = Instance.new("TextButton", ItemScroll)
                toolBtn.Size = UDim2.new(1, -6, 0, 24)
                toolBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
                toolBtn.Text = "  " .. itemName
                toolBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
                toolBtn.TextSize = 10
                toolBtn.Font = Enum.Font.FredokaOne
                toolBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UICorner", toolBtn).CornerRadius = UDim.new(0, 6)

                toolBtn.MouseButton1Click:Connect(function()
                    giveTool(itemName)
                    toolBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 70)
                    task.delay(0.4, function()
                        if toolBtn then toolBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 46) end
                    end)
                end)
            end
        end
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function() populateItemList(SearchBox.Text) end)

-- ==========================================
-- МОДАЛЬНОЕ ОКНО ПОДТВЕРЖДЕНИЯ ВЫКЛЮЧЕНИЯ
-- ==========================================
local function showUnloadConfirmation()
    local confirmOverlay = Instance.new("Frame", ScreenGui)
    confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
    confirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    confirmOverlay.BackgroundTransparency = 0.5
    confirmOverlay.ZIndex = 1000

    local confirmBox = Instance.new("Frame", confirmOverlay)
    confirmBox.Size = UDim2.new(0, 280, 0, 140)
    confirmBox.Position = UDim2.new(0.5, -140, 0.5, -70)
    confirmBox.BackgroundColor3 = Color3.fromRGB(25, 27, 35)
    Instance.new("UICorner", confirmBox).CornerRadius = UDim.new(0, 10)

    local warnText = Instance.new("TextLabel", confirmBox)
    warnText.Size = UDim2.new(1, -20, 0, 60)
    warnText.Position = UDim2.new(0, 10, 0, 10)
    warnText.Text = currentLanguage == "RU" and "Вы уверены?\nЕсли вы выключите скрипт, бот отключится!" or "Are you sure?\nIf you turn off the script, the bot will stop!"
    warnText.TextColor3 = Color3.fromRGB(255, 200, 100)
    warnText.Font = Enum.Font.FredokaOne
    warnText.TextSize = 12
    warnText.TextWrapped = true
    warnText.BackgroundTransparency = 1

    local yesBtn = Instance.new("TextButton", confirmBox)
    yesBtn.Size = UDim2.new(0.4, 0, 0, 32)
    yesBtn.Position = UDim2.new(0.08, 0, 0.65, 0)
    yesBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    yesBtn.Text = currentLanguage == "RU" and "Да" or "Yes"
    yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    yesBtn.Font = Enum.Font.FredokaOne
    Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 6)

    local noBtn = Instance.new("TextButton", confirmBox)
    noBtn.Size = UDim2.new(0.4, 0, 0, 32)
    noBtn.Position = UDim2.new(0.52, 0, 0.65, 0)
    noBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
    noBtn.Text = currentLanguage == "RU" and "Нет" or "Cancel"
    noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    noBtn.Font = Enum.Font.FredokaOne
    Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 6)

    yesBtn.MouseButton1Click:Connect(function()
        for _, conn in pairs(Connections) do
            if conn and typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        end
        table.clear(Connections)
        ScreenGui:Destroy()
        print("[BOT]: Скрипт выключен!")
    end)

    noBtn.MouseButton1Click:Connect(function() confirmOverlay:Destroy() end)
end

-- ==========================================
-- УПРАВЛЕНИЕ МЕНЮ И ПЕРЕТАСКИВАНИЕ
-- ==========================================
local menuOpen = false
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

MenuToggleBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        TweenService:Create(SubMenuFrame, tweenInfo, {Size = UDim2.new(0, 160, 0, 175)}):Play()
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
        SpawnToggleBtn.Text = currentLanguage == "RU" and "🏠 Спавн: ВКЛ" or "🏠 Spawn: ON"
        SpawnToggleBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
        TweenService:Create(SpawnToggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(15, 35, 55)}):Play()
        TweenService:Create(SpawnStroke, tweenInfo, {Color = Color3.fromRGB(60, 150, 255)}):Play()
    else
        SpawnToggleBtn.Text = currentLanguage == "RU" and "🏠 Спавн: ВЫКЛ" or "🏠 Spawn: OFF"
        SpawnToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        TweenService:Create(SpawnToggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
        TweenService:Create(SpawnStroke, tweenInfo, {Color = Color3.fromRGB(100, 100, 100)}):Play()
    end
end

-- Перетаскивание всего блока
local dragging = false
local dragMoved = false
local dragStart, startPos, menuStartPos, subMenuStartPos, itemsStartPos

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragMoved = false; dragStart = input.Position
        startPos = ToggleButton.Position; menuStartPos = MenuToggleBtn.Position
        subMenuStartPos = SubMenuFrame.Position; itemsStartPos = ItemsFrame.Position
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
            ItemsFrame.Position = UDim2.new(itemsStartPos.X.Scale, itemsStartPos.X.Offset + delta.X, itemsStartPos.Y.Scale, itemsStartPos.Y.Offset + delta.Y)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

ToggleButton.MouseButton1Click:Connect(function()
    if not dragMoved then
        botActive = not botActive
        updateUIState(botActive)
        if not botActive then followingPlayer = nil end
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
            SetSpawnBtn.Text = currentLanguage == "RU" and "📍 Спавн обновлен!" or "📍 Spawn Updated!"
            task.delay(1.5, function() 
                SetSpawnBtn.Text = currentLanguage == "RU" and "📍 Задать спавн" or "📍 Set Spawn Point"
            end)
        end
    end
end)

-- Переключатель языка
LanguageBtn.MouseButton1Click:Connect(function()
    if currentLanguage == "RU" then
        currentLanguage = "EN"
        LanguageBtn.Text = "🌐 Language: EN"
        LanguageBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
        LanguageStroke.Color = Color3.fromRGB(80, 160, 220)
        SetSpawnBtn.Text = "📍 Set Spawn Point"
        OpenItemsBtn.Text = "📜 Items Catalog"
        UnloadBtn.Text = "⛔ Delete Script"
    else
        currentLanguage = "RU"
        LanguageBtn.Text = "🌐 Язык: RU"
        LanguageBtn.TextColor3 = Color3.fromRGB(220, 200, 120)
        LanguageStroke.Color = Color3.fromRGB(200, 180, 80)
        SetSpawnBtn.Text = "📍 Задать спавн"
        OpenItemsBtn.Text = "📜 Список предметов"
        UnloadBtn.Text = "⛔ Удалить скрипт"
    end
    updateSpawnBtnState(returnToSpawnActive)
end)

OpenItemsBtn.MouseButton1Click:Connect(function()
    ItemsFrame.Visible = not ItemsFrame.Visible
    if ItemsFrame.Visible then populateItemList(SearchBox.Text) end
end)

CloseItemsBtn.MouseButton1Click:Connect(function() ItemsFrame.Visible = false end)
UnloadBtn.MouseButton1Click:Connect(function() showUnloadConfirmation() end)

-- Anti-Sit
local function bindAntiSeat(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
        if botActive and humanoid.Sit then
            safeWait(0.05)
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            local dict = Translations[currentLanguage]
            sayMessage(dict.seatReaction[math.random(#dict.seatReaction)])
        end
    end)
end

if LocalPlayer.Character then bindAntiSeat(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(bindAntiSeat)

-- ==========================================
-- ОБРАБОТКА ЧАТА (РАБОТАЕТ НА ОБОИХ ЯЗЫКАХ)
-- ==========================================
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
    local dict = Translations[currentLanguage]

    -- 1. Реакция на приветствие
    if isGreeting(cleanMsg) and dist <= 50 then
        lastResponseTime = tick()
        sayMessage(dict.greetings[math.random(#dict.greetings)])

    -- 2. Команда "Оцени" / "Rate"
    elseif cleanMsg:find("оцени") or cleanMsg:find("rate") then
        if dist <= 60 then
            lastResponseTime = tick()
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
            sayMessage(dict.evaluation[math.random(#dict.evaluation)])
        end

    -- 3. Команда подсказок "команды" / "commands" / "help" / "помощь"
    elseif cleanMsg:find("команды") or cleanMsg:find("commands") or cleanMsg:find("help") or cleanMsg:find("помощь") then
        if dist <= 60 then
            lastResponseTime = tick()
            sayMessage(dict.tips[math.random(#dict.tips)])
        end

    -- 4. Вопросы «ты бот?» / «you bot?»
    elseif cleanMsg:find("ты бот") or cleanMsg:find("ты ботик") or cleanMsg:find("you bot") or cleanMsg:find("are you a bot") then
        lastResponseTime = tick()
        sayMessage(dict.botIdentity[math.random(#dict.botIdentity)])

    -- 5. Команда «следуй за мной» / «follow me»
    elseif cleanMsg:find("следуй") or cleanMsg:find("follow") or cleanMsg:find("идем за мной") or cleanMsg:find("иди за мной") or cleanMsg:find("за мной") then
        if dist <= 60 then
            lastResponseTime = tick()
            if followingPlayer and followingPlayer ~= senderPlayer then
                sayMessage(dict.alreadyFollowing)
            else
                followingPlayer = senderPlayer
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
                sayMessage(dict.followOk)
            end
        end

    -- 6. Команда «стоп» / «stop»
    elseif cleanMsg:find("хватит") or cleanMsg:find("stop") or cleanMsg:find("стоп") or cleanMsg:find("не иди") then
        if followingPlayer == senderPlayer then
            lastResponseTime = tick()
            followingPlayer = nil
            sayMessage(dict.stopOk)
        end

    -- 7. Расскажи анекдот / Joke
    elseif cleanMsg:find("анекдот") or cleanMsg:find("joke") or cleanMsg:find("tell a joke") or cleanMsg:find("расскажи") then
        if dist <= 60 then
            lastResponseTime = tick()
            sayMessage(dict.jokes[math.random(#dict.jokes)])
        end
    end
end

if TextChatService then
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        local textSource = textChatMessage.TextSource
        if textSource then
            local senderPlayer = Players:GetPlayerByUserId(textSource.UserId)
            if senderPlayer then processChatMessage(senderPlayer, textChatMessage.Text) end
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then p.Chatted:Connect(function(msg) processChatMessage(p, msg) end) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then p.Chatted:Connect(function(msg) processChatMessage(p, msg) end) end
end)

-- ==========================================
-- ГЛАВНЫЙ ЦИКЛ ИИ
-- ==========================================
safeSpawn(function()
    print("[BOT]: Поток ИИ с поддержкой двух языков запущен!")
    while true do
        safeWait(0.2)

        if botActive then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hum and hrp and hum.Health > 0 then

                local threatPos, isFront = checkCartThreat(hrp)
                local dict = Translations[currentLanguage]

                -- 1. Побег от тележки
                if threatPos ~= nil then
                    hum.WalkSpeed = 32
                    local escapeTarget = isFront and (hrp.Position - (hrp.CFrame.LookVector * 28)) or (hrp.Position + (hrp.CFrame.LookVector * 28))
                    hum:MoveTo(escapeTarget)
                    sayMessage(dict.cartEscape[math.random(#dict.cartEscape)])
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
                            sayMessage(dict.farPlayer)
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
                            sayMessage(dict.spawnReturn[math.random(#dict.spawnReturn)])
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
                                    sayMessage(dict.playerStare[math.random(#dict.playerStare)])
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

                -- 4. Периодические случайные фразы в чат
                if tick() - lastChatTime >= chatCooldown then
                    sayMessage(dict.randomPhrases[math.random(#dict.randomPhrases)])
                    lastChatTime = tick()
                    chatCooldown = math.random(12, 25)
                end

            end
        end
    end
end)

print("[BOT]: Всё работает идеально!")
