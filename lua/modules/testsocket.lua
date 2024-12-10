local socket = require "socket"
local mimicsock = socket.udp()
if (arg[1] == "server") then
    mimicsock:setsockname("localhost", 3030)    
else
    mimicsock:setpeername("localhost", 3030)
end
mimicsock:settimeout(0)

while true do
    if (arg[1] == "server") then
        local data = mimicsock:receive()
        if (data) then
            print(data)
        end
    else
        mimicsock:send("It works!")
    end
end
