local ev = require('lib.samp.events')
local mb = require('MoonBot')

local raznos = false
local botData = {}

function main()
    repeat wait(0) until isSampAvailable()
    mb.registerIncomingRPC(61)
    mb.registerIncomingRPC(156)
    sampRegisterChatCommand('abot.add', function(param) 
        if param:len() >= 3 then
            local bot = mb.add(param)
            bot:connectAsNPC(true)
            table.insert(botData, {
                index = bot.index,
                logined = false,
                interior = 0,
                alt = false,
                raznos = false
            })
            bot:connect()
            addMessage(string.format('Подключаю %s[%d] на сервер', bot.name, bot.index))
        else
            addMessage('Ник должен быть от 3 символов')
        end
    end)
    sampRegisterChatCommand('abot.remove', function(param) 
        if param:match('%d+') then
            local id = tonumber(param)
            local found = false
            for k, lBot in pairs(botData) do
                if lBot.index == id then
                    local bot = mb.getBotHandleByIndex(id)
                    addMessage(string.format('Удаляю %s[%d]', bot.name, bot.index))
                    bot:disconnect()
                    mb.remove(bot.index)
                    found = true
                    table.remove(botData, k)
                    break
                end
            end
            if not found then
                addMessage('Не нашли бота с таким индексом!')
            end
        else
            addMessage('Используйте: /abot.remove [index]')
        end
    end)
    sampRegisterChatCommand('abot.raznos', function() 
        raznos = not raznos
        for k, lBot in pairs(botData) do
            lBot.raznos = false
        end
        addMessage(string.format('Разнос %s', raznos and 'включен' or 'выключен'))
    end)
    while true do
        wait(5)
        mb.updateCallbacks()
        for k, lBot in pairs(botData) do
            local bot = mb.getBotHandleByIndex(lBot.index)
            if lBot.logined and not bot.connected then
                lBot.logined = false
            end
            if not lBot.logined and bot.connected then
                local data = mb.getSpectatorData()
                lBot.alt = not lBot.alt
                data.keysData = lBot.alt and 1024 or 0
                if lBot.interior == 1 then
                    data.position.x, data.position.y, data.position.z = 2420, 2355, 1492
                else
                    data.position.x, data.position.y, data.position.z = 1814, -1876, 13
                end
                bot:sendSpectatorData(data)
            end
            if lBot.logined and raznos then
                local x, y, z = getCharCoordinates(PLAYER_PED)
                local _, ped = findAllRandomCharsInSphere(x, y, z, 1000, true, true)
                if _ then
                    local _, id = sampGetPlayerIdByCharHandle(ped)
                    if _ then
                        if not sampIsPlayerNpc(id) and not sampIsPlayerPaused(id) then
                            local angle = 0
                            local isCar = false
                            local px, py, pz = 0, 0, 0
                            if isCharInAnyCar(ped) then
                                angle = getCarHeading(getCarCharIsUsing(ped))
                                isCar = true
                                px, py, pz = getCarCoordinates(getCarCharIsUsing(ped))
                            else
                                angle = getCharHeading(ped)
                                px, py, pz = getCharCoordinates(ped)
                            end
                            local multiplier = 5
                            lBot.raznos = true
                            local data = mb.getPlayerData()
                            data.health = 100
                            data.armor = 0
                            data.weapon = 0
                            data.moveSpeed.x, data.moveSpeed.y, data.moveSpeed.z = math.sin(-math.rad(angle)) * multiplier, math.cos(-math.rad(angle)) * multiplier, multiplier
                            if isCar then
                                data.position.x, data.position.y, data.position.z = px, py, pz -1
                            else
                                data.position.x, data.position.y, data.position.z = px - math.sin(-math.rad(angle)), py - math.cos(-math.rad(angle)), pz + 0.5
                            end
                            local b = 0 * math.pi / 360.0
                            local h = 0 * math.pi / 360.0 
                            local a = angle * math.pi / 360.0

                            local c1, c2, c3 = math.cos(h), math.cos(a), math.cos(b)
                            local s1, s2, s3 = math.sin(h), math.sin(a), math.sin(b)
                            
                            data.quaternion.w = c1 * c2 * c3 - s1 * s2 * s3
                            data.quaternion.z = -( c1 * s2 * c3 - s1 * c2 * s3 )
                            bot:sendPlayerData(data)
                        else
                            lBot.raznos = false
                        end
                    else
                        lBot.raznos = false
                    end
                else
                    lBot.raznos = false
                end
            end
        end
    end
end

function onBotRPC(bot, rpcId, bs)
    if rpcId == 61 then
        local dialogId = bs:readInt16()
        bs:ignoreBits(8)
        local title = bs:readString8()
        for k, lBot in pairs(botData) do
            if lBot.index == bot.index and not lBot.logined then
                if title:find('Выберите') then
                    bot:sendDialogResponse(dialogId, 1, 0, '')
                    break
                end
            end
        end
    end
    if rpcId == 156 then
        for k, lBot in pairs(botData) do
            if lBot.index == bot.index then
                lBot.interior = bs:readInt8()
                if lBot.interior == 0 then
                    lBot.logined = true
                    addMessage(string.format('Bot %s[%d] багнулся', bot.name, bot.index))
                end
                break
            end
        end
    end
end

function onBotPacket(bot, packetId, bs)
    if packetId == 41 then
        addMessage(string.format('Bot %s[%d] подключился к серверу (playerId: %d)', bot.name, bot.index, bot.playerID))
    end
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        mb.unload()
    end
end

function addMessage(message)
    sampAddChatMessage(string.format('{FF5656}[ABot]: {FFFFFF}%s', message), -1)
end

function ev.onSendPickedUpPickup(pickup)
    for k, lBot in pairs(botData) do
        if lBot.logined then
            local bot = mb.getBotHandleByIndex(lBot.index)
            local data = mb.getSpectatorData()
            data.position.x, data.position.y, data.position.z = getCharCoordinates(PLAYER_PED)
            bot:sendSpectatorData(data)
            bot:sendPickedUpPickup(pickup)
        end
    end
end

function ev.onSendPlayerSync(data)
    for k, lBot in pairs(botData) do
        if lBot.logined and not lBot.raznos then
            local angle = getCharHealth(PLAYER_PED) - 90
            local sync = mb.getSpectatorData()
            sync.position.x, sync.position.y, sync.position.z = data.position.x + math.sin(-math.rad(angle)), data.position.y + math.cos(-math.rad(angle)), data.position.z
            sync.keysData = data.keysData
            sync.upDownKeys = data.upDownKeys
            sync.leftRightKeys = data.leftRightKeys
            mb.getBotHandleByIndex(lBot.index):sendSpectatorData(sync)
        end
    end
end