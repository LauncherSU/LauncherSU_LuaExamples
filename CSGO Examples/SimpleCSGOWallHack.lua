--CSGO Simple WallHack 
-----------------------------
--	LauncherSU.net
--				Lua5.1
-----------------------------
local pid = findProcessByName("csgo.exe")
if(pid == nil) then

print("CSGO不存在!")

end

m_OpenProcess(pid)
local mod = GetRemoteModule(pid,"client.dll")
local addr = tostring(mod + 0x1CC1F6 + 0x2) -- Lua 5.1 needs tostring() to correct calc the address,we have plan to move to Lua5.3+
local result = m_ReadProcessMemory(addr,1,1)

if(result == 0x2) then --enable

m_VirtualProtectEx(addr,1,64)
m_WriteProcessMemory(addr,1,1)
m_VirtualProtectEx(addr,1,32)

elseif(result == 0x1) then --disable

m_VirtualProtectEx(addr,1,64)
m_WriteProcessMemory(addr,2,1)
m_VirtualProtectEx(addr,1,32)

end

m_CloseHandle() --CloseHandle