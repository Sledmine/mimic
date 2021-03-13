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
-- Second parameter is the position in axis X of the biped object
-- Third parameter is the position in axis Y of the biped object
-- Fourth parameter is the position in axis Z of the biped object
"@s(2),tagIndex(4),i4x(10),i4x(10),i4x(10)"
```