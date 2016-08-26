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

stock int _GetObject(ArrayList data, int position, int offset, int blocksize)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Object)
		return _Dynamic_GetMemberDataInt(data, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return Invalid_Dynamic_Object;
	}
}

stock Dynamic_MemberType _SetObject(int index, ArrayList data, int position, int offset, int blocksize, int value, const char[] membername="")
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Object)
	{
		// remove parent from current value
		int currentvalue = _Dynamic_GetMemberDataInt(data, position, offset, blocksize);
		if (currentvalue != Invalid_Dynamic_Object)
			SetArrayCell(s_Collection, currentvalue, INVALID_DYNAMIC_OBJECT, Dynamic_ParentObject);
		
		// set value and name
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, value);
		
		if (value != Invalid_Dynamic_Object)
		{
			SetArrayCell(s_Collection, value, index, Dynamic_ParentObject);
			SetArrayCell(s_Collection, value, offset, Dynamic_ParentOffset);
		}
		
		return DynamicType_Object;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock int _Dynamic_GetObject(int index, const char[] membername)
{
	if (!_Dynamic_IsValid(index, true))
		return Invalid_Dynamic_Object;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Object))
		return Invalid_Dynamic_Object;
		
	return _GetObject(data, position, offset, blocksize);
}

stock int _Dynamic_SetObject(int index, const char[] membername, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Object))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetObject(index, data, position, offset, blocksize, value, membername);
	CallOnChangedForward(index, offset, membername, type);
	return offset;
}

// native Dynamic Dynamic_GetObjectByOffset(Dynamic obj, int offset);
stock int _Dynamic_GetObjectByOffset(int index, int offset)
{
	if (!_Dynamic_IsValid(index, true))
		return Invalid_Dynamic_Object;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!_Dynamic_RecalculateOffset(data, position, offset, blocksize))
		return Invalid_Dynamic_Object;
	
	return _GetObject(data, position, offset, blocksize);
}

stock bool _Dynamic_SetObjectByOffset(int index, int offset, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position;
	if (!_Dynamic_RecalculateOffset(data, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetObject(index, data, position, offset, blocksize, value);
	CallOnChangedForwardByOffset(index, offset, type);
	return true;
}

stock int _Dynamic_PushObject(int index, int value, const char[] name="")
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	SetArrayCell(s_Collection, value, index, Dynamic_ParentObject);
	int position; int offset;
	
	int memberindex = _Dynamic_CreateMemberOffset(array, index, position, offset, blocksize, name, DynamicType_Object);
	_Dynamic_SetMemberDataInt(array, position, offset, blocksize, value);
	CallOnChangedForward(index, offset, name, DynamicType_Object);
	return memberindex;
}

stock int _Dynamic_GetObjectByIndex(int index, int memberindex)
{
	if (!_Dynamic_IsValid(index, true))
		return Invalid_Dynamic_Object;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(index, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return Invalid_Dynamic_Object;
	
	return _Dynamic_GetObjectByOffset(index, offset);
}

stock bool _Dynamic_SetObjectByIndex(int index, int memberindex, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(index, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
	
	return _Dynamic_SetObjectByOffset(index, offset, value);
}