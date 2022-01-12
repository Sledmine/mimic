<html>
    <p align="center">
        <img width="200px" src="img/mimic_logo.png"/>
    </p>
    <h1 align="center">Mimic</h1>
    <p align="center">
       Events and AI Synchronization for Halo Custom Edition
    </p>
</html>

Halo Custom Edition AI Sync, a project that aims to provide AI synchronization in the most optimized
and simple way as possible, made with Lua for SAPP and Chimera.

# Getting Mimic
Get the latest version of the mod using the Mercury command:
```
mercury install mimic
```
# How it works?
Mimic is capable of syncing different aspects of the game, like AI bipeds, device machines, bsp index,
and script events, by providing a server script that tracks all the data of every aspect we want to
sync using Lua scripting on the server side and sending that information back to the client players
connected to the server that need that information depending on the situation.

**NOTE:** By now script events only can be synced by recompiling our target map with respective HSC
script adapted using the **Mimic Adapter Tool**.

# Can I contribute/help?
This project is on early development, feel free to contribute and join our [Discord server](https://discord.shadowmods.net)
server if you want to get more information about design, goals and updates for the project.