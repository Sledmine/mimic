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
local _, lpeg = pcall(require, "lpeg")
if not lpeg then
    -- Default to local lpeg if native lpeg is not available
    lpeg = require "lua.modules.lulpeg"
end
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
parser:option("--module", "Write script as a module with a given name", "module")

local args = parser:parse()

local parser = P {
    "program", -- initial rule
    program = Ct(V "sexpr" ^ 0),
    wspace = S " \n\r\t" ^ 0,
    atom = V "boolean" + V "string" + V "symbol" + V "number",
    symbol = C((1 - S " \n\r\t\"'()[]{}#@~") ^ 1) / function(s)
        -- Consider all symbols that have / as a string, except if it is the division (/) operator
        -- if s:includes("/") and s:len() > 1 then
        --    return "str_" .. s
        -- end
        return s
    end,
    boolean = C(P "true" + P "false") / function(x)
        return x == "true"
    end,
    number = C(R "19" * R "09" ^ 0 * (P "." * R "09" ^ 1) ^ -1) / tonumber,
    string = P "\"" * C((1 - S "\"\n\r") ^ 0) * P "\"" / function(s)
        -- return "str_" .. s
        return s
    end,
    coll = V "list" + V "array",
    list = P "'(" * Ct(V "expr" ^ 1) * P ")",
    array = P "[" * Ct(V "expr" ^ 1) * P "]",
    expr = V "wspace" * (V "coll" + V "atom" + V "sexpr"),
    group = V "wspace" * P "(" * Ct(V "expr" ^ 1) * V "wspace" * P ")",
    -- Try a function-style S-expression: (symbol expr*)
    --------------------------------------------------------------------------
    -- sexpr = V "wspace" * P "(" * ( -- Try a function-style S-expression: (symbol expr*)
    -- (V "symbol" * Ct(V "expr" ^ 0)) / function(f, ...)
    --    return {["function"] = f, ["args"] = ...}
    -- end + -- Otherwise fallback to a grouped expression (e.g. for cond branches)
    -- Ct(V "expr" ^ 1)) * V "wspace" * P ")"
    --------------------------------------------------------------------------
    --- Use array of symbols instead of a symbol expressions
    sexpr = V "group" +
        (V "wspace" * P "(" * V "symbol" * Ct(V "expr" ^ 0) * V "wspace" * P ")" / function(f, ...)
            return {["function"] = f, ["args"] = ...}
        end)

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

-- Track variables and user defined functions
-- It will help us to diffentiate symbols later on
local variables = {}
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

local function convertAstToLua(astNode, context)
    local lua = ""
    for nodeIndex, node in ipairs(astNode) do
        print("___________________________________________________________________")
        local name
        local astArgs
        if type(node) ~= "table" then
            name = node
            astArgs = table.slice(astNode, nodeIndex + 1)
        else
            name = node[1]
            astArgs = table.slice(node, 2)
        end
        -- print("Node index: " .. nodeIndex)
        -- print("Node: " .. inspect(node))
        print("Node name: " .. name)
        print("Arguments: ")
        for k, v in pairs(astArgs) do
            print(k, inspect(v))
        end
        if name == "global" then
            local varType = convertToString(astArgs[1])
            local varName = astArgs[2]
            local varValue = astArgs[3]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            if not table.keyof(nativeTypes, varType) then
                varValue = escapeStringValue(varValue)
            end
            if varType == "boolean" then
                varValue = luna.bool(varValue)
            end
            variables[varName] = varType
            print("\t-> Creating global variable " .. varName .. " of type " .. varType ..
                      " with value " .. tostring(varValue))
            lua = lua .. "local " .. varName .. " = " .. tostring(varValue) .. "\n"
        elseif name == "*" then
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " * " .. var2 .. "\n"
        elseif name == "set" then
            local varName = astArgs[1]
            local varValue = astArgs[2]
            if type(varValue) == "table" then
                varValue = convertAstToLua(varValue)
            end
            if variables[varName] == "boolean" then
                varValue = luna.bool(varValue)
            end
            lua = lua .. varName .. " = " .. tostring(varValue) .. "\n"
        elseif name == "not" then
            local varValue = astArgs[1]
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
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. tostring(var1) .. " == " .. tostring(var2) .. "\n"
        elseif name == "if" then
            local condition = astArgs[1]
            local body = astArgs[2]
            local elseBody = astArgs[3]
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
            local body = astArgs
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    body[i] = convertAstToLua(v)
                end
            end
            lua = lua .. table.concat(body, " and ") .. ""
        elseif name == "begin" then
            local body = astArgs
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    body[i] = convertAstToLua(v)
                end
            end
            -- Most begin elements in body will already have a newline at the end
            -- so we don't need to add a new line at the end of each element
            -- Or do we?... Not having it makes it more readable tho
            --
            -- lua = lua .. table.concat(body, "\n")
            --
            lua = lua .. table.concat(body, "")
            -- Should we consider begin blocks as self running functions?
            --
            -- lua = lua .. "function()\n" .. table.concat(body, "\n") .. "end\n"
            --
            -- This might help to produce more accurate "blocks" of code that keep scope of execution
            -- but it will look weird and might not be easy to read
            -- Check out the "begin_random" block for an example of possible conflicting cases
        elseif name == "begin_random" or name == "cond" then
            local body = astArgs
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
        elseif name == "or" then
            local body = astArgs
            for i, v in ipairs(body) do
                if type(v) == "table" then
                    body[i] = convertAstToLua(v)
                end
            end
            lua = lua .. table.concat(body, " or ") .. ""
        elseif name == "-" then
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " - " .. var2 .. "\n"
        elseif name == "+" then
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " + " .. var2 .. "\n"
        elseif name == "<" then
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " < " .. var2 .. "\n"
        elseif name == ">" then
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " > " .. var2 .. "\n"
        elseif name == "<=" then
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " <= " .. var2 .. "\n"
        elseif name == ">=" then
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " >= " .. var2 .. "\n"
        elseif name == "!=" then
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " ~= " .. var2 .. "\n"
        elseif name == "/" then
            local var1 = astArgs[1]
            local var2 = astArgs[2]
            if type(var1) == "table" then
                var1 = convertAstToLua(var1)
            end
            if type(var2) == "table" then
                var2 = convertAstToLua(var2)
            end
            lua = lua .. var1 .. " / " .. var2 .. "\n"
        elseif name == "script" then
            local scriptType = astArgs[1]
            local scriptName = astArgs[2]
            local scriptBody = table.slice(astArgs, 3)
            local scriptReturnType
            local scriptParameters
            print("-> Creating script \"" .. scriptName .. "\" of type \"" .. scriptType .. "\"")
            if scriptType == "static" then
                scriptReturnType = astArgs[2]
                scriptName = astArgs[3]
                scriptBody = table.slice(astArgs, 4)
                -- Script has arguments
                if type(scriptName) == "table" then
                    local args = astArgs[3]
                    scriptName = args[1]
                    scriptParameters = table.slice(args, 2)
                    -- Remove script name from the body to prevent invokation
                    -- astArgs[3] = scriptName
                end
                -- Create metadata for user defined function, used later on to determine arg types
                local definedFunction = {
                    returnType = scriptReturnType,
                    args = table.map(scriptParameters or {}, function(v)
                        local argType = v[1]
                        local argName = v[2]
                        return argType
                    end),
                    parameters = table.map(scriptParameters or {}, function(v)
                        local argType = v[1]
                        local argName = v[2]
                        return argName
                    end)
                }
                print("Parameters: ")
                for k,v in pairs(scriptParameters or {}) do
                    --print(k, inspect(v))
                    local argType = v[1]
                    local argName = v[2]
                    print(k, argType, argName)
                end
                userDefinedFunctions[scriptName] = definedFunction
                if scriptParameters then
                    scriptParameters = table.map(scriptParameters, function(v)
                        local argType = v[1]
                        local argName = v[2]
                        return argName
                    end)
                end
            end
            if scriptParameters then
                lua = lua .. "function " .. args.module .. "." .. scriptName .. "(call, sleep, " ..
                          table.concat(scriptParameters, ", ") .. ")\n"
            else
                lua = lua .. "function " .. args.module .. "." .. scriptName .. "(call, sleep)\n"
            end
            print("Body: ")
            for i, v in ipairs(scriptBody) do
                print(i, inspect(v))
                if type(v) == "table" then
                    if scriptReturnType and scriptReturnType ~= "void" and i == #astArgs then
                        lua = lua .. "return " .. convertAstToLua(v, definedFunction)
                    else
                        lua = lua .. convertAstToLua(v, definedFunction)
                    end
                end
            end
            lua = lua .. "end\n"
            if scriptType == "continuous" then
                lua = lua .. "script.continuous(" .. args.module .. "." .. scriptName .. ")\n"
            end
            if scriptType == "startup" then
                lua = lua .. "script.startup(" .. args.module .. "." .. scriptName .. ")\n"
            end
            lua = lua .. "\n"
        elseif name == "wake" then
            local scriptName = astArgs[1]
            if args.module then
                lua = lua .. "wake(" .. args.module .. "." .. scriptName .. ")\n"
            else
                lua = lua .. "wake(" .. scriptName .. ")\n"
            end
        elseif name == "sleep" then
            for i, v in ipairs(astArgs) do
                if type(v) == "table" then
                    astArgs[i] = convertAstToLua(v)
                end
            end
            local sleepForTicks = astArgs[1]
            local scriptName = astArgs[2]
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
            for i, v in ipairs(astArgs) do
                if type(v) == "table" then
                    astArgs[i] = convertAstToLua(v)
                end
            end
            if #astArgs == 1 then
                local condition = astArgs[1]
                lua = lua .. "sleep(function() return " .. condition .. " end)\n"
            elseif #astArgs == 2 then
                local condition = astArgs[1]
                local everyTicks = astArgs[2]
                lua = lua .. "sleep(function() return " .. condition .. " end, " .. everyTicks ..
                          ")\n"
            else
                local condition = astArgs[1]
                local everyTicks = astArgs[2]
                local maximumTicks = astArgs[3]
                lua = lua .. "sleep(function() return " .. condition .. " end, " .. everyTicks ..
                          ", " .. maximumTicks .. ")\n"
            end
        else
            -- We are handling a normal function call
            local hasArgs = astArgs and #astArgs > 0
            local funcMetadata = table.find(hscDoc.functions, function(doc)
                return doc.funcName:trim() == name:trim()
            end)
            local userDefinedFunction = userDefinedFunctions[name]
            if userDefinedFunction then
                funcMetadata = userDefinedFunction
            end
            if funcMetadata then
                print("<---------------------------------------------------------------->")
                print("-> Calling function: \"" .. name .. "\"")
                print("Arguments: ")
                -- print("Function metadata: " .. inspect(funcMetadata))
                for index, arg in ipairs(astArgs or {}) do
                    -- Argument is a string value (not a symbol cause it starts with "str_")
                    local argType = funcMetadata.args[index]
                    local parameter = funcMetadata.parameters and funcMetadata.parameters[index] or nil
                    print(index, inspect(arg), argType)
                    if parameter then
                        print("Is context")
                        local isParameter = table.find(context.args, function (v, k)
                            print("asdasdasd", v)
                            return v
                        end)
                    else
                        if type(arg) == "string" then
                            if not table.indexof(nativeTypes, argType) and not arg:includes("(") and
                                not arg:includes(")") and not variables[arg] then
                                astArgs[index] = escapeStringValue(arg:replace("str_", ""))
                            else
                                astArgs[index] = convertToString(arg)
                            end
                        elseif type(arg) == "boolean" then
                            astArgs[index] = tostring(arg)
                        elseif type(arg) == "string" then
                            if not arg:includes("(") and not arg:includes(")") and not arg:includes(" ") and
                                not tonumber(arg) and not variables[arg] then
                                astArgs[index] = escapeStringValue(arg)
                            end
                        elseif argType == "var" then
                            print("WHAAAAAAAAAAAAAAAAAAAAAAT:", inspect(arg))
                            astArgs[index] = arg:replace("\"", "")
                        else
                            -- If the argument is a table, we need to convert it to Lua code
                            if type(arg) == "table" then
                                astArgs[index] = convertAstToLua(arg)
                            end
                        end
                    end
                end
                if hasArgs then
                    -- We are calling a built in function
                    lua = lua .. "hsc." .. name .. "(" .. table.concat(astArgs, ", ") .. ")\n"
                else
                    -- We are calling a function without arguments
                    lua = lua .. "hsc." .. name .. "()\n"
                end
            else
                --print("Warning, no func")
                lua = lua .. name
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
        hscInput = hscInput .. file
    else
        print("Error reading HSC file " .. v)
    end
end
assert(hscInput, "Error reading HSC files, check if the files exist and are readable")
-- Remove all comments from the HSC script (; is the comment delimiter)
--
-- Maybe we should consider adding a flag to keep comments in the future
hscInput = hscInput:gsub(";[^\n]*", "")
print("Parsing HSC script...")
-- print(hscInput)
local hsc = parser:match(hscInput)
assert(#hsc > 0, "Error parsing HSC script, check if the script is valid HSC code")

if args.debug then
    print("------------------- NODES -------------------------------")
    print(inspect(hsc))
    -- return
end

print("------------------- AST -------------------------------")
local lua = convertAstToLua(hsc)
print("------------------- LUA -------------------------------")
print(lua)
os.exit()

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
