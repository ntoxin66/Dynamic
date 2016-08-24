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

stock int _GetHandle(ArrayList data, int position, int offset, int blocksize)
{
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Handle)
		return GetMemberDataInt(data, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return 0;
	}
}

stock Dynamic_MemberType _SetHandle(ArrayList data, int position, int offset, int blocksize, int value, const char[] membername="")
{
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Handle)
	{
		SetMemberDataInt(data, position, offset, blocksize, view_as<int>(value));
		return DynamicType_Handle;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock int _Dynamic_GetHandle(int index, const char[] membername)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Handle))
		return 0;
		
	return _GetHandle(data, position, offset, blocksize);
}

stock int _Dynamic_SetHandle(int index, const char[] membername, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Handle))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetHandle(data, position, offset, blocksize, value);
	CallOnChangedForward(index, offset, membername, type);
	return offset;
}

stock int _Dynamic_GetHandleByOffset(int index, int offset)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(data, position, offset, blocksize))
		return 0;
	
	return _GetHandle(data, position, offset, blocksize);
}

stock bool _Dynamic_SetHandleByOffset(int index, int offset, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(data, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetHandle(data, position, offset, blocksize, value);
	CallOnChangedForwardByOffset(index, offset, type);
	return true;
}

stock int _Dynamic_PushHandle(int index, int value, const char[] name="")
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(data, index, position, offset, blocksize, DynamicType_Object);
	SetMemberDataInt(data, position, offset, blocksize, value);
	_Dynamic_SetMemberNameByIndex(index, memberindex, name);
	//CallOnChangedForward(index, offset, membername, DynamicType_Int);
	return memberindex;
}

stock int _Dynamic_GetHandleByIndex(int index, int memberindex)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(index, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return 0;
	
	return _Dynamic_GetHandleByOffset(index, offset);
}