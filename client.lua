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

local lastJob = nil
local PlayerData = nil
local lastcash = nil
local lastbank = nil
local lastdirty = nil
local lastsociety = nil


SetRadarZoom(1150)

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
        Citizen.Wait(0)
    end
    loaded = true
    ESX.PlayerData = ESX.GetPlayerData()
end)

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(10)
    end
    Citizen.Wait(500)
    if PlayerData == nil or PlayerData.job == nil then
        PlayerData = ESX.GetPlayerData()
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
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
                    SendNUIMessage({seatbelton = true})
				else
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

        local player = GetPlayerPed(-1)
        local vehicle = GetVehiclePedIsIn(player, false)
        local pedinVeh = IsPedInAnyVehicle(player, false)				
        local vehicleIsOn = GetIsVehicleEngineRunning(vehicle)
        local hideseatbelt = false;
        local showlimiter = false;
        local showSpeedo = false;
        local mapoutline = false;
        
        if pedinVeh and vehicleIsOn then
            hideseatbelt = true
            showlimiter = true
            showSpeedo = true
            print(mapon)
            if mapon then
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
            enginerunning = false
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
        
        local showweap
        local showUi
        local Underwater

        if IsEntityInWater(PlayerPedId()) then
            Underwater = true
        else 
            Underwater = false
        end
                     
        if IsPauseMenuActive() then
            showUi = false
        else 
            showUi = true
        end
        
        if IsPedArmed(PlayerPedId(), 4 | 2) == 1 then
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


    if PlayerData.job ~= nil then
        if PlayerData.job.label ~= nil and PlayerData.job.grade_label ~= nil then
            ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
            society = money
            end, PlayerData.job.name)
        else
            society =  0
        end
    end
                   
    local player = PlayerPedId()

    --local radioStatus = exports["rp-radio"]:IsRadioOn()

    TriggerEvent('esx_status:getStatus', 'hunger', function(status) hunger = status.val / 10000 end)

    TriggerEvent('esx_status:getStatus', 'thirst', function(status) thirst = status.val / 10000 end)


    --SendNUIMessage({radio = radioStatus})

        if(PlayerData ~= nil) and (PlayerData.job ~= nil) then
            jobName = PlayerData.job.label..' - '..PlayerData.job.grade_label
            if(lastJob ~= jobName) then
                lastJob = jobName
                SendNUIMessage({job = jobName})
            end
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
        stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId()),
        hunger = hunger,
        thirst = thirst,
        oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10,
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
local checkvehclass = true
isinvehicle = function()
    Citizen.CreateThread(function()
        while true do
            Wait(speedfps)
            local veh = GetVehiclePedIsUsing(PlayerPedId(), false)
            local speed = math.floor(GetEntitySpeed(veh) * 3.6)
            local vehhash = GetEntityModel(veh)
            local maxspeed = (GetVehicleModelMaxSpeed(vehhash) * 3.6) + 20
            local fuellevel = exports["LegacyFuel"]:GetFuel(veh)
    
        if checkvehclass then
            local vehicleClass = GetVehicleClass(GetVehiclePedIsIn(PlayerPedId()))
            if vehicleClass == 8 or vehicleClass == 14 or vehicleClass == 15 or vehicleClass == 16 then
                checkvehclass = false
                SendNUIMessage({hideseatbeltextra = true})
            else
                checkvehclass = false
                SendNUIMessage({hideseatbeltextra = false})
            end  
        end
        
        SendNUIMessage({speed = speed, maxspeed = maxspeed, action = "update_fuel", fuel = fuellevel, showFuel = true})

        if Driving == false then
            checkvehclass = true
            break
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
        args = {"Bank", "You currently have $" .. comma_value(lastbank) .. " in your account"}
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
