#if defined _dynamic_included_
  #endinput
#endif
#define _dynamic_included_

#define MAX_FIELDNAME_SIZE				64

enum Dynamic_FieldType
{
	DynamicType_Int,
	DynamicType_Float,
	DynamicType_String,
	DynamicType_Unknown
}

typeset DynamicHookCB
{
	function void (int index, const char[] fieldnname, Dynamic_FieldType type);
}

native int Dynamic_Initialise(int maxstringsize=64);
native bool Dynamic_Dispose(int index);
native int Dynamic_GetInt(int index, const char[] fieldname, int defaultvalue=-1);
native bool Dynamic_SetInt(int index, const char[] fieldname, int value);
native float Dynamic_GetFloat(int index, const char[] fieldname, float defaultvalue=-1.0);
native bool Dynamic_SetFloat(int index, const char[] fieldname, float value);
native float Dynamic_GetString(int index, const char[] fieldname, char[] buffer, int size);
native bool Dynamic_SetString(int index, const char[] fieldname, const char[] value);
native int Dynamic_GetCollectionSize();
native bool Dynamic_GetFieldCount(int index);
native bool Dynamic_IsValidCollectionIndex(int index, bool throwerror=false);
native bool Dynamic_HookChanges(int index, DynamicHookCB callback);
native bool Dynamic_UnHookChanges(int index, DynamicHookCB callback);
native Dynamic_FieldType Dynamic_GetFieldType(int index, const char[] fieldname);
native Dynamic_FieldType Dynamic_GetFieldName(int index, int field, char[] buffer, int size);

methodmap Dynamic
{
	public Dynamic(int maxstringsize=64)
	{
		return view_as<Dynamic>(Dynamic_Initialise(maxstringsize));
	}
	
	property int IsValid
	{
		public get()
		{
			return Dynamic_IsValidCollectionIndex(view_as<int>(this), false);
		}
	}
	
	property int FieldCount
	{
		public get()
		{
			return Dynamic_GetFieldCount(view_as<int>(this));
		}
	}
	
	public void Dispose()
	{
		Dynamic_Dispose(view_as<int>(this));
	}
	
	public int GetInt(const char[] fieldname, int defaultvalue=-1)
	{
		return Dynamic_GetInt(view_as<int>(this), fieldname, defaultvalue);
	}
	
	public void SetInt(const char[] fieldname, int value)
	{
		Dynamic_SetInt(view_as<int>(this), fieldname, value);
	}
	
	public float GetFloat(const char[] fieldname, float defaultvalue=-1.0)
	{
		return Dynamic_GetFloat(view_as<int>(this), fieldname, defaultvalue);
	}
	
	public void SetFloat(const char[] fieldname, float value)
	{
		Dynamic_SetFloat(view_as<int>(this), fieldname, value);
	}
	
	public bool GetString(const char[] fieldname, char[] buffer, int size)
	{
		return view_as<bool>(Dynamic_GetString(view_as<int>(this), fieldname, buffer, size));
	}
	
	public void SetString(const char[] fieldname, const char[] value)
	{
		Dynamic_SetString(view_as<int>(this), fieldname, value);
	}
	
	public void HookChanges(DynamicHookCB callback)
	{
		Dynamic_HookChanges(view_as<int>(this), callback);	
	}
	
	public void UnHookChanges(DynamicHookCB callback)
	{
		Dynamic_UnHookChanges(view_as<int>(this), callback);	
	}

	public Dynamic_FieldType GetFieldType(const char[] fieldname)
	{
		return Dynamic_GetFieldType(view_as<int>(this), fieldname);
	}
	
	public Dynamic_FieldType GetFieldName(int field, char[] buffer, int size)
	{
		return Dynamic_GetFieldName(view_as<int>(this), field, buffer, size);
	}
}

#if !defined REQUIRE_PLUGIN
public __pl_dynamic_SetNTVOptional()
{
	MarkNativeAsOptional("Dynamic_Initialise");
	MarkNativeAsOptional("Dynamic_Dispose");
	MarkNativeAsOptional("Dynamic_GetInt");
	MarkNativeAsOptional("Dynamic_SetInt");
	MarkNativeAsOptional("Dynamic_GetFloat");
	MarkNativeAsOptional("Dynamic_SetFloat");
	MarkNativeAsOptional("Dynamic_GetString");
	MarkNativeAsOptional("Dynamic_SetString");
	MarkNativeAsOptional("Dynamic_GetCollectionSize");
	MarkNativeAsOptional("Dynamic_GetFieldCount");
	MarkNativeAsOptional("Dynamic_IsValidCollectionIndex");
	MarkNativeAsOptional("Dynamic_HookChanges");
	MarkNativeAsOptional("Dynamic_UnHookChanges");
	MarkNativeAsOptional("Dynamic_GetFieldType");
	MarkNativeAsOptional("Dynamic_GetFieldName");
}
#endif

public SharedPlugin __pl_dynamic = 
{
	name = "dynamic",
	file = "dynamic.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};