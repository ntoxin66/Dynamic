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

stock bool _Dynamic_GetString(int index, const char[] membername, char[] buffer, int length)
{
	if (!_Dynamic_IsValid(index, true))
	{
		buffer[0] = '\0';
		return false;
	}
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(data, index, membername, false, position, offset, blocksize, DynamicType_String))
	{
		buffer[0] = '\0';
		return false;
	}
	
	return _GetString(data, position, offset, blocksize, buffer, length);
}

stock int _Dynamic_SetString(int index, const char[] membername, const char[] value, int length, int valuelength)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	if (length == 0)
		length = ++valuelength;
	
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(data, index, membername, true, position, offset, blocksize, DynamicType_String, length))
		return INVALID_DYNAMIC_OFFSET;
	
	
	
	Dynamic_MemberType type = _SetString(data, position, offset, blocksize, value);
	CallOnChangedForward(index, offset, membername, type);
	return offset;
}

stock bool _Dynamic_GetStringByOffset(int index, int offset, char[] buffer, int length)
{
	if (!_Dynamic_IsValid(index, true))
	{
		buffer[0] = '\0';
		return false;
	}
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	if (!_Dynamic_RecalculateOffset(data, position, offset, blocksize))
	{
		buffer[0] = '\0';
		return false;
	}
	
	return _GetString(data, position, offset, blocksize, buffer, length);
}

stock bool _Dynamic_SetStringByOffset(int index, int offset, const char[] value, int length, int valuelength)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	if (length == 0)
		length = ++valuelength;
	
	int position;
	if (!_Dynamic_RecalculateOffset(data, position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetString(data, position, offset, blocksize, value);
	CallOnChangedForwardByOffset(index, offset, type);
	return true;
}

stock int _Dynamic_PushString(int index, const char[] value, int length, int valuelength, const char[] name)
{
	if (!_Dynamic_IsValid(index, true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	if (length == 0)
		length = ++valuelength;
	
	int position; int offset;
	int memberindex = _Dynamic_CreateMemberOffset(data, index, position, offset, blocksize, name, DynamicType_String, length);
	
	length+=2; // this can probably be removed (review Native_Dynamic_SetString for removal also)
	_Dynamic_SetMemberDataString(data, position, offset, blocksize, value);
	CallOnChangedForward(index, offset, name, DynamicType_String);
	return memberindex;
}

stock bool _Dynamic_GetStringByIndex(int index, int memberindex, char[] buffer, int length)
{
	if (!_Dynamic_IsValid(index, true))
	{
		buffer[0] = '\0';
		return false;
	}
	
	int offset = _Dynamic_GetMemberOffsetByIndex(index, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
	{
		buffer[0] = '\0';
		return false;
	}
	
	if (_Dynamic_GetStringByOffset(index, offset, buffer, length))
		return true;
		
	return false;
}

stock int _Dynamic_GetStringLength(int index, const char[] membername)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;

	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(data, index, membername, false, position, offset, blocksize, DynamicType_String))
		return 0;
	
	_Dynamic_RecalculateOffset(data, position, offset, blocksize);
	return _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
}

stock bool _Dynamic_CompareString(int index, const char[] membername, const char[] value, bool casesensitive)
{
	int offset = _Dynamic_GetMemberOffset(index, membername);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
	
	return _Dynamic_CompareStringByOffset(index, offset,  value, casesensitive);
}

stock bool _Dynamic_CompareStringByOffset(int index, int offset, const char[] value, bool casesensitive)
{
	int length = _Dynamic_GetStringLengthByOffset(index, offset);
	char[] buffer = new char[length];
	_Dynamic_GetStringByOffset(index, offset, buffer, length);
	
	PrintToServer("> Compare '%s' == '%s'", value, buffer);
	return StrEqual(value, buffer, casesensitive);	
}

stock int _Dynamic_GetStringLengthByOffset(int index, int offset)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	ArrayList data = GetArrayCell(s_Collection, index, Dynamic_Data);
	int blocksize = GetArrayCell(s_Collection, index, Dynamic_Blocksize);
	int position;
	_Dynamic_RecalculateOffset(data, position, offset, blocksize);
	return _Dynamic_GetMemberStringLength(data, position, offset, blocksize);
}

stock int _Dynamic_GetMemberStringLength(Handle array, int position, int offset, int blocksize)
{
	// Move the offset forward by one cell as this is where a strings length is stored
	offset++;
	
	// Calculate internal data array index and cell position
	_Dynamic_RecalculateOffset(array, position, offset, blocksize);
	
	// Return string length
	return GetArrayCell(array, position, offset);
}

stock void _Dynamic_SetMemberStringLength(Handle array, int position, int offset, int blocksize, int length)
{
	offset++;
	_Dynamic_RecalculateOffset(array, position, offset, blocksize);
	SetArrayCell(array, position, length, offset);
}

stock void _Dynamic_SetMemberDataString(Handle array, int position, int offset, int blocksize, const char[] buffer)
{
	int length = _Dynamic_GetMemberStringLength(array, position, offset, blocksize);
	
	// Move the offset forward by two cells as this is where the string data starts
	offset+=2;
	_Dynamic_RecalculateOffset(array, position, offset, blocksize);
	
	// Offsets for Strings must by multiplied by 4
	offset*=4;
	
	// Set string data cell by cell and recalculate offset incase the string data wraps onto a new array index
	int i;
	char letter;
	for (i=0; i < length; i++)
	{
		letter = buffer[i];
		SetArrayCell(array, position, letter, offset, true);
		
		// If the null terminator exists we are done
		if (letter == 0)
			return;
			
		offset++;
		_Dynamic_RecalculateOffset(array, position, offset, blocksize, false, true);
	}
	
	// Move back one offset once string is written to internal data array
	offset--;
	_Dynamic_RecalculateOffset(array, position, offset, blocksize, false, true);
	
	// Set null terminator
	SetArrayCell(array, position, 0, offset, true);
}

stock void _Dynamic_GetMemberDataString(Handle array, int position, int offset, int blocksize, char[] buffer, int length)
{
	// Move the offset forward by two cells as this is where the string data starts
	offset+=2;
	_Dynamic_RecalculateOffset(array, position, offset, blocksize, true);
	
	// Offsets for Strings must by multiplied by 4
	offset*=4;
	
	// Get string data cell by cell and recalculate offset incase the string data wraps onto a new array index
	int i; char letter;
	for (i=0; i < length; i++)
	{
		letter = view_as<char>(GetArrayCell(array, position, offset, true));
		buffer[i] = letter;
		
		// If the null terminator exists we are done
		if (letter == 0)
			return;
			
		offset++;
		_Dynamic_RecalculateOffset(array, position, offset, blocksize, false, true);
	}
	
	// Add null terminator to end of string
	buffer[i-1] = '0';
}