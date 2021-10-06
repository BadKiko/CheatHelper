local mb = require('MoonBot')
local ev = require('lib.samp.events')
local imgui = require('imgui')

local fa = require'fAwesome5'

local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })

local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local password = '123123' -- Пароль
local dist = 10 -- Макс.дистанция ботов от вас

local botData = {}
local presets = {}

local menu = imgui.ImBool(false)
local oldMenu = menu.v
local sameCommands = imgui.ImBool(true)
local botName = imgui.ImBuffer(32)
local inputPreset = imgui.ImBuffer(256)

local sameFlood = false
local sameKiss = false

math.randomseed(os.time())

function addMessage(message)
    sampAddChatMessage(string.format('{FF67FF}[Sla{FF57FF}ve]: {FFFFFF}%s', message), -1)
end

function saveSettings()
    local f = io.open(getWorkingDirectory() .. '\\config\\slave\\config.json', 'w')
    local data = {
        password = password,
        dist = dist,
        sameCommands = sameCommands.v,
        presets = {}
    }
    local cPresets = {}
    for k, preset in pairs(presets) do
        local cPreset = {
            name = u8(preset.name),
            phrases = {}
        }
        for i, phrase in pairs(preset.phrases) do
            table.insert(cPreset.phrases, u8(phrase))
        end
        table.insert(cPresets, cPreset)
    end
    data.presets = cPresets
    --sampfuncsLog(encodeJson(data))
    f:write(encodeJson(data))
    f:close()
end

function loadSettings()
    local f = io.open(getWorkingDirectory() .. '\\config\\slave\\config.json', 'r')
    if f then
        local data = decodeJson(f:read('*a'))
        for k, preset in pairs(data.presets) do
            preset.name = u8:decode(preset.name)
            for i, phrase in pairs(preset.phrases) do
                preset.phrases[i] = u8:decode(preset.phrases[i])
            end
            preset.inputPhrase = imgui.ImBuffer(256)
        end
        presets = data.presets
        password = data.password
        dist = data.dist
        sameCommands.v = data.sameCommands
        f:close()
    else
        saveSettings()
    end
end

function main()
    repeat wait(0) until isSampAvailable()
    --mb.disconnectAfterUnload(false)
    loadSettings()
    local x, y, z = getCharCoordinates(PLAYER_PED)
    for k, bot in pairs(mb.getBots()) do
        table.insert(botData, {
            index = bot.index,
            logined = true,
            position = {x = x, y = y, z = z},
            floodTimer = 0,
            kissTimer = 0,
            kissTarget = 0,
            kiss = false,
            presetIndex = imgui.ImInt(0),
            presetName = '',
            flood = false,
            timer = 0
        })
    end

    mb.registerIncomingRPC(61) -- dialog
    mb.registerIncomingRPC(68) -- spawnInfo
    mb.registerIncomingRPC(134) -- textdraw
    mb.registerIncomingRPC(12) -- setplayerpos
    sampRegisterChatCommand('slave.chat', function(param) 
        if sameCommands.v then
            if param ~= nil then
                for k, lBot in pairs(botData) do
                    if param[1] == '/' then
                        mb.getBotHandleByIndex(lBot.index):sendCommand(param)
                    else
                        mb.getBotHandleByIndex(lBot.index):sendChat(param)
                    end
                end
            else
                addMessage('Используй: /slave.chat [msg]')
            end
        else
            if param:match('%d+ .+') then
                local index, msg = param:match('(%d+) (.+)')
                index = tonumber(index)
                local found = false
                for k, lBot in pairs(botData) do
                    if lBot.index == index then
                        if msg[1] == '/' then
                            mb.getBotHandleByIndex(lBot.index):sendCommand(msg)
                        else
                            mb.getBotHandleByIndex(lBot.index):sendChat(msg)
                        end
                        found = true
                        break
                    end
                end
                if not found then
                    addMessage('Не нашли бота с таким индексом')
                end
            else
                addMessage('Используй: {A7A7A7}/slave.chat [Index] [msg]')
            end
        end
    end)
    sampRegisterChatCommand('slave.add', function(param) 
        if param:len() >= 3 then
            local bot = mb.add(param)
            --bot:setReconnectTime(3000)
            table.insert(botData, {
                index = bot.index,
                logined = false,
                position = {
                    x = 0,
                    y = 0,
                    z = 0
                },
                floodTimer = 0,
                kissTimer = 0,
                presetIndex = imgui.ImInt(0),
                presetName = '',
                flood = false,
                timer = 0
            })
            bot:connect()
            addMessage(string.format('Подключаю {A7A7A7}%s[%d]', bot.name, bot.index))
        else
            addMessage(string.format('Никнейм должен быть от 3 символов'))
        end
    end)
    
    sampRegisterChatCommand('slave', function()
        menu.v = not menu.v
    end)
    sampRegisterChatCommand('slave.remove', function(param) 
        if param:match('%d+') then
            local index = tonumber(param)
            local found = false
            for k, bot in pairs(mb.getBots()) do
                if bot.index == index then
                    addMessage(string.format('Удаляю {A7A7A7}%s[%d]', bot.name, bot.index))
                    for j, lBot in pairs(botData) do
                        if lBot.index == bot.index then
                            table.remove(botData, j)
                            break
                        end
                    end
                    mb.remove(index)
                    found = true
                    break
                end
            end
            if not found then
                addMessage('Не нашли бота с таким индексом')
            end
        else
            addMessage('Используй: {A7A7A7}/slave.remove [Index]')
        end
    end)
    sampRegisterChatCommand('slave.spawn', function(param) 
        if param:match('%d+') then
            local index = tonumber(param)
            local found = false
            for k, bot in pairs(mb.getBots()) do
                if bot.index == index then
                    addMessage(string.format('Спавню {A7A7A7}%s[%d]', bot.name, bot.index))
                    bot:sendRequestClass(1)
                    bot:sendRequestSpawn()
                    bot:sendSpawn()
                    for j, lBot in pairs(botData) do
                        lBot.logined = true
                    end
                    found = true
                    break
                end
            end
            if not found then
                addMessage('Не нашли бота с таким индексом')
            end
        else
            addMessage('Используй: {A7A7A7}/slave.remove [Index]')
        end
    end)
    sampRegisterChatCommand('slave.flood', function(param) 
        if sameCommands.v then
            sameFlood = not sameFlood
            for k, lBot in pairs(botData) do
                lBot.flood = sameFlood
            end
            addMessage('Теперь все боты ' .. (sameFlood and 'флудят фразами из своих пресетов' or 'не флудят'))
        else
            if param:match('%d+') then
                local index = tonumber(param)
                local found = false
                for k, lBot in pairs(botData) do
                    if lBot.index == index then
                        lBot.flood = not lBot.flood
                        addMessage(string.format('Теперь {A7A7A7}%s[%d]{FFFFFF} ' .. (lBot.flood and 'флудит фразами из своего пресета' or 'не флудит'), mb.getBotHandleByIndex(lBot.index).name, lBot.index))
                        found = true
                        break
                    end
                end
                if not found then
                    addMessage('Не нашли бота с таким индексом')
                end
            else
                addMessage('Используй: {A7A7A7}/slave.flood [Index]')
            end
        end
    end)
    sampRegisterChatCommand('slave.kiss', function(param) 
        if sameCommands.v then
            if sameKiss then
                sameKiss = false
                for k, lBot in pairs(botData) do
                    lBot.kiss = false
                end 
                addMessage('Теперь боты не целуют никого')
            else
                if param:match('%d+') then
                    local targetId = tonumber(param)
                    local _, ped = sampGetCharHandleBySampPlayerId(targetId)
                    if _ and isCharOnFoot(ped) then
                        local x, y, z = getCharCoordinates(ped)
                        local mx, my, mz = getCharCoordinates(PLAYER_PED)
                        if getDistanceBetweenCoords3d(x, y, z, mx, my, mz) <= dist then
                            sameKiss = true
                            for k, lBot in pairs(botData) do
                                lBot.kissTarget = targetId
                                lBot.kiss = true
                            end
                            addMessage(string.format('Теперь все боты целуют {A7A7A7}%s', sampGetPlayerNickname(targetId)))
                        else
                            addMessage('Цель слишком далеко')
                        end
                    else
                        addMessage('Цель не найдена, либо она в авто')
                    end
                else
                    addMessage('Используй: {A7A7A7}/slave.kiss [TargetId]')
                end
            end
        else
            if param:match('%d+') then
                local index = param:match('(%d+)')
                index = tonumber(index)
                local found = false
                for k, lBot in pairs(botData) do
                    if lBot.index == index then
                        if lBot.kiss then
                            lBot.kiss = false
                            addMessage(string.format('Теперь {A7A7A7}%s[%d]{FFFFFF} не целует', mb.getBotHandleByIndex(lBot.index).name, lBot.index))
                        else
                            if param:match('%d+ %d+') then
                                local targetId = param:match('%d+ (%d+)')
                                targetId = tonumber(targetId)
                                local _, ped = sampGetCharHandleBySampPlayerId(targetId)
                                if _ and isCharOnFoot(ped) then
                                    local x, y, z = getCharCoordinates(ped)
                                    local mx, my, mz = getCharCoordinates(PLAYER_PED)
                                    if getDistanceBetweenCoords3d(x, y, z, mx, my, mz) <= dist then
                                        lBot.kissTarget = targetId
                                        lBot.kiss = true
                                        addMessage(string.format('Теперь {A7A7A7}%s[%d]{FFFFFF} целует {A7A7A7}%s', mb.getBotHandleByIndex(lBot.index).name, lBot.index, sampGetPlayerNickname(targetId)))
                                    else
                                        addMessage('Цель слишком далеко')
                                    end
                                else
                                    addMessage('Цель не найдена, либо она в авто')
                                end
                            else
                                addMessage('Используй: {A7A7A7}/slave.kiss [Index] [TargetId]')
                            end
                        end
                        found = true
                        break
                    end
                end
                if not found then
                    addMessage('Не нашли бота с таким индексом')
                end
            else
                addMessage('Используй: {A7A7A7}/slave.kiss [Index] [TargetId]')
            end
        end
    end)
    lua_thread.create(function() 
        while true do
            wait(50)
            for k, lBot in pairs(botData) do
                if lBot.floodTimer > 0 then
                    lBot.floodTimer = lBot.floodTimer - 1
                end
                if lBot.kissTimer > 0 then
                    lBot.kissTimer = lBot.kissTimer - 1
                end
                if lBot.timer > 0 then
                    lBot.timer = lBot.timer - 1
                end
                if lBot.logined then
                    if lBot.floodTimer <= 0 and lBot.flood then
                        if lBot.presetIndex.v ~= 0 then
                            local preset = presets[lBot.presetIndex.v]
                            if table.getn(preset.phrases) > 0 then
                                local bot = mb.getBotHandleByIndex(lBot.index)
                                if bot.connected then
                                    local phrase = preset.phrases[math.random(1, table.getn(preset.phrases))]
                                    if phrase:sub(1, 1) == '/' then
                                        bot:sendCommand(phrase)
                                    else
                                        bot:sendChat(phrase)
                                    end
                                    lBot.floodTimer = 50
                                end
                            end
                        end
                    end
                    if lBot.kiss then
                        local _, ped = sampGetCharHandleBySampPlayerId(lBot.kissTarget)
                        if _ and isCharOnFoot(ped) then
                            local x, y, z = getCharCoordinates(ped)
                            local mx, my, mz = getCharCoordinates(PLAYER_PED)
                            if getDistanceBetweenCoords3d(x, y, z, mx, my, mz) <= dist then
                                local angle = getCharHeading(ped) - 180
                                local b = 0 * math.pi / 360.0
                                local h = 0 * math.pi / 360.0 
                                local a = angle * math.pi / 360.0

                                local c1, c2, c3 = math.cos(h), math.cos(a), math.cos(b)
                                local s1, s2, s3 = math.sin(h), math.sin(a), math.sin(b)
                                
                                local data = mb.getPlayerData()
                                data.quaternion.w = c1 * c2 * c3 - s1 * s2 * s3
                                data.quaternion.z = -( c1 * s2 * c3 - s1 * c2 * s3 )
                                angle = angle + 180
                                data.position.x, data.position.y, data.position.z = x + math.sin(-math.rad(angle)), y + math.cos(-math.rad(angle)), z
                                data.health = getCharHealth(PLAYER_PED)
                                data.weapon = 0
                                data.armor = 0
                                data.moveSpeed.x, data.moveSpeed.y, data.moveSpeed.z = math.sin(-math.rad(angle)) / 1000, math.cos(-math.rad(angle)) / 1000, 0.001
                                mb.getBotHandleByIndex(lBot.index):sendPlayerData(data)
                                lBot.position = {x = data.position.x, y = data.position.y, z = data.position.z}
                            else
                                lBot.kiss = false
                                addMessage(string.format('{FFFFFF}Цель бота {A7A7A7}%s[%d] {FFFFFF}слишком далеко.', mb.getBotHandleByIndex(lBot.index).name, lBot.index))
                            end
                        else
                            lBot.kiss = false
                            addMessage(string.format('{A7A7A7}%s[%d] {FFFFFF}не смог обнаружить свою цель (либо она в авто)', mb.getBotHandleByIndex(lBot.index).name, lBot.index))
                        end
                        if lBot.kissTimer <= 0 and lBot.kiss then
                            mb.getBotHandleByIndex(lBot.index):sendCommand('/hi ' .. lBot.kissTarget)
                            lBot.kissTimer = 10
                        end
                    end
                end
            end
        end
    end)
    while true do
        wait(0)
        imgui.Process = menu.v
        for k, lBot in pairs(botData) do
            if lBot.logined and not mb.getBotHandleByIndex(lBot.index).connected then
                lBot.logined = false
            end
        end
        if oldMenu ~= menu.v then
            oldMenu = menu.v
            if not oldMenu then
                saveSettings()
            end
        end
        mb.updateCallbacks()
    end
end

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
    end
end 

function imgui.OnDrawFrame()
    if menu.v then
        local xw, yw = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(xw / 2, yw / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(600, 300), imgui.Cond.FirstUseEver)
        imgui.Begin('Slave | Bot System', menu, imgui.WindowFlags.NoResize)
        imgui.Checkbox(u8'Общие команды', sameCommands)
        if imgui.CollapsingHeader(fa.ICON_FA_USERS .. u8' Управление слейвами') then
            imgui.PushItemWidth(100)
            imgui.InputText(u8'Введите имя нового бота##botName', botName)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_PLUS .. u8' Добавить бота') then
                sampProcessChatInput(string.format('/slave.add %s', u8:decode(botName.v)))
                botName.v = ''
            end
            imgui.Columns(3)
            imgui.Separator()
            imgui.Text(u8'Имя [Index]') imgui.NextColumn()
            imgui.Text(u8'Подключен?') imgui.NextColumn()
            imgui.Text(u8'Опции') imgui.NextColumn()
            for k, lBot in pairs(botData) do
                local bot = mb.getBotHandleByIndex(lBot.index)
                imgui.Separator()
                imgui.Text(string.format('%s[%d]', bot.name, bot.index)) imgui.NextColumn()
                imgui.Text(bot.connected and u8'Подключен' or u8'Не подключен') imgui.NextColumn()
                if imgui.Button(fa.ICON_FA_MINUS .. u8' Удалить') then
                    sampProcessChatInput('/slave.remove ' .. bot.index)
                end
                local presetNames = {u8'Отсутствует'}
                for k, preset in pairs(presets) do
                    table.insert(presetNames, u8(preset.name))
                end
                if lBot.presetIndex.v > table.getn(presetNames) - 1 then
                    local found = false
                    for k, presetName in pairs(presetNames) do
                        if u8:decode(presetName) == lBot.presetName then
                            lBot.presetIndex.v = k - 1
                            lBot.presetName = u8:decode(presetName)
                            found = true
                            break
                        end
                    end
                    if not found then
                        lBot.presetIndex.v = 0
                        lBot.presetname = u8:decode(presetNames[1])
                    end
                end
                if lBot.presetName ~= presetNames[lBot.presetIndex.v + 1] then
                    local found = false
                    for k, presetName in pairs(presetNames) do
                        if u8:decode(presetName) == lBot.presetName then
                            lBot.presetIndex.v = k - 1
                            lBot.presetName = u8:decode(presetName)
                            found = true
                            break
                        end
                    end
                    if not found then
                        lBot.presetIndex.v = 0
                        lBot.presetname = u8:decode(presetNames[1])
                    end
                end
                if imgui.Combo(u8'Пресет бота##bot' .. bot.index, lBot.presetIndex, presetNames) then
                    lBot.presetName = u8:decode(presetNames[lBot.presetIndex.v + 1])
                end
                if imgui.Button(not lBot.flood and fa.ICON_FA_VOLUME_UP .. u8' Флудить' or fa.ICON_FA_VOLUME_MUTE .. u8' Не флудить') then
                    lBot.flood = not lBot.flood
                end
                imgui.NextColumn()
            end
            imgui.Separator()
            imgui.Columns(1)
        end
        if imgui.CollapsingHeader(fa.ICON_FA_CLIPBOARD_LIST .. u8' Пресеты / фразы для флуда') then
            imgui.PushItemWidth(100)
            imgui.InputText(u8'Введите имя нового пресета##newPhrase', inputPreset)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_PLUS .. u8' Добавить пресет') then
                local good = true
                for k, preset in pairs(presets) do
                    if preset.name == u8:decode(inputPreset.v) then
                        good = false
                        break
                    end
                end
                if good then
                    table.insert(presets, {
                        name = u8:decode(inputPreset.v),
                        phrases = {},
                        inputPhrase = imgui.ImBuffer(256)
                    })
                    inputPreset.v = ''
                end
            end
            imgui.Separator()
            imgui.Text(u8'Созданные пресеты:')
            for k, preset in pairs(presets) do
                if imgui.CollapsingHeader(u8(preset.name)) then
                    if imgui.Button(fa.ICON_FA_MINUS .. u8' Удалить##preset' .. k) then
                        table.remove(presets, k)
                    else
                        imgui.PushItemWidth(100)
                        imgui.InputText(u8'Введите новую фразу для пресета##newPreset' .. k, preset.inputPhrase)
                        imgui.SameLine()
                        if imgui.Button(fa.ICON_FA_PLUS .. u8' Добавить фразу##preset' .. k) then
                            table.insert(presets[k].phrases, u8:decode(preset.inputPhrase.v))
                            preset.inputPhrase.v = ''
                        end
                        imgui.Columns(2)
                        imgui.Separator()
                        imgui.Text(u8'Фраза') imgui.NextColumn()
                        imgui.Text(u8'Опции') imgui.NextColumn()
                        for i, phrase in pairs(preset.phrases) do
                            imgui.Separator()
                            imgui.Text(u8(phrase)) imgui.NextColumn()
                            if imgui.Button(fa.ICON_FA_MINUS .. u8' Удалить##preset' .. k .. 'phrase' .. i) then
                                table.remove(preset.phrases, i)
                            end
                            imgui.NextColumn()
                        end
                        imgui.Separator()
                        imgui.Columns(1)
                    end
                end
            end
        end
        imgui.End()
    end
end

function onBotPacket(bot, packetId, bs)
    if packetId == 41 then
        addMessage(string.format('{A7A7A7}%s[%d] {FFFFFF}успешно подключился! {A7A7A7}(PlayerID: %d)', bot.name, bot.index, bot.playerID))
    end
end

function onBotRPC(bot, rpcId, bs)
    --sampAddChatMessage('got rpc: ' .. rpcId)
    if rpcId == 12 then
        for k, lBot in pairs(botData) do
            if lBot.index == bot.index then
                local x, y, z = bs:readFloat(), bs:readFloat(), bs:readFloat()
                lBot.position = {x = x, y = y, z = z}
                addMessage(string.format('{A7A7A7}%s[%d] {FFFFFF}сменил позицию {A7A7A7}(x: %d, y: %d, z: %d)', bot.name, bot.index, math.floor(x), math.floor(y), math.floor(z)))
            end
        end
    end
    if rpcId == 61 then
        local dialogId = bs:readInt16()
        local style = bs:readInt8()
        local title = bs:readString8()
        local btn1 = bs:readString8()
        local btn2 = bs:readString8()
        if title:find('Авторизация') then
            addMessage(string.format('{A7A7A7}%s[%d] {FFFFFF}авторизуется...', bot.name, bot.index))
            bot:sendDialogResponse(dialogId, 1, 0, password)
        end
        if title:find('%(1/4%)') then
            addMessage(string.format('{A7A7A7}%s [%d] {FFFFFF}регистрируется...', bot.name, bot.index))
            bot:sendDialogResponse(dialogId, 1, 0, password)
        end
        if title:find('%[2/5%]') or title:find('%[3/5%]') or title:find('%[3/4%]') then
            bot:sendDialogResponse(dialogId, 1, 0, '')
            addMessage(string.format('{A7A7A7}%s[%d] {FFFFFF}скипнул диалог {A7A7A7}(заголовок: %s{A7A7A7})', bot.name, bot.index, title))
        end
    end
    if rpcId == 68 then
        for k, lBot in pairs(botData) do
            if lBot.index == bot.index and not lBot.logined then
                local team = bs:readInt8()
                local skin = bs:readInt32()
                local unk = bs:readInt8()
                local x, y, z = bs:readFloat(), bs:readFloat(), bs:readFloat()
                lBot.position = {x = x, y = y, z = z}
                lBot.logined = true
                bot:sendRequestSpawn()
                bot:sendSpawn()
                addMessage(string.format('{A7A7A7}%s[%d] {FFFFFF}заспавнился', bot.name, bot.index))
                break
            end
        end
    end
    if rpcId == 134 then
        local tdId = bs:readInt16()
        bs:ignoreBits(264)
        local x, y = bs:readFloat(), bs:readFloat()
        if x == 233.000000 and y == 367.000000 then
            for k, lBot in pairs(botData) do
                if lBot.index == bot.index then
                    local sync = mb.getPlayerData()
                    sync.position.x, sync.position.y, sync.position.z = lBot.position.x, lBot.position.y, lBot.position.z
                    sync.health = 100
                    sync.armor = 0
                    sync.quaternion.w, sync.quaternion.x, sync.quaternion.y, sync.quaternion.z = 0, 0, 0, 0
                    sync.moveSpeed.x, sync.moveSpeed.y, sync.moveSpeed.z = 0, 0, 0
                    sync.weapon = 0
                    lBot.logined = false
                    bot:sendPlayerData(sync)
                    bot:sendClickTextdraw(tdId)
                    bot:sendRequestSpawn()
                    bot:sendSpawn()
                    addMessage(string.format('{A7A7A7}%s[%d] {FFFFFF}выбрал скин', bot.name, bot.index))
                    break
                end
            end
        end
    end
end

function ev.onSendPickedUpPickup(pickup)
    for k, lBot in pairs(botData) do
        if lBot.logined then
            local bot = mb.getBotHandleByIndex(lBot.index)
            local data = mb.getPlayerData()
            data.position.x, data.position.y, data.position.z = getCharCoordinates(PLAYER_PED)
            data.health = 100
            data.armor = 0
            data.quaternion.w, data.quaternion.x, data.quaternion.y, data.quaternion.z = 0, 0, 0, 0
            data.moveSpeed.x, data.moveSpeed.y, data.moveSpeed.z = 0, 0, 0
            data.weapon = 0
            bot:sendPlayerData(data)
            bot:sendPickedUpPickup(pickup)
        end
    end
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        mb.unload()
        saveSettings()
    end
end

function ev.onSendPlayerSync(data)
    local offset = 0
    for k, lBot in pairs(botData) do
        if lBot.logined and lBot ~= nil and not lBot.kiss then
            --printStringNow(string.format('distance: %f', getDistanceBetweenCoords3d(lBot.position.x, lBot.position.y, lBot.position.z, data.position.x, data.position.y, data.position.z)), 500)
            if getDistanceBetweenCoords3d(lBot.position.x, lBot.position.y, lBot.position.z, data.position.x, data.position.y, data.position.z) <= dist and lBot.timer <= 0 then
                offset = offset + 1
                local angle = getCharHeading(PLAYER_PED) - 90
                local sync = mb.getPlayerData()
                sync.position.x, sync.position.y, sync.position.z = data.position.x + math.sin(-math.rad(angle)) * offset, data.position.y + math.cos(-math.rad(angle)) * offset, data.position.z
                sync.health = data.health
                sync.armor = 0
                sync.quaternion.w, sync.quaternion.x, sync.quaternion.y, sync.quaternion.z = data.quaternion[0], data.quaternion[1], data.quaternion[2], data.quaternion[3]
                sync.moveSpeed.x, sync.moveSpeed.y, sync.moveSpeed.z = data.moveSpeed.x, data.moveSpeed.y, data.moveSpeed.z - 0.1
                sync.weapon = 0
                sync.animationFlags = data.animationFlags
                sync.animationId = data.animationId
                sync.leftRightKeys = data.leftRightKeys
                sync.upDownKeys = data.upDownKeys
                sync.keysData = data.keysData
                local bot = mb.getBotHandleByIndex(lBot.index)
                bot:sendPlayerData(sync)
                lBot.timer = 1 + lBot.index
                lBot.position = {x = sync.position.x, y = sync.position.y, z = sync.position.z}
            end
        end
    end
end

function purple_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.FrameRounding = 5
    colors[clr.FrameBg]                = ImVec4(0.46, 0.11, 0.29, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.69, 0.16, 0.43, 1.00)
    colors[clr.FrameBgActive]          = ImVec4(0.58, 0.10, 0.35, 1.00)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.61, 0.16, 0.39, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.94, 0.30, 0.63, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.85, 0.11, 0.49, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.89, 0.24, 0.58, 1.00)
    colors[clr.Button]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
    colors[clr.ButtonHovered]          = ImVec4(0.69, 0.17, 0.43, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.59, 0.10, 0.35, 1.00)
    colors[clr.Header]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.69, 0.16, 0.43, 1.00)
    colors[clr.HeaderActive]           = ImVec4(0.58, 0.10, 0.35, 1.00)
    colors[clr.Separator]              = ImVec4(0.69, 0.16, 0.43, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.58, 0.10, 0.35, 1.00)
    colors[clr.SeparatorActive]        = ImVec4(0.58, 0.10, 0.35, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.46, 0.11, 0.29, 0.70)
    colors[clr.ResizeGripHovered]      = ImVec4(0.69, 0.16, 0.43, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.70, 0.13, 0.42, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.78, 0.90, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.60, 0.19, 0.40, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border]                 = ImVec4(0.49, 0.14, 0.31, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.49, 0.14, 0.31, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

purple_style()