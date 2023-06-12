-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local sanitizes = module("cfg/sanitizes")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONEXÃO
-----------------------------------------------------------------------------------------------------------------------------------------
src = {}
Tunnel.bindInterface("vrp_homes",src)
vCLIENT = Tunnel.getInterface("vrp_homes")
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEBHOOK
-----------------------------------------------------------------------------------------------------------------------------------------
local webhookbaucasas = ""

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PREPARES
-----------------------------------------------------------------------------------------------------------------------------------------
vRP._prepare("homes/get_homeuser","SELECT * FROM vrp_homes_permissions WHERE user_id = @user_id AND home = @home")
vRP._prepare("homes/get_homeuserid","SELECT * FROM vrp_homes_permissions WHERE user_id = @user_id")
vRP._prepare("homes/get_homeuserowner","SELECT * FROM vrp_homes_permissions WHERE user_id = @user_id AND home = @home AND owner = 1")
vRP._prepare("homes/get_homeuseridowner","SELECT * FROM vrp_homes_permissions WHERE home = @home AND owner = 1")
vRP._prepare("homes/get_homepermissions","SELECT * FROM vrp_homes_permissions WHERE home = @home")
vRP._prepare("homes/add_permissions","INSERT IGNORE INTO vrp_homes_permissions(home,user_id) VALUES(@home,@user_id)")
vRP._prepare("homes/buy_permissions","INSERT IGNORE INTO vrp_homes_permissions(home,user_id,owner,tax,garage) VALUES(@home,@user_id,1,@tax,1)")
vRP._prepare("homes/count_homepermissions","SELECT COUNT(*) as qtd FROM vrp_homes_permissions WHERE home = @home")
vRP._prepare("homes/upd_permissions","UPDATE vrp_homes_permissions SET garage = 1 WHERE home = @home AND user_id = @user_id")
vRP._prepare("homes/rem_permissions","DELETE FROM vrp_homes_permissions WHERE home = @home AND user_id = @user_id")
vRP._prepare("homes/upd_taxhomes","UPDATE vrp_homes_permissions SET tax = @tax WHERE user_id = @user_id, home = @home AND owner = 1")
vRP._prepare("homes/rem_allpermissions","DELETE FROM vrp_homes_permissions WHERE home = @home")
vRP._prepare("homes/get_allhomes","SELECT * FROM vrp_homes_permissions WHERE owner = @owner")
vRP._prepare("homes/get_allvehs","SELECT * FROM vrp_vehicles")
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOMESINFO
-----------------------------------------------------------------------------------------------------------------------------------------
local homes = {
-----------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------FORTHILLS-----------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
	["NOME DA CASA"] = { 5000000,2,1000 },
--[[
	NOME DA CASA = O MESMO NOME DA CASA DO CLIENT.LUA
	5000000 = VALOR DA CASA
	2 = QUANTAS PESSOAS VÃO PODER TER ACESSO A CASA
	1000 = TAMANHO DO BAU
]]	
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIÁVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local actived = {}
local blipHomes = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLIPHOMES
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		blipHomes = {}
		for k,v in pairs(homes) do
			local checkHomes = vRP.query("homes/get_homeuseridowner",{ home = tostring(k) })
			if checkHomes[1] == nil then
				table.insert(blipHomes,{ name = tostring(k) })
				Citizen.Wait(10)
			end
		end
		Citizen.Wait(30*60000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOMES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand('casas',function(source,args,rawCommand)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		if args[1] == "add" and homes[tostring(args[2])] then
			local myHomes = vRP.query("homes/get_homeuserowner",{ user_id = parseInt(user_id), home = tostring(args[2]) })
			if myHomes[1] then
				local totalResidents = vRP.query("homes/count_homepermissions",{ home = tostring(args[2]) })
				if parseInt(totalResidents[1].qtd) >= parseInt(homes[tostring(args[2])][2]) then
					TriggerClientEvent("Notify",source,"negado","A residência "..tostring(args[2]).." atingiu o máximo de moradores.",10000)
					return
				end

				vRP.execute("homes/add_permissions",{ home = tostring(args[2]), user_id = parseInt(args[3]) })
				local identity = vRP.getUserIdentity(parseInt(args[3]))
				if identity then
					TriggerClientEvent("Notify",source,"sucesso","Permissão na residência <b>"..tostring(args[2]).."</b> adicionada para <b>"..identity.name.." "..identity.firstname.."</b>.",10000)
				end
			end
		elseif args[1] == "rem" and homes[tostring(args[2])] then
			local myHomes = vRP.query("homes/get_homeuserowner",{ user_id = parseInt(user_id), home = tostring(args[2]) })
			if myHomes[1] then
				local userHomes = vRP.query("homes/get_homeuser",{ user_id = parseInt(args[3]), home = tostring(args[2]) })
				if userHomes[1] then
					vRP.execute("homes/rem_permissions",{ home = tostring(args[2]), user_id = parseInt(args[3]) })
					local identity = vRP.getUserIdentity(parseInt(args[3]))
					if identity then
						TriggerClientEvent("Notify",source,"importante","Permissão na residência <b>"..tostring(args[2]).."</b> removida de <b>"..identity.name.." "..identity.firstname.."</b>.",10000)
					end
				end
			end
		elseif args[1] == "garagem" and homes[tostring(args[2])] then
			local myHomes = vRP.query("homes/get_homeuserowner",{ user_id = parseInt(user_id), home = tostring(args[2]) })
			if myHomes[1] then
				local userHomes = vRP.query("homes/get_homeuser",{ user_id = parseInt(args[3]), home = tostring(args[2]) })
				if userHomes[1] then
					if vRP.tryFullPayment(user_id,50000) then
						vRP.execute("homes/upd_permissions",{ home = tostring(args[2]), user_id = parseInt(args[3]) })
						local identity = vRP.getUserIdentity(parseInt(args[3]))
						if identity then
							TriggerClientEvent("Notify",source,"sucesso","Adicionado a permissão da garagem a <b>"..identity.name.." "..identity.firstname.."</b>.",10000)
						end
					else
						TriggerClientEvent("Notify",source,"negado","Dinheiro insuficiente.",10000)
					end
				end
			end
		elseif args[1] == "lista" then
			vCLIENT.setBlipsHomes(source,blipHomes)
		elseif args[1] == "check" and homes[tostring(args[2])] then
			local myHomes = vRP.query("homes/get_homeuserowner",{ user_id = parseInt(user_id), home = tostring(args[2]) })
			if myHomes[1] then
				local userHomes = vRP.query("homes/get_homepermissions",{ home = tostring(args[2]) })
				if parseInt(#userHomes) > 1 then
					local permissoes = ""
					for k,v in pairs(userHomes) do
						if v.user_id ~= user_id then
							local identity = vRP.getUserIdentity(v.user_id)
							permissoes = permissoes.."<b>Nome:</b> "..identity.name.." "..identity.firstname.." - <b>Passaporte:</b> "..v.user_id
							if k ~= #userHomes then
								permissoes = permissoes.."<br>"
							end
						end
						Citizen.Wait(10)
					end
					TriggerClientEvent("Notify",source,"importante","Permissões da residência <b>"..tostring(args[2]).."</b>: <br>"..permissoes,20000)
				else
					TriggerClientEvent("Notify",source,"negado","Nenhuma permissão encontrada.",20000)
				end
			end
		elseif args[1] == "transfer" and homes[tostring(args[2])] then
			local myHomes = vRP.query("homes/get_homeuserowner",{ user_id = parseInt(user_id), home = tostring(args[2]) })
			if myHomes[1] then
				local identity = vRP.getUserIdentity(parseInt(args[3]))
				if identity then
					local ok = vRP.request(source,"Transferir a residência <b>"..tostring(args[2]).."</b> para <b>"..identity.name.." "..identity.firstname.."</b> ?",30)
					if ok then
						vRP.execute("homes/rem_allpermissions",{ home = tostring(args[2]) })
						vRP.execute("homes/buy_permissions",{ home = tostring(args[2]), user_id = parseInt(args[3]), tax = parseInt(myHomes[1].tax) })
						TriggerClientEvent("Notify",source,"importante","Transferiu a residência <b>"..tostring(args[2]).."</b> para <b>"..identity.name.." "..identity.firstname.."</b>.",10000)
					end
				end
			end
		elseif args[1] == "tax" and homes[tostring(args[2])] then
			local ownerHomes = vRP.query("homes/get_homeuseridowner",{ home = tostring(args[2]) })
			if ownerHomes[1] then
				--if not vRP.hasGroup(user_id,"Platina") then
					local house_price = parseInt(homes[tostring(args[2])][1])
					local house_tax = 0.10
					if house_price >= 7000000 then
						house_tax = 0.00
					end
					if vRP.tryFullPayment(user_id,parseInt(house_price * house_tax)) then
						vRP.execute("homes/rem_permissions",{ home = tostring(args[2]), user_id = parseInt(ownerHomes[1].user_id) })
						vRP.execute("homes/buy_permissions",{ home = tostring(args[2]), user_id = parseInt(ownerHomes[1].user_id), tax = parseInt(os.time()) })
						TriggerClientEvent("Notify",source,"sucesso","Pagamento de <b>$"..vRP.format(parseInt(house_price * house_tax)).." dólares</b> efetuado com sucesso.",10000)
					else
						TriggerClientEvent("Notify",source,"negado","Dinheiro insuficiente.",10000)
					end
				--end
			end
		else
			local myHomes = vRP.query("homes/get_homeuserid",{ user_id = parseInt(user_id) })
			if parseInt(#myHomes) >= 1 then
				for k,v in pairs(myHomes) do
					local ownerHomes = vRP.query("homes/get_homeuseridowner",{ home = tostring(v.home) })
					if ownerHomes[1] then
						local house_price = parseInt(homes[tostring(v.home)][1])
						local house_tax = 0.10
						if house_price >= 7000000 then
							house_tax = 0.00
						end

						if parseInt(os.time()) >= parseInt(ownerHomes[1].tax+24*15*60*60) then
							TriggerClientEvent("Notify",source,"negado","<b>Residência:</b> "..v.home.."<br><b>Property Tax:</b> Atrasado<br>Valor: <b>$"..vRP.format(parseInt(house_price * house_tax)).." dólares</b>",20000)
						else
							TriggerClientEvent("Notify",source,"importante","<b>Residência:</b> "..v.home.."<br>Taxa em: "..vRP.getDayHours(parseInt(86400*15-(os.time()-ownerHomes[1].tax))).."<br>Valor: <b>$"..vRP.format(parseInt(house_price * house_tax)).." dólares</b>",20000)
						end
						Citizen.Wait(10)
					end
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLIPS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:playerSpawn",function(user_id,source,first_spawn)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local myHomes = vRP.query("homes/get_homeuserid",{ user_id = parseInt(user_id) })
		if parseInt(#myHomes) >= 1 then
			for k,v in pairs(myHomes) do
				vCLIENT.setBlipsOwner(source,v.home)
				Citizen.Wait(10)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACTIVEDOWNTIME
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(2000)
		for k,v in pairs(actived) do
			if v > 0 then
				actived[k] = v - 2
				if v == 0 then
					actived[k] = nil
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKPERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
local answered = {}
function src.checkPermissions(homeName)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local identity = vRP.getUserIdentity(user_id)
		if identity then
			if not vRP.searchReturn(source,user_id) then
				local homeResult = vRP.query("homes/get_homepermissions",{ home = tostring(homeName) })
				if parseInt(#homeResult) >= 1 then
					local myResult = vRP.query("homes/get_homeuser",{ user_id = parseInt(user_id), home = tostring(homeName) })
					local resultOwner = vRP.query("homes/get_homeuseridowner",{ home = tostring(homeName) })
					if myResult[1] then

						if homes[homeName][1] >= 7000000 then
							return true
						end

						if parseInt(os.time()) >= parseInt(resultOwner[1].tax+24*18*60*60) then

							local cows = vRP.getSData("chest:"..tostring(homeName))
							local rows = json.decode(cows) or {}
							if rows then
								vRP.execute("creative/rem_srv_data",{ dkey = "chest:"..tostring(homeName) })
							end

							vRP.execute("homes/rem_allpermissions",{ home = tostring(homeName) })
							TriggerClientEvent("Notify",source,"importante","A <b>Property Tax</b> venceu por <b>3 dias</b> e a casa foi vendida.",10000)
							return false
						elseif parseInt(os.time()) <= parseInt(resultOwner[1].tax+24*15*60*60) then
							return true
						else
							TriggerClientEvent("Notify",source,"importante","A <b>Property Tax</b> da residência está atrasada.",10000)
							return false
						end
					else
						if parseInt(os.time()) >= parseInt(resultOwner[1].tax+24*18*60*60) and homes[homeName][1] < 5000000 then

							local cows = vRP.getSData("chest:"..tostring(homeName))
							local rows = json.decode(cows) or {}
							if rows then
								vRP.execute("creative/rem_srv_data",{ dkey = "chest:"..tostring(homeName) })
							end

							vRP.execute("homes/rem_allpermissions",{ home = tostring(homeName) })
							return false
						end

						if parseInt(os.time()) >= parseInt(resultOwner[1].tax+24*15*60*60) and homes[homeName][1] < 5000000 then
							TriggerClientEvent("Notify",source,"importante","A <b>Property Tax</b> da residência está atrasada.",10000)
							return false
						end

						answered[user_id] = nil
						for k,v in pairs(homeResult) do
							local player = vRP.getUserSource(parseInt(v.user_id))
							if player then
								if not answered[user_id] then
									TriggerClientEvent("Notify",player,"importante","<b>"..identity.name.." "..identity.firstname.."</b> tocou o interfone da residência <b>"..tostring(homeName).."</b>.<br>Deseja permitir a entrada do mesmo?",10000)
									local ok = vRP.request(player,"Permitir acesso a residência?",30)
									if ok then
										answered[user_id] = true
										return true
									end
								end
							end
							Citizen.Wait(10)
						end
					end
				else
					local ok = vRP.request(source,"Deseja efetuar a compra da residência <b>"..tostring(homeName).."</b> por <b>$"..vRP.format(parseInt(homes[tostring(homeName)][1])).."</b> ?",30)
					if ok then
						if vRP.tryFullPayment(user_id,parseInt(homes[tostring(homeName)][1])) then
							vRP.execute("homes/buy_permissions",{ home = tostring(homeName), user_id = parseInt(user_id), tax = parseInt(os.time()) })
							TriggerClientEvent("Notify",source,"sucesso","A residência <b>"..tostring(homeName).."</b> foi comprada com sucesso.",10000)
						else
							TriggerClientEvent("Notify",source,"negado","Dinheiro insuficiente.",10000)
						end
					end
					return false
				end
			end
		end
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKINTPERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function src.checkIntPermissions(homeName)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		if not vRP.searchReturn(source,user_id) then
			local myResult = vRP.query("homes/get_homeuser",{ user_id = parseInt(user_id), home = tostring(homeName) })
			if myResult[1] or vRP.hasPermission(user_id,"policia.permissao") then
				return true
			end
		end
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OUTFIT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand('outfit',function(source,args,rawCommand)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local homeName = vCLIENT.getHomeStatistics(source)
		local myResult = vRP.query("homes/get_homeuser",{ user_id = parseInt(user_id), home = tostring(homeName) })
		if myResult[1] then
			local data = vRP.getSData("outfit:"..tostring(homeName))
			local result = json.decode(data) or {}
			if result then
				if args[1] == "save" and args[2] then
					local custom = vRPclient.getCustomPlayer(source)
					if custom then
						local outname = sanitizeString(rawCommand:sub(13),sanitizes.homename[1],sanitizes.homename[2])
						if result[outname] == nil and string.len(outname) > 0 then
							result[outname] = custom
							vRP.setSData("outfit:"..tostring(homeName),json.encode(result))
							TriggerClientEvent("Notify",source,"sucesso","Outfit <b>"..outname.."</b> adicionado com sucesso.",10000)
						else
							TriggerClientEvent("Notify",source,"importante","Nome escolhido já existe na lista de <b>Outfits</b>.",10000)
						end
					end
				elseif args[1] == "rem" and args[2] then
					local outname = sanitizeString(rawCommand:sub(12),sanitizes.homename[1],sanitizes.homename[2])
					if result[outname] ~= nil and string.len(outname) > 0 then
						result[outname] = nil
						vRP.setSData("outfit:"..tostring(homeName),json.encode(result))
						TriggerClientEvent("Notify",source,"sucesso","Outfit <b>"..outname.."</b> removido com sucesso.",10000)
					else
						TriggerClientEvent("Notify",source,"negado","Nome escolhido não encontrado na lista de <b>Outfits</b>.",10000)
					end
				elseif args[1] == "apply" and args[2] then
					local outname = sanitizeString(rawCommand:sub(14),sanitizes.homename[1],sanitizes.homename[2])
					if result[outname] ~= nil and string.len(outname) > 0 then
						TriggerClientEvent("updateRoupas",source,result[outname])
						TriggerClientEvent("Notify",source,"sucesso","Outfit <b>"..outname.."</b> aplicado com sucesso.",10000)
					else
						TriggerClientEvent("Notify",source,"negado","Nome escolhido não encontrado na lista de <b>Outfits</b>.",10000)
					end
				else
					for k,v in pairs(result) do
						TriggerClientEvent("Notify",source,"importante","<b>Outfit:</b> "..k,20000)
						Citizen.Wait(10)
					end
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OPENCHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function src.openChest(homeName)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local hsinventory = {}
		local myinventory = {}
		local data = vRP.getSData("chest:"..tostring(homeName))
		local result = json.decode(data) or {}
		if result then
			for k,v in pairs(result) do
				table.insert(hsinventory,{ amount = parseInt(v.amount), name = vRP.itemNameList(k), index = vRP.itemIndexList(k), key = k, peso = vRP.getItemWeight(k) })
			end

			local inv = vRP.getInventory(parseInt(user_id))
			for k,v in pairs(inv) do
				table.insert(myinventory,{ amount = parseInt(v.amount), name = vRP.itemNameList(k), index = vRP.itemIndexList(k), key = k, peso = vRP.getItemWeight(k) })
			end
		end
		return hsinventory,myinventory,vRP.getInventoryWeight(user_id),vRP.getInventoryMaxWeight(user_id),vRP.computeItemsWeight(result),parseInt(homes[tostring(homeName)][3])
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOREITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function src.storeItem(homeName,itemName,amount)
	local source = source
	if itemName then
		local user_id = vRP.getUserId(source)
		local identity = vRP.getUserIdentity(user_id)
		if user_id and actived[parseInt(user_id)] == 0 or not actived[parseInt(user_id)] then
			if string.match(itemName,"identidade") then
				TriggerClientEvent("Notify",source,"importante","Não pode guardar este item.",8000)
				return
			end

			local data = vRP.getSData("chest:"..tostring(homeName))
			local items = json.decode(data) or {}
			if items then
				if parseInt(amount) > 0 then
					local new_weight = vRP.computeItemsWeight(items)+vRP.getItemWeight(itemName)*parseInt(amount)
					if new_weight <= parseInt(homes[tostring(homeName)][3]) then
						if vRP.tryGetInventoryItem(parseInt(user_id),itemName,parseInt(amount)) then
							SendWebhookMessage(webhookbaucasas,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[GUARDOU]: "..vRP.format(parseInt(amount)).." "..vRP.itemNameList(itemName).." \n[BAU]: "..(tostring(homeName)).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
							if items[itemName] ~= nil then
								items[itemName].amount = parseInt(items[itemName].amount) + parseInt(amount)
							else
								items[itemName] = { amount = parseInt(amount) }
							end
							actived[parseInt(user_id)] = 2
						end
					else
						TriggerClientEvent("Notify",source,"negado","<b>Vault</b> cheio.",8000)
					end
				else
					local inv = vRP.getInventory(parseInt(user_id))
					for k,v in pairs(inv) do
						if itemName == k then
							local new_weight = vRP.computeItemsWeight(items)+vRP.getItemWeight(itemName)*parseInt(v.amount)
							if new_weight <= parseInt(homes[tostring(homeName)][3]) then
								if vRP.tryGetInventoryItem(parseInt(user_id),itemName,parseInt(v.amount)) then
									if items[itemName] ~= nil then
										items[itemName].amount = parseInt(items[itemName].amount) + parseInt(v.amount)
									else
										items[itemName] = { amount = parseInt(v.amount) }
									end
									SendWebhookMessage(webhookbaucasas,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[GUARDOU]: "..vRP.format(parseInt(v.amount)).." "..vRP.itemNameList(itemName).." \n[BAU]: "..(tostring(homeName)).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
									actived[parseInt(user_id)] = 2
								end
							else
								TriggerClientEvent("Notify",source,"negado","<b>Vault</b> cheio.",8000)
							end
						end
					end
				end
				vRP.setSData("chest:"..tostring(homeName),json.encode(items))
				TriggerClientEvent('Creative:UpdateVault',source,'updateVault')
			end
		end
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function src.takeItem(homeName,itemName,amount)
	local source = source
	if itemName then
		local user_id = vRP.getUserId(source)
		local identity = vRP.getUserIdentity(user_id)
		if user_id and actived[parseInt(user_id)] == 0 or not actived[parseInt(user_id)] then
			local data = vRP.getSData("chest:"..tostring(homeName))
			local items = json.decode(data) or {}
			if items then
				if parseInt(amount) > 0 then
					if items[itemName] ~= nil and parseInt(items[itemName].amount) >= parseInt(amount) then
						if vRP.getInventoryWeight(parseInt(user_id))+vRP.getItemWeight(itemName)*parseInt(amount) <= vRP.getInventoryMaxWeight(parseInt(user_id)) then
							SendWebhookMessage(webhookbaucasas,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[RETIROU]: "..vRP.format(parseInt(amount)).." "..vRP.itemNameList(itemName).." \n[BAU]: "..(tostring(homeName)).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
							vRP.giveInventoryItem(parseInt(user_id),itemName,parseInt(amount))
							items[itemName].amount = parseInt(items[itemName].amount) - parseInt(amount)
							if parseInt(items[itemName].amount) <= 0 then
								items[itemName] = nil
							end
							actived[parseInt(user_id)] = 2
						else
							TriggerClientEvent("Notify",source,"negado","<b>Mochila</b> cheia.",8000)
						end
					end
				else
					if items[itemName] ~= nil and parseInt(items[itemName].amount) >= parseInt(amount) then
						if vRP.getInventoryWeight(parseInt(user_id))+vRP.getItemWeight(itemName)*parseInt(items[itemName].amount) <= vRP.getInventoryMaxWeight(parseInt(user_id)) then
							SendWebhookMessage(webhookbaucasas,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[RETIROU]: "..vRP.format(parseInt(items[itemName].amount)).." "..vRP.itemNameList(itemName).." \n[BAU]: "..(tostring(homeName)).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
							vRP.giveInventoryItem(parseInt(user_id),itemName,parseInt(items[itemName].amount))
							items[itemName] = nil
							actived[parseInt(user_id)] = 2
						else
							TriggerClientEvent("Notify",source,"negado","<b>Mochila</b> cheia.",8000)
						end
					end
				end
				TriggerClientEvent('Creative:UpdateVault',source,'updateVault')
				vRP.setSData("chest:"..tostring(homeName),json.encode(items))
			end
		end
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKPOLICE
-----------------------------------------------------------------------------------------------------------------------------------------
function src.checkPolice()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		if vRP.hasPermission(user_id,"policia.permissao") then
			return true
		end
		return false
	end
end