local ev = require('lib.samp.events')
local effil = require('effil')
local imgui = require('imgui')

local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local state = false
local messages = { -- /nick/ /id/ /message/
}
local pBotUrl = 'https://mrcreepton.mtmcode.ru/pbot/index.php'
local xusuUrl = 'https://xu.su/api/send'
local playerData = {}
local directList = {}

local menu = imgui.ImBool(false)
local onscreen = imgui.ImBool(false)
local directMode = imgui.ImBool(false)
local dist = imgui.ImFloat(20)
local oldMenu = menu.v
local selectedBot = imgui.ImInt(1)
local addTextBox = imgui.ImBuffer(256)
local directTextBox = imgui.ImBuffer(256)

function main()
    repeat wait(0) until isSampAvailable()
    CherryTheme()
    loadSettings()
    sampRegisterChatCommand('cb', function(param)
        state = not state
        sampAddChatMessage(state and 'on' or 'off', -1)
    end)
    sampRegisterChatCommand('cb.menu', function(param)
        menu.v = not menu.v
    end)
    while true do
        wait(0)
        imgui.Process = menu.v
        if oldMenu ~= menu.v then
            saveSettings()
            oldMenu = menu.v
        end
    end
end

function imgui.OnDrawFrame()
    if menu.v then
        local xw, yw = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(xw / 2, yw / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'ChatBot', menu, imgui.WindowFlags.NoResize)
        if imgui.Button(u8(state and 'Выключить' or 'Включить'), imgui.ImVec2(-1, 20)) then state = not state end
        imgui.InputFloat(u8'Дистанция срабатывания', dist, 0, 0, 2)
        imgui.Checkbox(u8'Цель должна быть на экране', onscreen)
        imgui.Separator()
        imgui.Text(u8'/nick/ - ник, /id/ - id, /message/ - сообщение')
        imgui.PushItemWidth(200)
        imgui.InputText(u8'Новая фраза', addTextBox)
        imgui.PopItemWidth()
        imgui.SameLine()
        if imgui.Button(u8'Добавить##phrase') then table.insert(messages, u8:decode(addTextBox.v)) addTextBox.v = '' end
        if imgui.CollapsingHeader(u8'Добавленные фразы') then
            if messages then
                for k, message in pairs(messages) do
                    imgui.Text(u8(message))
                    imgui.SameLine()
                    if imgui.Button(u8'Удалить##phrase' .. k) then
                        table.remove(messages, k)
                    end
                end
            end
        end
        imgui.Checkbox(u8'Персональный режим', directMode)
        if directMode.v then
            imgui.PushItemWidth(200)
            imgui.InputText(u8'Новая жертва (Ник/ID)', directTextBox)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(u8'Добавить##target') then table.insert(directList, u8:decode(directTextBox.v)) directTextBox.v = '' end
            if imgui.CollapsingHeader(u8'Ники/ID жертв') then
                if directList then
                    for k, direct in pairs(directList) do
                        imgui.Text(u8(direct))
                        imgui.SameLine()
                        if imgui.Button(u8'Удалить##direct' .. k) then
                            table.remove(directList, k)
                        end
                    end
                end
            end
        end
        imgui.Separator()
        imgui.Text(u8'Выберите чатбота:')
        imgui.RadioButton(u8'PBot (умный, но медленный)', selectedBot, 1)
        imgui.RadioButton(u8'XuSu (тупой, но быстрый)', selectedBot, 2)
        imgui.End()
    end
end

function ev.onServerMessage(color, text)
    if state then
        for k, message in pairs(messages) do
            local cMessage = esc(message)
            local rMessage = ''
            local arguments = {}
            --print(cMessage)
            --print(text)
            while cMessage:find('/%w+/') do
                local a, b = cMessage:find('/%w+/')
                local found = string.sub(cMessage, a, b)
                rMessage = rMessage .. cMessage:sub(1, a - 1) .. '(.+)'
                cMessage = cMessage:sub(b + 1)
                table.insert(arguments, found)
                --print(found)
            end
            rMessage = rMessage .. cMessage
            --print(rMessage)
            if text:match(rMessage) then
                local filledArguments = {text:match(rMessage)}
                local nick, id, message = nil, nil, nil
                for k, arg in pairs(arguments) do
                    if arg == '/nick/' and not nick then
                        nick = filledArguments[k]
                    end
                    if arg == '/id/' and not id then
                        id = tonumber(filledArguments[k])
                    end
                    if arg == '/message/' and not message then
                        message = filledArguments[k]
                    end
                end
                local isMe = false
                local myData = getMyData()
                if nick == nil and id ~= nil then
                    nick = sampGetPlayerNickname(id)
                end
                if id ~= nil and id == myData.id then
                    isMe = true
                end
                if nick ~= nil and nick == myData.nick then
                    isMe = true
                end
                if not isMe and message ~= nil and nick ~= nil then
                    sendMessage(nick, message)
                end
            end
        end
    end
end

function loadSettings()
    local f = io.open(getWorkingDirectory() .. '/config/chatbot/settings.json', 'r')
    data = decodeJson(u8:decode(f:read('*a')))
    messages = data.messages
    directList = data.directList
    selectedBot.v = data.selectedBot
    directMode.v = data.directMode
    dist.v = data.dist
    onscreen.v = data.onscreen
    f:close()
end

function saveSettings()
    --sampAddChatMessage('save', -1)
    local f = io.open(getWorkingDirectory() .. '/config/chatbot/settings.json', 'w')
    local data = {
        messages = messages,
        selectedBot = selectedBot.v,
        directMode = directMode.v,
        dist = dist.v,
        onscreen = onscreen.v,
        directList = directList
    }
    f:write(u8(encodeJson(data)))
    f:close()
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        saveSettings()
    end
end

function esc(x)
    return (x:gsub('%%', '%%%%')
             :gsub('^%^', '%%^')
             :gsub('%$$', '%%$')
             :gsub('%(', '%%(')
             :gsub('%)', '%%)')
             :gsub('%.', '%%.')
             :gsub('%[', '%%[')
             :gsub('%]', '%%]')
             :gsub('%*', '%%*')
             :gsub('%+', '%%+')
             :gsub('%-', '%%-')
             :gsub('%?', '%%?'))
end 

function getMyData()
    local id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
    local nick = sampGetPlayerNickname(id)
    return {
        id = id,
        nick = nick
    }
end

function sendMessage(playerNick, message)
    local player = nil
    for k, cPlayer in pairs(playerData) do
        if cPlayer.nick == playerNick then
            player = cPlayer
            break
        end
    end
    if player == nil then
        table.insert(playerData, {
            nick = playerNick,
            messages = {},
            answering = false
        })
        for k, cPlayer in pairs(playerData) do
            if cPlayer.nick == playerNick then
                player = cPlayer
                break
            end
        end
    end
    if player ~= nil and not player.answering then
        local id = sampGetPlayerIdByNickname(playerNick)
        if id then
            -- sampAddChatMessage('test: ' .. id, -1)
            if directMode.v then
                local found = false
                for k, direct in pairs(directList) do
                    if direct:match('%d+') then
                        local cId = tonumber(direct)
                        if cId == id then
                            found = true
                            break
                        end
                    end
                    if direct == playerNick then
                        found = true
                        break
                    end
                end
                if not found then
                    return false
                end
            end
            local _, ped = sampGetCharHandleBySampPlayerId(id)
            if _ then
                local x, y, z = getCharCoordinates(PLAYER_PED)
                local px, py, pz = getCharCoordinates(ped)
                if getDistanceBetweenCoords3d(x, y, z, px, py, pz) > dist.v then
                    return false
                end
                if onscreen.v and not isCharOnScreen(ped) then
                    return false
                end
                if selectedBot.v == 1 then
                    --sampAddChatMessage('pbot call', -1)
                    local data = string.format('message=%s&playerNick=%s&nick=%s&dialogId=%s', u8(message), u8(playerNick), u8(getMyData().nick), u8'2bd198480e3898bd')

                    for i = 1, 3 do
                        if i <= table.getn(player.messages) then
                            data = data .. u8('&message' .. i .. '=' .. player.messages[i].message)
                            data = data .. u8('&answer' .. i .. '=' .. player.messages[i].answer)
                        else
                            data = data .. u8('&message' .. i .. '=')
                            data = data .. u8('&answer' .. i .. '=')
                        end
                    end

                    local args = {
                        data = data,
                        headers = {
                            ['content-type']='application/x-www-form-urlencoded'
                        },
                        timeout = 60
                    }

                    player.answering = true
                    asyncHttpRequest('POST', pBotUrl, args, 
                    function(result)
                        -- sampfuncsLog(result.text)
                        local data = decodeJson(u8:decode(result.text))
                        if not data.error then
                            player.messages[1].answer = u8:decode(data.message)
                            sampSendChat(u8:decode(data.message))
                        end
                        player.answering = false
                    end, 
                    function(err) 
                        player.answering = false
                        -- :c
                    end)

                    if table.getn(player.messages) > 3 then
                        table.remove(player.messages, 1)
                    end
                    table.insert(player.messages, {
                        message = message,
                        answer = ''
                    })
                else
                    --sampAddChatMessage('xusu call', -1)
                    local request = {
                        uid = nil,
                        bot = u8('тролль-бот'),
                        text = u8(message)
                    }
                    local args = {
                        data = encodeJson(request),
                        headers = {
                            ['content-type']='application/json'
                        }
                    }
                    asyncHttpRequest('POST', xusuUrl, args, function(result)
                        local data = decodeJson(u8:decode(result.text))
                        --sampAddChatMessage(data.text, -1)
                        sampSendChat(data.text)
                    end,
                    function(err) 
                        -- :c
                    end)
                end
            end
        end
    end
end

function sampGetPlayerIdByNickname(nick)
    nick = tostring(nick)
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if nick == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1003 do
      if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
        return i
      end
    end
  end

function asyncHttpRequest(method, url, args, resolve, reject)
   local request_thread = effil.thread(function (method, url, args)
      local requests = require 'requests'
      local result, response = pcall(requests.request, method, url, args)
      if result then
         response.json, response.xml = nil, nil
         return true, response
      else
         return false, response
      end
   end)(method, url, args)
   -- Если запрос без функций обработки ответа и ошибок.
   if not resolve then resolve = function() end end
   if not reject then reject = function() end end
   -- Проверка выполнения потока
   lua_thread.create(function()
      local runner = request_thread
      while true do
         local status, err = runner:status()
         if not err then
            if status == 'completed' then
               local result, response = runner:get()
               if result then
                  resolve(response)
               else
                  reject(response)
               end
               return
            elseif status == 'canceled' then
               return reject(status)
            end
         else
            return reject(err)
         end
         wait(0)
      end
   end)
end

function CherryTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
  
  
    style.WindowPadding = ImVec2(6, 4)
    style.WindowRounding = 0.0
    style.FramePadding = ImVec2(5, 2)
    style.FrameRounding = 3.0
    style.ItemSpacing = ImVec2(7, 7)
    style.ItemInnerSpacing = ImVec2(5, 1)
    style.TouchExtraPadding = ImVec2(0, 0)
    style.IndentSpacing = 6.0
    style.ScrollbarSize = 12.0
    style.ScrollbarRounding = 16.0
    style.GrabMinSize = 20.0
    style.GrabRounding = 2.0
  
    style.WindowTitleAlign = ImVec2(0.5, 0.5)
  
    colors[clr.Text] = ImVec4(0.860, 0.930, 0.890, 0.78)
    colors[clr.TextDisabled] = ImVec4(0.860, 0.930, 0.890, 0.28)
    colors[clr.WindowBg] = ImVec4(0.13, 0.14, 0.17, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(0.200, 0.220, 0.270, 0.58)
    colors[clr.PopupBg] = ImVec4(0.200, 0.220, 0.270, 0.9)
    colors[clr.Border] = ImVec4(0.31, 0.31, 1.00, 0.00)
    colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg] = ImVec4(0.200, 0.220, 0.270, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.455, 0.198, 0.301, 0.78)
    colors[clr.FrameBgActive] = ImVec4(0.455, 0.198, 0.301, 1.00)
    colors[clr.TitleBg] = ImVec4(0.232, 0.201, 0.271, 1.00)
    colors[clr.TitleBgActive] = ImVec4(0.502, 0.075, 0.256, 1.00)
    colors[clr.TitleBgCollapsed] = ImVec4(0.200, 0.220, 0.270, 0.75)
    colors[clr.MenuBarBg] = ImVec4(0.200, 0.220, 0.270, 0.47)
    colors[clr.ScrollbarBg] = ImVec4(0.200, 0.220, 0.270, 1.00)
    colors[clr.ScrollbarGrab] = ImVec4(0.09, 0.15, 0.1, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.455, 0.198, 0.301, 0.78)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.455, 0.198, 0.301, 1.00)
    colors[clr.CheckMark] = ImVec4(0.71, 0.22, 0.27, 1.00)
    colors[clr.SliderGrab] = ImVec4(0.47, 0.77, 0.83, 0.14)
    colors[clr.SliderGrabActive] = ImVec4(0.71, 0.22, 0.27, 1.00)
    colors[clr.Button] = ImVec4(0.47, 0.77, 0.83, 0.14)
    colors[clr.ButtonHovered] = ImVec4(0.455, 0.198, 0.301, 0.86)
    colors[clr.ButtonActive] = ImVec4(0.455, 0.198, 0.301, 1.00)
    colors[clr.Header] = ImVec4(0.455, 0.198, 0.301, 0.76)
    colors[clr.HeaderHovered] = ImVec4(0.455, 0.198, 0.301, 0.86)
    colors[clr.HeaderActive] = ImVec4(0.502, 0.075, 0.256, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.47, 0.77, 0.83, 0.04)
    colors[clr.ResizeGripHovered] = ImVec4(0.455, 0.198, 0.301, 0.78)
    colors[clr.ResizeGripActive] = ImVec4(0.455, 0.198, 0.301, 1.00)
    colors[clr.PlotLines] = ImVec4(0.860, 0.930, 0.890, 0.63)
    colors[clr.PlotLinesHovered] = ImVec4(0.455, 0.198, 0.301, 1.00)
    colors[clr.PlotHistogram] = ImVec4(0.860, 0.930, 0.890, 0.63)
    colors[clr.PlotHistogramHovered] = ImVec4(0.455, 0.198, 0.301, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.455, 0.198, 0.301, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(0.200, 0.220, 0.270, 0.73)
  end