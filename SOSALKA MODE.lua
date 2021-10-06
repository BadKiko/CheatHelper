script_name("SOSALKA MOD")
script_author("Kiko")

local sampev = require("lib.samp.events")
local imgui = require("imgui")
local encoding = require("encoding")
local sw, sh = getScreenResolution()

local speed = imgui.ImFloat(0.07)
local radius = imgui.ImFloat(100)
local jumpCooldown = imgui.ImInt(150)
local tppos = imgui.ImFloat(2.5)
local chaseTheVictim = imgui.ImBool(true) -- Преследовать жертву если машина не будет найдена
local tpToNearCars = imgui.ImBool(false)


encoding.default = "CP1251"
u8 = encoding.UTF8

local x, y, z
local sx, sy, sz
local nowX, nowY, nowZ
local distanceX, distanceY
local playerId
local mainCar, mainPed
local runEnd = false
local touched = false
local touchedint = 0

local menu_window_state = imgui.ImBool(false) -- статус main окна

local runt

function main()
    repeat wait(1500) until isSampAvailable()
    sendMessage("Created {464446}by{EA5455} Kiko {464446}base {EA5455}S E V E N")
    sendMessage("{464446}Активация - {EA5455}/sosalka")
    sampRegisterChatCommand("sosalka", cmd)
    sampRegisterChatCommand("sosalka.menu", function()
        menu_window_state.v = not menu_window_state.v
        imgui.Process = menu_window_state.v
    end)

    while true do
        wait(0)
        -- прячем показываем курсор
        if menu_window_state.v == false then
            imgui.ShowCursor = false
        else
            imgui.ShowCursor = true
        end
    end
end

-- Рисуем меню
function imgui.OnDrawFrame()
    -- Main меню
    if menu_window_state.v then
        imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2),
                               imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin("[SosalkaMod] by Kiko", menu_window_state,
                    imgui.WindowFlags.AlwaysAutoResize)
        apply_custom_style()
        imgui.Text(u8 'Не вы сосете если что.')
        imgui.Separator()
        imgui.Text(u8 'Скорость перемещения тачки:')
        imgui.SameLine()
        imgui.SliderFloat('', speed, 0, 1)
        imgui.Separator()
        imgui.Text(u8 'Радиус действия:')
        imgui.SameLine()
        imgui.SliderFloat(' ', radius, 1, 1000)
        imgui.Separator()
        imgui.Text(u8 'Кулдаун между рванкой:')
        imgui.SameLine()
        imgui.SliderInt('  ', jumpCooldown, 0, 2000)
        imgui.Separator()
        imgui.Text(u8 'ТП расстояние от машины:')
        imgui.SameLine()
        imgui.SliderFloat('   ', tppos, 0, 5)
        imgui.Separator()
        imgui.Text(
            u8 'Преследовать жертву если машина не будет найдена:')
        imgui.SameLine()
        imgui.Checkbox('    ', chaseTheVictim)
        imgui.Separator()
        imgui.Text(
            u8 'Постоянное ТП к ближайшим авто:')
        imgui.SameLine()
        imgui.Checkbox('     ', tpToNearCars)
        imgui.End()
    end
end

function sampev.onSendUnoccupiedSync(data)
    if act then
        havePed, ped = sampGetCharHandleBySampPlayerId(playerId)
        if havePed then
            x, y, z = getCharCoordinates(ped)
            xc, yc, zc = getCharCoordinates(playerPed)
            distanceX = x - xc
            distanceY = y - yc
            data.moveSpeed.x = distanceX * speed.v
            data.moveSpeed.y = distanceY * speed.v
            if runEnd then teleportOnCarSide(ped) end
            touchedint = touchedint + 1
            if touchedint == 4 then -- Если мы докасаемся 10 раз дом машины то колибровка выполнена
                touched = true
            end
            sx, sy, sz = getCharCoordinates(playerPed)
            printStringNow("~p~POSOSI", 100)
        end
    end
end

function cmd(pId)
    if pId ~= '' then
        playerId = pId
        act = not act
        sampAddChatMessage(act and
                               "{464446}[Sosalka{EA5455}Mod{464446}]: {EA5455}Включена." or
                               "{464446}[Sosalka{EA5455}Mod{464446}]: {EA5455}Отключена",
                           -1)
        if act then
            teleportToNext()
        else
            runEnd = false
            touched = false
            touchedint = 0
        end
    else
        sendMessage("Укажите ид игрока")
    end
end

function sendMessage(text)
    tag = '{464446}[Sosalka{EA5455}Mod{464446}]: {EA5455}'
    sampAddChatMessage(tag .. text, -1)
end

function teleportToNext() -- Телепорт к следующей машине
    havePed, ped = sampGetCharHandleBySampPlayerId(playerId)
    if havePed then
        mainPed = ped
        mainCar = findCar()
        searchCar()
        x, y, z = getCharCoordinates(ped)
        result = isCharInAnyCar(ped)
        if mainCar ~= -1 then
            carX, carY, carZ = getCarCoordinates(mainCar)
            setCarHeading(mainCar, 180)
            setCharHeading(playerPed, 90)
            setCharCoordinates(playerPed, carX + tppos.v, carY, carZ)
            runToPoint(carX, carY)
            distanceX = x - carX
            distanceY = y - carY
            drawCarLine()
        else
            if chaseTheVictim.v then -- Если машины нет, то телепортируемся за игроком, пока не найдем авто
                teleportToVictim(ped)
            else
                sendMessage(
                    "Машин возле игрока не найдено, увеличьте радиус. Остановка")
            end
        end
    else
        sendMessage("Чорт куда-то делся")
    end
end


function drawCarLine()
    lua_thread.create(function()
    for i = 0, 200 do
        if mainCar ~= -1 then
            i = i + 1
            x, y, z = getCharCoordinates(playerPed)
            carX, carY, carZ = getCarCoordinates(mainCar)
            local xw, yw = convert3DCoordsToScreen(x, y, z)
            local carXw, carYw = convert3DCoordsToScreen(carX, carY, carZ)

            renderDrawLine(xw, yw, carXw, carYw, 2, 0xFFE33939) -- непрозрачный красный цвет
            wait(0)
        end
    end
end)
end

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 8
    style.FramePadding = imgui.ImVec2(5, 5)
    style.FrameRounding = 8
    style.ItemSpacing = imgui.ImVec2(7, 5)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21.0
    style.ScrollbarSize = 14.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 20.0
    style.GrabRounding = 15.0

    colors[clr.Text] = ImVec4(0.92, 0.33, 0.33, 1.00)
    colors[clr.TextDisabled] = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg] = ImVec4(0.06, 0.06, 0.06, 1)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border] = ImVec4(0.92, 0.33, 0.33, 0.38)
    colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg] = ImVec4(0.20, 0.20, 0.20, 0.54)
    colors[clr.FrameBgHovered] = ImVec4(0.17, 0.17, 0.17, 0.54)
    colors[clr.FrameBgActive] = ImVec4(0.24, 0.24, 0.24, 0.67)
    colors[clr.TitleBg] = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive] = ImVec4(0.07, 0.07, 0.07, 1.00)
    colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.MenuBarBg] = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab] = ImVec4(0.16, 0.16, 0.16, 0.86)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.22, 0.22, 0.22, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.29, 0.29, 0.29, 1.00)
    colors[clr.CheckMark] = ImVec4(0.92, 0.33, 0.33, 1.00)
    colors[clr.SliderGrab] = ImVec4(0.92, 0.33, 0.33, 1.00)
    colors[clr.SliderGrabActive] = ImVec4(0.2, 0.2, 0.2, 1.00)
    colors[clr.Button] = ImVec4(0.37, 0.37, 0.37, 0.27)
    colors[clr.ButtonHovered] = ImVec4(0.16, 0.16, 0.16, 0.54)
    colors[clr.ButtonActive] = ImVec4(0.20, 0.20, 0.20, 0.54)
    colors[clr.Header] = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.HeaderHovered] = ImVec4(0.17, 0.17, 0.17, 0.45)
    colors[clr.HeaderActive] = ImVec4(0.23, 0.23, 0.23, 0.41)
    colors[clr.Separator] = ImVec4(0.29, 0.29, 0.29, 0.50)
    colors[clr.SeparatorHovered] = ImVec4(0.29, 0.29, 0.29, 0.50)
    colors[clr.SeparatorActive] = ImVec4(0.29, 0.29, 0.29, 0.50)
    colors[clr.ResizeGrip] = ImVec4(0.92, 0.33, 0.33, 1.00)
    colors[clr.ResizeGripHovered] = ImVec4(0.92, 0.33, 0.33, 1.00)
    colors[clr.ResizeGripActive] = ImVec4(0.92, 0.33, 0.33, 1.00)
    colors[clr.PlotLines] = ImVec4(0.25, 0.25, 0.25, 1.00)
    colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)

end

function runToPoint(tox, toy)
    lua_thread.create(function()
        if act then
            local x, y, z = getCharCoordinates(PLAYER_PED)
            local angle = getHeadingFromVector2d(tox - x, toy - y)
            setCameraPositionUnfixed(0, 0)
            stopRun = false
            while touched == false do
                setGameKeyState(1, -255)
                -- setGameKeyState(16, 1)
                wait(0)
                x, y, z = getCharCoordinates(PLAYER_PED)
                angle = getHeadingFromVector2d(tox - x, toy - y)
                setCameraPositionUnfixed(0, 0)
                if stopRun then
                    stopRun = false
                    break
                end
            end
            sx, sy, sz = getCharCoordinates(playerPed)
            runEnd = true
            teleportOnCarSide(ped)
        end
    end)
end

function teleportOnCarSide(ped)
        if mainCar ~= -1 then
            setCarHeading(mainCar, 180)
            setCharHeading(playerPed, 90)
            carX, carY, carZ = getCarCoordinates(mainCar)
            setCharCoordinates(playerPed, sx, sy, carZ)
        end
end

function teleportToVictim(ped)
    local teleportToVC = lua_thread.create(function()
        while mainCar == -1 do
            wait(500)
            x, y, z = getCharCoordinates(ped)
            setCharCoordinates(playerPed, x, y, z)
        end
        teleportToNext()
    end)
end

function searchCar()
if tpToNearCars.v then
local t = lua_thread.create(function()
    while act do
        local car
        car = mainCar
        wait(2000)
        mainCar = findCar()
        if car ~= mainCar then
            runEnd = false
            touched = false
            touchedint = 0
            teleportToNext()
        end
    end
end)
end
end

function findCar()
    vehicles = getAllVehicles() -- Загружаем весь транспорт
    local selectedCar

    local carHadlesTable = {}
    local carDistanceTable = {}

    for _, currentCar in pairs(vehicles) do -- Проходимся по каждой машине
        if doesVehicleExist(currentCar) then --Если авто есть в зоне стрима идем дальше
            if isCarPassengerSeatFree(currentCar, 0) and isCharInCar(mainPed, currentCar) == false then --Не сидит ли в этом авто никто
                px, py, pz = getCharCoordinates(mainPed) --Координаты жертвы
                ccX, ccY, ccZ = getCarCoordinates(currentCar) --Координаты машины в цикле
                if isLineOfSightClear(ccX, ccY, ccZ, px, py, pz, true, false, false, true, false) then -- Проверка на то сможет ли машина зарванить игрока
                    distance = getDistanceBetweenCoords2d(px, py, ccX, ccY) --Получаем дистанцию
                    if distance < 150 then
                        table.insert(carDistanceTable, distance)
                        table.insert(carHadlesTable, currentCar)
                    end
                end
            end
        end
    end
    
    if (table.maxn(carHadlesTable)) > 0 then
        bubblesort(carDistanceTable, carHadlesTable)
        selectedCar = carHadlesTable[1] --Выбираем наилучший тс
    else
        selectedCar = -1
    end

    return selectedCar

end

--- Первый bubblesort что нашел в гугле)
function swap(a, b, table, table2)

    if table[a] == nil or table[b] == nil then
        return false
    end

    if table[a] > table[b] then
        table[a], table[b] = table[b], table[a]
        table2[a], table2[b] = table2[b], table2[a]
        return true
    end

    return false

end


function bubblesort(array, array2)

    for i=1,table.maxn(array) do

        local ci = i
        ::redo::
        if swap(ci, ci+1, array, array2) then
            ci = ci - 1
            goto redo
        end
    end
end