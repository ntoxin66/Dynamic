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
	int client = 0;
	if (userid > 0)
	{
		client = GetClientOfUserId(userid);
		if (!IsClientConnected(client))
			client = 0;
	}
	
	_Dynamic_HandleUsage_TotalHandleCount(client);
	
	// Loop plugins
	Handle iterator = GetPluginIterator();
	Handle plugin;
	while (MorePlugins(iterator))
	{
		plugin = ReadPlugin(iterator);
		_Dynamic_HandleUsage_CountPluginHandles(plugin, client);
	}
	CloseHandle(iterator);
}

stock void _Dynamic_HandleUsage_TotalHandleCount(int client)
{
	int count = 0;
	int persistant = 0;
	DynamicObject dynamic;
	for (int i = MAXPLAYERS; i < s_CollectionSize; i++)
	{
		dynamic = view_as<DynamicObject>(i);
		
		// Skip disposed objects
		if (!dynamic.IsValid(false))
			continue;
		
		if (dynamic.Persistent)
			persistant++;
		
		count++;
	}
  
	ReplyToCommand(client, "-> Total Handles: %d (%d persistant handles)", count, persistant);
}

stock void _Dynamic_HandleUsage_CountPluginHandles(Handle plugin, int client)
{
	int count = 0;
	int persistant = 0;
	
	DynamicObject dynamic;
	for (int i = MAXPLAYERS; i < s_CollectionSize; i++)
	{
		dynamic = view_as<DynamicObject>(i);
		
		// Skip disposed objects
		if (!dynamic.IsValid(false))
			continue;
		
		if (dynamic.OwnerPluginHandle == plugin)
		{
			if (dynamic.Persistent)
				persistant++;
				
			count++;
		}
	}
	
	if (count == 0)
		return;
	
	char pluginname[64];
	GetPluginInfo(plugin, PlInfo_Name, pluginname, sizeof(pluginname));
	ReplyToCommand(client, "--> `%s`: %d Handles (%d persistant handles)", pluginname, count, persistant);
}
