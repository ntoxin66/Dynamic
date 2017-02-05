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
			value.ParentOffset = DynamicOffset(position, offset);
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
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, offset, DynamicType_Dynamic))
		return INVALID_DYNAMIC_OBJECT;
		
	return _GetDynamic(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize);
}

stock DynamicOffset _Dynamic_SetDynamic(DynamicObject dynamic, const char[] membername, DynamicObject value)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, true, offset, DynamicType_Dynamic))
		return INVALID_DYNAMIC_OFFSET;
	
	Dynamic_MemberType type = _SetDynamic(dynamic, dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value, membername);
	_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	return offset;
}

stock DynamicObject _Dynamic_GetDynamicByOffset(DynamicObject dynamic, DynamicOffset offset)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OBJECT;
	
	return _GetDynamic(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize);
}

stock bool _Dynamic_SetDynamicByOffset(DynamicObject dynamic, DynamicOffset offset, DynamicObject value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	Dynamic_MemberType type = _SetDynamic(dynamic, dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value);
	_Dynamic_CallOnChangedForwardByOffset(dynamic, offset, type);
	return true;
}

stock int _Dynamic_PushDynamic(DynamicObject dynamic, DynamicObject value, const char[] name="")
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_INDEX;
	
	DynamicOffset offset;	
	int memberindex = _Dynamic_CreateMemberOffset(dynamic, offset, name, DynamicType_Dynamic);
	_Dynamic_SetMemberDataInt(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize, value.Index);
	
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
	
	DynamicOffset offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return INVALID_DYNAMIC_OBJECT;
	
	return _Dynamic_GetDynamicByOffset(dynamic, offset);
}

stock bool _Dynamic_SetDynamicByIndex(DynamicObject dynamic, int memberindex, DynamicObject value)
{
	if (!dynamic.IsValid(true))
		return false;
	
	DynamicOffset offset = _Dynamic_GetMemberOffsetByIndex(dynamic, memberindex);
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
	
	return _Dynamic_SetDynamicByOffset(dynamic, offset, value);
}