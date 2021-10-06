local hook = require('lib.samp.events')
local vkeys = require ("vkeys")
local fa = require 'fAwesome5'
local imgui = require 'imgui'
local encoding = require 'encoding'
local inicfg = require 'inicfg'

encoding.default = 'CP1251'
u8 = encoding.UTF8
local font = renderCreateFont('Verdana', 12, 12, 1)

local act = false
local act2 = false
local act_all = false
local id = nil
local px, py, pz = 0, 0, 0



local mainIni = inicfg.load({
   config = {
    mX_veh = -0.0,
    mY_veh = -0.0,
    mZ_veh = -0.0,
    mX_ofoot = -0.0,
    mY_ofoot = -0.0,
    mZ_ofoot = -0.0,
    line_target = false,
	nick_target = false,
	dist_all = 0.0,
	dist_veh = 0.0,
	dist_onfoot = 0.0,
	logs = false,
	imgui_style = 0,
}
}, "Snos-Rvanka")


local status = inicfg.load(mainIni, 'Snos-Rvanka.ini')
if not doesFileExist('moonloader/config/Snos-Rvanka.ini') then inicfg.save(mainIni, 'Snos-Rvanka.ini') end

local main_window_state = imgui.ImBool(false)

local movespeedX_veh = imgui.ImFloat(mainIni.config.mX_veh)
local movespeedY_veh = imgui.ImFloat(mainIni.config.mY_veh)
local movespeedZ_veh = imgui.ImFloat(mainIni.config.mZ_veh)

local movespeedX_ofoot = imgui.ImFloat(mainIni.config.mX_ofoot)
local movespeedY_ofoot = imgui.ImFloat(mainIni.config.mY_ofoot)
local movespeedZ_ofoot = imgui.ImFloat(mainIni.config.mZ_ofoot)

local DrawLine_Target = imgui.ImBool(mainIni.config.line_target)
local DrawNick_Target = imgui.ImBool(mainIni.config.nick_target)

local rv_logs = imgui.ImBool(mainIni.config.logs)

local distance_veh = imgui.ImFloat(mainIni.config.dist_veh)
local distance_onfoot = imgui.ImFloat(mainIni.config.dist_onfoot)
local distance_all = imgui.ImFloat(mainIni.config.dist_all)

local imgui_style = imgui.ImInt(mainIni.config.imgui_style)


local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig() -- to use 'imgui.ImFontConfig.new()' on error
        font_config.MergeMode = true

        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
    end
end

function main()
	repeat wait(0) until isSampAvailable()
	msg('Рванка успешно Загружена by Enlizmee | /snos.m для активации')
	sampRegisterChatCommand('snos.m', function()
		main_window_state.v = not main_window_state.v
		imgui.Process = main_window_state.v
	end)
	sampRegisterChatCommand('snos.all', function()
		if act_all then act_all = false return msg("Рванка на всех выключена!") end
		if act or act2 then return msg("оффни сначала рванку на игрока.") end
		if isCharInAnyCar(PLAYER_PED) then
			act_all = true
			msg("врублена!")
		else
			msg("сядь в машину")
		end
	end)
	sampRegisterChatCommand('snos.veh', function(param)
		if act2 then return msg('сначала выключите onfoot рванку! /snos.onfoot') end
		if act then act = false return msg('Выключено!', -1) end
		if not param:match('%d+') then return msg('Используй /snos.veh [playerID]') end
		id = tonumber(param)
		local _, ped = sampGetCharHandleBySampPlayerId(id)
		if not sampIsPlayerConnected(id) then return msg('Игрока нет на сервере!') end
		if not _ then return msg('Игрока нет в зоне стрима') end
		local localx, localy, localz = getCharCoordinates(ped)
		local ppx, ppy, ppz = getCharCoordinates(PLAYER_PED)
		if getDistanceBetweenCoords3d(localx, localy, localz, ppx, ppy, ppz) > distance_veh.v then
			return msg("Жертва {FF0000}"..sampGetPlayerNickname(id).."["..id.."]{ffffff} далеко!")
		end
		if isCharInAnyCar(PLAYER_PED) then
			msg('Жертва: {FF0000}'..sampGetPlayerNickname(id)..'['..id..'].{ffffff} Начинаем ее рванить!')
			act = true
			print("RVANKA IN VEHICLE ON! Target: "..sampGetPlayerNickname(id).."["..id.."]")
			local dataa = samp_create_sync_data('vehicle')
			--local X, Y, Z = getCharCoordinates(PLAYER_PED)
			lua_thread.create(function()
				while act do wait(0)
					if isCharInAnyCar(PLAYER_PED) then
						if sampIsPlayerConnected(id) then
							printStringNow("VEH SNOSIM: ~r~"..sampGetPlayerNickname(id).."["..id.."]", 1)
						else
							act = false
							print("rvanka off (do you not drive vehicle)")
						end
						dataa.position.x, dataa.position.y, dataa.position.z = px, py, pz - 0.5
						sampForceVehicleSync(sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED)))
					else
						print("rvanka off (do you exit vehicle)")
						msg('вы вышли с авто скрипт оффнут.') 
						act = false
					end
				end
			end)
		else 
			return msg('Сядь в машину ёпта') 
		end
	end)
	sampRegisterChatCommand('snos.of', function(param)	
		if act then return msg('сначала выключите veh рванку! /snos.veh') end
		if act2 then act2 = false return msg('Выключено!') end
		if not param:match('%d+') then return msg('Используй /snos.of [playerID]') end
		id = tonumber(param)
		local _, ped = sampGetCharHandleBySampPlayerId(id)
		if not sampIsPlayerConnected(id) then return msg('Игрока нет на сервере!') end
		if not _ then return msg('Игрока нет в зоне стрима') end
		local localx, localy, localz = getCharCoordinates(ped)
		local ppx, ppy, ppz = getCharCoordinates(PLAYER_PED)
		if getDistanceBetweenCoords3d(localx, localy, localz, ppx, ppy, ppz) > distance_onfoot.v then
			return msg("Жертва {FF0000}"..sampGetPlayerNickname(id).."["..id.."]{ffffff} далеко!")
		end
		if not isCharInAnyCar(PLAYER_PED) then
			msg('Жертва: {FF0000}'..sampGetPlayerNickname(id)..'['..id..'].{ffffff} Начинаем ее рванить!')
			act2 = true
			print("RVANKA IN VEHICLE ON! Target: "..sampGetPlayerNickname(id).."["..id.."]")
			local dataa = samp_create_sync_data('player')
			lua_thread.create(function()
				while act2 do wait(0)
					if not isCharInAnyCar(PLAYER_PED) then
						if sampIsPlayerConnected(id) then
							printStringNow("ONFOOT SNOSIM: ~r~"..sampGetPlayerNickname(id).."["..id.."]", 1)
						else
							act2 = false
							print("rvanka off (onfoot)")
						end
						dataa.position.x, dataa.position.y, dataa.position.z = px, py, pz -- 0.5
						sampForceOnfootSync()
					else
						--imgui.Process = main_window_state.v
						msg('вы сели в машину скрипт оффнут') 
						act2 = false
						print("rvanka off (you enter vehicle)")
					end
				end
			end)
		else 
			return msg('Выйди с машины') 
		end 
	end)
	while true do
        wait(0)
		imgui.Process = main_window_state.v
        if act or act2 then
            result, ped = sampGetCharHandleBySampPlayerId(id)
            if result then
                x, y, z = getCharCoordinates(ped)
                mx, my, mz = getCharCoordinates(PLAYER_PED)
                
                wposX1, wposY1 = convert3DCoordsToScreen(x, y, z)
                wposX2, wposY2 = convert3DCoordsToScreen(mx, my, mz)
           
                if isCharOnScreen(ped) and DrawLine_Target.v or DrawNick_Target.v then 
					renderDrawLine(wposX2, wposY2, wposX1, wposY1, 3, 0xFFFF0000) 
					renderDrawLine(wposX2, wposY2, wposX1, wposY1, 3, 0xFFFF0000)
                    renderDrawPolygon(wposX1, wposY1, 15, 15, 10, 0, 0xFFFF0000)
                    renderDrawPolygon(wposX2, wposY2, 15, 15, 10, 0, 0xFFFF0000)
					
					if DrawNick_Target.v then 
						renderFontDrawText(font,""..sampGetPlayerNickname(id).."["..id.."]",wposX1, wposY1,0xFFFF0000)
					end
					if isCharInAnyCar(PLAYER_PED) and act then
						if getDistanceBetweenCoords3d(x, y, z, mx, my, mz) > distance_veh.v then
							msg("Игрок слишком далеко убежал!")
							act = false
						end
					else if act2 == true then
						if getDistanceBetweenCoords3d(x, y, z, mx, my, mz) > distance_onfoot.v then
							msg("Игрок слишком далеко убежал!")
							act2 = false
							end
						end
					end
				end
			end
		end
	end
end

function hook.onSendVehicleSync(data)
	if act then
		local _, ped = sampGetCharHandleBySampPlayerId(id)
		if not _ then act = false return msg('Игрок: {FF0000}'..sampGetPlayerNickname(id)..'['..id..']{ffffff} сьебався с зоны стрима.') end
		if not sampIsPlayerConnected(id) then act = false return msg('Игрокa {FF0000}'..sampGetPlayerNickname(id)..'['..id..']{ffffff} кикнуло!')end
		local playerX, playerY, playerZ = getCharCoordinates(ped)
		local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
		data.position.x, data.position.y, data.position.z = playerX, playerY, playerZ - 0.5
		playerX, playerY, playerZ = px, py, pz
		data.moveSpeed.x = movespeedX_veh.v
		data.moveSpeed.y = movespeedY_veh.v
		data.moveSpeed.z = movespeedZ_veh.v
		if rv_logs.v then
			print("[VEHICLE] SYNC POS | X: "..myX.." | Y: "..myY.." | Z: "..myZ.."|Target: "..sampGetPlayerNickname(id).."")
			print("[VEHICLE] MoveSpeed: x: "..data.moveSpeed.x.." | y: "..data.moveSpeed.y.." | z: "..data.moveSpeed.z.."|Target: "..sampGetPlayerNickname(id).."")
		end
	elseif act_all == true then
	lua_thread.create(function()
        local x, y, z = getCharCoordinates(PLAYER_PED)
        local result, Ped = findAllRandomCharsInSphere(x, y, z, distance_all.v, true, true)
            if result then
                local x2, y2, z2 = getCharCoordinates(Ped)
                local _, id_all = sampGetPlayerIdByCharHandle(Ped)
                    if isCharInAnyCar(PLAYER_PED) then
                        data.position.x, data.position.y, data.position.z = x2, y2, z2
                        data.moveSpeed.x = movespeedX_veh.v
                        data.moveSpeed.y = movespeedY_veh.v
                        data.moveSpeed.z = movespeedZ_veh.v
                        printStringNow("~g~[RvankaAll]:~y~Target: ~r~"..sampGetPlayerNickname(id_all).."["..id_all.."]", 300)
                    else
                        msg("вы вышли с машины, рванка на всех оффнута.")
					end
				end
			end)
		end
	end

function hook.onSendPlayerSync(data)
	if act2 then
		local _, ped = sampGetCharHandleBySampPlayerId(id)
		if not _ then act2 = false return msg('Игрок: {FF0000}'..sampGetPlayerNickname(id)..'['..id..']{ffffff} сьебався с зоны стрима.') end
		if not sampIsPlayerConnected(id) then act2 = false return msg('Игрокa {FF0000}'..sampGetPlayerNickname(id)..'['..id..']{ffffff} кикнуло!')end
		local playerX, playerY, playerZ = getCharCoordinates(ped)
		local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
		data.position.x, data.position.y, data.position.z = playerX, playerY, playerZ -- 0.5
		playerX, playerY, playerZ = px, py, pz
		data.moveSpeed.x = movespeedX_ofoot.v
		data.moveSpeed.y = movespeedY_ofoot.v
		data.moveSpeed.z = movespeedZ_ofoot.v
		if rv_logs.v then
			print("[ONFOOT] SYNC POS | X: "..myX.." | Y: "..myY.." | Z: "..myZ.."|Target: "..sampGetPlayerNickname(id).."")
			print("[ONFOOT] MoveSpeed: x: "..data.moveSpeed.x.." | y: "..data.moveSpeed.y.." | z: "..data.moveSpeed.z.."|Target: "..sampGetPlayerNickname(id).."")
		end
	end
end

function msg(msg)
	sampAddChatMessage('{6FA8DC}[Snos-Rvanka 0.4]: {ffffff}'..msg..'', -1)
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

function imgui.OnDrawFrame()
	if main_window_state.v then
		GetTheme()
		local xPos, yPos = getScreenResolution() 
		imgui.SetNextWindowPos(imgui.ImVec2(xPos-650, yPos-300), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5)) 
		--imgui.SetNextWindowSize(imgui.ImVec2(410, 295), 1) 
		imgui.SetNextWindowSize(imgui.ImVec2(550, 400), 1) 
		imgui.Begin(u8"Snos-Rvanka 0.4 [BETA] | Автор: Enlizmee.", main_window_state, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar+imgui.WindowFlags.NoMove)
		imgui.GetStyle().WindowTitleAlign.x = 0.5
		if imgui.CollapsingHeader(fa.ICON_FA_CAR..u8"   Vehicle Rvanka") then
			imgui.Text(u8"Рванка с транспорта.")
			
			imgui.SliderFloat(u8'Дистанция ##1', distance_veh, 0.0, 85.0)
			imgui.TextQuestion(u8"Дистанция на которой будет рванить.") 
			
			imgui.SliderFloat('MoveSpeed X ##1', movespeedY_veh, -0.0, 5.0)
			imgui.SliderFloat('MoveSpeed Y ##3', movespeedX_veh, -0.0, 5.0)
			imgui.SliderFloat('MoveSpeed Z ##5', movespeedZ_veh, -0.0, 5.0)
			imgui.Separator()
			
			imgui.Text(u8"Активация /snos.veh [playerID]")
		end
		if imgui.CollapsingHeader(fa.ICON_FA_RUNNING..u8"   OnFoot Rvanka") then
			imgui.Text(u8"Рванка с ног.")
			
			imgui.SliderFloat(u8'Дистанция ##2', distance_onfoot, 0.0, 85.0)
			imgui.TextQuestion(u8"Дистанция на которой будет рванить.") 
			
			imgui.SliderFloat('MoveSpeed X ##2',movespeedX_ofoot, -0.0, 5.0)
			imgui.SliderFloat('MoveSpeed Y ##4', movespeedY_ofoot, -0.0, 5.0)
			imgui.SliderFloat('MoveSpeed Z ##6', movespeedZ_ofoot, -0.0, 5.0)
			imgui.Separator()
			
			imgui.Text(u8"Активация /snos.of [playerID]")
		end
		if imgui.CollapsingHeader(fa.ICON_FA_USERS..u8"   Рванка на всех") then
			imgui.Text(u8"Рванка на всех | работает только с транспорта | настроить скорость в Vehicle Rvanka")
			
			imgui.SliderFloat(u8'Дистанция ##3', distance_all, 0.0, 30.0)
			imgui.TextQuestion(u8"Дистанция на которой искать жертв.") 
			imgui.Separator()
			
			imgui.Text(u8"Активация /snos.all")
		end
		if imgui.CollapsingHeader(fa.ICON_FA_LIST..u8"   Другие Настройки") then
			imgui.Checkbox(u8"Линия к жертве.", DrawLine_Target)
			imgui.TextQuestion(u8"Рисует линию к жертвам.") 
			imgui.Checkbox(u8"Ник/айди жертвы.", DrawNick_Target)
			imgui.TextQuestion(u8"Рисует ник и айди жертвы.") 
			imgui.Checkbox(u8"LOG", rv_logs)
			imgui.TextQuestion(u8"Данная функция позволяет узнать работает ли рванка. показывает ваш мувспид/x,y,z/скорость в консоле сампфункса") 
			if imgui.Combo(u8'Стиль ImGUI', imgui_style, {u8'Обычная тема', u8'Серая тема'}, 2) then
				if imgui_style.v == 0 then
					apply_custom_style()
					mainIni.config.imgui_style = 0
					SaveIni()
				end
				if imgui_style.v  == 1 then
					seriy_theme()
					mainIni.config.imgui_style = 1
					SaveIni()
				end
			end
		end
		if imgui.Button(fa.ICON_FA_SAVE..u8'  Сохранить настройки',imgui.ImVec2(155,65)) then
			msg("Настройки сохранены!")
			SaveIni()
		end
		imgui.TextQuestion(u8"Сохраняет текущие настройки.") 
		if imgui.Button(fa.ICON_FA_EXCLAMATION..u8'  Выгрузить скрипт',imgui.ImVec2(155,65)) then
			thisScript():unload()
		end
		imgui.TextQuestion(u8"Выгружает скрипт.") 
		if imgui.Button(fa.ICON_FA_SYNC..u8'  Перезагрузить скрипт',imgui.ImVec2(155,65)) then
			thisScript():reload()
		end
		imgui.TextQuestion(u8"Перезагружает скрипт.") 
		if imgui.Link(fa.ICON_FA_CLOUD..u8"  ТЕМА НА БЛАСТХАКЕ   "..fa.ICON_FA_CLOUD) then
			os.execute(('explorer.exe "%s"'):format("https://www.blast.hk/threads/88202/"))
        end
		imgui.TextQuestion(u8"ТЕМА НА БЛАСТХАКЕ.") 
		if imgui.Link(fa.ICON_FA_USER..u8"  VK АВТОРА   "..fa.ICON_FA_USER) then
			--os.execute(('explorer.exe "%s"'):format("https://vk.com/notfoundjs"))
        end
		imgui.TextQuestion(u8"ВК АВТОРА СКРИПТА") 
		imgui.End()
	end
end 

function imgui.Link(label, description)

    local size = imgui.CalcTextSize(label)
    local p = imgui.GetCursorScreenPos()
    local p2 = imgui.GetCursorPos()
    local result = imgui.InvisibleButton(label, size)

    imgui.SetCursorPos(p2)

    if imgui.IsItemHovered() then
        if description then
            imgui.BeginTooltip()
            imgui.PushTextWrapPos(600)
            imgui.TextUnformatted(description)
            imgui.PopTextWrapPos()
            imgui.EndTooltip()

        end

        imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.CheckMark], label)
        imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.CheckMark]))

    else
        imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.CheckMark], label)
    end

    return result
end    
		

function apply_custom_style()
   imgui.SwitchContext()
   local style = imgui.GetStyle()
   local colors = style.Colors
   local clr = imgui.Col
   local ImVec4 = imgui.ImVec4
   local ImVec2 = imgui.ImVec2

    colors[clr.Text]                 = ImVec4(0.86, 0.93, 0.89, 0.78)
	colors[clr.TextDisabled]         = ImVec4(0.36, 0.42, 0.47, 1.00)
	colors[clr.WindowBg]             = ImVec4(0.11, 0.15, 0.17, 1.00)
	colors[clr.ChildWindowBg]        = ImVec4(0.15, 0.18, 0.22, 1.00)
	colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
	colors[clr.FrameBgHovered]       = ImVec4(0.12, 0.20, 0.28, 1.00)
	colors[clr.FrameBgActive]        = ImVec4(0.09, 0.12, 0.14, 1.00)
	colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.16, 0.48, 0.42, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.MenuBarBg]            = ImVec4(0.15, 0.18, 0.22, 1.00)
	colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.39)
	colors[clr.ScrollbarGrab]        = ImVec4(0.20, 0.25, 0.29, 1.00)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
	colors[clr.ScrollbarGrabActive]  = ImVec4(0.09, 0.21, 0.31, 1.00)
	colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.CheckMark]              = ImVec4(0.26, 0.98, 0.85, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.24, 0.88, 0.77, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.98, 0.85, 1.00)
	colors[clr.Button]                 = ImVec4(0.26, 0.98, 0.85, 0.30)
	colors[clr.ButtonHovered]          = ImVec4(0.26, 0.98, 0.85, 0.50)
	colors[clr.ButtonActive]           = ImVec4(0.06, 0.98, 0.82, 0.50)
	colors[clr.Header]                 = ImVec4(0.26, 0.98, 0.85, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.26, 0.98, 0.85, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.26, 0.98, 0.85, 1.00)
	colors[clr.Separator]            = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.SeparatorHovered]     = ImVec4(0.60, 0.60, 0.70, 1.00)
	colors[clr.SeparatorActive]      = ImVec4(0.70, 0.70, 0.90, 1.00)
	colors[clr.ResizeGrip]           = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[clr.ResizeGripHovered]    = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.ResizeGripActive]     = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.CloseButton]          = ImVec4(0.40, 0.39, 0.38, 0.16)
	colors[clr.CloseButtonHovered]   = ImVec4(0.40, 0.39, 0.38, 0.39)
	colors[clr.CloseButtonActive]    = ImVec4(0.40, 0.39, 0.38, 1.00)
	colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg]       = ImVec4(0.25, 1.00, 0.00, 0.43)
	colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end
apply_custom_style()

function imgui.TextQuestion(text) 
	local war = u8'Подсказка: '
	if imgui.IsItemHovered() then
		imgui.BeginTooltip()
		imgui.PushTextWrapPos(450)
		imgui.TextColored(imgui.ImVec4(0.00, 0.69, 0.33, 1.00), war)
		imgui.TextUnformatted(text)
		imgui.PopTextWrapPos()
		imgui.EndTooltip()
	end
end


function SaveIni()
	mainIni.config.mX_veh = movespeedX_veh.v
	mainIni.config.mY_veh = movespeedY_veh.v
	mainIni.config.mZ_veh = movespeedZ_veh.v
	mainIni.config.mX_ofoot = movespeedX_ofoot.v
	mainIni.config.mY_ofoot = movespeedY_ofoot.v
	mainIni.config.mZ_ofoot = movespeedZ_ofoot.v
	mainIni.config.line_target = DrawLine_Target.v
	mainIni.config.nick_target = DrawNick_Target.v
	mainIni.config.dist_all = distance_all.v
	mainIni.config.dist_veh = distance_veh.v
	mainIni.config.dist_onfoot = distance_onfoot.v
	mainIni.config.logs = rv_logs.v
	mainIni.config.imgui_style = imgui_style.v
	inicfg.save(mainIni, 'Snos-Rvanka.ini')
end

function hook.onPlayerQuit(playerid, reason) SaveIni() end

function hook.OnSetPlayerPos(position) if act or act2 then return false end end

function seriy_theme()
   imgui.SwitchContext()
   local style = imgui.GetStyle()
   local colors = style.Colors
   local clr = imgui.Col
   local ImVec4 = imgui.ImVec4
   local ImVec2 = imgui.ImVec2

    style.WindowPadding = ImVec2(15, 15)
    style.WindowRounding = 15.0
    style.FramePadding = ImVec2(5, 5)
    style.ItemSpacing = ImVec2(12, 8)
    style.ItemInnerSpacing = ImVec2(8, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 15.0
    style.GrabMinSize = 15.0
    style.GrabRounding = 7.0
    style.ChildWindowRounding = 8.0
    style.FrameRounding = 6.0
  

      colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
      colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
      colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
      colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
      colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
      colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
      colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
      colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
      colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1.00)
      colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
      colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
      colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
      colors[clr.TitleBgActive] = ImVec4(0.08, 0.10, 0.12, 1.00)
      colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
      colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
      colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
      colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
      colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
      colors[clr.ComboBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
      colors[clr.CheckMark] = ImVec4(0.28, 0.56, 1.00, 1.00)
      colors[clr.SliderGrab] = ImVec4(0.28, 0.56, 1.00, 1.00)
      colors[clr.SliderGrabActive] = ImVec4(0.37, 0.61, 1.00, 1.00)
      colors[clr.Button] = ImVec4(0.20, 0.25, 0.29, 1.00)
      colors[clr.ButtonHovered] = ImVec4(0.28, 0.56, 1.00, 1.00)
      colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1.00)
      colors[clr.Header] = ImVec4(0.20, 0.25, 0.29, 0.55)
      colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.80)
      colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1.00)
      colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
      colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
      colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
      colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
      colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
      colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
      colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
      colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
      colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
      colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
      colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
      colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end
seriy_theme()

function GetTheme()
  if mainIni.config.imgui_style == 0 then apply_custom_style()
  elseif mainIni.config.imgui_style == 1 then seriy_theme() end
end
GetTheme()