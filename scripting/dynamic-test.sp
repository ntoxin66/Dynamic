#include <sourcemod>
#include <dynamic>

public Plugin myinfo =
{
	name = "Dynamic Test",
	author = "Neuro Toxin",
	description = "Benchmarks and Tests all Dynamic Object aspects",
	version = "1.0.0",
	url = ""
}

public void OnPluginStart()
{
    BenchmarkTest();
}

stock void BenchmarkTest()
{
	int objectcount = 1000;
	int membercount = 99; // must be a multiple of 3

	PrintToServer("[SM] Preparing benchmark Test...");
	Dynamic someoject;
	char membernames[99][DYNAMIC_MEMBERNAME_MAXLEN];
	int memberoffsets[99];
	char buffer[DYNAMIC_MEMBERNAME_MAXLEN];
	int ival; float fval; char sval[DYNAMIC_MEMBERNAME_MAXLEN];
	int offset;
    
	// Make member names
	for (int x = 0; x < membercount; x++)
	{
		Format(membernames[x], DYNAMIC_MEMBERNAME_MAXLEN, "m_Field_%d", x);
	}
	PrintToServer("[SM] Starting Benchmark Tests...");

	// Create objectcount objects with 99 fields in each
	float start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = Dynamic(16, 0);
		//someoject.HookChanges(OnDynamicMemberChanged);
	}
	PrintToServer("Created %d dynamic object(s) in %f second(s)", objectcount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 4; p++)
			{
				if (p == 1)
				{
					memberoffsets[x] = someoject.SetInt(membernames[x], x+i+p);
					x++;
				}
				else if (p==2)
				{
					memberoffsets[x] = someoject.SetFloat(membernames[x], float(x+i+p));
					x++;
				}
				else if (p==3)
				{
					memberoffsets[x] = someoject.SetString(membernames[x], "Some nice string that has some data", 128);
				}
			}
		}
	}
	PrintToServer("Created %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 4; p++)
			{
				if (p == 1)
				{
					someoject.GetInt(membernames[x]);
					x++;
				}
				else if (p==2)
				{
					someoject.GetFloat(membernames[x]);
					x++;
				}
				else if (p==3)
				{
					someoject.GetString(membernames[x], buffer, sizeof(buffer));
				}
			}
		}
	}
	PrintToServer("Read %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 4; p++)
			{
				if (p == 1)
				{
					someoject.GetIntByOffset(memberoffsets[x]);
					x++;
				}
				else if (p==2)
				{
					someoject.GetFloatByOffset(memberoffsets[x]);
					x++;
				}
				else if (p==3)
				{
					someoject.GetStringByOffset(memberoffsets[x], buffer, sizeof(buffer));
				}
			}
		}
	}
	PrintToServer("Read %d dynamic member(s) using offsets in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 4; p++)
			{
				ival = x+i+p;
				fval = float(x+i+p);

				if (p == 1)
				{
					if (someoject.GetInt(membernames[x]) != ival)
						PrintToServer("!! Member data INVALID! (Int)");
					if (someoject.GetFloat(membernames[x]) != fval)
					PrintToServer("!! Conversion error (Int2Float)");
	
					someoject.GetString(membernames[x], buffer, sizeof(buffer));
					IntToString(ival, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Int2String)");
					x++;
				}
				else if (p==2)
				{
					if (someoject.GetFloat(membernames[x]) != fval)
						PrintToServer("!! Member data INVALID! (Float)");
					if (someoject.GetInt(membernames[x]) != ival)
						PrintToServer("!! Conversion error (FloatToInt)");

					someoject.GetString(membernames[x], buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Float2String)");
					x++;
				}
				else if (p==3)
				{
					someoject.GetString(membernames[x], buffer, sizeof(buffer));
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
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 4; p++)
			{
				if (p == 1)
				{
					someoject.SetInt(membernames[x], x+i+p);
					x++;
				}
				else if (p==2)
				{
					someoject.SetFloat(membernames[x], float(x+i+p));
					x++;
				}
				else if (p==3)
				{
					someoject.SetString(membernames[x], "Some nice string that has some data");
				}
			}
		}
	}
	PrintToServer("Updated %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);

	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		for (int x = 0; x < membercount; x++)
		{
			for (int p = 1; p < 4; p++)
			{
				ival = x+i+p;
				fval = float(x+i+p);
				offset = someoject.GetMemberOffset(membernames[x]);

				if (p == 1)
				{
					if (someoject.GetIntByOffset(offset) != ival)
						PrintToServer("!! Member data INVALID! (Int)");
					if (someoject.GetFloatByOffset(offset) != fval)
						PrintToServer("!! Conversion error (Int2Float)");

					someoject.GetStringByOffset(offset, buffer, sizeof(buffer));
					IntToString(ival, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Int2String)");
					x++;
				}
				else if (p==2)
				{
					if (someoject.GetFloatByOffset(offset) != fval)
						PrintToServer("!! Member data INVALID! (Float)");
					if (someoject.GetIntByOffset(offset) != ival)
						PrintToServer("!! Conversion error (FloatToInt)");

					someoject.GetStringByOffset(offset, buffer, sizeof(buffer));
					FloatToString(fval, sval, sizeof(sval));
					if (!StrEqual(buffer, sval))
						PrintToServer("!! Conversion error (Float2String)");
					x++;
				}
				else if (p==3)
				{
					someoject.GetStringByOffset(offset, buffer, sizeof(buffer));
					if (!StrEqual(buffer, "Some nice string that has some data"))
						PrintToServer("!! Member data INVALID! (String)");
				}
			}
		}
	}
	PrintToServer("Offset verification with %d dynamic member(s) in %f second(s)", objectcount * membercount, GetEngineTime() - start);
	
	start = GetEngineTime();
	for (int i=0; i<objectcount; i++)
	{
		someoject = view_as<Dynamic>(i);
		someoject.Dispose();
	}
	PrintToServer("Disposed %d dynamic object(s) in %f second(s)", objectcount, GetEngineTime() - start);
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
		case DynamicType_String:
		{
			char somestring[64];
			obj.GetStringByOffset(offset, somestring, sizeof(somestring));
			PrintToServer("[%d] <string>obj.%s = '%s'", offset, member, somestring);
		}
	}
}
