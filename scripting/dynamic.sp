#include <dynamic>
#include <regex>
#pragma newdecls required
#pragma semicolon 1

static Handle s_Collection = null;
static int s_CollectionSize = 0;
static Handle s_FreeIndicies = null;
static Handle s_tObjectNames = null;
static Handle g_sRegex_Vector = null;
static int g_iDynamic_MemberLookup_Offset;

public Plugin myinfo =
{
	name = "Dynamic",
	author = "Neuro Toxin",
	description = "Shared Dynamic Objects for Sourcepawn",
	version = "0.0.16",
	url = "https://forums.alliedmods.net/showthread.php?t=270519"
}

#define Dynamic_Index						0
// Size isn't yet implement for optimisation around ExpandIfRequired()
#define Dynamic_Size						1
#define Dynamic_Blocksize				2
#define Dynamic_Offsets					3
#define Dynamic_MemberNames				4
#define Dynamic_Data						5
#define Dynamic_Forwards					6
#define Dynamic_NextOffset				7
#define Dynamic_CallbackCount			8
#define Dynamic_ParentObject				9
#define Dynamic_MemberCount				10
#define Dynamic_Field_Count				11

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Register plugin and natives
	RegPluginLibrary("dynamic");
	CreateNative("Dynamic_Initialise", Native_Dynamic_Initialise);
	CreateNative("Dynamic_IsValid", Native_Dynamic_IsValid);
	CreateNative("Dynamic_Dispose", Native_Dynamic_Dispose);
	CreateNative("Dynamic_SetName", Native_Dynamic_SetName);
	CreateNative("Dynamic_FindByName", Native_Dynamic_FindByName);
	CreateNative("Dynamic_GetParent", Native_Dynamic_GetParent);
	CreateNative("Dynamic_ReadConfig", Native_Dynamic_ReadConfig);
	CreateNative("Dynamic_WriteConfig", Native_Dynamic_WriteConfig);
	CreateNative("Dynamic_ReadKeyValues", Native_Dynamic_ReadKeyValues);
	CreateNative("Dynamic_WriteKeyValues", Native_Dynamic_WriteKeyValues);
	CreateNative("Dynamic_GetInt", Native_Dynamic_GetInt);
	CreateNative("Dynamic_SetInt", Native_Dynamic_SetInt);
	CreateNative("Dynamic_GetIntByOffset", Native_Dynamic_GetIntByOffset);
	CreateNative("Dynamic_SetIntByOffset", Native_Dynamic_SetIntByOffset);
	CreateNative("Dynamic_PushInt", Native_Dynamic_PushInt);
	CreateNative("Dynamic_GetIntByIndex", Native_Dynamic_GetIntByIndex);
	CreateNative("Dynamic_GetBool", Native_Dynamic_GetBool);
	CreateNative("Dynamic_SetBool", Native_Dynamic_SetBool);
	CreateNative("Dynamic_GetBoolByOffset", Native_Dynamic_GetBoolByOffset);
	CreateNative("Dynamic_SetBoolByOffset", Native_Dynamic_SetBoolByOffset);
	CreateNative("Dynamic_PushBool", Native_Dynamic_PushBool);
	CreateNative("Dynamic_GetBoolByIndex", Native_Dynamic_GetBoolByIndex);
	CreateNative("Dynamic_GetFloat", Native_Dynamic_GetFloat);
	CreateNative("Dynamic_SetFloat", Native_Dynamic_SetFloat);
	CreateNative("Dynamic_GetFloatByOffset", Native_Dynamic_GetFloatByOffset);
	CreateNative("Dynamic_SetFloatByOffset", Native_Dynamic_SetFloatByOffset);
	CreateNative("Dynamic_PushFloat", Native_Dynamic_PushFloat);
	CreateNative("Dynamic_GetFloatByIndex", Native_Dynamic_GetFloatByIndex);
	CreateNative("Dynamic_GetString", Native_Dynamic_GetString);
	CreateNative("Dynamic_SetString", Native_Dynamic_SetString);
	CreateNative("Dynamic_GetStringByOffset", Native_Dynamic_GetStringByOffset);
	CreateNative("Dynamic_SetStringByOffset", Native_Dynamic_SetStringByOffset);
	CreateNative("Dynamic_PushString", Native_Dynamic_PushString);
	CreateNative("Dynamic_GetStringByIndex", Native_Dynamic_GetStringByIndex);
	CreateNative("Dynamic_GetStringLengthByOffset", Native_Dynamic_GetStringLengthByOffset);
	CreateNative("Dynamic_GetStringLength", Native_Dynamic_GetStringLength);
	CreateNative("Dynamic_GetObject", Native_Dynamic_GetObject);
	CreateNative("Dynamic_SetObject", Native_Dynamic_SetObject);
	CreateNative("Dynamic_GetObjectByOffset", Native_Dynamic_GetObjectByOffset);
	CreateNative("Dynamic_SetObjectByOffset", Native_Dynamic_SetObjectByOffset);
	CreateNative("Dynamic_PushObject", Native_Dynamic_PushObject);
	CreateNative("Dynamic_GetObjectByIndex", Native_Dynamic_GetObjectByIndex);
	CreateNative("Dynamic_SetObjectByIndex", Native_Dynamic_SetObjectByIndex);
	CreateNative("Dynamic_GetHandle", Native_Dynamic_GetHandle);
	CreateNative("Dynamic_SetHandle", Native_Dynamic_SetHandle);
	CreateNative("Dynamic_GetHandleByOffset", Native_Dynamic_GetHandleByOffset);
	CreateNative("Dynamic_SetHandleByOffset", Native_Dynamic_SetHandleByOffset);
	CreateNative("Dynamic_PushHandle", Native_Dynamic_PushHandle);
	CreateNative("Dynamic_GetHandleByIndex", Native_Dynamic_GetHandleByIndex);
	CreateNative("Dynamic_GetVector", Native_Dynamic_GetVector);
	CreateNative("Dynamic_SetVector", Native_Dynamic_SetVector);
	CreateNative("Dynamic_GetVectorByOffset", Native_Dynamic_GetVectorByOffset);
	CreateNative("Dynamic_SetVectorByOffset", Native_Dynamic_SetVectorByOffset);
	CreateNative("Dynamic_PushVector", Native_Dynamic_PushVector);
	CreateNative("Dynamic_GetVectorByIndex", Native_Dynamic_GetVectorByIndex);
	CreateNative("Dynamic_GetCollectionSize", Native_Dynamic_GetCollectionSize);
	CreateNative("Dynamic_GetMemberCount", Native_Dynamic_GetMemberCount);
	CreateNative("Dynamic_HookChanges", Native_Dynamic_HookChanges);
	CreateNative("Dynamic_UnHookChanges", Native_Dynamic_UnHookChanges);
	CreateNative("Dynamic_CallbackCount", Native_Dynamic_CallbackCount);
	CreateNative("Dynamic_GetMemberOffset", Native_Dynamic_GetMemberOffset);
	CreateNative("Dynamic_GetMemberOffsetByIndex", Native_Dynamic_GetMemberOffsetByIndex);
	CreateNative("Dynamic_GetMemberType", Native_Dynamic_GetMemberType);
	CreateNative("Dynamic_GetMemberTypeByOffset", Native_Dynamic_GetMemberTypeByOffset);
	CreateNative("Dynamic_GetMemberNameByIndex", Native_Dynamic_GetMemberNameByIndex);
	CreateNative("Dynamic_GetMemberNameByOffset", Native_Dynamic_GetMemberNameByOffset);
	CreateNative("Dynamic_SortMembers", Native_Dynamic_SortMembers);
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Initialise static plugin data
	s_Collection = CreateArray(Dynamic_Field_Count);
	s_CollectionSize = 0;
	s_FreeIndicies = CreateStack();
	s_tObjectNames = CreateTrie();
	g_iDynamic_MemberLookup_Offset = ByteCountToCells(DYNAMIC_MEMBERNAME_MAXLEN)+1;
	
	// Reserve first object index for global settings
	Dynamic settings = Dynamic();
	
	// Ensure settings is assigned index 0
	if (view_as<int>(settings) != 0)
		SetFailState("Serious error encountered assigning server settings index!");
	
	// Reserve first object indicies for player objects
	for (int client = 1; client < MAXPLAYERS; client++)
	{
		settings = Dynamic();
		
		// This is a check to ensure the index matches the client
		if (view_as<int>(settings) != client)
			SetFailState("Serious error encountered assigning player settings indicies!");
	}
}

public void OnPluginEnd()
{
	// Dispose of all objects in the collection pool
	while (s_CollectionSize > 0)
	{
		Dynamic_Dispose(s_CollectionSize - 1, false);
	}
}

// native Dynamic Dynamic_Initialise(int blocksize=64, int startsize=0);
public int Native_Dynamic_Initialise(Handle plugin, int params)
{
	int blocksize = GetNativeCell(1);
	int startsize = GetNativeCell(2);
	int index = -1;
	
	// Always try to reuse a previously disposed index
	while (PopStackCell(s_FreeIndicies, index))
	{
		if (index < s_CollectionSize)
			break;
			
		index = -1;
	}
	
	if (index == -1)
	{
		// Create a new index
		index = PushArrayCell(s_Collection, -1);
		s_CollectionSize++;
	}	
	
	// Initialise dynamic object
	SetArrayCell(s_Collection, index, index, Dynamic_Index);
	SetArrayCell(s_Collection, index, 0, Dynamic_Size);
	SetArrayCell(s_Collection, index, blocksize, Dynamic_Blocksize);
	SetArrayCell(s_Collection, index, CreateTrie(), Dynamic_Offsets);
	SetArrayCell(s_Collection, index, CreateArray(blocksize, startsize), Dynamic_Data);
	SetArrayCell(s_Collection, index, CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell), Dynamic_Forwards);
	SetArrayCell(s_Collection, index, CreateArray(g_iDynamic_MemberLookup_Offset+1), Dynamic_MemberNames);
	//SetArrayCell(s_Collection, index, CreateArray(), Dynamic_MemberOffsets);
	SetArrayCell(s_Collection, index, 0, Dynamic_NextOffset);
	SetArrayCell(s_Collection, index, 0, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, INVALID_DYNAMIC_OBJECT, Dynamic_ParentObject);
	SetArrayCell(s_Collection, index, 0, Dynamic_MemberCount);
	
	// Return the next index
	return index;
}

// native bool Dynamic_Dispose(int index, bool disposemembers);
public int Native_Dynamic_Dispose(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
		
	// Dispose of child members if disposemembers is set
	if (GetNativeCell(2))
	{
		Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
		int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
		int count = GetMemberCount(index);
		int offset; int position; int disposablemember;
		Dynamic_MemberType membertype;
		
		for (int i = 0; i < count; i++)
		{
			position = 0;
			offset = GetMemberOffsetByIndex(index, i);
			membertype = GetMemberType(data, position, offset, blocksize);
			
			if (membertype == DynamicType_Object)
			{
				disposablemember = GetMemberDataInt(data, position, offset, blocksize);
				if (Dynamic_IsValid(disposablemember))
					Dynamic_Dispose(disposablemember, true);
			}
			else if (membertype == DynamicType_Handle)
			{
				disposablemember = GetMemberDataInt(data, position, offset, blocksize);
				CloseHandle(view_as<Handle>(disposablemember));
			}
		}
	}
	
	// Close dynamic object array handles
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_Offsets));
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_Data));
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_Forwards));
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_MemberNames));
	
	// Remove all indicies from the end of the array which are empty (trimend array)
	if (index + 1 == s_CollectionSize)
	{
		RemoveFromArray(s_Collection, index);
		s_CollectionSize--;
		
		for (int i = index - 1; i >= 0; i--)
		{
			if (GetArrayCell(s_Collection, i, Dynamic_Index) > -1)
				break;
			
			RemoveFromArray(s_Collection, i);
			s_CollectionSize--;
		}
	}
	else
	{
		// Mark the index as diposed and report the free index for reusage
		SetArrayCell(s_Collection, index, -1, Dynamic_Index);
		PushStackCell(s_FreeIndicies, index);
	}
	return 1;
}

// native bool Dynamic_SetName(Dynamic obj, const char[] objectname, bool replace);
public int Native_Dynamic_SetName(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index))
		return 0;
	
	// Set object name to object names trie
	// -> This currently overrides a previous name
	// -> This should throw an error
	int length;
	GetNativeStringLength(2, length);
	char[] objectname = new char[length];
	GetNativeString(2, objectname, length);
	
	return SetTrieValue(s_tObjectNames, objectname, index, GetNativeCell(3));
}

// native Dynamic Dynamic_FindByName(const char[] objectname);
public int Native_Dynamic_FindByName(Handle plugin, int params)
{
	// Get native params
	int length;
	GetNativeStringLength(1, length);
	char[] objectname = new char[length];
	GetNativeString(1, objectname, length);
	
	// Find name in object names trie
	int index;
	if (!GetTrieValue(s_tObjectNames, objectname, index))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	// Check object is still valid
	if (!Dynamic_IsValid(index))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	// Return object index
	return index;
}

// native Dynamic Dynamic_GetParent(Dynamic obj);
public int Native_Dynamic_GetParent(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	return GetArrayCell(s_Collection, index, Dynamic_ParentObject);
}

// native bool Dynamic_ReadConfig(Dynamic obj, const char[] path, bool use_valve_fs = false, bool valuelength=128);
public int Native_Dynamic_ReadConfig(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index))
		return 0;
		
	// Get native params
	int length;
	GetNativeStringLength(2, length);
	char[] path = new char[length];
	GetNativeString(2, path, length+1);
	bool use_valve_fs = GetNativeCell(3);
	int maxlength = GetNativeCell(4);
	
	// Check file exists
	if (!FileExists(path, use_valve_fs))
	{
		ThrowNativeError(0, "Filepath '%s' doesn't exist!", path);
		return 0;
	}
	
	// Open file for reading
	File stream = OpenFile(path, "r", use_valve_fs);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return 0;
	}
		
	// Loop through file in blocks
	char buffer[16];
	bool readingname = true;
	bool readingstring = false;
	bool readingvalue = false;
	int lastchar = 0;
	bool skippingcomment = false;
	ArrayList settingnamearray = CreateArray(1);
	int settingnamelength = 0;
	ArrayList settingvaluearray = CreateArray(1);
	int settingvaluelength = 0;
	while ((length = stream.ReadString(buffer, sizeof(buffer))) > 0)
	{
		for (int i = 0; i < length; i++)
		{
			int byte = buffer[i];
			
			// space and tabspace
			if (byte == 9 || byte == 32)
			{
				// continue if skipping comments
				if (skippingcomment)
					continue;
					
				if (readingname)
				{
					if (readingstring)
					{
						settingvaluearray.Push(byte);
						settingvaluelength++;
					}
					else
					{
						readingname = false;
						readingvalue = true;
					}
				}
				
				else if (readingvalue)
				{
					if (readingstring)
					{
						settingvaluearray.Push(byte);
						settingvaluelength++;
					}
					else
					{
						//if (settingvaluelength > 0)
						//	skippingcomment = true;
					}
				}
			}
			
			// new line
			else if (byte == 10)
			{
				readingname = true;
				readingstring = false;
				readingvalue = false;
				
				if (skippingcomment)
				{
					skippingcomment = false;
					continue;
				}
				
				AddConfigSetting(index, settingnamearray, settingnamelength, settingvaluearray, settingvaluelength, maxlength);
				settingnamelength = 0;
				settingvaluelength = 0;
			}
			
			// quote
			else if (byte == 34)
			{
				readingstring = !readingstring;
				
				if (!readingstring && readingvalue)
				{
					AddConfigSetting(index, settingnamearray, settingnamelength, settingvaluearray, settingvaluelength, maxlength);
					settingnamelength = 0;
					settingvaluelength = 0;
					skippingcomment = true;
				}
			}
			else
			{
				// continue if skipping a comment
				if (skippingcomment)
					continue;
				
				// skip double backslash comments
				if (byte == 92 && lastchar == 92)
				{
					skippingcomment = true;
					settingnamearray.Clear();
					settingnamelength = 0;
					settingvaluelength = 0;
					continue;
				}
				
				lastchar = byte;
				if (readingname)
				{
					settingnamearray.Push(byte);
					settingnamelength++;
				}
				else if (readingvalue)
				{
					settingvaluearray.Push(byte);
					settingvaluelength++;
				}
			}
		}
	}
	
	delete stream;
	delete settingnamearray;
	delete settingvaluearray;
	return 1;
}

stock void AddConfigSetting(int index, ArrayList name, int namelength, ArrayList value, int valuelength, int maxlength)
{
	char[] settingname = new char[namelength];
	GetArrayStackAsString(name, settingname, namelength);
	name.Clear();
	
	char[] settingvalue = new char[valuelength];
	GetArrayStackAsString(value, settingvalue, valuelength);
	value.Clear();
	
	CreateMemberFromString(view_as<Dynamic>(index), settingname, settingvalue, maxlength);
}

stock Dynamic_MemberType CreateMemberFromString(Dynamic obj, const char[] membername, const char[] value, int maxlength)
{
	bool canbeint = true;
	bool canbefloat = true;
	int byte;
	int val;
	
	for (int i = 0; (byte = value[i]) != 0; i++)
	{
		// 48 = `0`, 57 = `9`, 46 = `.`, 45 = `-`
		if (byte < 48 || byte > 57)
		{
			if (byte == 45 && i == 0)
				continue;
			
			canbeint = false;
			
			if (byte != 46)
				canbefloat = false;
		}
		
		if (!canbeint && !canbefloat)
			break;
	}
	
	if (canbeint)
	{
		// Longs need to be stored as strings
		val = StringToInt(value);
		if (val == -1 && StrEqual(value, "-1"))
		{
			obj.SetInt(membername, val);
			return DynamicType_Int;
		}
		else
		{
			obj.SetString(membername, value, maxlength);
			return DynamicType_String;
		}
	}
	else if (canbefloat)
	{
		obj.SetFloat(membername, StringToFloat(value));
		return DynamicType_Float;
	}
	else
	{
		// make regex if required
		if (g_sRegex_Vector == null)
			g_sRegex_Vector = CompileRegex("^\\{ ?+([-+]?[0-9]*\\.?[0-9]+) ?+, ?+([-+]?[0-9]*\\.?[0-9]+) ?+, ?+([-+]?[0-9]*\\.?[0-9]+) ?+\\}$");
		
		// check for vector
		int count = MatchRegex(g_sRegex_Vector, value);
		if (count == 4)
		{
			float vec[3];
			char matchbuffer[64];
			
			GetRegexSubString(g_sRegex_Vector, 1, matchbuffer, sizeof(matchbuffer));
			vec[0] = StringToFloat(matchbuffer);
			
			GetRegexSubString(g_sRegex_Vector, 2, matchbuffer, sizeof(matchbuffer));
			vec[1] = StringToFloat(matchbuffer);
			
			GetRegexSubString(g_sRegex_Vector, 3, matchbuffer, sizeof(matchbuffer));
			vec[2] = StringToFloat(matchbuffer);
			
			obj.SetVector(membername, vec);
			return DynamicType_Vector;
		}
		
		// check for bool last
		if (StrEqual(value, "true", false))
		{
			obj.SetBool(membername, true);
			return DynamicType_Bool;
		}
		else if (StrEqual(value, "false", false))
		{
			obj.SetBool(membername, false);
			return DynamicType_Bool;
		}
		
		obj.SetString(membername, value, maxlength);
		return DynamicType_String;
	}	
}

stock void GetArrayStackAsString(ArrayList stack, char[] buffer, int length)
{
	for (int i = 0; i < length; i++)
	{
		buffer[i] = view_as<int>(stack.Get(i));
	}
}

// native bool Dynamic_Config(Dynamic obj, const char[] path, bool use_valve_fs = false);
public int Native_Dynamic_WriteConfig(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index))
		return 0;
		
	// Get native params
	int length;
	GetNativeStringLength(2, length);
	char[] path = new char[length];
	GetNativeString(2, path, length+1);

	// Open file for writting
	File stream = OpenFile(path, "w", false);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return 0;
	}
	
	int count = GetMemberCount(index);
	int memberoffset;
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	for (int i = 0; i < count; i++)
	{
		memberoffset = GetMemberOffsetByIndex(index, i);
		GetMemberNameByIndex(index, i, membername, sizeof(membername));
		length = GetStringLengthByOffset(index, memberoffset);
		char[] membervalue = new char[length];
		Dynamic_GetStringByOffset(view_as<Dynamic>(index), memberoffset, membervalue, length);
		stream.WriteLine("%s\t\"%s\"", membername, membervalue);
	}
	
	delete stream;
	return 1;
}

// native bool Dynamic_ReadKeyValues(Dynamic obj, const char[] path, bool use_valve_fs = false, bool valuelength=128);
public int Native_Dynamic_ReadKeyValues(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index))
		return 0;
		
	// Get native params
	int length;
	GetNativeStringLength(2, length);
	char[] path = new char[length];
	GetNativeString(2, path, length+1);
	bool use_valve_fs = GetNativeCell(3);
	int maxlength = GetNativeCell(4);
	
	// Check file exists
	if (!FileExists(path, use_valve_fs))
	{
		ThrowNativeError(0, "Filepath '%s' doesn't exist!", path);
		return 0;
	}
	
	// Open file for reading
	File stream = OpenFile(path, "r", use_valve_fs);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return 0;
	}
	
	// Loop through file in blocks
	char buffer[2048];
	bool readingname = true;
	bool readingstring = false;
	bool readingvalue = false;
	int lastchar = 0;
	bool skippingcomment = false;
	ArrayList settingnamearray = CreateArray(1);
	int settingnamelength = 0;
	ArrayList settingvaluearray = CreateArray(1);
	int settingvaluelength = 0;
	
	Dynamic child;
	Dynamic parent = INVALID_DYNAMIC_OBJECT;
	
	bool waitingbrace = false;
	
	while ((length = stream.ReadString(buffer, sizeof(buffer))) > 0)
	{
		for (int i = 0; i < length; i++)
		{
			int byte = buffer[i];
			
			// open brace
			if (byte == 123)
			{
				// continue if skipping comments
				if (skippingcomment)
					continue;
			
				if (readingstring)
				{
					if (readingvalue)
					{
						settingvaluearray.Push(byte);
						settingvaluelength++;
						waitingbrace = false;
					}
					else if (readingname)
					{
						settingnamearray.Push(byte);
						settingnamelength++;
						waitingbrace = false;
					}
				}
				
				else if (readingvalue && settingvaluelength > 0)
				{
					settingvaluearray.Push(byte);
					settingvaluelength++;
					waitingbrace = false;
				}
				
				else if (readingname || waitingbrace)
				{					
					char[] childname = new char[settingnamelength];
					GetArrayStackAsString(settingnamearray, childname, settingnamelength);
					
					if (parent == INVALID_DYNAMIC_OBJECT)
					{
						parent = view_as<Dynamic>(index);
					}
					else
					{
						if (childname[0] == '\0')
						{
							child = Dynamic();
							parent.PushObject(child);
							parent = child;
						}
						else
						{
							child = parent.GetObject(childname);
							if (child == INVALID_DYNAMIC_OBJECT)
							{
								child = Dynamic();
								parent.SetObject(childname, child);
							}
							parent = child;
						}
					}
					
					readingname = true;
					waitingbrace = false;
					readingstring = false;
					readingvalue = false;
					skippingcomment = false;
					settingnamelength = 0;
					settingvaluelength = 0;
					settingnamearray.Clear();
					settingvaluearray.Clear();
				}
			}
			
			// close brace
			else if (byte == 125)
			{
				if (readingstring)
				{
					if (readingvalue)
					{
						settingvaluearray.Push(byte);
						settingvaluelength++;
						waitingbrace = false;
					}
					else if (readingname)
					{
						settingnamearray.Push(byte);
						settingnamelength++;
						waitingbrace = false;
					}
				}
				
				else if (readingvalue)
				{
					settingvaluearray.Push(byte);
					settingvaluelength++;
					waitingbrace = false;
				}
				
				else
				{
					parent = parent.Parent;
					skippingcomment = true;
				}
			}
			
			// space and tabspace
			else if (byte == 9 || byte == 32)
			{
				// continue if skipping comments
				if (skippingcomment)
					continue;
					
				if (readingname)
				{
					if (readingstring)
					{
						settingnamearray.Push(byte);
						settingnamelength++;
						waitingbrace = false;
					}
					else
					{
						if (settingnamelength > 0)
						{
							readingname = false;
							readingvalue = true;
							waitingbrace = true;
						}
					}
				}
				
				else if (readingvalue)
				{
					if (readingstring)
					{
						settingvaluearray.Push(byte);
						settingvaluelength++;
						waitingbrace = false;
					}
					else
					{
						if (settingvaluelength > 0)
							skippingcomment = true;
					}
				}
			}
			
			// new line
			else if (byte == 10)
			{
				if (readingname)
				{
					if (settingnamelength > 0)
					{
						readingname = false;
						readingvalue = false;
						waitingbrace = true;
						continue;
					}
				}
				
				readingname = true;
				waitingbrace = false;
				readingstring = false;
				readingvalue = false;
				
				if (skippingcomment && settingvaluelength == 0)
				{
					skippingcomment = false;
					settingnamelength = 0;
					settingvaluelength = 0;
					settingnamearray.Clear();
					settingvaluearray.Clear();
					continue;
				}
				
				if (settingvaluelength > 0)
				{
					AddConfigSetting(view_as<int>(parent), settingnamearray, settingnamelength, settingvaluearray, settingvaluelength, maxlength);
					settingnamelength = 0;
					settingvaluelength = 0;
				}
			}
			
			// quote
			else if (byte == 34)
			{
				readingstring = !readingstring;
				
				if (!readingstring && readingvalue)
				{
					AddConfigSetting(view_as<int>(parent), settingnamearray, settingnamelength, settingvaluearray, settingvaluelength, maxlength);
					settingnamelength = 0;
					settingvaluelength = 0;
					skippingcomment = true;
				}
			}
			else
			{
				// continue if skipping a comment
				if (skippingcomment)
					continue;
				
				// skip double backslash comments
				if (byte == 92 && lastchar == 92)
				{
					skippingcomment = true;
					settingnamearray.Clear();
					settingnamelength = 0;
					settingvaluelength = 0;
					continue;
				}
				
				lastchar = byte;
				if (readingname)
				{
					char somestring[2];
					somestring[0] = byte;
					somestring[1] = 0;
					
					settingnamearray.Push(byte);
					settingnamelength++;
				}
				else if (readingvalue)
				{
					char somestring[2];
					somestring[0] = byte;
					somestring[1] = 0;
					
					settingvaluearray.Push(byte);
					settingvaluelength++;
					waitingbrace = false;					
				}
			}
		}
	}
	
	delete stream;
	delete settingnamearray;
	delete settingvaluearray;
	return 1;
}

// native bool Dynamic_WriteKeyValues(Dynamic obj, const char[] path, bool use_valve_fs = false);
public int Native_Dynamic_WriteKeyValues(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index))
		return 0;
		
	// Get native params
	int length;
	GetNativeStringLength(2, length);
	char[] path = new char[length];
	GetNativeString(2, path, length+1);

	// Open file for writting
	File stream = OpenFile(path, "w", false);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return 0;
	}
	
	stream.WriteLine("{");
	WriteObjectToKeyValues(stream, view_as<Dynamic>(index), 1);
	stream.WriteLine("}");
	
	delete stream;
	return 1;
}

stock void WriteObjectToKeyValues(File stream, Dynamic obj, int indent)
{
	// Create indent
	char indextext[16];
	for (int i = 0; i < indent; i++)
		indextext[i] = 9;
	indextext[indent] = 0;
	int length = 1024;

	int count = GetMemberCount(view_as<int>(obj));
	int memberoffset;
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	for (int i = 0; i < count; i++)
	{
		memberoffset = GetMemberOffsetByIndex(view_as<int>(obj), i);
		GetMemberNameByIndex(view_as<int>(obj), i, membername, sizeof(membername));
		Dynamic_MemberType type = Dynamic_GetMemberTypeByOffset(obj, memberoffset);
		
		if (type == DynamicType_Object)
		{
			stream.WriteLine("%s\"%s\"", indextext, membername);
			stream.WriteLine("%s{", indextext);
			WriteObjectToKeyValues(stream, obj.GetObjectByOffset(memberoffset), indent+1);
			stream.WriteLine("%s}", indextext);
		}
		else
		{
			//length = GetStringLengthByOffset(view_as<int>(obj), memberoffset);
			char[] membervalue = new char[length];
			Dynamic_GetStringByOffset(obj, memberoffset, membervalue, length);
			stream.WriteLine("%s\"%s\"\t\"%s\"", indextext, membername, membervalue);
		}
	}
}

// native bool Dynamic_IsValid(int index, bool throwerror=false);
public int Native_Dynamic_IsValid(Handle plugin, int params)
{
	// Get native params
	int index = GetNativeCell(1);
	bool throwerror = GetNativeCell(2);
	
	// Check if object index is valid
	if (index < 0 || index >= s_CollectionSize)
	{
		if (throwerror)
			ThrowNativeError(SP_ERROR_NATIVE, "Unable to access dynamic handle %d", index);
		return 0;
	}
		
	if (GetArrayCell(s_Collection, index, Dynamic_Index) == -1)
	{
		if (throwerror)
			ThrowNativeError(SP_ERROR_NATIVE, "Tried to access disposed dynamic handle %d", index);
		return 0;
	}
	
	return 1;
}

stock bool GetMemberOffset(Handle array, int index, const char[] membername, bool create, int &position, int &offset, int blocksize, Dynamic_MemberType newtype, int stringlength=0)
{
	position = 0;
	offset = 0;
	Handle offsets = GetArrayCell(s_Collection, index, Dynamic_Offsets);
	
	// Find and return member offset
	if (GetTrieValue(offsets, membername, offset))
	{
		RecalculateOffset(array, position, offset, blocksize);
		return true;
	}
	
	// Return false if offset was not found and we dont need to create a new member
	if (!create)
		return false;
	
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	int memberindex;
	
	// Increment member count
	SetArrayCell(s_Collection, index, GetMemberCount(index)+1, Dynamic_MemberCount);
	
	// Create new entry
	if (newtype == DynamicType_String)
	{
		if (stringlength == 0)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "You must set a strings length when you initialise it");
			return false;
		}
		
		offset = GetArrayCell(s_Collection, index, Dynamic_NextOffset);
		SetTrieValue(offsets, membername, offset);
		memberindex = PushArrayString(membernames, membername);
		SetArrayCell(membernames, memberindex, offset, g_iDynamic_MemberLookup_Offset);
		
		ExpandIfRequired(array, position, offset, blocksize, ByteCountToCells(stringlength));
		SetMemberType(array, position, offset, blocksize, newtype);
		SetMemberStringLength(array, position, offset, blocksize, stringlength);
		SetArrayCell(s_Collection, index, offset + 3 + ByteCountToCells(stringlength), Dynamic_NextOffset);
		return true;
	}
	else if (newtype == DynamicType_Vector)
	{
		offset = GetArrayCell(s_Collection, index, Dynamic_NextOffset);
		SetTrieValue(offsets, membername, offset);
		memberindex = PushArrayString(membernames, membername);
		SetArrayCell(membernames, memberindex, offset, g_iDynamic_MemberLookup_Offset);
		
		ExpandIfRequired(array, position, offset, blocksize, 3);
		SetMemberType(array, position, offset, blocksize, newtype);
		SetArrayCell(s_Collection, index, offset + 4, Dynamic_NextOffset);
		return true;
	}
	else
	{
		offset = GetArrayCell(s_Collection, index, Dynamic_NextOffset);
		SetTrieValue(offsets, membername, offset);
		memberindex = PushArrayString(membernames, membername);
		SetArrayCell(membernames, memberindex, offset, g_iDynamic_MemberLookup_Offset);
		
		ExpandIfRequired(array, position, offset, blocksize, 1);
		SetMemberType(array, position, offset, blocksize, newtype);
		SetArrayCell(s_Collection, index, offset + 2, Dynamic_NextOffset);
		return true;
	}
}

stock int CreateMemberOffset(Handle array, int index, int &position, int &offset, int blocksize, Dynamic_MemberType type, int stringlength=0)
{
	int memberindex;
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	
	// Increment member count
	SetArrayCell(s_Collection, index, GetMemberCount(index)+1, Dynamic_MemberCount);
	
	if (type == DynamicType_String)
	{
		if (stringlength == 0)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "You must set a strings length when you initialise it");
			return false;
		}
		
		offset = GetArrayCell(s_Collection, index, Dynamic_NextOffset);
		memberindex = PushArrayString(membernames, "");
		SetArrayCell(membernames, memberindex, offset, g_iDynamic_MemberLookup_Offset);
		
		ExpandIfRequired(array, position, offset, blocksize, ByteCountToCells(stringlength));
		SetMemberType(array, position, offset, blocksize, type);
		SetMemberStringLength(array, position, offset, blocksize, stringlength);
		SetArrayCell(s_Collection, index, offset + 3 + ByteCountToCells(stringlength), Dynamic_NextOffset);
		return memberindex;
	}
	else if (type == DynamicType_Vector)
	{
		offset = GetArrayCell(s_Collection, index, Dynamic_NextOffset);
		memberindex = PushArrayString(membernames, "");
		SetArrayCell(membernames, memberindex, offset, g_iDynamic_MemberLookup_Offset);
		
		ExpandIfRequired(array, position, offset, blocksize, 3);
		SetMemberType(array, position, offset, blocksize, type);
		SetArrayCell(s_Collection, index, offset + 4, Dynamic_NextOffset);
		return memberindex;
	}
	else
	{
		offset = GetArrayCell(s_Collection, index, Dynamic_NextOffset);
		memberindex = PushArrayString(membernames, "");
		SetArrayCell(membernames, memberindex, offset, g_iDynamic_MemberLookup_Offset);
		
		ExpandIfRequired(array, position, offset, blocksize, 1);
		SetMemberType(array, position, offset, blocksize, type);
		SetArrayCell(s_Collection, index, offset + 2, Dynamic_NextOffset);
		return memberindex;
	}
}

stock bool RecalculateOffset(Handle array, int &position, int &offset, int blocksize, bool expand=false, bool aschar=false)
{
	// Calculate offset into internal array index and cell position
	if (aschar)
		blocksize *= 4;
		
	while (offset < 0)
	{
		offset+=blocksize;
		position--;
	}
	while (offset >= blocksize)
	{
		offset-=blocksize;
		position++;
	}
	
	if (expand)
	{
		// Expand array if offset is outside of array bounds
		// Performance: Get array size should be replaced with an size counter
		// The above needs a really good think!!
		int size = GetArraySize(array);
		while (size <= position)
		{
			// -1 is the default value of unused memory to allow parenting via Set/PushObject
			int val = PushArrayCell(array, INVALID_DYNAMIC_OBJECT);
			size++;
			
			// This was added to ensure all memory is set to -1 for a parent resetting
			// -> this might impact performance and potentially cause parent resetting be redone
			for (int block = 1; block < blocksize; block++)
			{
				SetArrayCell(array, val, INVALID_DYNAMIC_OBJECT, block);
			}
		}
	}
	return true;
}

stock bool ValidateOffset(Handle array, int &position, int &offset, int blocksize, bool aschar=false)
{
	// This has become redundant and is no longer required
	// -> Some internal methods still use this and need to be switched to RecalculateOffset
	if (aschar)
		blocksize *= 4;
		
	while (offset < 0)
	{
		offset+=blocksize;
		position--;
	}
	while (offset >= blocksize)
	{
		offset-=blocksize;
		position++;
	}
	
	// This safeguard was removed as it was reducing performance
	// Invalid offset positions will now cause array index errors
	/*int size = GetArraySize(array);
	if (size <= position)
		return false;*/
	
	return true;
}

stock void ExpandIfRequired(Handle array, int position, int offset, int blocksize, int length=1)
{
	// Used to expand internal object arrays by the GetMemberOffset method
	offset += length + 1;
	RecalculateOffset(array, position, offset, blocksize, true);
}

stock Dynamic_MemberType GetMemberType(Handle array, int position, int offset, int blocksize)
{
	// Calculate internal data array index and cell position
	RecalculateOffset(array, position, offset, blocksize);
	
	// Get and return type
	int type = GetArrayCell(array, position, offset);
	return view_as<Dynamic_MemberType>(type);
}

stock void SetMemberType(Handle array, int position, int offset, int blocksize, Dynamic_MemberType type)
{
	// Calculate internal data array index and cell position
	RecalculateOffset(array, position, offset, blocksize);
	
	// Set member type
	SetArrayCell(array, position, type, offset);
}

stock int GetMemberStringLength(Handle array, int position, int offset, int blocksize)
{
	// Move the offset forward by one cell as this is where a strings length is stored
	offset++;
	
	// Calculate internal data array index and cell position
	RecalculateOffset(array, position, offset, blocksize);
	
	// Return string length
	return GetArrayCell(array, position, offset);
}

stock void SetMemberStringLength(Handle array, int position, int offset, int blocksize, int length)
{
	offset++;
	RecalculateOffset(array, position, offset, blocksize);
	SetArrayCell(array, position, length, offset);
}

stock int GetMemberDataInt(Handle array, int position, int offset, int blocksize)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	RecalculateOffset(array, position, offset, blocksize);
	
	// Return value
	return GetArrayCell(array, position, offset);
}

stock void SetMemberDataInt(Handle array, int position, int offset, int blocksize, int value)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	RecalculateOffset(array, position, offset, blocksize);
	
	// Set the value
	SetArrayCell(array, position, value, offset);
}

stock float GetMemberDataFloat(Handle array, int position, int offset, int blocksize)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	RecalculateOffset(array, position, offset, blocksize);
	
	// Return value
	return GetArrayCell(array, position, offset);
}

stock void SetMemberDataFloat(Handle array, int position, int offset, int blocksize, float value)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	RecalculateOffset(array, position, offset, blocksize);
	
	// Set the value
	SetArrayCell(array, position, value, offset);
}

stock bool GetMemberDataVector(Handle array, int position, int offset, int blocksize, float vector[3])
{
	// A vector has 3 cells of data to be retrieved
	for (int i=0; i<3; i++)
	{
		// Move the offset forward by one cell as this is where the value is stored
		offset++;
		
		// Calculate internal data array index and cell position
		RecalculateOffset(array, position, offset, blocksize);
		
		// Get the value
		vector[i] = GetArrayCell(array, position, offset);
	}
	return true;
}

stock void SetMemberDataVector(Handle array, int position, int offset, int blocksize, float value[3])
{
	// A vector has 3 cells of data to be stored
	for (int i=0; i<3; i++)
	{
		// Move the offset forward by one cell as this is where the value is stored
		offset++;
		
		// Calculate internal data array index and cell position
		RecalculateOffset(array, position, offset, blocksize);
		
		// Set the value
		SetArrayCell(array, position, value[i], offset);
	}
}

stock void GetMemberDataString(Handle array, int position, int offset, int blocksize, char[] buffer, int length)
{
	// Move the offset forward by two cells as this is where the string data starts
	offset+=2;
	RecalculateOffset(array, position, offset, blocksize, true);
	
	// Offsets for Strings must by multiplied by 4
	offset*=4;
	
	// Get string data cell by cell and recalculate offset incase the string data wraps onto a new array index
	int i; char letter;
	for (i=0; i < length; i++)
	{
		letter = view_as<char>(GetArrayCell(array, position, offset, true));
		buffer[i] = letter;
		
		// If the null terminator exists we are done
		if (letter == 0)
			return;
			
		offset++;
		RecalculateOffset(array, position, offset, blocksize, false, true);
	}
	
	// Add null terminator to end of string
	buffer[i-1] = '0';
}

stock void SetMemberDataString(Handle array, int position, int offset, int blocksize, const char[] buffer)
{
	int length = GetMemberStringLength(array, position, offset, blocksize);
	
	// Move the offset forward by two cells as this is where the string data starts
	offset+=2;
	RecalculateOffset(array, position, offset, blocksize);
	
	// Offsets for Strings must by multiplied by 4
	offset*=4;
	
	// Set string data cell by cell and recalculate offset incase the string data wraps onto a new array index
	int i;
	char letter;
	for (i=0; i < length; i++)
	{
		letter = buffer[i];
		SetArrayCell(array, position, letter, offset, true);
		
		// If the null terminator exists we are done
		if (letter == 0)
			return;
			
		offset++;
		RecalculateOffset(array, position, offset, blocksize, false, true);
	}
	
	// Move back one offset once string is written to internal data array
	offset--;
	RecalculateOffset(array, position, offset, blocksize, false, true);
	
	// Set null terminator
	SetArrayCell(array, position, 0, offset, true);
}

stock int GetMemberCount(int index)
{
	// A simple way to ge the member count
	// -> If performance is faster to store a count for the object this will be updated
	return GetArrayCell(s_Collection, index, Dynamic_MemberCount);
}

// native int Dynamic_GetInt(Dynamic obj, const char[] membername, int defaultvalue=-1);
public int Native_Dynamic_GetInt(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return GetNativeCell(3);
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Int))
		return GetNativeCell(3);
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Int || type == DynamicType_Bool)
		return GetMemberDataInt(array, position, offset, blocksize);
	else if (type == DynamicType_Float)
		return RoundToFloor(GetMemberDataFloat(array, position, offset, blocksize));
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(array, position, offset, blocksize, buffer, length);
		return StringToInt(buffer);
	}
	else if (type == DynamicType_Object)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return GetNativeCell(3);
	}
}

// native int Dynamic_SetInt(Dynamic obj, const char[] membername, int value);
public int Native_Dynamic_SetInt(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, true, position, offset, blocksize, DynamicType_Int))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	
	
	if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForward(index, offset, membername, DynamicType_Int);
		return offset;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, float(GetNativeCell(3)));
		CallOnChangedForward(index, offset, membername, DynamicType_Float);
		return offset;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return 1;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		IntToString(GetNativeCell(3), buffer, length);
		SetMemberDataString(array, position, offset, blocksize, buffer);
		CallOnChangedForward(index, offset, membername, DynamicType_String);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

// native int Dynamic_GetIntByOffset(Dynamic obj, int offset, int defaultvalue=-1);
public int Native_Dynamic_GetIntByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return GetNativeCell(3);
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return GetNativeCell(3);
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Int || type == DynamicType_Bool)
		return GetMemberDataInt(array, position, offset, blocksize);
	else if (type == DynamicType_Float)
		return RoundToFloor(GetMemberDataFloat(array, position, offset, blocksize));
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(array, position, offset, blocksize, buffer, length);
		return StringToInt(buffer);
	}
	else if (type == DynamicType_Object)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return GetNativeCell(3);
	}
}

// native bool Dynamic_SetIntByOffset(Dynamic obj, int offset, int value);
public int Native_Dynamic_SetIntByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int offset = GetNativeCell(2);
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	
	if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Int);
		return 1;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, float(GetNativeCell(3)));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Float);
		return 1;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return 1;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		IntToString(GetNativeCell(3), buffer, length);
		SetMemberDataString(array, position, offset, blocksize, buffer);
		CallOnChangedForwardByOffset(index, offset, DynamicType_String);
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native int Dynamic_PushInt(Dynamic obj, int value);
public int Native_Dynamic_PushInt(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Int);
	SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(2));
	//CallOnChangedForward(index, offset, membername, DynamicType_Int);
	return memberindex;
}

// native int Dynamic_GetIntByIndex(Dynamic obj, int index, int defaultvalue=-1);
public int Native_Dynamic_GetIntByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	int memberindex = GetNativeCell(2);
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return GetNativeCell(3);
	
	return Dynamic_GetIntByOffset(view_as<Dynamic>(index), offset, GetNativeCell(3));
}

// native float Dynamic_GetFloat(Dynamic obj, const char[] membername, float defaultvalue=-1.0);
public int Native_Dynamic_GetFloat(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return GetNativeCell(3);
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Float))
		return GetNativeCell(3);
		
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
		return view_as<int>(GetMemberDataFloat(data, position, offset, blocksize));
	else if (type == DynamicType_Int || type == DynamicType_Bool)
		return view_as<int>(float(GetMemberDataInt(data, position, offset, blocksize)));
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(data, position, offset, blocksize, buffer, length);
		return view_as<int>(StringToFloat(buffer));
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return GetNativeCell(3);
	}
}

// native int Dynamic_SetFloat(Dynamic obj, const char[] membername, float value);
public int Native_Dynamic_SetFloat(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Float))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
	{
		SetMemberDataFloat(data, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForward(index, offset, membername, DynamicType_Float);
		return offset;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(data, position, offset, blocksize, RoundToFloor(GetNativeCell(3)));
		CallOnChangedForward(index, offset, membername, DynamicType_Int);
		return offset;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(data, position, offset, blocksize, RoundToFloor(GetNativeCell(3)));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return 1;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		FloatToString(GetNativeCell(3), buffer, length);
		SetMemberDataString(data, position, offset, blocksize, buffer);
		CallOnChangedForward(index, offset, membername, DynamicType_String);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

// native float Dynamic_GetFloatByOffset(Dynamic obj, int offset, float defaultvalue=-1.0);
public int Native_Dynamic_GetFloatByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return GetNativeCell(3);
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return GetNativeCell(3);
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Float)
		return view_as<int>(GetMemberDataFloat(array, position, offset, blocksize));
	else if (type == DynamicType_Int || type == DynamicType_Bool)
		return view_as<int>(float(GetMemberDataInt(array, position, offset, blocksize)));
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(array, position, offset, blocksize, buffer, length);
		return view_as<int>(StringToFloat(buffer));
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return GetNativeCell(3);
	}
}

// native bool Dynamic_SetFloatByOffset(Dynamic obj, int offset, float value);
public int Native_Dynamic_SetFloatByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;

	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return GetNativeCell(3);
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Float);
		return 1;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, RoundToFloor(GetNativeCell(3)));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Int);
		return 1;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, RoundToFloor(GetNativeCell(3)));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return 1;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		FloatToString(GetNativeCell(3), buffer, length);
		SetMemberDataString(array, position, offset, blocksize, buffer);
		CallOnChangedForwardByOffset(index, offset, DynamicType_String);
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native int Dynamic_PushFloat(Dynamic obj, float value);
public int Native_Dynamic_PushFloat(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(data, index, position, offset, blocksize, DynamicType_Float);
	SetMemberDataFloat(data, position, offset, blocksize, GetNativeCell(2));
	//CallOnChangedForward(index, offset, membername, DynamicType_Float);
	return memberindex;
}


// native float Dynamic_GetFloatByIndex(Dynamic obj, int index, float defaultvalue=-1.0);
public int Native_Dynamic_GetFloatByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	int memberindex = GetNativeCell(2);
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return GetNativeCell(3);
	
	return view_as<int>(Dynamic_GetFloatByOffset(view_as<Dynamic>(index), offset, GetNativeCell(3)));
}

// native bool Dynamic_GetString(Dynamic obj, const char[] membername, char[] buffer, int size);
public int Native_Dynamic_GetString(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
	{
		SetNativeString(3, "", 1);
		return 0;
	}
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_String))
	{
		SetNativeString(3, "", 1);
		return 0;
	}
		
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		char[] buffer = new char[GetNativeCell(4)];
		GetMemberDataString(data, position, offset, blocksize, buffer, GetNativeCell(4));
		SetNativeString(3, buffer, GetNativeCell(4));
		return 1;
	}
	else if (type == DynamicType_Int)
	{
		int value = GetMemberDataInt(data, position, offset, blocksize);
		int length = GetNativeCell(4);
		char[] buffer = new char[length];
		IntToString(value, buffer, length);
		SetNativeString(3, buffer, length);
		return 1;
	}
	else if (type == DynamicType_Float)
	{
		float value = GetMemberDataFloat(data, position, offset, blocksize);
		int length = GetNativeCell(4);
		char[] buffer = new char[length];
		FloatToString(value, buffer, length);
		SetNativeString(3, buffer, length);
		return 1;
	}
	else if (type == DynamicType_Bool)
	{
		if (GetMemberDataInt(data, position, offset, blocksize))
			SetNativeString(3, "True", 5);
		else
			SetNativeString(3, "False", 6);
		return 1;
	}
	else if (type == DynamicType_Vector)
	{
		float vector[3];
		GetMemberDataVector(data, position, offset, blocksize, vector);
		Format(membername, sizeof(membername), "{%f, %f, %f}", vector[0], vector[1], vector[2]);
		SetNativeString(3, membername, sizeof(membername));
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		SetNativeString(3, "", 1);
		return 0;
	}
}

// native int Dynamic_SetString(Dynamic obj, const char[] membername, const char[] value, int length=0);
public int Native_Dynamic_SetString(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int length = GetNativeCell(4);
	if (length == 0)
	{
		GetNativeStringLength(3, length);
		length++;
	}
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_String, length))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		length++;
		char[] buffer = new char[length+1];
		GetNativeString(3, buffer, length);
		SetMemberDataString(data, position, offset, blocksize, buffer);
		CallOnChangedForward(index, offset, membername, DynamicType_String);
		return offset;
	}
	else if (type == DynamicType_Int)
	{
		GetNativeStringLength(3, length);
		length++;
		char[] buffer = new char[length];
		GetNativeString(3, buffer, length);
		SetMemberDataInt(data, position, offset, blocksize, StringToInt(buffer));
		CallOnChangedForward(index, offset, membername, DynamicType_Int);
		return offset;
	}
	else if (type == DynamicType_Float)
	{
		GetNativeStringLength(3, length);
		length++;
		char[] buffer = new char[length];
		GetNativeString(3, buffer, length);
		SetMemberDataFloat(data, position, offset, blocksize, StringToFloat(buffer));
		CallOnChangedForward(index, offset, membername, DynamicType_Float);
		return offset;
	}
	else if (type == DynamicType_Bool)
	{
		char[] buffer = new char[length];
		GetNativeString(3, buffer, length);
		
		if (StrEqual(buffer, "True"))
			SetMemberDataInt(data, position, offset, blocksize, true);
		else if (StrEqual(buffer, "1"))
			SetMemberDataInt(data, position, offset, blocksize, true);
		
		SetMemberDataInt(data, position, offset, blocksize, false);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

// native int Dynamic_GetStringByOffset(Dynamic obj, int offset, char[] buffer, int size);
public int Native_Dynamic_GetStringByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
	{
		SetNativeString(3, "", 1);
		return 0;
	}
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
	{
		SetNativeString(3, "", 1);
		return 0;
	}
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		char[] buffer = new char[GetNativeCell(4)];
		GetMemberDataString(array, position, offset, blocksize, buffer, GetNativeCell(4));
		SetNativeString(3, buffer, GetNativeCell(4));
		return 1;
	}
	else if (type == DynamicType_Int)
	{
		int value = GetMemberDataInt(array, position, offset, blocksize);
		int length = GetNativeCell(4);
		char[] buffer = new char[length];
		IntToString(value, buffer, length);
		SetNativeString(3, buffer, length);
		return 1;
	}
	else if (type == DynamicType_Float)
	{
		float value = GetMemberDataFloat(array, position, offset, blocksize);
		int length = GetNativeCell(4);
		char[] buffer = new char[length];
		FloatToString(value, buffer, length);
		SetNativeString(3, buffer, length);
		return 1;
	}
	else if (type == DynamicType_Bool)
	{
		if (GetMemberDataInt(array, position, offset, blocksize))
			SetNativeString(3, "True", 5);
		else
			SetNativeString(3, "False", 6);
		return 1;
	}
	else if (type == DynamicType_Vector)
	{
		float vector[3];
		char buffer[DYNAMIC_MEMBERNAME_MAXLEN];
		GetMemberDataVector(array, position, offset, blocksize, vector);
		Format(buffer, sizeof(buffer), "{%f, %f, %f}", vector[0], vector[1], vector[2]);
		SetNativeString(3, buffer, sizeof(buffer));
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		SetNativeString(3, "", 1);
		return 0;
	}
}

// native bool Dynamic_SetStringByOffset(Dynamic obj, int offset, const char[] value, int length=0);
public int Native_Dynamic_SetStringByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int length = GetNativeCell(4);
	if (length == 0)
	{
		GetNativeStringLength(3, length);
		length++;
	}
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		length++;
		char[] buffer = new char[length+1];
		GetNativeString(3, buffer, length);
		SetMemberDataString(array, position, offset, blocksize, buffer);
		CallOnChangedForwardByOffset(index, offset, DynamicType_String);
		return 1;
	}
	else if (type == DynamicType_Int)
	{
		GetNativeStringLength(3, length);
		length++;
		char[] buffer = new char[length];
		GetNativeString(3, buffer, length);
		SetMemberDataInt(array, position, offset, blocksize, StringToInt(buffer));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Int);
		return 1;
	}
	else if (type == DynamicType_Float)
	{
		GetNativeStringLength(3, length);
		length++;
		char[] buffer = new char[length];
		GetNativeString(3, buffer, length);
		SetMemberDataFloat(array, position, offset, blocksize, StringToFloat(buffer));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Float);
		return 1;
	}
	else if (type == DynamicType_Bool)
	{
		char[] buffer = new char[length];
		GetNativeString(3, buffer, length);
		
		if (StrEqual(buffer, "True"))
			SetMemberDataInt(array, position, offset, blocksize, true);
		else if (StrEqual(buffer, "1"))
			SetMemberDataInt(array, position, offset, blocksize, true);
		
		SetMemberDataInt(array, position, offset, blocksize, false);
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native int Dynamic_PushString(Dynamic obj, const char[] value);
public int Native_Dynamic_PushString(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int length = GetNativeStringLength(3, length);
	int memberindex = CreateMemberOffset(data, index, position, offset, blocksize, DynamicType_String, length);
	
	length+=2; // this can probably be removed (review Native_Dynamic_SetString for removal also)
	char[] buffer = new char[length];
	GetNativeString(3, buffer, length);
	SetMemberDataString(data, position, offset, blocksize, buffer);
	//CallOnChangedForward(index, offset, membername, DynamicType_String);
	return memberindex;
}

// native bool Dynamic_GetStringByIndex(Dynamic obj, int index, char[] buffer, int length);
public int Native_Dynamic_GetStringByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	int memberindex = GetNativeCell(2);
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return GetNativeCell(3);
	
	int length = GetNativeCell(4);
	char[] buffer = new char[length];
	
	if (Dynamic_GetStringByOffset(view_as<Dynamic>(index), offset, buffer, length))
	{
		SetNativeString(3, buffer, length);
		return 1;
	}
	return 0;
}

// native int Dynamic_GetStringLength(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetStringLength(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return -1;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_String))
	{
		SetNativeString(3, "", 1);
		return 0;
	}
	
	RecalculateOffset(array, position, offset, blocksize);
	return GetMemberStringLength(array, position, offset, blocksize);
}

// native int Dynamic_GetStringLengthByOffset(Dynamic obj, int offset);
public int Native_Dynamic_GetStringLengthByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	
	RecalculateOffset(array, position, offset, blocksize);
	return GetMemberStringLength(array, position, offset, blocksize);
}

stock int GetStringLengthByOffset(int index, int offset)
{
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position;
	
	RecalculateOffset(array, position, offset, blocksize);
	return GetMemberStringLength(array, position, offset, blocksize);
}

// native Dynamic Dynamic_GetObject(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetObject(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Object))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Object)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	}
}

// native int Dynamic_SetObject(Dynamic obj, const char[] membername, Dynamic value);
public int Native_Dynamic_SetObject(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, true, position, offset, blocksize, DynamicType_Object))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Object)
	{
		// remove parent from current value
		int currentobject = GetMemberDataInt(array, position, offset, blocksize);
		if (currentobject != view_as<int>(INVALID_DYNAMIC_OBJECT))
			SetArrayCell(s_Collection, currentobject, INVALID_DYNAMIC_OBJECT, Dynamic_ParentObject);
		
		// set value
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		
		// set parent only on first attempt
		// the only time a parent can be reset is after the parenting member is set to INVALID_DYNAMIC_OBJECT
		if (GetNativeCell(3) != INVALID_DYNAMIC_OBJECT)
		{
			if (GetArrayCell(s_Collection, GetNativeCell(3), Dynamic_ParentObject) == INVALID_DYNAMIC_OBJECT)
				SetArrayCell(s_Collection, GetNativeCell(3), index, Dynamic_ParentObject);
		}
		
		CallOnChangedForward(index, offset, membername, DynamicType_Object);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

// native Dynamic Dynamic_GetObjectByOffset(Dynamic obj, int offset);
public int Native_Dynamic_GetObjectByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Object)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	}
}

// native bool Dynamic_SetObjectByOffset(Dynamic obj, int offset, Dynamic value);
public int Native_Dynamic_SetObjectByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int offset = GetNativeCell(2);
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Object)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Object);
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native int Dynamic_PushObject(Dynamic obj, Dynamic value);
public int Native_Dynamic_PushObject(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	int value = GetNativeCell(2);
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	SetArrayCell(s_Collection, value, index, Dynamic_ParentObject);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Object);
	SetMemberDataInt(array, position, offset, blocksize, value);
	
	//CallOnChangedForward(index, offset, "Pushed", DynamicType_Object);
	return memberindex;
}

// native Dynamic Dynamic_GetObjectByIndex(Dynamic obj, int index);
public int Native_Dynamic_GetObjectByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	int memberindex = GetNativeCell(2);
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	return view_as<int>(Dynamic_GetObjectByOffset(view_as<Dynamic>(index), offset));
}

// native bool Dynamic_SetObjectByIndex(Dynamic obj, int index, Dynamic value);
public int Native_Dynamic_SetObjectByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return false;
	
	int memberindex = GetNativeCell(2);
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
		
	Dynamic value = GetNativeCell(3);
	Dynamic_SetObjectByOffset(view_as<Dynamic>(index), offset, value);
	return true;
}

// native Handle Dynamic_GetHandle(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetHandle(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Handle))
		return 0;
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Handle)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native int Dynamic_SetHandle(Dynamic obj, const char[] membername, Handle value);
public int Native_Dynamic_SetHandle(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, true, position, offset, blocksize, DynamicType_Handle))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Handle)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForward(index, offset, membername, DynamicType_Handle);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

// native Handle Dynamic_GetHandleByOffset(Dynamic obj, int offset);
public int Native_Dynamic_GetHandleByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Handle)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native bool Dynamic_SetHandleByOffset(Dynamic obj, int offset, Handle value);
public int Native_Dynamic_SetHandleByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int offset = GetNativeCell(2);
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Handle)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Handle);
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native int Dynamic_PushHandle(Dynamic obj, Handle value);
public int Native_Dynamic_PushHandle(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Object);
	SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(2));
	//CallOnChangedForward(index, offset, membername, DynamicType_Int);
	return memberindex;
}

// native Handle Dynamic_GetHandleByIndex(Dynamic obj, int index);
public int Native_Dynamic_GetHandleByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	int memberindex = GetNativeCell(2);
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return 0;
	
	return view_as<int>(Dynamic_GetHandleByOffset(view_as<Dynamic>(index), offset));
}

// native bool Dynamic_GetVector(Dynamic obj, const char[] membername, float[3] vector);
public int Native_Dynamic_GetVector(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Vector))
		return 0;
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Vector)
	{
		float vector[3];
		bool returnvalue = GetMemberDataVector(array, position, offset, blocksize, vector);
		if (returnvalue)
		{
			SetNativeArray(3, vector, sizeof(vector));
			return 1;
		}
		return 0;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native int Dynamic_SetVector(Dynamic obj, const char[] membername, const float[3] value);
public int Native_Dynamic_SetVector(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, true, position, offset, blocksize, DynamicType_Vector))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Vector)
	{
		float vector[3];
		GetNativeArray(3, vector, sizeof(vector));
		SetMemberDataVector(array, position, offset, blocksize, vector);
		CallOnChangedForward(index, offset, membername, DynamicType_Vector);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

// native bool Dynamic_GetVectorByOffset(Dynamic obj, int offset, float[3] vector);
public int Native_Dynamic_GetVectorByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Vector)
	{
		float vector[3];
		bool returnvalue = GetMemberDataVector(array, position, offset, blocksize, vector);
		if (returnvalue)
		{
			SetNativeArray(3, vector, sizeof(vector));
			return 1;
		}
		return 0;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native bool Dynamic_SetVectorByOffset(Dynamic obj, int offset, const float[3] value);
public int Native_Dynamic_SetVectorByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int offset = GetNativeCell(2);
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Vector)
	{
		float vector[3];
		GetNativeArray(3, vector, sizeof(vector));
		SetMemberDataVector(array, position, offset, blocksize, vector);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Vector);
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native int Dynamic_PushVector(Dynamic obj, const float value[3]);
public int Native_Dynamic_PushVector(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset; float vector[3];
	
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Vector);
	GetNativeArray(3, vector, sizeof(vector));
	SetMemberDataVector(array, position, offset, blocksize, vector);
	//CallOnChangedForward(index, offset, membername, DynamicType_Vector);
	return memberindex;
}

// native bool Dynamic_GetVectorByIndex(Dynamic obj, int index, float[3] vector);
public int Native_Dynamic_GetVectorByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	int memberindex = GetNativeCell(2);
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return GetNativeCell(3);
	
	float vector[3];
	
	if (Dynamic_GetVectorByOffset(view_as<Dynamic>(index), offset, vector))
	{
		SetNativeArray(3, vector, sizeof(vector));
		return 1;
	}
	return 0;
}

// native bool Dynamic_GetBool(Dynamic obj, const char[] membername, bool defaultvalue=false);
public int Native_Dynamic_GetBool(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return GetNativeCell(3);
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Bool))
		return GetNativeCell(3);
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Bool)
		return GetMemberDataInt(array, position, offset, blocksize);
	else if (type == DynamicType_Int)
		return (GetMemberDataInt(array, position, offset, blocksize) == 0 ? 0 : 1);
	else if (type == DynamicType_Float)
		return (GetMemberDataFloat(array, position, offset, blocksize) == 0.0 ? 0 : 1);
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(array, position, offset, blocksize, buffer, length);
		if (StrEqual(buffer, ""))
			return false;
		
		return true;
	}
	else if (type == DynamicType_Object)
	{
		int value = GetMemberDataInt(array, position, offset, blocksize);
		if (value == view_as<int>(INVALID_DYNAMIC_OBJECT))
			return false;
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return GetNativeCell(3);
	}
}

// native int Dynamic_SetBool(Dynamic obj, const char[] membername, bool value);
public int Native_Dynamic_SetBool(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, true, position, offset, blocksize, DynamicType_Bool))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForward(index, offset, membername, DynamicType_Bool);
		return offset;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForward(index, offset, membername, DynamicType_Int);
		return offset;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, float(GetNativeCell(3)));
		CallOnChangedForward(index, offset, membername, DynamicType_Float);
		return offset;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		if (GetNativeCell(3))
			strcopy(buffer, length, "True");
		else
			strcopy(buffer, length, "");
		SetMemberDataString(array, position, offset, blocksize, buffer);
		CallOnChangedForward(index, offset, membername, DynamicType_String);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

// native bool Dynamic_GetBoolByOffset(Dynamic obj, int offset, bool defaultvalue=false);
public int Native_Dynamic_GetBoolByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return GetNativeCell(3);
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return GetNativeCell(3);
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Bool)
		return GetMemberDataInt(array, position, offset, blocksize);
	else if (type == DynamicType_Int)
		return (GetMemberDataInt(array, position, offset, blocksize) == 0 ? 0 : 1);
	else if (type == DynamicType_Float)
		return (GetMemberDataFloat(array, position, offset, blocksize) == 0.0 ? 0 : 1);
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(array, position, offset, blocksize, buffer, length);
		if (StrEqual(buffer, ""))
			return false;
		return true;
	}
	else if (type == DynamicType_Object)
	{
		int value = GetMemberDataInt(array, position, offset, blocksize);
		if (value == view_as<int>(INVALID_DYNAMIC_OBJECT))
			return false;
		else
			return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return GetNativeCell(3);
	}
}

// native bool Dynamic_SetBoolByOffset(Dynamic obj, int offset, bool value);
public int Native_Dynamic_SetBoolByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int offset = GetNativeCell(2);
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	
	if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return 1;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Int);
		return 1;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, float(GetNativeCell(3)));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Float);
		return 1;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		if (GetNativeCell(3))
			strcopy(buffer, length, "True");
		else
			strcopy(buffer, length, "");
		SetMemberDataString(array, position, offset, blocksize, buffer);
		CallOnChangedForwardByOffset(index, offset, DynamicType_String);
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

// native int Dynamic_PushBool(Dynamic obj, bool value);
public int Native_Dynamic_PushBool(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Bool);
	SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(2));
	//CallOnChangedForward(index, offset, membername, DynamicType_Bool);
	return memberindex;
}

// native bool Dynamic_GetBoolByIndex(Dynamic obj, int index, bool defaultvalue=false);
public int Native_Dynamic_GetBoolByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	int memberindex = GetNativeCell(2);
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return GetNativeCell(3);
	
	return Dynamic_GetBoolByOffset(view_as<Dynamic>(index), offset, GetNativeCell(3));
}

// native int Dynamic_GetCollectionSize();
public int Native_Dynamic_GetCollectionSize(Handle plugin, int params)
{
	// Collection size is stored within the dynamic object as this is MUCH faster than GetArraySize
	return s_CollectionSize;
}

// native int Dynamic_GetMemberCount(Dynamic obj);
public int Native_Dynamic_GetMemberCount(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	// Return the member count
	return GetMemberCount(index);
}

// native bool Dynamic_HookChanges(Dynamic obj, DynamicHookCB callback);
public int Native_Dynamic_HookChanges(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	// Add forward to objects forward list
	AddToForward(GetArrayCell(s_Collection, index, Dynamic_Forwards), plugin, GetNativeCell(2));
	
	// Store new callback count
	int count = GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, ++count, Dynamic_CallbackCount);
	return 1;
}

// native bool Dynamic_UnHookChanges(Dynamic obj, DynamicHookCB callback);
public int Native_Dynamic_UnHookChanges(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	// Remove forward from objects forward list
	RemoveFromForward(GetArrayCell(s_Collection, index, Dynamic_Forwards), plugin, GetNativeCell(2));
	
	// Store new callback count
	int count = GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, --count, Dynamic_CallbackCount);
	return 1;
}

// native int Dynamic_CallbackCount(Dynamic obj);
public int Native_Dynamic_CallbackCount(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	// Return callback count
	return GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
}

// native int Dynamic_GetMemberOffset(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetMemberOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	// Get member name
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	
	// Find and return offset for member
	Handle offsets = GetArrayCell(s_Collection, index, Dynamic_Offsets);
	int offset;
	if (GetTrieValue(offsets, membername, offset))
		return offset;
	
	// No offset found
	return INVALID_DYNAMIC_OFFSET;
}

// native int Dynamic_GetMemberOffsetByIndex(Dynamic obj, int index);
public int Native_Dynamic_GetMemberOffsetByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	// Get member index param and return offset at this position
	int memberindex = GetNativeCell(2);
	return GetMemberOffsetByIndex(index, memberindex);
}

public int GetMemberOffsetByIndex(int index, int memberindex)
{
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	
	// We dont validate the size of the member count for performance
	// This means a plugin calling for an invalid index will generate errors
	return GetArrayCell(membernames, memberindex, g_iDynamic_MemberLookup_Offset);
}

// native Dynamic_MemberType Dynamic_GetMemberType(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetMemberType(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return view_as<int>(DynamicType_Unknown);
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Unknown))
		return view_as<int>(DynamicType_Unknown);
		
	return view_as<int>(GetMemberType(array, position, offset, blocksize));
}

// native Dynamic_MemberType Dynamic_GetMemberTypeByOffset(Dynamic obj, int offset);
public int Native_Dynamic_GetMemberTypeByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	int position = 0;
	int offset = GetNativeCell(2);
	
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	return view_as<int>(GetMemberType(GetArrayCell(s_Collection, index, Dynamic_Data), position, offset, blocksize));
}

// native bool Dynamic_GetMemberNameByIndex(Dynamic obj, int index, char[] buffer, int size);
public int Native_Dynamic_GetMemberNameByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	int memberindex = GetNativeCell(2);
	int size = GetNativeCell(4);
	
	char[] buffer = new char[size];
	
	if (!GetMemberNameByIndex(index, memberindex, buffer, size))
	{
		SetNativeString(3, "", size);
		return 0;
	}
	
	SetNativeString(3, buffer, size);
	return 1;
}

public bool GetMemberNameByIndex(int index, int memberindex, char[] buffer, int size)
{
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	int membercount = GetMemberCount(index);
	
	if (memberindex >= membercount)
	{
		buffer[0] = '\0';
		return false;
	}
	
	GetArrayString(membernames, memberindex, buffer, size);
	return true;
}

// native bool Dynamic_GetMemberNameByOffset(Dynamic obj, int offset, char[] buffer, int size);
public int Native_Dynamic_GetMemberNameByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	int offset = GetNativeCell(2);
	
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	int membercount = GetMemberCount(index);
	
	for (int i = 0; i < membercount; i++)
	{
		if (GetArrayCell(membernames, i, g_iDynamic_MemberLookup_Offset) == offset)
		{
			char membername[DYNAMIC_MEMBERNAME_MAXLEN];
			GetArrayString(membernames, i, membername, sizeof(membername));
			SetNativeString(3, membername, GetNativeCell(4));
			return 1;
		}
	}
	return 0;
}

// native bool Dynamic_SortMembers(Dynamic obj, SortOrder order);
public int Native_Dynamic_SortMembers(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	int count = GetMemberCount(index);
	if (count == 0)
		return 0;
	
	// Dont bother sorting if there are no members
	Handle members = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	Handle offsetstrie = GetArrayCell(s_Collection, index, Dynamic_Offsets);
	char[][] membernames = new char[count][DYNAMIC_MEMBERNAME_MAXLEN];
	int offset;
	
	// Get each membername into a string array
	for (int memberindex = 0; memberindex < count; memberindex++)
		GetArrayString(members, memberindex, membernames[memberindex], DYNAMIC_MEMBERNAME_MAXLEN);
	
	// Sort member names
	SortOrder order = GetNativeCell(2);
	SortStrings(membernames, count, order);
	
	// Clear current member index lookup arrays
	ClearArray(members);
	
	// Rebuild member lookup arrays based on sorted membernames
	for (int memberindex = 0; memberindex < count; memberindex++)
	{
		if (!GetTrieValue(offsetstrie, membernames[memberindex], offset))
			continue;
		
		memberindex = PushArrayString(members, membernames[memberindex]);
		SetArrayCell(members, memberindex, offset, g_iDynamic_MemberLookup_Offset);
	}
	return 1;
}

stock bool StrEqualEx(Handle array, int index, const char[] fieldname)
{
	for (int i = 0; i < DYNAMIC_MEMBERNAME_MAXLEN; i++)
	{
		if (GetArrayCell(array, index, i, true) != fieldname[i])
			return false;
	
		if (fieldname[i] == 0)
			return true;
	}
	return false;
}

stock void CallOnChangedForward(int index, int offset, const char[] member, Dynamic_MemberType type)
{
	Call_StartForward(GetArrayCell(s_Collection, index, Dynamic_Forwards));
	Call_PushCell(index);
	Call_PushCell(offset);
	Call_PushString(member);
	Call_PushCell(type);
	Call_Finish();
}

stock void CallOnChangedForwardByOffset(int index, int offset, Dynamic_MemberType type)
{
	if (GetArrayCell(s_Collection, index, Dynamic_CallbackCount) > 0)
	{
		char membername[DYNAMIC_MEMBERNAME_MAXLEN];
		Dynamic_GetMemberNameByOffset(view_as<Dynamic>(index), offset, membername, sizeof(membername));
		CallOnChangedForward(index, offset, membername, type);
	}
}
