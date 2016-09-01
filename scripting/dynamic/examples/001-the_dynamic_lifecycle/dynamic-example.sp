#include <dynamic>
#pragma newdecls required
#pragma semicolon 1

public void OnPluginStart()
{
	// Creating a dynamic object
	Dynamic dynamic = Dynamic();
	
	// You must dispose of your dynamic objects!
	dynamic.Dispose();
	
	// You may want to set your reference to invalid
	dynamic = INVALID_DYNAMIC_OBJECT;
	
	// Sometimes you need to check if an object is still valid
	if (!dynamic.IsValid)
		dynamic = Dynamic();
	
	// What if you want to reset an object and keep the reference
	dynamic.Reset();
	
	// Dont forget to dispose!
	dynamic.Dispose();
}