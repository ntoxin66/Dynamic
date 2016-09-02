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

#if defined _dynamic_system_datatypes_float
  #endinput
#endif
#define _dynamic_system_datatypes_float

stock float _GetFloat(ArrayList data, int position, int offset, int blocksize, float defaultvalue)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
		return _Dynamic_GetMemberDataFloat(data, position, offset, blocksize);
	else if (type == DynamicType_Int || type == DynamicType_Bool)
		return float(_Dynamic_GetMemberDataInt(data, position, offset, blocksize));
	else if (type == DynamicType_String)
	{
		int length = _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		_Dynamic_GetMemberDataString(data, position, offset, blocksize, buffer, length);
		return StringToFloat(buffer);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return defaultvalue;
	}
}

stock Dynamic_MemberType _SetFloat(ArrayList data, int position, int offset, int blocksize, float value)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
	{
		_Dynamic_SetMemberDataFloat(data, position, offset, blocksize, value);
		return DynamicType_Float;
	}
	else if (type == DynamicType_Int)
	{
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, RoundFloat(value));
		return DynamicType_Int;
	}
	else if (type == DynamicType_Bool)
	{
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, RoundFloat(value));
		return DynamicType_Bool;
	}
	else if (type == DynamicType_String)
	{
		int length = _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		FloatToString(value, buffer, length);
		_Dynamic_SetMemberDataString(data, position, offset, blocksize, buffer);
		return DynamicType_String;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock float _Dynamic_GetFloat(DynamicObject dynamic, const char[] membername, float defaultvalue=-1.0)
{
	if (!dynamic.IsValid(true))
		return defaultvalue;
	
	int blocksize = dynamic.BlockSize;
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, position, offset, DynamicType_Float))
		return defaultvalue;
		
	return _GetFloat(dynamic.Data, position, offset, blocksize, defaultvalue);
}

stock int _Dynamic_SetFloat(DynamicObject dynamic, const char[] membername, float value)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	int blocksize = dynamic.BlockSize;
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, true, position, offset, DynamicType_Float))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetFloat(dynamic.Data, position, offset, blocksize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	return offset;
}

stock float _Dynamic_GetFloatByOffset(DynamicObject dynamic, int offset, float defaultvalue=-1.0)
{
	if (!dynamic.IsValid(true))
		return defaultvalue;
	
	int blocksize = dynamic.BlockSize;
	int position;
	if (!_Dynamic_RecalculateOffset(position, offset, blocksize))
		return defaultvalue;
		
	return _GetFloat(dynamic.Data, position, offset, blocksize, defaultvalue);
}

stock bool _Dynamic_SetFloatByOffset(DynamicObject dynamic, int offset, float value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	int blocksize = dynamic.BlockSize;
	int position;
	if (!_Dynamic_RecalculateOffset(position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetFloat(dynamic.Data, position, offset, blocksize, value);
	_Dynamic_CallOnChangedForwardByOffset(dynamic, offset, type);
	return true;
}

stock int _Dynamic_PushFloat(DynamicObject dynamic, float value, const char[] name="")
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	int position; int offset;
	int memberindex = _Dynamic_CreateMemberOffset(dynamic, position, offset, name, DynamicType_Float);
	_Dynamic_SetMemberDataFloat(dynamic.Data, position, offset, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, name, DynamicType_Float);
	return memberindex;
}

stock float _Dynamic_GetFloatByIndex(DynamicObject dynamic, int memberindex, float defaultvalue=-1.0)
{
	if (!dynamic.IsValid(true))
		return defaultvalue;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return _Dynamic_GetFloatByOffset(dynamic, offset, defaultvalue);
}

stock float _Dynamic_GetMemberDataFloat(ArrayList data, int position, int offset, int blocksize)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(position, offset, blocksize);
	
	// Return value
	return data.Get(position, offset);
}

stock void _Dynamic_SetMemberDataFloat(ArrayList data, int position, int offset, int blocksize, float value)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(position, offset, blocksize);
	
	// Set the value
	SetArrayCell(data, position, value, offset);
}