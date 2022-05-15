local function toUnsigned(address_) -- Library
	return string.format("%u",address_)
end
--[[
CHLClient->GetAllClasses():
B0 01 C3 CC CC CC CC CC CC CC CC CC CC CC CC A1 ? ? ? ? C3 + 0xF

class RecvProp
{
public:
    char*                   m_pVarName;
    SendPropType            m_RecvType;
    int                     m_Flags;
    int                     m_StringBufferSize;
    int                     m_bInsideArray;
    const void*             m_pExtraData;
    RecvProp*               m_pArrayProp;
    ArrayLengthRecvProxyFn  m_ArrayLengthProxy;
    RecvVarProxyFn          m_ProxyFn;
    DataTableRecvVarProxyFn m_DataTableProxyFn;
    RecvTable*              m_pDataTable;
    int                     m_Offset;
    int                     m_ElementStride;
    int                     m_nElements;
    const char*             m_pParentArrayPropName;

    RecvVarProxyFn			GetProxyFn() const;
    void					SetProxyFn(RecvVarProxyFn fn);
    DataTableRecvVarProxyFn	GetDataTableProxyFn() const;
    void					SetDataTableProxyFn(DataTableRecvVarProxyFn fn);

};

class RecvTable
{
public:
    RecvProp*               m_pProps;
    int                     m_nProps;
    void*                   m_pDecoder;
    char*                   m_pNetTableName;
    bool                    m_bInitialized;
    bool                    m_bInMainList;
};

class ClientClass
{
public:
    CreateClientClassFn      m_pCreateFn;
    CreateEventFn            m_pCreateEventFn;
    char*                    m_pNetworkName;
    RecvTable*               m_pRecvTable;
    ClientClass*             m_pNext;
    ClassId                  m_ClassID;
};

struct netvar_table
{
	std::string               name;
	RecvProp*                 prop;
	uint32_t                  offset;
	std::vector<RecvProp*>    child_props;
	std::vector<netvar_table> child_tables;
};

--]]

local function make_recvprop(base)
	local recvprop = {}
	recvprop.m_pVarName = 				m_ReadProcessMemory(toUnsigned(base),4,2)
	recvprop.m_RecvType = 				m_ReadProcessMemory(toUnsigned(base + 0x4),4,2)
	recvprop.m_Flags = 					m_ReadProcessMemory(toUnsigned(base + 0x8),4,2)
	recvprop.m_StringBufferSize = 		m_ReadProcessMemory(toUnsigned(base + 0xC),4,2)
	recvprop.m_bInsideArray = 			m_ReadProcessMemory(toUnsigned(base + 0x10),4,2)
	recvprop.m_pExtraData = 			m_ReadProcessMemory(toUnsigned(base + 0x14),4,2)
	recvprop.m_pArrayProp = 			m_ReadProcessMemory(toUnsigned(base + 0x18),4,2)
	recvprop.m_ArrayLengthProxy = 		m_ReadProcessMemory(toUnsigned(base + 0x1C),4,2)
	recvprop.m_ProxyFn = 				m_ReadProcessMemory(toUnsigned(base + 0x20),4,2)
	recvprop.m_DataTableProxyFn = 		m_ReadProcessMemory(toUnsigned(base + 0x24),4,2)
	recvprop.m_pDataTable = 			m_ReadProcessMemory(toUnsigned(base + 0x28),4,2)
	recvprop.m_Offset = 				m_ReadProcessMemory(toUnsigned(base + 0x2C),4,2)
	recvprop.m_ElementStride = 			m_ReadProcessMemory(toUnsigned(base + 0x30),4,2)
	recvprop.m_nElements = 				m_ReadProcessMemory(toUnsigned(base + 0x34),4,2)
	recvprop.m_pParentArrayPropName = 	m_ReadProcessMemory(toUnsigned(base + 0x38),4,2)
	return recvprop
end

local function make_recvtable(base)
	local recvtable = {}
	recvtable.m_pProps = m_ReadProcessMemory(toUnsigned(base),4,2)
	recvtable.m_nProps = m_ReadProcessMemory(toUnsigned(base + 0x4),4,2)
	recvtable.m_pDecoder = m_ReadProcessMemory(toUnsigned(base + 0x8),4,2)
	recvtable.m_pNetTableName = m_ReadProcessMemory(toUnsigned(base + 0xC),4,2)
	recvtable.m_bInitialized = m_ReadProcessMemory(toUnsigned(base + 0x10),4,2)
	recvtable.m_bInMainList = m_ReadProcessMemory(toUnsigned(base + 0x14),4,2)
	return recvtable
end

local function make_clientclass(base)
	local clientclass = {}
	clientclass.m_pCreateFn = m_ReadProcessMemory(toUnsigned(base),4,2)
	clientclass.m_pCreateEventFn = m_ReadProcessMemory(toUnsigned(base + 0x4),4,2)
	clientclass.m_pNetworkName = m_ReadProcessMemory(toUnsigned(base + 0x8),4,2)
	clientclass.m_pRecvTable = m_ReadProcessMemory(toUnsigned(base + 0xC),4,2)
	clientclass.m_pNext = m_ReadProcessMemory(toUnsigned(base + 0x10),4,2)
	clientclass.m_ClassID = m_ReadProcessMemory(toUnsigned(base + 0x14),4,2)
	return clientclass
end

local function remoteName(paddress)
	local final_string = ""
	local single_char = m_ReadProcessMemory(toUnsigned(paddress),1,1)
	while(single_char ~= 0)
	do
		final_string = final_string .. string.char(single_char)
		paddress = toUnsigned(paddress + 1)
		single_char = m_ReadProcessMemory(toUnsigned(paddress),1,1)
	end
	return final_string
end

local function GetNetvarInterface() 
	local pid = findProcessByName("csgo.exe")
	if(pid < 1) then
		print("CSGO not found")
		return 0
	end
	m_OpenProcess(pid)
	local mod = GetRemoteModule(pid,"client.dll")
	if(mod < 1) then
		print("find module failed")
		return 0
	end
	local addr_sigscan = toUnsigned(mod + 0x256601)--m_PatternScan("client.dll","B0 01 C3 CC CC CC CC CC CC CC CC CC CC CC CC A1 ? ? ? ? C3")
	local result = m_ReadProcessMemory(toUnsigned(addr_sigscan + 0x10),4,2)
	result = m_ReadProcessMemory(toUnsigned(result),4,2)
	local netvar_entry = toUnsigned(result)
	return netvar_entry
end

local function SaveTable(masterName,tableaddr)
	
	local recvtable = make_recvtable(tableaddr)
	local retTable_Name = {}
	local retTable_Offset = {}
	
	local TableName = remoteName(recvtable.m_pNetTableName)
	temp(masterName,"TableName",TableName)
	
	for i=0,recvtable.m_nProps
	do
		repeat
		
			local prop = make_recvprop(toUnsigned(recvtable.m_pProps + i * 0x3C))
			local firstchar = m_ReadProcessMemory(toUnsigned(prop.m_pVarName),1,1)
			if(prop.m_pVarName == 0 or (firstchar > 0x30 and firstchar < 0x39)) then 
				break
			end
			if("baseclass" == remoteName(prop.m_pVarName)) then
				break
			end
			if(prop.m_RecvType == 6 and prop.m_pDataTable ~= 0) then
				
			else
				retTable_Name[i] = remoteName(prop.m_pVarName)
				retTable_Offset[i] = prop.m_Offset
				
				temp(masterName,retTable_Name[i],string.format("0x%X",retTable_Offset[i]))
			end
		until(true)
	end
	
end

local function DumpNetvarToTemp()

	local nvar_entry = GetNetvarInterface()
	while(nvar_entry ~= 0)
	do
		local nvar = make_clientclass(nvar_entry)
		nvar_class_name = remoteName(nvar.m_pNetworkName)
		SaveTable(nvar_class_name,nvar.m_pRecvTable)

		nvar_entry = m_ReadProcessMemory(toUnsigned(nvar_entry + 0x10),4,2)
	end

end

DumpNetvarToTemp()