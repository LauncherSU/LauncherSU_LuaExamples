Convar = {}

local function toUnsigned(address_) -- Library
	return string.format("%u",address_)
end

local function BuildHexTableByString(srcText) -- Library
	local tables = {}
	if(string.len(srcText) % 4 == 0) then
		local stack = ""
		for i=1,string.len(srcText) do
			stack = string.format("%X",string.byte(string.sub(srcText,i,i))) .. stack
			if(i % 4 == 0) then
				tables[i/4] = stack
				stack = ""
			end
		end
	else
		for i=1,string.len(srcText) do
			tables[i] = string.format("%X",string.byte(string.sub(srcText,i,i)))
		end
	end
	return tables
end

local function checkCachePidMatch()
	local pid = findProcessByName("csgo.exe")	
	if(pid == tonumber(readtemp("csgo","pid"))) then
		return true
	end
	return false
end

local function GetCVarInterface() 
	local pid = findProcessByName("csgo.exe")
	if(pid < 1) then
		print("CSGO not found")
		return 0
	end
	m_OpenProcess(pid)
	local mod = GetRemoteModule(pid,"vstdlib.dll")
	if(mod < 1) then
		print("find module failed")
		return 0
	end
	if(checkCachePidMatch() == true) then
		print("reading from cache:",toUnsigned(readtemp("csgo","cvar_entry")))
		return readtemp("csgo","cvar_entry")
	end
	local addr_sigscan = m_PatternScan("vstdlib.dll","8B 0D ? ? ? ? C7 05")
	local result = m_ReadProcessMemory(toUnsigned(addr_sigscan + 0x2),4,2)
	result = m_ReadProcessMemory(toUnsigned(result),4,2)
	local cvar_entry = m_ReadProcessMemory(toUnsigned(result + 0x30),4,2)
	temp("csgo","pid",pid)
	temp("csgo","cvar_entry",toUnsigned(cvar_entry))
	return cvar_entry
end

--[[
class ConVar
{
	public:
    char pad_0x0000[0x4]; //0x0
    ConVar * pNext;		  //0x4
    int32_t bRegistered;  //0x8
    char* pszName;		  //0xC
    char* pszHelpString;  //0x10
    int32_t nFlags;		  //0x14
    char pad_0x0018[0x4]; //0x18
    ConVar* pParent;	  //0x1C
    char* pszDefaultValue;//0x20
    char* strString;	  //0x24
    int32_t StringLength; //0x28
    float fValue;		  //0x2C
    int32_t nValue;
    int32_t bHasMin;
    float fMinVal;
    int32_t bHasMax;
    float fMaxVal;
    void *fnChangeCallback;
}
--]]


function Convar.UnlockAllCVar()
	local cvar_entry = GetCVarInterface()
	while(cvar_entry ~= 0)
	do
		--0x14 = flags
		m_WriteProcessMemory(toUnsigned(cvar_entry + 0x14),0x00000000,4)
		cvar_entry = m_ReadProcessMemory(toUnsigned(cvar_entry + 0x4),4,2)
	end
	print("UnlockAll CVar Done!")
	m_CloseHandle()
end

--[[

Convar可以是省略了部分的字符串
例如 "cl_ragdoll_gravity" 可以用 "cl_ragdoll_g" 来代替
但是注意省略部分字符串之后剩下的字符串长度必须可以被4整除，否则实际寻找Convar速度不会得到提升
如果你不想提升查找Convar速度而仅仅只是想要更短的字符串则可以不用在乎是否能够被4整除

--]]
function Convar.SetConvar(convar,value)
	--cache
	if(checkCachePidMatch() == true and readtemp("cvar_table",convar) == "1") then
		print("found convar address in cache!")
		cvar_entry = readtemp(convar,"address")
		local bIsFloat = tonumber(InputBox("Convar已经找到，但是我们还需要进一步知道一些信息:\n此Convar的值是否为Float(浮点型)？即带小数的整数，如果是请输入1，如果不是请输入0","Convar已找到"))
			if(bIsFloat == 1) then
				m_WriteProcessMemory(toUnsigned(cvar_entry + 0x2C),bit_xor(cvar_entry,value),4)
			else
				m_WriteProcessMemory(toUnsigned(cvar_entry + 0x30),bit_xor(cvar_entry,value),4)
			end
		m_CloseHandle()
		return
	end
	--cache
	local cvar_entry = GetCVarInterface()
	local stringtable = BuildHexTableByString(convar)
	local tablesize = table.getn(stringtable)
	local bFound = false

	while(cvar_entry ~= 0)
	do
		local pName = m_ReadProcessMemory(toUnsigned(cvar_entry + 0xC),4,2)
		local iFoundTimes = 0
		if(string.len(convar) % 4 == 0) then
			for i=1,tablesize do
				local cName = m_ReadProcessMemory(toUnsigned(pName + (i - 1) * 4),4,2)
				if(stringtable[i] == string.format("%X",cName)) then
					iFoundTimes = iFoundTimes + 1
				end
			end
			if(iFoundTimes == tablesize) then
				bFound = true
			end
		else
			for i=1,tablesize do
				local cName = m_ReadProcessMemory(toUnsigned(pName + (i - 1)),1,1)
				if(stringtable[i] == string.format("%X",cName)) then
					iFoundTimes = iFoundTimes + 1	
				end	
			end
			if(iFoundTimes == tablesize) then
				bFound = true	
			end	
		end	
		if(bFound == true) then
			--0x2C = fValue
			--0x30 = nValue
			local bIsFloat = tonumber(InputBox("Convar已经找到，但是我们还需要进一步知道一些信息:此Convar的值是否为Float 浮点型？即带小数的整数，如果是请输入1，如果不是请输入0","Convar已找到"))
			print(string.format("cvar %s found! Address:0x%X setting var to %d",convar,cvar_entry,value))
			if(bIsFloat == 1) then
				m_WriteProcessMemory(toUnsigned(cvar_entry + 0x2C),bit_xor(cvar_entry,value),4)
			else
				m_WriteProcessMemory(toUnsigned(cvar_entry + 0x30),bit_xor(cvar_entry,value),4)
			end
			temp("cvar_table",tostring(convar),tostring(1))
			temp(convar,"address",toUnsigned(cvar_entry))
			break
		end	
		cvar_entry = m_ReadProcessMemory(toUnsigned(cvar_entry + 0x4),4,2)
	end
	if(bFound == false) then
		print(string.format("ConVar:%s not found",convar))
	end
	m_CloseHandle()
end