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
	else if (type == DynamicType_Object)
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

stock int _Dynamic_GetInt(DynamicObject item, const char[] membername, int defaultvalue=-1)
{
	if (!item.IsValid(true))
		return defaultvalue;
	
	ArrayList data = item.Data;
	int blocksize = item.BlockSize;
	
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(item, membername, false, position, offset, DynamicType_Int))
		return defaultvalue;
		
	return _GetInt(data, position, offset, blocksize, defaultvalue);
}

// native int Dynamic_SetInt(Dynamic obj, const char[] membername, int value);
stock int _Dynamic_SetInt(DynamicObject item, const char[] membername, int value)
{
	if (!item.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = item.Data;
	int blocksize = item.BlockSize;
	
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(item, membername, true, position, offset, DynamicType_Int))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetInt(data, position, offset, blocksize, value);
	_Dynamic_CallOnChangedForward(item, offset, membername, type);
	return offset;
}

stock int _Dynamic_GetIntByOffset(DynamicObject item, int offset, int defaultvalue=-1)
{
	if (!item.IsValid(true))
		return defaultvalue;
	
	ArrayList data = item.Data;
	int blocksize = item.BlockSize;
	int position;
	
	if (!_Dynamic_RecalculateOffset(data, position, offset, blocksize))
		return defaultvalue;
	
	return _GetInt(data, position, offset, blocksize, defaultvalue);
}

stock bool _Dynamic_SetIntByOffset(DynamicObject item, int offset, int value)
{
	if (!item.IsValid(true))
		return false;
	
	ArrayList data = item.Data;
	int blocksize = item.BlockSize;
	
	int position;
	if (!_Dynamic_RecalculateOffset(data, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetInt(data, position, offset, blocksize, value);
	_Dynamic_CallOnChangedForwardByOffset(item, offset, type);
	return true;
}

stock int _Dynamic_PushInt(DynamicObject item, int value, const char[] name="")
{
	if (!item.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = item.Data;
	int blocksize = item.BlockSize;
	int position; int offset;
	
	int memberindex = _Dynamic_CreateMemberOffset(item, position, offset, name, DynamicType_Int);
	_Dynamic_SetMemberDataInt(data, position, offset, blocksize, value);
	_Dynamic_CallOnChangedForward(item, offset, name, DynamicType_Int);
	return memberindex;
}

stock int _Dynamic_GetIntByIndex(DynamicObject item, int memberindex, int defaultvalue=-1)
{
	if (!item.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(item, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return _Dynamic_GetIntByOffset(item, offset, defaultvalue);
}

stock int _Dynamic_GetMemberDataInt(Handle array, int position, int offset, int blocksize)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(array, position, offset, blocksize);
	
	// Return value
	return GetArrayCell(array, position, offset);
}

stock void _Dynamic_SetMemberDataInt(Handle data, int position, int offset, int blocksize, int value)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(data, position, offset, blocksize);
	
	// Set the value
	SetArrayCell(data, position, value, offset);
}