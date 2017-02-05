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

#if defined _dynamic_system_keyvalues
  #endinput
#endif
#define _dynamic_system_keyvalues

stock bool _Dynamic_ReadKeyValues(Handle plugin, DynamicObject dynamic, const char[] path, int valuelength=128, Dynamic_HookType hook=INVALID_FUNCTION)
{
	if (!dynamic.IsValid(true))
		return false;
	
	// Check file exists
	if (!FileExists(path, false))
	{
		ThrowNativeError(0, "Filepath '%s' doesn't exist!", path);
		return false;
	}
	
	KeyValues kv = new KeyValues("");
	kv.SetEscapeSequences(true);
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		return false;
	}
	
	Handle callbackforward = null;
	if (hook != INVALID_FUNCTION)
	{
		callbackforward = CreateForward(ET_Single, Param_Cell, Param_String, Param_Cell);
		AddToForward(callbackforward, plugin, hook);
	}
	
	IterateKeyValues(plugin, kv, dynamic, valuelength, callbackforward);
	delete kv;
	
	if (callbackforward != null)
	{
		RemoveFromForward(callbackforward, plugin, hook);
		delete callbackforward;
	}
	return true;
}

stock void IterateKeyValues(Handle plugin, KeyValues kv, DynamicObject dynamic, int valuelength, Handle callbackforward, int depth=0)
{
	char key[DYNAMIC_MEMBERNAME_MAXLEN];
	KvDataTypes type;
	
	do
	{
		kv.GetSectionName(key, sizeof(key));
		if (kv.GotoFirstSubKey(false))
		{
			Action result;
			if (callbackforward != null)
			{
				Call_StartForward(callbackforward);
				Call_PushCell(dynamic);
				Call_PushString(key);
				Call_PushCell(depth);
				Call_Finish(result);
			}
			
			if (result == Plugin_Continue)
			{
				if (depth == 0)
				{
					IterateKeyValues(plugin, kv, dynamic, valuelength, callbackforward, depth+1);
				}
				else
				{
					DynamicObject child = _Dynamic_GetDynamic(dynamic, key);
					if (!child.IsValid(false))
					{
						child = DynamicObject();
						child.Initialise(plugin);
						
						_Dynamic_SetDynamic(dynamic, key, child);
					}
					IterateKeyValues(plugin, kv, child, valuelength, callbackforward, depth+1);
				}
			}
			kv.GoBack();
		}
		else
		{
			type = kv.GetDataType(NULL_STRING);
			switch(type)
			{
				case KvData_String:
				{
					char[] value = new char[valuelength];
					kv.GetString(NULL_STRING, value, valuelength);
					_Dynamic_SetString(dynamic, key, value, valuelength, valuelength);
				}
				case KvData_Int:
				{
					_Dynamic_SetInt(dynamic, key, kv.GetNum(NULL_STRING));
				}
				case KvData_Float:
				{
					_Dynamic_SetFloat(dynamic, key, kv.GetFloat(NULL_STRING));
				}
				case KvData_Ptr:
				{
					LogError("Type `KvData_Ptr` not yet supported!");
				}
				case KvData_WString:
				{
					LogError("Type `KvData_WString` not yet supported!");
				}
				case KvData_Color:
				{
					LogError("Type `KvData_Color` not yet supported!");
				}
				case KvData_UInt64:
				{
					LogError("Type `KvData_UInt64` not yet supported!");
				}
			}
		}
	}
	while (kv.GotoNextKey(false));
}

stock bool _Dynamic_WriteKeyValues(DynamicObject dynamic, const char[] path, const char[] basekey)
{
	if (!dynamic.IsValid(true))
		return false;
	
	// Open file for writting
	File stream = OpenFile(path, "w", false);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return false;
	}
	
	stream.WriteLine("\"%s\"", basekey);
	stream.WriteLine("{");
	_Dynamic_KeyValues_WriteDynamic(stream, dynamic, 1);
	stream.WriteLine("}");
	
	delete stream;
	return true;
}

stock void _Dynamic_KeyValues_WriteDynamic(File stream, DynamicObject dynamic, int indent)
{
	// Create indent
	char indextext[16];
	for (int i = 0; i < indent; i++)
		indextext[i] = 9;
	indextext[indent] = 0;
	int length = 1024;
	char buffer[1024];

	int count = dynamic.MemberCount;
	DynamicOffset memberoffset;
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	for (int i = 0; i < count; i++)
	{
		memberoffset = _Dynamic_GetMemberOffsetByIndex(dynamic, i);
		_Dynamic_GetMemberNameByIndex(dynamic, i, membername, sizeof(membername));
		Dynamic_MemberType type = _Dynamic_GetMemberTypeByOffset(dynamic, memberoffset);
		
		if (type == DynamicType_Dynamic)
		{
			if (StrEqual(membername, ""))
				stream.WriteLine("%s\"%d\"", indextext, i);
			else
			{
				_Dynamic_KeyValues_EscapeString(membername, buffer, sizeof(membername));
				stream.WriteLine("%s\"%s\"", indextext, buffer);
			}
			stream.WriteLine("%s{", indextext);
			_Dynamic_KeyValues_WriteDynamic(stream, _Dynamic_GetDynamicByOffset(dynamic, memberoffset), indent+1);
			stream.WriteLine("%s}", indextext);
		}
		else
		{
			//length = GetStringLengthByOffset(view_as<int>(dynamic), memberoffset);
			char[] membervalue = new char[length];
			_Dynamic_GetStringByOffset(dynamic, memberoffset, membervalue, length);
			_Dynamic_KeyValues_EscapeString(membervalue, buffer, sizeof(buffer));
			stream.WriteLine("%s\"%s\"\t\"%s\"", indextext, membername, membervalue);
		}
	}
}

stock void _Dynamic_KeyValues_EscapeString(const char[] input, char[] output, int length)
{
	int pos_in=0;
	int pos_out=0;
	int x;
	do
	{
		x = input[pos_in++];
		switch (x)
		{
			case 34: // `"` -> `\"`
			{
				if (pos_out+1 >= length)
					return;
					
				output[pos_out++] = 92;
				output[pos_out++] = 34;
			}
			case 92: // `\` -> `\\`
			{
				if (pos_out+1 >= length)
					return;
					
				output[pos_out++] = 92;
				output[pos_out++] = 92;
			}
			case 10: // newline -> `\n`
			{
				if (pos_out+1 >= length)
					return;
					
				output[pos_out++] = 92;
				output[pos_out++] = 110;
			}
			case 13: // linefeed -> `\r`
			{
				if (pos_out+1 >= length)
					return;
					
				output[pos_out++] = 92;
				output[pos_out++] = 114;
			}
			default:
			{
				if (pos_out == length)
					return;
					
				output[pos_out++] = x;
			}
		}
	}
	while(x != 0);
}