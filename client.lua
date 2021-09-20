local Driving = false;
local Underwater = false;
local enableCruise = false;
local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["CAPSLOCK"] = 171, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18, ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182, ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81, ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178, ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173, ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}
local society
local mapon = true;
local speedfps = 125;
local minimap = RequestScaleformMovie("minimap")
local hunger
local thirst

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end

    while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerLoaded = true
	ESX.PlayerData = ESX.GetPlayerData()
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


local speedBuffer  = {}
local velBuffer    = {}
local wasInCar     = false

Citizen.CreateThread(function()
	while true do
		local car = GetVehiclePedIsIn(PlayerPedId())
		if car ~= 0 and (wasInCar or IsCar(car)) then
			wasInCar = true
			
			if beltOn then 
                DisableControlAction(0, 75) 
            end
			
			speedBuffer[2] = speedBuffer[1]
			speedBuffer[1] = GetEntitySpeed(car)
			
			if speedBuffer[2] ~= nil 
			   and not beltOn
			   and GetEntitySpeedVector(car, true).y > 1.0  
			   and speedBuffer[1] > 19.25 
			   and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255) then
			   
				local co = GetEntityCoords(PlayerPedId())
				local fw = Fwv(PlayerPedId())
				SetEntityCoords(PlayerPedId(), co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
				SetEntityVelocity(PlayerPedId(), velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
				Citizen.Wait(500)
				SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
			end
				
			velBuffer[2] = velBuffer[1]
			velBuffer[1] = GetEntityVelocity(car)
            
            function seatbelt()
				beltOn = not beltOn				  
				if beltOn then
                    ESX.ShowNotification('Memasang seatbelt', 'success')
                    SendNUIMessage({seatbelton = true})
				else
                    ESX.ShowNotification('Melepas seatbelt', 'error')
                    SendNUIMessage({seatbelton = false})
                end 
		    end
		elseif wasInCar then
            wasInCar = false
            beltOn = false
            speedBuffer[1], speedBuffer[2] = 0.0, 0.0
		end
        Wait(10) 
	end
end)

local ind = {l = false, r = false}

local speedBuffer  = {}
local velBuffer    = {}

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
		local sleep = 500  
		local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
		local vehicleModel = GetEntityModel(vehicle)
		local speed = GetEntitySpeed(vehicle)
		local float Max = GetVehicleModelMaxSpeed(vehicleModel)
        local isTalking = NetworkIsPlayerTalking(PlayerId())

        SendNUIMessage({talking = isTalking})
        RegisterCommand('speedlimiter', function()
            local inVehicle = GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId())) == 1 
            if (inVehicle) then
                if (GetPedInVehicleSeat(vehicle, -1) == PlayerPedId()) then	
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
        Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(1500)
        
        if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId()), -1) == PlayerPedId() and GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId())) == 1 then
            SendNUIMessage({showlimiter = true, showSpeedo = true})
            if Driving == false then
                Driving = true
                isinvehicle()
                TriggerVehicleLoop()
            end
        else
            Driving = false
            enableCruise = false
            SendNUIMessage({showlimiter = false, showSpeedo = false})
        end
        
        if IsPedInAnyVehicle(PlayerPedId(), false) and GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId())) == 1 then
            SendNUIMessage({hideseatbelt = true})
        else
            SendNUIMessage({hideseatbelt = false})
        end    

        if IsPedInAnyVehicle(PlayerPedId(-1), false) and mapon == true and GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId())) == 1 then
            ToggleRadar(true)
            SendNUIMessage({mapoutline = true})
        else
            ToggleRadar(false)
            SetRadarZoom(1150)
            SendNUIMessage({mapoutline = false})
        end

        if IsEntityInWater(PlayerPedId()) then
            Underwater = true
            SendNUIMessage({showOxygen = true})
        elseif not IsEntityInWater(PlayerPedId()) then
            Underwater = false
            SendNUIMessage({showOxygen = false})
        end
                     
        TriggerServerEvent('joehud:getServerInfo')

        if IsPauseMenuActive() then
            SendNUIMessage({showUi = false})
        elseif not IsPauseMenuActive() then
            SendNUIMessage({showUi = true})
        end
        
        if IsPedArmed(PlayerPedId(), 4 | 2) == 1 then
            SendNUIMessage({showweap = true})
        else
            SendNUIMessage({showweap = false})
        end

    end
end)

RegisterNetEvent('joehud:setInfo')
AddEventHandler('joehud:setInfo', function(info)

    if ESX.PlayerData.job ~= nil then
        if ESX.PlayerData.job.grade_name ~= nil and ESX.PlayerData.job.grade_name == 'boss' then
            ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
            society = money
            end, ESX.PlayerData.job.name)
        else
            society =  0
        end
    end
                   
    job = info['job']
    blackMoney = comma_value(info['blackMoney'])
    bank = comma_value(info['bankMoney'])
    money = comma_value(info['money'])
    vip_coins = comma_value(info['vipCoins'])
    car_coins = comma_value(info['carCoins'])

    if GetEntityMaxHealth(PlayerPedId()) ~= 200 then
        SetEntityMaxHealth(PlayerPedId(), 200)
        SetEntityHealth(PlayerPedId(), 200)
    end
    local player = PlayerPedId()
    local talking = NetworkIsPlayerTalking(PlayerId())
    local oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
    local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    -- local radioStatus = exports["rp-radio"]:IsRadioOn()

    TriggerEvent('esx_status:getStatus', 'hunger', function(status) hunger = status.val / 10000 end)

    TriggerEvent('esx_status:getStatus', 'thirst', function(status) thirst = status.val / 10000 end)


    -- SendNUIMessage({radio = radioStatus})

    SendNUIMessage({
        action = "update_hud",
        hp = GetEntityHealth(player) - 100,
        armor = GetPedArmour(player),
        stamina = stamina,
        hunger = hunger,
        thirst = thirst,
        oxygen = oxygen,
        job = info['job'],
        money = comma_value(info['money']),
        bank = comma_value(info['bankMoney']),
        blackMoney = comma_value(info['blackMoney']),
        society = comma_value(society)
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

isinvehicle = function()
    Citizen.CreateThread(function()
        while true do
            Wait(speedfps)
            local veh = GetVehiclePedIsUsing(PlayerPedId(), false)
            local speed = math.floor(GetEntitySpeed(veh) * 3.6)
            local vehhash = GetEntityModel(veh)
            local maxspeed = (GetVehicleModelMaxSpeed(vehhash) * 3.6) + 20
            local vehicleClass = GetVehicleClass(GetVehiclePedIsIn(PlayerPedId()))
            local fuellevel = exports["LegacyFuel"]:GetFuel(veh)

            SendNUIMessage({speed = speed, maxspeed = maxspeed, action = "update_fuel", fuel = fuellevel, showFuel = true})

            if vehicleClass == 8 or vehicleClass == 14 or vehicleClass == 15 or vehicleClass == 16 then
                SendNUIMessage({hideseatbeltextra = true})
            else
                SendNUIMessage({hideseatbeltextra = false})
            end  

        if Driving == false then
            break
        end
        end
    end)
end

-- Map stuff below
local x = -0.025
local y = -0.015
local w = 0.16
local h = 0.25

Citizen.CreateThread(function()

	RequestStreamedTextureDict("circlemap", false)
	while not HasStreamedTextureDictLoaded("circlemap") do
		Wait(100)
	end

	AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")

    SetMinimapClipType(1)
    SetMinimapComponentPosition('minimap', 'L', 'B', -0.015, -0.025, 0.16, 0.24)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', x + 0.17, y + 0.09, 0.072, 0.164)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.035, -0.03, 0.18, 0.22)
    ThefeedSpsExtendWidescreenOn()
    SetRadarBigmapEnabled(true, false)
    Wait(150)
    SetRadarBigmapEnabled(false, false)
end)

TriggerVehicleLoop = function()
	Citizen.CreateThread(function()
		ToggleRadar(true)
        SetRadarBigmapEnabled(false, false)
	end)
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

RegisterNetEvent('joehud:devmode')
AddEventHandler('joehud:devmode', function()
    SendNUIMessage({action = "devmode"})
end, false)       

RegisterNetEvent('joehud:hudmenu')
AddEventHandler('joehud:hudmenu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({showhudmenu = true})
end, false)   

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
