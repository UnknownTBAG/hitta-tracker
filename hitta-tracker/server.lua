local ESX = nil
local time_out = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


RegisterServerEvent("hitta-tracker")
AddEventHandler("hitta-tracker", function(plate) 

    local xPlayers = ESX.GetPlayers()

    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])


        if xPlayer.getJob().name == 'police' then
            TriggerClientEvent("hitta-tracker:plate", xPlayers[i], plate)

        end

    end
end)

RegisterServerEvent("hitta-tracker:setActivePlates")
AddEventHandler("hitta-tracker:setActivePlates", function(plate)
    time_out[plate] = false
end)

RegisterServerEvent("hitta-tracker:removeActivePlate")
AddEventHandler("hitta-tracker:removeActivePlate", function(plate)
    time_out[plate] = time_out[nil]
    local xPlayers = ESX.GetPlayers()

    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])


        if xPlayer.getJob().name == 'police' then
            TriggerClientEvent("hitta-tracker:updateActivePlate", xPlayers[i], plate)
        end

    end

end)

RegisterServerEvent("hitta-tracker:getActivePlates")
AddEventHandler("hitta-tracker:getActivePlates", function()
    TriggerClientEvent("hitta-tracker:getActivePlates", source, time_out)
end)


RegisterServerEvent("hitta-tracker:triggerTimer")
AddEventHandler("hitta-tracker:triggerTimer", function(plate)
    local xPlayers = ESX.GetPlayers()
    local startTimer = os.time() + Config.removeTimer
    Citizen.CreateThread(function()
        while os.time() < startTimer and time_out[plate] ~= nil do 
            Citizen.Wait(5)
        end

        for i=1, #xPlayers, 1 do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
    
    
            if xPlayer.getJob().name == 'police' then
                TriggerClientEvent("hitta-tracker:updateTimer", xPlayers[i], plate)
            end
    
        end
    
    end)
end)

