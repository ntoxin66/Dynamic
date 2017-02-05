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

#if defined _dynamic_system_commands
  #endinput
#endif
#define _dynamic_system_commands

stock void RegisterCommands()
{
	RegAdminCmd("sm_dynamic_selftest", OnDynamicSelfTestCommand, ADMFLAG_RCON, "performs a Dynamic SelfTest to verify Dynamic is running properly");
	RegAdminCmd("sm_dynamic_handles", OnDynamicHandlesCommand, ADMFLAG_RCON, "displays a Dynamic Handle usage report per plugin");
	RegAdminCmd("sm_dynamic_collectgarbage", OnDynamicCollectGarbageCommand, ADMFLAG_RCON, "runs Dynamic's garbage collector");
}

public Action OnDynamicSelfTestCommand(int client, int args)
{
	ReplyToCommand(client, "Dynamic is running a SelfTest...");
	RequestFrame(_Dynamic_SelfTest, (client > 0 ? GetClientUserId(client) : 0));
	return Plugin_Handled;
}

public Action OnDynamicHandlesCommand(int client, int args)
{
	PrintToConsole(client, "Dynamic is running a HandleUsage report...");
	RequestFrame(_Dynamic_HandleUsage, (client > 0 ? GetClientUserId(client) : 0));
	return Plugin_Handled;
}

public Action OnDynamicCollectGarbageCommand(int client, int args)
{
	PrintToConsole(client, "Dynamic is starting it's garbage collector...");
	_Dynamic_CollectGarbage();
	return Plugin_Handled;
}
