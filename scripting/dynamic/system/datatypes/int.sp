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

#if defined _dynamic_system_datatypes_int
  #endinput
#endif
#define _dynamic_system_datatypes_int

stock int _GetInt(ArrayList data, int position, int offset, int blocksize, int defaultvalue)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Int || type == DynamicType_Bool)
		return _Dynamic_GetMemberDataInt(data, position, offset, blocksize);
	else if (type == DynamicType_Float)
		return RoundFloat(_Dynamic_GetMemberDataFloat(data, position, offset, blocksize));
	else if (type == DynamicType_String)
	{
		int length = _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		_Dynamic_GetMemberDataString(data, position, offset, blocksize, buffer, length);
		return StringToInt(buffer);
	}
	else if (type == DynamicType_Dynamic)
		return _Dynamic_GetMemberDataInt(data, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return defaultvalue;
	}
}

stock Dynamic_MemberType _SetInt(ArrayList data, int position, int offset, int blocksize, int value)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Int)
	{
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, value);
		return DynamicType_Int;
	}
	else if (type == DynamicType_Float)
	{
		_Dynamic_SetMemberDataFloat(data, position, offset, blocksize, float(value));
		return DynamicType_Float;
	}
	else if (type == DynamicType_Bool)
	{
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, value);
		return DynamicType_Bool;
	}
	else if (type == DynamicType_String)
	{
		int length = _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		IntToString(value, buffer, length);
		_Dynamic_SetMemberDataString(data, position, offset, blocksize, buffer);
		return DynamicType_String;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock int _Dynamic_GetInt(DynamicObject dynamic, const char[] membername, int defaultvalue=-1)
{
	if (!dynamic.IsValid(true))
		return defaultvalue;
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, offset, DynamicType_Int))
		return defaultvalue;
		
	return _GetInt(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, defaultvalue);
}

// native int Dynamic_SetInt(Dynamic obj, const char[] membername, int value);
stock DynamicOffset _Dynamic_SetInt(DynamicObject dynamic, const char[] membername, int value)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, true, offset, DynamicType_Int))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetInt(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	return offset;
}

stock int _Dynamic_GetIntByOffset(DynamicObject dynamic, DynamicOffset offset, int defaultvalue=-1)
{
	if (!dynamic.IsValid(true))
		return defaultvalue;
	
	return _GetInt(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, defaultvalue);
}

stock bool _Dynamic_SetIntByOffset(DynamicObject dynamic, DynamicOffset offset, int value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	Dynamic_MemberType type = _SetInt(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForwardByOffset(dynamic, offset, type);
	return true;
}

stock int _Dynamic_PushInt(DynamicObject dynamic, int value, const char[] name="")
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_INDEX;
	
	DynamicOffset offset;	
	int memberindex = _Dynamic_CreateMemberOffset(dynamic, offset, name, DynamicType_Int);
	_Dynamic_SetMemberDataInt(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, name, DynamicType_Int);
	return memberindex;
}

stock int _Dynamic_GetIntByIndex(DynamicObject dynamic, int memberindex, int defaultvalue=-1)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_INDEX;
	
	DynamicOffset offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return _Dynamic_GetIntByOffset(dynamic, offset, defaultvalue);
}

stock int _Dynamic_GetMemberDataInt(ArrayList data, int position, int offset, int blocksize)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(position, offset, blocksize);
	
	// Return value
	return data.Get(position, offset);
}

stock void _Dynamic_SetMemberDataInt(ArrayList data, int position, int offset, int blocksize, int value)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(position, offset, blocksize);
	
	// Set the value
	SetArrayCell(data, position, value, offset);
}