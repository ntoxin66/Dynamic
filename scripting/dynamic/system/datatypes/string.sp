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

#if defined _dynamic_system_datatypes_string
  #endinput
#endif
#define _dynamic_system_datatypes_string

stock bool _GetString(ArrayList data, int position, int offset, int blocksize, char[] buffer, int length)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		_Dynamic_GetMemberDataString(data, position, offset, blocksize, buffer, length);
		return true;
	}
	else if (type == DynamicType_Int)
	{
		int value = _Dynamic_GetMemberDataInt(data, position, offset, blocksize);
		IntToString(value, buffer, length);
		return true;
	}
	else if (type == DynamicType_Float)
	{
		float value = _Dynamic_GetMemberDataFloat(data, position, offset, blocksize);
		FloatToString(value, buffer, length);
		return true;
	}
	else if (type == DynamicType_Bool)
	{
		if (_Dynamic_GetMemberDataInt(data, position, offset, blocksize))
			Format(buffer, length, "True");
		else
			Format(buffer, length, "False");
		return true;
	}
	else if (type == DynamicType_Vector)
	{
		float vector[3];
		_Dynamic_GetMemberDataVector(data, position, offset, blocksize, vector);
		Format(buffer, length, "{%f, %f, %f}", vector[0], vector[1], vector[2]);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		buffer[0] = '\0';
		return false;
	}
}

stock Dynamic_MemberType _SetString(ArrayList data, int position, int offset, int blocksize, const char[] value)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_String)
	{
		_Dynamic_SetMemberDataString(data, position, offset, blocksize, value);
		return DynamicType_String;
	}
	else if (type == DynamicType_Int)
	{
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, StringToInt(value));
		return DynamicType_Int;
	}
	else if (type == DynamicType_Float)
	{
		_Dynamic_SetMemberDataFloat(data, position, offset, blocksize, StringToFloat(value));
		return DynamicType_Float;
	}
	else if (type == DynamicType_Bool)
	{
		if (StrEqual(value, "True"))
			_Dynamic_SetMemberDataInt(data, position, offset, blocksize, true);
		else if (StrEqual(value, "1"))
			_Dynamic_SetMemberDataInt(data, position, offset, blocksize, true);
		else
			_Dynamic_SetMemberDataInt(data, position, offset, blocksize, false);
		return DynamicType_Bool;
	}
	else if (type == DynamicType_Vector)
	{
		float vector[3];
		if (!GetVectorFromString(value, vector))
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
			return DynamicType_Unknown;
		}
		
		_SetVector(data, position, offset, blocksize, vector);
		return DynamicType_Vector;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock bool _Dynamic_GetString(DynamicObject dynamic, const char[] membername, char[] buffer, int length)
{
	if (!dynamic.IsValid(true))
	{
		buffer[0] = '\0';
		return false;
	}
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, offset, DynamicType_String))
	{
		buffer[0] = '\0';
		return false;
	}
	
	return _GetString(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, buffer, length);
}

stock DynamicOffset _Dynamic_SetString(DynamicObject dynamic, const char[] membername, const char[] value, int length, int valuelength)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	if (length == 0)
		length = ++valuelength;
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, true, offset, DynamicType_String, length))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetString(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	return offset;
}

stock bool _Dynamic_GetStringByOffset(DynamicObject dynamic, DynamicOffset offset, char[] buffer, int length)
{
	if (!dynamic.IsValid(true))
	{
		buffer[0] = '\0';
		return false;
	}
	
	return _GetString(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, buffer, length);
}

stock bool _Dynamic_SetStringByOffset(DynamicObject dynamic, DynamicOffset offset, const char[] value, int length, int valuelength)
{
	if (!dynamic.IsValid(true))
		return false;
	
	Dynamic_MemberType type = _SetString(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForwardByOffset(dynamic, offset, type);
	return true;
}

stock int _Dynamic_PushString(DynamicObject dynamic, const char[] value, int length, int valuelength, const char[] name)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_INDEX;
	
	if (length == 0)
		length = ++valuelength;
	
	DynamicOffset offset;
	int memberindex = _Dynamic_CreateMemberOffset(dynamic, offset, name, DynamicType_String, length);
	
	length+=2; // this can probably be removed (review Native_Dynamic_SetString for removal also)
	_Dynamic_SetMemberDataString(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForward(dynamic, offset, name, DynamicType_String);
	return memberindex;
}

stock bool _Dynamic_GetStringByIndex(DynamicObject dynamic, int memberindex, char[] buffer, int length)
{
	if (!dynamic.IsValid(true))
	{
		buffer[0] = '\0';
		return false;
	}
	
	DynamicOffset offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
	{
		buffer[0] = '\0';
		return false;
	}
	
	if (_Dynamic_GetStringByOffset(dynamic, offset, buffer, length))
		return true;
		
	return false;
}

stock int _Dynamic_GetStringLength(DynamicObject dynamic, const char[] membername)
{
	if (!dynamic.IsValid(true))
		return 0;
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, offset, DynamicType_String))
		return 0;
	
	return _Dynamic_GetMemberStringLength(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize);
}

stock bool _Dynamic_CompareString(DynamicObject dynamic, const char[] membername, const char[] value, bool casesensitive)
{
	DynamicOffset offset = _Dynamic_GetMemberOffset(dynamic, membername);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
	
	return _Dynamic_CompareStringByOffset(dynamic, offset, value, casesensitive);
}

stock bool _Dynamic_CompareStringByOffset(DynamicObject dynamic, DynamicOffset offset, const char[] value, bool casesensitive)
{
	int length = _Dynamic_GetStringLengthByOffset(dynamic, offset);
	char[] buffer = new char[length];
	_Dynamic_GetStringByOffset(dynamic, offset, buffer, length);
	
	PrintToServer("> Compare '%s' == '%s'", value, buffer);
	return StrEqual(value, buffer, casesensitive);	
}

stock int _Dynamic_GetStringLengthByOffset(DynamicObject dynamic, DynamicOffset offset)
{
	if (!dynamic.IsValid(true))
		return 0;
	
	return _Dynamic_GetMemberStringLength(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize);
}

stock int _Dynamic_GetMemberStringLength(ArrayList data, int position, int offset, int blocksize)
{
	// Move the offset forward by one cell as this is where a strings length is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(position, offset, blocksize);
	
	// Return string length
	return data.Get(position, offset);
}

stock void _Dynamic_SetMemberStringLength(ArrayList data, DynamicOffset offset, int blocksize, int length)
{
	offset = offset.Clone(blocksize, 1);
	data.Set(offset.Index, length, offset.Cell);
}

stock void _Dynamic_SetMemberDataString(ArrayList data, int position, int offset, int blocksize, const char[] buffer)
{
	int length = _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
	
	// Move the offset forward by two cells as this is where the string data starts
	offset+=2;
	_Dynamic_RecalculateOffset(position, offset, blocksize);
	
	// Offsets for Strings must by multiplied by 4
	offset*=4;
	
	// Set string data cell by cell and recalculate offset incase the string data wraps onto a new array index
	int i;
	char letter;
	for (i=0; i < length; i++)
	{
		letter = buffer[i];
		SetArrayCell(data, position, letter, offset, true);
		
		// If the null terminator exists we are done
		if (letter == 0)
			return;
			
		offset++;
		_Dynamic_RecalculateOffset(position, offset, blocksize, true);
	}
	
	// Move back one offset once string is written to internal data array
	offset--;
	_Dynamic_RecalculateOffset(position, offset, blocksize, true);
	
	// Set null terminator
	SetArrayCell(data, position, 0, offset, true);
}

stock void _Dynamic_GetMemberDataString(ArrayList data, int position, int offset, int blocksize, char[] buffer, int length)
{
	// Move the offset forward by two cells as this is where the string data starts
	offset+=2;
	_Dynamic_RecalculateOffset(position, offset, blocksize);
	
	// Offsets for Strings must by multiplied by 4
	offset*=4;
	
	// Get string data cell by cell and recalculate offset incase the string data wraps onto a new array index
	int i; char letter;
	for (i=0; i < length; i++)
	{
		letter = view_as<char>(data.Get(position, offset, true));
		buffer[i] = letter;
		
		// If the null terminator exists we are done
		if (letter == 0)
			return;
			
		offset++;
		_Dynamic_RecalculateOffset(position, offset, blocksize, true);
	}
	
	// Add null terminator to end of string
	buffer[i-1] = '0';
}