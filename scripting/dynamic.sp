#include <dynamic>
#pragma semicolon 1
#pragma newdecls required

static Handle s_Collection = null;
static int s_CollectionSize = 0;
static Handle s_FreeIndicies = null;

public Plugin myinfo =
{
	name = "Dynamic",
	author = "Neuro Toxin",
	description = "Shared Dynamic Objects for Sourcepawn",
	version = "0.0.2",
	url = ""
}

#define Dynamic_Index					0
#define Dynamic_Size					1
#define Dynamic_Blocksize				2
#define Dynamic_Data					3
#define Dynamic_Forwards				4
#define Dynamic_MemberCount				5
#define Dynamic_Field_Count				6

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Register plugin and natives
	RegPluginLibrary("dynamic");
	CreateNative("Dynamic_Initialise", Native_Dynamic_Initialise);
	CreateNative("Dynamic_Dispose", Native_Dynamic_Dispose);
	CreateNative("Dynamic_GetInt", Native_Dynamic_GetInt);
	CreateNative("Dynamic_SetInt", Native_Dynamic_SetInt);
	CreateNative("Dynamic_GetFloat", Native_Dynamic_GetFloat);
	CreateNative("Dynamic_SetFloat", Native_Dynamic_SetFloat);
	CreateNative("Dynamic_GetString", Native_Dynamic_GetString);
	CreateNative("Dynamic_SetString", Native_Dynamic_SetString);
	CreateNative("Dynamic_GetCollectionSize", Native_Dynamic_GetCollectionSize);
	CreateNative("Dynamic_GetMemberCount", Native_Dynamic_GetMemberCount);
	CreateNative("Dynamic_IsValidCollectionIndex", Native_Dynamic_IsValidCollectionIndex);
	CreateNative("Dynamic_HookChanges", Native_Dynamic_HookChanges);
	CreateNative("Dynamic_UnHookChanges", Native_Dynamic_UnHookChanges);
	CreateNative("Dynamic_GetMemberType", Native_Dynamic_GetMemberType);
	CreateNative("Dynamic_GetMemberName", Native_Dynamic_GetMemberName);
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Initialise static plugin data
	s_Collection = CreateArray(Dynamic_Field_Count);
	s_CollectionSize = 0;
	s_FreeIndicies = CreateStack();
}

public void OnPluginEnd()
{
	// Dipose of all objects in the collection pool
	while (s_CollectionSize > 0)
	{
		Dynamic_Dispose(s_CollectionSize - 1);
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
	SetArrayCell(s_Collection, index, CreateArray(blocksize, startsize), Dynamic_Data);
	SetArrayCell(s_Collection, index, CreateForward(ET_Ignore, Param_Cell, Param_String, Param_Cell), Dynamic_Forwards);
	SetArrayCell(s_Collection, index, 0, Dynamic_MemberCount);
	
	// Return the next index
	return index;
}

public int Native_Dynamic_Dispose(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index))
		return 0;
	
	// Close data dynamic object array handles
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_Data));
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_Forwards));
	
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

public int Native_Dynamic_IsValidCollectionIndex(Handle plugin, int params)
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
	int membercount = GetMemberCount(index);
	
	//int baseoffset = 0;
	Dynamic_MemberType type;
	
	position = 0;
	offset = 0;
	char letter;
	int charoffset = 0;
	
	//PrintToServer("Matching member %s", membername);
	
	// Loop through each member
	for (int member = 0; member < membercount; member++)
	{
		//PrintToServer("-> member baseoffset: %d", offset);
		if (offset > 0)
			charoffset = offset * 4;
		else
			charoffset = 0;
		
		// Check for membername (StrEqual)
		for (int i = 0; i < MAX_FIELDNAME_SIZE; i++)
		{
			// Check if the current char (i) matches
			letter = membername[i];
			//PrintToServer("Checking -> %d == %d", letter, GetArrayCell(array, position, offset, true));
			
			if (letter != GetArrayCell(array, position, charoffset, true))
			{
				charoffset-=i;
				RecalculateOffset(array, position, charoffset, blocksize, false, true);
				break; // Go find next membername offset
			}
			
			// Check if the membername string is finished
			if (letter == 0)
				return true;
			
			charoffset++;
			RecalculateOffset(array, position, charoffset, blocksize, false, true);
		}
		
		// Member didnt match, get next base offset
		type = GetMemberType(array, position, offset, blocksize);
		if (type == DynamicType_String)
		{
			offset += ByteCountToCells(MAX_FIELDNAME_SIZE) + 1 + 
				ByteCountToCells(GetMemberStringLength(array, position, offset, blocksize));
			RecalculateOffset(array, position, offset, blocksize);
		}
		else
		{
			offset += ByteCountToCells(MAX_FIELDNAME_SIZE) + 2;
			RecalculateOffset(array, position, offset, blocksize);
		}
	}
	
	if (!create)
		return false;
		
	int length = GetArraySize(array);
	
	// Create new entry
	if (newtype == DynamicType_String)
	{
		if (stringlength == 0)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "You must set a strings length when you initialise it");
			return false;
		}
		
		ExpandIfRequired(array, position, offset, blocksize, stringlength);
		SetMemberName(array, position, offset, blocksize, membername);
		SetMemberType(array, position, offset, blocksize, newtype);
		SetMemberCount(index, membercount+1);
		SetMemberStringLength(array, position, offset, blocksize, stringlength);
		return true;
	}
	
	ExpandIfRequired(array, position, offset, blocksize, length);
	SetMemberName(array, position, offset, blocksize, membername);
	SetMemberType(array, position, offset, blocksize, newtype);
	SetMemberCount(index, membercount+1);
	return true;
}

stock void RecalculateOffset(Handle array, int &position, int &offset, int blocksize, bool expand=false, bool aschar=false)
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
}

stock void ExpandIfRequired(Handle array, int position, int offset, int blocksize, int length=1)
{
	offset += ByteCountToCells(MAX_FIELDNAME_SIZE) + length + 1;
	RecalculateOffset(array, position, offset, blocksize, true);
}

stock void SetMemberName(Handle array, int position, int offset, int blocksize, const char[] membername)
{
	//PrintToServer("SetMemberName(position=%d, offset=%d, blocksize=%d, membername=%s)", position, offset, blocksize, membername);
	
	offset*=4;
	char letter;
	for (int i = 0; i < MAX_FIELDNAME_SIZE; i++)
	{
		letter = membername[i];
		//PrintToServer("-> setting [%d] = %d", i, letter);
		SetArrayCell(array, position, letter, offset, true);
		offset++;
		RecalculateOffset(array, position, offset, blocksize, false, true);
		
		if (letter == 0)
			return;
	}
	
	offset--;
	RecalculateOffset(array, position, offset, blocksize, false, true);
	SetArrayCell(array, position, 0, offset, true);
}

stock Dynamic_MemberType GetMemberType(Handle array, int position, int offset, int blocksize)
{
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE);
	RecalculateOffset(array, position, offset, blocksize);
	
	int type = GetArrayCell(array, position, offset);
	//PrintToServer("GetMemberType(position=%d, offset=%d, blocksize=%d)=%d", position, offset, blocksize, type);
	return view_as<Dynamic_MemberType>(type);
}

stock void SetMemberType(Handle array, int position, int offset, int blocksize, Dynamic_MemberType type)
{
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE);
	RecalculateOffset(array, position, offset, blocksize);
	//PrintToServer("SetMemberType(position=%d, offset=%d, blocksize=%d, type=%d)", position, offset, blocksize, view_as<int>(type));
	SetArrayCell(array, position, type, offset);
}

stock int GetMemberStringLength(Handle array, int position, int offset, int blocksize)
{
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE)+1;
	RecalculateOffset(array, position, offset, blocksize);
	//PrintToServer("GetMemberStringLength(position=%d, offset=%d, blocksize=%d)=%d", position, offset, blocksize, GetArrayCell(array, position, offset));
	return GetArrayCell(array, position, offset);
}

stock void SetMemberStringLength(Handle array, int position, int offset, int blocksize, int length)
{
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE)+1;
	RecalculateOffset(array, position, offset, blocksize);
	//PrintToServer("SetMemberStringLength(position=%d, offset=%d, blocksize=%d, length=%d)", position, offset, blocksize, length);
	SetArrayCell(array, position, length, offset);
}

stock int GetMemberDataInt(Handle array, int position, int offset, int blocksize)
{
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE)+1;
	RecalculateOffset(array, position, offset, blocksize);
	//PrintToServer("GetMemberDataInt(position=%d, offset=%d, blocksize=%d)=%d", position, offset, blocksize, GetArrayCell(array, position, offset));
	return GetArrayCell(array, position, offset);
}

stock void SetMemberDataInt(Handle array, int position, int offset, int blocksize, int value)
{
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE)+1;
	RecalculateOffset(array, position, offset, blocksize);
	SetArrayCell(array, position, value, offset);
	//PrintToServer("SetMemberDataInt(position=%d, offset=%d, blocksize=%d, value=%d)", position, offset, blocksize, value);
}

stock float GetMemberDataFloat(Handle array, int position, int offset, int blocksize)
{
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE)+1;
	RecalculateOffset(array, position, offset, blocksize);
	//PrintToServer("GetMemberDataFloat(position=%d, offset=%d, blocksize=%d)=%f", position, offset, blocksize, GetArrayCell(array, position, offset));
	return GetArrayCell(array, position, offset);
}

stock void SetMemberDataFloat(Handle array, int position, int offset, int blocksize, float value)
{
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE)+1;
	RecalculateOffset(array, position, offset, blocksize);
	SetArrayCell(array, position, value, offset);
	//PrintToServer("SetMemberDataFloat(position=%d, offset=%d, blocksize=%d, value=%f)", position, offset, blocksize, value);
}

stock void GetMemberDataString(Handle array, int position, int offset, int blocksize, char[] buffer, int length)
{
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE)+2;
	RecalculateOffset(array, position, offset, blocksize, true);
	
	//PrintToServer("GetMemberDataString(position=%d, offset=%d, blocksize=%d)", position, offset, blocksize, buffer);
	offset*=4;
	
	int i; char letter;
	for (i=0; i < length; i++)
	{
		letter = view_as<char>(GetArrayCell(array, position, offset, true));
		buffer[i] = letter;
		//PrintToServer("-> setting [%d] = %d", i, letter);
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
	
	offset+=ByteCountToCells(MAX_FIELDNAME_SIZE)+2;
	RecalculateOffset(array, position, offset, blocksize);
	
	//PrintToServer("SetMemberDataString(position=%d, offset=%d, blocksize=%d, value='%s', length=%d)", position, offset, blocksize, buffer, length);
	offset*=4;
	
	int i;
	char letter;
	for (i=0; i < length; i++)
	{
		letter = buffer[i];
		//PrintToServer("-> [%d, %d] = setting [%d] = %d", position, offset, i, letter);
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
	//PrintToServer("GetMemberCount(index=%d)=%d", index, GetArrayCell(s_Collection, index, Dynamic_MemberCount));
	return GetArrayCell(s_Collection, index, Dynamic_MemberCount);
}

stock int SetMemberCount(int index, int count)
{
	//PrintToServer("SetMemberCount(index=%d, value=%d)", index, count);
	SetArrayCell(s_Collection, index, count, Dynamic_MemberCount);
}

// native int Dynamic_GetInt(int index, const char[] membername, int defaultvalue=-1);
public int Native_Dynamic_GetInt(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return GetNativeCell(3);
	
	char membername[MAX_FIELDNAME_SIZE];
	GetNativeString(2, membername, MAX_FIELDNAME_SIZE);
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Int))
		return GetNativeCell(3);
		
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Int)
		return GetMemberDataInt(data, position, offset, blocksize);
	else if (type == DynamicType_Float)
		return RoundToFloor(GetMemberDataFloat(data, position, offset, blocksize));
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(data, position, offset, blocksize, buffer, length);
		return StringToInt(buffer);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return GetNativeCell(3);
	}
}

// native bool Dynamic_SetInt(int index, const char[] membername, int value);
public int Native_Dynamic_SetInt(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	char membername[MAX_FIELDNAME_SIZE];
	GetNativeString(2, membername, MAX_FIELDNAME_SIZE);
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Int))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Int)
	{
		SetMemberDataInt(data, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForward(index, membername, DynamicType_Int);
		return 1;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(data, position, offset, blocksize, float(GetNativeCell(3)));
		CallOnChangedForward(index, membername, DynamicType_Float);
		return 1;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		IntToString(GetNativeCell(3), buffer, length);
		SetMemberDataString(data, position, offset, blocksize, buffer);
		CallOnChangedForward(index, membername, DynamicType_String);
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
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return GetNativeCell(3);
	
	char membername[MAX_FIELDNAME_SIZE];
	GetNativeString(2, membername, MAX_FIELDNAME_SIZE);
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Float))
		return GetNativeCell(3);
		
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
		return view_as<int>(GetMemberDataFloat(data, position, offset, blocksize));
	else if (type == DynamicType_Int)
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
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	char membername[MAX_FIELDNAME_SIZE];
	GetNativeString(2, membername, MAX_FIELDNAME_SIZE);
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Float))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
	{
		SetMemberDataFloat(data, position, offset, blocksize, GetNativeCell(3));
		CallOnChangedForward(index, membername, DynamicType_Float);
		return 1;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(data, position, offset, blocksize, RoundToFloor(GetNativeCell(3)));
		CallOnChangedForward(index, membername, DynamicType_Int);
		return 1;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		FloatToString(GetNativeCell(3), buffer, length);
		SetMemberDataString(data, position, offset, blocksize, buffer);
		CallOnChangedForward(index, membername, DynamicType_String);
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
	if (!Dynamic_IsValidCollectionIndex(index, true))
	{
		SetNativeString(3, "", 1);
		return 0;
	}
	
	char membername[MAX_FIELDNAME_SIZE];
	GetNativeString(2, membername, MAX_FIELDNAME_SIZE);
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
		//PrintToServer("-> '%s'", buffer);
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
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	char membername[MAX_FIELDNAME_SIZE];
	GetNativeString(2, membername, MAX_FIELDNAME_SIZE);
	Handle data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_String, GetNativeCell(4)))
		return 0;
	
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		int length; GetNativeStringLength(3, length);
		length++;
		char[] buffer = new char[length];
		GetNativeString(3, buffer, length);
		SetMemberDataString(data, position, offset, blocksize, buffer);
		CallOnChangedForward(index, membername, DynamicType_String);
		return 1;
	}
	else if (type == DynamicType_Int)
	{
		int length; GetNativeStringLength(3, length);
		length++;
		char[] buffer = new char[length];
		GetNativeString(3, buffer, length);
		SetMemberDataInt(data, position, offset, blocksize, StringToInt(buffer));
		CallOnChangedForward(index, membername, DynamicType_Int);
		return 1;
	}
	else if (type == DynamicType_Float)
	{
		int length; GetNativeStringLength(3, length);
		length++;
		char[] buffer = new char[length];
		GetNativeString(3, buffer, length);
		SetMemberDataFloat(data, position, offset, blocksize, StringToFloat(buffer));
		CallOnChangedForward(index, membername, DynamicType_Float);
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
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	return GetMemberCount(index);
}

public int Native_Dynamic_HookChanges(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	AddToForward(GetArrayCell(s_Collection, index, Dynamic_Forwards), plugin, GetNativeCell(2));
	return 1;
}

public int Native_Dynamic_UnHookChanges(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	RemoveFromForward(GetArrayCell(s_Collection, index, Dynamic_Forwards), plugin, GetNativeCell(2));
	return 1;
}

public int Native_Dynamic_GetMemberType(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	char name[MAX_FIELDNAME_SIZE];
	GetNativeString(2, name, MAX_FIELDNAME_SIZE);
	
	return view_as<int>(DynamicType_Unknown);
}

public int Native_Dynamic_GetMemberName(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	/*int field = GetNativeCell(1);
	char buffer[MAX_FIELDNAME_SIZE] = "";
	SetNativeString(3, buffer, GetNativeCell(4));*/
	return view_as<int>(DynamicType_Unknown);
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
	for (int i = 0; i < MAX_FIELDNAME_SIZE; i++)
	{
		if (GetArrayCell(array, index, i, true) != fieldname[i])
			return false;
	
		if (fieldname[i] == 0)
			return true;
	}
	return false;
}

stock void CallOnChangedForward(int index, const char[] fieldname, Dynamic_MemberType type)
{
	Call_StartForward(GetArrayCell(s_Collection, index, Dynamic_Forwards));
	Call_PushCell(index);
	Call_PushString(fieldname);
	Call_PushCell(type);
	Call_Finish();
}