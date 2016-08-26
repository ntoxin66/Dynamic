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
#include <regex>
#pragma newdecls required
#pragma semicolon 1
 
#define Dynamic_Index					0
// Size isn't yet implement for optimisation around _Dynamic_ExpandIfRequired()
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
#define Dynamic_ParentOffset			13
#define Dynamic_Field_Count				14

Handle s_Collection = null;
int s_CollectionSize = 0;
Handle s_FreeIndicies = null;
Handle s_tObjectNames = null;
Handle g_sRegex_Vector = null;
int g_iDynamic_MemberLookup_Offset;

#include "dynamic/bool.sp"
#include "dynamic/commands.sp"
#include "dynamic/flatconfigs.sp"
#include "dynamic/float.sp"
#include "dynamic/handle.sp"
#include "dynamic/hooks.sp"
#include "dynamic/int.sp"
#include "dynamic/keyvalues.sp"
#include "dynamic/natives.sp"
#include "dynamic/object.sp"
#include "dynamic/selftest.sp"
#include "dynamic/string.sp"
#include "dynamic/vector.sp"

public Plugin myinfo =
{
	name = "Dynamic",
	author = "Neuro Toxin",
	description = "Shared Dynamic Objects for Sourcepawn",
	version = "0.0.18",
	url = "https://forums.alliedmods.net/showthread.php?t=270519"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("dynamic");
	CreateNatives();
	return APLRes_Success;
}

public void OnLibraryRemoved(const char[] name)
{
	_Dynamic_CollectGarbage();
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
	
	// Register commands
	RegisterCommands();
}

public void OnPluginEnd()
{
	// Dispose of all objects in the collection pool
	while (s_CollectionSize > 0)
	{
		_Dynamic_Dispose(s_CollectionSize - 1, false);
	}
}

public void OnMapStart()
{
	_Dynamic_CollectGarbage();
}

stock void OnClientDisconnect_Post(int client)
{
	_Dynamic_ResetObject(client);
}

stock int _Dynamic_Initialise(Handle plugin, int blocksize=64, int startsize=0, bool persistent=false)
{
	int index = -1;
	
	if (index == -1)
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
	SetArrayCell(s_Collection, index, INVALID_DYNAMIC_OFFSET, Dynamic_ParentOffset);
	SetArrayCell(s_Collection, index, 0, Dynamic_MemberCount);
	SetArrayCell(s_Collection, index, plugin, Dynamic_OwnerPlugin);
	SetArrayCell(s_Collection, index, persistent, Dynamic_Persistent);
	
	// Return the next index
	return index;
}

stock bool _Dynamic_Dispose(int index, bool disposemembers, bool reuse=false, int startsize=0)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	// Dispose of child members if disposemembers is set
	if (disposemembers)
	{
		Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
		int count = _Dynamic_GetMemberCount(index);
		int offset; int position; int disposablemember;
		Dynamic_MemberType membertype;
		
		for (int i = 0; i < count; i++)
		{
			position = 0;
			offset = _Dynamic_GetMemberOffsetByIndex(index, i);
			membertype = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
			
			if (membertype == DynamicType_Object)
			{
				disposablemember = _Dynamic_GetMemberDataInt(data, position, offset, blocksize);
				if (!_Dynamic_IsValid(disposablemember))
					continue;
					
				// Check if member hasnt been referenced to another object
				if (_Dynamic_GetParent(disposablemember) == index)
					_Dynamic_Dispose(disposablemember, true);
			}
			else if (membertype == DynamicType_Handle)
			{
				disposablemember = _Dynamic_GetMemberDataInt(data, position, offset, blocksize);
				_Dynamic_SetMemberDataInt(data, position, offset, blocksize, 0);
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
	
	if (reuse)
	{
		SetArrayCell(s_Collection, index, CreateTrie(), Dynamic_Offsets);
		SetArrayCell(s_Collection, index, CreateArray(blocksize, startsize), Dynamic_Data);
		SetArrayCell(s_Collection, index, 0, Dynamic_Forwards);
		SetArrayCell(s_Collection, index, CreateArray(g_iDynamic_MemberLookup_Offset+1), Dynamic_MemberNames);
		SetArrayCell(s_Collection, index, 0, Dynamic_NextOffset);
		SetArrayCell(s_Collection, index, 0, Dynamic_CallbackCount);
		SetArrayCell(s_Collection, index, 0, Dynamic_Size);
		SetArrayCell(s_Collection, index, 0, Dynamic_MemberCount);
		return true;
	}
	
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

stock void _Dynamic_CollectGarbage()
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
			_Dynamic_Dispose(i, false);
	}
}

stock bool _Dynamic_ResetObject(int index, bool disposemembers, int blocksize=0, int startsize=0)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	if (blocksize > 0)
		SetArrayCell(s_Collection, index, blocksize, Dynamic_Blocksize);
	
	return _Dynamic_Dispose(index, disposemembers, true, startsize);
}

stock int _Dynamic_GetOwnerPlugin(int index)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	return GetArrayCell(s_Collection, index, Dynamic_OwnerPlugin);
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
		return Invalid_Dynamic_Object;
	
	// Check object is still valid
	if (!_Dynamic_IsValid(index))
		return Invalid_Dynamic_Object;
	
	// Return object index
	return index;
}

stock int _Dynamic_GetParent(int index)
{
	if (!_Dynamic_IsValid(index))
		return Invalid_Dynamic_Object;
	
	return GetArrayCell(s_Collection, index, Dynamic_ParentObject);
}

stock bool _Dynamic_GetName(int index, char[] buffer, int length)
{
	if (!_Dynamic_IsValid(index))
		return false;

	int parent = GetArrayCell(s_Collection, index, Dynamic_ParentObject);
	if (!_Dynamic_IsValid(parent))
		return false;
	
	int offset = GetArrayCell(s_Collection, index, Dynamic_ParentOffset);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
		
	_Dynamic_GetMemberNameByOffset(parent, offset, buffer, length);
	return true;	
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

stock bool _Dynamic_GetMemberDataOffset(Handle array, int index, const char[] membername, bool create, int &position, int &offset, int blocksize, Dynamic_MemberType type, int stringlength=0)
{
	position = 0;
	offset = 0;
	Handle offsets = GetArrayCell(s_Collection, index, Dynamic_Offsets);
	
	// Find and return member offset
	if (GetTrieValue(offsets, membername, offset))
	{
		_Dynamic_RecalculateOffset(array, position, offset, blocksize);
		return true;
	}
	
	// Return false if offset was not found and we dont need to create a new member
	if (!create)
		return false;
	
	_Dynamic_CreateMemberOffset(array, index, position, offset, blocksize, membername, type, stringlength, offsets);
	return true;
}

stock int _Dynamic_CreateMemberOffset(Handle array, int index, int &position, int &offset, int blocksize, const char[] membername, Dynamic_MemberType type, int stringlength=0, Handle offsets=null)
{
	int memberindex;
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	
	// Increment member count
	SetArrayCell(s_Collection, index, _Dynamic_GetMemberCount(index)+1, Dynamic_MemberCount);
	
	// Get offsets if required
	if (offsets == null)
		offsets = GetArrayCell(s_Collection, index, Dynamic_Offsets);
	
	offset = GetArrayCell(s_Collection, index, Dynamic_NextOffset);
	SetTrieValue(offsets, membername, offset);
	memberindex = PushArrayString(membernames, membername);
	SetArrayCell(membernames, memberindex, offset, g_iDynamic_MemberLookup_Offset);
		
	if (type == DynamicType_String)
	{
		if (stringlength == 0)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "You must set a strings length when you initialise it");
			return false;
		}
		
		_Dynamic_ExpandIfRequired(array, position, offset, blocksize, ByteCountToCells(stringlength));
		_Dynamic_SetMemberDataType(array, position, offset, blocksize, type);
		_Dynamic_SetMemberStringLength(array, position, offset, blocksize, stringlength);
		SetArrayCell(s_Collection, index, offset + 3 + ByteCountToCells(stringlength), Dynamic_NextOffset);
		return memberindex;
	}
	else if (type == DynamicType_Vector)
	{
		_Dynamic_ExpandIfRequired(array, position, offset, blocksize, 3);
		_Dynamic_SetMemberDataType(array, position, offset, blocksize, type);
		SetArrayCell(s_Collection, index, offset + 4, Dynamic_NextOffset);
		return memberindex;
	}
	else
	{
		_Dynamic_ExpandIfRequired(array, position, offset, blocksize, 1);
		_Dynamic_SetMemberDataType(array, position, offset, blocksize, type);
		SetArrayCell(s_Collection, index, offset + 2, Dynamic_NextOffset);
		return memberindex;
	}
}

stock bool _Dynamic_RecalculateOffset(Handle array, int &position, int &offset, int blocksize, bool expand=false, bool aschar=false)
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

stock void _Dynamic_ExpandIfRequired(Handle array, int position, int offset, int blocksize, int length=1)
{
	// Used to expand internal object arrays by the _Dynamic_GetMemberDataOffset method
	offset += length + 1;
	_Dynamic_RecalculateOffset(array, position, offset, blocksize, true);
}

stock Dynamic_MemberType _Dynamic_GetMemberDataType(Handle data, int position, int offset, int blocksize)
{
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(data, position, offset, blocksize);
	
	// Get and return type
	Dynamic_MemberType type = GetArrayCell(data, position, offset);
	return type;
}

stock void _Dynamic_SetMemberDataType(Handle array, int position, int offset, int blocksize, Dynamic_MemberType type)
{
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(array, position, offset, blocksize);
	
	// Set member type
	SetArrayCell(array, position, type, offset);
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
	if (!_Dynamic_GetMemberDataOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Unknown))
		return DynamicType_Unknown;
		
	return _Dynamic_GetMemberDataType(array, position, offset, blocksize);
}

stock Dynamic_MemberType _Dynamic_GetMemberTypeByOffset(int index, int offset)
{
	if (!_Dynamic_IsValid(index, true))
		return DynamicType_Unknown;
	
	int position = 0;
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	return _Dynamic_GetMemberDataType(data, position, offset, blocksize);
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
		return 0;
		
	// Iterate through child dynamic objects
	int membercount = _Dynamic_GetMemberCount(index);
	if (membercount == 0)
		return 0;
	
	// All the required stuff
	ArrayList results = new ArrayList();
	int member;
	int paramcount = _Dynamic_GetMemberCount(params);
	bool matched = true;
	int resultcount = 0;
	int memberoffset;
	
	// Compile params
	char[][] param_name = new char[paramcount][DYNAMIC_MEMBERNAME_MAXLEN];
	Dynamic_MemberType[] param_type = new Dynamic_MemberType[paramcount];
	int[] param_offset = new int[paramcount];
	int[] param_length = new int[paramcount];
	int param_maxlength;
	for (int param=0; param<paramcount; param++)
	{
		param_offset[param] = _Dynamic_GetMemberOffsetByIndex(params, param);
		_Dynamic_GetMemberNameByIndex(params, param, param_name[param], DYNAMIC_MEMBERNAME_MAXLEN);
		param_type[param] = _Dynamic_GetMemberTypeByOffset(params, param_offset[param]);
		if (param_type[param] == DynamicType_String)
		{
			param_length[param] = _Dynamic_GetStringLengthByOffset(params, param_offset[param]);
			if (param_length[param] > param_maxlength)
				param_maxlength = param_length[param];
		}
	}
	char[] paramvalue = new char[param_maxlength];
	
	// Loop members in object
	for (int i = 0; i < membercount; i++)
	{
		// Get member offset and check its a dynamic object
		memberoffset = _Dynamic_GetMemberOffsetByIndex(index, i);
		if (_Dynamic_GetMemberTypeByOffset(index, memberoffset) != DynamicType_Object)
			continue;
		
		// Get member and check its valid
		member = _Dynamic_GetObjectByOffset(index, memberoffset);
		if (!_Dynamic_IsValid(member))
			continue;
		
		// Iterate through each param and check for matches
		matched = true;
		for (int param=0; param < paramcount; param++)
		{			
			switch (param_type[param])
			{
				case DynamicType_String:
				{
					_Dynamic_GetStringByOffset(params, param_offset[param], paramvalue, param_length[param]);
					memberoffset = _Dynamic_GetMemberOffset(member, param_name[param]);
					
					if (!_Dynamic_CompareStringByOffset(member, memberoffset, paramvalue, true))
					{
						matched = false;
						break;
					}
				}
				default:
				{
					ThrowError("Dynamic_MemberType:%d is not yet supported", param_type[param]);
					return 0;
				}
			}
		}
		
		// Check result
		if (!matched)
			continue;
		
		results.Push(member);
		resultcount++;
	}
	
	if (resultcount == 0)
	{
		delete results;
		return 0;
	}
	
	return view_as<int>(results);
}