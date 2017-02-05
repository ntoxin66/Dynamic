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

#if defined _dynamic_system_datatypes_bool
  #endinput
#endif
#define _dynamic_system_datatypes_bool

stock bool _GetBool(ArrayList data, int position, int offset, int blocksize, bool defaultvalue)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Bool)
		return view_as<bool>(_Dynamic_GetMemberDataInt(data, position, offset, blocksize));
	else if (type == DynamicType_Int)
		return (_Dynamic_GetMemberDataInt(data, position, offset, blocksize) == 0 ? false : true);
	else if (type == DynamicType_Float)
		return (_Dynamic_GetMemberDataFloat(data, position, offset, blocksize) == 0.0 ? false : true);
	else if (type == DynamicType_String)
	{
		int length = _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		_Dynamic_GetMemberDataString(data, position, offset, blocksize, buffer, length);
		if (StrEqual(buffer, "True"))
			return true;
		if (StrEqual(buffer, "true"))
			return true;
		
		return false;
	}
	else if (type == DynamicType_Dynamic)
	{
		DynamicObject value = view_as<DynamicObject>(_Dynamic_GetMemberDataInt(data, position, offset, blocksize));
		if (!value.IsValid(false))
			return false;
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return defaultvalue;
	}
}

stock Dynamic_MemberType _SetBool(ArrayList data, int position, int offset, int blocksize, bool value)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Bool)
	{
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, value);
		return DynamicType_Bool;
	}
	else if (type == DynamicType_Int)
	{
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, value);
		return DynamicType_Int;
	}
	else if (type == DynamicType_Float)
	{
		_Dynamic_SetMemberDataFloat(data, position, offset, blocksize, float(value));
		return DynamicType_Float;
	}
	else if (type == DynamicType_String)
	{
		int length = _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		if (value)
			strcopy(buffer, length, "True");
		else
			strcopy(buffer, length, "False");
		_Dynamic_SetMemberDataString(data, position, offset, blocksize, buffer);
		return DynamicType_String;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock bool _Dynamic_GetBool(DynamicObject dynamic, const char[] membername, bool defaultvalue=false)
{
	if (!dynamic.IsValid(true))
		return defaultvalue;
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, offset, DynamicType_Bool))
		return defaultvalue;
		
	return _GetBool(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, defaultvalue);
}

stock DynamicOffset _Dynamic_SetBool(DynamicObject dynamic, const char[] membername, bool value)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
		
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, true, offset, DynamicType_Bool))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetBool(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	return offset;
}

stock bool _Dynamic_GetBoolByOffset(DynamicObject dynamic, DynamicOffset offset, bool defaultvalue=false)
{
	if (!dynamic.IsValid(true))
		return defaultvalue;
	
	return _GetBool(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, defaultvalue);
}

stock bool _Dynamic_SetBoolByOffset(DynamicObject dynamic, DynamicOffset offset, bool value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	Dynamic_MemberType type = _SetBool(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForwardByOffset(dynamic, offset, type);
	return true;
}

stock int _Dynamic_PushBool(DynamicObject dynamic, bool value, const char[] name="")
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_INDEX;
	
	DynamicOffset offset;
	int memberindex = _Dynamic_CreateMemberOffset(dynamic, offset, name, DynamicType_Bool);
	_Dynamic_SetMemberDataInt(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, name, DynamicType_Bool);
	return memberindex;
}

stock bool _Dynamic_GetBoolByIndex(DynamicObject dynamic, int memberindex, bool defaultvalue=false)
{
	if (!dynamic.IsValid(true))
		return false;
	
	DynamicOffset offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return _Dynamic_GetBoolByOffset(dynamic, offset, defaultvalue);
}