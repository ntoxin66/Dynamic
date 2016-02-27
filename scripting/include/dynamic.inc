#if defined _dynamic_included_
  #endinput
#endif
#define _dynamic_included_

#define INVALID_DYNAMIC_OBJECT			-1
#define INVALID_DYNAMIC_OFFSET			-1
#define DYNAMIC_MEMBERNAME_MAXLEN		64

enum Dynamic_MemberType
{
	DynamicType_Int = 0,
	DynamicType_Float = 1,
	DynamicType_String = 2,
	DynamicType_Object = 3,
	DynamicType_Unknown = 4
}

typeset DynamicHookCB
{
	function void (Dynamic obj, int offset, const char[] member, Dynamic_MemberType type);
}

native int Dynamic_GetCollectionSize();

native Dynamic Dynamic_Initialise(int blocksize=64, int startsize=0);
native bool Dynamic_IsValid(int index, bool throwerror=false);
native bool Dynamic_Dispose(Dynamic obj);

native int Dynamic_GetMemberCount(Dynamic obj);
native int Dynamic_GetMemberOffset(Dynamic obj, const char[] membername);
native int Dynamic_GetMemberOffsetByIndex(Dynamic obj, int index);
native bool Dynamic_GetMemberNameByIndex(Dynamic obj, int index, char[] buffer, int size);
native bool Dynamic_GetMemberNameByOffset(Dynamic obj, int offset, char[] buffer, int size);
native Dynamic_MemberType Dynamic_GetMemberType(Dynamic obj, const char[] membername);
native Dynamic_MemberType Dynamic_GetMemberTypeByOffset(Dynamic obj, int offset);

native int Dynamic_CallbackCount(Dynamic obj);
native bool Dynamic_HookChanges(Dynamic obj, DynamicHookCB callback);
native bool Dynamic_UnHookChanges(Dynamic obj, DynamicHookCB callback);

native int Dynamic_GetInt(Dynamic obj, const char[] membername, int defaultvalue=-1);
native int Dynamic_SetInt(Dynamic obj, const char[] membername, int value);
native int Dynamic_GetIntByOffset(Dynamic obj, int offset, int defaultvalue=-1);
native bool Dynamic_SetIntByOffset(Dynamic obj, int offset, int value);

native float Dynamic_GetFloat(Dynamic obj, const char[] membername, float defaultvalue=-1.0);
native int Dynamic_SetFloat(Dynamic obj, const char[] membername, float value);
native float Dynamic_GetFloatByOffset(Dynamic obj, int offset, float defaultvalue=-1.0);
native bool Dynamic_SetFloatByOffset(Dynamic obj, int offset, float value);

native bool Dynamic_GetString(Dynamic obj, const char[] membername, char[] buffer, int size);
native int Dynamic_SetString(Dynamic obj, const char[] membername, const char[] value, int length=0);
native int Dynamic_GetStringByOffset(Dynamic obj, int offset, char[] buffer, int size);
native bool Dynamic_SetStringByOffset(Dynamic obj, int offset, const char[] value, int length=0);
native int Dynamic_GetStringLength(Dynamic obj, const char[] membername);
native int Dynamic_GetStringLengthByOffset(Dynamic obj, int offset);

native Dynamic Dynamic_GetObject(Dynamic obj, const char[] membername);
native int Dynamic_SetObject(Dynamic obj, const char[] membername, Dynamic value);
native Dynamic Dynamic_GetObjectByOffset(Dynamic obj, int offset);
native bool Dynamic_SetObjectByOffset(Dynamic obj, int offset, Dynamic value);

methodmap Dynamic
{
	public Dynamic(int blocksize=64, int startsize=0)
	{
		return Dynamic_Initialise(blocksize, startsize);
	}
	
	property int IsValid
	{
		public get()
		{
			return Dynamic_IsValid(view_as<int>(this), false);
		}
	}
	
	property int MemberCount
	{
		public get()
		{
			return Dynamic_GetMemberCount(this);
		}
	}
	
	public void Dispose()
	{
		Dynamic_Dispose(this);
	}
	
	public int GetInt(const char[] membername, int defaultvalue=-1)
	{
		return Dynamic_GetInt(this, membername, defaultvalue);
	}
	
	public int SetInt(const char[] membername, int value)
	{
		return Dynamic_SetInt(this, membername, value);
	}
	
	public int GetIntByOffset(int offset, int defaultvalue=-1)
	{
		return Dynamic_GetIntByOffset(this, offset, defaultvalue);
	}
	
	public void SetIntByOffset(int offset, int value)
	{
		Dynamic_SetIntByOffset(this, offset, value);
	}
	
	public float GetFloat(const char[] membername, float defaultvalue=-1.0)
	{
		return Dynamic_GetFloat(this, membername, defaultvalue);
	}
	
	public int SetFloat(const char[] membername, float value)
	{
		return Dynamic_SetFloat(this, membername, value);
	}
	
	public float GetFloatByOffset(int offset, float defaultvalue=-1.0)
	{
		return Dynamic_GetFloatByOffset(this, offset, defaultvalue);
	}
	
	public void SetFloatByOffset(int offset, float value)
	{
		Dynamic_SetFloatByOffset(this, offset, value);
	}
	
	public bool GetString(const char[] membername, char[] buffer, int length)
	{
		return Dynamic_GetString(this, membername, buffer, length);
	}
	
	public int SetString(const char[] membername, const char[] value, int length=0)
	{
		return Dynamic_SetString(this, membername, value, length);
	}
	
	public int GetStringByOffset(int offset, char[] buffer, int length)
	{
		return Dynamic_GetStringByOffset(this, offset, buffer, length);
	}
	
	public void SetStringByOffset(const int offset, const char[] value, int length=0)
	{
		Dynamic_SetStringByOffset(this, offset, value, length);
	}
	
	public int GetStringLength(const char[] membername)
	{
		return Dynamic_GetStringLength(this, membername);
	}
	
	public int GetStringLengthByOffset(int offset)
	{
		return Dynamic_GetStringLengthByOffset(this, offset);
	}
	
	public Dynamic GetObject(const char[] membername)
	{
		return Dynamic_GetObject(this, membername);
	}
	
	public int SetObject(const char[] membername, Dynamic value)
	{
		return Dynamic_SetObject(this, membername, value);
	}
	
	public Dynamic GetObjectByOffset(int offset)
	{
		return Dynamic_GetObjectByOffset(this, offset);
	}
	
	public void SetObjectByOffset(int offset, Dynamic value)
	{
		Dynamic_SetObjectByOffset(this, offset, value);
	}
	
	public void HookChanges(DynamicHookCB callback)
	{
		Dynamic_HookChanges(this, callback);	
	}
	
	public void UnHookChanges(DynamicHookCB callback)
	{
		Dynamic_UnHookChanges(this, callback);
	}
	
	public int CallbackCount()
	{
		Dynamic_CallbackCount(this);
	}
	
	public int GetMemberOffset(const char[] membername)
	{
		return Dynamic_GetMemberOffset(this, membername);
	}
	
	public Dynamic_MemberType GetMemberType(int offset)
	{
		return Dynamic_GetMemberTypeByOffset(this, offset);
	}
	
	public bool GetMemberNameByIndex(int index, char[] buffer, int length)
	{
		return Dynamic_GetMemberNameByIndex(this, index, buffer, length);
	}
	
	public int GetMemberOffsetByIndex(int index)
	{
		return Dynamic_GetMemberOffsetByIndex(this, index);
	}
	
	public bool GetMemberNameByOffset(int offset, char[] buffer, int length)
	{
		return Dynamic_GetMemberNameByOffset(this, offset, buffer, length);
	}
}

#if !defined REQUIRE_PLUGIN
public __pl_dynamic_SetNTVOptional()
{
	MarkNativeAsOptional("Dynamic_Initialise");
	MarkNativeAsOptional("Dynamic_Dispose");
	MarkNativeAsOptional("Dynamic_GetInt");
	MarkNativeAsOptional("Dynamic_SetInt");
	MarkNativeAsOptional("Dynamic_GetIntByOffset");
	MarkNativeAsOptional("Dynamic_SetIntByOffset");
	MarkNativeAsOptional("Dynamic_GetFloat");
	MarkNativeAsOptional("Dynamic_SetFloat");
	MarkNativeAsOptional("Dynamic_GetFloatByOffset");
	MarkNativeAsOptional("Dynamic_SetFloatByOffset");
	MarkNativeAsOptional("Dynamic_GetString");
	MarkNativeAsOptional("Dynamic_SetString");
	MarkNativeAsOptional("Dynamic_GetStringByOffset");
	MarkNativeAsOptional("Dynamic_SetStringByOffset");
	MarkNativeAsOptional("Dynamic_GetStringLength");
	MarkNativeAsOptional("Dynamic_GetStringLengthByOffset");
	MarkNativeAsOptional("Dynamic_GetObject");
	MarkNativeAsOptional("Dynamic_SetObject");
	MarkNativeAsOptional("Dynamic_GetObjectByOffset");
	MarkNativeAsOptional("Dynamic_SetObjectByOffset");
	MarkNativeAsOptional("Dynamic_GetCollectionSize");
	MarkNativeAsOptional("Dynamic_GetMemberCount");
	MarkNativeAsOptional("Dynamic_IsValid");
	MarkNativeAsOptional("Dynamic_HookChanges");
	MarkNativeAsOptional("Dynamic_UnHookChanges");
	MarkNativeAsOptional("Dynamic_CallbackCount");
	MarkNativeAsOptional("Dynamic_GetMemberOffset");
	MarkNativeAsOptional("Dynamic_GetMemberOffsetByIndex");
	MarkNativeAsOptional("Dynamic_GetMemberType");
	MarkNativeAsOptional("Dynamic_GetMemberTypeByOffset");
	MarkNativeAsOptional("Dynamic_GetMemberNameByIndex");
	MarkNativeAsOptional("Dynamic_GetMemberNameByOffset");
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