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

stock bool _GetBool(ArrayList data, int position, int offset, int blocksize, bool defaultvalue)
{
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Bool)
		return view_as<bool>(GetMemberDataInt(data, position, offset, blocksize));
	else if (type == DynamicType_Int)
		return (GetMemberDataInt(data, position, offset, blocksize) == 0 ? false : true);
	else if (type == DynamicType_Float)
		return (GetMemberDataFloat(data, position, offset, blocksize) == 0.0 ? false : true);
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		GetMemberDataString(data, position, offset, blocksize, buffer, length);
		if (StrEqual(buffer, "True"))
			return true;
		if (StrEqual(buffer, "true"))
			return true;
		
		return false;
	}
	else if (type == DynamicType_Object)
	{
		int value = GetMemberDataInt(data, position, offset, blocksize);
		if (value == Invalid_Dynamic_Object)
			return false;
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return defaultvalue;
	}
}

stock Dynamic_MemberType _SetBool(ArrayList data, int position, int offset, int blocksize, bool value)
{
	Dynamic_MemberType type = GetMemberType(data, position, offset, blocksize);
	if (type == DynamicType_Bool)
	{
		SetMemberDataInt(data, position, offset, blocksize, value);
		return DynamicType_Bool;
	}
	else if (type == DynamicType_Int)
	{
		SetMemberDataInt(data, position, offset, blocksize, value);
		return DynamicType_Int;
	}
	else if (type == DynamicType_Float)
	{
		SetMemberDataFloat(data, position, offset, blocksize, float(value));
		return DynamicType_Float;
	}
	else if (type == DynamicType_String)
	{
		int length = GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		if (value)
			strcopy(buffer, length, "True");
		else
			strcopy(buffer, length, "False");
		SetMemberDataString(data, position, offset, blocksize, buffer);
		return DynamicType_String;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock bool _Dynamic_GetBool(int index, const char[] membername, bool defaultvalue=false)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;

	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, false, position, offset, blocksize, DynamicType_Bool))
		return defaultvalue;
		
	return _GetBool(data, position, offset, blocksize, defaultvalue);
}

stock int _Dynamic_SetBool(int index, const char[] membername, bool value)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;

	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!GetMemberOffset(data, index, membername, true, position, offset, blocksize, DynamicType_Bool))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetBool(data, position, offset, blocksize, value);
	CallOnChangedForward(index, offset, membername, type);
	return offset;
}

stock bool _Dynamic_GetBoolByOffset(int index, int offset, bool defaultvalue=false)
{
	if (!_Dynamic_IsValid(index, true))
		return defaultvalue;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(data, position, offset, blocksize))
		return defaultvalue;
	
	return _GetBool(data, position, offset, blocksize, defaultvalue);
}

stock bool _Dynamic_SetBoolByOffset(int index, int offset, bool value)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!ValidateOffset(data, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetBool(data, position, offset, blocksize, value);
	CallOnChangedForwardByOffset(index, offset, type);
	return true;
}

stock int _Dynamic_PushBool(int index, bool value, const char[] name="")
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	int memberindex = CreateMemberOffset(data, index, position, offset, blocksize, DynamicType_Bool);
	SetMemberDataInt(data, position, offset, blocksize, value);
	_Dynamic_SetMemberNameByIndex(index, memberindex, name);
	//CallOnChangedForward(index, offset, membername, DynamicType_Bool);
	return memberindex;
}

stock bool _Dynamic_GetBoolByIndex(int index, int memberindex, bool defaultvalue=false)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(index, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return defaultvalue;
	
	return _Dynamic_GetBoolByOffset(index, offset, defaultvalue);
}