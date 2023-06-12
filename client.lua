-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONEXÃO
-----------------------------------------------------------------------------------------------------------------------------------------
src = {}
Tunnel.bindInterface("vrp_homes",src)
vSERVER = Tunnel.getInterface("vrp_homes")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local houseTimer = 0
local houseOpen = ""
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTFOCUS
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	SetNuiFocus(false,false)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHESTCLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("chestClose",function(data)
	TriggerEvent("vrp_sound:source",'zipperclose',0.2)
	SetNuiFocus(false,false)
	SendNUIMessage({ action = "hideMenu" })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("takeItem",function(data)
	vSERVER.takeItem(tostring(houseOpen),data.item,data.amount)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOREITEM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("storeItem",function(data)
	vSERVER.storeItem(tostring(houseOpen),data.item,data.amount)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- AUTO-UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("Creative:UpdateVault")
AddEventHandler("Creative:UpdateVault",function(action)
	SendNUIMessage({ action = action })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REQUESTVAULT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("requestVault",function(data,cb)
	local inventario,inventario2,peso,maxpeso,peso2,maxpeso2 = vSERVER.openChest(tostring(houseOpen))
	if inventario then
		cb({ inventario = inventario, inventario2 = inventario2, peso = peso, maxpeso = maxpeso, peso2 = peso2, maxpeso2 = maxpeso2 })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local homes = {
-----------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------CASAS---------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
	["NOME DA CASA"] = { -- QUANDO COLOCAR O NOME DA CASA TEM QUE SER JUNTO TIPO = NOMEDACASA
		["enter"] = {  }, -- LOCAL ONDE O PLAYER VAI DAR /ENTER OU /ENTRAR PARA ENTRAR E COMPRAR A CASA
		["exit"] = {  }, -- LOCAL ONDE O JOGADOR VAI SAIR DA CASA
		["vault"] = {  } -- LOCAL ONDE O PLAYER VAI DAR /BAU OU /CHEST
	},
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOUSETIMER
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(3000)
		if houseTimer > 0 then
			houseTimer = houseTimer - 3
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("entrar",function(source,args)
	local ped = PlayerPedId()
	local x,y,z = table.unpack(GetEntityCoords(ped))
	for k,v in pairs(homes) do
		local _,i = GetGroundZFor_3dCoord(v["enter"][1],v["enter"][2],v["enter"][3])
		local distance = Vdist(x,y,z,v["enter"][1],v["enter"][2],i)
		if distance <= 1.5 and houseTimer <= 0 and vSERVER.checkPermissions(k) then
			houseTimer = 3
			DoScreenFadeOut(1000)
			TriggerEvent("vrp_sound:source","enterexithouse",0.7)
			SetTimeout(1400,function()
				SetEntityCoords(ped,v["exit"][1]+0.0001,v["exit"][2]+0.0001,v["exit"][3]+0.0001-1,1,0,0,1)
				Citizen.Wait(750)
				DoScreenFadeIn(1000)
				houseOpen = tostring(k)
				print(houseOpen)
			end)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXIT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("sair",function(source,args)
	local ped = PlayerPedId()
	local x,y,z = table.unpack(GetEntityCoords(ped))
	for k,v in pairs(homes) do
		local _,i = GetGroundZFor_3dCoord(v["exit"][1],v["exit"][2],v["exit"][3])
		local distance = Vdist(x,y,z,v["exit"][1],v["exit"][2],i)
		if distance <= 1.5 and houseTimer <= 0 then
			houseTimer = 3
			DoScreenFadeOut(1000)
			TriggerEvent("vrp_sound:source","enterexithouse",0.5)
			SetTimeout(1300,function()
				SetEntityCoords(ped,v["enter"][1]+0.0001,v["enter"][2]+0.0001,v["enter"][3]+0.0001-1,1,0,0,1)
				Citizen.Wait(750)
				DoScreenFadeIn(1000)
				houseOpen = ""
			end)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VAULT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("bau",function(source,args)
	local ped = PlayerPedId()
	local x,y,z = table.unpack(GetEntityCoords(ped))
	for k,v in pairs(homes) do
		local _,i = GetGroundZFor_3dCoord(v["vault"][1],v["vault"][2],v["vault"][3])
		local distance = Vdist(x,y,z,v["vault"][1],v["vault"][2],i)
		if distance <= 2.0 and houseTimer <= 0 and vSERVER.checkIntPermissions(k) then
			houseTimer = 3
			TriggerEvent("vrp_sound:source","zipperopen",0.5)
			SetNuiFocus(true,true)
			SendNUIMessage({ action = "showMenu" })
			houseOpen = tostring(k)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVADE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("invade",function(source,args)
	local ped = PlayerPedId()
	local x,y,z = table.unpack(GetEntityCoords(ped))
	for k,v in pairs(homes) do
		local _,i = GetGroundZFor_3dCoord(v["enter"][1],v["enter"][2],v["enter"][3])
		local distance = Vdist(x,y,z,v["enter"][1],v["enter"][2],i)
		if distance <= 1.5 and vSERVER.checkPolice() then
			DoScreenFadeOut(1000)
			TriggerEvent("vrp_sound:source","enterexithouse",0.7)
			SetTimeout(1400,function()
				SetEntityCoords(ped,v["exit"][1]+0.0001,v["exit"][2]+0.0001,v["exit"][3]+0.0001-1,1,0,0,1)
				Citizen.Wait(750)
				DoScreenFadeIn(1000)
			end)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETHOMESTATISTICS
-----------------------------------------------------------------------------------------------------------------------------------------
function src.getHomeStatistics()
	return tostring(houseOpen)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETBLIPSHOMES
-----------------------------------------------------------------------------------------------------------------------------------------
function src.setBlipsOwner(homeName)
	local blip = AddBlipForCoord(homes[homeName]["enter"][1],homes[homeName]["enter"][2],homes[homeName]["enter"][3])
	SetBlipSprite(blip,411)
	SetBlipAsShortRange(blip,true)
	SetBlipColour(blip,36)
	SetBlipScale(blip,0.4)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Residência: ~g~"..homeName)
	EndTextCommandSetBlipName(blip)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETBLIPSHOMES
-----------------------------------------------------------------------------------------------------------------------------------------
function src.setBlipsHomes(status)
	for k,v in pairs(status) do
		local blip = AddBlipForCoord(homes[v.name]["enter"][1],homes[v.name]["enter"][2],homes[v.name]["enter"][3])
		SetBlipSprite(blip,411)
		SetBlipAsShortRange(blip,true)
		SetBlipColour(blip,2)
		SetBlipScale(blip,0.4)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Disponível: ~g~"..v.name)
		EndTextCommandSetBlipName(blip)
		SetTimeout(30000,function()
			if DoesBlipExist(blip) then
				RemoveBlip(blip)
			end
		end)
	end
end