local script = {}

local engine = Engine

local callTrace = {}

---Sleeps for a certain amount of ticks or until a condition is met
---@param sleepFor number | fun(): boolean
---@param everyTicks? number
---@param maximumTicks? number
local function waitNTicks(sleepFor, everyTicks, maximumTicks)
    local ticks = type(sleepFor) == "number" and sleepFor or nil
    if ticks then 
        logger:warning("Sleeping for " .. sleepFor .. " ticks")
        local currentTicks = engine.core.getTickCount()
        while engine.core.getTickCount() - currentTicks < ticks do
            --logger:debug("Sleeping...")
            coroutine.yield()
        end
    end
    local sleepUntil = type(sleepFor) == "function" and sleepFor or nil
    if sleepUntil then
        logger:warning("Sleeping until condition is true")
        local currentTicks = engine.core.getTickCount()
        --while sleepUntil() ~= true or (maximumTicks and engine.core.getTickCount() - currentTicks < maximumTicks) do
        while sleepUntil() ~= true do
            --logger:debug("Sleeping...")
            coroutine.yield()
        end
    end
    --while (ticks and (engine.core.getTickCount() - currentTicks < ticks) or sleepUntil and sleepUntil() ~= true) do
    coroutine.yield("_finished")
end

local function handleCoroutine(co, ...)
    local ok, result = coroutine.resume(co, ...)
    if not ok then
        error(result, 2)
    end
    return ok, result
end

function script.dispatch()
    for ref, v in pairs(callTrace) do
        local callCo = v[1]
        local run = v[2]
        local isCallAlive = coroutine.status(callCo) ~= "dead"
        local isWaitingForOtherCoroutine = callTrace[callCo]
        if isCallAlive and not isWaitingForOtherCoroutine then
            local isCallOk, callResult = (run or coroutine.resume)(callCo)
            local isCallDead = coroutine.status(callCo) == "dead"
            --logger:info("Routine: {} is {}, result: {}", tostring(co), coroutine.status(co), tostring(callResult))
            if not isCallOk then
                error(callResult)
            end
            if isCallOk then
                if callResult then
                    if callResult == "_finished" then
                        logger:info("Call finished sleeping")
                        handleCoroutine(ref)
                        --callTrace[ref] = nil
                    else
                        logger:info("Call returned: " .. tostring(callResult))
                        handleCoroutine(ref, callResult)
                        -- callTrace[ref] = nil
                    end
                end
                if not callResult and isCallDead then
                    logger:info("Call is dead")
                    handleCoroutine(ref)
                    --callTrace[ref] = nil
                end
            end
        end
        if not isCallAlive then
            -- local ok, result = coroutine.resume(ref)
            -- if not ok then
            --    error("Coroutine failed: " .. result)
            -- end
            logger:warning("Coroutine {} is dead, removing...", tostring(callCo))
            callTrace[ref] = nil
        end
    end
    return #callTrace
end

function script.call(func, ...)
    --local currentRefFuncName = debug.getlocal(1, 1)
    local ref = coroutine.create(func)
    local call = function(funcToCall)
        -- table.insert(callTrace, {co, script.call(funcToCall)})
        callTrace[ref] = {script.call(funcToCall)}
        return coroutine.yield()
    end
    local sleep = function(sleepFor)
        -- callTrace[ref] = {script.call(function()
        --    waitNTicks(sleepForTicks)
        -- end)}
        callTrace[ref] = {
            coroutine.create(function()
                waitNTicks(sleepFor)
            end)
        }
        return coroutine.yield()
    end
    return ref, function()
        return coroutine.resume(ref, call, sleep)
    end
end

function script.wake(func)
    --local ref, run = script.call(function (call, sleep)
    --    sleep(1)
    --    return call(func)
    --end)
    local ref, run = script.call(func)
    run()
end

return script
