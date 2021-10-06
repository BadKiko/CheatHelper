require "moonloader"
local ev = require ("lib.samp.events")
local vk = require ("vkeys")
local imgui = require ("imgui")
local fa = require ('fAwesome5')
local inicfg = require ("inicfg")
local encoding = require ("encoding")
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local dlstatus = require("moonloader").download_status
imgui.Process = false
local id = nil
local state = 1

local update = {
	check_upd_ver = 1.0, -- нынишняя версия скрипта.

	script_upd = "", -- ссылка на обновление скрипта.
	script_ver = nil, -- новая версия скрипта.
	script_path = thisScript().path, -- местоположение скрипта.

	update_url = "https://raw.githubusercontent.com/Scar4ik64/onFoot-Rv/main/update.ini", -- ссылка на кфг проверки обновления.
	update_path = getWorkingDirectory().."\\config\\update.ini" -- местоположение файла для кфг с новой версией.
}

local onfoot = {
	window = imgui.ImBool(false),

	moveSpeedX = imgui.ImFloat(0),
	moveSpeedY = imgui.ImFloat(0),
	moveSpeedZ = imgui.ImFloat(1.3),
	Dist = imgui.ImFloat(100),
	rvPlayer = imgui.ImBool(false),
	rvSpeed = imgui.ImFloat(1.3),

	rainbow = imgui.ImBool(false),
	speed_rainbow = imgui.ImInt(3),

	rvankaQuaternion = imgui.ImBool(false),
	qX = imgui.ImFloat(0),
	qY = imgui.ImFloat(0),
	qZ = imgui.ImFloat(0),
	qW = imgui.ImFloat(0),

	rand_X_Y = imgui.ImBool(false),
	randFloat = imgui.ImFloat(0.3),

	nopSetPlayerPos = imgui.ImBool(false)
}

function main()
	repeat wait(0) until isSampAvailable()
	iniLoad() updateRV()
	sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Скрипт Загружен")
	sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}| Меню: {DD8900}/ofr {E6E6E6}| {DD8900}/ofr.r [ ID жертвы ] {E6E6E6}| {DD8900}/ofr.r all")
	sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Авторы скрипта: {FF187D}Scar {E6E6E6}и {FF187D}Nomio")
	sampRegisterChatCommand("ofr", function()
		onfoot.window.v = not onfoot.window.v
		imgui.Process = onfoot.window.v
	end)
	sampRegisterChatCommand("ofr.r", function(param)
		if eb or eb_all then eb = false eb_all = false end

		if tonumber(param) then
			id = tonumber(param)
			eb = true
			sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Рваним - {FF0000}"..param, -1)
		elseif param == "all" then
			eb_all = true
			sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}ВСЕХ :D", -1)
		elseif param == '' then
			id = nil
			eb = false
			eb_all = false
			sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Скрипт выключился.")
		end
	end)
	while true do wait(0)
		if onfoot.rainbow.v then imgui.SwitchContext() theme() end
		if onfoot.window.v == false then imgui.Process = false end
		if state == 3 then sampForceOnfootSync() state = 1 end

		if upd_script then
			downloadUrlToFile(update.script_upd, update.script_upd, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Скрипт Автоматически обновился, новая версия скрипта: [ v"..tonumber(update.script_ver).." ]")
					thisScript():reload() script_upd = false
				end
			end)
		end

	end
end

function imgui.OnDrawFrame()
	if onfoot.window.v then

		if not onfoot.rainbow.v then imgui.SwitchContext() theme() end

		local sizeX, sizeY = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(380, 578), imgui.Cond.FirstUseEver)

		imgui.Begin(fa.ICON_FA_MARS..u8" OnFoot Rvanka "..fa.ICON_FA_MARS, onfoot.window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
			imgui.BeginChild(u8"Child1", imgui.ImVec2(364, 492), true)

				imgui.Checkbox(fa.ICON_FA_LOCK..u8" NOP onSetPlayerPos", onfoot.nopSetPlayerPos)
				imgui.TextQuestion(u8"Не дает изменять серверу ващу позицию.")
				imgui.Checkbox(fa.ICON_FA_RAINBOW..u8" Радуга ", onfoot.rainbow) imgui.SameLine() imgui.PushItemWidth(236) imgui.SliderInt(u8"##speed__rainbow", onfoot.speed_rainbow, 1, 30) imgui.PopItemWidth()
				imgui.TextQuestion(u8"Изменяет цвет имуги окна.")
				imgui.NewLine()
				imgui.Checkbox(fa.ICON_FA_SQUARE_ROOT_ALT..u8" Рванить по кватернион",onfoot.rvankaQuaternion)
				imgui.TextQuestion(u8"Изменяет вращение персонажу,помогает рванке немного зацепить игрока.")
				imgui.SliderFloat(u8"quatX", onfoot.qX, 0, 3) imgui.SameLine(292) imgui.PushItemWidth(66) imgui.InputFloat(u8"##inputfloat4", onfoot.qX) imgui.PopItemWidth()
				imgui.SliderFloat(u8"quatY", onfoot.qY, 0, 3) imgui.SameLine(292) imgui.PushItemWidth(66) imgui.InputFloat(u8"##inputfloat5", onfoot.qY) imgui.PopItemWidth()
				imgui.SliderFloat(u8"quatZ", onfoot.qZ, 0, 3) imgui.SameLine(292) imgui.PushItemWidth(66) imgui.InputFloat(u8"##inputfloat6", onfoot.qZ) imgui.PopItemWidth()
				imgui.SliderFloat(u8"quatW", onfoot.qW, 0, 3) imgui.SameLine(292) imgui.PushItemWidth(66) imgui.InputFloat(u8"##inputfloat7", onfoot.qW) imgui.PopItemWidth()
				imgui.NewLine()
				imgui.Checkbox(fa.ICON_FA_USER..u8" Рванить в Педа ", onfoot.rvPlayer)
				imgui.TextQuestion(u8"Вычесление угла перса.")
				imgui.PushItemWidth(220) imgui.SliderFloat(u8"##slider1", onfoot.rvSpeed, 0.1, 10) imgui.PopItemWidth()
				imgui.NewLine()
				imgui.Checkbox(fa.ICON_FA_MAP_MARKER..u8" Random X, Y", onfoot.rand_X_Y)
				imgui.TextQuestion(u8"Рандомить кординаты X,Y.")
				imgui.SliderFloat(u8"##slider2", onfoot.randFloat, -3, 3)
				imgui.NewLine()
				imgui.SliderFloat(u8"X ", onfoot.moveSpeedX, -10, 10) imgui.SameLine() imgui.PushItemWidth(92) imgui.InputFloat(u8"##inputfloat1", onfoot.moveSpeedX) imgui.PopItemWidth()
				imgui.SliderFloat(u8"Y ", onfoot.moveSpeedY, -10, 10) imgui.SameLine() imgui.PushItemWidth(92) imgui.InputFloat(u8"##inputfloat2", onfoot.moveSpeedY) imgui.PopItemWidth()
				imgui.SliderFloat(u8"Z ", onfoot.moveSpeedZ, -10, 10) imgui.SameLine() imgui.PushItemWidth(92) imgui.InputFloat(u8"##inputfloat3", onfoot.moveSpeedZ) imgui.PopItemWidth()
				imgui.NewLine()
				imgui.PushItemWidth(272) imgui.SliderFloat(u8"Дистанция", onfoot.Dist, 1, 300) imgui.PopItemWidth()
			imgui.EndChild(Child1)

			if imgui.Button(fa.ICON_FA_SAVE..u8" Сохранить", imgui.ImVec2(364, 40)) then
				iniSave()
				sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Скрипт сохранил настройки.")
			end

		imgui.End()

	end
end

function ev.onSendPlayerSync(data)
	lua_thread.create(function()
		if eb then
			local _, handlePed = sampGetCharHandleBySampPlayerId(id)
			if _ then
				local x, y, z = getCharCoordinates(PLAYER_PED)
				local x1, y1, z1 = getCharCoordinates(handlePed)
				local distance = getDistanceBetweenCoords3d(x, y, z, x1, y1, z1)

				if state == 1 and distance <= onfoot.Dist.v then

					if onfoot.rvPlayer.v then

						if onfoot.rvPlayer.v then
							local heading = getHeadingFromVector2d(x1-x,y1-y)
							data.moveSpeed = {x = math.sin(-math.rad(heading)) * onfoot.rvSpeed.v, y = math.cos(-math.rad(heading)) * onfoot.rvSpeed.v, z = -0.60}
							data.position = {x1, y1, z1}
						end

					else

						if onfoot.rvankaQuaternion.v then
							data.quaternion[0] = math.random(-onfoot.qX.v, onfoot.qX.v)
							data.quaternion[1] = math.random(-onfoot.qY.v, onfoot.qY.v)
							data.quaternion[2] = math.random(-onfoot.qZ.v, onfoot.qZ.v)
							data.quaternion[3] = math.random(-onfoot.qW.v, onfoot.qW.v)
						else
							data.quaternion[0] = 0
							data.quaternion[1] = 0
							data.quaternion[2] = 0
							data.quaternion[3] = 0
						end

						data.moveSpeed.x = onfoot.moveSpeedX.v
						data.moveSpeed.y = onfoot.moveSpeedY.v
						data.moveSpeed.z = onfoot.moveSpeedZ.v

						if not onfoot.rand_X_Y.v then
							data.position = {x1, y1, z1}
						else
							data.position = {x1-math.random(-onfoot.randFloat.v,onfoot.randFloat.v), y1+math.random(-onfoot.randFloat.v,onfoot.randFloat.v), z1}
						end
					end

				elseif state == 2 then
					state = 3
				end

				printStringNow("~r~OnFoot - ~w~"..sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(handlePed))), 100)
			end
			return data
		elseif eb_all then
			local x, y, z = getCharCoordinates(PLAYER_PED)
			local _, handlePed = findAllRandomCharsInSphere(x, y, z, onfoot.Dist.v, true, true)
			if _ then
				local x1, y1, z1 = getCharCoordinates(handlePed)
				local _, id_all = sampGetPlayerIdByCharHandle(handlePed)

				if state == 1 then

					if onfoot.rvPlayer.v then

						local heading = getHeadingFromVector2d(x1-x,y1-y)
						data.moveSpeed = {x = math.sin(-math.rad(heading)) * onfoot.rvSpeed.v, y = math.cos(-math.rad(heading)) * onfoot.rvSpeed.v, z = 0.25}
						data.position = {x1, y1, z1}

					else

						if onfoot.rvankaQuaternion.v then
							data.quaternion[0] = math.random(-onfoot.qX.v, onfoot.qX.v)
							data.quaternion[1] = math.random(-onfoot.qY.v, onfoot.qY.v)
							data.quaternion[2] = math.random(-onfoot.qZ.v, onfoot.qZ.v)
							data.quaternion[3] = math.random(-onfoot.qW.v, onfoot.qW.v)
						else
							data.quaternion[0] = 0
							data.quaternion[1] = 0
							data.quaternion[2] = 0
							data.quaternion[3] = 0
						end

						data.moveSpeed.x = onfoot.moveSpeedX.v
						data.moveSpeed.y = onfoot.moveSpeedY.v
						data.moveSpeed.z = onfoot.moveSpeedZ.v

						if not onfoot.rand_X_Y.v then
							data.position = {x1, y1, z1}
						else
							data.position = {x1-math.random(-onfoot.randFloat.v,onfoot.randFloat.v), y1+math.random(-onfoot.randFloat.v,onfoot.randFloat.v), z1}
						end
					end
				elseif state == 2 then
					state = 3
				end
				printStringNow("~r~OnFoot - ~w~"..sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(handlePed))), 100)
			end
			return data
		end
	end)
end

function iniLoad()
	mainIni = inicfg.load(nil, "OnFoot_Rvanka.ini")
	if mainIni == nil then
		iniSave()
	else
		onfoot.moveSpeedX.v = mainIni.config.moveX
        onfoot.moveSpeedY.v = mainIni.config.moveY
		onfoot.moveSpeedZ.v = mainIni.config.moveZ
		onfoot.rvPlayer.v = mainIni.config.rvPed
		onfoot.Dist.v = mainIni.config.dist
		onfoot.rainbow.v = mainIni.config.rainbow
		onfoot.speed_rainbow.v = mainIni.config.speed_rainbow
		onfoot.rvankaQuaternion.v = mainIni.config.rvankaQuaternion
		onfoot.qX.v = mainIni.config.qX
		onfoot.qY.v = mainIni.config.qY
		onfoot.qZ.v = mainIni.config.qZ
		onfoot.qW.v = mainIni.config.qW
		onfoot.rand_X_Y.v = mainIni.config.randXY
		onfoot.randFloat.v = mainIni.config.randomFloatXY
		onfoot.nopSetPlayerPos.v = mainIni.config.NOP_onSetPlayerPos
	end
end

function iniSave()
	inicfg.save({
		config = {
            moveX = onfoot.moveSpeedX.v,
			moveY = onfoot.moveSpeedY.v,
			moveZ = onfoot.moveSpeedZ.v,
			dist = onfoot.Dist.v,
			rvPed = onfoot.rvPlayer.v,
			rainbow = onfoot.rainbow.v,
			speed_rainbow = onfoot.speed_rainbow.v,
			rvankaQuaternion = onfoot.rvankaQuaternion.v,
			qX = onfoot.qX.v,
			qY = onfoot.qY.v,
			qZ = onfoot.qZ.v,
			qW = onfoot.qW.v,
			randXY = onfoot.rand_X_Y.v,
			randomFloatXY = onfoot.randFloat.v,
			NOP_onSetPlayerPos = onfoot.nopSetPlayerPos.v
		}
	}, "OnFoot_Rvanka.ini")
end

function ev.onSetPlayerPos()
	if onfoot.nopSetPlayerPos.v then return false end
end

function ev.onPlayerDeath(playerId)
	if eb then
		if playerId == id then
			eb = false
			sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Игрок в больнице, скрипт автоматически выключился.")
		end
	elseif eb_all then
		if playerId == id_all then
			eb_all = false
			sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Игрок в больнице: "..sampGetPlayerNickname(id_all))
		end
	end
end

function ev.onPlayerQuit(playerId)
	if eb then
		if playerId == id then
			eb = false
			sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Игрок был кикнут, скрипт автоматически выключился.")
		end
	elseif eb_all then
		if playerId == id_all then
			sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Игрок был кикнут: "..sampGetPlayerNickname(id_all))
		end
	end
end

function updateRV()
	downloadUrlToFile(update.update_url, update.update_path, function(id, status)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			updateIni = inicfg.load(nil, update.update_path)
			if updateIni.version.ver ~= update.check_upd_ver then
				upd_script = true
				sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Найдено обновление скрипта: [ "..updateIni.version.ver.." ], начинаю Авто-Обновление.")
			else
				upd_script = false
				sampAddChatMessage("{FF9E00}[{FF5555}OnFoot Rvanka{FF9E00}]: {E6E6E6}Обновлений не найдено, у вас последнее обновление.")
			end
		end
	end)
end

function rainbow(speed, alpha)
    return math.floor(math.sin(os.clock() * speed) * 127 + 128), math.floor(math.sin(os.clock() * speed + 2) * 127 + 128), math.floor(math.sin(os.clock() * speed + 4) * 127 + 128), alpha
end

function join_argb(a, r, g, b)
    local argb = b
    argb = bit.bor(argb, bit.lshift(g, 8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function imgui.TextQuestion(text)
	imgui.SameLine()
	imgui.TextDisabled('[?]')
	if imgui.IsItemHovered() then
		imgui.BeginTooltip()
		imgui.PushTextWrapPos(450)
		imgui.TextUnformatted(text)
		imgui.PopTextWrapPos()
		imgui.EndTooltip()
	end
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

local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig() -- to use 'imgui.ImFontConfig.new()' on error
        font_config.MergeMode = true

        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
    end
end

function theme()
	local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

	local r,g,b,a = rainbow(onfoot.speed_rainbow.v, 255)
	local argb = join_argb(a, r, g, b)
    local a = a / 255
    local r = r / 255
    local g = g / 255
    local b = b / 255

	style.WindowPadding = imgui.ImVec2(8, 8)
	style.WindowRounding = 8.0
	style.FramePadding = imgui.ImVec2(4, 4)
	style.ItemSpacing = imgui.ImVec2(4, 4)
	style.ItemInnerSpacing = imgui.ImVec2(8, 6)
	style.IndentSpacing = 21
	style.ScrollbarSize = 10
	style.ScrollbarRounding = 8
	style.GrabMinSize = 12
	style.GrabRounding = 3
	style.FrameRounding = 6.0
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

	if not onfoot.rainbow.v then
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.16, 0.48, 0.42, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.24, 0.88, 0.77, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.26, 0.98, 0.85, 0.80)
        colors[clr.Header]                 = ImVec4(0.26, 0.98, 0.85, 0.31)
        colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00)
		colors[clr.Button]                 = ImVec4(0.26, 0.98, 0.85, 0.30)
    else
        colors[clr.TitleBg]                = ImVec4(r, g, b, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(r, g, b, 1.00)
        colors[clr.CheckMark]              = ImVec4(r, g, b, 1.00)
        colors[clr.SliderGrab]             = ImVec4(r, g, b, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(r, g, b, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(r, g, b, 1.00)
        colors[clr.Header]                 = ImVec4(r, g, b, 0.31)
        colors[clr.HeaderHovered]          = ImVec4(r, g, b, 0.80)
		colors[clr.ScrollbarGrabHovered]   = ImVec4(r, g, b, 1.00)
		colors[clr.Button]   			   = ImVec4(r, g, b, 1.00)
    end

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
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.MenuBarBg]            = ImVec4(0.15, 0.18, 0.22, 1.00)
	colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.39)
	colors[clr.ScrollbarGrab]        = ImVec4(0.20, 0.25, 0.29, 1.00)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
	colors[clr.ScrollbarGrabActive]  = ImVec4(0.09, 0.21, 0.31, 1.00)
	colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.ButtonHovered]          = ImVec4(0.26, 0.98, 0.85, 0.50)
	colors[clr.ButtonActive]           = ImVec4(0.06, 0.98, 0.82, 0.50)
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
theme()
