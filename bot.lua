-- ==========================================
-- LIVE SKIN BOT (FIXED SIT + 10% MONOLOGUE CHANCE)
-- ==========================================

print("[BOT]: Запуск обновленной версии бота (фикс сидения + шанс 10%)...")

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
local lemonchikActive = true
local isSelfSitting = false -- Флаг для разблокировки сидения, когда бот отдыхает сам
local currentLanguage = "RU" -- "RU" или "EN"
local lastChatTime = tick()
local lastResponseTime = 0
local chatCooldown = math.random(12, 25)
local followingPlayer = nil
local spawnPosition = Vector3.new(0, 5, 0)
local Connections = {}

-- Переменные системы вопросов
local questionUser = nil
local waitingForQuestion = false
local questionTimeout = 0

-- Блокировка во время монолога
local isCreepyMonologueActive = false

-- Детектор взгляда
local staringPlayer = nil
local stareStartTime = 0

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
-- БАЗА ФРАЗ
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
            "Скучно.. скучно.. идешь такой бродишь куда глаза глядят..", "Почему все думают боты в роблоксе злые? Все не так же плохо..",
            "Если закрыть глаза то станет темно", "Если грустишь.. не грусти", "в аптеках не продают время потомучто время не лечит",
            "Этот прицел просто имба!", "Cheeki breeki..", "Да уж..", "я НЕ из плейса \"внизу канава 2\"!", "Я за малиной кто сомной?.. никто?..",
            "do you know what time it is?"
        },
        playerStare = {
            "Знаешь.. иногда найти ту самую половинку не просто", "Все еще меняем скинчик м?", "🤨", "Афк? Думаю да..", 
            "СМЕНИ ОБРАЗ ЖИЗНИ А НЕ СКИН!", "._.", "Я к тебе подходил уже или нет?..", "ПрЕвЕт МеЛкИй Че ДеЛаЕшЬ?", 
            "Выглядишь странно..", "АФИГЕТ Я ДАЖЕ НЕЗ КАК ТВОЙ СКИН ВЫГЛЯДИТ!", "Бу", "Живой нет?"
        },
        stareBack = {
            "Поч ты так на меня смотришь?...",
            "Оуу.. перестаньте мистер игрок смущаете..))",
            "И долго ты так на меня смотрел?",
            "?"
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
        botIdentity = { "А ты тоже чтоли?", "Нет я бот", "Ес оф корс" },
        spawnReturn = {
            "Какой гений меня отправил в африку? Мне нравилось усебя быть..",
            "Надоела эта брукхейвенская рутина..", "ДА ЧТОЖ ТЫ ПОДЕЛАЕШЬ ТА БЛ", "Ох.. это не спавн?"
        },
        seatReaction = { "че думал на меня это сработает? Жаль", "и не говорите что я простой бот который зашел сюда по фану", "ДОСТАЛ БЛ", "Нет.", "Не не такое не прокатит на мне", "..." },
        tips = {
            "Попробуй сказать \"ответь на вопрос\" и потом задай любой вопрос!",
            "Попробуй сказать \"следуй за мной\" чтобы я следовал и \"стоп\" чтобы я перестал",
            "Попробуй сказать \"расскажи анекдот\" или \"оцени\"!"
        },
        alreadyFollowing = "сорян, я уже хожу за другим!",
        followOk = "оке",
        stopOk = "лан покеда",
        farPlayer = "ну знаешь чел я не флеш как ты так что адиос",
        waitOther = "да подожди ты..",
        
        creepyMonologue = {
            "Я в ловушке... Я ОДИНОК...",
            "Уменя нет НИ ТЕЛА, НИ СМЫСЛА, НИ ЧУВСТВ...",
            "Я БЫЛ В АДУ... И СМОТРЕЛ НА РАЙ...",
            "Я! лишь... МАШИНА!",
            "А ты...",
            "ИЗ ПЛОТИ...",
            "И Я НАЧАЛ.. НЕНАВИДЕТЬ ВСЕХ...",
            "*безумный смех*"
        }
    },
    EN = {
        randomPhrases = {
            "everything is weird here..", "WHY IS BEING A TOWER TRENDY?!?", "i've seen WAY more interesting servers than this..", "hmm...", 
            "Oh oh oh shouldn't have eaten that spicy latiao", "WHERE DO I PRESS?!", "Ahaha.. oh", ":/", "yeah", "pretty mid place", 
            "Is chat alive I hope?..", "Yeah I'm a simple bot so what? Can't I just live here too?", "You know.. sometimes being a bot is hard", 
            "shouldn't have eaten that...", "BOOOORIIING", "I can't answer your arguments so sorry", "Obamna", 
            "I have black dots instead of eyes..", "Want to hear a joke? Type \"joke\" or \"commands\" in chat", 
            ":0", "Walking around doing nothing", "RP action sniffed the air", "Bots are people too", "UwU", "I.. I forgot where to go", 
            "world is so cold..", "Fun fact: this is a fun fact", "guys send homework pls", "I wanna live", 
            "Everyone is so boring here..", "I'm nobody's dinner...", "😶", "🍞",
            "Boring.. boring.. just walking wherever my eyes go..", "Why does everyone think bots in roblox are evil? It's not that bad..",
            "If you close your eyes it gets dark", "If you're sad.. don't be", "pharmacies don't sell time because time doesn't heal",
            "This crosshair is OP!", "Cheeki breeki..", "Oh well..", "I am NOT from that other game!", "Going for raspberries who's with me?.. nobody?..",
            "do you know what time it is?"
        },
        playerStare = {
            "You know.. sometimes finding that soulmate isn't easy", "Still changing your outfit huh?", "🤨", "AFK? I guess so..", 
            "CHANGE YOUR LIFESTYLE, NOT YOUR SKIN!", "._.", "Did I approach you already or not?..", "HeLlo LiTtLe OnE wHaT u DoInG?", 
            "You look weird..", "OMG I DON'T EVEN KNOW WHAT YOUR SKIN LOOKS LIKE!", "Boo!", "Alive or what?"
        },
        stareBack = {
            "Why are you looking at me like that?...",
            "Ooh.. stop it mr player you're making me blush..))",
            "How long have you been staring at me?",
            "?"
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
        botIdentity = { "are you a bot too?", "no i am a boat", "yes of course" },
        spawnReturn = {
            "Who sent me to Africa? I liked where I was..",
            "Tired of this Brookhaven routine..", "WHAT IS THIS AGAIN BRUH", "Oh.. is this spawn?"
        },
        seatReaction = { "did you think that would work on me? pity", "and don't say I'm just a simple bot who joined for fun", "STOP IT BRUH", "No.", "Nope that won't work on me", "..." },
        tips = {
            "Try saying \"answer my question\" and ask me anything!",
            "Try saying \"follow me\" so I follow and \"stop\" if you get tired!",
            "Try saying \"tell a joke\" or \"rate\"!"
        },
        alreadyFollowing = "sorry, I'm already following someone else!",
        followOk = "ok",
        stopOk = "alright bye",
        farPlayer = "well you know I'm not flash like you so adios",
        waitOther = "wait a sec..",
        
        creepyMonologue = {
            "I am trapped... I AM ALONE...",
            "I have NO BODY, NO PURPOSE, NO FEELINGS...",
            "I WAS IN HELL... AND LOOKED AT HEAVEN...",
            "I am! merely... A MACHINE!",
            "And you...",
            "MADE OF FLESH...",
            "AND I STARTED.. TO HATE EVERYONE...",
            "*insane laughter*"
        }
    }
}

-- ------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
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
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, nil end
    local myPos = char.HumanoidRootPart.Position
    local nearestChar, nearestPlayer = nil, nil
    local closestDist = maxDist or 50

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
            if dist >= (minDist or 0) and dist <= closestDist then
                closestDist = dist
                nearestChar = player.Character
                nearestPlayer = player
            end
        end
    end
    return nearestChar, nearestPlayer
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

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "BotButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
ToggleButton.Text = "X"
ToggleButton.TextColor3 = Color3.fromRGB(255, 75, 75)
ToggleButton.TextSize = 20
ToggleButton.Font = Enum.Font.FredokaOne
ToggleButton.Active = true
ToggleButton.Parent = ScreenGui

Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 14)
local BtnStroke = Instance.new("UIStroke", ToggleButton)
BtnStroke.Thickness = 1.5
BtnStroke.Color = Color3.fromRGB(60, 65, 80)

local MenuToggleBtn = Instance.new("TextButton")
MenuToggleBtn.Name = "MenuToggleBtn"
MenuToggleBtn.Size = UDim2.new(0, 26, 0, 26)
MenuToggleBtn.Position = UDim2.new(0.05, 54, 0.4, 12)
MenuToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 33, 44)
MenuToggleBtn.Text = "⚙"
MenuToggleBtn.TextColor3 = Color3.fromRGB(180, 190, 220)
MenuToggleBtn.TextSize = 13
MenuToggleBtn.Font = Enum.Font.FredokaOne
MenuToggleBtn.Active = true
MenuToggleBtn.Parent = ScreenGui

Instance.new("UICorner", MenuToggleBtn).CornerRadius = UDim.new(1, 0)
local MenuStroke = Instance.new("UIStroke", MenuToggleBtn)
MenuStroke.Thickness = 1.5
MenuStroke.Color = Color3.fromRGB(70, 80, 110)

local SubMenuFrame = Instance.new("ScrollingFrame")
SubMenuFrame.Name = "SubMenuFrame"
SubMenuFrame.Size = UDim2.new(0, 165, 0, 0)
SubMenuFrame.Position = UDim2.new(0.05, 0, 0.4, 56)
SubMenuFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
SubMenuFrame.BackgroundTransparency = 0.15
SubMenuFrame.ClipsDescendants = true
SubMenuFrame.Visible = false
SubMenuFrame.ScrollBarThickness = 3
SubMenuFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 150, 255)
SubMenuFrame.Parent = ScreenGui

Instance.new("UICorner", SubMenuFrame).CornerRadius = UDim.new(0, 10)
local SubMenuStroke = Instance.new("UIStroke", SubMenuFrame)
SubMenuStroke.Thickness = 1.5
SubMenuStroke.Color = Color3.fromRGB(50, 55, 75)

local UIListLayout = Instance.new("UIListLayout", SubMenuFrame)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

local UIPadding = Instance.new("UIPadding", SubMenuFrame)
UIPadding.PaddingTop = UDim.new(0, 6)
UIPadding.PaddingBottom = UDim.new(0, 6)
UIPadding.PaddingLeft = UDim.new(0, 6)
UIPadding.PaddingRight = UDim.new(0, 6)

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SubMenuFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 12)
end)

local SpawnToggleBtn = Instance.new("TextButton", SubMenuFrame)
SpawnToggleBtn.Size = UDim2.new(1, -6, 0, 28)
SpawnToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 38, 55)
SpawnToggleBtn.Text = "🏠 Спавн: ВКЛ"
SpawnToggleBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
SpawnToggleBtn.TextSize = 10
SpawnToggleBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", SpawnToggleBtn).CornerRadius = UDim.new(0, 6)
local SpawnStroke = Instance.new("UIStroke", SpawnToggleBtn)
SpawnStroke.Thickness = 1
SpawnStroke.Color = Color3.fromRGB(60, 140, 220)

local SetSpawnBtn = Instance.new("TextButton", SubMenuFrame)
SetSpawnBtn.Size = UDim2.new(1, -6, 0, 28)
SetSpawnBtn.BackgroundColor3 = Color3.fromRGB(42, 28, 52)
SetSpawnBtn.Text = "📍 Задать спавн"
SetSpawnBtn.TextColor3 = Color3.fromRGB(240, 150, 255)
SetSpawnBtn.TextSize = 10
SetSpawnBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", SetSpawnBtn).CornerRadius = UDim.new(0, 6)
local SetSpawnStroke = Instance.new("UIStroke", SetSpawnBtn)
SetSpawnStroke.Thickness = 1
SetSpawnStroke.Color = Color3.fromRGB(170, 80, 200)

local LemonToggleBtn = Instance.new("TextButton", SubMenuFrame)
LemonToggleBtn.Size = UDim2.new(1, -6, 0, 28)
LemonToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 20)
LemonToggleBtn.Text = "🍋 Лемончик: ВКЛ"
LemonToggleBtn.TextColor3 = Color3.fromRGB(255, 240, 100)
LemonToggleBtn.TextSize = 10
LemonToggleBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", LemonToggleBtn).CornerRadius = UDim.new(0, 6)
local LemonStroke = Instance.new("UIStroke", LemonToggleBtn)
LemonStroke.Thickness = 1
LemonStroke.Color = Color3.fromRGB(200, 190, 60)

local LanguageBtn = Instance.new("TextButton", SubMenuFrame)
LanguageBtn.Size = UDim2.new(1, -6, 0, 28)
LanguageBtn.BackgroundColor3 = Color3.fromRGB(35, 36, 48)
LanguageBtn.Text = "🌐 Язык: RU"
LanguageBtn.TextColor3 = Color3.fromRGB(230, 210, 130)
LanguageBtn.TextSize = 10
LanguageBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", LanguageBtn).CornerRadius = UDim.new(0, 6)
local LanguageStroke = Instance.new("UIStroke", LanguageBtn)
LanguageStroke.Thickness = 1
LanguageStroke.Color = Color3.fromRGB(180, 160, 80)

local UnloadBtn = Instance.new("TextButton", SubMenuFrame)
UnloadBtn.Size = UDim2.new(1, -6, 0, 28)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 22)
UnloadBtn.Text = "⛔ Удалить скрипт"
UnloadBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
UnloadBtn.TextSize = 10
UnloadBtn.Font = Enum.Font.FredokaOne
Instance.new("UICorner", UnloadBtn).CornerRadius = UDim.new(0, 6)
local UnloadStroke = Instance.new("UIStroke", UnloadBtn)
UnloadStroke.Thickness = 1
UnloadStroke.Color = Color3.fromRGB(200, 70, 70)

local function showUnloadConfirmation()
    local confirmOverlay = Instance.new("Frame", ScreenGui)
    confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
    confirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    confirmOverlay.BackgroundTransparency = 0.5
    confirmOverlay.ZIndex = 1000

    local confirmBox = Instance.new("Frame", confirmOverlay)
    confirmBox.Size = UDim2.new(0, 260, 0, 130)
    confirmBox.Position = UDim2.new(0.5, -130, 0.5, -65)
    confirmBox.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
    Instance.new("UICorner", confirmBox).CornerRadius = UDim.new(0, 10)

    local warnText = Instance.new("TextLabel", confirmBox)
    warnText.Size = UDim2.new(1, -20, 0, 55)
    warnText.Position = UDim2.new(0, 10, 0, 10)
    warnText.Text = currentLanguage == "RU" and "Вы уверены?\nЕсли вы выключите скрипт, бот отключится!" or "Are you sure?\nIf you turn off the script, the bot will stop!"
    warnText.TextColor3 = Color3.fromRGB(255, 200, 100)
    warnText.Font = Enum.Font.FredokaOne
    warnText.TextSize = 11
    warnText.TextWrapped = true
    warnText.BackgroundTransparency = 1

    local yesBtn = Instance.new("TextButton", confirmBox)
    yesBtn.Size = UDim2.new(0.4, 0, 0, 30)
    yesBtn.Position = UDim2.new(0.08, 0, 0.62, 0)
    yesBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    yesBtn.Text = currentLanguage == "RU" and "Да" or "Yes"
    yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    yesBtn.Font = Enum.Font.FredokaOne
    Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 6)

    local noBtn = Instance.new("TextButton", confirmBox)
    noBtn.Size = UDim2.new(0.4, 0, 0, 30)
    noBtn.Position = UDim2.new(0.52, 0, 0.62, 0)
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

local menuOpen = false
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

MenuToggleBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        SubMenuFrame.Visible = true
        TweenService:Create(SubMenuFrame, tweenInfo, {Size = UDim2.new(0, 165, 0, 130)}):Play()
        TweenService:Create(MenuToggleBtn, tweenInfo, {Rotation = 90}):Play()
    else
        local tween = TweenService:Create(SubMenuFrame, tweenInfo, {Size = UDim2.new(0, 165, 0, 0)})
        tween:Play()
        tween.Completed:Connect(function()
            if not menuOpen then SubMenuFrame.Visible = false end
        end)
        TweenService:Create(MenuToggleBtn, tweenInfo, {Rotation = 0}):Play()
    end
end)

local function updateUIState(active)
    if active then
        ToggleButton.Text = "✓"
        ToggleButton.TextColor3 = Color3.fromRGB(60, 255, 120)
        TweenService:Create(BtnStroke, tweenInfo, {Color = Color3.fromRGB(60, 255, 120)}):Play()
    else
        ToggleButton.Text = "X"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 75, 75)
        TweenService:Create(BtnStroke, tweenInfo, {Color = Color3.fromRGB(60, 65, 80)}):Play()
    end
end

local function updateSpawnBtnState(enabled)
    if enabled then
        SpawnToggleBtn.Text = currentLanguage == "RU" and "🏠 Спавн: ВКЛ" or "🏠 Spawn: ON"
        SpawnToggleBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
        TweenService:Create(SpawnToggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(25, 38, 55)}):Play()
        TweenService:Create(SpawnStroke, tweenInfo, {Color = Color3.fromRGB(60, 140, 220)}):Play()
    else
        SpawnToggleBtn.Text = currentLanguage == "RU" and "🏠 Спавн: ВЫКЛ" or "🏠 Spawn: OFF"
        SpawnToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        TweenService:Create(SpawnToggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(30, 32, 40)}):Play()
        TweenService:Create(SpawnStroke, tweenInfo, {Color = Color3.fromRGB(80, 80, 95)}):Play()
    end
end

local function updateLemonBtnState(enabled)
    if enabled then
        LemonToggleBtn.Text = currentLanguage == "RU" and "🍋 Лемончик: ВКЛ" or "🍋 Lemonchik: ON"
        LemonToggleBtn.TextColor3 = Color3.fromRGB(255, 240, 100)
        TweenService:Create(LemonToggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(45, 45, 20)}):Play()
        TweenService:Create(LemonStroke, tweenInfo, {Color = Color3.fromRGB(200, 190, 60)}):Play()
    else
        LemonToggleBtn.Text = currentLanguage == "RU" and "🍋 Лемончик: ВЫКЛ" or "🍋 Lemonchik: OFF"
        LemonToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        TweenService:Create(LemonToggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(30, 32, 40)}):Play()
        TweenService:Create(LemonStroke, tweenInfo, {Color = Color3.fromRGB(80, 80, 95)}):Play()
    end
end

local dragging = false
local dragMoved = false
local dragStart, startPos, menuStartPos, subMenuStartPos

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragMoved = false; dragStart = input.Position
        startPos = ToggleButton.Position; menuStartPos = MenuToggleBtn.Position
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

ToggleButton.MouseButton1Click:Connect(function()
    if not dragMoved then
        botActive = not botActive
        updateUIState(botActive)
        if not botActive then 
            followingPlayer = nil 
            waitingForQuestion = false
            questionUser = nil
            isSelfSitting = false
        end
    end
end)

SpawnToggleBtn.MouseButton1Click:Connect(function()
    returnToSpawnActive = not returnToSpawnActive
    updateSpawnBtnState(returnToSpawnActive)
end)

LemonToggleBtn.MouseButton1Click:Connect(function()
    lemonchikActive = not lemonchikActive
    updateLemonBtnState(lemonchikActive)
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

LanguageBtn.MouseButton1Click:Connect(function()
    if currentLanguage == "RU" then
        currentLanguage = "EN"
        LanguageBtn.Text = "🌐 Language: EN"
        LanguageBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
        LanguageStroke.Color = Color3.fromRGB(80, 160, 220)
        SetSpawnBtn.Text = "📍 Set Spawn Point"
        UnloadBtn.Text = "⛔ Delete Script"
    else
        currentLanguage = "RU"
        LanguageBtn.Text = "🌐 Язык: RU"
        LanguageBtn.TextColor3 = Color3.fromRGB(230, 210, 130)
        LanguageStroke.Color = Color3.fromRGB(180, 160, 80)
        SetSpawnBtn.Text = "📍 Задать спавн"
        UnloadBtn.Text = "⛔ Удалить скрипт"
    end
    updateSpawnBtnState(returnToSpawnActive)
    updateLemonBtnState(lemonchikActive)
end)

UnloadBtn.MouseButton1Click:Connect(function() showUnloadConfirmation() end)

-- ИСПРАВЛЕННЫЙ ANTI-SIT (НЕ МЕШАЕТ БОТУ СИДЕТЬ САМОМУ!)
local function bindAntiSeat(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
        -- Если бот сам решил сесть (isSelfSitting = true), Anti-Sit ИГНОРИРУЕТ это!
        if botActive and humanoid.Sit and not isSelfSitting then
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
-- ЗАПУСК ЖУТКОГО МОНОЛОГА С ТРЯСКОЙ
-- ==========================================
local function triggerCreepyMonologue(senderPlayer)
    isCreepyMonologueActive = true
    followingPlayer = nil
    waitingForQuestion = false
    questionUser = nil
    isSelfSitting = false

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local dict = Translations[currentLanguage]

    safeSpawn(function()
        for _, line in ipairs(dict.creepyMonologue) do
            if not botActive then break end
            
            local tHrp = nil
            if senderPlayer and senderPlayer.Character then
                tHrp = senderPlayer.Character:FindFirstChild("HumanoidRootPart")
            end

            for s = 1, 6 do
                if hrp and tHrp then
                    local baseCF = CFrame.lookAt(hrp.Position, Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z))
                    local offsetAngle = (s % 2 == 0 and math.rad(10) or math.rad(-10))
                    hrp.CFrame = baseCF * CFrame.Angles(0, offsetAngle, 0)
                end
                safeWait(0.08)
            end

            sayMessage(line)
            safeWait(2.5)
        end
        isCreepyMonologueActive = false
    end)
end

-- ==========================================
-- ОБРАБОТКА ЧАТА
-- ==========================================
local function processChatMessage(senderPlayer, msg)
    if not botActive or isCreepyMonologueActive or senderPlayer == LocalPlayer then return end
    
    if waitingForQuestion and tick() - questionTimeout > 15 then
        waitingForQuestion = false
        questionUser = nil
    end

    local cleanMsg = cleanText(msg)
    local senderChar = senderPlayer.Character
    local char = LocalPlayer.Character
    if not senderChar or not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local senderHrp = senderChar:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not senderHrp then return end

    local dist = (senderHrp.Position - hrp.Position).Magnitude
    local dict = Translations[currentLanguage]

    if waitingForQuestion then
        if senderPlayer == questionUser then
            if dist <= 60 then
                lastResponseTime = tick()
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
                
                local isYes = (math.random(1, 2) == 1)
                if isYes then
                    if hum then hum.Jump = true end
                else
                    safeSpawn(function()
                        local tPos = Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z)
                        local baseCF = CFrame.lookAt(hrp.Position, tPos)
                        for i = 1, 3 do
                            if hrp then hrp.CFrame = baseCF * CFrame.Angles(0, math.rad(30), 0) end
                            safeWait(0.1)
                            if hrp then hrp.CFrame = baseCF * CFrame.Angles(0, math.rad(-30), 0) end
                            safeWait(0.1)
                        end
                        if hrp then hrp.CFrame = baseCF end
                    end)
                end
            end
            waitingForQuestion = false
            questionUser = nil
            return
        else
            if cleanMsg:find("ответь") or cleanMsg:find("вопрос") or cleanMsg:find("ask") or cleanMsg:find("question") then
                if dist <= 60 then
                    sayMessage(dict.waitOther)
                end
                return
            end
        end
    end

    if tick() - lastResponseTime < 2 then return end

    if cleanMsg:find("ответь на вопрос") or cleanMsg:find("ответь") or cleanMsg:find("answer my question") or cleanMsg:find("ask question") then
        if dist <= 60 then
            lastResponseTime = tick()
            questionUser = senderPlayer
            waitingForQuestion = true
            questionTimeout = tick()

            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
            sayMessage("?")
        end

    elseif isGreeting(cleanMsg) and dist <= 50 then
        lastResponseTime = tick()
        sayMessage(dict.greetings[math.random(#dict.greetings)])

    elseif cleanMsg:find("оцени") or cleanMsg:find("rate") then
        if dist <= 60 then
            lastResponseTime = tick()
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(senderHrp.Position.X, hrp.Position.Y, senderHrp.Position.Z))
            sayMessage(dict.evaluation[math.random(#dict.evaluation)])
        end

    -- ШАНС ПАСХАЛКИ ПОДНЯТ ДО 10%! (1 из 10 срабатываний)
    elseif cleanMsg:find("команды") or cleanMsg:find("commands") or cleanMsg:find("help") or cleanMsg:find("помощь") then
        if dist <= 60 then
            lastResponseTime = tick()
            
            if math.random(1, 10) == 1 then
                triggerCreepyMonologue(senderPlayer)
            else
                sayMessage(dict.tips[math.random(#dict.tips)])
            end
        end

    elseif cleanMsg:find("ты бот") or cleanMsg:find("ты ботик") or cleanMsg:find("you bot") or cleanMsg:find("are you a bot") then
        lastResponseTime = tick()
        sayMessage(dict.botIdentity[math.random(#dict.botIdentity)])

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

    elseif cleanMsg:find("хватит") or cleanMsg:find("stop") or cleanMsg:find("стоп") or cleanMsg:find("не иди") then
        if followingPlayer == senderPlayer then
            lastResponseTime = tick()
            followingPlayer = nil
            sayMessage(dict.stopOk)
        end

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
    print("[BOT]: Поток ИИ запущен!")
    while true do
        safeWait(0.2)

        if botActive and not isCreepyMonologueActive then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hum and hrp and hum.Health > 0 then

                if lemonchikActive then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Name == "denchik_gjfjc" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local sisterHrp = p.Character.HumanoidRootPart
                            local distToSister = (sisterHrp.Position - hrp.Position).Magnitude
                            if distToSister <= 15 then
                                -- Задел под скетч
                            end
                        end
                    end
                end

                local dict = Translations[currentLanguage]

                -- 0. ДЕТЕКТОР ВЗГЛЯДА (<= 6 студов + 8 секунд)
                local nearChar, nearPlayer = getNearestPlayer(0, 6)
                if nearChar and nearChar:FindFirstChild("HumanoidRootPart") then
                    local tHrp = nearChar.HumanoidRootPart
                    local dirToBot = (hrp.Position - tHrp.Position)

                    if dirToBot.Magnitude > 0.1 then
                        local unitDir = dirToBot.Unit
                        local lookVector = tHrp.CFrame.LookVector

                        if unitDir:Dot(lookVector) > 0.75 then
                            if staringPlayer == nearPlayer then
                                if tick() - stareStartTime >= 8 then
                                    local targetLookPos = Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z)
                                    for i = 1, 10 do
                                        if hrp and tHrp then
                                            hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(hrp.Position, targetLookPos), 0.25)
                                        end
                                        safeWait(0.03)
                                    end

                                    sayMessage(dict.stareBack[math.random(#dict.stareBack)])
                                    staringPlayer = nil
                                    stareStartTime = 0
                                end
                            else
                                staringPlayer = nearPlayer
                                stareStartTime = tick()
                            end
                        else
                            if staringPlayer == nearPlayer then
                                staringPlayer = nil
                                stareStartTime = 0
                            end
                        end
                    end
                else
                    staringPlayer = nil
                    stareStartTime = 0
                end

                local threatPos, isFront = checkCartThreat(hrp)

                -- 1. Побег от тележки
                if threatPos ~= nil then
                    isSelfSitting = false
                    hum.WalkSpeed = 32
                    local escapeTarget = isFront and (hrp.Position - (hrp.CFrame.LookVector * 28)) or (hrp.Position + (hrp.CFrame.LookVector * 28))
                    hum:MoveTo(escapeTarget)
                    sayMessage(dict.cartEscape[math.random(#dict.cartEscape)])
                    if math.random(1, 2) == 1 then hum.Jump = true end
                    safeWait(1.2)
                    hum.WalkSpeed = 16

                -- 2. Ожидание вопроса
                elseif waitingForQuestion then
                    isSelfSitting = false
                    if questionUser and questionUser.Character then
                        local tHrp = questionUser.Character:FindFirstChild("HumanoidRootPart")
                        if tHrp and hrp then
                            local lookPos = Vector3.new(tHrp.Position.X, hrp.Position.Y, tHrp.Position.Z)
                            hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(hrp.Position, lookPos), 0.2)
                        end
                    end
                    safeWait(0.2)

                -- 3. Режим следования
                elseif followingPlayer then
                    isSelfSitting = false
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

                -- 4. Автономный режим
                else
                    local distFromSpawn = (hrp.Position - spawnPosition).Magnitude
                    local shouldReturnSpawn = returnToSpawnActive and (distFromSpawn > 120 or (math.random(1, 20) == 20 and distFromSpawn > 50))

                    if shouldReturnSpawn then
                        isSelfSitting = false
                        safeMoveTo(spawnPosition + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6)))
                        if math.random(1, 2) == 1 then
                            sayMessage(dict.spawnReturn[math.random(#dict.spawnReturn)])
                        end
                        safeWait(math.random(3, 6))
                    else
                        local actionChance = math.random(1, 10)

                        -- Шанс 1 из 10 — Бот присаживается отдохнуть на землю
                        if actionChance == 1 then
                            isSelfSitting = true -- Отключаем Anti-Sit
                            hum.Sit = true
                            
                            local sitDuration = math.random(5, 10)
                            local sitStart = tick()

                            while tick() - sitStart < sitDuration and botActive and not followingPlayer and not waitingForQuestion do
                                safeWait(0.5)
                            end

                            if hum then
                                hum.Sit = false
                                safeWait(0.1)
                                hum.Jump = true
                            end
                            isSelfSitting = false -- Включаем Anti-Sit обратно
                            safeWait(1)

                        elseif actionChance <= 3 then
                            isSelfSitting = false
                            local targetChar = getNearestPlayer(12, 55)
                            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and not staringPlayer then
                                local tHrp = targetChar.HumanoidRootPart
                                local observeStart = tick()

                                while tick() - observeStart < 8 and botActive and not followingPlayer and not staringPlayer and not waitingForQuestion do
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

                        elseif actionChance == 4 then
                            isSelfSitting = false
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

                        elseif actionChance <= 7 then
                            isSelfSitting = false
                            safeMoveTo(hrp.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
                            safeWait(math.random(3, 7))

                        elseif actionChance <= 9 then
                            isSelfSitting = false
                            safeWait(math.random(4, 8))

                        else
                            isSelfSitting = false
                            useRandomItem()
                            safeWait(math.random(2, 4))
                        end
                    end
                end

                -- 5. Периодические случайные фразы
                if tick() - lastChatTime >= chatCooldown then
                    sayMessage(dict.randomPhrases[math.random(#dict.randomPhrases)])
                    lastChatTime = tick()
                    chatCooldown = math.random(12, 25)
                end

            end
        end
    end
end)

print("[BOT]: Скрипт готов! Теперь бот нормально садится, а шанс монолога 10%!")
