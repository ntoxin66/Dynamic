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

#if defined _dynamic_system_datatypes_handle
  #endinput
#endif
#define _dynamic_system_datatypes_handle

stock int _GetHandle(ArrayList data, int position, int offset, int blocksize)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Handle)
		return _Dynamic_GetMemberDataInt(data, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

stock Dynamic_MemberType _SetHandle(ArrayList data, int position, int offset, int blocksize, int value, const char[] membername="")
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Handle)
	{
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, view_as<int>(value));
		return DynamicType_Handle;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock int _Dynamic_GetHandle(DynamicObject dynamic, const char[] membername)
{
	if (!dynamic.IsValid(true))
		return 0;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, position, offset, DynamicType_Handle))
		return 0;
		
	return _GetHandle(data, position, offset, blocksize);
}

stock int _Dynamic_SetHandle(DynamicObject dynamic, const char[] membername, int value)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, true, position, offset, DynamicType_Handle))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetHandle(data, position, offset, blocksize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	return offset;
}

stock int _Dynamic_GetHandleByOffset(DynamicObject dynamic, int offset)
{
	if (!dynamic.IsValid(true))
		return 0;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	int position;
	if (!_Dynamic_RecalculateOffset(position, offset, blocksize))
		return 0;
	
	return _GetHandle(data, position, offset, blocksize);
}

stock bool _Dynamic_SetHandleByOffset(DynamicObject dynamic, int offset, int value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	int position;
	if (!_Dynamic_RecalculateOffset(position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetHandle(data, position, offset, blocksize, value);
	_Dynamic_CallOnChangedForwardByOffset(dynamic, offset, type);
	return true;
}

stock int _Dynamic_PushHandle(DynamicObject dynamic, int value, const char[] name="")
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	int position; int offset;
	int memberindex = _Dynamic_CreateMemberOffset(dynamic, position, offset, name, DynamicType_Dynamic);
	_Dynamic_SetMemberDataInt(dynamic.Data, position, offset, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, name, DynamicType_Handle);
	return memberindex;
}

stock int _Dynamic_GetHandleByIndex(DynamicObject dynamic, int memberindex)
{
	if (!dynamic.IsValid(true))
		return 0;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return 0;
	
	return _Dynamic_GetHandleByOffset(dynamic, offset);
}