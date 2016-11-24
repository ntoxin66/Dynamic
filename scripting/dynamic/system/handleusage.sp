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

#if defined _dynamic_system_handleusage
  #endinput
#endif
#define _dynamic_system_handleusage

public void _Dynamic_HandleUsage(any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientConnected(client))
		return;

	// Loop plugins
	Handle iterator = GetPluginIterator();
	Handle plugin;
	int count;
	char pluginname[64];
	while (MorePlugins(iterator))
	{
		plugin = ReadPlugin(iterator);
		count = _Dynamic_HandleUsage_CountPluginHandles(plugin);
		
		if (count == 0)
			continue;
			
		GetPluginInfo(plugin, PlInfo_Name, pluginname, sizeof(pluginname));
		PrintToConsole(client, "-> `%s`: %d Handles", pluginname, count);
	}
	CloseHandle(iterator);
}

stock int _Dynamic_HandleUsage_CountPluginHandles(Handle plugin)
{
	int count = 0;
	DynamicObject dynamic;
	for (int i = MAXPLAYERS; i < s_CollectionSize; i++)
	{
		dynamic = view_as<DynamicObject>(i);
		
		// Skip disposed objects
		if (!dynamic.IsValid(false))
			continue;
			
		if (dynamic.OwnerPlugin == plugin)
			count++;
	}
	return count;
}
