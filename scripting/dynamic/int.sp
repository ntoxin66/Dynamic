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
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Int || type == DynamicType_Bool)
		return GetMemberDataInt(data, position, offset, blocksize);
	else if (type == DynamicType_Float)
		return RoundFloat(GetMemberDataFloat(data, position, offset, blocksize));
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(data, position, offset, blocksize, buffer, length);
		return StringToInt(buffer);
	}
	else if (type == DynamicType_Object)
		return GetMemberDataInt(data, position, offset, blocksize);
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return defaultvalue;
	}
}

stock Dynamic_MemberType _SetInt(ArrayList data, int position, int offset, int blocksize, int value)
{
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Int)
	{
		SetMemberDataInt(data, position, offset, blocksize, value);
		return DynamicType_Int;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(data, position, offset, blocksize, float(value));
		return DynamicType_Float;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(data, position, offset, blocksize, value);
		return DynamicType_Bool;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		IntToString(value, buffer, length);
		SetMemberDataString(data, position, offset, blocksize, buffer);
		return DynamicType_String;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock int _Dynamic_GetInt(int index, const char[] membername, int defaultvalue=-1)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Int))
		return defaultvalue;
		
	return _GetInt(data, position, offset, blocksize, defaultvalue);
}

// native int Dynamic_SetInt(Dynamic obj, const char[] membername, int value);
stock int _Dynamic_SetInt(int index, const char[] membername, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Int))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetInt(data, position, offset, blocksize, value);
	CallOnChangedForward(index, offset, membername, type);
	return offset;
}

stock int _Dynamic_GetIntByOffset(int index, int offset, int defaultvalue=-1)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	
	if (!ValidateOffset(data, position, offset, blocksize))
		return defaultvalue;
	
	return _GetInt(data, position, offset, blocksize, defaultvalue);
}

stock bool _Dynamic_SetIntByOffset(int index, int offset, int value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position;
	if (!ValidateOffset(data, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetInt(data, position, offset, blocksize, value);
	CallOnChangedForwardByOffset(index, offset, type);
	return true;
}

stock int _Dynamic_PushInt(int index, int value, const char[] name="")
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(data, index, position, offset, blocksize, DynamicType_Int);
	SetMemberDataInt(data, position, offset, blocksize, value);
	_Dynamic_SetMemberNameByIndex(index, memberindex, name);
	//CallOnChangedForward(index, offset, membername, DynamicType_Int);
	return memberindex;
}

stock int _Dynamic_GetIntByIndex(int index, int memberindex, int defaultvalue=-1)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(index, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return _Dynamic_GetIntByOffset(index, offset, defaultvalue);
}