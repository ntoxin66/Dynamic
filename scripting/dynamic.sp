/**
 * =============================================================================
 * Dynamic for SourceMod (C)2016 Matthew J Dunn.   All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <dynamic>
#include <dynamic-collection>
#include "dynamic/natives.sp"
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
	version = "0.0.17",
	url = "https://forums.alliedmods.net/showthread.php?t=270519"
}

#define Dynamic_Index					0
// Size isn't yet implement for optimisation around ExpandIfRequired()
#define Dynamic_Size					1
#define Dynamic_Blocksize				2
#define Dynamic_Offsets					3
#define Dynamic_MemberNames				4
#define Dynamic_Data					5
#define Dynamic_Forwards				6
#define Dynamic_NextOffset				7
#define Dynamic_CallbackCount			8
#define Dynamic_ParentObject			9
#define Dynamic_MemberCount				10
#define Dynamic_OwnerPlugin				11
#define Dynamic_Persistent				12
#define Dynamic_Field_Count				13

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("dynamic");
	CreateNatives();
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

public void OnMapStart()
{
	// Dispose all objects owned by terminated plugins
	Handle plugin;
	PluginStatus status;
	for (int i = MAXPLAYERS; i < s_CollectionSize; i++)
	{
		// Skip disposed objects
		if (!_Dynamic_IsValid(i, false))
			continue;
			
		// Skip persistent objects
		if (GetArrayCell(s_Collection, i, Dynamic_Persistent))
			continue;
			
		plugin = GetArrayCell(s_Collection, i, Dynamic_OwnerPlugin);
		status = GetPluginStatus(plugin);
		
		if (status == Plugin_Error || status == Plugin_Failed)
			Dynamic_Dispose(i, false);
	}
}

stock int _Dynamic_Initialise(Handle plugin, int blocksize, int startsize, bool persistent)
{
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
	SetArrayCell(s_Collection, index, 0, Dynamic_Forwards);
	SetArrayCell(s_Collection, index, CreateArray(g_iDynamic_MemberLookup_Offset+1), Dynamic_MemberNames);
	SetArrayCell(s_Collection, index, 0, Dynamic_NextOffset);
	SetArrayCell(s_Collection, index, 0, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, INVALID_DYNAMIC_OBJECT, Dynamic_ParentObject);
	SetArrayCell(s_Collection, index, 0, Dynamic_MemberCount);
	SetArrayCell(s_Collection, index, plugin, Dynamic_OwnerPlugin);
	SetArrayCell(s_Collection, index, persistent, Dynamic_Persistent);
	
	// Return the next index
	return index;
}

stock bool _Dynamic_Dispose(int index, bool disposemembers)
{
	// Validate index
	if (!_Dynamic_IsValid(index, true))
		return false;
		
	// Dispose of child members if disposemembers is set
	if (disposemembers)
	{
		Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
		int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
		int count = _Dynamic_GetMemberCount(index);
		int offset; int position; int disposablemember;
		Dynamic_MemberType membertype;
		
		for (int i = 0; i < count; i++)
		{
			position = 0;
			offset = _Dynamic_GetMemberOffsetByIndex(index, i);
			membertype = GetMemberType(data, position, offset, blocksize);
			
			if (membertype == DynamicType_Object)
			{
				disposablemember = GetMemberDataInt(data, position, offset, blocksize);
				if (_Dynamic_IsValid(disposablemember))
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
	if (GetArrayCell(s_Collection, index, Dynamic_Forwards) != 0)
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
	return true;
}

stock bool _Dynamic_SetName(int index, const char[] objectname, bool replace)
{
	if (!_Dynamic_IsValid(index))
		return false;
	
	return SetTrieValue(s_tObjectNames, objectname, index, replace);
}

stock int _Dynamic_FindByName(const char[] objectname)
{
	// Find name in object names trie
	int index;
	if (!GetTrieValue(s_tObjectNames, objectname, index))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	// Check object is still valid
	if (!_Dynamic_IsValid(index))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	// Return object index
	return index;
}

stock int _Dynamic_GetParent(int index)
{
	if (!_Dynamic_IsValid(index))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	return GetArrayCell(s_Collection, index, Dynamic_ParentObject);
}

stock bool _Dynamic_GetPersistence(int index)
{
	if (!_Dynamic_IsValid(index))
		return false;
		
	return GetArrayCell(s_Collection, index, Dynamic_Persistent);
}

stock bool _Dynamic_SetPersistence(int index, bool value)
{
	if (!_Dynamic_IsValid(index))
		return false;
		
	SetArrayCell(s_Collection, index, value, Dynamic_Persistent);
	return true;
}

stock bool _Dynamic_ReadConfig(int index, const char[] path, bool use_valve_fs=false, int valuelength=128)
{
	if (!_Dynamic_IsValid(index))
		return false;
	
	// Check file exists
	if (!FileExists(path, use_valve_fs))
	{
		ThrowNativeError(0, "Filepath '%s' doesn't exist!", path);
		return false;
	}
	
	// Open file for reading
	File stream = OpenFile(path, "r", use_valve_fs);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return false;
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
	int length;
	
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
				
				AddConfigSetting(index, settingnamearray, settingnamelength, settingvaluearray, settingvaluelength, valuelength);
				settingnamelength = 0;
				settingvaluelength = 0;
			}
			
			// quote
			else if (byte == 34)
			{
				readingstring = !readingstring;
				
				if (!readingstring && readingvalue)
				{
					AddConfigSetting(index, settingnamearray, settingnamelength, settingvaluearray, settingvaluelength, valuelength);
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
	return true;
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

stock bool _Dynamic_WriteConfig(int index, const char[] path)
{
	if (!_Dynamic_IsValid(index))
		return false;

	// Open file for writting
	File stream = OpenFile(path, "w", false);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return false;
	}
	
	int count = _Dynamic_GetMemberCount(index);
	int memberoffset;
	int length;
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	for (int i = 0; i < count; i++)
	{
		memberoffset = _Dynamic_GetMemberOffsetByIndex(index, i);
		_Dynamic_GetMemberNameByIndex(index, i, membername, sizeof(membername));
		length = GetStringLengthByOffset(index, memberoffset);
		char[] membervalue = new char[length];
		Dynamic_GetStringByOffset(view_as<Dynamic>(index), memberoffset, membervalue, length);
		stream.WriteLine("%s\t\"%s\"", membername, membervalue);
	}
	
	delete stream;
	return true;
}

stock bool _Dynamic_ReadKeyValues(Handle plugin, int index, const char[] path, int valuelength=128, Dynamic_HookType hook=INVALID_FUNCTION)
{
	if (!_Dynamic_IsValid(index))
		return false;
	
	// Check file exists
	if (!FileExists(path, false))
	{
		ThrowNativeError(0, "Filepath '%s' doesn't exist!", path);
		return false;
	}
	
	KeyValues kv = new KeyValues("");
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		return false;
	}
	
	Handle callbackforward = null;
	if (hook != INVALID_FUNCTION)
	{
		callbackforward = CreateForward(ET_Single, Param_Cell, Param_String, Param_Cell);
		AddToForward(callbackforward, plugin, hook);
	}
	
	IterateKeyValues(kv, view_as<Dynamic>(index), valuelength, callbackforward);
	delete kv;
	
	if (callbackforward != null)
	{
		RemoveFromForward(callbackforward, plugin, hook);
		delete callbackforward;
	}
	return true;
}

stock void IterateKeyValues(KeyValues kv, Dynamic obj, int valuelength, Handle callbackforward, int depth=0)
{
	char key[512];
	KvDataTypes type;
	
	do
	{
		kv.GetSectionName(key, sizeof(key));
		if (kv.GotoFirstSubKey(false))
		{
			Action result;
			if (callbackforward != null)
			{
				Call_StartForward(callbackforward);
				Call_PushCell(obj);
				Call_PushString(key);
				Call_PushCell(depth);
				Call_Finish(result);
			}
			
			if (result == Plugin_Continue)
			{
				Dynamic child = obj.GetObject(key);
				if (!child.IsValid)
				{
					child = Dynamic();
					obj.SetObject(key, child);
				}
				
				IterateKeyValues(kv, child, valuelength, callbackforward, depth+1);
			}
			kv.GoBack();
		}
		else
		{
			type = kv.GetDataType(NULL_STRING);
			switch(type)
			{
				case KvData_String:
				{
					char[] value = new char[valuelength];
					kv.GetString(NULL_STRING, value, valuelength);
					obj.SetString(key, value, valuelength);
				}
				case KvData_Int:
				{
					obj.SetInt(key, kv.GetNum(NULL_STRING));
				}
				case KvData_Float:
				{
					obj.SetFloat(key, kv.GetFloat(NULL_STRING));
				}
				case KvData_Ptr:
				{
					LogError("Type `KvData_Ptr` not yet supported!");
				}
				case KvData_WString:
				{
					LogError("Type `KvData_WString` not yet supported!");
				}
				case KvData_Color:
				{
					LogError("Type `KvData_Color` not yet supported!");
				}
				case KvData_UInt64:
				{
					LogError("Type `KvData_UInt64` not yet supported!");
				}
			}
		}
	}
	while (kv.GotoNextKey(false));
}

stock bool _Dynamic_WriteKeyValues(int index, const char[] path)
{
	if (!_Dynamic_IsValid(index))
		return false;
	
	// Open file for writting
	File stream = OpenFile(path, "w", false);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return false;
	}
	
	WriteObjectToKeyValues(stream, view_as<Dynamic>(index), 0);
	
	delete stream;
	return true;
}

stock void WriteObjectToKeyValues(File stream, Dynamic obj, int indent)
{
	// Create indent
	char indextext[16];
	for (int i = 0; i < indent; i++)
		indextext[i] = 9;
	indextext[indent] = 0;
	int length = 1024;

	int count = _Dynamic_GetMemberCount(view_as<int>(obj));
	int memberoffset;
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	for (int i = 0; i < count; i++)
	{
		memberoffset = _Dynamic_GetMemberOffsetByIndex(view_as<int>(obj), i);
		_Dynamic_GetMemberNameByIndex(view_as<int>(obj), i, membername, sizeof(membername));
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

stock bool _Dynamic_IsValid(int index, bool throwerror=false)
{
	// Check if object index is valid
	if (index < 0 || index >= s_CollectionSize)
	{
		if (throwerror)
			ThrowNativeError(SP_ERROR_NATIVE, "Unable to access dynamic handle %d", index);
		return false;
	}
		
	if (GetArrayCell(s_Collection, index, Dynamic_Index) == -1)
	{
		if (throwerror)
			ThrowNativeError(SP_ERROR_NATIVE, "Tried to access disposed dynamic handle %d", index);
		return false;
	}
	
	return true;
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
	SetArrayCell(s_Collection, index, _Dynamic_GetMemberCount(index)+1, Dynamic_MemberCount);
	
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
	SetArrayCell(s_Collection, index, _Dynamic_GetMemberCount(index)+1, Dynamic_MemberCount);
	
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

stock void SetMemberDataVector(Handle array, int position, int offset, int blocksize, const float value[3])
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

stock int _Dynamic_GetInt(int index, const char[] membername, int defaultvalue=-1)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Int))
		return defaultvalue;
		
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
		return defaultvalue;
	}
}

// native int Dynamic_SetInt(Dynamic obj, const char[] membername, int value);
stock int _Dynamic_SetInt(int index, const char[] membername, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, true, position, offset, blocksize, DynamicType_Int))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForward(index, offset, membername, DynamicType_Int);
		return offset;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, float(value));
		CallOnChangedForward(index, offset, membername, DynamicType_Float);
		return offset;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return 1;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		IntToString(value, buffer, length);
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

stock int _Dynamic_GetIntByOffset(int index, int offset, int defaultvalue=-1)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	
	if (!ValidateOffset(array, position, offset, blocksize))
		return defaultvalue;
	
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
		return defaultvalue;
	}
}

stock bool _Dynamic_SetIntByOffset(int index, int offset, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	
	if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Int);
		return true;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, float(value));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Float);
		return true;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return true;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		IntToString(value, buffer, length);
		SetMemberDataString(array, position, offset, blocksize, buffer);
		CallOnChangedForwardByOffset(index, offset, DynamicType_String);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock int _Dynamic_PushInt(int index, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Int);
	SetMemberDataInt(array, position, offset, blocksize, value);
	//CallOnChangedForward(index, offset, membername, DynamicType_Int);
	return memberindex;
}

stock int _Dynamic_GetIntByIndex(int index, int memberindex, int defaultvalue=-1)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return Dynamic_GetIntByOffset(view_as<Dynamic>(index), offset, defaultvalue);
}

stock float _Dynamic_GetFloat(int index, const char[] membername, float defaultvalue=-1.0)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Float))
		return defaultvalue;
		
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
		return GetMemberDataFloat(data, position, offset, blocksize);
	else if (type == DynamicType_Int || type == DynamicType_Bool)
		return float(GetMemberDataInt(data, position, offset, blocksize));
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(data, position, offset, blocksize, buffer, length);
		return StringToFloat(buffer);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return defaultvalue;
	}
}

stock int _Dynamic_SetFloat(int index, const char[] membername, float value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Float))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
	{
		SetMemberDataFloat(data, position, offset, blocksize, value);
		CallOnChangedForward(index, offset, membername, DynamicType_Float);
		return offset;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(data, position, offset, blocksize, RoundToFloor(value));
		CallOnChangedForward(index, offset, membername, DynamicType_Int);
		return offset;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(data, position, offset, blocksize, RoundToFloor(value));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return 1;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		FloatToString(value, buffer, length);
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

stock float _Dynamic_GetFloatByOffset(int index, int offset, float defaultvalue=-1.0)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return defaultvalue;
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Float)
		return GetMemberDataFloat(array, position, offset, blocksize);
	else if (type == DynamicType_Int || type == DynamicType_Bool)
		return float(GetMemberDataInt(array, position, offset, blocksize));
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(array, position, offset, blocksize, buffer, length);
		return StringToFloat(buffer);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return defaultvalue;
	}
}

stock bool _Dynamic_SetFloatByOffset(int index, int offset, float value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;

	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Float);
		return true;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, RoundToFloor(value));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Int);
		return true;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, RoundToFloor(value));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return true;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		FloatToString(value, buffer, length);
		SetMemberDataString(array, position, offset, blocksize, buffer);
		CallOnChangedForwardByOffset(index, offset, DynamicType_String);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock int _Dynamic_PushFloat(int index, float value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(data, index, position, offset, blocksize, DynamicType_Float);
	SetMemberDataFloat(data, position, offset, blocksize, value);
	//CallOnChangedForward(index, offset, membername, DynamicType_Float);
	return memberindex;
}

stock float _Dynamic_GetFloatByIndex(int index, int memberindex, float defaultvalue=-1.0)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return _Dynamic_GetFloatByOffset(index, offset, defaultvalue);
}

stock bool _Dynamic_GetString(int index, const char[] membername, char[] buffer, int size)
{
	if (!_Dynamic_IsValid(index, true))
	{
		buffer[0] = '\0';
		return false;
	}
	
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_String))
	{
		buffer[0] = '\0';
		return false;
	}
		
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		GetMemberDataString(data, position, offset, blocksize, buffer, size);
		return true;
	}
	else if (type == DynamicType_Int)
	{
		int value = GetMemberDataInt(data, position, offset, blocksize);
		IntToString(value, buffer, size);
		return true;
	}
	else if (type == DynamicType_Float)
	{
		float value = GetMemberDataFloat(data, position, offset, blocksize);
		FloatToString(value, buffer, size);
		return true;
	}
	else if (type == DynamicType_Bool)
	{
		if (GetMemberDataInt(data, position, offset, blocksize))
			Format(buffer, size, "True");
		else
			Format(buffer, size, "False");
		return true;
	}
	else if (type == DynamicType_Vector)
	{
		float vector[3];
		GetMemberDataVector(data, position, offset, blocksize, vector);
		Format(buffer, size, "{%f, %f, %f}", vector[0], vector[1], vector[2]);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		buffer[0] = '\0';
		return false;
	}
}

stock int _Dynamic_SetString(int index, const char[] membername, const char[] value, int length, int valuelength)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	if (length == 0)
		length = ++valuelength;
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_String, length))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		SetMemberDataString(data, position, offset, blocksize, value);
		CallOnChangedForward(index, offset, membername, DynamicType_String);
		return offset;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(data, position, offset, blocksize, StringToInt(value));
		CallOnChangedForward(index, offset, membername, DynamicType_Int);
		return offset;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(data, position, offset, blocksize, StringToFloat(value));
		CallOnChangedForward(index, offset, membername, DynamicType_Float);
		return offset;
	}
	else if (type == DynamicType_Bool)
	{		
		if (StrEqual(value, "True"))
			SetMemberDataInt(data, position, offset, blocksize, true);
		else if (StrEqual(value, "1"))
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

stock bool _Dynamic_GetStringByOffset(int index, int offset, char[] buffer, int length)
{
	if (!_Dynamic_IsValid(index, true))
	{
		buffer[0] = '\0';
		return false;
	}
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
	{
		buffer[0] = '\0';
		return false;
	}
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		GetMemberDataString(array, position, offset, blocksize, buffer, length);
		return true;
	}
	else if (type == DynamicType_Int)
	{
		int value = GetMemberDataInt(array, position, offset, blocksize);
		IntToString(value, buffer, length);
		return true;
	}
	else if (type == DynamicType_Float)
	{
		float value = GetMemberDataFloat(array, position, offset, blocksize);
		FloatToString(value, buffer, length);
		return true;
	}
	else if (type == DynamicType_Bool)
	{
		if (GetMemberDataInt(array, position, offset, blocksize))
			Format(buffer, length, "True");
		else
			Format(buffer, length, "False");
		return true;
	}
	else if (type == DynamicType_Vector)
	{
		float vector[3];
		GetMemberDataVector(array, position, offset, blocksize, vector);
		Format(buffer, length, "{%f, %f, %f}", vector[0], vector[1], vector[2]);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		buffer[0] = '\0';
		return false;
	}
}

stock bool _Dynamic_SetStringByOffset(int index, int offset, const char[] value, int length, int valuelength)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	if (length == 0)
		length = ++valuelength;
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		SetMemberDataString(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_String);
		return true;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, StringToInt(value));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Int);
		return true;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, StringToFloat(value));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Float);
		return true;
	}
	else if (type == DynamicType_Bool)
	{
		if (StrEqual(value, "True"))
			SetMemberDataInt(array, position, offset, blocksize, true);
		else if (StrEqual(value, "1"))
			SetMemberDataInt(array, position, offset, blocksize, true);
		
		SetMemberDataInt(array, position, offset, blocksize, false);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock int _Dynamic_PushString(int index, const char[] value, int length, int valuelength)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	if (length == 0)
		length = ++valuelength;
	
	int position; int offset;
	int memberindex = CreateMemberOffset(data, index, position, offset, blocksize, DynamicType_String, length);
	
	length+=2; // this can probably be removed (review Native_Dynamic_SetString for removal also)
	SetMemberDataString(data, position, offset, blocksize, value);
	//CallOnChangedForward(index, offset, membername, DynamicType_String);
	return memberindex;
}

stock bool _Dynamic_GetStringByIndex(int index, int memberindex, char[] buffer, int length)
{
	if (!_Dynamic_IsValid(index, true))
	{
		buffer[0] = '\0';
		return false;
	}
	
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
	{
		buffer[0] = '\0';
		return false;
	}
	
	if (_Dynamic_GetStringByOffset(index, offset, buffer, length))
		return true;
		
	return false;
}

stock int _Dynamic_GetStringLength(int index, const char[] membername)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;

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

stock int _Dynamic_GetStringLengthByOffset(int index, int offset)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
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

stock int _Dynamic_GetObject(int index, const char[] membername)
{
	if (!_Dynamic_IsValid(index, true))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
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

stock int _Dynamic_SetObject(int index, const char[] membername, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
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
		
		// set value and name
		SetMemberDataInt(array, position, offset, blocksize, value);
		Dynamic_SetString(view_as<Dynamic>(index), "_name", membername); // naughty call back through native
		
		// set parent only on first attempt
		// the only time a parent can be reset is after the parenting member is set to INVALID_DYNAMIC_OBJECT
		if (value != view_as<int>(INVALID_DYNAMIC_OBJECT))
		{
			if (GetArrayCell(s_Collection, index, Dynamic_ParentObject) == INVALID_DYNAMIC_OBJECT)
				SetArrayCell(s_Collection, index, value, Dynamic_ParentObject);
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
stock int _Dynamic_GetObjectByOffset(int index, int offset)
{
	if (!_Dynamic_IsValid(index, true))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
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

stock bool _Dynamic_SetObjectByOffset(int index, int offset, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Object)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Object);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock int _Dynamic_PushObject(int index, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	SetArrayCell(s_Collection, value, index, Dynamic_ParentObject);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Object);
	SetMemberDataInt(array, position, offset, blocksize, value);
	
	//CallOnChangedForward(index, offset, "Pushed", DynamicType_Object);
	return memberindex;
}

stock int _Dynamic_GetObjectByIndex(int index, int memberindex)
{
	if (!_Dynamic_IsValid(index, true))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
	
	return view_as<int>(Dynamic_GetObjectByOffset(view_as<Dynamic>(index), offset));
}

stock bool _Dynamic_SetObjectByIndex(int index, int memberindex, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
	
	return _Dynamic_SetObjectByOffset(index, offset, value);
}

stock int _Dynamic_GetHandle(int index, const char[] membername)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
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

stock int _Dynamic_SetHandle(int index, const char[] membername, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, true, position, offset, blocksize, DynamicType_Handle))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Handle)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForward(index, offset, membername, DynamicType_Handle);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

stock int _Dynamic_GetHandleByOffset(int index, int offset)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
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

stock bool _Dynamic_SetHandleByOffset(int index, int offset, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Handle)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Handle);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock int _Dynamic_PushHandle(int index, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Object);
	SetMemberDataInt(array, position, offset, blocksize, value);
	//CallOnChangedForward(index, offset, membername, DynamicType_Int);
	return memberindex;
}

stock int _Dynamic_GetHandleByIndex(int index, int memberindex)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return 0;
	
	return _Dynamic_GetHandleByOffset(index, offset);
}

stock bool _Dynamic_GetVector(int index, const char[] membername, float[3] vector)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Vector))
		return false;
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Vector)
		return GetMemberDataVector(array, position, offset, blocksize, vector);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock int _Dynamic_SetVector(int index, const char[] membername, const float value[3])
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, true, position, offset, blocksize, DynamicType_Vector))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Vector)
	{
		SetMemberDataVector(array, position, offset, blocksize, value);
		CallOnChangedForward(index, offset, membername, DynamicType_Vector);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

stock bool _Dynamic_GetVectorByOffset(int index, int offset, float[3] value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Vector)
	{
		return GetMemberDataVector(array, position, offset, blocksize, value);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock bool _Dynamic_SetVectorByOffset(int index, int offset, const float value[3])
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Vector)
	{
		SetMemberDataVector(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Vector);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock int _Dynamic_PushVector(int index, const float value[3])
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Vector);
	
	SetMemberDataVector(array, position, offset, blocksize, value);
	//CallOnChangedForward(index, offset, membername, DynamicType_Vector);
	return memberindex;
}

// native bool Dynamic_GetVectorByIndex(Dynamic obj, int index, float value[3]);
stock bool _Dynamic_GetVectorByIndex(int index, int memberindex, float value[3])
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
	
	return _Dynamic_GetVectorByOffset(index, offset, value);
}

stock bool _Dynamic_GetBool(int index, const char[] membername, bool defaultvalue=false)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;

	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Bool))
		return defaultvalue;
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Bool)
		return view_as<bool>(GetMemberDataInt(array, position, offset, blocksize));
	else if (type == DynamicType_Int)
		return (GetMemberDataInt(array, position, offset, blocksize) == 0 ? false : true);
	else if (type == DynamicType_Float)
		return (GetMemberDataFloat(array, position, offset, blocksize) == 0.0 ? false : true);
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
		return defaultvalue;
	}
}

stock int _Dynamic_SetBool(int index, const char[] membername, bool value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;

	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, true, position, offset, blocksize, DynamicType_Bool))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForward(index, offset, membername, DynamicType_Bool);
		return offset;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForward(index, offset, membername, DynamicType_Int);
		return offset;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, float(value));
		CallOnChangedForward(index, offset, membername, DynamicType_Float);
		return offset;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		if (value)
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

stock bool _Dynamic_GetBoolByOffset(int index, int offset, bool defaultvalue=false)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return defaultvalue;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Bool)
		return view_as<bool>(GetMemberDataInt(array, position, offset, blocksize));
	else if (type == DynamicType_Int)
		return (GetMemberDataInt(array, position, offset, blocksize) == 0 ? false : true);
	else if (type == DynamicType_Float)
		return (GetMemberDataFloat(array, position, offset, blocksize) == 0.0 ? false : true);
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
		return defaultvalue;
	}
}

stock bool _Dynamic_SetBoolByOffset(int index, int offset, bool value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	
	if (type == DynamicType_Bool)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Bool);
		return true;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(array, position, offset, blocksize, value);
		CallOnChangedForwardByOffset(index, offset, DynamicType_Int);
		return true;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(array, position, offset, blocksize, float(value));
		CallOnChangedForwardByOffset(index, offset, DynamicType_Float);
		return true;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(array, position, offset, blocksize);
		char[] buffer = new char[length];
		if (value)
			strcopy(buffer, length, "True");
		else
			strcopy(buffer, length, "");
		SetMemberDataString(array, position, offset, blocksize, buffer);
		CallOnChangedForwardByOffset(index, offset, DynamicType_String);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock int _Dynamic_PushBool(int index, bool value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, DynamicType_Bool);
	
	SetMemberDataInt(array, position, offset, blocksize, value);
	//CallOnChangedForward(index, offset, membername, DynamicType_Bool);
	return memberindex;
}

stock bool _Dynamic_GetBoolByIndex(int index, int memberindex, bool defaultvalue=false)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	int offset = Dynamic_GetMemberOffsetByIndex(view_as<Dynamic>(index), memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return Dynamic_GetBoolByOffset(view_as<Dynamic>(index), offset, defaultvalue);
}

stock int _Dynamic_GetCollectionSize()
{
	return s_CollectionSize;
}

stock int _Dynamic_GetMemberCount(int index)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	return GetArrayCell(s_Collection, index, Dynamic_MemberCount);
}

stock bool _Dynamic_HookChanges(int index, Dynamic_HookType callback, Handle plugin)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle forwards = GetArrayCell(s_Collection, index, Dynamic_Forwards);
	if (forwards == null)
	{
		forwards = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell);
		SetArrayCell(s_Collection, index, forwards, Dynamic_Forwards);
	}
	
	// Add forward to objects forward list
	AddToForward(forwards, plugin, callback);
	
	// Store new callback count
	int count = GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, ++count, Dynamic_CallbackCount);
	return true;
}

stock bool _Dynamic_UnHookChanges(int index, Dynamic_HookType callback, Handle plugin)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle forwards = GetArrayCell(s_Collection, index, Dynamic_Forwards);
	if (forwards == null)
		return false;
	
	// Remove forward from objects forward list
	RemoveFromForward(forwards, plugin, callback);
	
	// Store new callback count
	int count = GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, --count, Dynamic_CallbackCount);
	
	if (count == 0)
	{
		CloseHandle(forwards);
		SetArrayCell(s_Collection, index, 0, Dynamic_Forwards);
	}
	return true;
}

stock int _Dynamic_CallbackCount(int index)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	return GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
}

stock int _Dynamic_GetMemberOffset(int index, const char[] membername)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	// Find and return offset for member
	Handle offsets = GetArrayCell(s_Collection, index, Dynamic_Offsets);
	int offset;
	if (GetTrieValue(offsets, membername, offset))
		return offset;
	
	// No offset found
	return INVALID_DYNAMIC_OFFSET;
}

stock int _Dynamic_GetMemberOffsetByIndex(int index, int memberindex)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	return GetArrayCell(membernames, memberindex, g_iDynamic_MemberLookup_Offset);
}

stock Dynamic_MemberType _Dynamic_GetMemberType(int index, const char[] membername)
{
	if (!_Dynamic_IsValid(index, true))
		return DynamicType_Unknown;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Unknown))
		return DynamicType_Unknown;
		
	return GetMemberType(array, position, offset, blocksize);
}

stock Dynamic_MemberType _Dynamic_GetMemberTypeByOffset(int index, int offset)
{
	if (!_Dynamic_IsValid(index, true))
		return DynamicType_Unknown;
	
	int position = 0;
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	return GetMemberType(GetArrayCell(s_Collection, index, Dynamic_Data), position, offset, blocksize);
}

stock bool _Dynamic_GetMemberNameByIndex(int index, int memberindex, char[] buffer, int length)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	int membercount = _Dynamic_GetMemberCount(index);
	
	if (memberindex >= membercount)
	{
		buffer[0] = '\0';
		return false;
	}
	
	GetArrayString(membernames, memberindex, buffer, length);
	return true;
}

stock bool _Dynamic_GetMemberNameByOffset(int index, int offset, char[] buffer, int length)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	int membercount = _Dynamic_GetMemberCount(index);
	
	for (int i = 0; i < membercount; i++)
	{
		if (GetArrayCell(membernames, i, g_iDynamic_MemberLookup_Offset) == offset)
		{
			GetArrayString(membernames, i, buffer, length);
			return true;
		}
	}
	return false;
}

stock bool _Dynamic_SortMembers(int index, SortOrder order)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	int count = _Dynamic_GetMemberCount(index);
	if (count == 0)
		return false;
	
	// Dont bother sorting if there are no members
	Handle members = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	Handle offsetstrie = GetArrayCell(s_Collection, index, Dynamic_Offsets);
	char[][] membernames = new char[count][DYNAMIC_MEMBERNAME_MAXLEN];
	int offset;
	
	// Get each membername into a string array
	for (int memberindex = 0; memberindex < count; memberindex++)
		GetArrayString(members, memberindex, membernames[memberindex], DYNAMIC_MEMBERNAME_MAXLEN);
	
	// Sort member names
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
	return true;
}

stock int _Dynamic_FindByMemberValue(int index, int params)
{
	if (!_Dynamic_IsValid(index, true))
		return view_as<int>(INVALID_DYNAMIC_OBJECT);
		
	/*// Iterate through child dynamic objects
	int count = GetMemberCount(index);
	if (count == 0)
		return null;
	
	Dynamic results = new Dynamic();
	
	for (int i = 0; i < count; i++)
	{
		memberoffset = GetMemberOffsetByIndex(i);
		if (someobj.GetMemberType(memberoffset) != DynamicType_Object)
			continue;
		
		
		
		someobj.GetMemberNameByIndex(i, membername, sizeof(membername));
		
	}*/
	
	return view_as<int>(INVALID_DYNAMIC_OBJECT);
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
	Handle forwards = GetArrayCell(s_Collection, index, Dynamic_Forwards);
	if (forwards == null)
		return;
		
	Call_StartForward(forwards);
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
