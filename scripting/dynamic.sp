#include <dynamic>
#pragma semicolon 1
#pragma newdecls required

static Handle s_Collection = null;
static int s_CollectionSize = 0;
static Handle s_FreeIndicies = null;
static Handle s_tObjectNames = null;

public Plugin myinfo =
{
	name = "Dynamic",
	author = "Neuro Toxin",
	description = "Shared Dynamic Objects for Sourcepawn",
	version = "0.0.11",
	url = "https://forums.alliedmods.net/showthread.php?t=270519"
}

#define Dynamic_Index						0
#define Dynamic_Size						1
#define Dynamic_Blocksize				2
#define Dynamic_Offsets					3
#define Dynamic_MemberNames				4
#define Dynamic_MemberOffsets			5
#define Dynamic_Data						6
#define Dynamic_Forwards					7
#define Dynamic_NextOffset				8
#define Dynamic_CallbackCount			9
#define Dynamic_Field_Count				10

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Register plugin and natives
	RegPluginLibrary("dynamic");
	CreateNative("Dynamic_Initialise", Native_Dynamic_Initialise);
	CreateNative("Dynamic_Dispose", Native_Dynamic_Dispose);
	CreateNative("Dynamic_SetName", Native_Dynamic_SetName);
	CreateNative("Dynamic_FindByName", Native_Dynamic_FindByName);
	CreateNative("Dynamic_GetInt", Native_Dynamic_GetInt);
	CreateNative("Dynamic_SetInt", Native_Dynamic_SetInt);
	CreateNative("Dynamic_GetIntByOffset", Native_Dynamic_GetIntByOffset);
	CreateNative("Dynamic_SetIntByOffset", Native_Dynamic_SetIntByOffset);
	CreateNative("Dynamic_GetBool", Native_Dynamic_GetBool);
	CreateNative("Dynamic_SetBool", Native_Dynamic_SetBool);
	CreateNative("Dynamic_GetBoolByOffset", Native_Dynamic_GetBoolByOffset);
	CreateNative("Dynamic_SetBoolByOffset", Native_Dynamic_SetBoolByOffset);
	CreateNative("Dynamic_GetFloat", Native_Dynamic_GetFloat);
	CreateNative("Dynamic_SetFloat", Native_Dynamic_SetFloat);
	CreateNative("Dynamic_GetFloatByOffset", Native_Dynamic_GetFloatByOffset);
	CreateNative("Dynamic_SetFloatByOffset", Native_Dynamic_SetFloatByOffset);
	CreateNative("Dynamic_GetString", Native_Dynamic_GetString);
	CreateNative("Dynamic_SetString", Native_Dynamic_SetString);
	CreateNative("Dynamic_GetStringByOffset", Native_Dynamic_GetStringByOffset);
	CreateNative("Dynamic_SetStringByOffset", Native_Dynamic_SetStringByOffset);
	CreateNative("Dynamic_GetStringLengthByOffset", Native_Dynamic_GetStringLengthByOffset);
	CreateNative("Dynamic_GetStringLength", Native_Dynamic_GetStringLength);
	CreateNative("Dynamic_GetObject", Native_Dynamic_GetObject);
	CreateNative("Dynamic_SetObject", Native_Dynamic_SetObject);
	CreateNative("Dynamic_GetObjectByOffset", Native_Dynamic_GetObjectByOffset);
	CreateNative("Dynamic_SetObjectByOffset", Native_Dynamic_SetObjectByOffset);
	CreateNative("Dynamic_GetHandle", Native_Dynamic_GetHandle);
	CreateNative("Dynamic_SetHandle", Native_Dynamic_SetHandle);
	CreateNative("Dynamic_GetHandleByOffset", Native_Dynamic_GetHandleByOffset);
	CreateNative("Dynamic_SetHandleByOffset", Native_Dynamic_SetHandleByOffset);
	CreateNative("Dynamic_GetCollectionSize", Native_Dynamic_GetCollectionSize);
	CreateNative("Dynamic_GetVector", Native_Dynamic_GetVector);
	CreateNative("Dynamic_SetVector", Native_Dynamic_SetVector);
	CreateNative("Dynamic_GetVectorByOffset", Native_Dynamic_GetVectorByOffset);
	CreateNative("Dynamic_SetVectorByOffset", Native_Dynamic_SetVectorByOffset);
	CreateNative("Dynamic_GetMemberCount", Native_Dynamic_GetMemberCount);
	CreateNative("Dynamic_IsValid", Native_Dynamic_IsValid);
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
}

public void OnPluginEnd()
{
	// Dispose of all objects in the collection pool
	while (s_CollectionSize > 0)
	{
		Dynamic_Dispose(s_CollectionSize - 1, false);
	}
}

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
	SetArrayCell(s_Collection, index, CreateArray(DYNAMIC_MEMBERNAME_MAXLEN), Dynamic_MemberNames);
	SetArrayCell(s_Collection, index, CreateArray(DYNAMIC_MEMBERNAME_MAXLEN), Dynamic_MemberOffsets);
	SetArrayCell(s_Collection, index, 0, Dynamic_NextOffset);
	SetArrayCell(s_Collection, index, 0, Dynamic_CallbackCount);
	
	// Return the next indexs
	return index;
}

public int Native_Dynamic_Dispose(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
		
	// Dispose of child members if
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
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_MemberOffsets));
	
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

public int Native_Dynamic_SetName(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index))
		return 0;
	
	int length;
	GetNativeStringLength(2, length);
	char[] objectname = new char[length];
	GetNativeString(2, objectname, length);
	return SetTrieValue(s_tObjectNames, objectname, index, GetNativeCell(3));
}

public int Native_Dynamic_FindByName(Handle plugin, int params)
{
	int length;
	GetNativeStringLength(1, length);
	char[] objectname = new char[length];
	GetNativeString(1, objectname, length);
	
	int index;
	if (!GetTrieValue(s_tObjectNames, objectname, index))
		return INVALID_DYNAMIC_OBJECT;
	
	if (!Dynamic_IsValid(index))
		return INVALID_DYNAMIC_OBJECT;
	
	return index;
}

public int Native_Dynamic_IsValid(Handle plugin, int params)
{
	int index = GetNativeCell(1);
	bool throwerror = GetNativeCell(2);
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
	
	if (GetTrieValue(offsets, membername, offset))
	{
		RecalculateOffset(array, position, offset, blocksize);
		return true;
	}
	
	if (!create)
		return false;
	
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	Handle memberoffsets = GetArrayCell(s_Collection, index, Dynamic_MemberOffsets);
	
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
		PushArrayString(membernames, membername);
		PushArrayCell(memberoffsets, offset);
		
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
		PushArrayString(membernames, membername);
		PushArrayCell(memberoffsets, offset);
		
		ExpandIfRequired(array, position, offset, blocksize, 3);
		SetMemberType(array, position, offset, blocksize, newtype);
		SetArrayCell(s_Collection, index, offset + 4, Dynamic_NextOffset);
		return true;
	}
	else
	{
		offset = GetArrayCell(s_Collection, index, Dynamic_NextOffset);
		SetTrieValue(offsets, membername, offset);
		PushArrayString(membernames, membername);
		PushArrayCell(memberoffsets, offset);
		
		ExpandIfRequired(array, position, offset, blocksize, 1);
		SetMemberType(array, position, offset, blocksize, newtype);
		SetArrayCell(s_Collection, index, offset + 2, Dynamic_NextOffset);
		return true;
	}
}

stock bool RecalculateOffset(Handle array, int &position, int &offset, int blocksize, bool expand=false, bool aschar=false)
{
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
		int size = GetArraySize(array);
		while (size <= position)
		{
			PushArrayCell(array, 0);
			size++;
		}
	}
	return true;
}

stock bool ValidateOffset(Handle array, int &position, int &offset, int blocksize, bool aschar=false)
{
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
	offset += length + 1;
	RecalculateOffset(array, position, offset, blocksize, true);
}

stock Dynamic_MemberType GetMemberType(Handle array, int position, int offset, int blocksize)
{
	RecalculateOffset(array, position, offset, blocksize);
	
	int type = GetArrayCell(array, position, offset);
	return view_as<Dynamic_MemberType>(type);
}

stock void SetMemberType(Handle array, int position, int offset, int blocksize, Dynamic_MemberType type)
{
	RecalculateOffset(array, position, offset, blocksize);
	SetArrayCell(array, position, type, offset);
}

stock int GetMemberStringLength(Handle array, int position, int offset, int blocksize)
{
	offset++;
	RecalculateOffset(array, position, offset, blocksize);
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
	offset++;
	RecalculateOffset(array, position, offset, blocksize);
	return GetArrayCell(array, position, offset);
}

stock void SetMemberDataInt(Handle array, int position, int offset, int blocksize, int value)
{
	offset++;
	RecalculateOffset(array, position, offset, blocksize);
	SetArrayCell(array, position, value, offset);
}

stock float GetMemberDataFloat(Handle array, int position, int offset, int blocksize)
{
	offset++;
	RecalculateOffset(array, position, offset, blocksize);
	return GetArrayCell(array, position, offset);
}

stock void SetMemberDataFloat(Handle array, int position, int offset, int blocksize, float value)
{
	offset++;
	RecalculateOffset(array, position, offset, blocksize);
	SetArrayCell(array, position, value, offset);
}

stock bool GetMemberDataVector(Handle array, int position, int offset, int blocksize, float vector[3])
{
	for (int i=0; i<3; i++)
	{
		offset++;
		RecalculateOffset(array, position, offset, blocksize);
		vector[i] = GetArrayCell(array, position, offset);
	}
	return true;
}

stock void SetMemberDataVector(Handle array, int position, int offset, int blocksize, float value[3])
{
	for (int i=0; i<3; i++)
	{
		offset++;
		RecalculateOffset(array, position, offset, blocksize);
		SetArrayCell(array, position, value[i], offset);
	}
}

stock void GetMemberDataString(Handle array, int position, int offset, int blocksize, char[] buffer, int length)
{
	offset+=2;
	RecalculateOffset(array, position, offset, blocksize, true);
	
	offset*=4;
	
	int i; char letter;
	for (i=0; i < length; i++)
	{
		letter = view_as<char>(GetArrayCell(array, position, offset, true));
		buffer[i] = letter;
		if (letter == 0)
			return;
			
		offset++;
		RecalculateOffset(array, position, offset, blocksize, false, true);
	}
	
	buffer[i-1] = '0';
}

stock void SetMemberDataString(Handle array, int position, int offset, int blocksize, const char[] buffer)
{
	int length = GetMemberStringLength(array, position, offset, blocksize);
	
	offset+=2;
	RecalculateOffset(array, position, offset, blocksize);
	offset*=4;
	
	int i;
	char letter;
	for (i=0; i < length; i++)
	{
		letter = buffer[i];
		SetArrayCell(array, position, letter, offset, true);
		if (letter == 0)
			return;
			
		offset++;
		RecalculateOffset(array, position, offset, blocksize, false, true);
	}
	
	offset--;
	RecalculateOffset(array, position, offset, blocksize, false, true);
	SetArrayCell(array, position, 0, offset, true);
}

stock int GetMemberCount(int index)
{
	return GetTrieSize(GetArrayCell(s_Collection, index, Dynamic_Offsets));
}

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
		return 1;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

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

public int Native_Dynamic_GetObject(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OBJECT;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Object))
		return INVALID_DYNAMIC_OBJECT;
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Object)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OBJECT;
	}
}

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
		SetMemberDataInt(array, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForward(index, offset, membername, DynamicType_Object);
		return offset;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OFFSET;
	}
}

public int Native_Dynamic_GetObjectByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OBJECT;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return INVALID_DYNAMIC_OBJECT;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Object)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OBJECT;
	}
}

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

public int Native_Dynamic_GetHandle(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OBJECT;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Handle))
		return INVALID_DYNAMIC_OBJECT;
		
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Handle)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OBJECT;
	}
}

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

public int Native_Dynamic_GetHandleByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OBJECT;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return INVALID_DYNAMIC_OBJECT;
	
	Dynamic_MemberType type = GetMemberType(array, position, offset, blocksize);
	if (type == DynamicType_Handle)
		return GetMemberDataInt(array, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OBJECT;
	}
}

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

public int Native_Dynamic_GetVector(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OBJECT;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(array, index, membername, false, position, offset, blocksize, DynamicType_Vector))
		return INVALID_DYNAMIC_OBJECT;
		
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
		return INVALID_DYNAMIC_OBJECT;
	}
}

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

public int Native_Dynamic_GetVectorByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OBJECT;
	
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int offset = GetNativeCell(2);
	int position;
	if (!ValidateOffset(array, position, offset, blocksize))
		return INVALID_DYNAMIC_OBJECT;
	
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
		return INVALID_DYNAMIC_OBJECT;
	}
}

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
		if (value == INVALID_DYNAMIC_OBJECT)
			return false;
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return GetNativeCell(3);
	}
}

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
		if (value == INVALID_DYNAMIC_OBJECT)
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

public int Native_Dynamic_GetCollectionSize(Handle plugin, int params)
{
	return s_CollectionSize;
}

public int Native_Dynamic_GetMemberCount(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	return GetMemberCount(index);
}

public int Native_Dynamic_HookChanges(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	AddToForward(GetArrayCell(s_Collection, index, Dynamic_Forwards), plugin, GetNativeCell(2));
	
	int count = GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, ++count, Dynamic_CallbackCount);
	return 1;
}

public int Native_Dynamic_UnHookChanges(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	RemoveFromForward(GetArrayCell(s_Collection, index, Dynamic_Forwards), plugin, GetNativeCell(2));
	
	int count = GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, --count, Dynamic_CallbackCount);
	return 1;
}

public int Native_Dynamic_CallbackCount(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	return GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
}

public int Native_Dynamic_GetMemberOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	
	Handle offsets = GetArrayCell(s_Collection, index, Dynamic_Offsets);
	int offset;
	if (GetTrieValue(offsets, membername, offset))
		return offset;
	
	return INVALID_DYNAMIC_OFFSET;
}

public int Native_Dynamic_GetMemberOffsetByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	int memberindex = GetNativeCell(2);
	return GetMemberOffsetByIndex(index, memberindex);
}

public int GetMemberOffsetByIndex(int index, int memberindex)
{
	Handle memberoffsets = GetArrayCell(s_Collection, index, Dynamic_MemberOffsets);
	int membercount = GetArraySize(memberoffsets);
	
	if (memberindex < membercount)
		return GetArrayCell(memberoffsets, memberindex);
	else
		return INVALID_DYNAMIC_OFFSET;
}

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


// native Dynamic_MemberType Dynamic_GetMemberNameByIndex(Dynamic obj, int index, char[] buffer, int size);
public int Native_Dynamic_GetMemberNameByIndex(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	int memberindex = GetNativeCell(2);
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	int membercount = GetArraySize(membernames);
	
	if (memberindex >= membercount)
	{
		SetNativeString(3, "", 1);
		return 0;
	}
	
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetArrayString(membernames, memberindex, membername, sizeof(membername));
	SetNativeString(3, membername, GetNativeCell(4));
	return 1;
}

//native bool Dynamic_GetMemberNameByOffset(Dynamic obj, int offset, char[] buffer, int size);
public int Native_Dynamic_GetMemberNameByOffset(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValid(index, true))
		return 0;
	
	int offset = GetNativeCell(2);
	
	Handle membernames = GetArrayCell(s_Collection, index, Dynamic_MemberNames);
	Handle memberoffsets = GetArrayCell(s_Collection, index, Dynamic_MemberOffsets);
	int membercount = GetArraySize(membernames);
	
	for (int i = 0; i < membercount; i++)
	{
		if (GetArrayCell(memberoffsets, i) == offset)
		{
			char membername[DYNAMIC_MEMBERNAME_MAXLEN];
			GetArrayString(membernames, i, membername, sizeof(membername));
			SetNativeString(3, membername, GetNativeCell(4));
			return 1;
		}
	}
	return 0;
}

//native Dynamic_SortMembers(Dynamic obj, SortOrder order);
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
	Handle offsets = GetArrayCell(s_Collection, index, Dynamic_MemberOffsets);
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
	ClearArray(offsets);
	
	// Rebuild member lookup arrays based on sorted membernames
	for (int memberindex = 0; memberindex < count; memberindex++)
	{
		if (!GetTrieValue(offsetstrie, membernames[memberindex], offset))
			continue;
		
		PushArrayString(members, membernames[memberindex]);
		PushArrayCell(offsets, offset);
	}
	return 1;
}

stock int GetFieldIndex(Handle array, const char[] fieldname)
{
	int length = GetArraySize(array);
	
	for (int i; i < length; i++)
	{
		if (StrEqualEx(array, i, fieldname))
			return i;
	}
	
	return -1;
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