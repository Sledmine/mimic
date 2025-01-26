local script = {}

local engine = Engine
local getTickCount = engine.core.getTickCount

---@class ScriptThreadMetadata
---@field type "startup"|"continuous"|"dormant"

---@class ScriptThread
---@field thread thread
---@field parent ScriptThread?
---@field child ScriptThread?
---@field type "startup"|"continuous"|"dormant"
---@field isDormant boolean
---@field isSleep boolean
---@field run fun(): boolean
---@field func fun()

---@type ScriptThread[]
local callTrace = {}

---@param scriptThread ScriptThread
local function addThreadToTrace(scriptThread)
    table.insert(callTrace, scriptThread)
end

---@param scriptThread ScriptThread
local function removeThreadFromTrace(scriptThread)
    local scriptThreadIndex = table.indexof(callTrace, scriptThread)
    logger:debug("Removing dead script {}.", scriptThreadIndex)
    if scriptThread.parent then
        scriptThread.parent.child = nil
    end
    table.remove(callTrace, scriptThreadIndex)
end

---@param ticks number
local function sleepThreadFor(ticks)
    if ticks == -1 then
        logger:warning("Sleeping until woken up")
    else
        logger:warning("Sleeping for " .. ticks .. " ticks")
    end
    local currentTicks = getTickCount()
    while ticks == -1 or getTickCount() - currentTicks < ticks do
        coroutine.yield()
    end
end

---@param evaluateCondition fun(): boolean
---@param maximumTicks? number
local function sleepThreadUntil(evaluateCondition, maximumTicks)
    logger:debug("Sleeping until condition is true")
    local currentTicks = getTickCount()
    while evaluateCondition() ~= true or (maximumTicks and getTickCount() - currentTicks < maximumTicks) do
        coroutine.yield()
    end
end

--- Handle a script thread recursively
--- If the script's thread is dead after resuming, remove it from the call trace and handle the parent thread.
--- If the script is continuous and its thread is dead after resuming, restart the script.
---@param script ScriptThread
local function handleScriptThread(script, ...)
    local threadResult
    if not script.child then
        threadResult = script.run()
    else
        local ok, result = coroutine.resume(script.thread, ...)
        if not ok then
            error(result, 2)
        end 
        threadResult = result
    end

    if coroutine.status(script.thread) == "dead" then
        if script.type == "continuous" then
            script.thread = coroutine.create(script.func)
        else
            removeThreadFromTrace(script)
            if script.parent then
                handleScriptThread(script.parent, threadResult)
            end
        end
    end
end

local function findScriptThreadByFunc(func)
    for _, scriptThread in ipairs(callTrace) do
        if scriptThread.func == func then
            return scriptThread
        end
    end
    return nil
end

local function getBottomMostScriptChild(scriptThread)
    local currentScriptThread = scriptThread
    while currentScriptThread.child do
        currentScriptThread = currentScriptThread.child
    end
    return currentScriptThread
end

function script.poll()
    for _, currentScript in ipairs(callTrace) do
        if not currentScript.child and not currentScript.isDormant then
            handleScriptThread(currentScript)
        end
    end
    return #callTrace
end

---@param func fun(call: fun(func: fun()), sleep: fun(...))
---@param metadata? ScriptThreadMetadata
function script.thread(func, metadata)
    local metadata = metadata or {}
    local parentScriptThread = {
        func = func,
        thread = coroutine.create(func),
        parent = nil,
        child = nil,
        type = metadata.type,
        isDormant = metadata.type == "dormant",
        isSleep = false
    }
    addThreadToTrace(parentScriptThread)

    local call = function(funcToCall)
        if parentScriptThread.child then
            error("Cannot call a function while another function is being called", 2)
        end
        local _, callScriptThread = script.thread(funcToCall)
        callScriptThread.parent = parentScriptThread
        parentScriptThread.child = callScriptThread
        return coroutine.yield()
    end

    local sleep = function(...)
        if parentScriptThread.child then
            error("Cannot sleep while another function is being called", 2)
        end
        local args = {...}
        local _, callScriptThread = script.thread(function()
            if #args == 1 and type(args[1]) == "number" then
                sleepThreadFor(args[1])
            elseif #args == 1 and type(args[1]) == "function" then
                sleepThreadUntil(args[1], args[2] or nil)
            else 
                error("Invalid sleep arguments")
            end
        end)
        callScriptThread.isSleep = true
        callScriptThread.parent = parentScriptThread
        parentScriptThread.child = callScriptThread
        return coroutine.yield()
    end

    local run = function()
        local scriptThread = parentScriptThread
        local ok, result = coroutine.resume(scriptThread.thread, call, sleep)
        if not ok then
            error(result, 2)
        end
        return result
    end

    parentScriptThread.run = run

    return run, parentScriptThread
end

function script.startup(func)
    local foundScript = findScriptThreadByFunc(func)
    if foundScript then
        logger:error("Tried to add a script that already exists.")
        return
    end
    local metadata = {type = "startup"}
    return script.thread(func, metadata)()
end

function script.continuous(func)
    local foundScript = findScriptThreadByFunc(func)
    if foundScript then
        logger:error("Tried to add a script that already exists.")
        return
    end
    local metadata = {type = "continuous"}
    local run, ref = script.thread(func, metadata)
    return run, ref
end

function script.dormant(func)
    local foundScript = findScriptThreadByFunc(func)
    if foundScript then
        logger:error("Tried to add a script that already exists.")
        return
    end
    local metadata = {type = "dormant"}
    script.thread(func, metadata)
end

function script.wake(func)
    local foundScript = findScriptThreadByFunc(func)
    if not foundScript then
        logger:error("Tried to wake a script that does not exist.")
        return
    end
    if foundScript.isDormant then
        foundScript.isDormant = false
    else
        local child = getBottomMostScriptChild(foundScript)
        if child.isSleep then
            removeThreadFromTrace(child)
        end
    end
end

return script
