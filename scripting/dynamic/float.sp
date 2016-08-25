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

stock float _GetFloat(ArrayList data, int position, int offset, int blocksize, float defaultvalue)
{
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
		return GetMemberDataFloat(data, position, offset, blocksize);
	else if (type == DynamicType_Int || type == DynamicType_Bool)
		return float(GetMemberDataInt(data, position, offset, blocksize));
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(data, position, offset, blocksize, buffer, length);
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
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Float)
	{
		SetMemberDataFloat(data, position, offset, blocksize, value);
		return DynamicType_Float;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(data, position, offset, blocksize, RoundFloat(value));
		return DynamicType_Int;
	}
	else if (type == DynamicType_Bool)
	{
		SetMemberDataInt(data, position, offset, blocksize, RoundFloat(value));
		return DynamicType_Bool;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		FloatToString(value, buffer, length);
		SetMemberDataString(data, position, offset, blocksize, buffer);
		return DynamicType_String;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock float _Dynamic_GetFloat(int index, const char[] membername, float defaultvalue=-1.0)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Float))
		return defaultvalue;
		
	return _GetFloat(data, position, offset, blocksize, defaultvalue);
}

stock int _Dynamic_SetFloat(int index, const char[] membername, float value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Float))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetFloat(data, position, offset, blocksize, value);
	CallOnChangedForward(index, offset, membername, type);
	return offset;
}

stock float _Dynamic_GetFloatByOffset(int index, int offset, float defaultvalue=-1.0)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position;
	if (!ValidateOffset(data, position, offset, blocksize))
		return defaultvalue;
		
	return _GetFloat(data, position, offset, blocksize, defaultvalue);
}

stock bool _Dynamic_SetFloatByOffset(int index, int offset, float value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;

	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(data, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetFloat(data, position, offset, blocksize, value);
	CallOnChangedForwardByOffset(index, offset, type);
	return true;
}

stock int _Dynamic_PushFloat(int index, float value, const char[] name="")
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	
	int memberindex = CreateMemberOffset(data, index, position, offset, blocksize, name, DynamicType_Float);
	SetMemberDataFloat(data, position, offset, blocksize, value);
	_Dynamic_SetMemberNameByIndex(index, memberindex, name);
	//CallOnChangedForward(index, offset, membername, DynamicType_Float);
	return memberindex;
}

stock float _Dynamic_GetFloatByIndex(int index, int memberindex, float defaultvalue=-1.0)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(index, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return _Dynamic_GetFloatByOffset(index, offset, defaultvalue);
}