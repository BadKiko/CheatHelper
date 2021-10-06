local ev = require('lib.samp.events')
local imgui = require('imgui')
local encoding = require('encoding')
local rkeys = require('rkeys')
local vk = require('vkeys')
local inicfg = require('inicfg')

imgui.HotKey = require('imgui_addons').HotKey

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local menu = imgui.ImBool(false)
local lastMenu = menu.v

local tabSize = imgui.ImVec2(100, 20)
local selectedTab = 1

local frontX, frontY, frontZ, camX, camY, camZ = 0, 0, 0, 0, 0, 0

local shootingAtMe = -1

local attackKey = {
	v = {vk.VK_Z}
}

local settings = {
    search = {
        canSee = imgui.ImBool(false),
        needKey = imgui.ImBool(false),
        radius = imgui.ImFloat(1000),
        ignoreCars = imgui.ImBool(true),
        searchMethod = imgui.ImInt(0),
        useWeaponRadius = imgui.ImBool(true)
    },
    render = {
        line = imgui.ImBool(true),
        circle = imgui.ImBool(true),
        printString = imgui.ImBool(true)
    },
    shoot = {
        misses = imgui.ImBool(true),
        shotsPerMiss = imgui.ImInt(3),
        removeAmmo = imgui.ImBool(true)
    }
}

local state = false
local canShoot = true
local targetId = 0

local miss = false
local toMiss = 0

local cRadius = 0
local cMaxRadius = 1
local cInvert = false

math.randomseed(os.time())

function main()
    repeat wait(0) until isSampAvailable()
    loadSettings()
    sampRegisterChatCommand('damager.menu', function() 
        menu.v = not menu.v
    end)
    sampRegisterChatCommand('damager', function() 
        state = not state
        shootingAtMe = -1
        sendMessage(state and 'Включен' or 'Выключен')
        if state then
            lua_thread.create(function() 
                while state do
                    wait(50)
                    sendData()
                end
            end)
            lua_thread.create(function() 
                while state do
                    wait(0)
                    local ped = findPlayer()
                    if ped ~= nil then
                        local _, id = sampGetPlayerIdByCharHandle(ped)
                        if _ then
                            targetId = id
                            local mx, my, mz = getCharCoordinates(PLAYER_PED)
                            local x, y, z = getCharCoordinates(ped)

                            local mxw, myw = convert3DCoordsToScreen(mx, my, mz)
                            local xw, yw = convert3DCoordsToScreen(x, y, z)

                            if settings.render.line.v and isPointOnScreen(x, y, z, 1) then
                                renderDrawLine(mxw, myw, xw, yw, 3, (settings.search.needKey.v and isKeyDown(attackKey.v[1]) or not settings.search.needKey.v) and 0xAA6EFB6E or 0xAAAEAEAE)
                            end
                            if settings.render.circle.v then
                                Draw3DCircle(x, y, z, cRadius, (settings.search.needKey.v and isKeyDown(attackKey.v[1]) or not settings.search.needKey.v) and 0xAA6EFB6E or 0xAAAEAEAE)
                            end
                        end
                    else
                        targetId = -1
                    end
                end
            end)
            lua_thread.create(function() 
                while state do
                    wait(10)
                    if cInvert then
                        cRadius = cRadius - 0.01
                        if cRadius <= 0.15 then
                            cInvert = false
                        end
                    else
                        cRadius = cRadius + 0.01
                        if cRadius >= cMaxRadius then
                            cInvert = true
                        end
                    end
                end
            end)
        end
    end)
    while true do
        wait(0)
        --printStringNow(getAmmoInCharWeapon(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED)), 500)
        imgui.Process = menu.v
        if lastMenu ~= menu.v then
            saveSettings()
        end
        lastMenu = menu.v
    end
end

function loadSettings()
    local ini = inicfg.load(nil, 'DammagerByMrCreepTon')
    if ini == nil then
        saveSettings()
    else
        settings.search.canSee.v = ini.search.canSee
        settings.search.needKey.v = ini.search.needKey
        attackKey.v[1] = ini.search.key
        settings.search.radius.v = ini.search.radius
        settings.search.ignoreCars.v = ini.search.ignoreCars
        settings.search.searchMethod.v = ini.search.searchMethod
        settings.search.useWeaponRadius.v = ini.search.useWeaponRadius

        settings.render.line.v = ini.render.line
        settings.render.circle.v = ini.render.circle
        settings.render.printString.v = ini.render.printString

        settings.shoot.misses.v = ini.shoot.misses
        settings.shoot.shotsPerMiss.v = ini.shoot.shotsPerMiss
        settings.shoot.removeAmmo.v = ini.shoot.removeAmmo
    end
end

function saveSettings()
    inicfg.save({
        search = {
            canSee = settings.search.canSee.v,
            needKey = settings.search.needKey.v,
            key = attackKey.v[1],
            radius = settings.search.radius.v,
            ignoreCars = settings.search.ignoreCars.v,
            searchMethod = settings.search.searchMethod.v,
            useWeaponRadius = settings.search.useWeaponRadius.v
        },
        render = {
            line = settings.render.line.v,
            circle = settings.render.circle.v,
            printString = settings.render.printString.v
        },
        shoot = {
            misses = settings.shoot.misses.v,
            shotsPerMiss = settings.shoot.shotsPerMiss.v,
            removeAmmo = settings.shoot.removeAmmo.v
        }
    }, 'damager')
end

function findPlayer()
    local peds = getAllChars()
    local selectedPed = nil
    local v = 1000000
    for k, ped in pairs(peds) do
        if ped ~= PLAYER_PED and (settings.search.canSee.v and isCharOnScreen(ped) or not settings.search.canSee.v) and not isCharDead(ped) then
            local _, id = sampGetPlayerIdByCharHandle(ped)
            if _ and not sampIsPlayerPaused(id) then
                local cHp = sampGetPlayerHealth(id) + sampGetPlayerArmor(id)
                local x, y, z = getCharCoordinates(ped)
                local mx, my, mz = getCharCoordinates(PLAYER_PED)
                local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                if isLineOfSightClear(mx, my, mz, x, y, z, true, not settings.search.ignoreCars.v, false, true, false) and getDistanceBetweenCoords3d(mx, my, mz, x, y, z) < ((settings.search.useWeaponRadius.v and weapon ~= nil and weapon.distance) or settings.search.radius.v) then
                    if settings.search.searchMethod.v == 0 then
                        if cHp < v then
                            v = cHp
                            selectedPed = ped
                        end
                    elseif settings.search.searchMethod.v == 1 then
                        if getDistanceBetweenCoords3d(mx, my, mz, x, y, z) < v then
                            v = getDistanceBetweenCoords3d(mx, my, mz, x, y, z)
                            selectedPed = ped
                        end
                    elseif settings.search.searchMethod.v == 2 then
                        if shootingAtMe == id then
                            --shootingAtMe = -1
                            selectedPed = ped
                            break
                        else
                            if getDistanceBetweenCoords3d(mx, my, mz, x, y, z) < v then
                                v = getDistanceBetweenCoords3d(mx, my, mz, x, y, z)
                                selectedPed = ped
                            end
                        end
                    end
                end
            end
        end
    end
    return selectedPed
end

function imgui.OnDrawFrame()
    if menu.v then
        local xw, yw = getScreenResolution()
        imgui.SetNextWindowSize(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2(xw / 2, yw / 2), imgui.Cond.FirstUseEver)
        imgui.Begin('Damager', menu, imgui.WindowFlags.NoResize)
        imgui.BeginChild('##tabs', imgui.ImVec2(-1, 20))
        if imgui.ButtonActivated(selectedTab == 1, u8'Поиск цели', tabSize) then
            selectedTab = 1
        end
        imgui.SameLine()
        if imgui.ButtonActivated(selectedTab == 2, u8'Отображение', tabSize) then
            selectedTab = 2
        end
        imgui.SameLine()
        if imgui.ButtonActivated(selectedTab == 3, u8'Стрельба', tabSize) then
            selectedTab = 3
        end
        imgui.EndChild()
        imgui.Separator()
        imgui.BeginChild('##options', imgui.ImVec2(-1, -1))
        if selectedTab == 1 then
            imgui.Combo(u8'Приоритет поиска цели', settings.search.searchMethod, {u8'С наименьшим здоровьем', u8'По приближенности к Вам', u8'Атакуемый Вас'})
            imgui.Separator()
            imgui.Checkbox(u8'Игнорировать автомобили', settings.search.ignoreCars)
            imgui.Separator()
            imgui.Checkbox(u8'Необходимо зажать клавишу для работы', settings.search.needKey)
            if settings.search.needKey.v then
                imgui.HotKey('##activateKey', attackKey)
                imgui.SameLine()
                imgui.Text(u8'Клавиша активации')
            end
            imgui.Checkbox(u8'Цель должна быть на экране', settings.search.canSee)
            imgui.Separator()
            imgui.Checkbox(u8'Использовать в качестве радиуса максимальную дистанцию оружия', settings.search.useWeaponRadius)
            if not settings.search.useWeaponRadius.v then
                imgui.SliderFloat(u8'Радиус поиска цели', settings.search.radius, 1, 50)
            end
        end
        if selectedTab == 2 then
            imgui.Checkbox(u8'Отображать линию к цели', settings.render.line)
            imgui.Checkbox(u8'Отображать окружность вокруг цели', settings.render.circle)
            imgui.Checkbox(u8'Писать снизу об атакуемой цели', settings.render.printString)
        end
        if selectedTab == 3 then
            imgui.Checkbox(u8'Промахи', settings.shoot.misses)
            if settings.shoot.misses.v then
                imgui.PushItemWidth(200)
                imgui.SliderInt(u8'Количество выстрелов подряд без промахов', settings.shoot.shotsPerMiss, 1, 10)
                imgui.PopItemWidth()
            end
            imgui.Checkbox(u8'Отнимать патроны при выстреле', settings.shoot.removeAmmo)
        end
        imgui.EndChild()
        imgui.End()
    end
end

function imgui.ButtonActivated(activated, ...)
    if activated then
        imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.CheckMark])
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.GetStyle().Colors[imgui.Col.CheckMark])
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.GetStyle().Colors[imgui.Col.CheckMark])

            imgui.Button(...)

        imgui.PopStyleColor()
        imgui.PopStyleColor()
        imgui.PopStyleColor()

    else
        return imgui.Button(...)
    end
end

function sendData()
    if isCharOnFoot(PLAYER_PED) then
        sampForceOnfootSync()
        sampForceAimSync()
    end
end

local weapons = {
    {
        id = 22,
        delay = 160,
        dmg = 8.25,
        distance = 35,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 23,
        delay = 120,
        dmg = 13.2,
        distance = 35,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 24,
        delay = 800,
        dmg = 46.2,
        distance = 35,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 25,
        delay = 800,
        dmg = 3.3,
        distance = 40,
        camMode = 53,
        weaponState = 1
    },
    {
        id = 26,
        delay = 120,
        dmg = 3.3,
        distance = 35,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 27,
        delay = 120,
        dmg = 4.95,
        distance = 40,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 28,
        delay = 50,
        dmg = 6.6,
        distance = 35,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 29,
        delay = 90,
        dmg = 8.25,
        distance = 45,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 30,
        delay = 90,
        dmg = 9.9,
        distance = 70,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 31,
        delay = 90,
        dmg = 9.9,
        distance = 90,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 32,
        delay = 70,
        dmg = 6.6,
        distance = 35,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 33,
        delay = 800,
        dmg = 24.75,
        distance = 100,
        camMode = 53,
        weaponState = 1
    },
    {
        id = 34,
        delay = 900,
        dmg = 41.25,
        distance = 320,
        camMode = 7,
        weaponState = 1
    },
    {
        id = 38,
        delay = 20,
        dmg = 46.2,
        distance = 75,
        camMode = 53,
        weaponState = 2
    },
    
}

function getWeaponInfoById(id)
    for k, weapon in pairs(weapons) do
        if weapon.id == id then
            return weapon
        end
    end
    return nil
end

function rand()
    return math.random(-50, 50) / 100
end

function getMyId()
    return select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
end

function ev.onBulletSync(playerId, data)
    if data.targetId == getMyId() then
        shootingAtMe = playerId
    end
end

function ev.onSendTakeDamage(playerId, damage, weapon, bodypart)
    shootingAtMe = playerId
end

function ev.onSendPlayerSync(data)
    if state and (settings.search.needKey.v and isKeyDown(attackKey.v[1]) or not settings.search.needKey.v) then
        local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)
        if _ and res then
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local x, y, z = getCharCoordinates(ped)
            if isLineOfSightClear(x, y, z, mx, my, mz, true, false, false, true, false) then
                local b = 0 * math.pi / 360.0
                local h = 0 * math.pi / 360.0 
                local angle = getHeadingFromVector2d(x - mx, y - my)
                local a = angle * math.pi / 360.0

                local c1, c2, c3 = math.cos(h), math.cos(a), math.cos(b)
                local s1, s2, s3 = math.sin(h), math.sin(a), math.sin(b)
                
                data.quaternion[0] = c1 * c2 * c3 - s1 * s2 * s3
                data.quaternion[3] = -( c1 * s2 * c3 - s1 * c2 * s3 )

                data.keys.aim = 1

                if canShoot then
                    local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                    if weapon ~= nil then
                        data.keys.secondaryFire_shoot = 1
                        lua_thread.create(function() 
                            canShoot = false
                            if miss or not settings.shoot.misses.v then
                                miss = false
                            end
                            if toMiss >= settings.shoot.shotsPerMiss.v then
                                miss = true
                                toMiss = 0
                            end
                            if not miss and settings.shoot.misses.v then
                                toMiss = toMiss + 1
                            end
                            local sync = samp_create_sync_data('bullet')
                            if miss then
                                sync.targetType = 0
                                sync.targetId = 65535
                            else
                                sync.targetType = 1
                                sync.targetId = targetId
                            end
                            sync.center = {x = rand(), y = rand(), z = rand()}
                            sync.origin = {x = mx + rand(), y = my + rand(), z = mz + rand()}
                            sync.target = {x = x + rand(), y = y + rand(), z = z + rand()}
                            sync.weaponId = getCurrentCharWeapon(PLAYER_PED)
                            sync.send()
                            if settings.shoot.removeAmmo.v then
                                --[[local weaponId = getCurrentCharWeapon(PLAYER_PED)
                                local ammo = getAmmoInCharWeapon(PLAYER_PED, weaponId) - 1
                                removeWeaponFromChar(PLAYER_PED, weaponId)
                                giveWeaponToChar(PLAYER_PED, weaponId, ammo)]]
                                --setCharAmmo(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED), getAmmoInCharWeapon(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED)) - 1)
                                addAmmoToChar(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED), -1)
                            end
                            if not miss then
                                sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 3)
                            end
                            if settings.render.printString.v then
                                printStringNow(miss and 'Shot missed' or string.format('Player ~r~%d ~w~damaged', targetId), 500)
                            end
                            wait(weapon.delay)
                            canShoot = true
                        end)
                    end
                end
            end
        end
    end
end

function Draw3DCircle(x, y, z, radius, color)
    local screen_x_line_old, screen_y_line_old;

    for rot=0, 360 do
        local rot_temp = math.rad(rot)
        local lineX, lineY, lineZ = radius * math.cos(rot_temp) + x, radius * math.sin(rot_temp) + y, z
        local screen_x_line, screen_y_line = convert3DCoordsToScreen(lineX, lineY, lineZ)
        if screen_x_line ~=nil and screen_x_line_old ~= nil and isPointOnScreen(lineX, lineY, lineZ, 1) then renderDrawLine(screen_x_line, screen_y_line, screen_x_line_old, screen_y_line_old, 3, color) end
        screen_x_line_old, screen_y_line_old = screen_x_line, screen_y_line
    end
end

function ev.onSendAimSync(data)
    if state and (settings.search.needKey.v and isKeyDown(attackKey.v[1]) or not settings.search.needKey.v) then
        camX = data.camPos.x
		camY = data.camPos.y
		camZ = data.camPos.z
		
		frontX = data.camFront.x
		frontY = data.camFront.y
		frontZ = data.camFront.z

        local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)
        if _ and res then
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local x, y, z = getCharCoordinates(ped)
            if isLineOfSightClear(x, y, z, mx, my, mz, true, false, false, true, false) then
                local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                if weapon ~= nil then
                    local b = 0 * math.pi / 360.0
                    local h = 0 * math.pi / 360.0 
                    local angle = getCharHeading(ped)
                    local a = angle * math.pi / 360.0

                    local c1, c2, c3 = math.cos(h), math.cos(a), math.cos(b)
                    local s1, s2, s3 = math.sin(h), math.sin(a), math.sin(b)

                    data.camMode = weapon.camMode
                    data.weaponState = weapon.weaponState

                    data.camPos.x = mx
                    data.camPos.y = my
                    data.camPos.z = mz

                    local dx = x - data.camPos.x
                    local dy = y - data.camPos.y
                    local dz = z - data.camPos.z

                    data.camFront.x = dx / vect3_length(dx, dy, dz)
                    data.camFront.y = dy / vect3_length(dx, dy, dz)
                    data.camFront.z = dz / vect3_length(dx, dy, dz)
                end
            end
        end
    end
end

function vect3_length(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end

function sendMessage(message)
    sampAddChatMessage('{6EFB6E}[Damager]: {FFFFFF}' .. message, -1)
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
    -- from SAMP.Lua
    local raknet = require 'samp.raknet'
    --require 'samp.synchronization'

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
    -- copy player's sync data to the allocated memory
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    -- function to send packet
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    -- metatable to access sync data and 'send' function
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

function darkgreentheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.Border]                 = ImVec4(0.70, 0.70, 0.70, 0.40)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.19, 0.19, 0.19, 0.71)
    colors[clr.FrameBgActive]          = ImVec4(0.34, 0.34, 0.34, 0.79)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.69, 0.33, 0.80)
    colors[clr.TitleBgActive]          = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.69, 0.33, 0.50)
    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.16, 0.16, 0.16, 1.00)
    colors[clr.ScrollbarGrab]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.ComboBg]                = ImVec4(0.20, 0.20, 0.20, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.77, 0.37, 1.00)
    colors[clr.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00)
    colors[clr.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57)
    colors[clr.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89)
    colors[clr.Separator]              = ImVec4(1.00, 1.00, 1.00, 0.40)
    colors[clr.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
    colors[clr.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 0.80)
    colors[clr.ResizeGrip]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.00, 0.76, 0.37, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(0.00, 0.86, 0.41, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.CloseButtonHovered]     = ImVec4(0.00, 0.88, 0.42, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.00, 0.69, 0.33, 0.72)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.17, 0.17, 0.17, 0.48)
end
darkgreentheme()