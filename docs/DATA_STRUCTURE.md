# Data Structure

This document contains all the information about the structure for different actions from the
server to client, using 80 bytes wide string message as data that we call packets.

Some packets can have parameters and the minimum size of packet is 2 bytes, parameters are
delimited by a comma or a special char (comma by default).

# Spawn AI

```lua
-- First char is designed to represent a string packet
-- Second char represents the type of action from the server
"@s(2)"

-- First parameter is the tagIndex of the biped object that the server is trying to sync
-- Second parameter is the object id from the server
"@s(2),serverId1(1-5),objectX(10),objectY(10),objectZ(10)"
```

# Update AI

```lua
-- First char is designed to represent a string packet
-- Second char represents the type of action from the server
"@u(2)"

-- First parameter is the serverId of the biped object that the server is trying to sync
-- Others parameter are the object coordinates
"@u(2),serverId(8),objectX(10),objectY(10),objectZ(10),objectAnim(10)"
```

# Kill AI

```lua
-- First char is designed to represent a string packet
-- Second char represents the type of action from the server
"@k(2)"

-- First parameter is the serverId of the biped object that the server is trying to sync
-- Others parameter are the object coordinates
"@k(2),serverId(8)"
```