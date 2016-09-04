#include <dynamic>
#pragma newdecls required
#pragma semicolon 1

bool bvalue = false;
Dynamic dvalue = INVALID_DYNAMIC_OBJECT;
float fvalue = 0.0;
Handle hvalue = null;
int ivalue = 0;
char svalue[16] = "";
float vvalue[3] = {0.0, 0.0, 0.0};

public void OnPluginStart()
{
	Dynamic dynamic = Dynamic();
	
	dynamic.SetBool("Bool", false);
	dynamic.SetDynamic("Dynamic", INVALID_DYNAMIC_OBJECT);
	dynamic.SetFloat("Float", 0.0);
	dynamic.SetHandle("Handle", null);
	dynamic.SetInt("Int", 0);
	dynamic.SetString("String", "");
	dynamic.SetVector("Vector", NULL_VECTOR);
	
	bvalue = dynamic.GetBool("Bool");
	dvalue = dynamic.GetDynamic("Dynamic");
	fvalue = dynamic.GetFloat("Float");
	hvalue = dynamic.GetHandle("Handle");
	ivalue = dynamic.GetInt("Int");
	dynamic.GetString("String", svalue, sizeof(svalue));
	dynamic.GetVector("Vector", vvalue);
	
	bvalue = dynamic.GetBool("Bool", bvalue);
	fvalue = dynamic.GetFloat("Float", fvalue);
	ivalue = dynamic.GetInt("Int", ivalue);
	
	dynamic.Dispose();
}