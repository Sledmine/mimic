-- Transpiler for HSC (Halo Script Language) to Lua
-- by Sledmine
----------------------------------------------------
-- This script attempts to transpile a HSC script for Halo Combat Evolved to Lua
-- It aims to parse any HSC script made for any version of Halo Combat Evolved (MCC, Custom Edition, Open Sauce, etc)
-- Officially just Custom Edition is supported, but it will get updates to support MCC later
-- (not supported yet due to addition of custom functions that can receive parameters and return values)
-- Uses LPEG for parsing and creating a semi AST to convert to Lua code, using an proto module script
-- reimplementation of how hsc "scripts" work, but using coroutines and integrating with Balltze.
--
-- WARNING: Transpiler will not take care of Lua code formatting, it will just transpile the code
-- as is, output will be valid Lua syntax but you will need an external tool to format the code
-- properly, like https://github.com/Koihik/LuaFormatter or similar.
--
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
-- This variables will be used later on as some cache variables to store values so we can execute
-- HSC using built in functions from the game and store the actual results from these and get them
-- back to Lua again and into the game.
local lpeg = require "lpeg"
local P, R, S = lpeg.P, lpeg.R, lpeg.S -- patterns
local C, Ct = lpeg.C, lpeg.Ct -- capture
local V = lpeg.V -- variable
local inspect = require "lua.modules.inspect"
local luna = require "lua.modules.luna"
local argparse = require "lua.scripts.modules.argparse"
local hscDoc = require "lua.modules.hscDoc"

local parser = argparse("hscToLua", "Transpiler for HSC (Halo Script Language) to Lua")
parser:argument("input", "Input HSC files to transpile"):args("*")
parser:option("-o --output", "Output Lua file to save the transpiled code", "output.lua")
parser:flag("--debug", "Enable debug mode")
parser:option("-m --module", "Write script as a module with a given name")
parser:flag("--unwrap-begin", "Do not unwrap begin blocks", false)

local args = parser:parse()

local function printd(...)
    if args.debug then
        print(...)
    end
end

local parser = P {
    "program", -- initial rule
    program = Ct(V "sexpr" ^ 0),
    wspace = S " \n\r\t" ^ 0,
    atom = V "boolean" + V "string" + V "symbol" + V "number",
    symbol = C((1 - S " \n\r\t\"'()[]{}#@~") ^ 1) / function(s)
        -- Consider all symbols that have / as a string, except if it is the division (/) operator
        if s:includes("/") and s:len() > 1 then
            return s
        end
        return s
    end,
    boolean = C(P "true" + P "false") / function(x)
        return x == "true"
    end,
    number = C(R "19" * R "09" ^ 0 * (P "." * R "09" ^ 1) ^ -1) / tonumber,
    string = P "\"" * C((1 - S "\"\n\r") ^ 0) * P "\"" / function(s)
        if s == "" then
            return "\"\""
        end
        return s
    end,
    coll = V "list" + V "array",
    list = P "'(" * Ct(V "expr" ^ 1) * P ")",
    array = P "[" * Ct(V "expr" ^ 1) * P "]",
    expr = V "wspace" * (V "coll" + V "atom" + V "sexpr"),
    group = V "wspace" * P "(" * Ct(V "expr" ^ 1) * V "wspace" * P ")",
    sexpr = V "wspace" * P "(" * ( -- Try a function-style S-expression: (symbol expr*)
    (V "symbol" * Ct(V "expr" ^ 0)) / function(f, ...)
        return {["function"] = f, ["args"] = ...}
    end + -- Otherwise fallback to a grouped expression (e.g. for cond branches)
    Ct(V "expr" ^ 1)) * V "wspace" * P ")"
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

-- Track variables and user defined functions
-- It will help us to diffentiate symbols later on
local globalVariables = {}
local localVariables = {}
local userDefinedFunctions = {}

--- Escape a string value to be used in Lua code
--- @param value string
--- @return string
local function escapeStringValue(value)
    local str = value
    str = str:replace("\\", "\\\\")
    if not str:startswith("\"") and not str:endswith("\"") then
        str = "\"" .. str .. "\""
    end
    return str
end

local function convertToString(value)
    if value:startswith("str_") or value:includes("\\") then
        return value:replace("str_", "")
    end
    return value
end

local nativeTypes = table.filter(hscDoc.nativeTypes, function(v)
    -- Remove string native types as we already handle those in the transpilation
    return not v:includes "string"
end)

local isSymbolLookupDone = false

local function convertAstToLua(astNode)
    local lua = ""
    if #astNode == 0 then
        astNode = {astNode}
    end
    for _, node in ipairs(astNode) do
        local hscArgs = node["args"] or {}
        local name = node["function"]
        if name == "global" then
            local varType = convertToString(hscArgs[1])
            local varName = hscArgs[2]
            local varValue = hscArgs[3]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            if not table.keyof(nativeTypes, varType) then
                varValue = escapeStringValue(varValue)
            end
            if varType == "boolean" then
                varValue = luna.bool(varValue)
            end

            -- Register the global variable existence and type
            globalVariables[varName] = varType

            print("Creating global variable " .. varName .. " of type " .. varType)
            lua = lua .. "local " .. varName .. " = " .. tostring(varValue) .. "\n"
        elseif name == "*" then
            for i, v in ipairs(hscArgs) do
                if type(v) == "table" then
                    hscArgs[i] = convertAstToLua(v)
                end
            end
            lua = lua .. table.concat(hscArgs, " * ") .. "\n"
        elseif name == "set" then
            local varName = hscArgs[1]
            local varValue = hscArgs[2]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            if globalVariables[varName] == "boolean" then
                varValue = luna.bool(varValue)
            end
            lua = lua .. varName .. " = " .. tostring(varValue) .. "\n"
        elseif name == "not" then
            local varValue = hscArgs[1]
            local hasSubExpression = type(varValue) == "table"
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            if hasSubExpression then
                lua = lua .. "not (" .. varValue .. ")"
            else
                lua = lua .. "not " .. varValue
            end
        elseif name == "=" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. tostring(var1) .. " == " .. tostring(var2) .. "\n"
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
                else
                    body[i] = convertToString(tostring(v))
                end
                -- Begin should return last evaluated expression
                -- Stock campaign scripts never used this but other complex scripts might
                if not args.unwrap_begin then
                    local updatedValue = tostring(body[i])
                    -- Handle some edge cases where scripts used run syntax like functions
                    -- as part of the begin block action, for example variable assignment is not
                    -- a function anymore, is an syntax for an action, we can not add a return to it
                    --
                    -- This prevents these edge cases, we might have to handle this with more
                    -- syntax converted functions from HSC tho
                    if not updatedValue:includes " = " and not updatedValue:startswith "if " then
                        body[i] = "return " .. body[i]
                    end
                end
            end
            -- This might help to produce more accurate "blocks" of code that keep scope of execution
            -- but it will look weird and might not be easy to read
            -- Check out the "begin_random" block for an example of possible conflicting cases
            if not args.unwrap_begin then
                for i, v in ipairs(body) do
                    if type(v) == "string" then
                        body[i] = "function() " .. v .. " end"
                    end
                end
                lua = lua .. "hsc." .. name .. "({\n" .. table.concat(body, ",\n") .. "})\n"
            else
                lua = lua .. table.concat(body, "")
            end
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
            lua = lua .. "hsc." .. name .. "({\n" .. table.concat(body, ",\n") .. "})\n"
            -- This might be an edge case so it is still safely to unwrap "begin" blocks in same
            -- scope after all, cause there are no other functions that explicitly run another
            -- function in different scopes.. I think
        elseif name == "cond" then
            local body = hscArgs
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    for j, v2 in ipairs(v) do
                        if type(v2) == "table" then
                            -- body[i][j] = "if " .. convertAstToLua(v2) .. " then "
                            body[i][j] = convertAstToLua(v2)
                        else
                            if tonumber(v2) then
                                body[i][j] = tonumber(v2)
                            elseif v2 == "true" or v2 == "false" then
                                body[i][j] = luna.bool(v2)
                            else
                                body[i][j] = convertToString(tostring(v2))
                            end
                        end
                        if j == 1 then
                            body[i][j] = "if " .. body[i][j] .. " then "
                        elseif j == #v and not tostring(body[i][j]):includes " = " then
                            -- body[i][j] = " return " .. body[i][j] .. " end"
                            body[i][j] = " return " .. body[i][j]
                        end
                    end
                end
            end
            body = table.map(body, function(v)
                return "{function() " .. table.concat(v, "") .. " end end}"
            end)
            lua = lua .. "hsc." .. name .. "(\n" .. table.concat(body, ",\n") .. ")\n"
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
            for i, v in ipairs(hscArgs) do
                if type(v) == "table" then
                    hscArgs[i] = convertAstToLua(v)
                end
            end
            lua = lua .. table.concat(hscArgs, " + ") .. "\n"
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
        elseif name == "<=" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " <= " .. var2 .. "\n"
        elseif name == ">=" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " >= " .. var2 .. "\n"
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
        elseif name == "/" then
            local var1 = hscArgs[1]
            local var2 = hscArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " / " .. var2 .. "\n"
        elseif name == "max" then
            for i, v in ipairs(hscArgs) do
                if type(v) == "table" then
                    hscArgs[i] = convertAstToLua(v)
                end
            end
            lua = lua .. "hsc.max(" .. table.concat(hscArgs, ", ") .. ")\n"
        elseif name == "min" then
            for i, v in ipairs(hscArgs) do
                if type(v) == "table" then
                    hscArgs[i] = convertAstToLua(v)
                end
            end
            lua = lua .. "hsc.min(" .. table.concat(hscArgs, ", ") .. ")\n"
        elseif name == "inspect" then
            for i, v in ipairs(hscArgs) do
                if type(v) == "table" then
                    hscArgs[i] = convertAstToLua(v)
                end
            end
            lua = lua .. "hsc.inspect(" .. table.concat(hscArgs, ", ") .. ")\n"
        elseif name == "print_if" then
            for i, v in ipairs(hscArgs) do
                if type(v) == "table" then
                    hscArgs[i] = convertAstToLua(v)
                end
                if i == 1 then
                    hscArgs[i] = "if " .. hscArgs[i] .. " then"
                elseif i == #hscArgs then
                    hscArgs[i] = "hsc.print(" .. hscArgs[i] .. ") end"
                end
            end
            lua = lua .. table.concat(hscArgs, " ") .. "\n"
        elseif name == "script" then
            local scriptType = hscArgs[1]
            local scriptName = hscArgs[2]
            local scriptBody = hscArgs[3]
            local scriptReturnType
            local scriptArgs
            if scriptType == "static" or scriptType == "stub" then
                scriptReturnType = hscArgs[2]
                scriptName = hscArgs[3]
                scriptBody = hscArgs[4]
                -- Script has arguments
                if type(scriptName) == "table" then
                    local scriptParameters = hscArgs[3]
                    scriptName = scriptParameters["function"]
                    print("Script name: " .. scriptName)
                    scriptArgs = table.map(scriptParameters["args"], function(v)
                        local type = v["function"]
                        local args = v["args"]
                        return {type = type, name = args[1]}
                    end)
                    localVariables = table.map(scriptArgs, function(v)
                        return v.name
                    end)
                    -- Remove script name from the body to prevent invokation
                    hscArgs[3] = scriptName
                end
                -- Register the user defined function existence and metadata
                userDefinedFunctions[scriptName] = {
                    args = table.map(scriptArgs or {}, function(v)
                        return v.type
                    end),
                    returnType = scriptReturnType,
                    funcName = scriptName
                }
                if scriptArgs then
                    scriptArgs = table.map(scriptArgs, function(v)
                        return v.name
                    end)
                end
            end
            print("Creating function " .. scriptName .. " of type " .. scriptType)
            if args.module then
                if scriptArgs then
                    lua =
                        lua .. "function " .. args.module .. "." .. scriptName .. "(call, sleep, " ..
                            table.concat(scriptArgs, ", ") .. ")\n"
                else
                    lua = lua .. "function " .. args.module .. "." .. scriptName ..
                              "(call, sleep)\n"
                end
            else
                if scriptArgs then
                    lua = lua .. "function " .. scriptName .. "(call, sleep, " ..
                              table.concat(scriptArgs, ", ") .. ")\n"
                else
                    lua = lua .. "function " .. scriptName .. "(call, sleep)\n"
                end
            end
            for i, v in ipairs(hscArgs) do
                if type(v) == "table" then
                    if scriptReturnType and scriptReturnType ~= "void" and i == #hscArgs then
                        lua = lua .. "return " .. convertAstToLua(v)
                    else
                        lua = lua .. "" .. convertAstToLua(v)
                    end
                end
            end
            lua = lua .. "end\n"

            -- Add script type declaration
            if scriptType == "continuous" then
                if args.module then
                else
                    lua = lua .. "script.continuous(" .. scriptName .. ")\n"
                end
                lua = lua .. "script.continuous(" .. args.module .. "." .. scriptName .. ")\n"
            end
            if scriptType == "startup" then
                if args.module then
                    lua = lua .. "script.startup(" .. args.module .. "." .. scriptName .. ")\n"
                else
                    lua = lua .. "script.startup(" .. scriptName .. ")\n"
                end
            end

            -- Reset local variables after exiting script scope
            localVariables = {}

            lua = lua .. "\n"
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
                    if args.module then
                        lua = lua .. "sleep(-1, " .. args.module .. "." .. scriptName .. ")\n"
                    else
                        lua = lua .. "sleep(-1, " .. scriptName .. ")\n"
                    end
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
            printd("Args:", inspect(hscArgs))
            for index, arg in ipairs(hscArgs) do
                -- Argument is a string value (not a symbol cause it starts with "str_")
                if type(arg) == "string" then
                    local argMetadata = table.find(hscDoc.functions, function(doc)
                        return doc.funcName:trim() == name:trim()
                    end)
                    if argMetadata then
                        printd("Function has metadata", inspect(argMetadata), inspect(hscArgs))
                        local argType = argMetadata.args[index]
                        local isVariable = table.find(localVariables, function(v)
                            return v == arg
                        end)
                        isVariable = isVariable or globalVariables[arg]
                        if isVariable then
                            printd("Found local variable " .. arg)
                            hscArgs[index] = arg
                        else
                            printd("Arg type: " .. argType)
                            local isNativeType = table.indexof(hscDoc.nativeTypes, argType)
                            if isNativeType then
                                printd("Found native type " .. argType)
                                if argType == "string" then
                                    hscArgs[index] = escapeStringValue(arg)
                                elseif arg:includes "\\" and arg:len() > 1 then
                                    hscArgs[index] = escapeStringValue(arg)
                                else
                                    hscArgs[index] = tostring(arg)
                                end
                            elseif arg:includes "\\" and arg:len() > 1 then
                                hscArgs[index] = escapeStringValue(arg)
                            else
                                hscArgs[index] = escapeStringValue(arg)
                            end
                        end
                    else
                        hscArgs[index] = convertToString(arg)
                    end
                elseif type(arg) == "boolean" then
                    hscArgs[index] = tostring(arg)
                else
                    hscArgs[index] = convertAstToLua(arg)
                end
            end
            -- TODO We might want to check this later on, not sure if we will ever need this,
            -- it all depends if HSC allowed you to create functions with the same names as the
            -- built-in functions, I highly doubt it but needs checking
            --
            -- For example let's assume you have created a script that shares the name of a
            -- function already defined in HSC or if you name a variable the same as a function
            -- name, this will cause a conflict and the transpiler will not be able to
            -- differentiate between the two, so we need to check if HSC allows this as valid
            -- syntax or not
            --
            -- Validate if the function is a user defined function or a built-in function
            local definedFunction = userDefinedFunctions[name]
            -- We are calling a user defined function
            if definedFunction then
                local functionArgs = definedFunction.args
                if args.module then
                    if functionArgs and #table.keys(functionArgs) > 0 then
                        print("Calling user defined function " .. args.module .. "." .. name)
                        for index, arg in ipairs(hscArgs) do
                            -- Argument is a string value (not a symbol cause it starts with "str_")
                            if type(arg) == "string" then
                                local argMetadata =
                                    table.find(userDefinedFunctions, function(doc)
                                        return doc.funcName:trim() == name:trim()
                                    end)
                                if argMetadata then
                                    print("Function has metadata", inspect(argMetadata),
                                          inspect(hscArgs))
                                    local argType = argMetadata.args[index]
                                    local isVariable =
                                        table.find(localVariables, function(v)
                                            return v == arg
                                        end)
                                    isVariable = isVariable or globalVariables[arg]
                                    if isVariable then
                                        print("Found local variable " .. arg)
                                        hscArgs[index] = arg
                                    else
                                        print("Arg type: " .. argType)
                                        local isNativeType =
                                            table.indexof(hscDoc.nativeTypes, argType)
                                        if isNativeType then
                                            print("Found native type " .. argType)
                                            if argType == "string" then
                                                hscArgs[index] = escapeStringValue(arg)
                                            elseif arg:includes "\\" and arg:len() > 1 then
                                                hscArgs[index] = escapeStringValue(arg)
                                            else
                                                hscArgs[index] = tostring(arg)
                                            end
                                        elseif arg:includes "\\" and arg:len() > 1 then
                                            hscArgs[index] = escapeStringValue(arg)
                                        else
                                            hscArgs[index] = convertToString(arg)
                                        end
                                    end
                                else
                                    hscArgs[index] = tostring(arg)
                                end
                            elseif type(arg) == "boolean" then
                                hscArgs[index] = tostring(arg)
                            else
                                hscArgs[index] = convertAstToLua(arg)
                            end
                        end

                        lua = lua .. "call(" .. args.module .. "." .. name .. "," ..
                                  table.concat(hscArgs, ", ") .. ")\n"
                    else
                        lua = lua .. "call(" .. args.module .. "." .. name .. ")\n"
                    end
                else
                    lua = lua .. "call(" .. name .. ")\n"
                end
            else
                -- We are calling a built in function
                lua = lua .. "hsc." .. name .. "(" .. table.concat(hscArgs, ", ") .. ")\n"
            end
        end
    end
    return lua
end

-- HSC file as a string
local hscInput = ""
for i, v in ipairs(args.input) do
    local file = luna.file.read(v)
    if file then
        hscInput = hscInput .. "\n" .. file
    else
        print("Error reading HSC file " .. v)
    end
end
assert(hscInput, "Error reading HSC file")
-- Remove all comments from the HSC script (; is the comment delimiter)
--
-- Maybe we should consider adding a flag to keep comments in the future
hscInput = hscInput:gsub(";[^\n]*", "")
local hsc = parser:match(hscInput)

printd("------------------- AST -------------------------------")
printd(inspect(hsc))

local lua = convertAstToLua(hsc)
if not isSymbolLookupDone then
    lua = ""
    hsc = parser:match(hscInput)
    -- FIXME This is a workaround to prevent transpiler from wrongly assuming that symbols that
    -- are created later on in different scripts but used early belong to the HSC functions module
    -- but are not, such as scripts that get defined later down the road in a different script
    -- but used in a script sooner in the hierarchy
    --
    -- We should split this into two phases so we can predeclare all symbols such as scripts and
    -- variables that will be declared at some point in the scripts but are referenced earlier
    lua = convertAstToLua(hsc)
    isSymbolLookupDone = true
end

local header = [[---------- Transpiled from HSC to Lua ----------
local script = require "script"
local wake = require"script".wake
local hsc = require "hsc"
local easy = "easy"
local normal = "normal"
local hard = "hard"
local impossible = "impossible"

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

-- local split = args.input:replace("\\", "/"):split("/")
-- local fileName = split[#split]
-- local fileNameWithoutExtension = fileName:split(".")[1]

-- assert(luna.file.write(fileNameWithoutExtension .. ".lua", lua), "Error writing Lua file, check if you have write permissions to the directory")
assert(luna.file.write(args.output, lua),
       "Error writing Lua file, check if you have write permissions to the directory")
