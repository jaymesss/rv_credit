local QBCore = exports[Config.CoreName]:GetCoreObject()
local PlayerJob = {}

Citizen.CreateThread(function()
    -- INFORMATION
    RequestModel(GetHashKey(Config.Information.Ped.Model))
    while not HasModelLoaded(GetHashKey(Config.Information.Ped.Model)) do
        Wait(1)
    end
    local ped = CreatePed(1, GetHashKey(Config.Information.Ped.Model), Config.Information.Ped.Coords, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    exports['qb-target']:AddBoxZone('credit-information', Config.Information.Target.Coords, 1.5, 1.6, {
        name = "credit-information",
        heading = Config.Information.Target.Heading,
        debugPoly = false
    }, {
        options = {
            {
                type = "client",
                event = "rv_credit:client:CreditInformation",
                icon = "fas fa-credit-card",
                label = Config.Information.Target.Label
            }
        }
    })
    -- TABLET SHOP
    if Config.TabletShop.Enabled then
        exports['qb-target']:AddBoxZone('tablet-shop', Config.TabletShop.Target.Coords, 1.5, 1.6, {
            name = "tablet-shop",
            heading = Config.TabletShop.Target.Heading,
            debugPoly = false
        }, {
            options = {
                {
                    type = "client",
                    event = "rv_bailbonds:client:OpenTabletShop",
                    icon = "fas fa-credit-card",
                    label = Config.TabletShop.Target.Label,
                    job = Config.JobName
                }
            }
        })
    end
    local Player = QBCore.Functions.GetPlayerData()
    if Player ~= nil then
        PlayerJob = Player.job
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    local Player = QBCore.Functions.GetPlayerData()
    PlayerJob = Player.job
end)

RegisterNetEvent("QBCore:Client:SetDuty", function(newDuty)
    PlayerJob.onduty = newDuty
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

function IsBanker()
    return PlayerJob.name == Config.JobName
end

RegisterNetEvent('rv_credit:client:CreditInformation', function()
    QBCore.Functions.Progressbar("pulling_up", Locale.Info.opening_information, 2000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
    }, {}, {}, function() -- Done
        local p = promise.new()
        local loans
        QBCore.Functions.TriggerCallback('rv_credit:server:GetPlayerLoans', function(result)
            p:resolve(result)
        end)
        loans = Citizen.Await(p)
        if loans[1] == nil then
            QBCore.Functions.Notify(Locale.Error.none_active, 'error', 5000)
            return
        end
        local options = {}
        for k,v in pairs(loans) do
            options[#options+1] = {
                title = v.name .. ' $' .. v.amount,
                description = Locale.Info.click_me,
                icon = 'dollar',
                onSelect = function()
                    TriggerEvent('rv_credit:client:PlayerLoanInfo', v)
                end
            }
        end
        lib.registerContext({
            id = 'player_loaninfo',
            title = Locale.Info.ongoing,
            options = options,
            -- onExit = function()
            --     lib.hideContext(false)
            --     Wait(150)
            --     TriggerEvent('rv_credit:client:BankerMenu')
            -- end
        })
        lib.showContext('player_loaninfo')
        Wait(100)
    end, function() -- Cancel
    end)
end)

RegisterNetEvent('rv_credit:client:OpenTablet', function()
    TriggerEvent('animations:client:EmoteCommandStart', {"tablet2"})
    QBCore.Functions.Progressbar("open_tablet", Locale.Info.opening_tablet, 2000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
    }, {}, {}, function() -- Done
        TriggerEvent('rv_credit:client:BankerMenu')
        Wait(100)
    end, function() -- Cancel
    end)
end)

RegisterNetEvent('rv_credit:client:BankerMenu', function()
    TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    lib.registerContext({
        id = 'banker_main_menu',
        title = Locale.Info.banker_menu,
        options = {
            {
                title = Locale.Info.create_loan,
                description = Locale.Info.create_loan_desc,
                icon = 'dollar',
                onSelect = function()   
                    TriggerEvent('rv_credit:client:CreateLoan')
                end
            },
            {
                title = Locale.Info.ongoing,
                description = Locale.Info.ongoing_desc,
                icon = 'credit-card',
                onSelect = function()   
                    TriggerEvent('rv_credit:client:OngoingLoans')
                end
            },
            {
                title = Locale.Info.old_loans,
                description = Locale.Info.old_loans_desc,
                icon = 'paperclip',
                onSelect = function()   
                    TriggerEvent('rv_credit:client:OldLoans')
                end
            },

        }
    })
    lib.showContext('banker_main_menu')
end)

RegisterNetEvent('rv_credit:client:CreateLoan', function()
    local input = lib.inputDialog(Locale.Info.create_loan, {
        {type = 'number', label = Locale.Info.target_id, required = true, icon = 'hashtag'},
        {type = 'input', label = Locale.Info.loan_name, required = true, icon = 'newspaper'},
        {type = 'number', label = Locale.Info.amount, required = true, icon = 'credit-card'},
        {type = 'number', label = Locale.Info.interest_rate, required = true, icon = 'chart-simple'},
        {type = 'number', label = Locale.Info.down_payment, required = true, icon = 'cash-register'},
        {type = 'number', label = Locale.Info.payment_amount, required = true, icon = 'hashtag'},
        {type = 'input', label = Locale.Info.notes, required = true, icon = 'paperclip'},
      })
      if input[1] ~= nil then
        TriggerServerEvent('rv_credit:server:CreateLoan', input)
    end
end)

RegisterNetEvent('rv_credit:client:OngoingLoans', function()
    local p = promise.new()
    local loans
    QBCore.Functions.TriggerCallback('rv_credit:server:GetOngoingLoans', function(result)
        p:resolve(result)
    end)
    loans = Citizen.Await(p)
    local options = {}
    for k,v in pairs(loans) do
        options[#options+1] = {
            title = v.fullname .. ' $' .. v.amount,
            description = Locale.Info.click_me,
            icon = 'dollar',
            onSelect = function()
                TriggerEvent('rv_credit:client:LoanInfo', v)
            end
        }
    end
    lib.registerContext({
        id = 'banker_loaninfo',
        title = Locale.Info.ongoing,
        options = options,
        -- onExit = function()
        --     lib.hideContext(false)
        --     Wait(150)
        --     TriggerEvent('rv_credit:client:BankerMenu')
        -- end
    })
    lib.showContext('banker_loaninfo')
end)

RegisterNetEvent('rv_credit:client:LoanInfo', function(loan)
    lib.registerContext({
        id = 'banker_loandetails',
        title = Locale.Info.loan_details,
        options = {
            {
                title = Locale.Info.full_name,
                description = loan.fullname,
                icon = 'cash-register',
            },
            {
                title = Locale.Info.loan_name,
                description = loan.name,
                icon = 'newspaper',
            },
            {
                title = Locale.Info.amount,
                description = '$' .. tostring(loan.amount),
                icon = 'credit-card',
            },
            {
                title = Locale.Info.interest_rate,
                description = tostring(loan.interest) .. '%',
                icon = 'chart-simple',
            },
            {
                title = Locale.Info.notes,
                description = loan.notes,
                icon = 'paperclip',
            },
        },
        -- onExit = function()
        --     lib.hideContext(false)
        --     Wait(150)
        --     TriggerEvent('rv_credit:client:OngoingLoans')
        -- end
    })
    lib.showContext('banker_loandetails')
end)

RegisterNetEvent('rv_credit:client:PlayerLoanInfo', function(loan)
    local amount = math.floor(loan.amount * tonumber('1.' .. loan.interest) / 24)
    lib.registerContext({
        id = 'banker_loandetails',
        title = Locale.Info.loan_details,
        options = {
            {
                title = Locale.Info.loan_name,
                description = loan.name,
                icon = 'newspaper',
            },
            {
                title = Locale.Info.amount,
                description = '$' .. tostring(loan.amount),
                icon = 'credit-card',
            },
            {
                title = Locale.Info.payments_left,
                description = loan.paymentsleft .. ' of $' .. amount,
                icon = 'cash-register',
            },
            {
                title = Locale.Info.interest_rate,
                description = tostring(loan.interest) .. '%',
                icon = 'chart-simple',
            },
            {
                title = Locale.Info.notes,
                description = loan.notes,
                icon = 'paperclip',
            },
        },
        -- onExit = function()
        --     lib.hideContext(false)
        --     Wait(150)
        --     TriggerEvent('rv_credit:client:OngoingLoans')
        -- end
    })
    lib.showContext('banker_loandetails')
end)

RegisterNetEvent('rv_credit:client:OldLoans', function()
    local p = promise.new()
    local loans
    QBCore.Functions.TriggerCallback('rv_credit:server:GetOldLoans', function(result)
        p:resolve(result)
    end)
    loans = Citizen.Await(p)
    local options = {}
    for k,v in pairs(loans) do
        options[#options+1] = {
            title = v.fullname .. ' $' .. v.amount,
            description = v.name,
            icon = 'dollar',
        }
    end
    lib.registerContext({
        id = 'banker_oldloans',
        title = Locale.Info.old_loans,
        options = options,
        -- onExit = function()
        --     lib.hideContext(false)
        --     Wait(150)
        --     TriggerEvent('rv_credit:client:BankerMenu')
        -- end
    })
    lib.showContext('banker_oldloans')
end)

RegisterNetEvent('rv_bailbonds:client:OpenTabletShop', function()
    if not IsBanker() then
        QBCore.Functions.Notify(Locale.Errors.not_banker, 'error', 5000)
        return
    end
    local authorizedItems = {
        label = Config.TabletShop.Label,
        slots = 50,
        items = {}
    }
    items = {
        {name = Config.TabletItem, price = Config.TabletPrice, amount = 50, type = "item", slot = 1, authorizedGrades = {0, 1, 2, 3, 4, 5}, info = {}},
    }
    index = 1
    for _, armoryItem in pairs(items) do
        authorizedItems.items[index] = armoryItem
        authorizedItems.items[index].slot = index
        index = index + 1
    end
    TriggerServerEvent('inventory:server:OpenInventory', 'shop', Config.JobName, authorizedItems)
end)