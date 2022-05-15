loadluafromfileR("scspoof.lua") -- requires sv_cheats spoof

print("warning: you need run this each time you enter game")

local hwnd = FindWindow("Valve001","")
c_ExecuteConsoleCommand(hwnd,"r_drawothermodels 2")

print("r_drawothermodels setted to 2")