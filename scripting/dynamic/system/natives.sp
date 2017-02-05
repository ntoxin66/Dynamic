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

#if defined _dynamic_system_natives
  #endinput
#endif
#define _dynamic_system_natives

// native Dynamic Dynamic_Initialise(int blocksize=64, int startsize=0, bool persistent=false);
public int Native_Dynamic_Initialise(Handle plugin, int params)
{
	int blocksize = GetNativeCell(1);
	int startsize = GetNativeCell(2);
	bool persistent = true;
	if (params > 2)
		persistent = GetNativeCell(3);
	return _Dynamic_Initialise(plugin, blocksize, startsize, persistent);
}

// native bool Dynamic_IsValid(int index, bool throwerror=false);
public int Native_Dynamic_IsValid(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	bool throwerror = GetNativeCell(2);
	return dynamic.IsValid(throwerror);
}

// native bool Dynamic_Dispose(int index, bool disposemembers=true);
public int Native_Dynamic_Dispose(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	bool disposemembers = GetNativeCell(2);
	return _Dynamic_Dispose(dynamic, disposemembers);
}

// native bool Dynamic_SetName(Dynamic obj, const char[] objectname, bool replace=false);
public int Native_Dynamic_SetName(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int length;
	GetNativeStringLength(2, length);
	char[] objectname = new char[length];
	GetNativeString(2, objectname, length);
	bool replace = GetNativeCell(3);
	return _Dynamic_SetName(dynamic, objectname, replace);
}

// native Dynamic Dynamic_FindByName(const char[] objectname);
public int Native_Dynamic_FindByName(Handle plugin, int params)
{
	int length;
	GetNativeStringLength(1, length);
	char[] objectname = new char[length];
	GetNativeString(1, objectname, length);
	return view_as<int>(_Dynamic_FindByName(objectname));
}

// native Dynamic Dynamic_GetParent(Dynamic obj);
public int Native_Dynamic_GetParent(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	return view_as<int>(_Dynamic_GetParent(dynamic));
}

// native bool Dynamic_GetName(Dynamic obj, char[] buffer, int length);
public int Native_Dynamic_GetName(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int length = GetNativeCell(3);
	char[] buffer = new char[length];
	bool result = _Dynamic_GetName(dynamic, buffer, length);
	SetNativeString(2, buffer, length);
	return result;
}

// native bool Dynamic_GetPersistence(Dynamic obj);
public int Native_Dynamic_GetPersistence(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	return _Dynamic_GetPersistence(dynamic);
}

// native bool Dynamic_SetPersistence(Dynamic obj, bool value);
public int Native_Dynamic_SetPersistence(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	bool value = GetNativeCell(2);
	return _Dynamic_SetPersistence(dynamic, value);
}

// native bool Dynamic_ReadConfig(Dynamic obj, const char[] path, bool use_valve_fs=false, int valuelength=256);
public int Native_Dynamic_ReadConfig(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int length;
	GetNativeStringLength(2, length);
	char[] path = new char[length];
	GetNativeString(2, path, length+1);
	bool use_valve_fs = GetNativeCell(3);
	int valuelength = GetNativeCell(4);
	return _Dynamic_ReadConfig(dynamic, path, use_valve_fs, valuelength);
}

// native bool Dynamic_WriteConfig(Dynamic obj, const char[] path);
public int Native_Dynamic_WriteConfig(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int length;
	GetNativeStringLength(2, length);
	char[] path = new char[length];
	GetNativeString(2, path, length+1);
	return _Dynamic_WriteConfig(dynamic, path);
}

// native bool Dynamic_ReadKeyValues(Dynamic obj, const char[] path, int valuelength, Dynamic_HookType callback=INVALID_FUNCTION);
public int Native_Dynamic_ReadKeyValues(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int length;
	GetNativeStringLength(2, length);
	char[] path = new char[length];
	GetNativeString(2, path, length+1);
	int valuelength = GetNativeCell(3);
	Dynamic_HookType hook = GetNativeCell(4);
	return _Dynamic_ReadKeyValues(plugin, dynamic, path, valuelength, hook);
}

// native bool Dynamic_WriteKeyValues(Dynamic obj, const char[] path);
public int Native_Dynamic_WriteKeyValues(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int length;
	GetNativeStringLength(2, length);
	char[] path = new char[length];
	GetNativeString(2, path, length+1);
	GetNativeStringLength(3, length);
	char[] basekey = new char[length];
	GetNativeString(3, basekey, length+1);
	return _Dynamic_WriteKeyValues(dynamic, path, basekey);
}

// native int Dynamic_GetInt(Dynamic obj, const char[] membername, int defaultvalue=-1);
public int Native_Dynamic_GetInt(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int defaultvalue = GetNativeCell(3);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	return _Dynamic_GetInt(dynamic, membername, defaultvalue);
}

// native DynamicOffset Dynamic_SetInt(Dynamic obj, const char[] membername, int value);
public int Native_Dynamic_SetInt(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	int value = GetNativeCell(3);
	return view_as<int>(_Dynamic_SetInt(dynamic, membername, value));
}

// native int Dynamic_GetIntByOffset(Dynamic obj, DynamicOffset offset, int defaultvalue=-1);
public int Native_Dynamic_GetIntByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	int defaultvalue = GetNativeCell(3);
	return _Dynamic_GetIntByOffset(dynamic, offset, defaultvalue);
}

// native bool Dynamic_SetIntByOffset(Dynamic obj, DynamicOffset offset, int value);
public int Native_Dynamic_SetIntByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	int value = GetNativeCell(3);
	return _Dynamic_SetIntByOffset(dynamic, offset, value);
}

// native int Dynamic_PushInt(Dynamic obj, int value, const char[] name="");
public int Native_Dynamic_PushInt(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int value = GetNativeCell(2);
	int length;
	GetNativeStringLength(3, length);
	char[] name = new char[++length];
	GetNativeString(3, name, length);
	return _Dynamic_PushInt(dynamic, value, name);
}

// native int Dynamic_GetIntByIndex(Dynamic obj, int index, int defaultvalue=-1);
public int Native_Dynamic_GetIntByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	int defaultvalue = GetNativeCell(3);
	return _Dynamic_GetIntByIndex(dynamic, memberindex, defaultvalue);
}

// native bool Dynamic_GetBool(Dynamic obj, const char[] membername, bool defaultvalue=false);
public int Native_Dynamic_GetBool(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	bool defaultvalue = GetNativeCell(3);
	return _Dynamic_GetBool(dynamic, membername, defaultvalue);
}

// native DynamicOffset Dynamic_SetBool(Dynamic obj, const char[] membername, bool value);
public int Native_Dynamic_SetBool(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	bool value = GetNativeCell(3);
	return view_as<int>(_Dynamic_SetBool(dynamic, membername, value));
}

// native bool Dynamic_GetBoolByOffset(Dynamic obj, int offset, bool defaultvalue=false);
public int Native_Dynamic_GetBoolByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	bool defaultvalue = GetNativeCell(3);
	return _Dynamic_GetBoolByOffset(dynamic, offset, defaultvalue);
}

// native bool Dynamic_SetBoolByOffset(Dynamic obj, int offset, bool value);
public int Native_Dynamic_SetBoolByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	bool value = GetNativeCell(3);
	return _Dynamic_SetBoolByOffset(dynamic, offset, value);
}

// native int Dynamic_PushBool(Dynamic obj, bool value, const char[] name="");
public int Native_Dynamic_PushBool(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	bool value = GetNativeCell(2);
	int length;
	GetNativeStringLength(3, length);
	char[] name = new char[++length];
	GetNativeString(3, name, length);
	return _Dynamic_PushBool(dynamic, value, name);
}

// native bool Dynamic_GetBoolByIndex(Dynamic obj, int index, bool defaultvalue=false);
public int Native_Dynamic_GetBoolByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	bool defaultvalue = GetNativeCell(3);
	return _Dynamic_GetBoolByIndex(dynamic, memberindex, defaultvalue);
}

// native float Dynamic_GetFloat(Dynamic obj, const char[] membername, float defaultvalue=-1.0);
public int Native_Dynamic_GetFloat(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	float defaultvalue = GetNativeCell(3);
	return view_as<int>(_Dynamic_GetFloat(dynamic, membername, defaultvalue));
}

// native int Dynamic_SetFloat(Dynamic obj, const char[] membername, float value);
public int Native_Dynamic_SetFloat(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	float value = GetNativeCell(3);
	return view_as<int>(_Dynamic_SetFloat(dynamic, membername, value));
}

// native float Dynamic_GetFloatByOffset(Dynamic obj, DynamicOffset offset, float defaultvalue=-1.0);
public int Native_Dynamic_GetFloatByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	float defaultvalue = GetNativeCell(3);
	return view_as<int>(_Dynamic_GetFloatByOffset(dynamic, offset, defaultvalue));
}

// native bool Dynamic_SetFloatByOffset(Dynamic obj, DynamicOffset offset, float value);
public int Native_Dynamic_SetFloatByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	float value = GetNativeCell(3);
	return _Dynamic_SetFloatByOffset(dynamic, offset, value);
}

// native int Dynamic_PushFloat(Dynamic obj, float value, const char[] name="");
public int Native_Dynamic_PushFloat(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	float value = GetNativeCell(2);
	int length;
	GetNativeStringLength(3, length);
	char[] name = new char[++length];
	GetNativeString(3, name, length);
	return _Dynamic_PushFloat(dynamic, value, name);
}

// native float Dynamic_GetFloatByIndex(Dynamic obj, int index, float defaultvalue=-1.0);
public int Native_Dynamic_GetFloatByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	float defaultvalue = GetNativeCell(3);
	return view_as<int>(_Dynamic_GetFloatByIndex(dynamic, memberindex, defaultvalue));
}

// native bool Dynamic_GetString(Dynamic obj, const char[] membername, char[] buffer, int length);
public int Native_Dynamic_GetString(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	int length = GetNativeCell(4);
	char[] buffer = new char[length];
	bool result = _Dynamic_GetString(dynamic, membername, buffer, length);
	SetNativeString(3, buffer, length);
	return result;
}

// native DynamicOffset Dynamic_SetString(Dynamic obj, const char[] membername, const char[] value, int length=0);
public int Native_Dynamic_SetString(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	int valuelength;
	GetNativeStringLength(3, valuelength);
	char[] value = new char[++valuelength];
	GetNativeString(3, value, valuelength);
	int length = GetNativeCell(4);
	return view_as<int>(_Dynamic_SetString(dynamic, membername, value, length, valuelength));
}

// native bool Dynamic_GetStringByOffset(Dynamic obj, DynamicOffset offset, char[] buffer, int length);
public int Native_Dynamic_GetStringByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	int length = GetNativeCell(4);
	char[] buffer = new char[length];
	bool result = _Dynamic_GetStringByOffset(dynamic, offset, buffer, length);
	SetNativeString(3, buffer, length);
	return result;
}

// native bool Dynamic_SetStringByOffset(Dynamic obj, int offset, const char[] value, int length=0);
public int Native_Dynamic_SetStringByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	int length = GetNativeCell(4);
	int valuelength;
	GetNativeStringLength(3, valuelength);
	if (valuelength > length)
		length = valuelength + 1; // include null terminater space
	char[] value = new char[length];
	GetNativeString(3, value, length);
	return _Dynamic_SetStringByOffset(dynamic, offset, value, length, valuelength);
}

// native int Dynamic_PushString(Dynamic obj, const char[] value, int length=0, const char[] name="");
public int Native_Dynamic_PushString(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int length;
	GetNativeStringLength(4, length);
	char[] name = new char[++length];
	GetNativeString(4, name, length);
	length = GetNativeCell(3);
	int valuelength;
	GetNativeStringLength(2, valuelength);
	char[] value = new char[++valuelength];
	GetNativeString(2, value, valuelength);
	return _Dynamic_PushString(dynamic, value, length, valuelength, name);
}

// native bool Dynamic_GetStringByIndex(Dynamic obj, int index, char[] buffer, int length);
public int Native_Dynamic_GetStringByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	int length = GetNativeCell(4);
	char[] buffer = new char[length];
	bool result = _Dynamic_GetStringByIndex(dynamic, memberindex, buffer, length);
	SetNativeString(3, buffer, length);
	return result;
}

// native int Dynamic_GetStringLengthByOffset(Dynamic obj, DynamicOffset offset);
public int Native_Dynamic_GetStringLengthByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	return _Dynamic_GetStringLengthByOffset(dynamic, offset);
}

// native int Dynamic_GetStringLength(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetStringLength(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	return _Dynamic_GetStringLength(dynamic, membername);
}

// native bool Dynamic_CompareString(Dynamic obj, const char[] membername, const char[] value, bool casesensitive=true);
public int Native_Dynamic_CompareString(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	int valuelength;
	GetNativeStringLength(3, valuelength);
	char[] value = new char[++valuelength];
	GetNativeString(3, value, valuelength);
	bool casesensitive = GetNativeCell(4);
	return _Dynamic_CompareString(dynamic, membername, value, casesensitive);
}

// native Dynamic Dynamic_GetDynamic(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetDynamic(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	return view_as<int>(_Dynamic_GetDynamic(dynamic, membername));
}

// native DynamicOffset Dynamic_SetDynamic(Dynamic obj, const char[] membername, Dynamic value);
public int Native_Dynamic_SetDynamic(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	DynamicObject value = GetNativeCell(3);
	return view_as<int>(_Dynamic_SetDynamic(dynamic, membername, value));
}

// native Dynamic Dynamic_GetDynamicByOffset(Dynamic obj, DynamicOffset offset);
public int Native_Dynamic_GetDynamicByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	return view_as<int>(_Dynamic_GetDynamicByOffset(dynamic, offset));
}

// native bool Dynamic_SetDynamicByOffset(Dynamic obj, DynamicOffset offset, Dynamic value);
public int Native_Dynamic_SetDynamicByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	DynamicObject value = GetNativeCell(3);
	return _Dynamic_SetDynamicByOffset(dynamic, offset, value);
}

// native int Dynamic_PushDynamic(Dynamic obj, Dynamic value, const char[] name="");
public int Native_Dynamic_PushDynamic(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicObject value = GetNativeCell(2);
	int length;
	GetNativeStringLength(3, length);
	char[] name = new char[++length];
	GetNativeString(3, name, length);
	return _Dynamic_PushDynamic(dynamic, value, name);
}

// native Dynamic Dynamic_GetDynamicByIndex(Dynamic obj, int index);
public int Native_Dynamic_GetDynamicByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	return view_as<int>(_Dynamic_GetDynamicByIndex(dynamic, memberindex));
}

// native bool Dynamic_SetDynamicByIndex(Dynamic obj, int index, Dynamic value);
public int Native_Dynamic_SetDynamicByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	DynamicObject value = GetNativeCell(3);
	return _Dynamic_SetDynamicByIndex(dynamic, memberindex, value);
}

// native Handle Dynamic_GetHandle(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetHandle(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, sizeof(membername));
	return _Dynamic_GetHandle(dynamic, membername);
}

// native DynamicOffset Dynamic_SetHandle(Dynamic obj, const char[] membername, Handle value);
public int Native_Dynamic_SetHandle(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	int value = GetNativeCell(3);
	return view_as<int>(_Dynamic_SetHandle(dynamic, membername, value));
}

// native Handle Dynamic_GetHandleByOffset(Dynamic obj, DynamicOffset offset);
public int Native_Dynamic_GetHandleByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	return _Dynamic_GetHandleByOffset(dynamic, offset);
}

// native bool Dynamic_SetHandleByOffset(Dynamic obj, DynamicOffset offset, Handle value);
public int Native_Dynamic_SetHandleByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	int value = GetNativeCell(3);
	return _Dynamic_SetHandleByOffset(dynamic, offset, value);
}

// native int Dynamic_PushHandle(Dynamic obj, Handle value, const char[] name="");
public int Native_Dynamic_PushHandle(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int value = GetNativeCell(2);
	int length;
	GetNativeStringLength(3, length);
	char[] name = new char[++length];
	GetNativeString(3, name, length);
	return _Dynamic_PushHandle(dynamic, value, name);
}

// native Handle Dynamic_GetHandleByIndex(Dynamic obj, int index);
public int Native_Dynamic_GetHandleByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	return _Dynamic_GetHandleByIndex(dynamic, memberindex);
}

// native bool Dynamic_GetVector(Dynamic obj, const char[] membername, float value[3]);
public int Native_Dynamic_GetVector(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	float vector[3];
	bool result = _Dynamic_GetVector(dynamic, membername, vector);
	SetNativeArray(3, vector, sizeof(vector));
	return result;
}

// native DynamicOffset Dynamic_SetVector(Dynamic obj, const char[] membername, const float value[3]);
public int Native_Dynamic_SetVector(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	float vector[3];
	GetNativeArray(3, vector, sizeof(vector));
	return view_as<int>(_Dynamic_SetVector(dynamic, membername, vector));
}

// native bool Dynamic_GetVectorByOffset(Dynamic obj, DynamicOffset offset, float value[3]);
public int Native_Dynamic_GetVectorByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	float value[3];
	bool result = _Dynamic_GetVectorByOffset(dynamic, offset, value);
	SetNativeArray(3, value, sizeof(value));
	return result;
}

// native bool Dynamic_SetVectorByOffset(Dynamic obj, DynamicOffset offset, const float value[3]);
public int Native_Dynamic_SetVectorByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	float value[3];
	return _Dynamic_SetVectorByOffset(dynamic, offset, value);
}

// native int Dynamic_PushVector(Dynamic obj, const float value[3], const char[] name="");
public int Native_Dynamic_PushVector(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	float value[3];
	GetNativeArray(2, value, sizeof(value));
	int length;
	GetNativeStringLength(3, length);
	char[] name = new char[++length];
	GetNativeString(3, name, length);
	return _Dynamic_PushVector(dynamic, value, name);
}

// native bool Dynamic_GetVectorByIndex(Dynamic obj, int index, float value[3]);
public int Native_Dynamic_GetVectorByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	float value[3];
	bool result = _Dynamic_GetVectorByIndex(dynamic, memberindex, value);
	SetNativeArray(3, value, sizeof(value));
	return result;
}

// native int Dynamic_GetCollectionSize();
public int Native_Dynamic_GetCollectionSize(Handle plugin, int params)
{
	return _Dynamic_GetCollectionSize();
}

// native int Dynamic_GetMemberCount(Dynamic obj);
public int Native_Dynamic_GetMemberCount(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	return _Dynamic_GetMemberCount(dynamic);
}

// native bool Dynamic_HookChanges(Dynamic obj, DynamicHookCB callback);
public int Native_Dynamic_HookChanges(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	Dynamic_HookType callback = GetNativeCell(2);
	return _Dynamic_HookChanges(dynamic, callback, plugin);
}

// native bool Dynamic_UnHookChanges(Dynamic obj, Dynamic_HookType callback);
public int Native_Dynamic_UnHookChanges(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	Dynamic_HookType callback = GetNativeCell(2);
	return _Dynamic_UnHookChanges(dynamic, callback, plugin);
}

// native int Dynamic_CallbackCount(Dynamic obj);
public int Native_Dynamic_CallbackCount(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	return _Dynamic_HookCount(dynamic);
}

// native DynamicOffset Dynamic_GetMemberOffset(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetMemberOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	return view_as<int>(_Dynamic_GetMemberOffset(dynamic, membername));
}

// native DynamicOffset Dynamic_GetMemberOffsetByIndex(Dynamic obj, int index);
public int Native_Dynamic_GetMemberOffsetByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	return view_as<int>(_Dynamic_GetMemberOffsetByIndex(dynamic, memberindex));
}

// native Dynamic_MemberType Dynamic_GetMemberType(Dynamic obj, const char[] membername);
public int Native_Dynamic_GetMemberType(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	GetNativeString(2, membername, DYNAMIC_MEMBERNAME_MAXLEN);
	return view_as<int>(_Dynamic_GetMemberType(dynamic, membername));
}

// native Dynamic_MemberType Dynamic_GetMemberTypeByOffset(Dynamic obj, DynamicOffset offset);
public int Native_Dynamic_GetMemberTypeByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	return view_as<int>(_Dynamic_GetMemberTypeByOffset(dynamic, offset));
}

// native bool Dynamic_GetMemberNameByIndex(Dynamic obj, int index, char[] buffer, int length);
public int Native_Dynamic_GetMemberNameByIndex(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	int memberindex = GetNativeCell(2);
	int length = GetNativeCell(4);
	char[] buffer = new char[length];
	bool result = _Dynamic_GetMemberNameByIndex(dynamic, memberindex, buffer, length);
	SetNativeString(3, buffer, length);
	return result;
}

// native bool Dynamic_GetMemberNameByOffset(Dynamic obj, DynamicOffset offset, char[] buffer, int length);
public int Native_Dynamic_GetMemberNameByOffset(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicOffset offset = GetNativeCell(2);
	int length = GetNativeCell(2);
	char[] buffer = new char[length];
	bool result = _Dynamic_GetMemberNameByOffset(dynamic, offset, buffer, length);
	SetNativeString(3, buffer, length);
	return result;
}

// native bool Dynamic_SortMembers(Dynamic obj, SortOrder order);
public int Native_Dynamic_SortMembers(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	SortOrder order = GetNativeCell(2);
	return _Dynamic_SortMembers(dynamic, order);
}

// native ArrayList Dynamic_FindByMemberValue(Dynamic obj, Dynamic params);
public int Native_Dynamic_FindByMemberValue(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	DynamicObject dparams = GetNativeCell(2);
	return view_as<int>(_Dynamic_FindByMemberValue(dynamic, dparams));
}

// native bool Dynamic_ResetObject(int index, bool disposemembers=true, int blocksize=0, int startsize=0);
public int Native_Dynamic_ResetObject(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	bool disposemembers = GetNativeCell(2);
	int blocksize = GetNativeCell(3);
	int startsize = GetNativeCell(4);
	return _Dynamic_ResetObject(dynamic, disposemembers, blocksize, startsize);
}

// native bool Dynamic_GetOwnerPlugin(int index);
public int Native_Dynamic_GetOwnerPlugin(Handle plugin, int params)
{
	DynamicObject dynamic = GetNativeCell(1);
	return view_as<int>(_Dynamic_GetOwnerPlugin(dynamic));
}

stock void CreateNatives()
{
	CreateNative("Dynamic_Initialise", Native_Dynamic_Initialise);
	CreateNative("Dynamic_IsValid", Native_Dynamic_IsValid);
	CreateNative("Dynamic_Dispose", Native_Dynamic_Dispose);
	CreateNative("Dynamic_ResetObject", Native_Dynamic_ResetObject);
	CreateNative("Dynamic_GetOwnerPlugin", Native_Dynamic_GetOwnerPlugin);
	CreateNative("Dynamic_SetName", Native_Dynamic_SetName);
	CreateNative("Dynamic_FindByName", Native_Dynamic_FindByName);
	CreateNative("Dynamic_GetParent", Native_Dynamic_GetParent);
	CreateNative("Dynamic_GetName", Native_Dynamic_GetName);
	CreateNative("Dynamic_GetPersistence", Native_Dynamic_GetPersistence);
	CreateNative("Dynamic_SetPersistence", Native_Dynamic_SetPersistence);
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
	CreateNative("Dynamic_CompareString", Native_Dynamic_CompareString);
	CreateNative("Dynamic_GetDynamic", Native_Dynamic_GetDynamic);
	CreateNative("Dynamic_SetDynamic", Native_Dynamic_SetDynamic);
	CreateNative("Dynamic_GetDynamicByOffset", Native_Dynamic_GetDynamicByOffset);
	CreateNative("Dynamic_SetDynamicByOffset", Native_Dynamic_SetDynamicByOffset);
	CreateNative("Dynamic_PushDynamic", Native_Dynamic_PushDynamic);
	CreateNative("Dynamic_GetDynamicByIndex", Native_Dynamic_GetDynamicByIndex);
	CreateNative("Dynamic_SetDynamicByIndex", Native_Dynamic_SetDynamicByIndex);
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
	CreateNative("Dynamic_FindByMemberValue", Native_Dynamic_FindByMemberValue);
	
	// These are deprecated until removed
	CreateNative("Dynamic_GetObject", Native_Dynamic_GetDynamic);
	CreateNative("Dynamic_SetObject", Native_Dynamic_SetDynamic);
	CreateNative("Dynamic_GetObjectByOffset", Native_Dynamic_GetDynamicByOffset);
	CreateNative("Dynamic_SetObjectByOffset", Native_Dynamic_SetDynamicByOffset);
	CreateNative("Dynamic_PushObject", Native_Dynamic_PushDynamic);
	CreateNative("Dynamic_GetObjectByIndex", Native_Dynamic_GetDynamicByIndex);
	CreateNative("Dynamic_SetObjectByIndex", Native_Dynamic_SetDynamicByIndex);
}