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

#if defined _dynamic_system_selftest
  #endinput
#endif
#define _dynamic_system_selftest

public void _Dynamic_SelfTest(any userid)
{
	int client = 0;
	if (userid > 0)
	{
		client = GetClientOfUserId(userid);
		if (!IsClientConnected(client))
			client = 0;
	}
	
	// Test DynamicOffset methodmap
	if (!_Dynamic_DynamicOffsetTest(client))
		return;
	ReplyToCommand(client, "> DynamicOffset test completed");
	
	// Test offset alignments (initialisation offset vs findmemberoffset)
	
	// Test dynamic dynamic creation
	Dynamic test;
	if (!_Dynamic_InitialiseTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> Dynamic_Initialise test completed");
	
	// DynamicType_Int Test
	test.Reset();
	if (!_Dynamic_IntTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> DynamicType_Int test completed");
	
	// DynamicType_Float Test
	test.Reset();
	if (!_Dynamic_FloatTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> DynamicType_Float test completed");
	
	// DynamicType_String Test
	test.Reset();
	if (!_Dynamic_StringTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> DynamicType_String test completed");
	
	// DynamicType_Bool Test
	test.Reset();
	if (!_Dynamic_BoolTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> DynamicType_Bool test completed");
	
	// DynamicType_Dynamic Test
	test.Reset();
	if (!_Dynamic_DynamicTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> DynamicType_Dynamic test completed");
	
	// DynamicType_Handle Test
	test.Reset();
	if (!_Dynamic_HandleTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> DynamicType_Handle test completed");
	
	// DynamicType_Vector Test
	test.Reset();
	if (!_Dynamic_VectorTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> DynamicType_Vector test completed");
	
	// DynamicType_Function Test
	test.Reset();
	if (!_DynamicType_FunctionTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> DynamicType_Function test completed");
	
	// Dynamic.GetMemberNameByIndex(Dynamic params) Test
	test.Reset();
	if (!_Dynamic_GetMemberNameByIndexTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> Dynamic_GetMemberNameByIndex test completed");
	
	// Dynamic.FindByMemberValue(Dynamic params) Test
	test.Reset();
	if (!_Dynamic_FindByMemberValueTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> Dynamic_FindByMemberValue test completed");
	
	// Dynamic_KeyValues Test
	test.Reset();
	if (!_Dynamic_KeyValuesTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> Dynamic_KeyValues test completed");
	
	// Dynamic_FlatConfigTest
	test.Reset();
	if (!_Dynamic_FlatConfigTest(client, test))
	{
		test.Dispose();
		return;
	}
	ReplyToCommand(client, "> Dynamic_FlatConfigTest test completed");
	
	test.Reset(true);
	_Dynamic_DBSchemeTest(client, test);
	test.Dispose();
}

stock bool _Dynamic_DynamicOffsetTest(int client)
{
	// Offset accessor testing
	DynamicOffset offset;
	for (int i=0; i<65536; i+=10)
	{
		for (int x=0; x<65536; x+=10)
		{
			offset = DynamicOffset(i, x);
			
			if (offset.Index != i)
			{
				ReplyToCommand(client, "DynamicOffset test failed: ErrorCode Bx1");
				ReplyToCommand(client, "> %d should equal %d", offset.Index, i);
				return false;
			}
			else if (offset.Cell != x)
			{
				ReplyToCommand(client, "DynamicOffset test failed: ErrorCode Bx2");
				ReplyToCommand(client, "> %d should equal %d", offset.Cell, x);
				return false;
			}
		}
	}
	
	// Test cloner
	offset = DynamicOffset(0,0);
	offset = offset.Clone(16, 1);
	if (offset.Index != 0)
	{
		ReplyToCommand(client, "DynamicOffset test failed: ErrorCode Bx3");
		ReplyToCommand(client, "> %d should equal %d", offset.Index, 0);
		return false;
	}
	if (offset.Cell != 1)
	{
		ReplyToCommand(client, "DynamicOffset test failed: ErrorCode Bx4");
		ReplyToCommand(client, "> %d should equal %d", offset.Index, 1);
		return false;
	}
	offset = offset.Clone(12, 11);
	if (offset.Index != 1)
	{
		ReplyToCommand(client, "DynamicOffset test failed: ErrorCode Bx5");
		ReplyToCommand(client, "> %d should equal %d", offset.Index, 1);
		return false;
	}
	if (offset.Cell != 0)
	{
		ReplyToCommand(client, "DynamicOffset test failed: ErrorCode Bx6");
		ReplyToCommand(client, "> %d should equal %d", offset.Index, 0);
		return false;
	}
	return true;
}

stock bool _Dynamic_InitialiseTest(int client, Dynamic &test)
{
	// Check initial test dynamic is valid
	test = Dynamic();
	if (!test.IsValid)
	{
		ReplyToCommand(client, "Dynamic_Initialise test failed: ErrorCode Ax1");
		ReplyToCommand(client, "> %d should equal %d", test.IsValid, true);
		ReplyToCommand(client, "> test=%d", test);
		return false;
	}
	return true;
}

stock bool _Dynamic_IntTest(int client, Dynamic test)
{
	// Test value
	int value = GetRandomInt(0, 32000);
	
	// Offset test
	DynamicOffset offset = test.SetInt("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x1");
		ReplyToCommand(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Int test
	if (test.GetInt("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x2");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("val"), value);
		return false;
	}
	
	// Float test
	float fvalue = float(value);
	if (test.GetFloat("val") != fvalue)
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x3");
		ReplyToCommand(client, "> %f should equal %f", test.GetFloat("val"), fvalue);
		return false;
	}
	test.SetFloat("val", fvalue);
	if (test.GetInt("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x4");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("val"), value);
		return false;
	}
	
	// String test
	char cvalue[2][16];
	if (!test.GetString("val", cvalue[0], sizeof(cvalue[])))
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x5");
		ReplyToCommand(client, "> Couldn't read int as string");
		return false;
	}
	IntToString(value, cvalue[1], sizeof(cvalue[]));
	if (!StrEqual(cvalue[0], cvalue[1]))
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x6");
		ReplyToCommand(client, "> '%s' should equal '%s'", cvalue[0], cvalue[1]);
		return false;
	}
	test.SetString("val", cvalue[1]);
	if (test.GetInt("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x7");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("val"), value);
		return false;
	}
	
	// Dynamic not supported - no test required
	
	// Boolean test
	test.SetInt("val", 0);
	if (test.GetBool("val"))
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x8");
		ReplyToCommand(client, "> %d should equal %d", test.GetBool("val"), false);
		return false;
	}
	test.SetInt("val", 1);
	if (!test.GetBool("val"))
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x9");
		ReplyToCommand(client, "> %d should equal %d", test.GetBool("val"), true);
		return false;
	}
	test.SetBool("val", false);
	if (test.GetInt("val"))
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x10");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("val"), false);
		return false;
	}
	test.SetBool("val", true);
	if (!test.GetInt("val"))
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x11");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("val"), true);
		return false;
	}
	
	// Handle not supported - no test required
	// Vector not supported - no test required
	
	// Set/Get by Offset test
	value = GetRandomInt(0, 32000);
	offset = test.GetMemberOffset("val");
	test.SetIntByOffset(offset, value);
	if (test.GetIntByOffset(offset) != value)
	{
		ReplyToCommand(client, "DynamicType_Int test failed: ErrorCode 0x12");
		ReplyToCommand(client, "> %d should equal %d", test.GetIntByOffset(offset), value);
		return false;
	}
	
	return true;
}

stock bool _Dynamic_FloatTest(int client, Dynamic test)
{
	// Test value
	float value = GetRandomFloat(0.0, 32000.0);
	
	// Offset test
	DynamicOffset offset = test.SetFloat("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x1");
		ReplyToCommand(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Float test
	if (test.GetFloat("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x2");
		ReplyToCommand(client, "> %f should equal %f", test.GetFloat("val"), value);
		return false;
	}
	
	// Int test
	int ivalue = RoundFloat(value);
	if (test.GetInt("val") != ivalue)
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x3");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("val"), ivalue);
		return false;
	}
	test.SetInt("val", ivalue);
	if (test.GetFloat("val") != RoundFloat(value))
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x4");
		ReplyToCommand(client, "> %f should equal %f", test.GetFloat("val"), RoundFloat(value));
		return false;
	}
	test.SetFloat("val", value);
	
	// String test
	char cvalue[2][64];
	if (!test.GetString("val", cvalue[0], sizeof(cvalue[])))
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x5");
		ReplyToCommand(client, "> Couldn't read int as string");
		return false;
	}
	FloatToString(value, cvalue[1], sizeof(cvalue[]));
	if (!StrEqual(cvalue[0], cvalue[1]))
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x6");
		ReplyToCommand(client, "> '%s' should equal '%s'", cvalue[0], cvalue[1]);
		return false;
	}
	test.SetString("val", cvalue[1]);
	if (test.GetFloat("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x7");
		ReplyToCommand(client, "> %f should equal %f", test.GetFloat("val"), value);
		return false;
	}
	
	// Dynamic not supported - no test required
	
	// Boolean test
	test.SetFloat("val", 0.0);
	if (test.GetBool("val"))
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x8");
		ReplyToCommand(client, "> %d should equal %d", test.GetBool("val"), false);
		return false;
	}
	test.SetFloat("val", 1.0);
	if (!test.GetBool("val"))
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x9");
		ReplyToCommand(client, "> %d should equal %d", test.GetBool("val"), true);
		return false;
	}
	test.SetBool("val", false);
	if (test.GetInt("val"))
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x10");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("val"), false);
		return false;
	}
	test.SetBool("val", true);
	if (!test.GetInt("val"))
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x11");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("val"), true);
		return false;
	}
	
	// Handle not supported - no test required
	// Vector not supported - no test required
	
	// Set/Get by Offset test
	value = GetRandomFloat(0.0, 32000.0);
	offset = test.GetMemberOffset("val");
	test.SetFloatByOffset(offset, value);
	if (test.GetFloatByOffset(offset) != value)
	{
		ReplyToCommand(client, "DynamicType_Float test failed: ErrorCode 1x12");
		ReplyToCommand(client, "> %f should equal %f", test.GetFloatByOffset(offset), value);
		return false;
	}
	
	return true;
}

stock bool _Dynamic_StringTest(int client, Dynamic test)
{
	// pulling strings back to basics, once completed all the normal tests should have no errors
	char buffer[128];
	DynamicOffset offset = test.SetString("string", "1234567890");
	
	if (strlen("1234567890") != test.GetStringLength("string"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode a2x1");
		ReplyToCommand(client, "> %d should equal %d", test.GetStringLength("string"), strlen("1234567890"));
		return false;
	}
	
	if (strlen("1234567890") != test.GetStringLengthByOffset(offset))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode b2x1");
		ReplyToCommand(client, "> %d should equal %d", test.GetStringLength("string"), strlen("1234567890"));
		return false;
	}
	
	test.GetString("string", buffer, sizeof(buffer));
	if (!StrEqual(buffer, "1234567890"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode a2x2");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "1234567890");
		return false;
	}
	
	test.GetStringByOffset(offset, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "1234567890"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode b2x2");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "1234567890");
		return false;
	}
	
	int dlength = test.GetStringLengthByOffset(offset)+1;
	char[] dbuffer = new char[dlength];
	test.GetStringByOffset(offset, dbuffer, dlength);
	if (!StrEqual(dbuffer, "1234567890"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode c2x2");
		ReplyToCommand(client, "> '%s' should equal '%s' (dlength=%d)", dbuffer, "1234567890", dlength);
		return false;
	}
	
	test.SetString("string", "12345678901");
	if (strlen("1234567890") != test.GetStringLength("string"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode a2x3");
		ReplyToCommand(client, "> %d should equal %d", test.GetStringLength("string"), strlen("1234567890"));
		return false;
	}
	
	test.GetString("string", buffer, sizeof(buffer));
	if (!StrEqual(buffer, "1234567890"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode a2x4");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "1234567890");
		return false;
	}
	
	test.SetString("string", "1234");
	test.GetString("string", buffer, sizeof(buffer));
	if (!StrEqual(buffer, "1234"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode a2x5");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "1234");
		return false;
	}
	
	// Test value
	char value[64];
	//char buffer[64];
	for (int i=0; i<sizeof(value); i++)
		value[i] = GetRandomInt(65, 122);
	value[63] = '\0';
	
	// Offset test
	offset = test.SetString("stringval", value);
	if (offset != test.GetMemberOffset("stringval"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x1");
		ReplyToCommand(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// String test
	if (test.GetString("stringval", buffer, sizeof(buffer)) && !StrEqual(value, buffer))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x2");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, value);
		return false;
	}
	
	// String by offset test
	test.SetStringByOffset(offset, "strval");
	if (test.GetStringByOffset(offset, buffer, sizeof(buffer)) && !StrEqual("strval", buffer))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x2b");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "strval");
		return false;
	}
	
	// Int test
	int ivalue = GetRandomInt(0, 32000);
	IntToString(ivalue, value, sizeof(value));
	test.SetString("stringval", value);
	if (test.GetInt("stringval") != ivalue)
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x3");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("stringval"), ivalue);
		return false;
	}
	test.SetInt("stringval", ivalue);
	if (test.GetString("stringval", buffer, sizeof(buffer)) && !StrEqual(value, buffer))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x4");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, value);
		return false;
	}
	
	// Float test
	float fvalue = GetRandomFloat(0.0, 32000.0);
	FloatToString(fvalue, value, sizeof(value));
	test.SetString("stringval", value);
	if (test.GetFloat("stringval") != fvalue)
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x5");
		ReplyToCommand(client, "> %f should equal %f", test.GetFloat("stringval"), fvalue);
		return false;
	}
	test.SetFloat("stringval", fvalue);
	if (test.GetString("stringval", buffer, sizeof(buffer)) && !StrEqual(value, buffer))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x6");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, value);
		return false;
	}
	
	// Dynamic not supported - no test required
	// Add support for this as Get/SetString -> Read/WriteKeyValues
	
	// Boolean test
	test.SetString("stringval", "False");
	if (test.GetBool("stringval"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x8");
		ReplyToCommand(client, "> %d should equal %d", test.GetBool("stringval"), false);
		return false;
	}
	test.SetString("stringval", "True");
	if (!test.GetBool("stringval"))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x9");
		ReplyToCommand(client, "> %d should equal %d", test.GetBool("stringval"), true);
		return false;
	}
	test.SetBool("stringval", false);
	if (test.GetString("stringval", buffer, sizeof(buffer)) && !StrEqual("False", buffer))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x10");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "False");
		return false;
	}
	test.SetBool("stringval", true);
	if (test.GetString("stringval", buffer, sizeof(buffer)) && !StrEqual("True", buffer))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x11");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "True");
		return false;
	}
	
	// Handle not supported - no test required
	
	// Vector test
	float vvalue[2][3];
	vvalue[0][0] = GetRandomFloat(1.0, 32000.0);
	vvalue[0][1] = GetRandomFloat(1.0, 32000.0);
	vvalue[0][2] = GetRandomFloat(1.0, 32000.0);
	char vbuffer[2][256];
	Format(vbuffer[0], sizeof(vbuffer[]), "{%f, %f, %f}", vvalue[0][0], vvalue[0][1], vvalue[0][2]);
	test.SetString("stringval", vbuffer[0]);
	if (!test.GetVector("stringval", vvalue[1]))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x12");
		ReplyToCommand(client, "> %d should equal %d", test.GetVector("stringval", vvalue[0]), true);
		return false;
	}
	if (!_Dynamic_CompareVectors(vvalue[0], vvalue[1]))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x13");
		ReplyToCommand(client, "> {%x, %x, %x} should equal {%x, %x, %x}", vvalue[0][0], vvalue[0][1], vvalue[0][2], vvalue[1][0], vvalue[1][1], vvalue[1][2]);
		return false;
	}
	test.SetVector("stringval", vvalue[0]);
	if (!test.GetString("stringval", vbuffer[1], sizeof(vbuffer[])))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x14");
		ReplyToCommand(client, "> %d should equal %d", test.GetString("stringval", vbuffer[1], sizeof(vbuffer[])), true);
		return false;
	}
	if (!StrEqual(vbuffer[0], vbuffer[1]))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x15");
		ReplyToCommand(client, "> '%s' should equal '%s'", vbuffer[0], vbuffer[1]);
		return false;
	}
	
	// Test setting string length > maxlength
	test.Reset(); // set blocksize to 16
	test.SetString("stringval", "1234567890", 6); // include eos space
	if (test.GetString("stringval", buffer, sizeof(buffer)) && !StrEqual("123456", buffer))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x16");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "123456");
		return false;
	}
	
	// Test string length that is > blocksize (array index wrapping test)
	test.Reset(true, 3); // set blocksize to 7 (a nice awkward size) 
	for (int i=0; i<sizeof(value); i++)
		value[i] = GetRandomInt(65, 122);
	value[15] = '\0';
	offset = test.SetString("stringval", value);
	if (test.GetString("stringval", buffer, sizeof(buffer)) && !StrEqual(value, buffer))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x17");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, value);
		return false;
	}
	
	// Test string length returns valid length
	test.Reset(true, 64);
	test.SetString("stringval", "123456789");
	if (test.GetStringLength("stringval") != 9) // Length expands by one to ensure trailing EOS is added
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x18");
		ReplyToCommand(client, "> %d should equal %d", test.GetStringLength("stringval"), 9);
		return false;
	}
	if (test.GetStringLengthByOffset(offset) != 9) // Length expands by one to ensure trailing EOS is added
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x19");
		ReplyToCommand(client, "> %d should equal %d", test.GetStringLengthByOffset(offset), 9);
		return false;
	}
	test.Reset(true, 64);
	test.SetString("stringval", "123456789", 128);
	if (test.GetStringLength("stringval") != 128) // Length expands by one to ensure trailing EOS is added
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x20");
		ReplyToCommand(client, "> %d should equal %d", test.GetStringLength("stringval"), 128);
		return false;
	}
	if (test.GetStringLengthByOffset(offset) != 128) // Length expands by one to ensure trailing EOS is added
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x21");
		ReplyToCommand(client, "> %d should equal %d", test.GetStringLengthByOffset(offset), 128);
		return false;
	}
	
	// Set/Get by Offset test
	offset = test.GetMemberOffset("stringval");
	test.SetStringByOffset(offset, value);
	test.GetStringByOffset(offset, buffer, sizeof(buffer));
	if (!StrEqual(value, buffer))
	{
		ReplyToCommand(client, "DynamicType_String test failed: ErrorCode 2x22");
		ReplyToCommand(client, "> %s should equal %s", value, buffer);
		return false;
	}
	
	return true;
}

stock bool _Dynamic_BoolTest(int client, Dynamic test)
{
	// Test value
	bool value = GetRandomInt(0, 1) == 0 ? false : true;
	
	// Offset test
	DynamicOffset offset = test.SetBool("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		ReplyToCommand(client, "DynamicType_Bool test failed: ErrorCode 3x1");
		ReplyToCommand(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Bool test
	if (test.GetBool("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Bool test failed: ErrorCode 3x2");
		ReplyToCommand(client, "> %d should equal %d", test.GetBool("val"), value);
		return false;
	}
	
	// Float test
	float fvalue = float(value);
	if (test.GetFloat("val") != fvalue)
	{
		ReplyToCommand(client, "DynamicType_Bool test failed: ErrorCode 3x3");
		ReplyToCommand(client, "> %f should equal %f", test.GetFloat("val"), fvalue);
		return false;
	}
	test.SetFloat("val", fvalue);
	if (test.GetBool("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Bool test failed: ErrorCode 3x4");
		ReplyToCommand(client, "> %d should equal %d", test.GetBool("val"), value);
		return false;
	}
	
	// String test
	char cvalue[2][16];
	if (!test.GetString("val", cvalue[0], sizeof(cvalue[])))
	{
		ReplyToCommand(client, "DynamicType_Bool test failed: ErrorCode 3x5");
		ReplyToCommand(client, "> Couldn't read int as string");
		return false;
	}
	if (value)
		Format(cvalue[1], sizeof(cvalue[]), "True");
	else
		Format(cvalue[1], sizeof(cvalue[]), "False");
	if (!StrEqual(cvalue[0], cvalue[1]))
	{
		ReplyToCommand(client, "DynamicType_Bool test failed: ErrorCode 3x6");
		ReplyToCommand(client, "> '%s' should equal '%s'", cvalue[0], cvalue[1]);
		return false;
	}
	test.SetString("val", cvalue[1]);
	if (test.GetBool("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Bool test failed: ErrorCode 3x7");
		ReplyToCommand(client, "> %d should equal %d", test.GetBool("val"), value);
		return false;
	}
	
	// Dynamic not supported - no test required
	// Handle not supported - no test required
	// Vector not supported - no test required
	
	// Set/Get by Offset test
	value = view_as<bool>(GetRandomInt(0, 1));
	offset = test.GetMemberOffset("val");
	test.SetBoolByOffset(offset, value);
	if (test.GetBoolByOffset(offset) != value)
	{
		ReplyToCommand(client, "DynamicType_Bool test failed: ErrorCode 3x8");
		ReplyToCommand(client, "> %f should equal %f", test.GetBoolByOffset(offset), value);
		return false;
	}
	
	return true;
}

stock bool _Dynamic_DynamicTest(int client, Dynamic test)
{
	// Test value
	Dynamic value = Dynamic();
	
	// Offset test
	DynamicOffset offset = test.SetDynamic("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x1");
		ReplyToCommand(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Dynamic test
	if (test.GetDynamic("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x2");
		ReplyToCommand(client, "> %d should equal %d", test.GetInt("val"), value);
		return false;
	}
	
	// Test parent is accurate
	Dynamic child = Dynamic();
	value.SetDynamic("child", child);
	if (child.Parent != value)
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x3");
		ReplyToCommand(client, "> %d should equal %d", child.Parent, value);
		return false;
	}
	
	// Test _name is accurate
	char buffer[32];
	if (!child.GetName(buffer, sizeof(buffer)))
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x4");
		ReplyToCommand(client, "> Couldn't read `_name` as string");
		return false;
	}
	if (!StrEqual(buffer, "child"))
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x5");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "child");
	}
	
	// Test parent follows most recent SetDynamic
	Dynamic value2 = Dynamic();
	value2.SetDynamic("child2", child);
	if (child.Parent != value2)
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x6");
		ReplyToCommand(client, "> %d should equal %d", child.Parent, value2);
		return false;
	}
	
	// Test _name setter follows most recent change
	if (!child.GetName(buffer, sizeof(buffer)))
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x7");
		ReplyToCommand(client, "> Couldn't read `_name` as string");
		return false;
	}
	if (!StrEqual(buffer, "child2"))
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x8");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "child2");
		return false;
	}
	
	// Test disposal of value - child should still be set as it's owner is value2
	value.Dispose();
	if (!child.IsValid)
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x9");
		ReplyToCommand(client, "> '%d' should equal '%d'", child.IsValid, true);
		return false;
	}
	
	// Test disposal of value2 - child should be disposed
	value2.Dispose();
	if (child.IsValid)
	{
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x10");
		ReplyToCommand(client, "> '%d' should equal '%d'", child.IsValid, false);
		return false;
	}
	
	// Int not supported - no test required
	// Float not supported - no test required
	// String not supported - no test required
	// Boolean not supported - no test required
	// Handle not supported - no test required
	// Vector not supported - no test required
	
	// Set/Get by Offset test
	value = Dynamic();
	offset = test.GetMemberOffset("val");
	test.SetDynamicByOffset(offset, value);
	if (test.GetDynamicByOffset(offset) != value)
	{
		value.Dispose();
		ReplyToCommand(client, "DynamicType_Dynamic test failed: ErrorCode 4x11");
		ReplyToCommand(client, "> %d should equal %d", test.GetDynamicByOffset(offset), value);
		return false;
	}
	value.Dispose();
	
	return true;
}

stock bool _Dynamic_HandleTest(int client, Dynamic test)
{
	// Test value
	ArrayList value = new ArrayList();
	
	// Offset test
	DynamicOffset offset = test.SetHandle("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		ReplyToCommand(client, "DynamicType_Handle test failed: ErrorCode 5x1");
		ReplyToCommand(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Handle test
	if (test.GetHandle("val") != value)
	{
		ReplyToCommand(client, "DynamicType_Handle test failed: ErrorCode 5x2");
		ReplyToCommand(client, "> %d should equal %d", test.GetHandle("val"), value);
		return false;
	}
	
	// Test handle conversion - create, add item, store member, get member, get value, does it match?
	delete value;
	value = new ArrayList();
	int ivalue = GetRandomInt(0, 32000);
	value.Push(ivalue);
	test.SetHandle("val", value);
	value = view_as<ArrayList>(test.GetHandle("val"));
	if (value.Get(0) != ivalue)
	{
		ReplyToCommand(client, "DynamicType_Handle test failed: ErrorCode 5x3");
		ReplyToCommand(client, "> %d should equal %d", value.Get(0), ivalue);
		return false;
	}
	
	// We must set the handle to null!
	delete value;
	test.SetHandle("val", null);

	// Int not supported - no test required
	// Float not supported - no test required
	// String not supported - no test required
	// Boolean not supported - no test required
	// Dynamic not supported - no test required
	// Vector not supported - no test required
	
	// Set/Get by Offset test
	value = new ArrayList();
	offset = test.GetMemberOffset("val");
	test.SetHandleByOffset(offset, value);
	if (test.GetHandleByOffset(offset) != value)
	{
		ReplyToCommand(client, "DynamicType_Handle test failed: ErrorCode 5x4");
		ReplyToCommand(client, "> %d should equal %d", test.GetHandleByOffset(offset), value);
		return false;
	}
	
	return true;
}

stock bool _Dynamic_VectorTest(int client, Dynamic test)
{
	// Test value
	float value[3];
	value[0] = GetRandomFloat(1.0, 32000.0);
	value[1] = GetRandomFloat(1.0, 32000.0);
	value[2] = GetRandomFloat(1.0, 32000.0);
	
	// Offset test
	DynamicOffset offset = test.SetVector("val", value);
	if (offset != test.GetMemberOffset("val"))
	{
		ReplyToCommand(client, "DynamicType_Vector test failed: ErrorCode 6x1");
		ReplyToCommand(client, "> member offset mismatch!!!!!");
		return false;
	}
	
	// Vector test
	float vector[3];
	if (!test.GetVector("val", vector))
	{
		ReplyToCommand(client, "DynamicType_Vector test failed: ErrorCode 6x2");
		ReplyToCommand(client, "> %d should equal %d", test.GetVector("val", vector), true);
		return false;
	}
	if (!_Dynamic_CompareVectors(vector, value))
	{
		ReplyToCommand(client, "DynamicType_Vector test failed: ErrorCode 6x3");
		ReplyToCommand(client, "> %d should equal %d", _Dynamic_CompareVectors(vector, value), true);
		return false;
	}
	
	// Int not supported - no test required
	// Float not supported - no test required
	
	// String test
	char buffer[2][256];
	if (!test.GetString("val", buffer[0], sizeof(buffer[])))
	{
		ReplyToCommand(client, "DynamicType_Vector test failed: ErrorCode 6x4");
		ReplyToCommand(client, "> %d should equal %d", test.GetString("val", buffer[0], sizeof(buffer[])), true);
		return false;
	}
	Format(buffer[1], sizeof(buffer[]), "{%f, %f, %f}", value[0], value[1], value[2]);
	if (!StrEqual(buffer[0], buffer[1]))
	{
		ReplyToCommand(client, "DynamicType_Vector test failed: ErrorCode 6x5");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer[0], buffer[1]);
		return false;
	}
	test.SetString("val", buffer[0]);
	if (!test.GetVector("val", vector))
	{
		ReplyToCommand(client, "DynamicType_Vector test failed: ErrorCode 6x6");
		ReplyToCommand(client, "> %d should equal %d", test.GetVector("val", vector), true);
		return false;
	}
	if (!_Dynamic_CompareVectors(vector, value))
	{
		ReplyToCommand(client, "DynamicType_Vector test failed: ErrorCode 6x7");
		ReplyToCommand(client, "> {%x, %x, %x} should equal {%x, %x, %x}", vector[0], vector[1], vector[2], value[0], value[1], value[2]);
		return false; 
	}
	
	// Boolean not supported - no test required
	// Dynamic not supported - no test required
	// Vector not supported - no test required
	
	// Set/Get by Offset test
	offset = test.GetMemberOffset("val");
	test.SetVectorByOffset(offset, value);
	test.GetVectorByOffset(offset, vector);
	if (!_Dynamic_CompareVectors(vector, value))
	{
		ReplyToCommand(client, "DynamicType_Vector test failed: ErrorCode 6x8");
		ReplyToCommand(client, "> {%x, %x, %x} should equal {%x, %x, %x}", value[0], value[1], value[2], vector[0], vector[1], vector[2]);
		return false;
	}
	
	return true;
}

stock bool _DynamicType_FunctionTest(int client, Dynamic test)
{
	ReplyToCommand(client, "> _DynamicType_FunctionTest not yet implemented!!!!!!!");
	return true;
}

stock bool _Dynamic_GetMemberNameByIndexTest(int client, Dynamic test)
{
	// Test GetMemberNameByIndex for Set/PushInt
	test.SetInt("index0", 0);
	char buffer[128];
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x1");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushInt(1, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x2");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushFloat
	test.SetFloat("index0", 0.0);
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x3");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushFloat(1.0, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x4");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushBool
	test.SetBool("index0", false);
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x5");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushBool(true, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x6");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushString
	test.SetString("index0", "0");
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x7");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushString("1", 0, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x8");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushDynamic
	test.SetDynamic("index0", Dynamic());
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x9");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushDynamic(Dynamic(), "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x10");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushHandle
	test.SetHandle("index0", null);
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x11");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushHandle(null, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x12");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	// Test GetMemberNameByIndex for Set/PushVector
	test.SetVector("index0", NULL_VECTOR);
	test.GetMemberNameByIndex(0, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index0"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x13");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.PushVector(NULL_VECTOR, "index1");
	test.GetMemberNameByIndex(1, buffer, sizeof(buffer));
	if (!StrEqual(buffer, "index1"))
	{
		ReplyToCommand(client, "_Dynamic_GetMemberNameByIndexTest test failed: ErrorCode 7x14");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "index1");
		return false; 
	}
	test.Reset();
	
	return true;
}

stock bool _Dynamic_FindByMemberValueTest(int client, Dynamic test)
{
	// Create some stuff to find
	Dynamic child = Dynamic();
	child.SetString("class", "Plant");
	child.SetString("name", "Tree");
	test.PushDynamic(child, "Tree");
	child = Dynamic();
	child.SetString("class", "Plant");
	child.SetString("name", "Shrub");
	test.PushDynamic(child, "Shrub");
	child = Dynamic();
	child.SetString("class", "Animal");
	child.SetString("name", "Cat");
	test.PushDynamic(child, "Cat");
	child = Dynamic();
	child.SetString("class", "Animal");
	child.SetString("name", "Dog");
	test.PushDynamic(child, "Dog");
	
	// Search for plants
	Dynamic params = Dynamic();
	Dynamic param = Dynamic();
	param.SetString("MemberName", "class");
	param.SetInt("Operator", view_as<int>(DynamicOperator_Equals));
	param.SetString("Value", "Plant");
	params.PushDynamic(param);
	Collection results = view_as<Collection>(test.FindByMemberValue(params));
	params.Reset(true);
	
	// Check plant results
	if (results == null)
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x1");
		ReplyToCommand(client, "> null should equal notnull", results.Length, 2);
		return false;
	}
	if (results.Length != 2)
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x1");
		ReplyToCommand(client, "> %d should equal %d", results.Length, 2);
		return false; 
	}
	char buffer[32];
	if (!results.Items(0).GetString("name", buffer, sizeof(buffer)))
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x2");
		ReplyToCommand(client, "> %d should equal %d", results.Items(0).GetString("name", buffer, sizeof(buffer)), true);
		return false; 
	}
	if (!StrEqual(buffer, "Tree"))
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x3");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "Tree");
		return false; 
	}
	if (!results.Items(1).GetString("name", buffer, sizeof(buffer)))
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x4");
		ReplyToCommand(client, "> %d should equal %d", results.Items(1).GetString("name", buffer, sizeof(buffer)), true);
		return false; 
	}
	if (!StrEqual(buffer, "Shrub"))
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x5");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "Tree");
		return false; 
	}
	delete results;
	
	// Search for animals
	params = Dynamic();
	param = Dynamic();
	param.SetString("MemberName", "class");
	param.SetInt("Operator", view_as<int>(DynamicOperator_NotEquals));
	param.SetString("Value", "Plant");
	params.PushDynamic(param);
	results = view_as<Collection>(test.FindByMemberValue(params));
	params.Reset(true);
	
	// Check animal results
	if (results == null)
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x6");
		ReplyToCommand(client, "> null should equal notnull", results.Length, 2);
		return false;
	}
	if (results.Length != 2)
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x7");
		ReplyToCommand(client, "> %d should equal %d", results.Length, 2);
		return false; 
	}
	if (!results.Items(0).GetString("name", buffer, sizeof(buffer)))
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x8");
		ReplyToCommand(client, "> %d should equal %d", results.Items(0).GetString("name", buffer, sizeof(buffer)), true);
		return false; 
	}
	if (!StrEqual(buffer, "Cat"))
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x9");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "Tree");
		return false; 
	}
	if (!results.Items(1).GetString("name", buffer, sizeof(buffer)))
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x10");
		ReplyToCommand(client, "> %d should equal %d", results.Items(1).GetString("name", buffer, sizeof(buffer)), true);
		return false; 
	}
	if (!StrEqual(buffer, "Dog"))
	{
		ReplyToCommand(client, "Dynamic_FindByMemberValue test failed: ErrorCode 8x11");
		ReplyToCommand(client, "> '%s' should equal '%s'", buffer, "Tree");
		return false; 
	}
	delete results;
	
	params.Dispose();
	return true;
}

stock bool _Dynamic_KeyValuesTest(int client, Dynamic test)
{
	// Build structure for testing
	Dynamic child; Dynamic grandchild;
	for (int i=0; i<3; i++)
	{
		child = Dynamic();
		child.SetString("String", "abcd");
		child.SetInt("Int", i);
		
		grandchild = Dynamic();
		grandchild.SetVector("Vector", NULL_VECTOR);
		grandchild.SetFloat("Float", 66.66);
		child.SetDynamic("granny", grandchild);
		
		if (i == 1)
			test.SetDynamic("SomeValue", child);
		else
			test.PushDynamic(child);
	}
	
	// Write test structure to disk
	test.WriteKeyValues("test.txt", "BaseKeyName");
	
	// Read test structure from disk
	test.Reset();
	test.ReadKeyValues("test.txt");
	
	// Really basic tests
	if (test.GetDynamicByIndex(0).GetInt("Int") != 0)
	{
		ReplyToCommand(client, "Dynamic_KeyValuesTest test failed: ErrorCode 9x1");
		ReplyToCommand(client, "> %d should equal %d", test.GetDynamicByIndex(0).GetInt("Int"), 0);
		return false; 
	}
	if (test.GetDynamic("SomeValue").GetInt("Int") != 1)
	{
		ReplyToCommand(client, "Dynamic_KeyValuesTest test failed: ErrorCode 9x2");
		ReplyToCommand(client, "> %d should equal %d", test.GetDynamic("SomeValue").GetInt("Int"), 1);
		return false; 
	}
	if (test.GetDynamicByIndex(2).GetInt("Int") != 2)
	{
		ReplyToCommand(client, "Dynamic_KeyValuesTest test failed: ErrorCode 9x3");
		ReplyToCommand(client, "> %d should equal %d", test.GetDynamicByIndex(2).GetInt("Int"), 2);
		return false; 
	}
	
	// Ensure file contents match after an additional write
	test.Reset();
	test.ReadKeyValues("test.txt");
	test.WriteKeyValues("test1.txt", "BaseKeyName");
	File stream1 = OpenFile("test.txt", "r");
	File stream2 = OpenFile("test1.txt", "r");
	char buffer1[1024];
	char buffer2[1024];
	while(stream1.ReadLine(buffer1, sizeof(buffer1)))
	{
		if (!stream2.ReadLine(buffer2, sizeof(buffer2)))
		{
			ReplyToCommand(client, "Dynamic_KeyValuesTest test failed: ErrorCode 9x4");
			ReplyToCommand(client, "> 0 should equal 1");
			delete stream1; delete stream2;
			return false;
		}
		else if (!StrEqual(buffer1, buffer2))
		{
			ReplyToCommand(client, "Dynamic_KeyValuesTest test failed: ErrorCode 9x5");
			ReplyToCommand(client, "> '%s' should equal '%s'", buffer1, buffer2);
			delete stream1; delete stream2;
			return false;
		}
	}
	if (stream2.ReadLine(buffer2, sizeof(buffer2)))
	{
		ReplyToCommand(client, "Dynamic_KeyValuesTest test failed: ErrorCode 9x6");
		ReplyToCommand(client, "> 1 should equal 0");
		delete stream1; delete stream2;
		return false;
	}
	
	delete stream1;
	delete stream2;
	
	DeleteFile("test.txt");
	DeleteFile("test1.txt");
	
	return true;
}
 
stock bool _Dynamic_CompareVectors(const float value1[3], const float value2[3])
{
	if (value1[0] != value2[0])
		return false;
	if (value1[1] != value2[1])
		return false;
	if (value1[2] != value2[2])
		return false;
	return true;
}

stock bool _Dynamic_FlatConfigTest(int client, Dynamic test)
{
	test.SetBool("boolvalue", true);
	test.SetInt("intvalue", 666);
	test.SetFloat("floatvalue", 666.666666);
	test.SetString("stringvalue", "some string", 64);
	
	test.WriteConfig("flatconfigtest.txt");
	test.Reset();
	test.ReadConfig("flatconfigtest.txt");
	
	if (!test.GetBool("boolvalue"))
	{
		ReplyToCommand(client, "Dynamic_FlatConfigTest test failed: ErrorCode 10x1");
		ReplyToCommand(client, "> false should equal true");
		return false;
	}
	
	if (test.GetInt("intvalue") != 666)
	{
		ReplyToCommand(client, "Dynamic_FlatConfigTest test failed: ErrorCode 10x2");
		ReplyToCommand(client, "> %d should equal 666", test.GetInt("intvalue"));
		return false;
	}
	
	if (test.GetFloat("floatvalue") != 666.666666)
	{
		ReplyToCommand(client, "Dynamic_FlatConfigTest test failed: ErrorCode 10x3");
		ReplyToCommand(client, "> %f should equal 666.666666", test.GetFloat("floatvalue"));
		return false;
	}
	
	if (!test.CompareString("stringvalue", "some string"))
	{
		char buffer[64];
		test.GetString("stringvalue", buffer, sizeof(buffer));
		ReplyToCommand(client, "Dynamic_FlatConfigTest test failed: ErrorCode 10x4");
		ReplyToCommand(client, "> '%s' should equal 'some string'", buffer);
		return false;
	}
	
	test.Reset();
	test.SetBool("boolvalue", false);
	test.SetInt("intvalue", 555);
	test.SetFloat("floatvalue", 555.555555);
	test.SetString("stringvalue", "another string", 64);
	test.SetInt("newintthatshouldntdissapear", 444);
	test.ReadConfig("flatconfigtest.txt");
	
	if (!test.GetBool("boolvalue"))
	{
		ReplyToCommand(client, "Dynamic_FlatConfigTest test failed: ErrorCode 10x5");
		ReplyToCommand(client, "> false should equal true");
		return false;
	}
	
	if (test.GetInt("intvalue") != 666)
	{
		ReplyToCommand(client, "Dynamic_FlatConfigTest test failed: ErrorCode 10x6");
		ReplyToCommand(client, "> %d should equal 666", test.GetInt("intvalue"));
		return false;
	}
	
	if (test.GetFloat("floatvalue") != 666.666666)
	{
		ReplyToCommand(client, "Dynamic_FlatConfigTest test failed: ErrorCode 10x7");
		ReplyToCommand(client, "> %f should equal 666.666666", test.GetFloat("floatvalue"));
		return false;
	}
	
	if (!test.CompareString("stringvalue", "some string"))
	{
		char buffer[64];
		test.GetString("stringvalue", buffer, sizeof(buffer));
		ReplyToCommand(client, "Dynamic_FlatConfigTest test failed: ErrorCode 10x8");
		ReplyToCommand(client, "> '%s' should equal 'some string'", buffer);
		return false;
	}
	
	if (test.GetInt("newintthatshouldntdissapear") != 444)
	{
		ReplyToCommand(client, "Dynamic_FlatConfigTest test failed: ErrorCode 10x9");
		ReplyToCommand(client, "> %d should equal 444", test.GetInt("newintthatshouldntdissapear"));
		return false;
	}
	
	test.Reset();
	
	DeleteFile("flatconfigtest.txt");
	return true;
}

stock bool _Dynamic_DBSchemeTest(int client, Dynamic test)
{
	test.SetString("stringvalue", "a string value");
	test.SetInt("intvalue", 666);
	test.SetFloat("floatvalue", 666.666666666);
	test.SetBool("boolvalue", true);
	test.SetString("ID", "STEAMID:XXXXXXXXXXX");
	
	PreparedQuery query = PreparedQuery();
	query.CompileQuery("UPDATE `table` SET `stringvalue`=?, `intvalue`=?, `floatvalue`=?, `boolvalue`=? WHERE `ID`=?");
	query.SendQuery(test, "default");
	query.Dispose();
	
	return true;
}