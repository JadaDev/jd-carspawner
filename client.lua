local QBCore = exports['qb-core']:GetCoreObject()
local spawnedVehicles, spawnedPeds = {}, {}
local lastRentalVehicle = nil
local activeRentalVehicles = {}
local loopingAlarms = {} -- Store looping alarms for non-emergency vehicles

-- =============== PED SPAWN ===============
function SpawnPeds()
    -- Spawn Job Peds
    if Config.JobSpawners then
        for jobName, jobData in pairs(Config.JobSpawners) do
            if jobData.type == "ped" and jobData.ped_model and jobData.ped_coords then
                RequestModel(jobData.ped_model)
                while not HasModelLoaded(jobData.ped_model) do Wait(10) end
                for _, pedLocationData in ipairs(jobData.ped_coords) do
                    if pedLocationData.coords then
                        local ped = CreatePed(0, jobData.ped_model, pedLocationData.coords, false, true)
                        FreezeEntityPosition(ped, true)
                        SetEntityInvincible(ped, true)
                        SetBlockingOfNonTemporaryEvents(ped, true)
                        table.insert(spawnedPeds, ped)
                    end
                end
            end
        end
    end

    -- Spawn Rental Peds
    if Config.RentalSpawner and Config.RentalSpawner.type == "ped" and Config.RentalSpawner.ped_model and Config.RentalSpawner.ped_coords then
        RequestModel(Config.RentalSpawner.ped_model)
        while not HasModelLoaded(Config.RentalSpawner.ped_model) do Wait(10) end
        for _, pedLocationData in ipairs(Config.RentalSpawner.ped_coords) do
            if pedLocationData.coords then
                local ped = CreatePed(0, Config.RentalSpawner.ped_model, pedLocationData.coords, false, true)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                table.insert(spawnedPeds, ped)
            end
        end
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
    local timeOptions, rentalFees, rentalDurations = GetRentalTimeOptions()
    
    -- Ensure colors are properly formatted for the UI
    local uiColors = {}
    for i, color in ipairs(Config.Colors) do
        table.insert(uiColors, {
            name = color.name,
            value = color.value,
            hex = color.hex
        })
    end

    local menuData = {
        type = 'rental',
        vehicles = Config.RentalSpawner.vehicles,
        timeOptions = timeOptions,
        colors = uiColors,  -- Use the properly formatted colors
        playerName = GetPlayerName(PlayerId()),
        playerId = GetPlayerServerId(PlayerId()),
        playerMoney = {
            cash = QBCore.Functions.GetPlayerData().money.cash,
            bank = QBCore.Functions.GetPlayerData().money.bank
        },
        showPlayerMoney = Config.UI.showPlayerMoney,
        rentalFees = rentalFees,
        rentalDurations = rentalDurations,
        config = Config.UI
    }
    
    SendNUIMessage({
        action = 'openMenu',
        data = menuData
    })
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


RegisterNUICallback('spawnVehicle', function(data, cb)
    if data.type == 'job' then
        -- Handle job vehicle spawning
        local playerPed = PlayerPedId()
        RequestModel(data.vehicle)
        while not HasModelLoaded(data.vehicle) do Wait(10) end
        
        local spawnCoords = data.spawnCoords or Config.JobCars[data.jobName].spawnLocations[1]
        local vehicle = CreateVehicle(data.vehicle, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
        SetEntityAsMissionEntity(vehicle, true, true)
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        
        SetVehicleNumberPlateText(vehicle, GenerateJobPlate(data.jobName))
        spawnedVehicles[data.jobName] = vehicle
        
        QBCore.Functions.Notify("Job vehicle spawned: " .. data.vehicle, "success")
        
    elseif data.type == 'rental' then
        -- Handle rental vehicle spawning, passing the final price from the UI
        TriggerServerEvent('jd-carspawner:server:rentCar', data.vehicle, data.vehicleColor, data.paymentType, data.rentalPrice)
        QBCore.Functions.Notify("Rental request sent for: " .. data.vehicle, "primary")
    end
    
    cb({ status = 'ok' })
end)

RegisterNetEvent('jd-carspawner:client:spawnRentalCar', function(model, colorData)
    local playerPed = PlayerPedId()
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local spawnCoords = Config.RentalSpawner.spawn_locations[1]
    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    SetVehicleNumberPlateText(vehicle, "RENT"..math.random(1000, 9999))
    
    -- Store vehicle reference
    lastRentalVehicle = vehicle
    activeRentalVehicles[#activeRentalVehicles+1] = {vehicle = vehicle, model = model, color = colorData}
    
    -- Apply color after a short delay to ensure vehicle is ready
    CreateThread(function()
        Wait(500) -- Wait for vehicle to be fully loaded
        if DoesEntityExist(vehicle) and colorData and colorData.value then
            SetVehicleModKit(vehicle, 0) -- Essential for color changes to apply reliably
            
            -- Apply the selected color to both primary and secondary
            SetVehicleColours(vehicle, colorData.value, colorData.value)
            
            -- Set pearlescent color to white (111) for a clean look, unless the car is white
            local pearlescentColor = 111
            if colorData.value == 111 then
                pearlescentColor = 0 -- If car is white, use black pearlescent for contrast
            end
            SetVehicleExtraColours(vehicle, pearlescentColor, 0) -- pearlescent, wheels
            
            QBCore.Functions.Notify("Vehicle color set to " .. colorData.name, "success")
        else
            QBCore.Functions.Notify("Vehicle spawned with default color.", "primary")
        end
    end)
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
    local targetVehicle = nil
    if activeRentalVehicles[1] and DoesEntityExist(activeRentalVehicles[1].vehicle) then
        targetVehicle = activeRentalVehicles[1].vehicle
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
    local targetVehicle = nil
    if activeRentalVehicles[1] and DoesEntityExist(activeRentalVehicles[1].vehicle) then
        targetVehicle = activeRentalVehicles[1].vehicle
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
    local targetVehicle = nil
    if activeRentalVehicles[1] and DoesEntityExist(activeRentalVehicles[1].vehicle) then
        targetVehicle = activeRentalVehicles[1].vehicle
    end

    if targetVehicle then
        if IsEmergencyVehicle(targetVehicle) then
            SetVehicleSiren(targetVehicle, true)
        else
            StartLoopingAlarm(targetVehicle)
        end
        QBCore.Functions.Notify("Siren/Alarm started.", "success")
    else
        QBCore.Functions.Notify("No rental vehicle found.", "error")
    end
end)

RegisterNetEvent('jd-carspawner:client:stopRentalSiren', function()
    local targetVehicle = nil
    if activeRentalVehicles[1] and DoesEntityExist(activeRentalVehicles[1].vehicle) then
        targetVehicle = activeRentalVehicles[1].vehicle
    end

    if targetVehicle then
        if IsEmergencyVehicle(targetVehicle) then
            SetVehicleSiren(targetVehicle, false)
        else
            StopLoopingAlarm(targetVehicle)
        end
        QBCore.Functions.Notify("Siren/Alarm stopped.", "success")
    else
        QBCore.Functions.Notify("No rental vehicle found.", "error")
    end
end)

-- =============== THREADS ===============
CreateThread(function() SpawnPeds() end)

-- Thread for Job Spawners
CreateThread(function()
    while true do
        local sleep = 1500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        if Config.JobSpawners then
            for jobName, jobData in pairs(Config.JobSpawners) do
                if jobData.ped_coords then
                    for _, pedLocationData in ipairs(jobData.ped_coords) do
                        if pedLocationData.coords then
                            local dist = #(playerCoords - pedLocationData.coords)
                            if dist < 2.0 then
                                sleep = 5
                                QBCore.Functions.DrawText3D(pedLocationData.coords.x, pedLocationData.coords.y, pedLocationData.coords.z + 1.0, "[ALT] Open " .. jobName .. " Menu")
                                if IsControlJustReleased(0, 19) then
                                    local playerJob = QBCore.Functions.GetPlayerData().job
                                    if playerJob.name == jobName then
                                        ShowJobMenu(jobName, playerJob.grade.level)
                                    else
                                        QBCore.Functions.Notify("You don't have the required job.", "error")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Thread for Rental Spawners
CreateThread(function()
    while true do
        local sleep = 1500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if Config.RentalSpawner and Config.RentalSpawner.ped_coords then
            for _, pedLocationData in ipairs(Config.RentalSpawner.ped_coords) do
                if pedLocationData.coords then
                    local dist = #(playerCoords - pedLocationData.coords)
                    if dist < 2.0 then
                        sleep = 5
                        QBCore.Functions.DrawText3D(pedLocationData.coords.x, pedLocationData.coords.y, pedLocationData.coords.z + 1.0, "[ALT] Open Rental Menu")
                        if IsControlJustReleased(0, 19) then
                            ShowRentalMenu()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
