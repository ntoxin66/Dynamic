#include <sourcemod>
#include <dynamic>

public Plugin myinfo =
{
	name = "Dynamic Test",
	author = "Neuro Toxin",
	description = "Benchmarks and Tests all Dynamic Object aspects",
	version = "1.0.2",
	url = "https://forums.alliedmods.net/showthread.php?t=270519"
}

public void OnPluginStart()
{
    BenchmarkTest();
}

stock void BenchmarkTest()
{
	int objectcount = 1000;
	int membercount = 100; // must be a multiple of 5

	PrintToServer("[SM] Preparing benchmark Test...");
	Dynamic someobject;
	char membernames[100][DYNAMIC_MEMBERNAME_MAXLEN];
	DynamicOffset memberoffsets[100];
	char buffer[DYNAMIC_MEMBERNAME_MAXLEN];
	int ival; float fval; char sval[DYNAMIC_MEMBERNAME_MAXLEN]; float vector[3];
	DynamicOffset offset;
	Dynamic objects[1000];
    
	// Make member names
	for (int x = 0; x < membercount; x++)
	{
		Format(membernames[x], DYNAMIC_MEMBERNAME_MAXLEN, "m_Field_%d", x);
	}
	PrintToServer("[SM] Starting Benchmark Tests...");

	// Create objectcount objects with 100 fields in each
	float start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		objects[i] = Dynamic(16, 0);
		//someobject.HookChanges(OnDynamicMemberChanged);
	}
	PrintToServer("Created %d dynamic object(s) in %f second(s)", objectcount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someobject = objects[i];
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 6; p++)
			{
				if (p == 1)
				{
					memberoffsets[x] = someobject.SetInt(membernames[x], x+i+p);
					x++;
				}
				else if (p==2)
				{
					memberoffsets[x] = someobject.SetFloat(membernames[x], float(x+i+p));
					x++;
				}
				else if (p==3)
				{
					memberoffsets[x] = someobject.SetBool(membernames[x], true);
					x++;
				}
				else if (p==4)
				{
					memberoffsets[x] = someobject.SetVector(membernames[x], view_as<float>({1.0, 2.0, 3.0}));
					x++;
				}
				else if (p==5)
				{
					memberoffsets[x] = someobject.SetString(membernames[x], "Some nice string that has some data", 128);
				}
			}
		}
	}
	PrintToServer("Created %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);
	
	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someobject = objects[i];
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 6; p++)
			{
				if (p == 1)
				{
					someobject.GetInt(membernames[x]);
					x++;
				}
				else if (p==2)
				{
					someobject.GetFloat(membernames[x]);
					x++;
				}
				else if (p==3)
				{
					someobject.GetBool(membernames[x]);
					x++;
				}
				else if (p==4)
				{
					someobject.GetVector(membernames[x], vector);
					x++;
				}
				else if (p==5)
				{
					someobject.GetString(membernames[x], buffer, sizeof(buffer));
				}
			}
		}
	}
	PrintToServer("Read %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someobject = objects[i];
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 6; p++)
			{
				if (p == 1)
				{
					someobject.GetIntByOffset(memberoffsets[x]);
					x++;
				}
				else if (p==2)
				{
					someobject.GetFloatByOffset(memberoffsets[x]);
					x++;
				}
				else if (p==3)
				{
					someobject.GetBoolByOffset(memberoffsets[x]);
					x++;
				}
				else if (p==4)
				{
					someobject.GetVectorByOffset(memberoffsets[x], vector);
					x++;
				}
				else if (p==5)
				{
					someobject.GetStringByOffset(memberoffsets[x], buffer, sizeof(buffer));
				}
			}
		}
	}
	PrintToServer("Read %d dynamic member(s) using offsets in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someobject = objects[i];
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 6; p++)
			{
				ival = x+i+p;
				fval = float(x+i+p);

				if (p == 1)
				{
					if (someobject.GetInt(membernames[x]) != ival)
						PrintToServer("!! Member data INVALID! (Int)");
					if (someobject.GetFloat(membernames[x]) != fval)
						PrintToServer("!! Conversion error (Int2Float)");
					if (someobject.GetBool(membernames[x]) != true)
						PrintToServer("!! Conversion error (Int2Bool) - (%d != true) - (ival=%d)", someobject.GetBool(membernames[x]), ival);
					
					someobject.GetString(membernames[x], buffer, sizeof(buffer));
					IntToString(ival, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Int2String)");
					x++;
				}
				else if (p==2)
				{
					if (someobject.GetFloat(membernames[x]) != fval)
						PrintToServer("!! Member data INVALID! (Float)");
					if (someobject.GetInt(membernames[x]) != ival)
						PrintToServer("!! Conversion error (FloatToInt)");
					if (someobject.GetBool(membernames[x]) != true)
						PrintToServer("!! Conversion error (FloatToBool) - (%d != true) - (fval: %f)", someobject.GetBool(membernames[x]), fval);
					
					someobject.GetString(membernames[x], buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Float2String)");
					x++;
				}
				else if (p==3)
				{
					if (someobject.GetBool(membernames[x]) != true)
						PrintToServer("!! Conversion error (Bool)");
					if (someobject.GetFloat(membernames[x]) != 1.0)
						PrintToServer("!! Member data INVALID! (BoolToFloat)");
					if (someobject.GetInt(membernames[x]) != 1)
						PrintToServer("!! Conversion error (BoolToInt)");
					
					someobject.GetString(membernames[x], buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, "True"))
						PrintToServer("!! Conversion error (Bool2String) - ('%s' != 'True')", buffer);
					x++;
				}
				else if (p==4)
				{
					someobject.GetVector(membernames[x], vector);
					if (vector[0] != 1.0 || vector[1] != 2.0 || vector[2] != 3.0)
						PrintToServer("!! Data corruption for vector");
					x++;
				}
				else if (p==5)
				{
					someobject.GetString(membernames[x], buffer, sizeof(buffer));
					if (!StrEqual(buffer, "Some nice string that has some data"))
						PrintToServer("!! Member data INVALID! (String)");
				}
			}
		}
	}
	PrintToServer("Verified %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someobject = objects[i];
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 6; p++)
			{
				if (p == 1)
				{
					someobject.SetInt(membernames[x], x+i+p+1);
					x++;
				}
				else if (p==2)
				{
					someobject.SetFloat(membernames[x], float(x+i+p+1));
					x++;
				}
				else if (p==3)
				{
					someobject.SetBool(membernames[x], false);
					x++;
				}
				else if (p==4)
				{
					someobject.SetVector(membernames[x], view_as<float>({2.0, 3.0, 4.0}));
					x++;
				}
				else if (p==5)
				{
					someobject.SetString(membernames[x], "123Some nice string that has some data123");
				}
			}
		}
	}
	PrintToServer("Updated %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someobject = objects[i];
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 6; p++)
			{
				ival = x+i+p+1;
				fval = float(x+i+p+1);
				offset = someobject.GetMemberOffset(membernames[x]);

				if (p == 1)
				{
					if (someobject.GetIntByOffset(offset) != ival)
						PrintToServer("!! Member data INVALID! (Int)");
					if (someobject.GetFloatByOffset(offset) != fval)
						PrintToServer("!! Conversion error (Int2Float)");
					if (someobject.GetBoolByOffset(offset) != true)
						PrintToServer("!! Member data INVALID! (IntToBool)");

					someobject.GetStringByOffset(offset, buffer, sizeof(buffer));
					IntToString(ival, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Int2String)");
					x++;
				}
				else if (p==2)
				{
					if (someobject.GetFloatByOffset(offset) != fval)
						PrintToServer("!! Member data INVALID! (Float)");
					if (someobject.GetIntByOffset(offset) != ival)
						PrintToServer("!! Conversion error (FloatToInt)");
					if (someobject.GetBoolByOffset(offset) != true)
						PrintToServer("!! Member data INVALID! (FloatToBool)");

					someobject.GetStringByOffset(offset, buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Float2String)");
					x++;
				}
				else if (p==3)
				{
					if (someobject.GetBoolByOffset(offset) != false)
						PrintToServer("!! Member data INVALID! (Bool)");
					if (someobject.GetFloatByOffset(offset) != 0.0)
						PrintToServer("!! Member data INVALID! (BoolToFloat)");
					if (someobject.GetIntByOffset(offset) != 0)
						PrintToServer("!! Conversion error (BoolToInt)");
					
					someobject.GetStringByOffset(offset, buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, "False"))
						PrintToServer("!! Conversion error (Bool2String) - ('%s' != 'False'", buffer);
					x++;
				}
				else if (p==4)
				{
					someobject.GetVectorByOffset(offset, vector);
					if (vector[0] != 2.0 || vector[1] != 3.0 || vector[2] != 4.0)
						PrintToServer("!! Data corruption for vector using offset");
					x++;
				}
				else if (p==5)
				{
					someobject.GetStringByOffset(offset, buffer, sizeof(buffer));
					if (!StrEqual(buffer, "123Some nice string that has some data123"))
						PrintToServer("!! Member data INVALID! (String)");
				}
			}
		}
	}
	PrintToServer("Offset verification with %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);
	
	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someobject = objects[i];
		someobject.Dispose();
	}
	PrintToServer("Disposed %d dynamic object(s) in %f second(s)", objectcount, GetEngineTime() - start);
}

public void OnDynamicMemberChanged(Dynamic obj, DynamicOffset offset, const char[] member, Dynamic_MemberType type)
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
		case DynamicType_String:
		{
			char somestring[64];
			obj.GetStringByOffset(offset, somestring, sizeof(somestring));
			PrintToServer("[%d] <string>obj.%s = '%s'", offset, member, somestring);
		}
	}
}