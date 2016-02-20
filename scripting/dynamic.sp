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
	version = "0.0.1",
	url = ""
}

#define Dynamic_Index					0
#define Dynamic_MaxStringSize			1
#define Dynamic_Int_Names				2
#define Dynamic_Int_Values				3
#define Dynamic_Float_Names				4
#define Dynamic_Float_Values			5
#define Dynamic_String_Names			6
#define Dynamic_String_Values			7
#define Dynamic_Forwards				8
#define Dynamic_Field_Count				9

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
	CreateNative("Dynamic_GetFieldCount", Native_Dynamic_GetFieldCount);
	CreateNative("Dynamic_IsValidCollectionIndex", Native_Dynamic_IsValidCollectionIndex);
	CreateNative("Dynamic_HookChanges", Native_Dynamic_HookChanges);
	CreateNative("Dynamic_UnHookChanges", Native_Dynamic_UnHookChanges);
	CreateNative("Dynamic_GetFieldType", Native_Dynamic_GetFieldType);
	CreateNative("Dynamic_GetFieldName", Native_Dynamic_GetFieldName);
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
	int maxstringsize = GetNativeCell(1);
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
	SetArrayCell(s_Collection, index, maxstringsize, Dynamic_MaxStringSize);
	
	// Create dynamic object arrays
	// Note: Each type has it's own field collection. I've done this to reduce memory usage as string
	//		 collections can require heaps more memory (stacksize)
	SetArrayCell(s_Collection, index, CreateArray(MAX_FIELDNAME_SIZE), Dynamic_Int_Names);
	SetArrayCell(s_Collection, index, CreateArray(), Dynamic_Int_Values);
	SetArrayCell(s_Collection, index, CreateArray(MAX_FIELDNAME_SIZE), Dynamic_Float_Names);
	SetArrayCell(s_Collection, index, CreateArray(), Dynamic_Float_Values);
	SetArrayCell(s_Collection, index, CreateArray(MAX_FIELDNAME_SIZE), Dynamic_String_Names);
	SetArrayCell(s_Collection, index, CreateArray(maxstringsize), Dynamic_String_Values);
	SetArrayCell(s_Collection, index, CreateForward(ET_Ignore, Param_Cell, Param_String, Param_Cell), Dynamic_Forwards);
	
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
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_Int_Names));
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_Int_Values));
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_Float_Names));
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_Float_Values));
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_String_Names));
	CloseHandle(GetArrayCell(s_Collection, index, Dynamic_String_Values));
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

public int Native_Dynamic_GetInt(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return GetNativeCell(3);
	
	char name[MAX_FIELDNAME_SIZE];
	GetNativeString(2, name, MAX_FIELDNAME_SIZE);
	
	Handle names = GetArrayCell(s_Collection, index, Dynamic_Int_Names);
	int fieldindex = GetFieldIndex(names, name);
	Handle values;
	
	if (fieldindex == -1)
	{
		// Check for float
		names = GetArrayCell(s_Collection, index, Dynamic_Float_Names);
		fieldindex = GetFieldIndex(names, name);
		if (fieldindex > -1)
		{
			// Convert float to int
			values = GetArrayCell(s_Collection, index, Dynamic_Float_Values);
			return RoundToFloor(GetArrayCell(values, fieldindex));
		}
		else
		{
			// Check for string
			names = GetArrayCell(s_Collection, index, Dynamic_String_Names);
			fieldindex = GetFieldIndex(names, name);
			
			if (fieldindex > -1)
			{
				// Convert string to int
				values = GetArrayCell(s_Collection, index, Dynamic_String_Values);
				int length = GetArrayCell(s_Collection, index, Dynamic_MaxStringSize);
				char[] buffer = new char[length];
				
				GetArrayString(values, fieldindex, buffer, length);
				return StringToInt(buffer);
			}
			else
				return GetNativeCell(3);
		}
	}
	
	values = GetArrayCell(s_Collection, index, Dynamic_Int_Values);
	return GetArrayCell(values, fieldindex);
}

public int Native_Dynamic_SetInt(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
		
	char name[MAX_FIELDNAME_SIZE];
	GetNativeString(2, name, MAX_FIELDNAME_SIZE);
	
	Handle names = GetArrayCell(s_Collection, index, Dynamic_Int_Names);
	Handle values = GetArrayCell(s_Collection, index, Dynamic_Int_Values);
	int fieldindex = GetFieldIndex(names, name);
	int value = GetNativeCell(3);
	
	if (fieldindex > -1)
	{
		SetArrayCell(values, fieldindex, value);
		CallOnChangedForward(index, name, DynamicType_Int);
	}
	else
	{
		// Check for float
		Handle names1 = GetArrayCell(s_Collection, index, Dynamic_Float_Names);
		fieldindex = GetFieldIndex(names1, name);
		if (fieldindex > -1)
		{
			// Convert int to float
			values = GetArrayCell(s_Collection, index, Dynamic_Float_Values);
			SetArrayCell(values, fieldindex, float(value));
			CallOnChangedForward(index, name, DynamicType_Float);
		}
		else
		{
			// Check for string
			names1 = GetArrayCell(s_Collection, index, Dynamic_String_Names);
			fieldindex = GetFieldIndex(names1, name);
			if (fieldindex > -1)
			{
				// Convert int to string
				values = GetArrayCell(s_Collection, index, Dynamic_String_Values);
				int length = GetArrayCell(s_Collection, index, Dynamic_MaxStringSize);
				char[] buffer = new char[length];
				IntToString(value, buffer, length);
				SetArrayString(values, fieldindex, buffer);
				CallOnChangedForward(index, name, DynamicType_String);
			}
			else
			{
				PushArrayString(names, name);
				PushArrayCell(values, value);
				CallOnChangedForward(index, name, DynamicType_Int);
			}
		}
	}
	return 1;
}

public int Native_Dynamic_GetFloat(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return GetNativeCell(3);
	
	char name[MAX_FIELDNAME_SIZE];
	GetNativeString(2, name, MAX_FIELDNAME_SIZE);
	
	Handle names = GetArrayCell(s_Collection, index, Dynamic_Float_Names);
	int fieldindex = GetFieldIndex(names, name);
	Handle values;
	
	if (fieldindex == -1)
	{
		// Check for int
		names = GetArrayCell(s_Collection, index, Dynamic_Int_Names);
		fieldindex = GetFieldIndex(names, name);
		
		if (fieldindex > -1)
		{
			// Convert int to float
			values = GetArrayCell(s_Collection, index, Dynamic_Int_Values);
			return view_as<int>(float(GetArrayCell(values, fieldindex)));
		}
		else
		{
			// Check for string
			names = GetArrayCell(s_Collection, index, Dynamic_String_Names);
			fieldindex = GetFieldIndex(names, name);
			
			if (fieldindex > -1)
			{
				// Convert string to float
				values = GetArrayCell(s_Collection, index, Dynamic_String_Values);
				int length = GetArrayCell(s_Collection, index, Dynamic_MaxStringSize);
				char[] buffer = new char[length];
				
				GetArrayString(values, fieldindex, buffer, length);
				return view_as<int>(StringToFloat(buffer));
			}
			else
				return GetNativeCell(3);
		}
	}
	
	values = GetArrayCell(s_Collection, index, Dynamic_Float_Values);
	return GetArrayCell(values, fieldindex);
}

public int Native_Dynamic_SetFloat(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
		
	char name[MAX_FIELDNAME_SIZE];
	GetNativeString(2, name, MAX_FIELDNAME_SIZE);
	
	Handle names = GetArrayCell(s_Collection, index, Dynamic_Float_Names);
	Handle values = GetArrayCell(s_Collection, index, Dynamic_Float_Values);
	int fieldindex = GetFieldIndex(names, name);
	float value = GetNativeCell(3);
	
	if (fieldindex > -1)
	{
		SetArrayCell(values, fieldindex, value);
		CallOnChangedForward(index, name, DynamicType_Float);
	}
	else
	{
		// Check for int
		Handle names1 = GetArrayCell(s_Collection, index, Dynamic_Int_Names);
		fieldindex = GetFieldIndex(names1, name);
		if (fieldindex > -1)
		{
			// Convert float to int
			values = GetArrayCell(s_Collection, index, Dynamic_Int_Values);
			SetArrayCell(values, fieldindex, RoundToFloor(value));
			CallOnChangedForward(index, name, DynamicType_Int);
		}
		else
		{
			// Check for string
			names1 = GetArrayCell(s_Collection, index, Dynamic_String_Names);
			fieldindex = GetFieldIndex(names1, name);
			if (fieldindex > -1)
			{
				// Convert float to string
				values = GetArrayCell(s_Collection, index, Dynamic_String_Values);
				int length = GetArrayCell(s_Collection, index, Dynamic_MaxStringSize);
				char[] buffer = new char[length];
				FloatToString(value, buffer, length);
				SetArrayString(values, fieldindex, buffer);
				CallOnChangedForward(index, name, DynamicType_String);
			}
			else
			{
				PushArrayString(names, name);
				PushArrayCell(values, value);
				CallOnChangedForward(index, name, DynamicType_Float);
			}
		}
	}
	return 1;
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
	
	char name[MAX_FIELDNAME_SIZE];
	GetNativeString(2, name, MAX_FIELDNAME_SIZE);
	
	Handle names = GetArrayCell(s_Collection, index, Dynamic_String_Names);
	int fieldindex = GetFieldIndex(names, name);
	Handle values;
	
	if (fieldindex == -1)
	{
		// Check for int
		names = GetArrayCell(s_Collection, index, Dynamic_Int_Names);
		fieldindex = GetFieldIndex(names, name);
		
		if (fieldindex > -1)
		{
			// Convert int to string
			values = GetArrayCell(s_Collection, index, Dynamic_Int_Values);
			int size = GetNativeCell(4);
			char[] buffer = new char[size];
			IntToString(GetArrayCell(values, fieldindex), buffer, size);
			SetNativeString(3, buffer, size);
			return 1;
		}
		else
		{
			// Check for float
			names = GetArrayCell(s_Collection, index, Dynamic_Float_Names);
			fieldindex = GetFieldIndex(names, name);
			
			if (fieldindex > -1)
			{
				// Convert float to string
				values = GetArrayCell(s_Collection, index, Dynamic_Float_Values);
				int size = GetNativeCell(4);
				char[] buffer = new char[size];
				FloatToString(GetArrayCell(values, fieldindex), buffer, size);
				SetNativeString(3, buffer, size);
				return 1;
			}
			else
			{
				SetNativeString(3, "", 1);
				return 0;
			}
		}
	}
		
	int size = GetNativeCell(4);
	values = GetArrayCell(s_Collection, index, Dynamic_String_Values);
	
	char[] buffer = new char[size];
	GetArrayString(values, fieldindex, buffer, size);
	SetNativeString(3, buffer, size);
	return 1;
}

public int Native_Dynamic_SetString(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
		
	char name[MAX_FIELDNAME_SIZE];
	GetNativeString(2, name, MAX_FIELDNAME_SIZE);
	
	int size = GetArrayCell(s_Collection, index, Dynamic_MaxStringSize);
	char[] value = new char[size];
	GetNativeString(3, value, size);
	
	Handle names = GetArrayCell(s_Collection, index, Dynamic_String_Names);
	Handle values = GetArrayCell(s_Collection, index, Dynamic_String_Values);
	int fieldindex = GetFieldIndex(names, name);
	
	if (fieldindex > -1)
	{
		SetArrayString(values, fieldindex, value);
		CallOnChangedForward(index, name, DynamicType_String);
	}
	else
	{
		// Check for int
		Handle names1 = GetArrayCell(s_Collection, index, Dynamic_Int_Names);
		fieldindex = GetFieldIndex(names1, name);
		if (fieldindex > -1)
		{
			// Convert string to int
			values = GetArrayCell(s_Collection, index, Dynamic_Int_Values);
			SetArrayCell(values, fieldindex, StringToInt(value));
			CallOnChangedForward(index, name, DynamicType_Int);
		}
		else
		{
			// Check for float
			names1 = GetArrayCell(s_Collection, index, Dynamic_Float_Names);
			fieldindex = GetFieldIndex(names1, name);
			if (fieldindex > -1)
			{
				// Convert string to float
				values = GetArrayCell(s_Collection, index, Dynamic_Float_Values);
				SetArrayCell(values, fieldindex, StringToFloat(value));
				CallOnChangedForward(index, name, DynamicType_Float);
			}
			else
			{
				PushArrayString(names, name);
				PushArrayString(values, value);
				CallOnChangedForward(index, name, DynamicType_String);
			}
		}
	}
	return 1;
}

public int Native_Dynamic_GetCollectionSize(Handle plugin, int params)
{
	return s_CollectionSize;
}

public int Native_Dynamic_GetFieldCount(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	return GetArraySize(GetArrayCell(s_Collection, index, Dynamic_Int_Names)) +
			GetArraySize(GetArrayCell(s_Collection, index, Dynamic_Float_Names)) +
			GetArraySize(GetArrayCell(s_Collection, index, Dynamic_String_Names));
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

public int Native_Dynamic_GetFieldType(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
		
	char name[MAX_FIELDNAME_SIZE];
	GetNativeString(2, name, MAX_FIELDNAME_SIZE);
	
	// Check for int
	Handle names = GetArrayCell(s_Collection, index, Dynamic_Int_Names);
	int fieldindex = GetFieldIndex(names, name);
	if (fieldindex > -1)
		return view_as<int>(DynamicType_Int);
	
	// Check for float
	names = GetArrayCell(s_Collection, index, Dynamic_Float_Names);
	fieldindex = GetFieldIndex(names, name);
	if (fieldindex > -1)
		return view_as<int>(DynamicType_Float);
		
	// Check for string
	names = GetArrayCell(s_Collection, index, Dynamic_String_Names);
	fieldindex = GetFieldIndex(names, name);
	if (fieldindex > -1)
		return view_as<int>(DynamicType_String);
	
	return view_as<int>(DynamicType_Unknown);
}

public int Native_Dynamic_GetFieldName(Handle plugin, int params)
{
	// Get and validate index
	int index = GetNativeCell(1);
	if (!Dynamic_IsValidCollectionIndex(index, true))
		return 0;
	
	int field = GetNativeCell(1);
	char buffer[MAX_FIELDNAME_SIZE];
	
	// Check int
	Handle array = GetArrayCell(s_Collection, index, Dynamic_Int_Names);
	int count = GetArraySize(array);
	if (field < count)
	{
		GetArrayString(array, field, buffer, sizeof(buffer));
		SetNativeString(3, buffer, GetNativeCell(4));
		return view_as<int>(DynamicType_Int);
	}
	field -= count;
	
	// Check float
	array = GetArrayCell(s_Collection, index, Dynamic_Float_Names);
	count = GetArraySize(array);
	if (field < count)
	{
		GetArrayString(array, field, buffer, sizeof(buffer));
		SetNativeString(3, buffer, GetNativeCell(4));
		return view_as<int>(DynamicType_Float);
	}
	field -= count;
	
	// Check string
	array = GetArrayCell(s_Collection, index, Dynamic_String_Names);
	count = GetArraySize(array);
	if (field < count)
	{
		GetArrayString(array, field, buffer, sizeof(buffer));
		SetNativeString(3, buffer, GetNativeCell(4));
		return view_as<int>(DynamicType_String);
	}
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

stock void CallOnChangedForward(int index, const char[] fieldname, Dynamic_FieldType type)
{
	Call_StartForward(GetArrayCell(s_Collection, index, Dynamic_Forwards));
	Call_PushCell(index);
	Call_PushString(fieldname);
	Call_PushCell(type);
	Call_Finish();
}