local script = {}

local engine = Engine
local getTickCount = engine.core.getTickCount

---@class ScriptThreadMetadata
---@field isContinuous boolean

---@class ScriptThread
---@field thread thread
---@field parent ScriptThread?
---@field child ScriptThread?
---@field isContinuous boolean
---@field run fun(): boolean
---@field func fun()

---@type ScriptThread[]
local callTrace = {}

---Sleeps for a certain amount of ticks or until a condition is met
---@overload fun(ticks: number)
---@overload fun(ticks: number, script: thread)
---@overload fun(sleepUntil: fun(): boolean)
---@overload fun(ticks: number, everyTicks?: number, maximumTicks?: number)
---@param ticksOrCondition number | fun(): boolean
---@param everyTicksOrThread? number
---@param maximumTicks? number
local function waitFor(ticksOrCondition, everyTicksOrThread, maximumTicks)
    local ticks = type(ticksOrCondition) == "number" and ticksOrCondition or nil
    local sleepUntil = type(ticksOrCondition) == "function" and ticksOrCondition or nil
    local threadToSleep = type(everyTicksOrThread) == "thread" and ticks or nil
    if ticks then
        if threadToSleep then
            logger:warning("Causing another thread to sleep is not implemented yet!!!")
            return
        end
        logger:warning("Sleeping for " .. ticksOrCondition .. " ticks")
        local currentTicks = getTickCount()
        while ticks == -1 or getTickCount() - currentTicks < ticks do
            coroutine.yield()
        end
    end
    if sleepUntil then
        logger:debug("Sleeping until condition is true")
        local currentTicks = getTickCount()
        -- while sleepUntil() ~= true or (maximumTicks and getTickCount() - currentTicks < maximumTicks) do
        while sleepUntil() ~= true do
            coroutine.yield()
        end
    end
end

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
        if script.isContinuous then
            script.thread = coroutine.create(script.func)
        else
            removeThreadFromTrace(script)
            if script.parent then
                handleScriptThread(script.parent, threadResult)
            end
        end
    end
end

function script.poll()
    for _, currentScript in ipairs(callTrace) do
        if not currentScript.child then
            handleScriptThread(currentScript)
        end
    end
    return #callTrace
end

function script.thread(func, metadata)
    local metadata = metadata or {}
    local parentScriptThread = {
        parent = nil,
        child = nil,
        func = func,
        thread = coroutine.create(func),
        isContinuous = metadata.isContinuous
    }
    addThreadToTrace(parentScriptThread)

    local call = function(funcToCall)
        local parent = parentScriptThread
        if parent.child then
            logger:warning("Tried to call a function while another is running")
        end
        local _, callScriptThread = script.thread(funcToCall)
        callScriptThread.parent = parent
        parent.child = callScriptThread
        return coroutine.yield()
    end

    local sleep = function(...)
        local sleepArgs = {...}
        print(table.unpack(sleepArgs))
        call(function()
            local args = sleepArgs
            waitFor(table.unpack(args))
        end)
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
    return script.thread(func)()
end

function script.continuous(func)
    local metadata = {isContinuous = true}
    local run, ref = script.thread(func, metadata)
    return run, ref
end

function script.wake(func)
    script.thread(function(call, sleep)
        sleep(1)
        call(func)
    end)()
end

return script
