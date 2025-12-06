-- BeeSSshota Key Loader (через Telegram-бот/Render)
-- 1) Показывает окно ввода ключа
-- 2) Отправляет ключ на https://bee-key-bot.onrender.com/check?key=...
-- 3) Если ответ строго "OK" — загружает основной скрипт 1.0
-- 4) Кнопка "Получить ключ" копирует ссылку на Recut (переход к твоему боту)

local MAIN_SCRIPT_URL  = "https://raw.githubusercontent.com/igroman33igrok/BeeSSshota/refs/heads/main/1.0"
local CHECK_BASE_URL   = "https://bee-key-bot.onrender.com/check?key="

-- >>> СЮДА ВСТАВЬ СВОЮ ССЫЛКУ НА RECUT <<<
local KEY_LINK = "https://link-center.net/1457865/OjRav1ogUn9l"

local HttpService = game:GetService("HttpService")
local StarterGui  = game:GetService("StarterGui")
local UIS         = game:GetService("UserInputService")

-- ================== ХЕЛПЕРЫ ==================

local function httpGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        warn("[BeeSSshota] Ошибка загрузки: " .. tostring(res))
        return nil
    end
    return res
end

local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "BeeSSshota",
            Text  = msg,
            Duration = 4
        })
    end)
end

-- ================== UI ДЛЯ ВВОДА КЛЮЧА ==================

local parentGui
pcall(function()
    if gethui then
        parentGui = gethui()
    else
        parentGui = game:GetService("CoreGui")
    end
end)
parentGui = parentGui or game:GetService("CoreGui")

local old = parentGui:FindFirstChild("BeeSSshota_KeyUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "BeeSSshota_KeyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parentGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 190) -- было 150, увеличил высоту под вторую кнопку
frame.Position = UDim2.new(0.5, -130, 0.5, -95)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(220, 220, 255)
title.Text = "Ввод ключа"
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 30)
box.Position = UDim2.new(0, 10, 0, 50)
box.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
box.Font = Enum.Font.Gotham
box.PlaceholderText = "Вставь сюда ключ"
box.TextColor3 = Color3.fromRGB(230, 230, 255)
box.Text = ""
box.ClearTextOnFocus = false
box.Parent = frame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = box

local activateBtn = Instance.new("TextButton")
activateBtn.Size = UDim2.new(1, -20, 0, 30)
activateBtn.Position = UDim2.new(0, 10, 0, 95)
activateBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 200)
activateBtn.Font = Enum.Font.GothamBold
activateBtn.TextSize = 14
activateBtn.TextColor3 = Color3.fromRGB(240, 240, 255)
activateBtn.Text = "Активировать"
activateBtn.AutoButtonColor = true
activateBtn.Parent = frame

local activateBtnCorner = Instance.new("UICorner")
activateBtnCorner.CornerRadius = UDim.new(0, 6)
activateBtnCorner.Parent = activateBtn

-- Новая кнопка "Получить ключ"
local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Size = UDim2.new(1, -20, 0, 30)
getKeyBtn.Position = UDim2.new(0, 10, 0, 135)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 80)
getKeyBtn.Font = Enum.Font.GothamBold
getKeyBtn.TextSize = 14
getKeyBtn.TextColor3 = Color3.fromRGB(240, 240, 255)
getKeyBtn.Text = "Получить ключ"
getKeyBtn.AutoButtonColor = true
getKeyBtn.Parent = frame

local getKeyBtnCorner = Instance.new("UICorner")
getKeyBtnCorner.CornerRadius = UDim.new(0, 6)
getKeyBtnCorner.Parent = getKeyBtn

-- Перетаскивание окна
local dragging = false
local dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging   = true
        dragStart  = input.Position
        startPos   = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ================== ПРОВЕРКА КЛЮЧА И ЗАПУСК 1.0 =========

local activated = false

local function tryActivate()
    if activated then return end

    local key = tostring(box.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then
        notify("Сначала введи ключ")
        return
    end

    notify("Проверяю ключ...")

    local url = CHECK_BASE_URL .. HttpService:UrlEncode(key)
    local resp = httpGet(url)
    if not resp then
        notify("Не удалось связаться с сервером. Попробуй ещё раз.")
        return
    end

    local clean = resp:gsub("%s+", ""):upper()
    if clean ~= "OK" then
        notify("Неверный или устаревший ключ")
        return
    end

    activated = true
    notify("Ключ принят. Загрузка BeeSSshota...")
    gui:Destroy()

    local code = httpGet(MAIN_SCRIPT_URL)
    if not code then
        notify("Ошибка загрузки основного скрипта :(")
        return
    end

    local fn, err = loadstring(code)
    if not fn then
        warn("[BeeSSshota] loadstring error: " .. tostring(err))
        notify("Ошибка выполнения скрипта.")
        return
    end

    fn()
end

activateBtn.MouseButton1Click:Connect(tryActivate)

box.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        tryActivate()
    end
end)

-- ================== КНОПКА "ПОЛУЧИТЬ КЛЮЧ" ==================

local function copyKeyLink()
    if not KEY_LINK or KEY_LINK == "" then
        notify("Ссылка для получения ключа не настроена.")
        return
    end

    if setclipboard then
        setclipboard(KEY_LINK)
        notify("Ссылка скопирована в буфер обмена")
    else
        notify("Ваш эксплойт не поддерживает копирование.\nСсылка:\n" .. KEY_LINK)
    end
end

getKeyBtn.MouseButton1Click:Connect(copyKeyLink)
