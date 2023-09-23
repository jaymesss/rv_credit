local QBCore = exports[Config.CoreName]:GetCoreObject()
local notified = {}

Citizen.CreateThread(function()
    while true do
        local response = MySQL.query.await('SELECT * FROM creditloans')
        local time = os.time()
        for k,v in pairs (response) do
            if v.lastpaymenttime + 86400 < time then
                local Player = QBCore.Functions.GetPlayerByCitizenId(v.citizenid)
                if Player ~= nil then
                    local src = Player.PlayerData.source
                    if not Config.AllowDebt and v.amount > Player.Functions.GetMoney('bank') then
                        if not notified[src] then
                            TriggerClientEvent('QBCore:Notify', src, Locale.Error.cant_pay, 'error')
                        end
                        table.insert(notified, src)
                    else
                        local amount = math.floor(v.amount * tonumber('1.' .. v.interest))
                        Player.Functions.RemoveMoney('bank', math.floor(amount / v.totalpayments))
                        exports['qb-management']:AddMoney(Config.JobName, amount / v.totalpayments)
                        TriggerClientEvent('QBCore:Notify', src, string.gsub(Locale.Success.paid_off, 'amount', v.amount), 'success')
                        if v.paymentsleft - 1 <= 0 then
                            MySQL.Async.execute('DELETE FROM creditloans WHERE id=?', { v.id })  
                            MySQL.insert.await('INSERT INTO `creditloanhistory` (fullname, name, amount) VALUES (?, ?, ?)', {
                                v.fullname, v.name, v.amount
                            })
                        else
                            MySQL.Async.execute('UPDATE creditloans SET paymentsleft = ? WHERE id = ?', {
                                v.paymentsleft - 1, v.id
                            })
                            MySQL.Async.execute('UPDATE creditloans SET lastpaymenttime = ? WHERE id = ?', {
                                time, v.id
                            })
                        end
                    end
                end
            end 
        end
        Wait(60000)
    end
end)

QBCore.Functions.CreateUseableItem(Config.TabletItem, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player.Functions.GetItemByName(Config.TabletItem) then return end
    if Player.PlayerData.job.name ~= Config.JobName then
        TriggerClientEvent('QBCore:Notify', src, Locale.Errors.not_banker, 'error')
        return
    end
    TriggerClientEvent('rv_credit:client:OpenTablet', src)
end)

QBCore.Functions.CreateCallback('rv_credit:server:GetPlayerLoans', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local response = MySQL.query.await('SELECT * FROM creditloans WHERE citizenid = ?', {
        Player.PlayerData.citizenid
    })
    cb(response)
end)

QBCore.Functions.CreateCallback('rv_credit:server:GetOngoingLoans', function(source, cb)
    local src = source
    local response = MySQL.query.await('SELECT * FROM creditloans')
    cb(response)
end)

QBCore.Functions.CreateCallback('rv_credit:server:GetOldLoans', function(source, cb)
    local src = source
    local response = MySQL.query.await('SELECT * FROM creditloanhistory')
    cb(response)
end)

RegisterNetEvent('rv_credit:server:CreateLoan', function(input)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.name ~= Config.JobName then
        return
    end
    local target = input[1]
    local OtherPlayer = QBCore.Functions.GetPlayer(target)
    if OtherPlayer == nil then
        TriggerClientEvent('QBCore:Notify', src, Locale.Error.player_not_found, 'error')
        return
    end
    local name = input[2]
    local amount = input[3]
    local interestrate = input[4]
    local downpayment = input[5]
    local paymentamount = input[6]
    local notes = input[7]
    if amount > exports['qb-management']:GetAccount(Config.JobName) then
        TriggerClientEvent('QBCore:Notify', src, Locale.Error.company_cant_afford, 'error')
        return
    end
    if downpayment > OtherPlayer.Functions.GetMoney('bank') then
        TriggerClientEvent('QBCore:Notify', src, Locale.Error.player_cant_afford, 'error')
        return
    end
    exports['qb-management']:RemoveMoney(Config.JobName, amount - downpayment)
    OtherPlayer.Functions.RemoveMoney('bank', amount)
    TriggerClientEvent('QBCore:Notify', src, string.gsub(string.gsub(Locale.Success.you_gave, 'amount', amount), 'fullname', OtherPlayer.PlayerData.charinfo.firstname .. ' ' .. OtherPlayer.PlayerData.charinfo.lastname), 'success')
    TriggerClientEvent('QBCore:Notify', target, string.gsub(Locale.Success.received, 'amount', amount), 'success')
    MySQL.insert.await('INSERT INTO `creditloans` (id, citizenid, fullname, name, amount, interest, paymentsleft, totalpayments, lastpaymenttime, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        math.random(111111, 999999), Player.PlayerData.citizenid, OtherPlayer.PlayerData.charinfo.firstname .. ' ' .. OtherPlayer.PlayerData.charinfo.lastname, name, amount, interestrate, paymentamount, paymentamount, os.time(), notes
    })
end)