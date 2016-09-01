#include <dynamic>
#pragma newdecls required
#pragma semicolon 1

public void OnPluginStart()
{
	// local reference values for storage
	bool bvalue = false;
	Dynamic dvalue = INVALID_DYNAMIC_OBJECT;
	float fvalue = 0.0;
	Handle hvalue = null;
	int ivalue = 0;
	char svalue[16] = "";
	float vvalue[3] = {0.0, 0.0, 0.0};
	
	// Creating a dynamic object
	Dynamic dynamic = Dynamic();
	
	// Lets show each types setter
	dynamic.SetBool("Bool", bvalue);
	dynamic.SetDynamic("Dynamic", dvalue);
	dynamic.SetFloat("Float", fvalue);
	dynamic.SetHandle("Handle", hvalue);
	dynamic.SetInt("Int", ivalue);
	dynamic.SetString("String", svalue);
	dynamic.SetVector("Vector", vvalue);
	
	// Lets get everything
	bvalue = dynamic.GetBool("Bool");
	dvalue = dynamic.GetDynamic("Dynamic");
	fvalue = dynamic.GetFloat("Float");
	hvalue = dynamic.GetHandle("Handle");
	ivalue = dynamic.GetInt("Int");
	dynamic.GetString("String", svalue, sizeof(svalue));
	dynamic.GetVector("Vector", vvalue);
	
	// The following types have default value support
	bvalue = dynamic.GetBool("Bool", bvalue);
	fvalue = dynamic.GetFloat("Float", fvalue);
	ivalue = dynamic.GetInt("Int", ivalue);
	
	// Dont forget to dispose!
	dynamic.Dispose();
}