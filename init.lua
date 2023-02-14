Facts = {
    names = {}, --loaded in from file
    values = {}
}
Details = {
    loaded = false,
    names = {}, --loaded in from file
    values = {}
}
Fact = {
    name = "",
    fact = -1
}
DiffFacts = {}
LoadDetails = function ()
    local file = io.open("details.txt")
    if(file) then
        for line in file:lines() do
            table.insert(Details.names, line)
            table.insert(Details.values,-1)
        end
    else
        print("[[ERROR]]: details.txt missing from FactLog file system.")
        return
    end
    Details.loaded = true
end

local qs = nil
local GameSession = require('GameSession') --Game Session is copyright (c) 2021 psiberx

StoredData = require("settings")
if StoredData == nil then
    StoredData = {true,true,false,false}
end

GetStoredDataString = function ()
    local s = "{"
    for k, v in next, StoredData do
        s = s .. tostring(v)
        if next(StoredData, k) ~= nil then
            s = s .. ", "
        end

    end
    s = s .. "}"
    return s
end


registerForEvent('onInit', function()
    local file = io.open("facts.txt")
    if(file) then
        for line in file:lines() do
            table.insert(Facts.names, line)
            table.insert(Facts.values,-1)
        end
    else
        print("[[ERROR]]: facts.txt missing from FactLog file system.")
        return
    end
    if StoredData[4] then
        LoadDetails()
    end
    Bbs = Game.GetBlackboardSystem()
    qs = Game.GetQuestsSystem()
    GameSession.StoreInDir('sessions') -- Set directory to store session data
    --GameSession.Persist(Facts.values) -- Link the data that should be watched and persisted 
    GameSession.Persist(DiffFacts)
    GameSession.OnLoad(function()
        print("Loaded Saved Data from session file")
    end)
    print("FactLog Initalized")
    GameSession.OnStart(function()
        print('Game Session Started')
        GameSession.TryLoad()
    end)

    GameSession.OnEnd(function()
        print('Game Session Ended')
        GameSession.TrySave()
    end)
end)
--@TODO add button to print contents to file 
Message = {}
Duration = 5
Tick = 0
ShouldTick = false
local bot = 0
local botDeets = 0
local queuedFacts = {}
local queuedFactsHash = {}
registerForEvent("onUpdate", function()
    if qs == nil then
        qs = Game.GetQuestsSystem()
        if qs == nil then return end
    end
    if not StoredData[1] then return end --if mod is disabled
    if not GameSession.IsLoaded() then return end -- if the function inst ready, don't dump known facts
    Tick = Tick + 1
    local d = Duration*60
    local factsToCheck = 500
    --Check through the next 500 quest facts
    for i = botDeets, botDeets + factsToCheck do
        if not Facts.values[i] then Facts.values[i] = 0 goto factsConinue end
        local fact = Facts.names[i]
        if not fact then goto endFacts end --Deets is smaller than 500
        local currentFactVal = qs.GetFactStr(qs,fact) or Game.GetFact(fact)
        local currentFactValSanitized = qs.GetFactStr(qs,string.sub(fact,1,-1)) or Game.GetFact(string.sub(fact,1,-1))
        if currentFactVal ~= currentFactValSanitized then
            print(fact)
            currentFactVal = math.max(currentFactVal,currentFactValSanitized)
        end
        if currentFactVal ~= Facts.values[i] then
            if queuedFactsHash[fact]==nil then
                DiffFacts[tostring(fact)] = currentFactVal
                Facts.values[i] = currentFactVal
                queuedFacts[#queuedFacts+1] = i
                queuedFactsHash[fact] = true
                Message[#Message+1] = fact .. ":: " .. tostring(currentFactVal)
            end
        end
        ::factsConinue::
    ::endFacts::
    end
    if StoredData[4] then --details is enabled
        if not Details.loaded then
            LoadDetails()
        end 
        for i = botDeets, botDeets + factsToCheck do
            if not Details.values[i] then Details.values[i] = 0 goto deetsContinue end
            local fact = Details.names[i]
            if not fact then goto endDeets end --Deets is smaller than 500
            local currentFactVal = qs.GetFactStr(qs,fact) or Game.GetFact(fact)
            local currentFactValSanitized = qs.GetFactStr(qs,string.sub(fact,1,-1)) or Game.GetFact(string.sub(fact,1,-1))
            if currentFactVal ~= currentFactValSanitized then
                print(fact)
                currentFactVal = math.max(currentFactVal,currentFactValSanitized)
            end
            if currentFactVal ~= Details.values[i] then
                Details.values[i] = currentFactVal
                if queuedFactsHash[fact]==nil then
                    DiffFacts[fact..""] = currentFactVal
                    print(DiffFacts[fact])
                    queuedFacts[#queuedFacts+1] = i
                    queuedFactsHash[fact] = true
                    Message[#Message+1] = fact .. ": " .. tostring(currentFactVal)
                end
            end
            ::deetsContinue::
        end
        ::endDeets::
    end
    -- Pacifist Fail Check
    if StoredData[3] and (Game.GetFact("gmpl_npc_killed_by_player")==1) then
        Game.GetQuestsSystem():SetFactStr("factlog_failedpacifist",1)
        ShowWarning("Failed pacifism. Reload save",10.00)
        Facts.values[0] = 1
    end
    -- Message print
    if Tick % d == d-1 then
        if #Message > 0 then
            if #Message > 50 then --this is the opening load
                local s = ""
                if not StoredData[2] then
                    print("Opening load caught")
                    GameSession.TrySave()
                else 
                    for i,m in ipairs(Message) do
                        s = s .. m .. ", "
                    end
                    print(s)
                end
                for i in pairs(Message) do
                    Message[i] = nil
                end
                return
            end
            for i,m in ipairs(Message) do
                local s = s .. m .. "\n"
                table.remove(Message,i)
                if queuedFacts and #queuedFacts > 0 and queuedFacts[0] then
                    queuedFactsHash[queuedFacts[0]] = nil
                    table.remove(queuedFacts,0)
                end
                if i>3 then
                    break
                end
            end
            ShowMessage(s)
            if StoredData[2] then
                print(s)
            end
        end
        Tick = 0
    end
    --Loop around what the next x facts are
    bot = (bot + factsToCheck)%(#Facts.names)
    botDeets = (botDeets + factsToCheck)%(#Details.names)
end)

local isOverlayOpen = false
registerForEvent("onOverlayOpen", function()
    isOverlayOpen = true
end)
registerForEvent("onOverlayClose", function()
    isOverlayOpen = false
end)
CheckPacifist = function()
    local b = nil
        if Game.GetFact("gmpl_npc_killed_by_player") == nil or Game.GetFact("gmpl_npc_killed_by_player") < 1 then
            b = "Still Possible"
        else
           b = "Failed"
        end
        if (Facts.values[0] and Facts.values[0]>0) or (Game.GetFact("factlog_failedpacifist") and Game.GetFact("factlog_failedpacifist")>0) then
            b = "Failed"
        end
    return b
end

registerForEvent("onDraw", function()
    if(not isOverlayOpen) then
        return
    end
    ImGui.PushStyleVar(ImGuiStyleVar.WindowMinSize, 300, 40)
    ImGui.Begin("Fact Log", ImGuiWindowFlags.AlwaysAutoResize)

    local modToggled = false
    local logToggled = false
    local pacToggled = false
    local deetsToggled = false
    StoredData[1], modToggled= ImGui.Checkbox("Enable mod", StoredData[1])
    local a = modToggled
    if StoredData[1] then
        StoredData[2], logToggled= ImGui.Checkbox("Log to console", StoredData[2])
        StoredData[3], pacToggled= ImGui.Checkbox("Pacifist mode", StoredData[3])
        a = a or logToggled or pacToggled
        if StoredData[3] then
            ImGui.Text("Pacifist Mode: " .. CheckPacifist())
        end
        StoredData[4], deetsToggled= ImGui.Checkbox("Details mode", StoredData[4])
        a = a or deetsToggled
        if StoredData[4] then
            ImGui.Text("This feature is best used during quests")
        end
        if ImGui.Button("Dump Facts", 100, 30) then 
            local s = ""
            for key, value in ipairs(DiffFacts) do
                s = s .. key .. ": " .. value ", "
            end
            if s == "" then print("No facts to dump") else print(s) end
        end
    end
    if (a) then
        local stateFile = io.open('settings.lua', 'w')
        if stateFile then
            stateFile:write('return ')
            stateFile:write(GetStoredDataString())
            stateFile:close()
        end
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


function ShowWarning(text, duration)
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