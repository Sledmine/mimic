--- Transpiler for HSC (Halo Script Language) to Lua
--- by Sledmine
----------------------------------------------------
--- This script attempts to transpile a HSC script for Halo Combat Evolved to Lua
--- It aims to parse any HSC script made for any version of Halo Combat Evolved (MCC, Custom Edition, Open Sauce, etc)
--- Officially just Custom Edition is supported, but it will get updates to support MCC later
--- (not supported yet due to addition of custom functions that can receive parameters and return values)
--- Uses LPEG for parsing and creating a semi AST to convert to Lua code that trough a
--- reimplementation of how hsc "scripts" work but using coroutines and integration with Balltze
local lpeg = require "lpeg"
local P, R, S = lpeg.P, lpeg.R, lpeg.S -- patterns
local C, Ct = lpeg.C, lpeg.Ct -- capture
local V = lpeg.V -- variable
local inspect = require "lua.modules.inspect"
local luna = require "lua.modules.luna"
local hscdoc = require "lua.modules.hscDoc"

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

print("------------------- AST -------------------------------")

local hsc = parser:match(luna.file.read(arg[1]))
print(inspect(hsc))

print("-------------------- AST -> LUA ------------------------------")

local variables = {}
local blocks = {}

local function convertAstToLua(astNode)
    local lua = ""
    if #astNode == 0 then
        astNode = {astNode}
    end
    for _, node in ipairs(astNode) do
        local args = node["args"]
        local name = node["function"]
        if name == "global" then
            local varType = args[1]
            local varName = args[2]
            local varValue = args[3]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            variables[varName] = true
            lua = lua .. "local " .. varName .. " = " .. tostring(varValue) .. "\n"
        elseif name == "*" then
            local var1 = args[1]
            local var2 = args[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " * " .. var2 .. "\n"
        elseif name == "set" then
            local varName = args[1]
            local varValue = args[2]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            lua = lua .. varName .. " = " .. tostring(varValue) .. "\n"
        elseif name == "not" then
            local varValue = args[1]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            lua = lua .. "not " .. varValue .. "\n"
        elseif name == "=" then
            local var1 = args[1]
            local var2 = args[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. tostring(var2) .. " == " .. tostring(var1) .. ""
        elseif name == "if" then
            local condition = args[1]
            local body = args[2]
            local elseBody = args[3]
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
            local var1 = args[1]
            local var2 = args[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " and " .. var2 .. ""
        elseif name == "begin" then
            local body = args
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    body[i] = convertAstToLua(v)
                end
            end
            lua = lua .. table.concat(body, "\n")
            --lua = lua .. "function()\n" .. table.concat(body, "\n") .. "end\n"
        elseif name == "begin_random" then
            local body = args
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    body[i] = convertAstToLua(v)
                end
            end
            -- TODO Check alternatives for this, keep in mind it needs to return a value
            lua = lua .. "hsc.begin_random(function()\n" .. table.concat(body, "\n") .. "end)\n"
        elseif name == "or" then
            local var1 = args[1]
            local var2 = args[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " or " .. var2 .. ""
        elseif name == "-" then
            local var1 = args[1]
            local var2 = args[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " - " .. var2 .. "\n"
        elseif name == "+" then
            local var1 = args[1]
            local var2 = args[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " + " .. var2 .. "\n"
        elseif name == "<" then
            local var1 = args[1]
            local var2 = args[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " < " .. var2 .. "\n"
        elseif name == ">" then
            local var1 = args[1]
            local var2 = args[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " > " .. var2 .. "\n"
        elseif name == "!=" then
            local var1 = args[1]
            local var2 = args[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " ~= " .. var2 .. "\n"
        elseif name == "script" then
            local scriptType = args[1]
            local scriptName = args[2]
            local scriptBody = args[3]
            local scriptReturnType
            if scriptType == "static" then
                scriptReturnType = args[2]
                scriptName = args[3]
                scriptBody = args[4]
            end
            --lua = lua .. "function " .. scriptName .. "()\n"
            blocks[scriptName] = scriptBody
            lua = lua .. scriptName .. " = function(call, sleep)\n"
            local args = args
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
            local scriptName = args[1]
            lua = lua .. "wake(" .. scriptName .. ")\n"
        elseif name == "sleep" then
            for i, v in ipairs(args) do
                if type(v) == "table" then
                    args[i] = convertAstToLua(v)
                end
            end
            local sleepForTicks = args[1]
            local scriptName = args[2]
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
            for i, v in ipairs(args) do
                if type(v) == "table" then
                    args[i] = convertAstToLua(v)
                end
            end
            if #args == 1 then
                local condition = args[1]
                lua = lua .. "sleep(function() return " .. condition .. " end)\n"
            elseif #args == 2 then
                local condition = args[1]
                local everyTicks = args[2]
                lua = lua .. "sleep(function() return " .. condition .. " end, " .. everyTicks ..
                          ")\n"
            else
                local condition = args[1]
                local everyTicks = args[2]
                local maximumTicks = args[3]
                lua = lua .. "sleep(function() return " .. condition .. " end, " .. everyTicks ..
                          ", " .. maximumTicks .. ")\n"
            end
        else
            local functionName = name
            -- print("General function call", functionName)
            local functionArgs = args
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
            --local hscFunction = table.find(hscdoc, function(doc)
            --    return doc.funcName:trim() == functionName:trim()
            --end)
            --if hscFuntion then
            --    print("HSC FUNCTION", inspect(hscFunction))
            --    functionName = "hsc." .. hscFunction.funcName
            --    os.exit()
            --end
            --lua = lua .. functionName .. "(" .. table.concat(functionArgs, ", ") .. ")\n"
            if blocks[functionName] then
                lua = lua .. "call(" .. functionName .. ")\n"
            else
                lua = lua .. "hsc." .. functionName .. "(" .. table.concat(functionArgs, ", ") .. ")\n"
            end
        end
    end
    return lua
end

local lua = convertAstToLua(hsc)
local header = [[---------- Transpiled from HSC to Lua ----------
local script = require "script".call
local wake = require"script".wake
local hsc = require "hsc"
hsc.begin_random = function(func)
    func()
end
hsc.print(message)
    Engine.core.consolePrint("{}", tostring(message))
end

]]
lua = header .. lua
luna.file.write("output.lua", lua)
--print("-------------------- LUA ------------------------------")
--print(lua)
