local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('jd-carspawner:server:rentCar', function(model, color, payment, duration)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local price = Config.Rental.pricePerHour * duration
    if not Player then return end

    if payment == 'bank' and Player.Functions.RemoveMoney('bank', price) or
       payment == 'cash' and Player.Functions.RemoveMoney('cash', price) then
        TriggerClientEvent('jd-carspawner:client:spawnRentalCar', src, model, color)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money', 'error')
    end
end)
