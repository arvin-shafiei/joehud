local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local mapon, checkvehclass = true, true
local speedfps = Config.SpeedFPS
local minimap = RequestScaleformMovie("minimap")
local speedBuffer, velBuffer  = {}, {}
local Driving, Underwater, enableCruise, wasInCar, pedinVeh, beltOn = false, false, false, false, false, false
local lastJob, lastcash, lastbank, lastdirty, lastsociety, society, hunger, thirst
local player = PlayerPedId()
local ind = {l = false, r = false}

ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
    end
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

RegisterKeyMapping('speedlimiter', 'SpeedLimiter', 'keyboard', 'CAPITAL')
RegisterKeyMapping('seatbelt', 'Seatbelt', 'keyboard', 'B')

RegisterCommand('seatbelt', function()
    seatbelt()
end, false)    

Citizen.CreateThread(function()
	while true do
		if IsPedInAnyVehicle(player, false) then
            local vehicle = GetVehiclePedIsIn(player, false)
			wasInCar = true
			
			speedBuffer[2] = speedBuffer[1]
			speedBuffer[1] = GetEntitySpeed(vehicle)
			
			if speedBuffer[2] ~= nil and not beltOn and GetEntitySpeedVector(vehicle, true).y > 1.0  and speedBuffer[1] > 19.25 and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255) then
				local co = GetEntityCoords(player)
				local fw = Fwv(player)

				SetEntityCoords(player, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
				SetEntityVelocity(player, velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
				Citizen.Wait(500)
				SetPedToRagdoll(player, 1000, 1000, 0, 0, 0, 0)
			end
				
			velBuffer[2] = velBuffer[1]
			velBuffer[1] = GetEntityVelocity(vehicle)
            
		elseif wasInCar then
            wasInCar = false
            beltOn = false
            speedBuffer[1], speedBuffer[2] = 0.0, 0.0
		end
        Wait(10) 
	end
end)

function seatbelt()	
    if pedinVeh then
        beltOn = not beltOn
        if beltOn then
            SendNUIMessage({seatbelton = true})
            DisableControlAction(0, 75) 
        else
            SendNUIMessage({seatbelton = false})
        end 
    end
end

IsCar = function(veh)
    local vc = GetVehicleClass(veh)
    return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end	

Fwv = function (entity)
    local hr = GetEntityHeading(entity) + 90.0
    if hr < 0.0 then hr = 360.0 + hr end
    hr = hr * 0.0174533
    return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end

Citizen.CreateThread( function()
	while true do 
		local vehicle = GetVehiclePedIsIn(player, false)
		local vehicleModel = GetEntityModel(vehicle)
		local speed = GetEntitySpeed(vehicle)
		local Max = GetVehicleModelEstimatedMaxSpeed(vehicleModel)
        local isTalking = NetworkIsPlayerTalking(PlayerId())

        SendNUIMessage({talking = isTalking})
        RegisterCommand('speedlimiter', function()
            local inVehicle = GetIsVehicleEngineRunning(GetVehiclePedIsIn(player)) == 1 
            if (inVehicle) then
                if (GetPedInVehicleSeat(vehicle, -1) == player) then	
                    if enableCruise == false then 
                        SetVehicleMaxSpeed(vehicle, speed)
                        enableCruise = true
                        SendNUIMessage({
                            speedlimiter = true
                        })
                    elseif enableCruise == true then
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
                Wait(10)
            end
        end, false)
        Wait(500)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(1500)

        player = PlayerPedId()
        pedinVeh = IsPedInAnyVehicle(player, false)	
        local vehicle = GetVehiclePedIsIn(player, false)				
        local vehicleIsOn = GetIsVehicleEngineRunning(vehicle)
        local hideseatbelt, showlimiter, showSpeedo, mapoutline = false, false, false, false
        local showweap, showUi
        
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
            if Driving == false then
                Driving = true
                isinvehicle()
                TriggerVehicleLoop()
            end
            SendNUIMessage({
                hideseatbelt = hideseatbelt, 
                showlimiter = showlimiter,
                showSpeedo =  showSpeedo,
                mapoutline = mapoutline})
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
                mapoutline = mapoutline})
        end

        if IsEntityInWater(player) then
            Underwater = true
        else 
            Underwater = false
        end
                     
        if IsPauseMenuActive() then
            showUi = false
        else 
            showUi = true
        end
        
        if IsPedArmed(player, 4 | 2) == 1 then
            showweap = true
        else
            showweap = false
        end

        SendNUIMessage({
            showOxygen = Underwater, 
            showUi = showUi,
            showweap = showweap})

        TriggerServerEvent('joehud:getServerInfo')
    end
end)

RegisterNetEvent('joehud:setInfo')
AddEventHandler('joehud:setInfo', function(info)
    local player = PlayerPedId()

    if ESX.PlayerData.job ~= nil then
        if ESX.PlayerData.job.label ~= nil and ESX.PlayerData.job.grade_label ~= nil then
            ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
            society = money
            end, ESX.PlayerData.job.name)
        else
            society =  0
        end
    end
                   

    TriggerEvent('esx_status:getStatus', 'hunger', function(status) hunger = status.val / 10000 end)
    TriggerEvent('esx_status:getStatus', 'thirst', function(status) thirst = status.val / 10000 end)

    if Config.rpRadio then
        local radioStatus = exports["rp-radio"]:IsRadioOn()
        SendNUIMessage({radio = radioStatus})
    end

        if(lastjob ~= info['job']) then
            lastjob = info['job']
            SendNUIMessage({job = info['job']})
        end

        if(lastcash ~= info['money']) then
            lastcash = info['money']
            SendNUIMessage({money = comma_value(info['money'])})
        end

        if(lastbank ~= info['bankMoney']) then
            lastbank = info['bankMoney']
            SendNUIMessage({bank = comma_value(info['bankMoney'])})
        end

        if(lastdirty ~= info['blackMoney']) then
            lastdirty = info['blackMoney']
            SendNUIMessage({blackMoney = comma_value(info['blackMoney'])})
        end

        if(lastsociety ~= society) then
            lastsociety = society
            SendNUIMessage({society = comma_value(society)})
        end

    SendNUIMessage({
        action = "update_hud",
        hp = GetEntityHealth(player) - 100,
        armor = GetPedArmour(player),
        stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerPedId()),
        hunger = hunger,
        thirst = thirst,
        oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
    })
end)
 
comma_value = function(amount)
    local formatted = amount
    
    while true do
        if formatted == nil then 
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

-- Speedometer and a few other things
isinvehicle = function()
    Citizen.CreateThread(function()
        while true do
            Wait(speedfps)

        if IsPedInAnyVehicle(player, false) then
            local veh = GetVehiclePedIsIn(player, false)
            local speed = math.floor(GetEntitySpeed(veh) * Config.Speed)
            local vehhash = GetEntityModel(veh)
            local maxspeed = (GetVehicleModelMaxSpeed(vehhash) * Config.Speed) + 20
    
        if checkvehclass then
            local vehicleClass = GetVehicleClass(GetVehiclePedIsIn(player))
            if vehicleClass == 8 or vehicleClass == 14 or vehicleClass == 15 or vehicleClass == 16 then
                checkvehclass = false
                SendNUIMessage({hideseatbeltextra = true})
            else
                checkvehclass = false
                SendNUIMessage({hideseatbeltextra = false})
            end  
        end


        if Config.LegacyFuel then 
            local fuellevel = exports["LegacyFuel"]:GetFuel(veh)
            SendNUIMessage({speed = speed, maxspeed = maxspeed, action = "update_fuel", fuel = fuellevel, showFuel = true})
        else
            local fuellevel = GetVehicleFuelLevel(veh)
            SendNUIMessage({speed = speed, maxspeed = maxspeed, action = "update_fuel", fuel = fuellevel, showFuel = true})
        end

        if Driving == false then
            checkvehclass = true
            break
        end

        end
    end
    end)
end

-- Map stuff below
local x = -0.025
local y = -0.015

Citizen.CreateThread(function()

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

TriggerVehicleLoop = function()
    if mapon then
	    Citizen.CreateThread(function()
		    ToggleRadar(true)
            SetRadarBigmapEnabled(false, false)
	    end)
    end
end

ToggleRadar = function(state)
	DisplayRadar(state)
	BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
	ScaleformMovieMethodAddParamInt(3)
	EndScaleformMovieMethod()
end

Voicelevel = function(val)
    SendNUIMessage({action = "voice_level", voicelevel = val})
end
exports('Voicelevel', Voicelevel)


-- server sided commands
RegisterNetEvent('joehud:devmode')
AddEventHandler('joehud:devmode', function()
    SendNUIMessage({action = "devmode"})
end, false)       

RegisterNetEvent('joehud:showjob')
AddEventHandler('joehud:showjob', function()
    TriggerEvent('chat:addMessage', {
        color = { 150, 75, 0},
        multiline = true,
        args = {"Job Center", "Your current job is " .. jobName}
      })
end, false)   

RegisterNetEvent('joehud:showcash')
AddEventHandler('joehud:showcash', function()
    TriggerEvent('chat:addMessage', {
        color = { 0, 240, 0},
        multiline = true,
        args = {"Wallet", "You currently have $" .. comma_value(lastcash) .. " in your wallet"}
      })
end, false)   

RegisterNetEvent('joehud:showbank')
AddEventHandler('joehud:showbank', function()
    TriggerEvent('chat:addMessage', {
        color = { 240, 0, 0},
        multiline = true,
        args = {"Bank", "You currently have $" .. comma_value(lastbank) .. " in your bank account"}
      })
end, false)   

RegisterNetEvent('joehud:showdirty')
AddEventHandler('joehud:showdirty', function()
    TriggerEvent('chat:addMessage', {
        color = { 128, 128, 128},
        multiline = true,
        args = {"Pocket", "You currently have $" .. comma_value(lastdirty) .. " worth of marked bills in your pockets"}
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


-- NUI Callbacks

RegisterNUICallback('cancel', function()
    SetNuiFocus(false, false)
    SendNUIMessage({showhudmenu = false})
end)

RegisterNUICallback('getmap', function(data, cb)
    mapon = data.mapon
    cb(mapon)
end)

RegisterNUICallback('getspeedfps', function(data, cb)
    speedfps = data.speedfps
    cb(speedfps)
end)