local QBCore = exports['qb-core']:GetCoreObject()
local spawnedVehicles, spawnedPeds = {}, {}
local lastRentalVehicle = nil
local activeRentalVehicles = activeRentalVehicles or {}
local loopingAlarms = {} -- Store looping alarms for non-emergency vehicles

-- =============== PED SPAWN ===============
function SpawnJobPeds()
    for job, data in pairs(Config.JobCars) do
        local pedData = data.ped
        RequestModel(pedData.model)
        while not HasModelLoaded(pedData.model) do Wait(0) end

        local ped = CreatePed(0, pedData.model, pedData.coords.x, pedData.coords.y, pedData.coords.z - 1.0, pedData.coords.w, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        spawnedPeds[job] = ped
    end
end

-- =============== MENUS ===============
function ShowJobMenu(jobName, jobGrade)
    local carOptions = {}
    for rank, cars in pairs(Config.JobCars[jobName].ranks) do
        if jobGrade >= rank then
            for _, car in ipairs(cars) do
                table.insert(carOptions, {
                    header = 'Spawn: ' .. car,
                    params = { event = 'jd-carspawner:client:spawnJobCar', args = { car = car, job = jobName } }
                })
            end
        end
    end
    exports['qb-menu']:openMenu(carOptions)
end

function ShowRentalMenu()
    local rentalOptions = {}
    for _, duration in ipairs(Config.Rental.durations) do
        table.insert(rentalOptions, {
            header = duration .. ' Hour Rental ($' .. (duration * Config.Rental.pricePerHour) .. ')',
            params = { event = 'jd-carspawner:client:rentCarPrompt', args = { duration = duration } }
        })
    end
    exports['qb-menu']:openMenu(rentalOptions)
end

-- =============== VEHICLE SPAWN ===============
RegisterNetEvent('jd-carspawner:client:spawnJobCar', function(data)
    local playerPed = PlayerPedId()
    local job = data.job
    if spawnedVehicles[job] then
        QBCore.Functions.Notify("You already have a vehicle spawned.", "error")
        return
    end

    RequestModel(data.car)
    while not HasModelLoaded(data.car) do Wait(0) end

    local spawnCoords = Config.JobCars[job].spawnLocations[1]
    local vehicle = CreateVehicle(data.car, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    SetVehicleNumberPlateText(vehicle, GenerateJobPlate(job))
    spawnedVehicles[job] = vehicle
end)

RegisterNetEvent('jd-carspawner:client:rentCarPrompt', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = "Choose Vehicle and Color",
        submitText = "Confirm",
        inputs = {
            { type = 'text', isRequired = true, name = 'model', text = 'Vehicle Model (e.g., sultan)' },
            { type = 'color', isRequired = true, name = 'color', text = 'Color' },
            { type = 'radio', name = 'payment', options = { { value = 'cash', text = 'Cash' }, { value = 'bank', text = 'Bank' } } }
        }
    })
    if not dialog or not dialog.model then return end
    TriggerServerEvent('jd-carspawner:server:rentCar', dialog.model, dialog.color, dialog.payment, data.duration)
end)

RegisterNetEvent('jd-carspawner:client:spawnRentalCar', function(model, color)
    local playerPed = PlayerPedId()
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local spawnCoords = Config.Rental.spawnLocations[1]
    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    SetVehicleNumberPlateText(vehicle, "RENT"..math.random(1000, 9999))
    SetVehicleColours(vehicle, tonumber(color), tonumber(color))

    lastRentalVehicle = vehicle
end)

-- =============== UTILS ===============
function IsEmergencyVehicle(vehicle)
    local models = {
        'police','police2','police3','police4','policeb','policet',
        'sheriff','sheriff2','ambulance','firetruk','riot','fbi',
        'lguard','pranger','pbus'
    }
    local model = GetEntityModel(vehicle)
    for _, m in ipairs(models) do
        if model == GetHashKey(m) then return true end
    end
    return false
end

-- Persistent car alarm loop
function StartLoopingAlarm(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if loopingAlarms[netId] then return end
    loopingAlarms[netId] = true
    CreateThread(function()
        while loopingAlarms[netId] and DoesEntityExist(vehicle) do
            SetVehicleAlarm(vehicle, true)
            StartVehicleAlarm(vehicle)
            Wait(8000) -- retrigger every 8s to keep alive
        end
    end)
end

function StopLoopingAlarm(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    loopingAlarms[netId] = nil
    SetVehicleAlarm(vehicle, false)
end

-- =============== NUI CALLBACKS ===============
RegisterNUICallback('startRentalSiren', function(data, cb)
    local rentalIndex = (data.rentalIndex or 0) + 1
    local index, targetVehicle = 0, nil
    for _, rentalData in pairs(activeRentalVehicles) do
        if DoesEntityExist(rentalData.vehicle) then
            index = index + 1
            if index == rentalIndex then targetVehicle = rentalData.vehicle break end
        end
    end

    if targetVehicle and DoesEntityExist(targetVehicle) then
        if IsEmergencyVehicle(targetVehicle) then
            for i = 0, 12 do
                if DoesExtraExist(targetVehicle, i) then SetVehicleExtra(targetVehicle, i, 0) end
            end
            SetVehicleSiren(targetVehicle, true)
            SetVehicleHasMutedSirens(targetVehicle, false)
            SetVehicleLights(targetVehicle, 2)
            QBCore.Functions.Notify("Siren started.", "success")
            cb({ success = true })
        else
            StartLoopingAlarm(targetVehicle)
            QBCore.Functions.Notify("Alarm triggered (non-emergency).", "primary")
            cb({ success = true })
        end
    else
        QBCore.Functions.Notify("No rental vehicle found.", "error")
        cb({ success = false })
    end
end)

RegisterNUICallback('stopRentalSiren', function(data, cb)
    local rentalIndex = (data.rentalIndex or 0) + 1
    local index, targetVehicle = 0, nil
    for _, rentalData in pairs(activeRentalVehicles) do
        if DoesEntityExist(rentalData.vehicle) then
            index = index + 1
            if index == rentalIndex then targetVehicle = rentalData.vehicle break end
        end
    end

    if targetVehicle and DoesEntityExist(targetVehicle) then
        if IsEmergencyVehicle(targetVehicle) then
            SetVehicleSiren(targetVehicle, false)
            for i = 0, 12 do
                if DoesExtraExist(targetVehicle, i) then SetVehicleExtra(targetVehicle, i, 1) end
            end
            QBCore.Functions.Notify("Siren stopped.", "success")
        else
            StopLoopingAlarm(targetVehicle)
            QBCore.Functions.Notify("Alarm stopped.", "primary")
        end
        cb({ success = true })
    else
        QBCore.Functions.Notify("No rental vehicle found.", "error")
        cb({ success = false })
    end
end)

-- =============== BASIC COMMANDS FOR TESTING ===============
RegisterNetEvent('jd-carspawner:client:startRentalSiren', function()
    if lastRentalVehicle and DoesEntityExist(lastRentalVehicle) then
        if IsEmergencyVehicle(lastRentalVehicle) then
            SetVehicleSiren(lastRentalVehicle, true)
        else
            StartLoopingAlarm(lastRentalVehicle)
        end
        QBCore.Functions.Notify("Siren/Alarm started.", "success")
    else
        QBCore.Functions.Notify("No rental vehicle found.", "error")
    end
end)

RegisterNetEvent('jd-carspawner:client:stopRentalSiren', function()
    if lastRentalVehicle and DoesEntityExist(lastRentalVehicle) then
        if IsEmergencyVehicle(lastRentalVehicle) then
            SetVehicleSiren(lastRentalVehicle, false)
        else
            StopLoopingAlarm(lastRentalVehicle)
        end
        QBCore.Functions.Notify("Siren/Alarm stopped.", "success")
    else
        QBCore.Functions.Notify("No rental vehicle found.", "error")
    end
end)

-- =============== THREADS ===============
CreateThread(function() SpawnJobPeds() end)

CreateThread(function()
    while true do
        local sleep = 1500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for job, data in pairs(Config.JobCars) do
            local dist = #(coords - vector3(data.ped.coords.x, data.ped.coords.y, data.ped.coords.z))
            if dist < 2.0 then
                sleep = 0
                QBCore.Functions.DrawText3D(data.ped.coords.x, data.ped.coords.y, data.ped.coords.z + 1.0, "[ALT] Open Menu")
                if IsControlJustReleased(0, 19) then
                    local jobData = QBCore.Functions.GetPlayerData().job
                    if jobData.name == job then
                        ShowJobMenu(job, jobData.grade.level)
                    else
                        ShowRentalMenu()
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
