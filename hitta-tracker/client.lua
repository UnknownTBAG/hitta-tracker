ESX = nil
local isLoading = true
local display = false 
local blips_pos = {}
local prev_pos = {}
local time_out = {}

Citizen.CreateThread(function()
	while true do
		Wait(5)
		if ESX ~= nil then
		
		else
			ESX = nil
			TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		end
	end
end)



Citizen.CreateThread(function()
    while true do
      Citizen.Wait(5)
      
      if (IsControlJustPressed(1, Config.openKey)) then
            local playerData = ESX.GetPlayerData()

            if isInVehicle() and playerData.job.name == "police" then 
                SetNuiFocus(true, true)
                SendNUIMessage({type = 'ui', display = true})
            end
      end
    end
end)


Citizen.CreateThread(function()
    while isLoading == true do 
        Citizen.Wait(20000)     -- Roughly takes around 20-30 secs to load everything including vehicles 
        local playerData = ESX.GetPlayerData()

        if ESX.IsPlayerLoaded(PlayerId) and playerData.job.name == "police" then 
            print("Police vehicle tracker loaded.")
            TriggerServerEvent("hitta-tracker:getActivePlates")
            isLoading = false
        end
    end 

end)

RegisterNetEvent("hitta-tracker:updateTimer")
AddEventHandler("hitta-tracker:updateTimer", function(plate)
    time_out[plate] = time_out[nil]
end)

RegisterNetEvent("hitta-tracker:updateActivePlate")
AddEventHandler("hitta-tracker:updateActivePlate", function(plate)

    for v,k in pairs(time_out) do 
        if time_out[v] == plate then 
            time_out[plate] = true 
        end
    end
   
end)



RegisterNetEvent("hitta-tracker:getActivePlates")
AddEventHandler("hitta-tracker:getActivePlates", function(plates)
    time_out = plates
    for v,k in pairs(time_out) do
        checkVehicle(v)
    end
end)

RegisterNetEvent('hitta-tracker:plate')
AddEventHandler('hitta-tracker:plate', function(plate)
    checkVehicle(plate)
end)

RegisterNUICallback('searchPlate', function(data, cb)
    local vehicle = ESX.Game.GetVehicles()
    local miss = 0

    for i=1, #vehicle, 1 do 
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle[i])
        
        if vehicleProps.plate == data.plate then 
            local nCheck = 0
            for _ in pairs(time_out) do 
                nCheck=nCheck + 1
            end

            if nCheck >= Config.maxTracker then 
                SendNUIMessage({type = "maxPlate"})
            else
                SendNUIMessage({
                    type = "ui",
                    display = false
                  })
            
                SetNuiFocus(false)
                TriggerServerEvent("hitta-tracker", data.plate)
            end
        else 
            miss = miss + 1 
        end 
    end

    if #vehicle == miss then 
        SendNUIMessage({type = "noPlate"})
    end
end)

RegisterNUICallback("removeSearch", function(data, cb)
    local vehicle = ESX.Game.GetVehicles()
    local miss = 0

    for i=1, #vehicle, 1 do 
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle[i])
        
        if vehicleProps.plate == data.plate then 
            TriggerServerEvent("hitta-tracker:removeActivePlate", data.plate)
            SendNUIMessage({
                type = "ui",
                display = false
              })
        
            SetNuiFocus(false)
        else 
            miss = miss + 1 
        end 
    end

    if #vehicle == miss then 
        SendNUIMessage({type = "noPlate"})
    end
end)


RegisterNUICallback("close", function(data, cb)
    SendNUIMessage({
        type = "ui",
        display = false
      })

    SetNuiFocus(false)
end)


function checkVehicle(plate)
    local vehicle = ESX.Game.GetVehicles()

    for i=1, #vehicle, 1 do 
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle[i])
        
        if vehicleProps.plate == plate then 
            TriggerServerEvent("hitta-tracker:setActivePlates", plate)
            time_out[plate] = false
            createVehicleTracker(vehicle[i], plate) 
        end 
    end

end

function triggerTimer(plate)
    TriggerServerEvent("hitta-tracker:triggerTimer", plate)
end

function isInVehicle()
    if Config.inVehicle then 
        return IsPedInAnyVehicle(PlayerPedId(), false)
    else
        return true 
    end 
end

function createVehicleTracker(vehicle, plate) 
    triggerTimer(plate)

        ESX.ShowNotification(_U('tracker_activated') .. plate)
        Citizen.CreateThread(function()
            while time_out[plate] == false do
                Wait(50)

                if DoesEntityExist(vehicle) then 
           

                    local x, y, z = table.unpack(GetEntityCoords(vehicle))
         

                    if prev_pos == table.unpack(GetEntityCoords(vehicle)) then 
                
                    else 


                        RemoveBlip(blips_pos[plate])
 
                        local new_pos_blip = AddBlipForCoord(x,y,z)
      
                        SetBlipSprite(new_pos_blip, 432)
                        SetBlipDisplay(new_pos_blip, 4)
                        SetBlipColour(new_pos_blip, 75)
                        SetBlipScale(new_pos_blip, 1.0)


                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString(_U("blip_text") .. plate)
                        EndTextCommandSetBlipName(new_pos_blip)

    
                        blips_pos[plate] = new_pos_blip
                        prev_pos = table.unpack(GetEntityCoords(vehicle))
                    end

                else
                    time_out[plate] = time_out[nil]
                    TriggerServerEvent("hitta-tracker:removeActivePlate", plate)
                    ESX.ShowNotification(_U('tracker_lost') .. plate)
                end
            end 
            RemoveBlip(blips_pos[plate])
            time_out[plate] = time_out[nil]
            TriggerServerEvent("hitta-tracker:removeActivePlate", plate)
            ESX.ShowNotification(_U("tracker_lost") .. plate)
    
        end)
end 



