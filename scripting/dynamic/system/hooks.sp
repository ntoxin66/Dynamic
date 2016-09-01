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

#if defined _dynamic_system_hooks
  #endinput
#endif
#define _dynamic_system_hooks

stock bool _Dynamic_HookChanges(DynamicObject dynamic, Dynamic_HookType callback, Handle plugin)
{
	if (!dynamic.IsValid(true))
		return false;
	
	Handle forwards = dynamic.Forwards;
	if (forwards == null)
		dynamic.Forwards = forwards = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell);
	
	// Add forward to objects forward list
	AddToForward(forwards, plugin, callback);
	
	// Increment callback count
	dynamic.HookCount++;
	return true;
}

stock bool _Dynamic_UnHookChanges(DynamicObject dynamic, Dynamic_HookType callback, Handle plugin)
{
	if (!dynamic.IsValid(true))
		return false;
	
	Handle forwards = dynamic.Forwards;
	if (forwards == null)
		dynamic.Forwards = forwards = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell);
	
	// Remove forward from objects forward list
	RemoveFromForward(forwards, plugin, callback);
	
	// Decrement callback count
	if (--dynamic.HookCount == 0)
	{
		// Remove unused handle
		CloseHandle(forwards);
		dynamic.Forwards = null;
	}
	return true;
}

stock int _Dynamic_HookCount(DynamicObject dynamic)
{
	if (!dynamic.IsValid(true))
		return 0;
	
	return dynamic.HookCount;
}

stock void _Dynamic_CallOnChangedForward(DynamicObject dynamic, int offset, const char[] member, Dynamic_MemberType type)
{
	Handle forwards = dynamic.Forwards;
	if (forwards == null)
		return;
		
	Call_StartForward(forwards);
	Call_PushCell(dynamic);
	Call_PushCell(offset);
	Call_PushString(member);
	Call_PushCell(type);
	Call_Finish();
}

stock void _Dynamic_CallOnChangedForwardByOffset(DynamicObject dynamic, int offset, Dynamic_MemberType type)
{
	if (dynamic.HookCount > 0)
	{
		char membername[DYNAMIC_MEMBERNAME_MAXLEN];
		_Dynamic_GetMemberNameByOffset(dynamic, offset, membername, sizeof(membername));
		_Dynamic_CallOnChangedForward(dynamic, offset, membername, type);
	}
}