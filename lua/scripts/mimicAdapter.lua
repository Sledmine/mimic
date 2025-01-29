-- Mimic HSC Adapter
-- Sledmine
-- Converts a HSC campaign/coop script into a Mimic friendly server script.
local luna = require "lua.modules.luna"
local inspect = require "lua.modules.inspect"

-- Util string operations
function string.insert(str1, str2, pos)
    return str1:sub(1, pos) .. str2 .. str1:sub(pos + 1)
end
function string.override(str1, str2, from, to)
    return str1:sub(1, from) .. str2 .. str1:sub(to + 1)
end

local maximumActionLength = 80

local actions = {
    "hud_set_timer_position",
    "hud_set_timer_time",
    "hud_set_timer_warning_time",
    "pause_hud_timer",
    "show_hud_timer",
    "hud_set_objective_text",
    "show_hud_help_text",
    "hud_set_help_text",
    "show_hud",
    -- Verify if this is needed on the client side
    -- "set",
    "fade_in",
    "fade_out",
    "camera_control",
    "camera_set",
    "camera_set_first_person",
    "camera_set_relative",
    "cinematic_screen_effect_start",
    "cinematic_screen_effect_set_convolution",
    "cinematic_screen_effect_set_filter_desaturation_tint",
    "cinematic_screen_effect_set_filter",
    "cinematic_start",
    "cinematic_set_title",
    "cinematic_show_letterbox",
    "cinematic_stop",
    "sound_impulse_start",
    "sound_looping_start",
    "sound_looping_stop",
    "sound_looping_set_alternate",
    "sound_class_set_gain",
    "ai_conversation",
    "ai_conversation_stop",
    -- Probably can cause issues with Mimic
    -- "ai_attach_free",
    -- We do not need this anymore, Mimic can sync this natively
    -- "switch_bsp",
    "player_enable_input",
    "object_create",
    "object_create_anew",
    "object_create_containing",
    "object_destroy",
    "unit_set_seat",
    "unit_set_emotion",
    "unit_suspended",
    "unit_stop_custom_animation",
    "unit_custom_animation_at_frame",
    -- Replace with a vehicle enter function from SAPP, desyncs otherwise
    -- "unit_enter_vehicle",
    "object_teleport",
    -- "object_pvs_activate",
    -- We need a more native implementation of this on Mimic, probably using Harmony
    -- This can consume a lot of bandwidth when Mimic attempts to sync them
    "device_set_position",
    "device_set_position_immediate",
    "device_set_power",
    "device_one_sided_set",
    -- "breakable_surfaces_enable",
    -- "breakable_surfaces_reset",
    -- "activate_nav_point_flag",
    -- "deactivate_nav_point_flag",
    -- "effect_new",
    "custom_animation",
    "scenery_animation_start",
    "recording_play",
    "objects_attach",
    "objects_detach",
    -- Only used in d40
    "numeric_countdown_timer_set",
    "numeric_countdown_timer_stop"
}

local header = [[; Used to communicate with Mimic Server
(global "string" sync_hsc_command "")

; Used to trigger events instead of game_is_cooperative
(global boolean is_multiplayer false)

; Used to perform events only on host side
(global boolean is_host false)

(script static "unit" player2
(unit (list_get (players )2 )))

(script static "unit" player3
(unit (list_get (players )3 )))

(script static "unit" player4
(unit (list_get (players )4 )))

(script static "unit" player5
(unit (list_get (players )5 )))

(script static "unit" player6
(unit (list_get (players )6 )))

(script static "unit" player7
(unit (list_get (players )7 )))

(script static "unit" player8
(unit (list_get (players )8 )))

(script static "unit" player9
(unit (list_get (players )9 )))

(script static "unit" player10
(unit (list_get (players )10 )))

(script static "unit" player11
(unit (list_get (players )11 )))

(script static "unit" player12
(unit (list_get (players )12 )))

(script static "unit" player13
(unit (list_get (players )13 )))

(script static "unit" player14
(unit (list_get (players )14 )))

(script static "unit" player15
(unit (list_get (players )15 )))

]]

local replacements = {
    ["startup mission_"] = "dormant main_",
    -- Allow server game to end
    ["(game_won )"] = "(begin (cinematic_show_letterbox false)(sv_map_next))",
    ["(game_lost )"] = "(begin (cinematic_show_letterbox false)(sv_map_next))",
    -- Force variable comparision for cooperative mode
    game_is_cooperative = "> (player_count) 1",
    -- C20 hardcoded replacements
    ["monitor_dialogue_scale )"] = " 1)",
    ["\" (list_get (ai_actors bsp0_monitor )0 )"] = "\" none ",
    ["\" (list_get (ai_actors bsp1_monitor )0 )"] = "\" none ",
    ["\" (list_get (ai_actors bsp2_monitor )0 )"] = "\" none ",
    ["\" (list_get (ai_actors bsp3_monitor )0 )"] = "\" none "
    -- ["activate_team_nav_point_flag default_red player"] = "activate_nav_point_flag default_red (player0)",
    -- ["deactivate_team_nav_point_flag player"] = "deactivate_nav_point_flag (player0)"
    -- ["object_teleport (player1 )"] = function (action)
    --    local splitAction = action:split "object_teleport (player1 )"
    --    for playerIndex = 2,15 do
    --        local newAction = splitAction[2]
    --    end
    -- end
}

-- Absolute or relative path to the HSC script to convert
---@type string
local hscPath = arg[1]
assert(hscPath, "You must provide a HSC script to convert!")

local hsc = luna.file.read(arg[1]) --[[@as string]]

if hsc then
    hsc = hsc:insert(header, 0)
    for k, v in pairs(replacements) do
        -- hsc = hsc:gsub(k:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]','%%%1'), v)
        hsc = hsc:replace(k, v)
    end

    for _, name in pairs(actions) do
        local actionStart, actionNameEnd = 0, 0
        local functionName = "%(" .. name .. " "
        while actionStart do
            actionStart, actionNameEnd = hsc:find(functionName, actionNameEnd)
            if actionStart then
                local actionNameStart = actionStart + 1

                local actionName = hsc:sub(actionNameStart, actionNameEnd)
                local actionCloseStart = hsc:find("%)", actionNameEnd)
                local actionBody = hsc:sub(actionNameEnd + 1, actionCloseStart - 1)
                local actionBodySubParenthesis = actionBody:find("%(")
                while actionBodySubParenthesis do
                    actionCloseStart = hsc:find("%)", actionCloseStart + 1)
                    actionBody = hsc:sub(actionNameEnd + 1, actionCloseStart - 1)
                    actionBodySubParenthesis = actionBody:find("%(", actionCloseStart + 1)
                end
                if not actionCloseStart then
                    actionCloseStart = hsc:find("%)", actionNameEnd)
                end

                local originalAction = "(" .. actionName .. actionBody .. ")"
                local syncAction = "sync_" .. actionName .. actionBody
                -- This function is almost impossible to sync with Mimic, ignore it if present
                if not originalAction:includes("ai_actors") then
                    local syncActionLength = string.len(syncAction)
                    if syncActionLength > maximumActionLength then
                        print("Warning: " .. syncAction .. " is too long for rcon -> " ..
                                  syncActionLength)
                    end
                    local newAction = "(set sync_hsc_command \"" .. syncAction:replace("\"", "'") ..
                                          "\")"
                    -- local fixedAction = originalAction .. newAction
                    local fixedAction = "(begin " .. originalAction .. newAction .. ")"

                    -- Print debug info
                    print("-------------------------- (" .. name .. ") --------------------------")
                    print("ORIGINAL: " .. originalAction)
                    print("\27[34mSYNC:\27[0m\t" .. syncAction)
                    print("\27[33mFIXED:\27[0m\t" .. fixedAction)

                    isActionOverriden = (name == "ai_conversation" or
                                            (hscPath:find("c10") or hscPath:find("c20") and
                                                (name == "device_set_position_immediate" or name ==
                                                    "device_set_position")))
                    if isActionOverriden then
                        hsc = hsc:override(fixedAction, actionStart - 1, actionCloseStart)
                    else
                        hsc = hsc:insert(newAction, actionCloseStart)
                    end
                else
                    print("Warning, ai_actors sync is not supported: " .. syncAction)
                end
            end
        end
    end
end

if not hsc:find("sv_map_next") then
    print(
        "WARNING, There is no sv_map_next present on this script, game will never end on multiplayer!")
end
local outputPath = hscPath:gsub("%.hsc", "_sync.hsc")
print("\n\27[32mScript succesfully adapted to Mimic\27[0m")
print("Saving output to: " .. outputPath .. "\n")
luna.file.write(outputPath, hsc)
