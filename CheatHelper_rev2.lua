script_name("CheatHelper")
script_version("rev2")
script_author("Kiko")

local sampev = require("lib.samp.events")
local imgui = require("imgui")
local encoding = require("encoding")
local sw, sh = getScreenResolution()


local dlstatus = require("moonloader").download_status

encoding.default = "CP1251"
u8 = encoding.UTF8



local directjson = "moonloader\\cheatsdescription.json"
local mainJson = io.open(directjson)
local jsonData = decodeJson(mainJson:read('*a'))
mainJson:close()

update_status = false

local script_vers = 12
local script_vers_text = "2.00.00 alfa"

local update_url = "https://raw.githubusercontent.com/BadKiko/SAMP-Sborka-by-Kiko/main/moonloader/updateCheatHelp.ini"
local update_path = getWorkingDirectory().."/updateCheatHelp.ini"

local script_url = "https://raw.githubusercontent.com/BadKiko/SAMP-Sborka-by-Kiko/main/moonloader/CheatHelper.lua"
local script_path = thisScript().path

------------------------

local filter = imgui.ImBuffer(256)


local menu_window_state = imgui.ImBool(false) --статус main окна

function main()

	repeat wait(0) until isSampLoaded() and isSampAvailable()

	wait(0)
	sampAddChatMessage(" ")
	sendMessage("Created {464446}by{EA5455} Kiko")
	sendMessage("{464446}Открыть окно помощника - {EA5455}/chelp")
	logo = imgui.CreateTextureFromFile('moonloader/resource/cheathelper/logo.jpg')
	imgui.Process = true
	imgui.Process =  menu_window_state.v
	


	--UPDATE

--	downloadUrlToFile(update_url, update_path, function(id, status)
	--	if status == dlstatus.STATUS_ENDDOWNLOADDATA then
	--		updateIni = inicfg.load(nil,update_path)
	--		if tonumber(updateIni.script_info.vers) > script_vers then
	--			sendMessage("Dungeon Master нашел обновление! Обновляем {464446}<CheatHelper>{850AB9} до версии:{464446} "..updateIni.script_info.vers_text)
--				update_status = true
--			else
---				sendMessage("Slave, ты красавец, у тебя последняя версия {464446}<CheatHelper> - "..updateIni.script_info.vers_text.."!")
--			end
--		end
--	end)



	sampRegisterChatCommand("chelp", function()
		menu_window_state.v = not menu_window_state.v
		imgui.Process =  menu_window_state.v
	end)

	while true do
		wait(0)
		--прячем показываем курсор
		if menu_window_state.v == false then
			imgui.ShowCursor = false
		else
			imgui.ShowCursor = true
		end
		
		if(isKeyJustPressed(72) and isKeyJustPressed(18)) then
			menu_window_state.v = not menu_window_state.v
			imgui.Process =  menu_window_state.v
		end


		--Update

		if update_status then
			downloadUrlToFile(script_url, script_path, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					sendMessage("Dungeon Master успешно обновил {464446}<CheatHelper>!")
					thisScript():reload()
				end
			end)
			break
		end

	end
end


--Рисуем меню
function imgui.OnDrawFrame()
	--Main меню
	if menu_window_state.v then
		imgui.SetNextWindowPos(imgui.ImVec2((sw / 2) + 300, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin("[CheatHelper] by Kiko | Version: "..script_vers_text, menu_window_state, imgui.WindowFlags.AlwaysAutoResize)
		apply_custom_style()

		imgui.Image(logo, imgui.ImVec2(sw/4, sh/12))

		imgui.Text(u8'Обновленная сучка готова к использованию:')
		imgui.Separator()

		------ ЗДЕСЬ ВСЕ ЧИТЫ

		--ЕСЛИ НЕ ИСПОЛЬЗУЕТСЯ ФИЛЬТР
		if filter.v == '' then

			--ЦИКЛ ПРОХОДИТСЯ ПО ВСЕМ КАТЕГОРИЯМ - ПЕРЕМЕННАЯ J - текущая категория
			for j=1,getListLength(jsonData['cheats']) do

				if imgui.TreeNode(u8(jsonData['cheats'][j]['categoryname'])) then

					--ЦИКЛ ПРОХОДИТСЯ ПО ВСЕМ ЧИТАМ В КАТЕГОРИИ - ПЕРЕМЕННАЯ I - текущий чит
					for i=1,getListLength(jsonData['cheats'][j]['name']) do

						if imgui.TreeNode(u8(jsonData['cheats'][j]['name'][i])) then
							imgui.Separator()
							imgui.Text(u8' Название скрипта: '..u8(jsonData['cheats'][j]['name'][i]))
							imgui.Separator()
							imgui.Text(u8' Использование:')
							for k=1,getSymbolLength(u8(jsonData['cheats'][j]['usage'][i]), '&')-1 do ---Команды которые прописываются в чат как заготовка
								if(imgui.Button(spliutOnButtons(u8(jsonData['cheats'][j]['usage'][i]), '&')[k+1])) then
									sampSetChatInputText(spliutOnButtons(u8(jsonData['cheats'][j]['usage'][i]), '&')[k+1])
									sampSetChatInputEnabled(true)
								end
							end
							for k=1,getSymbolLength(u8(jsonData['cheats'][j]['usage'][i]), '!')-1 do --Команды которые сразу выполняются
								if(imgui.Button(spliutOnButtons(u8(jsonData['cheats'][j]['usage'][i]), '!')[k])) then
									sampProcessChatInput(spliutOnButtons(u8(jsonData['cheats'][j]['usage'][i]), '!')[k])
								end
							end
							imgui.Separator()
							imgui.Text(u8' Описание: '..(string.gsub(u8(jsonData['cheats'][j]['description'][i]), "|", "\n")))
							imgui.Separator()
							imgui.Text(u8' Автор: '..u8(jsonData['cheats'][j]['author'][i]))
							imgui.TreePop()
						end

					end
					imgui.TreePop()
				end

			end
		--ЕСЛИ ИСПОЛЬЗУЕТСЯ ФИЛЬТР
		else
			for j=1,getListLength(jsonData['cheats']) do
				for i=1,getListLength(jsonData['cheats'][j]['name']) do
					if string.lower(u8(jsonData['cheats'][j]['name'][i])):find(string.lower(filter.v))
					or string.lower(u8(jsonData['cheats'][j]['description'][i])):find(string.lower(filter.v))
					or string.lower(u8(jsonData['cheats'][j]['usage'][i])):find(string.lower(filter.v))
					or string.lower(u8(jsonData['cheats'][j]['author'][i])):find(string.lower(filter.v)) then --ЗДЕСЬ ИДЕТ ПОИСК ПО ИМЕНИ ЧИТА, ОПИСАНИЮ, КОММАНДАМ, АВТОРАМ
						if imgui.TreeNode(u8(jsonData['cheats'][j]['name'][i])) then
							imgui.Separator()
							imgui.Text(u8' Название скрипта: '..u8(jsonData['cheats'][j]['name'][i]))
							imgui.Separator()
							imgui.Text(u8' Использование:')
							for k=1,getSymbolLength(u8(jsonData['cheats'][j]['usage'][i]), '&') do
								imgui.Button(spliutOnButtons(u8(jsonData['cheats'][j]['usage'][i]), '&')[k])
							end
							imgui.Separator()
							imgui.Text(u8' Описание: '..(string.gsub(u8(jsonData['cheats'][j]['description'][i]), "|", "\n")))
							imgui.Separator()
							imgui.Text(u8' Автор: '..u8(jsonData['cheats'][j]['author'][i]))
							imgui.TreePop()
						end
					end
				end
			end
		end
		
		imgui.Separator()
		imgui.Text(u8'Найти чит:')
		imgui.InputText('', filter)
		
		----------------------------------------------------

		imgui.End()
	end
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
	style.GrabMinSize = 15.0
	style.GrabRounding = 12.0

	colors[clr.Text]                   = ImVec4(0.92, 0.33, 0.33, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border]                 = ImVec4(0.92, 0.33, 0.33, 0.38)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg]                = ImVec4(0.20, 0.20, 0.20, 0.54)
	colors[clr.FrameBgHovered]         = ImVec4(0.17, 0.17, 0.17, 0.54)
	colors[clr.FrameBgActive]          = ImVec4(0.24, 0.24, 0.24, 0.67)
	colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.07, 0.07, 0.07, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.16, 0.16, 0.16, 0.86)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.22, 0.22, 0.22, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.29, 0.29, 0.29, 1.00)
	colors[clr.CheckMark]              = ImVec4(0.92, 0.33, 0.33, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.92, 0.33, 0.33, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.12, 0.12, 0.12, 1.00)
	colors[clr.Button]                 = ImVec4(0.37, 0.37, 0.37, 0.27)
	colors[clr.ButtonHovered]          = ImVec4(0.16, 0.16, 0.16, 0.54)
	colors[clr.ButtonActive]           = ImVec4(0.20, 0.20, 0.20, 0.54)
	colors[clr.Header]                 = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.HeaderHovered]          = ImVec4(0.17, 0.17, 0.17, 0.45)
	colors[clr.HeaderActive]           = ImVec4(0.23, 0.23, 0.23, 0.41)
	colors[clr.Separator]              = ImVec4(0.29, 0.29, 0.29, 0.50)
	colors[clr.SeparatorHovered]       = ImVec4(0.29, 0.29, 0.29, 0.50)
	colors[clr.SeparatorActive]        = ImVec4(0.29, 0.29, 0.29, 0.50)
	colors[clr.ResizeGrip]             = ImVec4(0.92, 0.33, 0.33, 1.00)
	colors[clr.ResizeGripHovered]      = ImVec4(0.92, 0.33, 0.33, 1.00)
	colors[clr.ResizeGripActive]       = ImVec4(0.92, 0.33, 0.33, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.25, 0.25, 0.25, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
	colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
	colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
	colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
	
end

function sendMessage(text)
	tag = '{464446}[Cheat{EA5455}Helper{464446}]: {EA5455}'
	sampAddChatMessage(tag .. text, -1)
end

--Возвращает длинну массива
function getListLength(table)
	local len = 0
	for _ in pairs(table) do
		len = len + 1 
	end
	return len
end

--Возвращает количество символов в строке
function getSymbolLength(text, symbol)
	local value = 0
	while string.find(text, symbol) do
		text = text:gsub(symbol, "", 1)
		value = value + 1
		if value>=1000 then
			break
		end
	end
	return value 
end

function spliutOnButtons (inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end