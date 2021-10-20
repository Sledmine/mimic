local blam = require "blam"
local tagClasses = blam.tagClasses

return {
    sound_impulse_start = {
        name = "sound_impulse_start",
        packetType = "@sis",
        arguments = {
            {name = "sound", type = "string", value = "path", class = tagClasses.sound},
            {name = "object", type = "string"},
            {name = "gain", type = "number"}
        }
    },
    effect_new = {
        name = "effect_new",
        packetType = "@en",
        arguments = {
            {name = "effect", type = "string", value = "path", class = tagClasses.effect},
            {name = "cutscene_flag", type = "string"}
        }
    },
    custom_animation = {
        name = "custom_animation",
        packetType = "@ca",
        arguments = {
            {name = "unit", type = "string"},
            {
                name = "animation_graph",
                type = "string",
                value = "path",
                class = tagClasses.modelAnimations
            },
            {name = "animation", type = "string"},
            {name = "interpolate", type = "boolean"},
            {name = "frame", type = "number"}
        }
    },
    scenery_animation_start = {
        name = "scenery_animation_start",
        packetType = "@sas",
        arguments = {
            {name = "scenery", type = "string"},
            {
                name = "animation_graph",
                type = "string",
                value = "path",
                class = tagClasses.modelAnimations
            },
            {name = "animation", type = "string"}
        }
    },
    unit_custom_animation_at_frame = {
        name = "unit_custom_animation_at_frame",
        packetType = "@ucaatf",
        arguments = {
            {name = "unit", type = "string"},
            {name = "animation_graph", type = "string", value = "path", class = tagClasses.modelAnimations},
            {name = "animation", type = "string"},
            {name = "interpolate", type = "boolean"},
            {name = "frame", type = "number"}
        }
    }
}
