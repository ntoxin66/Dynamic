#if defined _dynamic_included_
  #endinput
#endif
#define _dynamic_included_

#define MAX_FIELDNAME_SIZE				64

enum Dynamic_MemberType
{
	DynamicType_Int = 0,
	DynamicType_Float = 1,
	DynamicType_String = 2,
	DynamicType_Unknown = 3
}

typeset DynamicHookCB
{
	function void (int index, const char[] fieldnname, Dynamic_MemberType type);
}

native int Dynamic_Initialise(int blocksize=64, int startsize=0);
native bool Dynamic_Dispose(int index);
native int Dynamic_GetInt(int index, const char[] membername, int defaultvalue=-1);
native bool Dynamic_SetInt(int index, const char[] membername, int value);
native float Dynamic_GetFloat(int index, const char[] membername, float defaultvalue=-1.0);
native bool Dynamic_SetFloat(int index, const char[] membername, float value);
native float Dynamic_GetString(int index, const char[] membername, char[] buffer, int size);
native bool Dynamic_SetString(int index, const char[] membername, const char[] value, int length=0);
native int Dynamic_GetCollectionSize();
native bool Dynamic_GetMemberCount(int index);
native bool Dynamic_IsValidCollectionIndex(int index, bool throwerror=false);
native bool Dynamic_HookChanges(int index, DynamicHookCB callback);
native bool Dynamic_UnHookChanges(int index, DynamicHookCB callback);
native int Dynamic_GetMemberOffset(int index, const char[] membername);
native Dynamic_MemberType Dynamic_GetMemberType(int index, int offset);
native Dynamic_MemberType Dynamic_GetMemberName(int index, int offset, char[] buffer, int size);

methodmap Dynamic
{
	public Dynamic(int blocksize=64, int startsize=0)
	{
		return view_as<Dynamic>(Dynamic_Initialise(blocksize, startsize));
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
			return Dynamic_GetMemberCount(view_as<int>(this));
		}
	}
	
	public void Dispose()
	{
		Dynamic_Dispose(view_as<int>(this));
	}
	
	public int GetInt(const char[] membername, int defaultvalue=-1)
	{
		return Dynamic_GetInt(view_as<int>(this), membername, defaultvalue);
	}
	
	public void SetInt(const char[] membername, int value)
	{
		Dynamic_SetInt(view_as<int>(this), membername, value);
	}
	
	public float GetFloat(const char[] membername, float defaultvalue=-1.0)
	{
		return Dynamic_GetFloat(view_as<int>(this), membername, defaultvalue);
	}
	
	public void SetFloat(const char[] membername, float value)
	{
		Dynamic_SetFloat(view_as<int>(this), membername, value);
	}
	
	public bool GetString(const char[] membername, char[] buffer, int length)
	{
		return view_as<bool>(Dynamic_GetString(view_as<int>(this), membername, buffer, length));
	}
	
	public void SetString(const char[] membername, const char[] value, int length=0)
	{
		Dynamic_SetString(view_as<int>(this), membername, value, length);
	}
	
	public void HookChanges(DynamicHookCB callback)
	{
		Dynamic_HookChanges(view_as<int>(this), callback);	
	}
	
	public void UnHookChanges(DynamicHookCB callback)
	{
		Dynamic_UnHookChanges(view_as<int>(this), callback);	
	}
	
	public int GetMemberOffset(const char[] membername)
	{
		return Dynamic_GetMemberOffset(view_as<int>(this), membername);
	}

	public Dynamic_MemberType GetMemberType(int offset)
	{
		return Dynamic_GetMemberType(view_as<int>(this), offset);
	}
	
	public Dynamic_MemberType GetMemberName(int offset, char[] buffer, int length)
	{
		return Dynamic_GetMemberName(view_as<int>(this), offset, buffer, length);
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
	MarkNativeAsOptional("Dynamic_GetMemberCount");
	MarkNativeAsOptional("Dynamic_IsValidCollectionIndex");
	MarkNativeAsOptional("Dynamic_HookChanges");
	MarkNativeAsOptional("Dynamic_UnHookChanges");
	MarkNativeAsOptional("Dynamic_GetMemberOffset");
	MarkNativeAsOptional("Dynamic_GetMemberType");
	MarkNativeAsOptional("Dynamic_GetMemberName");
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