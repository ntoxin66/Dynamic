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

#if defined _dynamic_system_datatypes_function
  #endinput
#endif
#define _dynamic_system_datatypes_function

stock Function _GetFunction(ArrayList data, int position, int offset, int blocksize)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Function)
		return _Dynamic_GetMemberDataFunction(data, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_FUNCTION;
	}
}

stock Dynamic_MemberType _SetFunction(ArrayList data, int position, int offset, int blocksize, Function value, const char[] membername="")
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Function)
	{
		_Dynamic_SetMemberDataFunction(data, position, offset, blocksize, value);
		return DynamicType_Function;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock Function _Dynamic_GetFunction(DynamicObject dynamic, const char[] membername)
{
	if (!dynamic.IsValid(true))
		return INVALID_FUNCTION;
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, offset, DynamicType_Function))
		return INVALID_FUNCTION;
		
	return _GetFunction(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize);
}

stock DynamicOffset _Dynamic_SetFunction(DynamicObject dynamic, const char[] membername, Function value)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, true, offset, DynamicType_Function))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetFunction(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	return offset;
}

stock Function _Dynamic_GetFunctionByOffset(DynamicObject dynamic, DynamicOffset offset)
{
	if (!dynamic.IsValid(true))
		return INVALID_FUNCTION;
	
	return _GetFunction(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize);
}

stock bool _Dynamic_SetFunctionByOffset(DynamicObject dynamic, DynamicOffset offset, Function value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	Dynamic_MemberType type = _SetFunction(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForwardByOffset(dynamic, offset, type);
	return true;
}

stock int _Dynamic_PushFunction(DynamicObject dynamic, Function value, const char[] name="")
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_INDEX;
	
	DynamicOffset offset;
	int memberindex = _Dynamic_CreateMemberOffset(dynamic, offset, name, DynamicType_Function);
	_Dynamic_SetMemberDataFunction(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, name, DynamicType_Function);
	return memberindex;
}

stock Function _Dynamic_GetFunctionByIndex(DynamicObject dynamic, int memberindex)
{
	if (!dynamic.IsValid(true))
		return INVALID_FUNCTION;
	
	DynamicOffset offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return INVALID_FUNCTION;
	
	return _Dynamic_GetFunctionByOffset(dynamic, offset);
}

stock Function _Dynamic_GetMemberDataFunction(ArrayList data, int position, int offset, int blocksize)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(position, offset, blocksize);
	
	// Return value
	return data.Get(position, offset);
}

stock void _Dynamic_SetMemberDataFunction(ArrayList data, int position, int offset, int blocksize, Function value)
{
	// Move the offset forward by one cell as this is where the value is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(position, offset, blocksize);
	
	// Set the value
	SetArrayCell(data, position, view_as<int>(value), offset);
}