Facts = {
    init = false,
    names = {}, --loaded in from file
    values = {}
}

local GameSession = require('GameSession') --Game Session is copyright (c) 2021 psiberx
DiffFacts = {}

registerForEvent('onInit', function()
    local file = io.open("facts.txt")
    if(not (file == nil)) then
        for line in file:lines() do
            table.insert(Facts.names, line)
            table.insert(Facts.values,0)
        end
    else
        print("[[ERROR]]: facts.txt missing from FactLog file system.")
        return
    end
    Bbs = Game.GetBlackboardSystem()
    GameSession.StoreInDir('sessions') -- Set directory to store session data
    GameSession.Persist(Facts.values) -- Link the data that should be watched and persisted 
    GameSession.OnLoad(function()
        print("loaded persisted data")
    end)
    print("FactLog Initalized")
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
local modEnabled = require('mod_on')
if modEnabled ~= false then
	modEnabled = true
end

local bot = 0
registerForEvent("onUpdate", function()
    if not modEnabled then return end
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
    if PacifistMode and (Game.GetFact("gmpl_npc_killed_by_player")==1) then
        Game.GetQuestsSystem():SetFactStr("factlog_failedpacifist",1)
        PrintWarning("Failed pacifism. Reload save",3.00)
        Facts.values[0] = 1
    end
    bot = (bot + 100)%(#Facts.names)
    if Tick % d == d-1 then
        if #Message > 0 then
            local s = ""
            if #Message > 50 then --this is the opening load
                if not EnableLogging then
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
            if EnableLogging then
                print(s)
            end
        end
        Tick = 0
    end
end)

local isOverlayOpen = false
registerForEvent("onOverlayOpen", function()
    isOverlayOpen = true
end)
registerForEvent("onOverlayClose", function()
    isOverlayOpen = false
end)

PacifistMode = require('pacifist_mode')

if PacifistMode ~= true then
	PacifistMode = false
end

CheckPacifist =function()
    local b = nil
        if Game.GetFact("gmpl_npc_killed_by_player") == nil or Game.GetFact("gmpl_npc_killed_by_player") < 1 then
            b = "Still Possible"
        else
           b = "Failed"
        end
        if Facts.values[0]>0 or Game.GetFact("factlog_failedpacifist")>0 then
            b = "Failed"
        end
    return b
end

EnableLogging = require('logging_state')

if EnableLogging ~= false then
	EnableLogging = true
end


registerForEvent("onDraw", function()
    if(not isOverlayOpen) then
        -- if PacifistMode then
        --     ImGui.Begin("Fact Log", ImGuiWindowFlags.AlwaysAutoResize)
        --     ImGui.Text("Pacifist Mode: " .. CheckPacifist())
        --     ImGui.End()
        -- end
        return
    end
    ImGui.PushStyleVar(ImGuiStyleVar.WindowMinSize, 300, 40)
    ImGui.Begin("Fact Log", ImGuiWindowFlags.AlwaysAutoResize)

    local modToggled = false
    modEnabled, modToggled= ImGui.Checkbox("Enable mod", modEnabled)
    if modToggled then
        local stateFile = io.open('mod_on.lua', 'w')
        if stateFile then
            stateFile:write('return ')
            stateFile:write(tostring(modEnabled))
            stateFile:close()
        end
    end

    local logToggled = false
    EnableLogging, logToggled= ImGui.Checkbox("Log to console", EnableLogging)
    if logToggled then
        local stateFile = io.open('logging_state.lua', 'w')
        if stateFile then
            stateFile:write('return ')
            stateFile:write(tostring(EnableLogging))
            stateFile:close()
        end
    end
    local pacToggled = false
    PacifistMode, pacToggled= ImGui.Checkbox("Pacifist mode", PacifistMode)
    if pacToggled then
        local stateFile = io.open('pacifist_mode.lua', 'w')
        if stateFile then
            stateFile:write('return ')
            stateFile:write(tostring(PacifistMode))
            stateFile:close()
        end
    end
    if PacifistMode then
        ImGui.Text("Pacifist Mode: " .. CheckPacifist())
    end
    ImGui.End()
    ImGui.PopStyleVar(1)

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


function PrintWarning(text, duration)
	if text == nil or text == "" then
		return
	end

	local message = SimpleScreenMessage.new()
	message.message = text
	message.duration = duration
	message.isShown = true

	local blackboardDefs = Game.GetAllBlackboardDefs()
	local blackboardUI = Game.GetBlackboardSystem():Get(blackboardDefs.UI_Notifications)

	blackboardUI:SetVariant(
		blackboardDefs.UI_Notifications.WarningMessage,
		ToVariant(message),
		true
	)
end