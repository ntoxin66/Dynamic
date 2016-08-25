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

stock bool _GetVector(ArrayList data, int position, int offset, int blocksize, float value[3])
{
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Vector)
		return GetMemberDataVector(data, position, offset, blocksize, value);
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(data, position, offset, blocksize, buffer, length);
		return GetVectorFromString(buffer, value);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return false;
	}
}

stock Dynamic_MemberType _SetVector(ArrayList data, int position, int offset, int blocksize, const float value[3], const char[] membername="")
{
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Vector)
	{
		SetMemberDataVector(data, position, offset, blocksize, value);
		return DynamicType_Vector;
	}
	else if (type == DynamicType_String)
	{
		char buffer[192];
		Format(buffer, sizeof(buffer), "{%f, %f, %f}", value[0], value[1], value[2]);
		SetMemberDataString(data, position, offset, blocksize, buffer);
		return DynamicType_String;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock bool _Dynamic_GetVector(int index, const char[] membername, float[3] vector)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Vector))
		return false;
		
	return _GetVector(data, position, offset, blocksize, vector);
}

stock int _Dynamic_SetVector(int index, const char[] membername, const float value[3])
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Vector))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetVector(data, position, offset, blocksize, value, membername);
	CallOnChangedForward(index, offset, membername, type);
	return offset;
}

stock bool _Dynamic_GetVectorByOffset(int index, int offset, float[3] value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(data, position, offset, blocksize))
		return false;
	
	return _GetVector(data, position, offset, blocksize, value);
}

stock bool _Dynamic_SetVectorByOffset(int index, int offset, const float value[3])
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position;
	if (!ValidateOffset(data, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetVector(data, position, offset, blocksize, value);
	CallOnChangedForwardByOffset(index, offset, type);
	return true;
}

stock int _Dynamic_PushVector(int index, const float value[3], const char[] name="")
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList array = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	int memberindex = CreateMemberOffset(array, index, position, offset, blocksize, name, DynamicType_Vector);
	SetMemberDataVector(array, position, offset, blocksize, value);
	_Dynamic_SetMemberNameByIndex(index, memberindex, name);
	//CallOnChangedForward(index, offset, membername, DynamicType_Vector);
	return memberindex;
}

// native bool Dynamic_GetVectorByIndex(Dynamic obj, int index, float value[3]);
stock bool _Dynamic_GetVectorByIndex(int index, int memberindex, float value[3])
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(index, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
	
	return _Dynamic_GetVectorByOffset(index, offset, value);
}