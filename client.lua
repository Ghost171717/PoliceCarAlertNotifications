local detectionEnabled = false
local detectionDistance = 50.0
local isInPoliceVehicle = false

-- Entity enumerator
local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
        enum.destructor = nil
        enum.handle = nil
    end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end
        local enum = {handle = iter, destructor = disposeFunc}
        setmetatable(enum, entityEnumerator)
        local next = true
        repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
        until not next
        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end

local function EnumeratePeds()
    return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

local function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

local function IsPedInPoliceVehicle(ped)
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            return GetVehicleClass(veh) == 18 -- Emergency
        end
    end
    return false
end

-- Main detection thread
CreateThread(function()
    while true do
        Wait(800)
        local ped = PlayerPedId()
        isInPoliceVehicle = IsPedInPoliceVehicle(ped)

        if detectionEnabled and isInPoliceVehicle then
            local myVeh = GetVehiclePedIsIn(ped, false)
            local playerCoords = GetEntityCoords(ped)

            for veh in EnumerateVehicles() do
                if veh ~= myVeh then
                    local vehCoords = GetEntityCoords(veh)
                    if #(vehCoords - playerCoords) <= detectionDistance then
                        TriggerEvent("police:vehicleApproaching", veh)
                    end
                end
            end

            for p in EnumeratePeds() do
                if not IsPedAPlayer(p) then
                    local pCoords = GetEntityCoords(p)
                    if #(pCoords - playerCoords) <= detectionDistance then
                        TriggerEvent("police:pedApproaching", p)
                    end
                end
            end
        end
    end
end)

-- Notifications + sounds
AddEventHandler("police:vehicleApproaching", function(veh)
    local plate = GetVehicleNumberPlateText(veh)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(("~b~Vehicle Detected:~s~ %s (%s)"):format(model, plate))
    EndTextCommandThefeedPostTicker(false, true)
    PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
end)

AddEventHandler("police:pedApproaching", function(ped)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName("~y~Pedestrian Detected Nearby")
    EndTextCommandThefeedPostTicker(false, true)
    PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
end)

-- NUI callbacks
RegisterNUICallback("toggleDetection", function(data, cb)
    detectionEnabled = data.state and true or false
    cb("ok")
end)

RegisterNUICallback("setDistance", function(data, cb)
    local dist = tonumber(data.distance) or detectionDistance
    dist = math.max(10.0, math.min(200.0, dist))
    detectionDistance = dist
    cb("ok")
end)

RegisterNUICallback("escape", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Command to open UI
RegisterCommand("policeui", function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openUI",
        enabled = detectionEnabled,
        distance = detectionDistance
    })
end, false)

RegisterKeyMapping("policeui", "Open Police Detector UI", "keyboard", "F7")
