--CSGO sv_cheats spoof
-----------------------------
--	LauncherSU.net
--				Lua5.1
-----------------------------
local pid = findProcessByName("csgo.exe")
if(pid == nil) then

print("CSGO not found!")

end

m_OpenProcess(pid)
local mod = GetRemoteModule(pid,"engine.dll")
--CC A1 ? ? ? ? B9 ? ? ? ? FF 50 34 F7 D8 1B C0 F7 D8 C3 + 0x1
local addr = tostring(mod + 0x1E1010) -- Lua 5.1 needs tostring() to correct calc the address,we have plan to move to Lua5.3+

local result = m_ReadProcessMemory(tostring(addr+1),1,1)

if(result == 0x1) then


print("-------------------------------")
print("sv_cheats 1 spoof already done!")
print("-------------------------------")

else

--mov al,01
--ret
m_VirtualProtectEx(addr,5,64)
m_WriteProcessMemory(addr,0xB0,1)
m_WriteProcessMemory(tostring(addr+1),0x01,1)
m_WriteProcessMemory(tostring(addr+2),0xC3,1)
m_WriteProcessMemory(tostring(addr+3),0x90,1)
m_WriteProcessMemory(tostring(addr+4),0x90,1)

m_VirtualProtectEx(addr,5,32)
print("-------------------------------")
print("sv_cheats 1 spoof done\nwarning:the patch is uncancellable")
print("-------------------------------")

end



m_CloseHandle() --CloseHandle