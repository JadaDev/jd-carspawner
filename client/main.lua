local alarmThreads = {} -- store active alarm loops by netId

-- Helper function for target system abstraction
local function AddTargetToPed(ped, options)
    if Config.TargetSystem == 'qb-target' then
        exports['qb-target']:AddTargetEntity(ped, options)
    elseif Config.TargetSystem == 'ox_target' then
        exports.ox_target:addLocalEntity(ped, options.options)
    else
        print("[ERROR] Invalid target system configured: " .. tostring(Config.TargetSystem))
    end
end



RegisterNetEvent("jd-carspawner:startRentalSiren", function(vehicleNetId)
    local vehicle = NetToVeh(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        return
    end
    -- Always enable alarm system before starting
    SetVehicleAlarm(vehicle, true)
    -- Stop existing loop if any
    if alarmThreads[vehicleNetId] and alarmThreads[vehicleNetId].active ~= nil then
        alarmThreads[vehicleNetId].active = false
        alarmThreads[vehicleNetId] = nil
    end
    local repeatAlarm = Config.SirenOptions.repeatAlarm
    local alarmDuration = Config.SirenOptions.alarmDuration or 15
    local alarmRepeatInterval = Config.SirenOptions.alarmRepeatInterval or 7

    local function reliableStartAlarm()
        for i = 1, 3 do
            SetVehicleAlarm(vehicle, true)
            StartVehicleAlarm(vehicle)
            Citizen.Wait(100)
            if IsVehicleAlarmActivated(vehicle) then
                break
            end
        end
    end

    local control = { active = true, netId = vehicleNetId }
    alarmThreads[vehicleNetId] = control
    Citizen.CreateThread(function()
        if repeatAlarm then
            while control.active and DoesEntityExist(vehicle) do
                reliableStartAlarm()
                Citizen.Wait(alarmRepeatInterval * 1000)
            end
        else
            reliableStartAlarm()
            Citizen.Wait(alarmDuration * 1000)
            SetVehicleAlarm(vehicle, false)
        end
    end)
end)



RegisterNetEvent("jd-carspawner:stopRentalSiren", function(vehicleNetId)
    -- First ensure thread is stopped regardless of vehicle existence
    if alarmThreads[vehicleNetId] then
        alarmThreads[vehicleNetId].active = false
        alarmThreads[vehicleNetId] = nil
    end

    local vehicle = NetToVeh(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        return
    end

    -- Completely stop and reset alarm system
    Citizen.CreateThread(function()
        local attempts = 0
        while attempts < 5 and DoesEntityExist(vehicle) do
            attempts = attempts + 1
            
            -- Reset all alarm states
            SetVehicleAlarm(vehicle, false)
            SetVehicleAlarmTimeLeft(vehicle, 0)
            StartVehicleAlarm(vehicle) -- This actually stops any active alarm
            SetVehicleAlarm(vehicle, false)
            
            -- Additional forced stop
            if IsVehicleAlarmActivated(vehicle) then
                SetVehicleAlarm(vehicle, false)
                StartVehicleAlarm(vehicle)
            end
            
            -- Check if alarm is really off
            if not IsVehicleAlarmActivated(vehicle) then
                break
            end
            
            Citizen.Wait(200)
        end
        
        -- Final cleanup if vehicle still exists
        if DoesEntityExist(vehicle) then
            SetVehicleAlarm(vehicle, false)
            StartVehicleAlarm(vehicle)
        end
    end)
end)
-- Siren/Alarm threads for job vehicles
RegisterNetEvent("jd-carspawner:startJobSiren", function(vehicleNetId)
    local vehicle = NetToVeh(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        return
    end
    -- Always enable alarm system before starting
    SetVehicleAlarm(vehicle, true)
    -- Stop existing loop if any
    if alarmThreads[vehicleNetId] and alarmThreads[vehicleNetId].active ~= nil then
        alarmThreads[vehicleNetId].active = false
        alarmThreads[vehicleNetId] = nil
    end
    local repeatAlarm = Config.JobSirenOptions.repeatAlarm
    local alarmDuration = Config.JobSirenOptions.alarmDuration or 15
    local alarmRepeatInterval = Config.JobSirenOptions.alarmRepeatInterval or 7

    local function reliableStartAlarm()
        for i = 1, 3 do
            SetVehicleAlarm(vehicle, true)
            StartVehicleAlarm(vehicle)
            Citizen.Wait(100)
            if IsVehicleAlarmActivated(vehicle) then
                break
            end
        end
    end

    local control = { active = true, netId = vehicleNetId }
    alarmThreads[vehicleNetId] = control
    Citizen.CreateThread(function()
        if repeatAlarm then
            while control.active and DoesEntityExist(vehicle) do
                reliableStartAlarm()
                Citizen.Wait(alarmRepeatInterval * 1000)
            end
        else
            reliableStartAlarm()
            Citizen.Wait(alarmDuration * 1000)
            SetVehicleAlarm(vehicle, false)
        end
    end)
end)

RegisterNetEvent("jd-carspawner:stopJobSiren", function(vehicleNetId)
    -- First ensure thread is stopped regardless of vehicle existence
    if alarmThreads[vehicleNetId] then
        alarmThreads[vehicleNetId].active = false
        alarmThreads[vehicleNetId] = nil
    end

    local vehicle = NetToVeh(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        return
    end

    -- Completely stop and reset alarm system
    Citizen.CreateThread(function()
        local attempts = 0
        while attempts < 5 and DoesEntityExist(vehicle) do
            attempts = attempts + 1
            
            -- Reset all alarm states
            SetVehicleAlarm(vehicle, false)
            SetVehicleAlarmTimeLeft(vehicle, 0)
            StartVehicleAlarm(vehicle) -- This actually stops any active alarm
            SetVehicleAlarm(vehicle, false)
            
            -- Additional forced stop
            if IsVehicleAlarmActivated(vehicle) then
                SetVehicleAlarm(vehicle, false)
                StartVehicleAlarm(vehicle)
            end
            
            -- Check if alarm is really off
            if not IsVehicleAlarmActivated(vehicle) then
                break
            end
            
            Citizen.Wait(200)
        end
        
        -- Final cleanup if vehicle still exists
        if DoesEntityExist(vehicle) then
            SetVehicleAlarm(vehicle, false)
            StartVehicleAlarm(vehicle)
        end
    end)
end)

-- Siren/Alarm NUI callbacks for job vehicles
RegisterNUICallback("startJobSiren", function(data, cb)
    local vehicleNetId = data.vehicleNetId
    if not vehicleNetId then cb({success=false}); return end
    TriggerEvent("jd-carspawner:startJobSiren", vehicleNetId)
    cb({success=true})
end)

RegisterNUICallback("stopJobSiren", function(data, cb)
    local vehicleNetId = data.vehicleNetId
    if not vehicleNetId then cb({success=false}); return end
    TriggerEvent("jd-carspawner:stopJobSiren", vehicleNetId)
    cb({success=true})
end)
-- Siren/Alarm NUI callbacks (NetToVeh based)
RegisterNUICallback("startRentalSiren", function(data, cb)
    local vehicleNetId = data.vehicleNetId
    if not vehicleNetId then cb({success=false}); return end
    TriggerEvent("jd-carspawner:startRentalSiren", vehicleNetId)
    cb({success=true})
end)

RegisterNUICallback("stopRentalSiren", function(data, cb)
    local vehicleNetId = data.vehicleNetId
    if not vehicleNetId then cb({success=false}); return end
    TriggerEvent("jd-carspawner:stopRentalSiren", vehicleNetId)
    cb({success=true})
end)
local QBCore = exports["qb-core"]:GetCoreObject()
local spawnedPeds = {}
local activeRentalVehicles = {}
local activeJobVehicles = {}
local rentalWaypoints = {}
local jobVehicleWaypoints = {}
local countdownActive = false
local currentRentalVehicle = nil

function ShowCountdown(seconds, vehicle)
    currentRentalVehicle = vehicle
    if not countdownActive then
        countdownActive = true
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = "createCountdownFrame"
        })
        Wait(100)
        SendNUIMessage({
            action = "showCountdown",
            seconds = seconds
        })
    end
end

function UpdateCountdown(seconds)
    local ped = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    
    local currentRentalVehicleNetId = nil
    local isInRentalVehicle = false
    
    for netId, rentalData in pairs(activeRentalVehicles) do
        if DoesEntityExist(rentalData.vehicle) and currentVehicle == rentalData.vehicle then
            currentRentalVehicleNetId = netId
            isInRentalVehicle = true
            currentRentalVehicle = rentalData.vehicle
            break
        end
    end
    
    if isInRentalVehicle and currentRentalVehicle then
        if countdownActive then
            SendNUIMessage({
                action = "updateCountdown", 
                seconds = seconds
            })
        else
            ShowCountdown(seconds, currentRentalVehicle)
        end
    else
        if countdownActive then
            countdownActive = false
            currentRentalVehicle = nil
            SendNUIMessage({
                action = "hideCountdown"
            })
        end
    end
end

function HideCountdown()
    if countdownActive then
        countdownActive = false
        currentRentalVehicle = nil
        SendNUIMessage({
            action = "hideCountdown"
        })
    end
end

function GetVehiclesInArea(coords, radius)
    local vehicles = {}
    local allVehicles = GetGamePool('CVehicle')
    
    for i = 1, #allVehicles do
        local vehicle = allVehicles[i]
        if DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(coords - vehicleCoords)
            
            if distance <= radius then
                table.insert(vehicles, vehicle)
            end
        end
    end
    
    return vehicles
end

Citizen.CreateThread(function()
    for jobName, spawnerData in pairs(Config.JobSpawners) do
        if spawnerData.type == "ped" then
            RequestModel(spawnerData.ped_model)
            while not HasModelLoaded(spawnerData.ped_model) do Citizen.Wait(0) end
            
            local pedCoords = spawnerData.ped_coords
            
            if pedCoords[1] and pedCoords[1].coords then
                for i, pedData in ipairs(pedCoords) do
                    local coords = pedData.coords
                    local ped = CreatePed(4, spawnerData.ped_model, coords.x, coords.y, coords.z, coords.w or spawnerData.ped_heading, false, false)
                    SetEntityInvincible(ped, true)
                    FreezeEntityPosition(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
                    AddTargetToPed(ped, {
                        options = {
                            {
                                type = "client",
                                event = "jd-carspawner:client:openMenu",
                                icon = "fas fa-car",
                                label = "Open " .. jobName .. " Spawner",
                                spawnerType = "job",
                                spawnerData = { 
                                    job = jobName, 
                                    data = spawnerData,
                                    pedIndex = i,
                                    spawnLocations = pedData.spawn_locations
                                }
                            }
                        },
                        distance = 2.5
                    })
                    table.insert(spawnedPeds, ped)
                end
            else
                if pedCoords.x then
                    pedCoords = {pedCoords}
                end
                
                for i, coords in ipairs(pedCoords) do
                    local ped = CreatePed(4, spawnerData.ped_model, coords.x, coords.y, coords.z, coords.w or spawnerData.ped_heading, false, false)
                    SetEntityInvincible(ped, true)
                    FreezeEntityPosition(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
                    AddTargetToPed(ped, {
                        options = {
                            {
                                type = "client",
                                event = "jd-carspawner:client:openMenu",
                                icon = "fas fa-car",
                                label = "Open " .. jobName .. " Spawner",
                                spawnerType = "job",
                                spawnerData = { job = jobName, data = spawnerData }
                            }
                        },
                        distance = 2.5
                    })
                    table.insert(spawnedPeds, ped)
                end
            end
        end
    end

    if Config.RentalSpawner and Config.RentalSpawner.type == "ped" then
        RequestModel(Config.RentalSpawner.ped_model)
        while not HasModelLoaded(Config.RentalSpawner.ped_model) do Citizen.Wait(0) end
        
        local pedCoords = Config.RentalSpawner.ped_coords
        
        if pedCoords[1] and pedCoords[1].coords then
            for i, pedData in ipairs(pedCoords) do
                local coords = pedData.coords
                local rentalPed = CreatePed(4, Config.RentalSpawner.ped_model, coords.x, coords.y, coords.z, coords.w or Config.RentalSpawner.ped_heading, false, false)
                SetEntityInvincible(rentalPed, true)
                FreezeEntityPosition(rentalPed, true)
                SetBlockingOfNonTemporaryEvents(rentalPed, true)
                TaskStartScenarioInPlace(rentalPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
                AddTargetToPed(rentalPed, {
                    options = {
                        {
                            type = "client",
                            event = "jd-carspawner:client:openMenu",
                            icon = "fas fa-car",
                            label = "Open Vehicle Rental",
                            spawnerType = "rental",
                            spawnerData = {
                                type = Config.RentalSpawner.type,
                                ped_model = Config.RentalSpawner.ped_model,
                                ped_heading = Config.RentalSpawner.ped_heading,
                                vehicles = Config.RentalSpawner.vehicles,
                                time_options_hours = Config.RentalSpawner.time_options_hours,
                                rental_fees = Config.RentalSpawner.rental_fees,
                                payment_options = Config.RentalSpawner.payment_options,
                                pedIndex = i,
                                spawn_locations = pedData.spawn_locations
                            }
                        }
                    },
                    distance = 2.5
                })
                table.insert(spawnedPeds, rentalPed)
            end
        else
            if pedCoords.x then
                pedCoords = {pedCoords}
            end
            
            for i, coords in ipairs(pedCoords) do
                local rentalPed = CreatePed(4, Config.RentalSpawner.ped_model, coords.x, coords.y, coords.z, coords.w or Config.RentalSpawner.ped_heading, false, false)
                SetEntityInvincible(rentalPed, true)
                FreezeEntityPosition(rentalPed, true)
                SetBlockingOfNonTemporaryEvents(rentalPed, true)
                TaskStartScenarioInPlace(rentalPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
                AddTargetToPed(rentalPed, {
                    options = {
                        {
                            type = "client",
                            event = "jd-carspawner:client:openMenu",
                            icon = "fas fa-car",
                            label = "Open Vehicle Rental",
                            spawnerType = "rental",
                            spawnerData = Config.RentalSpawner
                        }
                    },
                    distance = 2.5
                })
                table.insert(spawnedPeds, rentalPed)
            end
        end
    end
end)

Citizen.CreateThread(function()
    local lastVehicleCheck = nil
    
    while true do
        local ped = PlayerPedId()
        local currentVehicle = GetVehiclePedIsIn(ped, false)
        
        local inRentalVehicle = nil
        local rentalData = nil
        
        for netId, data in pairs(activeRentalVehicles) do
            if DoesEntityExist(data.vehicle) and currentVehicle == data.vehicle then
                inRentalVehicle = data.vehicle
                rentalData = data
                break
            end
        end
        
        if inRentalVehicle and rentalData then
            if lastVehicleCheck ~= inRentalVehicle then
                lastVehicleCheck = inRentalVehicle
                currentRentalVehicle = inRentalVehicle
                
                local timeLeft = rentalData.expiryTime - GetGameTimer()
                if timeLeft <= 60000 and timeLeft > 0 then
                    local secondsLeft = math.ceil(timeLeft / 1000)
                    if not countdownActive then
                        ShowCountdown(secondsLeft, inRentalVehicle)
                    end
                else
                    if countdownActive then
                        countdownActive = false
                        currentRentalVehicle = nil
                        SendNUIMessage({
                            action = "hideCountdown"
                        })
                    end
                end
            end
        else
            if lastVehicleCheck ~= nil then
                lastVehicleCheck = nil
                currentRentalVehicle = nil
                
                if countdownActive then
                    countdownActive = false
                    SendNUIMessage({
                        action = "hideCountdown"
                    })
                end
            end
        end
        
        Wait(500)
    end
end)

function openJobMenu(playerJob, jobConfig, spawnLocations, jobName)
    -- Check if player has too many job vehicles
    if Config.JobVehicleManagement.enableJobVehicleTracking then
        local PlayerData = QBCore.Functions.GetPlayerData()
        local playerJobVehicleCount = 0
        
        for netId, jobVehicleData in pairs(activeJobVehicles) do
            if DoesEntityExist(jobVehicleData.vehicle) and 
               jobVehicleData.playerCitizenId == PlayerData.citizenid and 
               jobVehicleData.jobName == jobName then
                playerJobVehicleCount = playerJobVehicleCount + 1
            else
                -- Clean up non-existent vehicles
                activeJobVehicles[netId] = nil
                if jobVehicleWaypoints[netId] then
                    RemoveBlip(jobVehicleWaypoints[netId])
                    jobVehicleWaypoints[netId] = nil
                end
            end
        end
        
        if playerJobVehicleCount >= Config.JobVehicleManagement.maxJobVehiclesPerPlayer then
            QBCore.Functions.Notify(string.format("You already have %d job vehicle(s) spawned. Store or remove existing vehicles first.", Config.JobVehicleManagement.maxJobVehiclesPerPlayer), "error")
            return
        end
    end
    
    local availableVehicles = {}
    for rank = 0, playerJob.grade do
        if jobConfig.vehicles[rank] then
            for _, vehicle in ipairs(jobConfig.vehicles[rank]) do
                if not table.contains(availableVehicles, vehicle) then
                    table.insert(availableVehicles, vehicle)
                end
            end
        end
    end

    local PlayerData = QBCore.Functions.GetPlayerData()
    
    local jobGradeNames = {}
    if Config.GradeNames and Config.GradeNames[playerJob.job] then
        for grade, name in pairs(Config.GradeNames[playerJob.job]) do
            jobGradeNames[tostring(grade)] = name
        end
    end
    
    local menuData = {
        type = "job",
        jobName = jobName,
        vehicles = jobConfig.vehicles,
        playerName = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname,
        playerId = GetPlayerServerId(PlayerId()),
        playerGrade = playerJob.grade,
        gradeNames = jobGradeNames,
        spawnCoords = spawnLocations or jobConfig.spawn_locations or {jobConfig.coords},
        spawnHeading = jobConfig.heading,
        colors = Config.Colors,  -- Add colors to menuData
        config = Config
    }

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openMenu", data = menuData })
end

function openRentalMenu(spawnerData, spawnLocations)
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    local timeOptions, rentalFees, rentalDurations = GetRentalTimeOptions()
    
    local menuData = {
        type = "rental",
        vehicles = spawnerData.vehicles,
        playerName = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname,
        playerId = GetPlayerServerId(PlayerId()),
        timeOptions = timeOptions,
        rentalFees = rentalFees,
        rentalDurations = rentalDurations,
        paymentOptions = spawnerData.payment_options,
        spawnCoords = spawnLocations or spawnerData.spawn_locations,
        spawnHeading = spawnerData.ped_heading,
        playerMoney = {
            cash = PlayerData.money.cash or 0,
            bank = PlayerData.money.bank or 0
        },
        showPlayerMoney = Config.UI.showPlayerMoney or false,
        colors = Config.Colors,  -- Add colors to menuData
        config = Config
    }

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openMenu", data = menuData })
end

RegisterNUICallback("closeMenu", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeMenu" })
    cb("ok")
end)

RegisterNUICallback("spawnVehicle", function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeMenu" })

    local coords, heading
    local availableSpawns = {}
    
    if type(data.spawnCoords) == "table" and #data.spawnCoords > 0 then
        for i, spawnLocation in ipairs(data.spawnCoords) do
            local spawnCoords = vector3(spawnLocation.x, spawnLocation.y, spawnLocation.z)
            local spawnHeading = spawnLocation.w or spawnLocation.heading or data.spawnHeading
            
            local nearbyVehicles = GetVehiclesInArea(spawnCoords, 3.0)
            
            if #nearbyVehicles == 0 then
                table.insert(availableSpawns, {
                    coords = spawnCoords,
                    heading = spawnHeading,
                    index = i
                })
            end
        end
        
        if #availableSpawns > 0 then
            local selectedSpawn = availableSpawns[math.random(1, #availableSpawns)]
            coords = selectedSpawn.coords
            heading = selectedSpawn.heading
        else
            QBCore.Functions.Notify("All spawn locations are occupied. Please try again later.", "error")
            cb("error")
            return
        end
    else
        local spawnCoords = vector3(data.spawnCoords.x, data.spawnCoords.y, data.spawnCoords.z)
        local nearbyVehicles = GetVehiclesInArea(spawnCoords, 3.0)
        
        if #nearbyVehicles > 0 then
            QBCore.Functions.Notify("Spawn location is occupied. Please move any vehicles and try again.", "error")
            cb("error")
            return
        end
        
        coords = spawnCoords
        heading = data.spawnHeading
    end

    if data.type == "rental" then
        TriggerServerEvent("jd-carspawner:server:spawnRentalVehicle", {
            vehicle = data.vehicle,
            coords = coords,
            heading = heading,
            color = data.vehicleColor or 0,
            rentalTime = data.rentalTime,
            rentalDurationSeconds = data.rentalDurationSeconds,
            rentalPrice = data.rentalPrice,
            paymentType = data.paymentType
        })
    else
                -- Get extras from vehicle data
                local extras = nil
                local PlayerData = QBCore.Functions.GetPlayerData()
                local playerJob = PlayerData.job
                
                if playerJob and data.jobConfig and data.jobConfig.vehicles then
                    local jobConfig = data.jobConfig
                    local maxGrade = playerJob.grade or 0
                    for rank = 0, maxGrade do
                        if jobConfig.vehicles[tostring(rank)] then
                            for _, vehicle in ipairs(jobConfig.vehicles[tostring(rank)]) do
                                if vehicle.model == data.vehicle then
                                    extras = vehicle.extras
                                    break
                                end
                            end
                            if extras then break end
                        end
                    end
                end
                local color = data.vehicleColor or 0
                SpawnAndEnterVehicle(data.vehicle, coords, heading, color, false, nil, nil, data.jobName, extras)
    end
    cb("ok")
end)

RegisterNUICallback("removeVehicle", function(_, cb)
    TriggerServerEvent("jd-carspawner:server:removeVehicle")
    SetNuiFocus(false, false)
    cb("ok")
end)

function SpawnAndEnterVehicle(model, coords, heading, color, isRental, rentalTime, rentalDurationSeconds, jobName, extras)
    local ped = PlayerPedId()
    QBCore.Functions.SpawnVehicle(model, function(vehicle)
        SetEntityHeading(vehicle, heading)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        
        local plate
        if isRental then
            plate = "RENT"..math.random(100,999)
        elseif jobName then
            plate = GenerateJobPlate(jobName)
        else
            plate = "SPAWNED"..math.random(100,999)
        end
        SetVehicleNumberPlateText(vehicle, plate)

        -- Apply vehicle extras if defined
        if extras then
            for _, extraId in ipairs(extras) do
                SetVehicleExtra(vehicle, extraId, false) -- false means enable the extra
            end
        end
        
        CreateThread(function()
            Wait(500)
            
            local keyGiven = false
            pcall(function() 
                exports['qb-vehiclekeys']:GiveKeys(plate)
                keyGiven = true
            end)
            if not keyGiven then
                pcall(function() TriggerEvent("vehiclekeys:client:SetOwner", plate) end)
            end
            
                    if color and color ~= 0 then
                        local hexColor
                        
                        -- Handle different color value types
                        if type(color) == "table" then
                            -- Directly use HEX from color table
                            hexColor = color.hex and color.hex:gsub("#", "") or nil
                        elseif type(color) == "number" then
                            -- Look up color in Config.Colors
                            for _, c in ipairs(Config.Colors) do
                                if c.value == color then
                                    hexColor = c.hex:gsub("#", "")
                                    break
                                end
                            end
                        elseif type(color) == "string" then
                            hexColor = color:gsub("#", "")
                        end

                        if hexColor and #hexColor == 6 then
                            local r = tonumber(hexColor:sub(1, 2), 16)
                            local g = tonumber(hexColor:sub(3, 4), 16)
                            local b = tonumber(hexColor:sub(5, 6), 16)
                            
                            if r and g and b then
                                SetVehicleCustomPrimaryColour(vehicle, r, g, b)
                                SetVehicleCustomSecondaryColour(vehicle, r, g, b)
                            end
                        end
                    
                        SetVehicleDirtLevel(vehicle, 0.0)
                        SetVehicleModKit(vehicle, 0)
                
                Wait(100)
                local engineHealth = GetVehicleEngineHealth(vehicle)
                SetVehicleEngineOn(vehicle, false, true, true)
                Wait(50)
                SetVehicleEngineOn(vehicle, true, true, false)
                SetVehicleEngineHealth(vehicle, engineHealth)
            end
            
            Wait(200)
            TaskWarpPedIntoVehicle(ped, vehicle, -1)
        end)
        
        if isRental and rentalTime and rentalDurationSeconds then
            local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
            
            local timeInMs = rentalDurationSeconds * 1000
            
            activeRentalVehicles[vehicleNetId] = {
                vehicle = vehicle,
                expiryTime = GetGameTimer() + timeInMs,
                rentalTime = rentalTime,
                durationSeconds = rentalDurationSeconds
            }
            
            CreateThread(function()
                local debugMessage = ""
                
                if rentalDurationSeconds < 60 then
                    debugMessage = string.format("Vehicle will expire in %d seconds", rentalDurationSeconds)
                elseif rentalDurationSeconds < 3600 then
                    local minutes = math.floor(rentalDurationSeconds / 60)
                    debugMessage = string.format("Vehicle will expire in %d minute(s)", minutes)
                else
                    local hours = math.floor(rentalDurationSeconds / 3600)
                    debugMessage = string.format("Vehicle rented for %d hour(s)", hours)
                end
                
                QBCore.Functions.Notify(debugMessage, rentalDurationSeconds <= 600 and "primary" or "success")
                
                local expiryTime = GetGameTimer() + timeInMs
                local lastWarning = 0
                
                local checkInterval = rentalDurationSeconds <= 600 and 5000 or 30000
                
                while GetGameTimer() < expiryTime do
                    if not DoesEntityExist(vehicle) then
                        activeRentalVehicles[vehicleNetId] = nil
                        HideCountdown()
                        return
                    end
                    
                    local timeLeft = expiryTime - GetGameTimer()
                    local currentTime = GetGameTimer()
                    local secondsLeft = math.ceil(timeLeft / 1000)
                    
                    local ped = PlayerPedId()
                    local currentVehicle = GetVehiclePedIsIn(ped, false)
                    local playerInThisRentalVehicle = (currentVehicle == vehicle)
                    
                    if timeLeft <= 60000 and playerInThisRentalVehicle then
                        if not countdownActive then
                            ShowCountdown(secondsLeft, vehicle)
                        else
                            if currentRentalVehicle == vehicle then
                                UpdateCountdown(secondsLeft)
                            end
                        end
                        
                        if secondsLeft == 30 and (currentTime - lastWarning) > 5000 then
                            QBCore.Functions.Notify("Your rental vehicle will expire in 30 seconds", "warning")
                            lastWarning = currentTime
                        elseif secondsLeft == 15 and (currentTime - lastWarning) > 5000 then
                            QBCore.Functions.Notify("Your rental vehicle will expire in 15 seconds", "error")
                            lastWarning = currentTime
                        elseif secondsLeft == 5 and (currentTime - lastWarning) > 5000 then
                            QBCore.Functions.Notify("Your rental vehicle will expire in 5 seconds", "error")
                            lastWarning = currentTime
                        end
                    end
                    
                    if rentalDurationSeconds >= 3600 then
                        -- For rentals 1 hour or longer
                        if timeLeft <= 300000 and timeLeft > 270000 and (currentTime - lastWarning) > 30000 then
                            QBCore.Functions.Notify("Your rental vehicle will expire in 5 minutes", "warning")
                            lastWarning = currentTime
                        elseif timeLeft <= 60000 and timeLeft > 30000 and (currentTime - lastWarning) > 30000 then
                            QBCore.Functions.Notify("Your rental vehicle will expire in 1 minute - Countdown active!", "error")
                            lastWarning = currentTime
                        end
                    else
                        -- For short duration rentals (debug/test durations)
                        if rentalDurationSeconds <= 60 and timeLeft <= 30000 and timeLeft > 25000 and (currentTime - lastWarning) > 5000 then
                            QBCore.Functions.Notify("Vehicle expires in " .. secondsLeft .. " seconds", "warning")
                            lastWarning = currentTime
                        elseif rentalDurationSeconds > 60 and rentalDurationSeconds < 3600 and timeLeft <= 60000 and timeLeft > 55000 and (currentTime - lastWarning) > 5000 then
                            QBCore.Functions.Notify("Countdown starting - " .. math.ceil(secondsLeft/60) .. " minute(s) left", "warning")
                            lastWarning = currentTime
                        end
                    end
                    
                    Wait(math.min(checkInterval, math.max(1000, timeLeft / 10)))
                end
                
                if DoesEntityExist(vehicle) then
                    QBCore.Functions.Notify("Your rented vehicle has been despawned.", "error")
                    Wait(1000)
                    DeleteVehicle(vehicle)
                end
                
                -- Clean up waypoint if exists
                if rentalWaypoints[vehicleNetId] then
                    RemoveBlip(rentalWaypoints[vehicleNetId])
                    rentalWaypoints[vehicleNetId] = nil
                end
                
                HideCountdown()
                activeRentalVehicles[vehicleNetId] = nil
            end)
        elseif jobName and Config.JobVehicleManagement.enableJobVehicleTracking then
            -- Track job vehicles
            local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
            local PlayerData = QBCore.Functions.GetPlayerData()
            
            activeJobVehicles[vehicleNetId] = {
                vehicle = vehicle,
                jobName = jobName,
                playerCitizenId = PlayerData.citizenid,
                coords = coords,
                model = model,
                plate = plate,
                spawnTime = GetGameTimer()
            }
            
            QBCore.Functions.Notify("Job vehicle spawned and is being tracked", "success")
        end
    end, coords, true)
end

function table.contains(tbl, val)
    for _, value in pairs(tbl) do
        if value == val then return true end
    end
    return false
end

RegisterNetEvent("jd-carspawner:client:spawnRentalVehicle", function(data)
    SpawnAndEnterVehicle(data.vehicle, data.coords, data.heading, data.color, true, data.rentalTime, data.rentalDurationSeconds, nil, data.extras)
end)

RegisterNetEvent("jd-carspawner:client:openMenu", function(data)
    local spawnerType = data.spawnerType
    local spawnerData = data.spawnerData

    if spawnerType == "job" then
        QBCore.Functions.TriggerCallback("jd-carspawner:server:getPlayerJob", function(playerJob)
            if playerJob and playerJob.job == spawnerData.job then
                local spawnLocations = spawnerData.spawnLocations or spawnerData.data.spawn_locations
                openJobMenu(playerJob, spawnerData.data, spawnLocations, spawnerData.job)
            else
                QBCore.Functions.Notify("You don't have access to this vehicle spawner", "error")
            end
        end)
    elseif spawnerType == "rental" then
        local spawnLocations = spawnerData.spawn_locations
        openRentalMenu(spawnerData, spawnLocations)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if GetCurrentResourceName() == resource then
        HideCountdown()
        
        for _, ped in ipairs(spawnedPeds) do
            DeletePed(ped)
        end
        
        for netId, rentalData in pairs(activeRentalVehicles) do
            if DoesEntityExist(rentalData.vehicle) then
                DeleteVehicle(rentalData.vehicle)
            end
        end
        
        -- Clean up job vehicles
        for netId, jobVehicleData in pairs(activeJobVehicles) do
            if DoesEntityExist(jobVehicleData.vehicle) then
                DeleteVehicle(jobVehicleData.vehicle)
            end
        end
        
        -- Clean up all rental waypoints
        if rentalWaypoints then
            for netId, blip in pairs(rentalWaypoints) do
                RemoveBlip(blip)
            end
            rentalWaypoints = {}
        end
        
        -- Clean up all job vehicle waypoints
        if jobVehicleWaypoints then
            for netId, blip in pairs(jobVehicleWaypoints) do
                RemoveBlip(blip)
            end
            jobVehicleWaypoints = {}
        end
        
        activeRentalVehicles = {}
        activeJobVehicles = {}
    end
end)

-- ===============================================
-- RENTAL MANAGEMENT SYSTEM
-- ===============================================

function ShowRentalManagementMenu()
    if not Config.RentalManagement.enableRentalMenu then
        QBCore.Functions.Notify("Rental management is disabled", "error")
        return
    end

    local rentals = {}
    local jobVehicles = {}
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    -- Get rental vehicles (only non-expired ones)
    for netId, rentalData in pairs(activeRentalVehicles) do
        if DoesEntityExist(rentalData.vehicle) then
            local timeLeft = rentalData.expiryTime - GetGameTimer()
            
            -- Only add vehicles that haven't expired
            if timeLeft > 0 then
                local vehicleModel = GetEntityModel(rentalData.vehicle)
                local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
                local vehicleCoords = GetEntityCoords(rentalData.vehicle)
                
                table.insert(rentals, {
                    netId = netId,
                    vehicle = rentalData.vehicle,
                    vehicleName = vehicleName,
                    vehicleModel = GetLabelText(vehicleName),
                    timeLeft = timeLeft,
                    durationSeconds = rentalData.durationSeconds or 3600,
                    coords = {x = vehicleCoords.x, y = vehicleCoords.y, z = vehicleCoords.z},
                    type = "rental"
                })
            else
                -- Remove expired vehicles from tracking (cleanup)
                activeRentalVehicles[netId] = nil
            end
        else
            -- Remove vehicles that no longer exist
            activeRentalVehicles[netId] = nil
        end
    end
    
    -- Get job vehicles if enabled
    if Config.JobVehicleManagement.enableJobVehicleTracking and Config.JobVehicleManagement.showJobVehiclesInMenu then
        local jobVehicleCount = 0
        for netId, jobVehicleData in pairs(activeJobVehicles) do
            jobVehicleCount = jobVehicleCount + 1
            
            if DoesEntityExist(jobVehicleData.vehicle) and jobVehicleData.playerCitizenId == PlayerData.citizenid then
                local vehicleModel = GetEntityModel(jobVehicleData.vehicle)
                local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
                
                local vehicleCoords = GetEntityCoords(jobVehicleData.vehicle)
                table.insert(jobVehicles, {
                    netId = netId,
                    vehicle = jobVehicleData.vehicle,
                    vehicleName = vehicleName,
                    vehicleModel = GetLabelText(vehicleName),
                    jobName = jobVehicleData.jobName,
                    plate = jobVehicleData.plate,
                    coords = {x = vehicleCoords.x, y = vehicleCoords.y, z = vehicleCoords.z},
                    spawnTime = jobVehicleData.spawnTime,
                    type = "job"
                })
            end
        end
    end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openRentalMenu",
        rentals = rentals,
        jobVehicles = jobVehicles
    })
end

RegisterNUICallback("locateRentalVehicle", function(data, cb)
    local rentalIndex = data.rentalIndex + 1 -- Convert from 0-based to 1-based indexing
    
    if not Config.RentalManagement.enableGPSWaypoints then
        QBCore.Functions.Notify("GPS waypoints are disabled", "error")
        cb("error")
        return
    end
    
    local rentals = {}
    local index = 0
    
    for netId, rentalData in pairs(activeRentalVehicles) do
        if DoesEntityExist(rentalData.vehicle) then
            index = index + 1
            if index == rentalIndex then
                local coords = GetEntityCoords(rentalData.vehicle)
                
                -- Remove existing waypoint for this vehicle
                if rentalWaypoints[netId] then
                    RemoveBlip(rentalWaypoints[netId])
                end
                
                -- Create new waypoint
                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(blip, Config.RentalManagement.waypointBlipSprite)
                SetBlipColour(blip, Config.RentalManagement.waypointBlipColor)
                SetBlipScale(blip, Config.RentalManagement.waypointBlipScale)
                SetBlipAsShortRange(blip, false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Rental Vehicle")
                EndTextCommandSetBlipName(blip)
                
                -- Set GPS route to the vehicle
                SetBlipRoute(blip, true)
                SetBlipRouteColour(blip, Config.RentalManagement.waypointBlipColor)
                
                rentalWaypoints[netId] = blip
                
                break
            end
        end
    end
    
    cb("ok")
end)

RegisterNUICallback("returnRentalVehicle", function(data, cb)
    local rentalIndex = data.rentalIndex + 1 -- Convert from 0-based to 1-based indexing
    
    local index = 0
    local targetNetId = nil
    local targetVehicle = nil
    
    for netId, rentalData in pairs(activeRentalVehicles) do
        if DoesEntityExist(rentalData.vehicle) then
            index = index + 1
            if index == rentalIndex then
                targetNetId = netId
                targetVehicle = rentalData.vehicle
                break
            end
        end
    end
    
    if targetNetId and targetVehicle then
        -- Remove waypoint if exists
        if rentalWaypoints[targetNetId] then
            RemoveBlip(rentalWaypoints[targetNetId])
            rentalWaypoints[targetNetId] = nil
        end
        
        -- Remove from active rentals
        activeRentalVehicles[targetNetId] = nil
        
        -- Delete the vehicle
        if DoesEntityExist(targetVehicle) then
            DeleteVehicle(targetVehicle)
        end
        
        QBCore.Functions.Notify("Rental vehicle returned successfully", "success")
        
        ShowRentalManagementMenu()
    else
        QBCore.Functions.Notify("Vehicle not found", "error")
    end
    
    cb("ok")
end)

RegisterNUICallback("closeRentalMenu", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)


RegisterNUICallback("locateJobVehicle", function(data, cb)
    local jobVehicleIndex = data.jobVehicleIndex + 1
    
    if not Config.RentalManagement.enableGPSWaypoints then
        QBCore.Functions.Notify("GPS waypoints are disabled", "error")
        cb("error")
        return
    end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    local index = 0
    
    for netId, jobVehicleData in pairs(activeJobVehicles) do
        if DoesEntityExist(jobVehicleData.vehicle) and jobVehicleData.playerCitizenId == PlayerData.citizenid then
            index = index + 1
            if index == jobVehicleIndex then
                local coords = GetEntityCoords(jobVehicleData.vehicle)
                
                -- Remove existing waypoint for this vehicle
                if jobVehicleWaypoints[netId] then
                    RemoveBlip(jobVehicleWaypoints[netId])
                end
                
                -- Create new waypoint
                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(blip, Config.JobVehicleManagement.jobWaypointBlipSprite)
                SetBlipColour(blip, Config.JobVehicleManagement.jobWaypointBlipColor)
                SetBlipScale(blip, Config.JobVehicleManagement.jobWaypointBlipScale)
                SetBlipAsShortRange(blip, false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Job Vehicle (" .. string.upper(jobVehicleData.jobName) .. ")")
                EndTextCommandSetBlipName(blip)
                
                -- Set GPS route to the vehicle
                SetBlipRoute(blip, true)
                SetBlipRouteColour(blip, Config.JobVehicleManagement.jobWaypointBlipColor)
                
                jobVehicleWaypoints[netId] = blip

                break
            end
        end
    end
    
    cb("ok")
end)

RegisterNUICallback("hideJobVehicleWaypoint", function(data, cb)
    if not Config.RentalManagement.enableGPSWaypoints then
        QBCore.Functions.Notify("GPS waypoints are disabled", "error")
        cb("error")
        return
    end
    
    local jobVehicleIndex = data.jobVehicleIndex + 1
    local PlayerData = QBCore.Functions.GetPlayerData()
    local index = 0
    
    for netId, jobVehicleData in pairs(activeJobVehicles) do
        if DoesEntityExist(jobVehicleData.vehicle) and jobVehicleData.playerCitizenId == PlayerData.citizenid then
            index = index + 1
            if index == jobVehicleIndex then
                -- Remove waypoint and route
                if jobVehicleWaypoints[netId] then
                    RemoveBlip(jobVehicleWaypoints[netId])
                    jobVehicleWaypoints[netId] = nil
                    QBCore.Functions.Notify("GPS waypoint removed", "success")
                else
                    QBCore.Functions.Notify("No waypoint found for this vehicle", "error")
                end
                break
            end
        end
    end
    
    cb("ok")
end)

RegisterNUICallback("storeJobVehicle", function(data, cb)
    local jobVehicleIndex = data.jobVehicleIndex + 1
    local PlayerData = QBCore.Functions.GetPlayerData()
    local index = 0
    local targetNetId = nil
    local targetVehicle = nil
    
    for netId, jobVehicleData in pairs(activeJobVehicles) do
        if DoesEntityExist(jobVehicleData.vehicle) and jobVehicleData.playerCitizenId == PlayerData.citizenid then
            index = index + 1
            if index == jobVehicleIndex then
                targetNetId = netId
                targetVehicle = jobVehicleData.vehicle
                break
            end
        end
    end
    
    if targetNetId and targetVehicle then
        -- Remove waypoint if exists
        if jobVehicleWaypoints[targetNetId] then
            RemoveBlip(jobVehicleWaypoints[targetNetId])
            jobVehicleWaypoints[targetNetId] = nil
        end
        
        -- Remove from active job vehicles
        activeJobVehicles[targetNetId] = nil
        
        -- Delete the vehicle
        if DoesEntityExist(targetVehicle) then
            DeleteVehicle(targetVehicle)
        end
        
        QBCore.Functions.Notify("Job vehicle stored successfully", "success")
        
        -- Refresh the menu
        ShowRentalManagementMenu()
    else
        QBCore.Functions.Notify("Vehicle not found", "error")
    end
    
    cb("ok")
end)

RegisterNUICallback("hideRentalWaypoint", function(data, cb)
    if not Config.RentalManagement.enableGPSWaypoints then
        QBCore.Functions.Notify("GPS waypoints are disabled", "error")
        cb("error")
        return
    end
    
    local rentalIndex = data.rentalIndex + 1
    local index = 0
    
    for netId, rentalData in pairs(activeRentalVehicles) do
        if DoesEntityExist(rentalData.vehicle) then
            index = index + 1
            if index == rentalIndex then
                -- Remove waypoint and route
                if rentalWaypoints[netId] then
                    RemoveBlip(rentalWaypoints[netId])
                    rentalWaypoints[netId] = nil
                    QBCore.Functions.Notify("GPS waypoint removed", "success")
                else
                    QBCore.Functions.Notify("No waypoint found for this vehicle", "error")
                end
                break
            end
        end
    end
    
    cb("ok")
end)

CreateThread(function()
    while true do
        Wait(0)
        
        if Config.RentalManagement.menuKey > 0 and IsControlJustReleased(0, Config.RentalManagement.menuKey) then
            if not IsPauseMenuActive() and not IsNuiFocused() then
                ShowRentalManagementMenu()
            end
        end
    end
end)

-- Clean up waypoints when vehicles are removed
function CleanupRentalWaypoints()
    for netId, blip in pairs(rentalWaypoints) do
        if not activeRentalVehicles[netId] or not DoesEntityExist(activeRentalVehicles[netId].vehicle) then
            RemoveBlip(blip)
            rentalWaypoints[netId] = nil
        end
    end
end

-- Update waypoint positions periodically and reset route
CreateThread(function()
    while true do
        Wait(Config.RentalManagement.gpsUpdateInterval or 3000)
        
        -- Update rental vehicle waypoints
        for netId, blip in pairs(rentalWaypoints) do
            if activeRentalVehicles[netId] and DoesEntityExist(activeRentalVehicles[netId].vehicle) then
                local coords = GetEntityCoords(activeRentalVehicles[netId].vehicle)
                SetBlipCoords(blip, coords.x, coords.y, coords.z)
                SetBlipRoute(blip, true) -- Reset route tracing
                SetBlipRouteColour(blip, Config.RentalManagement.waypointBlipColor)
            end
        end
        
        -- Update job vehicle waypoints
        for netId, blip in pairs(jobVehicleWaypoints) do
            if activeJobVehicles[netId] and DoesEntityExist(activeJobVehicles[netId].vehicle) then
                local coords = GetEntityCoords(activeJobVehicles[netId].vehicle)
                SetBlipCoords(blip, coords.x, coords.y, coords.z)
                SetBlipRoute(blip, true) -- Reset route tracing
                SetBlipRouteColour(blip, Config.JobVehicleManagement.jobWaypointBlipColor)
            end
        end
    end
end)

-- Fix siren loop functionality
RegisterNetEvent("jd-carspawner:startRentalSiren", function(vehicleNetId)
    local vehicle = NetToVeh(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        return
    end
    -- Always enable alarm system before starting
    SetVehicleAlarm(vehicle, true)
    -- Stop existing loop if any
    if alarmThreads[vehicleNetId] and alarmThreads[vehicleNetId].active ~= nil then
        alarmThreads[vehicleNetId].active = false
        alarmThreads[vehicleNetId] = nil
    end
    local repeatAlarm = Config.SirenOptions.repeatAlarm
    local alarmDuration = Config.SirenOptions.alarmDuration or 15
    local alarmRepeatInterval = Config.SirenOptions.alarmRepeatInterval or 10

    local function reliableStartAlarm()
        for i = 1, 3 do
            SetVehicleAlarm(vehicle, true)
            StartVehicleAlarm(vehicle)
            Citizen.Wait(100)
            if IsVehicleAlarmActivated(vehicle) then
                break
            end
        end
    end

    local control = { active = true, netId = vehicleNetId }
    alarmThreads[vehicleNetId] = control
    Citizen.CreateThread(function()
        while control.active and DoesEntityExist(vehicle) do
            reliableStartAlarm()
            if repeatAlarm then
                Citizen.Wait(alarmRepeatInterval * 1000)
            else
                Citizen.Wait(alarmDuration * 1000)
                SetVehicleAlarm(vehicle, false)
                break
            end
        end
        alarmThreads[vehicleNetId] = nil
    end)
end)

-- Cleanup expired rental vehicles periodically
CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        
        for netId, rentalData in pairs(activeRentalVehicles) do
            if rentalData.expiryTime and GetGameTimer() > rentalData.expiryTime then
                -- Vehicle has expired, remove from tracking
                activeRentalVehicles[netId] = nil
                
                -- Remove any waypoint for this vehicle
                if rentalWaypoints[netId] then
                    RemoveBlip(rentalWaypoints[netId])
                    rentalWaypoints[netId] = nil
                end
            elseif not DoesEntityExist(rentalData.vehicle) then
                -- Vehicle no longer exists, remove from tracking
                activeRentalVehicles[netId] = nil
                
                -- Remove any waypoint for this vehicle
                if rentalWaypoints[netId] then
                    RemoveBlip(rentalWaypoints[netId])
                    rentalWaypoints[netId] = nil
                end
            end
        end
    end
end)

-- Update the existing checkrentals command with config check
RegisterCommand(Config.RentalManagement.checkRentalsCommand or "checkrentals", function()
    if not Config.RentalManagement.enableCheckRentalsCommand then
        QBCore.Functions.Notify("Check rentals command is disabled", "error")
        return
    end
    
    ShowRentalManagementMenu()
end, false)
