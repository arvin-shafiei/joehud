local speedomulti = 2.236936
local speedtext = "MPH"
local mapon, checkvehclass = true, true
local speedfps = 125
local minimap = RequestScaleformMovie("minimap")
local speedBuffer, velBuffer  = {}, {}
local Driving, Underwater, enableCruise, wasInCar, pedinVeh, beltOn = false, false, false, false, false, false
local lastjob, lastcash, lastbank, lastdirty, lastsociety, society, hunger, thirst, player, vehicle, vehicleIsOn

ESX = nil

CreateThread(function()
    while not ESX do
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
        Wait(0)
    end

    while not ESX.GetPlayerData().job do
	Wait(10)
    end

    ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

--[[Functions]]--
function IsCar(veh)
    local vc = GetVehicleClass(veh)
    return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end	

function Fwv(entity)  
    local hr = GetEntityHeading(entity) + 90.0
    if hr < 0.0 then hr = 360.0 + hr end
    hr = hr * 0.0174533
    return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end

function isinvehicle()
    CreateThread(function()
        while true do
            Wait(125)

            local veh = GetVehiclePedIsUsing(player, false)
            local speed = math.floor(GetEntitySpeed(veh) * speedomulti)
	        local vehhash = GetEntityModel(veh)
            local maxspeed = (GetVehicleModelMaxSpeed(vehhash) * speedomulti) + 50
       
            if checkvehclass then
                local vehicleClass = GetVehicleClass(GetVehiclePedIsIn(PlayerPedId()))
                checkvehclass = false
                if vehicleClass == 8 or vehicleClass == 13 or vehicleClass == 14 or vehicleClass == 15 or vehicleClass == 16 then
                    SendNUIMessage({hideseatbeltextra = true})
                else
                    SendNUIMessage({hideseatbeltextra = false})
                end  
            end
        
            if Config.LegacyFuel then 
                local fuellevel = exports["LegacyFuel"]:GetFuel(veh)
                SendNUIMessage({speed = speed, speedtext = speedtext, maxspeed = maxspeed, action = "update_fuel", fuel = fuellevel, showFuel = true})
            else
                local fuellevel = GetVehicleFuelLevel(veh)
                SendNUIMessage({speed = speed, speedtext = speedtext, maxspeed = maxspeed, action = "update_fuel", fuel = fuellevel, showFuel = true})
            end

            if not Driving then
                checkvehclass = true
                break
            end
        end
    end)
end

function comma_value(amount)
    local formatted = amount
    
    while true do
        if not formatted then 
            break
        else
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        end
      if k == 0 then
        break
      end
    end
    return formatted
end

function TriggerVehicleLoop()
    if mapon then
	    CreateThread(function()
	        ToggleRadar(true)
            SetRadarBigmapEnabled(false, false)
	    end)
    end
end

function ToggleRadar(state)
	DisplayRadar(state)
	BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
	ScaleformMovieMethodAddParamInt(3)
	EndScaleformMovieMethod()
end

function Voicelevel(val)
    SendNUIMessage({action = "voice_level", voicelevel = val})
end

exports('Voicelevel', Voicelevel)
--[[End of Functions]]--

--[[Threads]]--
CreateThread(function()
    while true do
        Wait(1500)

        player = PlayerPedId()
        pedinVeh = IsPedInAnyVehicle(player, false)				
        vehicle = GetVehiclePedIsIn(player, false)
        vehicleIsOn = GetIsVehicleEngineRunning(vehicle)
        local hideseatbelt, showlimiter, showSpeedo = false, false, false 
        local mapoutline = false
        
        if pedinVeh and vehicleIsOn then
            hideseatbelt = true
            showlimiter = true
            showSpeedo = true
            if mapon then
                SetRadarZoom(1150)
                ToggleRadar(true)
                mapoutline = true
            else
                ToggleRadar(false)
            end
            if not Driving then
                Driving = true
                isinvehicle()
                TriggerVehicleLoop()
            end
            SendNUIMessage({
                hideseatbelt = hideseatbelt, 
                showlimiter = showlimiter,
                showSpeedo =  showSpeedo,
                mapoutline = mapoutline
            })
        else 
            enableCruise = false
            showlimiter = false
            showSpeedo = false
            ToggleRadar(false)
            mapoutline = false
            Driving = false
            SendNUIMessage({
                hideseatbelt = hideseatbelt, 
                showlimiter = showlimiter,
                showSpeedo =  showSpeedo,
                mapoutline = mapoutline
            })
        end
        
        if IsEntityInWater(PlayerPedId()) then -- doesn't work with player variable
            Underwater = true
        else
            Underwater = false
        end
                     
        if IsPauseMenuActive() then
            showUi = false
        else 
            showUi = true
        end
        
        if IsPedArmed(player, 4 | 2) then
            showweap = true
        else
            showweap = false
        end

        SendNUIMessage({
            showOxygen = Underwater, 
            showUi = showUi,
            showweap = showweap
        })

        TriggerServerEvent('joehud:getServerInfo')
    end
end)

CreateThread(function()
	while true do
		local car = GetVehiclePedIsIn(player)
		if car ~= 0 and (wasInCar or IsCar(car)) then
			wasInCar = true
			
	    		if beltOn then 
                		DisableControlAction(0, 75)
            		end
			
			speedBuffer[2] = speedBuffer[1]
			speedBuffer[1] = GetEntitySpeed(car)
			
			if speedBuffer[2] and not beltOn and GetEntitySpeedVector(car, true).y > 1.0  and speedBuffer[1] > 15 and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255) then			   
				local co = GetEntityCoords(player)
				local fw = Fwv(player)
				SetEntityCoords(player, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
				SetEntityVelocity(PlayerPedId(), velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
				Wait(500)
				SetPedToRagdoll(player, 1000, 1000, 0, 0, 0, 0)
			end
				
			velBuffer[2] = velBuffer[1]
			velBuffer[1] = GetEntityVelocity(car)
		elseif wasInCar then
            		wasInCar = false
            		beltOn = false
           		speedBuffer[1], speedBuffer[2] = 0.0, 0.0
        	end
        Wait(0) 
	end
end)

CreateThread(function()
	while true do 
        Wait(500)
			
        local istalking = NetworkIsPlayerTalking(PlayerId()) -- doesn't work with player variable
        SendNUIMessage({talking = istalking})
    end
end)
--[[End of Threads]]--

--[[Status Event]]--
RegisterNetEvent('joehud:setInfo')
AddEventHandler('joehud:setInfo', function(info)
        if ESX.PlayerData.job and ESX.PlayerData.job.grade_name and ESX.PlayerData.job.grade_name == 'boss' then
            ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
                society = money
            end, ESX.PlayerData.job.name)
        else
            society =  0
        end

        TriggerEvent('esx_status:getStatus', 'hunger', function(status) hunger = status.val / 10000 end)
        TriggerEvent('esx_status:getStatus', 'thirst', function(status) thirst = status.val / 10000 end)

        if Config.rpRadio then
            local radioStatus = exports["rp-radio"]:IsRadioOn()
            SendNUIMessage({radio = radioStatus})
        end

        if (lastjob ~= info['job']) then
            lastjob = info['job']
            SendNUIMessage({job = info['job']})
        end

        if (lastcash ~= info['money']) then
            lastcash = info['money']
            SendNUIMessage({money = comma_value(info['money'])})
        end

        if (lastbank ~= info['bankMoney']) then
            lastbank = info['bankMoney']
            SendNUIMessage({bank = comma_value(info['bankMoney'])})
        end

        if (lastdirty ~= info['blackMoney']) then
            lastdirty = info['blackMoney']
            SendNUIMessage({blackMoney = comma_value(info['blackMoney'])})
        end

        if (lastsociety ~= society) then
            lastsociety = society
            SendNUIMessage({society = comma_value(society)})
        end

    SendNUIMessage({
        action = "update_hud",
        hp = GetEntityHealth(PlayerPedId()) - 100,
        armor = GetPedArmour(PlayerPedId()),
        stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId()), -- doesn't work with player variable
        hunger = hunger,
        thirst = thirst,
        oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10 -- doesn't work with player variable
    })
end)
 --[[End of Status Event]]

--[[Map]]--
local x = -0.025
local y = -0.015

CreateThread(function()

    RequestStreamedTextureDict("circlemap", false)
		
    while not HasStreamedTextureDictLoaded("circlemap") do
	Wait(100)
    end

    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")

    SetMinimapClipType(1)
    SetMinimapComponentPosition('minimap', 'L', 'B', -0.022, -0.026, 0.16, 0.245)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', x + 0.21, y + 0.09, 0.071, 0.164)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.032, -0.04, 0.18, 0.22)
    SetRadarBigmapEnabled(true, false)
    Wait(150)
    SetRadarBigmapEnabled(false, false)
end)
--[[End of Map]]--

--[[Command Events]]
RegisterNetEvent('joehud:devmode')
AddEventHandler('joehud:devmode', function()
    SendNUIMessage({action = "devmode"})
end, false)       

RegisterNetEvent('joehud:showjob')
AddEventHandler('joehud:showjob', function()
    TriggerEvent('chat:addMessage', {
        color = { 150, 75, 0},
        multiline = true,
        args = {"Job Center", "Your job is " .. lastjob}
      })
end, false)   

RegisterNetEvent('joehud:showcash')
AddEventHandler('joehud:showcash', function()
    TriggerEvent('chat:addMessage', {
        color = { 0, 240, 0},
        multiline = true,
        args = {"Wallet", "You have $" .. comma_value(lastcash)}
      })
end, false)   

RegisterNetEvent('joehud:showbank')
AddEventHandler('joehud:showbank', function()
    TriggerEvent('chat:addMessage', {
        color = { 240, 0, 0},
        multiline = true,
        args = {"Bank", "You have $" .. comma_value(lastbank)}
      })
end, false)   

RegisterNetEvent('joehud:showdirty')
AddEventHandler('joehud:showdirty', function()
    TriggerEvent('chat:addMessage', {
        color = { 128, 128, 128},
        multiline = true,
        args = {"Pocket", "You have $" .. comma_value(lastdirty)}
      })
end, false)   

RegisterNetEvent('joehud:showid')
AddEventHandler('joehud:showid', function()
    TriggerEvent('chat:addMessage', {
        color = { 0, 240, 0},
        multiline = true,
        args = {"Wallet", "Your state ID is: " ..  GetPlayerServerId(PlayerId()) }
      })
end, false)   

RegisterNetEvent('joehud:showsociety')
AddEventHandler('joehud:showsociety', function()
    TriggerEvent('chat:addMessage', {
        color = { 150, 75, 0},
        multiline = true,
        args = {"Business", "The current business funds are $" ..  comma_value(society) }
      })
end, false)   

RegisterNetEvent('joehud:hudmenu')
AddEventHandler('joehud:hudmenu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({showhudmenu = true})
end, false)   
--[[End of Command Events]]--

--[[Callbacks]]--
RegisterNUICallback('cancel', function()
    SetNuiFocus(false, false)
    SendNUIMessage({showhudmenu = false})
end)

RegisterNUICallback('getmap', function(data, cb)
    mapon = data.mapon
    cb(mapon)
end)

RegisterNUICallback('getspeedfps', function(data, cb)
    speedfps = data.speedfps or 125
    cb(speedfps)
end)
--[[End of Callbacks]]--

--[[Commands & KeyMappings]]--
RegisterCommand('uir', function()
    ESX.UI.Menu.CloseAll()
    TriggerEvent('wk:toggleMenuControlLock', false)
    SendNUIMessage({showhudmenu = false})
    SendNUIMessage({type = 'destroy'})
    SendNUIMessage({toggleradarrc = true})
    SendNUIMessage({action = 'closeMenu', namespace = namespace, name = name, data = data})
    SendNUIMessage({type = 'closeAll'})
    TriggerEvent("mdt:closeModal")
    showMenu = false
    SetNuiFocus(false, false)
    ClearPedTasksImmediately(PlayerPedId())
end, false)  

RegisterCommand('speedlimiter', function()
   if pedinVeh and vehicleIsOn then
    local vehicle = GetVehiclePedIsIn(player, false)
    local vehicleModel = GetEntityModel(vehicle)
    local speed = GetEntitySpeed(vehicle)
    local Max = GetVehicleModelMaxSpeed(vehicleModel)
    local vehicleClass = GetVehicleClass(GetVehiclePedIsIn(player))

        if (GetPedInVehicleSeat(vehicle, -1) == player) then
		if vehicleClass == 13 then
    	else
            if not enableCruise then 
                SetVehicleMaxSpeed(vehicle, speed)
                enableCruise = true
                SendNUIMessage({
                    speedlimiter = true
                })
            elseif enableCruise then
                SetVehicleMaxSpeed(vehicle, GetVehicleHandlingFloat(vehicle,"CHandlingData","fInitialDriveMaxFlatVel"))
                enableCruise = false
                SendNUIMessage({
                    speedlimiter = false
                })
            else
                SetVehicleMaxSpeed(vehicle, Max)
                enableCruise = false
                SendNUIMessage({
                    speedlimiter = false
                })
            end 
	    end
        end
    end
end, false)

RegisterCommand('seatbelt', function()
    local vehicleClass = GetVehicleClass(GetVehiclePedIsIn(player))

    if vehicleClass == 8 or vehicleClass == 13 or vehicleClass == 14 or vehicleClass == 21 then
	print("You can't enable your seatbelt in this type of vehicle")
    else
        if pedinVeh then
            beltOn = not beltOn				  
            if beltOn then
                SendNUIMessage({seatbelton = true})
            else
                SendNUIMessage({seatbelton = false})
            end 
        end
    end
end, false)

RegisterKeyMapping('speedlimiter', 'Activate Speedlimiter', 'keyboard', 'CAPITAL')
RegisterKeyMapping('seatbelt', 'Activate Seatbelt', 'keyboard', 'B')   
--[[End of Commands & KeyMappings]]

--[[Single Checks]]--
if Config.Speed == "mph" or Config.Speed == "MPH" then
        speedtext = "MPH"
        speedomulti = 2.236936
    else
        speedtext = "KMH"
        speedomulti = 3.6
end
--[[End of Single Checks]]--
