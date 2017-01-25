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

public int _Dynamic_Plugins_GetIndex(Handle plugin)
{
	// Return plugin handle index if already registered
	int index = g_aPlugins.FindValue(plugin, 0);
	if (index > -1)
		return index;
		
	// Create forward and add plugin handle
	Handle pluginforward = CreateForward(ET_Ignore);
	AddToForward(pluginforward, plugin, GetFunctionByName(plugin, "_Dynamic_Plugins_PrivateFowardCallback")); // WildCard65: Add to forward requires a function ID of public function FROM PLUGIN YOUR ADDING FOR, using your own function id will result in a different function being added or native error.
	
	// Create new index and push plugin handle and forward
	index = g_aPlugins.Push(plugin);
	g_aPlugins.Set(index, pluginforward, 1);
	return index;
}

public bool _Dynamic_Plugins_IsLoaded(int plugin)
{
	// Get the plugins forward handle
	Handle pluginforward = g_aPlugins.Get(plugin, 1);
	
	// Check if the forward still has functions assigned to it
	if (GetForwardFunctionCount(pluginforward) == 0)
		return false;
		
	return true;
}

public Handle _Dynamic_Plugins_GetHandleFromIndex(int plugin)
{
	return g_aPlugins.Get(plugin);
}
