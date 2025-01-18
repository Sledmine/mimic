-- Transpiler for HSC (Halo Script Language) to Lua
-- by Sledmine
----------------------------------------------------
-- This script attempts to transpile a HSC script for Halo Combat Evolved to Lua
-- It aims to parse any HSC script made for any version of Halo Combat Evolved (MCC, Custom Edition, Open Sauce, etc)
-- Officially just Custom Edition is supported, but it will get updates to support MCC later
-- (not supported yet due to addition of custom functions that can receive parameters and return values)
-- Uses LPEG for parsing and creating a semi AST to convert to Lua code that trough a
-- reimplementation of how hsc "scripts" work but using coroutines and integration with Balltze
-- In order to use this script you need to add these variables in your HSC script and get them
-- compiled in your map:
--[[
(global boolean lua_boolean false)
(global short lua_short 0)
(global long lua_long 0)
(global real lua_real 0)
(global string lua_string "")
(global unit lua_unit none)
(global object lua_object none)
(global object_list lua_object_list none)
--]] --
local lpeg = require "lpeg"
local P, R, S = lpeg.P, lpeg.R, lpeg.S -- patterns
local C, Ct = lpeg.C, lpeg.Ct -- capture
local V = lpeg.V -- variable
local inspect = require "lua.modules.inspect"
local luna = require "lua.modules.luna"
local hscdoc = require "lua.modules.hscDoc"
local argparse = require "lua.scripts.modules.argparse"

local parser = argparse("hscToLua", "Transpiler for HSC (Halo Script Language) to Lua")
parser:argument("input", "Input HSC file to transpile")
parser:option("-o --output", "Output Lua file to save the transpiled code", "output.lua")
parser:option("--debug", "Enable debug mode", false)
parser:option("--module", "Write script as a module with a given name", "module")

local args = parser:parse()
print(inspect(args))

local parser = P {
    "program", -- initial rule
    program = Ct(V "sexpr" ^ 0),
    wspace = S " \n\r\t" ^ 0,
    atom = V "boolean" + V "integer" + V "string" + V "symbol",
    symbol = C((1 - S " \n\r\t\"'()[]{}#@~") ^ 1) / function(s)
        if s:includes("/") then
            return "str_" .. s
        end
        return s
    end,
    boolean = C(P "true" + P "false") / function(x)
        return x == "true"
    end,
    integer = C(R "19" * R "09" ^ 0) / tonumber,
    string = P "\"" * C((1 - S "\"\n\r") ^ 0) * P "\"" / function(s)
        return "str_" .. s
    end,
    coll = V "list" + V "array",
    list = P "'(" * Ct(V "expr" ^ 1) * P ")",
    array = P "[" * Ct(V "expr" ^ 1) * P "]",
    expr = V "wspace" * (V "coll" + V "atom" + V "sexpr"),
    -- sexpr = V "wspace" * P "(" * V "symbol" * Ct(V "expr" ^ 0) * P ")" / function(f, ...)
    --    return {["function"] = f, ["args"] = ...}
    -- end
    sexpr = V "wspace" * P "(" * V "symbol" * Ct(V "expr" ^ 0) * V "wspace" * P ")" /
        function(f, ...)
            -- for i, v in ipairs({...}) do
            --    print("v", inspect(v))
            -- end
            return {["function"] = f, ["args"] = ...}
        end
}

-- some "built-ins"
reduce = function(f, list)
    for i, v in ipairs(list) do
        if i == 1 then
            head = v
        else
            head = f(head, v)
        end
    end
    return head
end

-- t = parser:match([[
-- (* 2 3 4 (+ 10 20))
-- (def yay false)
-- (not yay)
-- (str "lua" "lisp" "!") 
-- (global "boolean" global_music_on false)
-- (set global_music_on true)
-- ]])

-- test = parser:match([[
-- (global global_dialog_on false)
-- (not global_dialog_on)
-- ]])

local variables = {}
local blocks = {}

local function convertAstToLua(astNode)
    local lua = ""
    if #astNode == 0 then
        astNode = {astNode}
    end
    for _, node in ipairs(astNode) do
        local hscArgs = node["args"]
        local name = node["function"]
        if name == "global" then
            local varType = hscArgs[1]
            local varName = hscArgs[2]
            local varValue = hscArgs[3]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            variables[varName] = true
            lua = lua .. "local " .. varName .. " = " .. tostring(varValue) .. "\n"
        elseif name == "*" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " * " .. var2 .. "\n"
        elseif name == "set" then
            local varName = hscArgs[1]
            local varValue = hscArgs[2]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            lua = lua .. varName .. " = " .. tostring(varValue) .. "\n"
        elseif name == "not" then
            local varValue = hscArgs[1]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            lua = lua .. "not " .. varValue .. "\n"
        elseif name == "=" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. tostring(var2) .. " == " .. tostring(var1) .. ""
        elseif name == "if" then
            local condition = hscArgs[1]
            local body = hscArgs[2]
            local elseBody = hscArgs[3]
            if type(condition) == "table" then
                condition = convertAstToLua(condition)
            end
            if type(body) == "table" then
                body = convertAstToLua(body)
            end
            condition = tostring(condition)
            if type(elseBody) == "table" then
                elseBody = convertAstToLua(elseBody)
                lua = lua .. "if " .. condition .. " then\n" .. body .. "else\n" .. elseBody ..
                          "end\n"
            else
                lua = lua .. "if " .. condition .. " then\n" .. body .. "end\n"
            end
        elseif name == "and" then
            local body = hscArgs
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    body[i] = convertAstToLua(v)
                end
            end
            lua = lua .. table.concat(body, " and ") .. ""
        elseif name == "begin" then
            local body = hscArgs
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    body[i] = convertAstToLua(v)
                end
            end
            lua = lua .. table.concat(body, "\n")
            -- Should we consider beging blocks as self running functions?
            --
            -- lua = lua .. "function()\n" .. table.concat(body, "\n") .. "end\n"
            --
            -- This might help to produce more accurate "blocks" of code that keep scope of execution
            -- but it will look weird and might not be easy to read
        elseif name == "begin_random" then
            local body = hscArgs
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    body[i] = convertAstToLua(v)
                end
            end
            -- This relates to a begin like block, begin blocks will execute directly in the same scope
            -- but begin_random might be a function that executes multiple begin blocks in a random order
            --
            -- So we need to wrap each block in a function to be executed in their own scope but
            -- allowing to be run in a random order
            body = table.map(body, function(v)
                return "function() " .. v .. " end"
            end)
            lua = lua .. "hsc.begin_random({\n" .. table.concat(body, ",\n") .. "})\n"
            -- This might be an edge case so it is still safely to unwrap "begin" blocks in same
            -- scope after all, cause there are no other functions that explicitly run another
            -- function in different scopes.. I think
        elseif name == "or" then
            local body = hscArgs
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    body[i] = convertAstToLua(v)
                end
            end
            lua = lua .. table.concat(body, " or ") .. ""
        elseif name == "-" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " - " .. var2 .. "\n"
        elseif name == "+" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " + " .. var2 .. "\n"
        elseif name == "<" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " < " .. var2 .. "\n"
        elseif name == ">" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " > " .. var2 .. "\n"
        elseif name == "!=" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " ~= " .. var2 .. "\n"
        elseif name == "script" then
            local scriptType = hscArgs[1]
            local scriptName = hscArgs[2]
            local scriptBody = hscArgs[3]
            local scriptReturnType
            if scriptType == "static" then
                scriptReturnType = hscArgs[2]
                scriptName = hscArgs[3]
                scriptBody = hscArgs[4]
            end
            blocks[scriptName] = scriptBody
            if args.module then
                lua = lua .. "function " .. args.module .. "." .. scriptName .. "(call, sleep)\n"
            else
                lua = lua .. "function " .. scriptName .. "(call, sleep)\n"
            end
            local args = hscArgs
            for i, v in ipairs(args) do
                if type(v) == "table" then
                    if scriptReturnType and scriptReturnType ~= "str_void" and i == #args then
                        lua = lua .. "return " .. convertAstToLua(v)
                    else
                        lua = lua .. "" .. convertAstToLua(v)
                    end
                end
            end
            lua = lua .. "end\n"
        elseif name == "wake" then
            local scriptName = hscArgs[1]
            if args.module then
                lua = lua .. "wake(" .. args.module .. "." .. scriptName .. ")\n"
            else
                lua = lua .. "wake(" .. scriptName .. ")\n"
            end
        elseif name == "sleep" then
            for i, v in ipairs(hscArgs) do
                if type(v) == "table" then
                    hscArgs[i] = convertAstToLua(v)
                end
            end
            local sleepForTicks = hscArgs[1]
            local scriptName = hscArgs[2]
            if scriptName then
                if sleepForTicks == "-1" then
                    -- TODO Ccheck about this it seems like this tries to stop another script
                    lua = lua .. "stop(" .. scriptName .. ")\n"
                else
                    lua = lua .. "sleep(" .. sleepForTicks .. ", " .. scriptName .. ")\n"
                end
            else
                lua = lua .. "sleep(" .. sleepForTicks .. ")\n"
            end
        elseif name == "sleep_until" then
            for i, v in ipairs(hscArgs) do
                if type(v) == "table" then
                    hscArgs[i] = convertAstToLua(v)
                end
            end
            if #hscArgs == 1 then
                local condition = hscArgs[1]
                lua = lua .. "sleep(function() return " .. condition .. " end)\n"
            elseif #hscArgs == 2 then
                local condition = hscArgs[1]
                local everyTicks = hscArgs[2]
                lua = lua .. "sleep(function() return " .. condition .. " end, " .. everyTicks ..
                          ")\n"
            else
                local condition = hscArgs[1]
                local everyTicks = hscArgs[2]
                local maximumTicks = hscArgs[3]
                lua = lua .. "sleep(function() return " .. condition .. " end, " .. everyTicks ..
                          ", " .. maximumTicks .. ")\n"
            end
        else
            local functionName = name
            -- print("General function call", functionName)
            local functionArgs = hscArgs
            -- print("Args", inspect(functionArgs))
            for i, v in ipairs(functionArgs) do
                if type(v) == "table" then
                    functionArgs[i] = convertAstToLua(v)
                end
            end
            -- print("NewArgs", inspect(functionArgs))
            for argPos, v in ipairs(functionArgs) do
                -- if type(v) == "string" and (v:startswith("str_") or hscdoc[functionName]) then
                -- print("ARG", functionName, argPos, v)
                if type(v) == "string" and v:startswith("str_") then
                    local str = v:replace("str_", "")
                    str = str:replace("\\", "\\\\")
                    str = "\"" .. str .. "\""
                    functionArgs[argPos] = str
                elseif type(v) == "boolean" then
                    functionArgs[argPos] = tostring(v)
                elseif type(v) == "string" then
                    if not v:includes("(") and not v:includes(")") and not v:includes(" ") and
                        not tonumber(v) and not variables[v] then
                        local str = v
                        str = str:replace("\\", "\\\\")
                        str = "\"" .. str .. "\""
                        functionArgs[argPos] = str
                    end
                end
            end
            -- local hscFunction = table.find(hscdoc, function(doc)
            --    return doc.funcName:trim() == functionName:trim()
            -- end)
            -- if hscFuntion then
            --    print("HSC FUNCTION", inspect(hscFunction))
            --    functionName = "hsc." .. hscFunction.funcName
            --    os.exit()
            -- end
            -- lua = lua .. functionName .. "(" .. table.concat(functionArgs, ", ") .. ")\n"
            if blocks[functionName] then
                if args.module then
                    lua = lua .. "call(" .. args.module .. "." .. functionName .. ")\n"
                else
                    lua = lua .. "call(" .. functionName .. ")\n"
                end
            else
                lua = lua .. "hsc." .. functionName .. "(" .. table.concat(functionArgs, ", ") ..
                          ")\n"
            end
        end
    end
    return lua
end

local hsc = parser:match(luna.file.read(args.input))

if args.debug then
    print("------------------- AST -------------------------------")
    print(inspect(hsc))
end

local lua = convertAstToLua(hsc)
local header = [[---------- Transpiled from HSC to Lua ----------
local script = require"script".call
local wake = require"script".wake
local hsc = require "hsc"
math.randomseed(os.time())
-- Reimplement HSC functions with Lua
hsc.begin_random = function(functions)
    local functions = table.copy(functions)
    local function random()
        local index = math.random(1, #functions)
        local func = functions[index]
        table.remove(functions, index)
        return func
    end
    while #functions > 0 do
        random()()
    end
end
local easy = "easy"
local normal = "normal"
local hard = "hard"
local impossible = "impossible"
hsc.game_difficulty_get = function()
    -- TODO Implement this by reading game actual difficulty
    return normal
end
hsc.game_difficulty_get_real = hsc.game_difficulty_get
hsc.print = function(message)
    Engine.core.consolePrint("{}", tostring(message))
end
---------- Finish HSC Header to Lua ----------
]]

if args.module then
    header = header .. "local " .. args.module .. " = {}\n\n"
end

lua = header .. lua

if args.module then
    lua = lua .. "\nreturn " .. args.module
end

if args.debug then
    print("-------------------- AST -> LUA ------------------------------")
    print(lua)
end

assert(luna.file.write(args.output, lua), "Error writing Lua file")
