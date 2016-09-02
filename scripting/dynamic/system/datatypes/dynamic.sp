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

#if defined _dynamic_system_datatypes_dynamic
  #endinput
#endif
#define _dynamic_system_datatypes_dynamic

stock DynamicObject _GetDynamic(ArrayList data, int position, int offset, int blocksize)
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Dynamic)
		return view_as<DynamicObject>(_Dynamic_GetMemberDataInt(data, position, offset, blocksize));
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return INVALID_DYNAMIC_OBJECT;
	}
}

stock Dynamic_MemberType _SetDynamic(DynamicObject dynamic, ArrayList data, int position, int offset, int blocksize, DynamicObject value, const char[] membername="")
{
	Dynamic_MemberType type = _Dynamic_GetMemberDataType(data, position, offset, blocksize);
	if (type == DynamicType_Dynamic)
	{
		// remove parent from current value
		DynamicObject currentvalue = view_as<DynamicObject>(_Dynamic_GetMemberDataInt(data, position, offset, blocksize));
		if (currentvalue != INVALID_DYNAMIC_OBJECT)
		{
			currentvalue.Parent = INVALID_DYNAMIC_OBJECT;
			currentvalue.ParentOffset = INVALID_DYNAMIC_OFFSET;
		}
		
		// set value and name
		_Dynamic_SetMemberDataInt(data, position, offset, blocksize, value.Index);
		
		// set parent
		if (value != INVALID_DYNAMIC_OBJECT)
		{
			value.Parent = dynamic;
			value.ParentOffset = offset;
		}
		return DynamicType_Dynamic;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Unsupported member datatype (%d)", type);
		return DynamicType_Unknown;
	}
}

stock DynamicObject _Dynamic_GetDynamic(DynamicObject dynamic, const char[] membername)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OBJECT;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, position, offset, DynamicType_Dynamic))
		return INVALID_DYNAMIC_OBJECT;
		
	return _GetDynamic(data, position, offset, blocksize);
}

stock int _Dynamic_SetDynamic(DynamicObject dynamic, const char[] membername, DynamicObject value)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	int position; int offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, true, position, offset, DynamicType_Dynamic))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetDynamic(dynamic, data, position, offset, blocksize, value, membername);
	_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	return offset;
}

stock DynamicObject _Dynamic_GetDynamicByOffset(DynamicObject dynamic, int offset)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OBJECT;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	int position;
	if (!_Dynamic_RecalculateOffset(position, offset, blocksize))
		return INVALID_DYNAMIC_OBJECT;
	
	return _GetDynamic(data, position, offset, blocksize);
}

stock bool _Dynamic_SetDynamicByOffset(DynamicObject dynamic, int offset, DynamicObject value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	
	int position;
	if (!_Dynamic_RecalculateOffset(position, offset, blocksize))
		return false;
	
	Dynamic_MemberType type = _SetDynamic(dynamic, data, position, offset, blocksize, value);
	_Dynamic_CallOnChangedForwardByOffset(dynamic, offset, type);
	return true;
}

stock int _Dynamic_PushDynamic(DynamicObject dynamic, DynamicObject value, const char[] name="")
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	int position; int offset;	
	int memberindex = _Dynamic_CreateMemberOffset(dynamic, position, offset, name, DynamicType_Dynamic);
	_Dynamic_SetMemberDataInt(dynamic.Data, position, offset, dynamic.BlockSize, value.Index);
	
	// set parent
	if (value != INVALID_DYNAMIC_OBJECT)
	{
		value.Parent = dynamic;
		value.ParentOffset = offset;
	}
	
	_Dynamic_CallOnChangedForward(dynamic, offset, name, DynamicType_Dynamic);
	return memberindex;
}

stock DynamicObject _Dynamic_GetDynamicByIndex(DynamicObject dynamic, int memberindex)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OBJECT;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return INVALID_DYNAMIC_OBJECT;
	
	return _Dynamic_GetDynamicByOffset(dynamic, offset);
}

stock bool _Dynamic_SetDynamicByIndex(DynamicObject dynamic, int memberindex, DynamicObject value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	int offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
	
	return _Dynamic_SetDynamicByOffset(dynamic, offset, value);
}