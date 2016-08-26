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

stock bool _Dynamic_HookChanges(int index, Dynamic_HookType callback, Handle plugin)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle forwards = GetArrayCell(s_Collection, index, Dynamic_Forwards);
	if (forwards == null)
	{
		forwards = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell);
		SetArrayCell(s_Collection, index, forwards, Dynamic_Forwards);
	}
	
	// Add forward to objects forward list
	AddToForward(forwards, plugin, callback);
	
	// Store new callback count
	int count = GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, ++count, Dynamic_CallbackCount);
	return true;
}

stock bool _Dynamic_UnHookChanges(int index, Dynamic_HookType callback, Handle plugin)
{
	if (!_Dynamic_IsValid(index, true))
		return false;
	
	Handle forwards = GetArrayCell(s_Collection, index, Dynamic_Forwards);
	if (forwards == null)
		return false;
	
	// Remove forward from objects forward list
	RemoveFromForward(forwards, plugin, callback);
	
	// Store new callback count
	int count = GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
	SetArrayCell(s_Collection, index, --count, Dynamic_CallbackCount);
	
	if (count == 0)
	{
		CloseHandle(forwards);
		SetArrayCell(s_Collection, index, 0, Dynamic_Forwards);
	}
	return true;
}

stock int _Dynamic_CallbackCount(int index)
{
	if (!_Dynamic_IsValid(index, true))
		return 0;
	
	return GetArrayCell(s_Collection, index, Dynamic_CallbackCount);
}

stock void CallOnChangedForward(int index, int offset, const char[] member, Dynamic_MemberType type)
{
	Handle forwards = GetArrayCell(s_Collection, index, Dynamic_Forwards);
	if (forwards == null)
		return;
		
	Call_StartForward(forwards);
	Call_PushCell(index);
	Call_PushCell(offset);
	Call_PushString(member);
	Call_PushCell(type);
	Call_Finish();
}

stock void CallOnChangedForwardByOffset(int index, int offset, Dynamic_MemberType type)
{
	if (GetArrayCell(s_Collection, index, Dynamic_CallbackCount) > 0)
	{
		char membername[DYNAMIC_MEMBERNAME_MAXLEN];
		_Dynamic_GetMemberNameByOffset(index, offset, membername, sizeof(membername));
		CallOnChangedForward(index, offset, membername, type);
	}
}