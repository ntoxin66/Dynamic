/*
	In this example, you will see how Dynamic can parse a KeyValues file while using a hook
	to select the keys you would like to load.
*/

#include <dynamic>
#pragma newdecls required
#pragma semicolon 1

public void OnPluginStart()
{
	// The normal old begining for Dynamic
	Dynamic items_game = Dynamic();
	
	// Lets load `items_game.txt` and parse our hook callback
	items_game.ReadKeyValues("scripts/items/items_game.txt", 1024, PK_ReadDynamicKeyValue);
	
	// The hook has now done it's work and we are left with only a couple of subkeys
	Dynamic game_info = items_game.GetObject("game_info");
	Dynamic prefabs = items_game.GetObject("prefabs");
	Dynamic items = items_game.GetObject("items");
	Dynamic attributes = items_game.GetObject("attributes");
	
	// Lets make a new version of `items_game.txt`
	items_game.WriteKeyValues("scripts/items/items_game_dynamic.txt");
	
	// That's all folks, better clean up my trash!
	items_game.Dispose(true);
}

public Action PK_ReadDynamicKeyValue(Dynamic obj, const char[] member, int depth)
{
	// Allow the basekey (depth=0) to be loaded
	if (depth == 0)
		return Plugin_Continue;
	
	// Check all subkeys (depth=1) within the basekey (depth=0)
	if (depth == 1)
	{
		// Allow these subkeys (depth=1) in the basekey (depth=0) to load
		if (StrEqual(member, "game_info"))
			return Plugin_Continue;
		if (StrEqual(member, "prefabs"))
			return Plugin_Continue;
		if (StrEqual(member, "items"))
			return Plugin_Continue;
		if (StrEqual(member, "attributes"))
			return Plugin_Continue;
		else
		{
			// Block all other subkeys (depth=1)
			return Plugin_Stop;
		}
	}
	
	// Let all subkeys in higher depths load (depth>1)
	return Plugin_Continue;
}
