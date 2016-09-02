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

#if defined _dynamic_system_datatypes_vector
  #endinput
#endif
#define _dynamic_system_datatypes_vector

stock bool _GetVector(ArrayList data, int position, int offset, int blocksize, float value[3])
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Vector)
		return _Dynamic_GetMemberDataVector(data, position, offset, blocksize, value);
	else if (type == DynamicType_String)
	{
		int length = _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
		char[] buffer = new char[length];
		_Dynamic_GetMemberDataString(data, position, offset, blocksize, buffer, length);
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
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Vector)
	{
		_Dynamic_SetMemberDataVector(data, position, offset, blocksize, value);
		return DynamicType_Vector;
	}
	else if (type == DynamicType_String)
	{
		char buffer[192];
		Format(buffer, sizeof(buffer), "{%f, %f, %f}", value[0], value[1], value[2]);
		_Dynamic_SetMemberDataString(data, position, offset, blocksize, buffer);
		return DynamicType_String;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock bool _Dynamic_GetVector(DynamicObject dynamic, const char[] membername, float[3] vector)
{
	if (!dynamic.IsValid(true))
		return false;
	
	int blocksize = dynamic.BlockSize;
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, position, offset, DynamicType_Vector))
		return false;
		
	return _GetVector(dynamic.Data, position, offset, blocksize, vector);
}

stock int _Dynamic_SetVector(DynamicObject dynamic, const char[] membername, const float value[3])
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	int blocksize = dynamic.BlockSize;
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, true, position, offset, DynamicType_Vector))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetVector(dynamic.Data, position, offset, blocksize, value, membername);
	_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	return offset;
}

stock bool _Dynamic_GetVectorByOffset(DynamicObject dynamic, int offset, float[3] value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	int position;
	if (!_Dynamic_RecalculateOffset(data, position, offset, blocksize))
		return false;
	
	return _GetVector(data, position, offset, blocksize, value);
}

stock bool _Dynamic_SetVectorByOffset(DynamicObject dynamic, int offset, const float value[3])
{
	if (!dynamic.IsValid(true))
		return false;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	
	int position;
	if (!_Dynamic_RecalculateOffset(data, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetVector(data, position, offset, blocksize, value);
	_Dynamic_CallOnChangedForwardByOffset(dynamic, offset, type);
	return true;
}

stock int _Dynamic_PushVector(DynamicObject dynamic, const float value[3], const char[] name="")
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	int position; int offset;
	int memberindex = _Dynamic_CreateMemberOffset(dynamic, position, offset, name, DynamicType_Vector);
	_Dynamic_SetMemberDataVector(dynamic.Data, position, offset, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, name, DynamicType_Vector);
	return memberindex;
}

stock bool _Dynamic_GetVectorByIndex(DynamicObject dynamic, int memberindex, float value[3])
{
	if (!dynamic.IsValid(true))
		return false;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
	
	return _Dynamic_GetVectorByOffset(dynamic, offset, value);
}

stock bool _Dynamic_GetMemberDataVector(ArrayList data, int position, int offset, int blocksize, float vector[3])
{
	// A vector has 3 cells of data to be retrieved
	for (int i=0; i<3; i++)
	{
		// Move the offset forward by one cell as this is where the value is stored
		offset++;
		
		// Calculate internal data array index and cell position
		_Dynamic_RecalculateOffset(data, position, offset, blocksize);
		
		// Get the value
		vector[i] = GetArrayCell(data, position, offset);
	}
	return true;
}

stock void _Dynamic_SetMemberDataVector(ArrayList data, int position, int offset, int blocksize, const float value[3])
{
	// A vector has 3 cells of data to be stored
	for (int i=0; i<3; i++)
	{
		// Move the offset forward by one cell as this is where the value is stored
		offset++;
		
		// Calculate internal data array index and cell position
		_Dynamic_RecalculateOffset(data, position, offset, blocksize);
		
		// Set the value
		SetArrayCell(data, position, value[i], offset);
	}
}