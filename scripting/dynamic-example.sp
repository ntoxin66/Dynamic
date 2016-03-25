#include <dynamic>
#include <dynamic-example>
#pragma newdecls required
#pragma semicolon 1

public void OnPluginStart()
{	
	// Creating dynamic objects is straight foward
	Dynamic someobj = Dynamic();
	
	// Setting integers, floats and booleans also
	someobj.SetInt("someint", 1);
	someobj.SetFloat("somefloat", 512.7);
	someobj.SetBool("somebool", true);
	
	// When dealing with strings...
	// you want to set an appropriate length if the value will change
	someobj.SetString("somestring", "What did you say?", 64);
	
	// If the value of a string will never change you might as well
	someobj.SetString("our_planets_name", "Earth");
	
	// Getting integers, floats and booleans is also straight foward
	int someint = someobj.GetInt("someint");
	float somefloat = someobj.GetFloat("somefloat");
	bool somebool = someobj.GetBool("somebool");
	
	// You can also include default values in case a member doesn't exist
	someint = someobj.GetInt("someint1", -1);
	somefloat = someobj.GetFloat("somefloat2", 7.25);
	somebool = someobj.GetBool("somebool2", false);
	
	// And the normal "extra" stuff to get a string in sourcespawn
	char somestring[64];
	someobj.GetString("somestring", somestring, sizeof(somestring));
	
	// You can also get an exact string by size
	int length = someobj.GetStringLength("our_planets_name");
	char[] our_planets_name = new char[length];
	someobj.GetString("our_planets_name", our_planets_name, length);
	
	// Dynamic supports type conversion!!!!!!!!!!!
	someint = someobj.GetInt("somefloat"); // rounds to floor
	somefloat = someobj.GetFloat("someint");
	someobj.GetString("somefloat", somestring, sizeof(somestring));
	someobj.GetString("somebool", somestring, sizeof(somestring));
	
	// You can even set dynamic objects within themselves
	Dynamic anotherobj = Dynamic();
	anotherobj.SetInt("someint", 128);
	someobj.SetObject("anotherobj", anotherobj);
	
	// You can name a dynamic object
	someobj.SetName("someobj");
	
	// So another plugin can access it like so
	someobj = Dynamic.FindByName("someobj");
	
	// You can also sort members within a dynamic object by name
	someobj.SortMembers(Sort_Ascending);

	// Sometimes you might want to iterate through members to accomplish stuff
	int count = someobj.MemberCount;
	int memberoffset;
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	
	PrintToServer("GETTING ALL DYNAMIC OBJECT MEMBERS");
	for (int i = 0; i < count; i++)
	{
		memberoffset = someobj.GetMemberOffsetByIndex(i);
		someobj.GetMemberNameByIndex(i, membername, sizeof(membername));
		
		switch (someobj.GetMemberType(memberoffset))
		{
			case DynamicType_Int:
			{
				someint = someobj.GetIntByOffset(memberoffset);
				PrintToServer("[%d] <int>someobj.%s = %d", memberoffset, membername, someint);
			}
			case DynamicType_Bool:
			{
				somebool = someobj.GetBoolByOffset(memberoffset);
				PrintToServer("[%d] <bool>someobj.%s = %d", memberoffset, membername, somebool);
			}
			case DynamicType_Float:
			{
				somefloat = someobj.GetFloatByOffset(memberoffset);
				PrintToServer("[%d] <float>someobj.%s = %f", memberoffset, membername, somefloat);
			}
			case DynamicType_String:
			{
				someobj.GetStringByOffset(memberoffset, somestring, sizeof(somestring));
				PrintToServer("[%d] <string>someobj.%s = '%s'", memberoffset, membername, somestring);
			}
			case DynamicType_Object:
			{
				anotherobj = someobj.GetObjectByOffset(memberoffset);
				someint = anotherobj.GetInt("someint");
				PrintToServer("[%d] <dynamic>.<int>someobj.%s.someint = %d", memberoffset, membername, someint);
			}
		}
	}
	
	// Sometimes you may want to listen to member changes within a callback
	PrintToServer("CALLBACK TESTING MESSAGES");
	someobj.HookChanges(OnDynamicMemberChanged);
	someobj.SetInt("someint", 256);
	someobj.SetFloat("somefloat", -12.04);
	someobj.SetBool("somebool", false);
	someobj.SetString("somestring", "ye sure moite");
	
	// You MUST! dispose your dynamic objects when your done.
	anotherobj.Dispose();
	
	// You can also dispose of any disposable members like this
	someobj.Dispose(true);
	
	// You can also use Dynamic to back Methodmap properties. This is another step
	// towards pawn feeling a bit more OO
	// -> Find the methodmap in 'include/dynamic-example.sp'
	PrintToServer("MYCLASS VALUES");
	MyClass myclass = MyClass();
	myclass.SomeInt = 66;
	myclass.SomeFloat = 58.5;
	myclass.SetSomeString("hello from toxin!");
	PrintToServer("myclass.SomeInt = %d;", myclass.SomeInt);
	PrintToServer("myclass.SomeFloat = %f;", myclass.SomeFloat);
	myclass.GetSomeString(somestring, sizeof(somestring));
	PrintToServer("myclass.SomeFloat = '%s';", somestring);
	myclass.Dispose();
}

public void OnDynamicMemberChanged(Dynamic obj, int offset, const char[] member, Dynamic_MemberType type)
{
	switch (type)
	{
		case DynamicType_Int:
		{
			PrintToServer("[%d] <int>obj.%s = %d", offset, member, obj.GetIntByOffset(offset));
		}
		case DynamicType_Float:
		{
			PrintToServer("[%d] <float>obj.%s = %f", offset, member, obj.GetFloatByOffset(offset));
		}
		case DynamicType_Bool:
		{
			PrintToServer("[%d] <bool>obj.%s = %d", offset, member, obj.GetBoolByOffset(offset));
		}
		case DynamicType_String:
		{
			char somestring[64];
			obj.GetStringByOffset(offset, somestring, sizeof(somestring));
			PrintToServer("[%d] <string>obj.%s = '%s'", offset, member, somestring);
		}
	}
}