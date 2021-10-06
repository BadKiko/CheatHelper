script_name("Pass Ban")
script_author("seven.")

require "moonloader"
local samp = require("samp.events")
local ffi = require("ffi")
local memory = require("memory")

local act = false
local ACWait = 10
local seat = 1

function main()
    repeat wait(0) until isSampAvailable()
    sampAddChatMessage("Pass Fly Loaded. Author: seven. (vk.com/nanseven)", -1)
    sampRegisterChatCommand("pcar", PassAct)
    sampRegisterChatCommand("seat", function(arg) 
        if tonumber(arg) then 
            carId = tonumber(arg) 
            local res, carHandle = sampGetCarHandleBySampVehicleId(carId) 
            if res then 
                local x, y, z = getCarCoordinates(carHandle) 
                lua_thread.create(function() 
                    setCharCoordinates(PLAYER_PED, x, y, z) 
                    wait(300) 
                    sampSendEnterVehicle(carId, 1) 
                    wait(800) 
                    warpCharIntoCarAsPassenger(PLAYER_PED, carHandle, 0) 
                end) 
            end 
        end 
    end)
    while true do
        wait(0)
        if act then
            if isCharInAnyCar(PLAYER_PED) then
                local playerPos = {getCharCoordinates(PLAYER_PED)}
                local handleCar = storeCarCharIsInNoSave(PLAYER_PED)
                local _, vehId = sampGetVehicleIdByCarHandle(handleCar)
                local fX, fY, fZ = getActiveCameraCoordinates()
                local zX, zY, zZ = getActiveCameraPointAt()

                local heading = getHeadingFromVector2d(zX - fX, zY - fY)
                setCarHeading(handleCar, heading)

                if not sampIsCursorActive() then
                    local currentHead = getCarHeading(handleCar)
                    if isKeyDown(0x57) then
                        local speedX = math.sin(-math.rad(heading)) * 1.1
                        local speedY = math.cos(-math.rad(heading)) * 1.1
                        setVehicleMoveSpeed(handleCar, speedX, speedY, 0.0)
                    end

                    if isKeyDown(0x53) then
                        setVehicleMoveSpeed(handleCar, 0.0, 0.0, 0.0)
                    end

                    if isKeyDown(0x20) then
                        local speedX, speedY, speedZ = getVehicleMoveSpeed(handleCar)
                        setVehicleMoveSpeed(handleCar, speedX, speedY, 0.3)
                    end

                    if isKeyDown(0xA0) then
                        local speedX, speedY, speedZ = getVehicleMoveSpeed(handleCar)
                        setVehicleMoveSpeed(handleCar, speedX, speedY, -0.3)
                    end
                end
                printStringNow("Vehicle: ~r~" .. vehId .. "~w~ | Seat: ~r~" .. seat, 1000)
                SendSync(vehId, getCharHealth(PLAYER_PED), getCharArmour(PLAYER_PED), playerPos[1], playerPos[2], playerPos[3], getCarHealth(storeCarCharIsInNoSave(PLAYER_PED)))
                wait(ACWait)
            else
                act = false
                sampAddChatMessage("auto disable", -1)
            end
        end
    end
end

function setVehicleMoveSpeed(handle, x, y, z)
    local ptr = getCarPointer(handle)
    if ptr ~= 0 then
        ffi.cast("void (__thiscall *)(uint32_t, float, float, float)", 0x441130)(ptr, x, y, z)
    end
end

function getVehicleMoveSpeed(handle)
    local ptr = getCarPointer(handle)
    if ptr ~= 0 then
        local X = memory.getfloat(ptr + 0x44, true)
        local Y = memory.getfloat(ptr + 0x44 + 0x4, true)
        local Z = memory.getfloat(ptr + 0x44 + 0x8, true)
        return X, Y, Z
    end
end

function samp.onSendPassengerSync(sync)
    seat = sync.seatId
end

function onSendPacket(id, bitstream)
	if act then
		return false
	end
end

function SendSync(vehicleId, health, armor, x, y, z, vehicleHealth)
    local data = samp_create_sync_data("passenger")
    data.vehicleId = vehicleId
    data.seatId = seat
    data.health = health
    data.armor = armor
    data.position = {x, y, z}
    data.send()

    local heading = getCharHeading(PLAYER_PED)

    local data = samp_create_sync_data("unoccupied")
    data.vehicleId = vehicleId
    data.seatId = seat
    data.roll = {0.1, 0.2, 0.3}
    data.direction = {-0.04, -0.9, -0.04}
    data.position = {x, y, z}
    data.moveSpeed.x = math.sin(-math.rad(heading)) * 0.1
    data.moveSpeed.y = math.cos(-math.rad(heading)) * 0.2
    data.moveSpeed.z = 0.5
    data.turnSpeed = {-0.1, -0.2, -0.3}
    data.vehicleHealth = vehicleHealth
    data.send()
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
    -- from SAMP.Lua
    local raknet = require 'samp.raknet'
    require 'samp.synchronization'

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

function PassAct()
    if isCharInAnyCar(PLAYER_PED) then
        act = not act
        sampAddChatMessage(string.format("Hack: %s", act and "ON" or "OFF"), -1)
    else
        sampAddChatMessage("Seat to the vehicle (passenger)", -1)
    end
end