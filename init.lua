Facts = {
    init = false,
    names = {}, --loaded in from file
    values = {}
}

local GameSession = require('GameSession') --Game Session is copyright (c) 2021 psiberx
DiffFacts = {}

registerForEvent('onInit', function()
    local file = io.open("flags.txt")
    if(not (file == nil)) then
        for line in file:lines() do
            table.insert(Facts.names, line)
            table.insert(Facts.values,0)
        end
    
    else
        print("[[ERROR]]: flags.txt missing from FlagLog file system.")
        return
    end
        Bbs = Game.GetBlackboardSystem()
    GameSession.StoreInDir('sessions') -- Set directory to store session data
    GameSession.Persist(Facts.values) -- Link the data that should be watched and persisted 
    GameSession.OnLoad(function()
        print("loaded persisted data")
    end)
    print("FlagLog Initalized")
    GameSession.OnStart(function()
        print('Game Session Started')
        GameSession.TryLoad()
        DiffFacts = Facts.values
    end)

    GameSession.OnEnd(function()
        print('Game Session Ended')
        GameSession.TrySave()
        local diff = {}
        for i,m in Facts.values do
            if Facts.values[i] ~= DiffFacts[i] then
                diff[#diff +1] = Facts.values[i]
            end
        end
        local s = ""
        for i in pairs(diff) do
            s = s .. diff[i] .. "\t"
        end
        print(s)
    end)
end)

Message = {}
Duration = 5
Tick = 0
ShouldTick = false
local enableLogging = require('logging_state')

if enableLogging ~= false then
	enableLogging = true
end

registerHotkey('ToggleLog', 'Toggle logging', function()
	enableLogging = not enableLogging
    print("FlagLog Console Logging: " .. ((enableLogging and ("ON")) or ("OFF") ))

	local stateFile = io.open('logging_state.lua', 'w')

	if stateFile then
		stateFile:write('return ')
		stateFile:write(tostring(enableLogging))
		stateFile:close()
	end
end)

local bot = 0

registerForEvent("onUpdate", function()
   -- return
    if not GameSession.IsLoaded() then return end -- if the function inst ready, don't dump known facts
    
    Tick = Tick + 1
    local d = Duration*60
    for i = bot, bot + 500 do
        local fact = Facts.names[i]
        if not Facts.values[i] then Facts.values[i] = 0 goto continue end
        local currentFactVal = Game.CheckFactValue(fact) or Game.GetFact(fact)
        if currentFactVal ~= Facts.values[i] then
            Facts.values[i] = currentFactVal
            Message[#Message+1] = fact .. ": " .. tostring(currentFactVal)
        end
        ::continue::
    end
    bot = (bot + 100)%(#Facts.names)
    if Tick % d == d-1 then
        if #Message > 0 then
            local s = ""
            if #Message > 50 then --this is the opening load
                if not enableLogging then
                    print("Opening load caught")
                    GameSession.TrySave()
                else 
                    for i,m in ipairs(Message) do
                        s = s .. m .. "  "
                    end
                    print(s)
                end
                for i in pairs(Message) do
                    Message[i] = nil
                end
                return
            end
            for i,m in ipairs(Message) do
                s = s .. m .. "\n"
                table.remove(Message,i)
                if i>3 then
                    break
                end
            end
            ShowMessage(s)
            if enableLogging then
                print(s)
            end
        end
        Tick = 0
    end
end)

function ShowMessage(text)
	if text == nil or text == "" then
		return
	end

	local message = SimpleScreenMessage.new()
	message.message = text
	message.isShown = true
    message.isInstant = true
    message.duration = Duration

	local blackboardDefs = Game.GetAllBlackboardDefs()
	local blackboardUI = Game.GetBlackboardSystem():Get(blackboardDefs.UI_Notifications)

	blackboardUI:SetVariant(
		blackboardDefs.UI_Notifications.OnscreenMessage,
		ToVariant(message),
		true
	)
end

function PrintString(text)
    if text == nil or text == "" then
		return
	end
    --
    
    local m = SimpleScreenMessage.new()
    m.message = text
    m.isShown = true

    local blackboardDefs = Game.GetAllBlackboardDefs()
	local blackboardUI = Game.GetBlackboardSystem():Get(blackboardDefs.UI_Notifications)
	blackboardUI:SetVariant(
        blackboardDefs.UI_Notifications.OnscreenMessage,
		ToVariant(m),
		true
	)
end
