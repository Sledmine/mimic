local lu = require "lua.tests.luaunit"
local glue = require "glue"

-- Mocking and test setup
package.path = package.path .. ";./lua/?.lua"
console_out = print
local core = require "lua.mimic.core"

TestCore = {}

function TestCore:setUp()
    self.commandWithSpaces =
        [[custom_animation chief_armed 'cinematics\animations test\chief\x70\x70' 'x70_0210' false]]
    self.commandWithDashes =
        [[custom_animation cortana 'cinematics\animations\cortana\x70\x70' 'x70_2_410-725' true]]
    self.commandWithDashesNoTag = [[objects_attach chief_test 'test-345' 'super test' 1]]
    self.commandWithBlankParameters = [[objects_attach chief_test 'test' '' 1]]
    self.commandNoParameters = [[cinematic_stop]]
end

function TestCore:testHSCParser()
    lu.assertEquals(core.parseHSC(self.commandWithSpaces), {
        "custom_animation",
        "chief_armed",
        [[cinematics\animations test\chief\x70\x70]],
        "x70_0210",
        "false"
    })

    lu.assertEquals(core.parseHSC(self.commandWithDashes), {
        "custom_animation",
        "cortana",
        [[cinematics\animations\cortana\x70\x70]],
        "x70_2_410-725",
        "true"
    })

    lu.assertEquals(core.parseHSC(self.commandWithDashesNoTag),
                    {"objects_attach", "chief_test", [[test-345]], "super test", "1"})

    lu.assertEquals(core.parseHSC(self.commandWithBlankParameters),
                    {"objects_attach", "chief_test", "test", "''", "1"})

    lu.assertEquals(core.parseHSC(self.commandNoParameters), {"cinematic_stop"})
end

local function runTests()
    local runner = lu.LuaUnit.new()
    runner:runSuite()
end

if (not arg) then
    return runTests
else
    runTests()
end
