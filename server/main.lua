local QBCore = nil

pcall(function()
    QBCore = exports["qb-core"]:GetCoreObject()
end)
-- ===============================================
-- HELPER FUNCTIONS FOR JOB PLATES (SERVER)
-- ===============================================
function GenerateJobPlate(jobName)
    local platePrefix = Config.JobPlates[jobName] or "JOB"
    local maxPlateLength = 8
    
    if string.len(platePrefix) >= maxPlateLength then
        return string.sub(platePrefix, 1, maxPlateLength)
    end
    
    local remainingLength = maxPlateLength - string.len(platePrefix)
    local maxNumber = math.pow(10, remainingLength) - 1
    
    local randomNumber = math.random(1, maxNumber)
    local numberString = string.format("%0" .. remainingLength .. "d", randomNumber)
    
    return platePrefix .. numberString
end

CreateThread(function()
    local attempts = 0
    while not QBCore and attempts < 100 do
        attempts += 1
        pcall(function()
            QBCore = exports["qb-core"]:GetCoreObject()
        end)
        Wait(100)
    end

    if QBCore then
        QBCore.Functions.CreateCallback("jd-carspawner:server:getPlayerJob", function(source, cb)
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                cb({
                    job = Player.PlayerData.job.name,
                    grade = Player.PlayerData.job.grade.level
                })
            else
                cb(nil)
            end
        end)
    end
end)

RegisterNetEvent("jd-carspawner:server:spawnVehicle", function(vehicleModel, spawnCoords, spawnHeading, isRental, rentalTime, rentalPrice, paymentType, jobName)
    local src = source
    local vehicleHash = GetHashKey(vehicleModel)

    if vehicleHash == 0 or vehicleHash == GetHashKey("UNKNOWN") then
        TriggerClientEvent("QBCore:Notify", src, "Invalid vehicle model: " .. vehicleModel, "error")
        return
    end

    local veh = CreateVehicle(vehicleHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, true)

    if veh and veh ~= 0 then
        Wait(100)
        SetVehicleOnGroundProperly(veh)
        SetVehicleEngineOn(veh, true, true, false)

        local plate
        if isRental then
            plate = "RENT" .. math.random(100, 999)
        elseif jobName then
            plate = GenerateJobPlate(jobName)
        else
            plate = "QBC" .. math.random(1000, 9999)
        end
        
        SetVehicleNumberPlateText(veh, plate)
        Entity(veh).state.fuel = 100

        -- Apply vehicle extras if defined
        if data and data.extras then
            for _, extraId in ipairs(data.extras) do
                SetVehicleExtra(veh, extraId, false) -- false means enable the extra
            end
        end

        TriggerClientEvent("jd-carspawner:client:enterVehicle", src, veh, plate)
        TriggerClientEvent("QBCore:Notify", src, "Vehicle spawned successfully!", "success")
    else
        TriggerClientEvent("QBCore:Notify", src, "Failed to create vehicle", "error")
    end
end)

RegisterNetEvent("jd-carspawner:server:spawnRentalVehicle", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent("QBCore:Notify", src, "Player data not found", "error")
        return
    end

    -- Check if player has enough money
    local hasEnoughMoney = false
    if data.paymentType == "cash" then
        hasEnoughMoney = Player.PlayerData.money.cash >= data.rentalPrice
    elseif data.paymentType == "bank" then
        hasEnoughMoney = Player.PlayerData.money.bank >= data.rentalPrice
    end

    if not hasEnoughMoney then
        TriggerClientEvent("QBCore:Notify", src, "You don't have enough money for this rental ($" .. data.rentalPrice .. ")", "error")
        return
    end

    -- Remove money
    if data.paymentType == "cash" then
        Player.Functions.RemoveMoney('cash', data.rentalPrice, "vehicle-rental")
    elseif data.paymentType == "bank" then
        Player.Functions.RemoveMoney('bank', data.rentalPrice, "vehicle-rental")
    end

    -- Send success to client to spawn vehicle
    TriggerClientEvent("jd-carspawner:client:spawnRentalVehicle", src, data)
    
    -- Generate time text based on actual duration
    local timeText = ""
    local durationSeconds = data.rentalDurationSeconds or 3600

    -- Log extras if present (for debugging)
    if data.extras then
        print("Spawning rental vehicle with extras:", json.encode(data.extras))
    end
    
    if durationSeconds < 60 then
        timeText = string.format("%d seconds (DEBUG)", durationSeconds)
    elseif durationSeconds < 3600 then
        local minutes = math.floor(durationSeconds / 60)
        timeText = string.format("%d minute(s) %s", minutes, durationSeconds <= 600 and "(DEBUG)" or "")
    else
        local hours = math.floor(durationSeconds / 3600)
        timeText = string.format("%d hour(s)", hours)
    end
    
    TriggerClientEvent("QBCore:Notify", src, string.format("Vehicle rented for %s! Paid $%d via %s", timeText, data.rentalPrice, data.paymentType), "success")
end)

RegisterNetEvent("jd-carspawner:server:removeVehicle", function()
    local src = source
    TriggerClientEvent("QBCore:Notify", src, "Remove vehicle feature - under development", "info")
end)
