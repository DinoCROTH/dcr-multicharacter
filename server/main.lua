-- Functions

local StarterItems = {
    ['apple'] = { amount = 1, item = 'apple' }
}


local function GiveStarterItems(source)
    local Player = exports['dcr-core']:GetPlayer(source)
    for k, v in pairs(StarterItems) do
        Player.Functions.AddItem(v.item, 1)
    end
end

local function loadHouseData()
    local HouseGarages = {}
    local Houses = {}
    local result = MySQL.query.await('SELECT * FROM houselocations')
    if result[1] ~= nil then
        for k, v in pairs(result) do
            local owned = false
            if tonumber(v.owned) == 1 then
                owned = true
            end
            local garage = v.garage ~= nil and json.decode(v.garage) or {}
            Houses[v.name] = {
                coords = json.decode(v.coords),
                owned = v.owned,
                price = v.price,
                locked = true,
                adress = v.label,
                tier = v.tier,
                garage = garage,
                decorations = {},
            }
            HouseGarages[v.name] = {
                label = v.label,
                takeVehicle = garage,
            }
        end
    end
    TriggerClientEvent("dcr-garages:client:houseGarageConfig", -1, HouseGarages)
    TriggerClientEvent("dcr-houses:client:setHouseConfig", -1, Houses)
end

RegisterNetEvent('dcr-multicharacter:server:disconnect', function(source)
    DropPlayer(source, "You have disconnected from DCCore RedM")
end)

RegisterNetEvent('dcr-multicharacter:server:loadUserData', function(cData)
    local src = source
    if exports['dcr-core']:Login(src, cData.citizenid) then
        print('^2[dcr-core]^7 '..GetPlayerName(src)..' (Citizen ID: '..cData.citizenid..') has succesfully loaded!')
        exports['dcr-core']:RefreshCommands(src)
        TriggerClientEvent("dcr-multicharacter:client:closeNUI", src)
        TriggerClientEvent('dcr-spawn:client:setupSpawnUI', src, cData, false)
        TriggerEvent("dcr-log:server:CreateLog", "joinleave", "Loaded", "green", "**".. GetPlayerName(src) .. "** ("..cData.citizenid.." | "..src..") loaded..")
	end
end)

RegisterNetEvent('dcr-multicharacter:server:createCharacter', function(data, enabledhouses)
    local newData = {}
    local src = source
    newData.cid = data.cid
    newData.charinfo = data
    if exports['dcr-core']:Login(src, false, newData) then
        exports['dcr-core']:ShowSuccess(GetCurrentResourceName(), GetPlayerName(src)..' has succesfully loaded!')
        exports['dcr-core']:RefreshCommands(src)
        --[[if enabledhouses then loadHouseData() end]] -- Enable once housing is ready
        TriggerClientEvent("dcr-multicharacter:client:closeNUI", src)
        TriggerClientEvent('dcr-spawn:client:setupSpawnUI', src, newData, true)
        GiveStarterItems(src)
	end
end)

RegisterNetEvent('dcr-multicharacter:server:deleteCharacter', function(citizenid)
    exports['dcr-core']:DeleteCharacter(source, citizenid)
end)

-- Callbacks

exports['dcr-core']:CreateCallback("dc-multicharacter:server:setupCharacters", function(source, cb)
    local license = exports['dcr-core']:GetIdentifier(source, 'license')
    local plyChars = {}
    MySQL.query('SELECT * FROM players WHERE license = @license', {['@license'] = license}, function(result)
        for i = 1, (#result), 1 do
            result[i].charinfo = json.decode(result[i].charinfo)
            result[i].money = json.decode(result[i].money)
            result[i].job = json.decode(result[i].job)
            plyChars[#plyChars+1] = result[i]
        end
        cb(plyChars)
    end)
end)

exports['dcr-core']:CreateCallback("dc-multicharacter:server:GetNumberOfCharacters", function(source, cb)
    local license = exports['dcr-core']:GetIdentifier(source, 'license')
    local numOfChars = 0
    if next(Config.PlayersNumberOfCharacters) then
        for i, v in pairs(Config.PlayersNumberOfCharacters) do
            if v.license == license then
                numOfChars = v.numberOfChars
                break
            else
                numOfChars = Config.DefaultNumberOfCharacters
            end
        end
    else
        numOfChars = Config.DefaultNumberOfCharacters
    end
    cb(numOfChars)
end)

exports['dcr-core']:CreateCallback("dcr-multicharacter:server:getSkin", function(source, cb, cid)
    MySQL.query('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', {cid, 1}, function(result)
        result[1].skin = json.decode(result[1].skin)
        result[1].clothes = json.decode(result[1].clothes)
        cb(result[1])
    end)
end)

-- Commands

exports['dcr-core']:AddCommand("logout", "Logout of Character (Admin Only)", {}, false, function(source)
    exports['dcr-core']:Logout(source)
    TriggerClientEvent('dcr-multicharacter:client:chooseChar', source)
end, 'admin')

exports['dcr-core']:AddCommand("closeNUI", "Close Multi NUI", {}, false, function(source)
    TriggerClientEvent('dc-multicharacter:client:closeNUI', source)
end, 'user')
