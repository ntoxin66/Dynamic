#include <dynamic>
#include <dynamic-example>
#pragma newdecls required
#pragma semicolon 1

public void OnPluginStart()
{
	// You can also use Dynamic to back Methodmap properties.
	// This is another step towards sourcepawn feeling a bit more OO
	// -> Find the methodmap in 'include/dynamic-example.sp'
	// -> This class was generated @ 'http://console.aus-tg.com/index.php?page=createdynamicclass'
	
	// Creating dynamic classes is straight foward
	MyClass someobj = MyClass();
	
	// Setting integers, floats and booleans also
	someobj.SomeInt = 1;
	someobj.SomeFloat = 512.7;
	someobj.SomeBool = true;
	
	// The strings length is now defined within the class initialiser code
	someobj.SetSomeString("What did you say?");
	
	// Getting integers, floats and booleans is also straight foward
	int someint = someobj.SomeInt;
	float somefloat = someobj.SomeFloat;
	bool somebool = someobj.SomeBool;
	
	// And the normal "extra" stuff to get a string in sourcespawn
	char somestring[64];
	someobj.GetSomeString(somestring, 64);
	
	// You can also get an exact string by size
	int length = someobj.GetStringLength("SomeString");
	someobj.GetSomeString(somestring, length);
	
	// Dynamic supports type conversion!!!!!!!!!!!
	// -> Type conversion is not possible inside of classes
	//someint = someobj.GetInt("somefloat"); // rounds to floor
	//somefloat = someobj.GetFloat("someint");
	//someobj.GetString("somefloat", somestring, sizeof(somestring));
	//someobj.GetString("somebool", somestring, sizeof(somestring));
	
	// You can even set dynamic objects within themselves
	Dynamic anotherobj = Dynamic();
	anotherobj.SetInt("someint", 128);
	someobj.SomeObject = anotherobj;
	
	// You can also get and set Handles
	someobj.SomeHandle = CreateArray();
	Handle somehandle = someobj.SomeHandle;
	PushArrayCell(somehandle, 1);
	
	// Vectors are also supported like so
	float somevec[3] = {1.0, 2.0, 3.0};
	someobj.SetSomeVector(NULL_VECTOR);
	someobj.SetSomeVector(somevec);
	someobj.GetSomeVector(somevec);
	
	// You can name a dynamic object
	someobj.SetName("someobj");
	
	// So another plugin can access it like so
	someobj = view_as<MyClass>(Dynamic.FindByName("someobj"));
	
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
			case DynamicType_Handle:
			{
				somehandle = someobj.GetHandleByOffset(memberoffset);
				PrintToServer("[%d] <Handle>.someobj.%s = %d", memberoffset, membername, somehandle);
			}
			case DynamicType_Vector:
			{
				someobj.GetVectorByOffset(memberoffset, somevec);
				PrintToServer("[%d] <Vector>.someobj.%s = {%f, %f, %f}", memberoffset, membername, somevec[0], somevec[1], somevec[2]);
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
	someobj.SetVector("somevec", view_as<float>({2.0, 3.0, 4.0}));
	
	// You MUST! dispose your dynamic objects when your done.
	anotherobj.Dispose();
	
	// You can also dispose of any disposable members like this
	// -> This includes auto closure of Handle datatypes
	someobj.Dispose(true);
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
		case DynamicType_Vector:
		{
			char somestring[64];
			obj.GetStringByOffset(offset, somestring, sizeof(somestring));
			PrintToServer("[%d] <Vector>obj.%s = %s", offset, member, somestring);
		}
	}
}