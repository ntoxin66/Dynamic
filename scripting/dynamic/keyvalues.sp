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

stock bool _Dynamic_ReadKeyValues(Handle plugin, int index, const char[] path, int valuelength=128, Dynamic_HookType hook=INVALID_FUNCTION)
{
	if (!_Dynamic_IsValid(index))
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
	
	IterateKeyValues(kv, index, valuelength, callbackforward);
	delete kv;
	
	if (callbackforward != null)
	{
		RemoveFromForward(callbackforward, plugin, hook);
		delete callbackforward;
	}
	return true;
}

stock void IterateKeyValues(KeyValues kv, int index, int valuelength, Handle callbackforward, int depth=0)
{
	char key[512];
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
				Call_PushCell(index);
				Call_PushString(key);
				Call_PushCell(depth);
				Call_Finish(result);
			}
			
			if (result == Plugin_Continue)
			{
				int child = _Dynamic_GetObject(index, key);
				if (!_Dynamic_IsValid(child))
				{
					child = _Dynamic_Initialise(null);
					_Dynamic_SetObject(index, key, child);
				}
				
				IterateKeyValues(kv, child, valuelength, callbackforward, depth+1);
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
					_Dynamic_SetString(index, key, value, valuelength, valuelength);
				}
				case KvData_Int:
				{
					_Dynamic_SetInt(index, key, kv.GetNum(NULL_STRING));
				}
				case KvData_Float:
				{
					_Dynamic_SetFloat(index, key, kv.GetFloat(NULL_STRING));
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

stock bool _Dynamic_WriteKeyValues(int index, const char[] path)
{
	if (!_Dynamic_IsValid(index))
		return false;
	
	// Open file for writting
	File stream = OpenFile(path, "w", false);
	
	// Exit if failed to open
	if (stream == null)
	{
		ThrowNativeError(0, "Unable to open file stream '%s'!", path);
		return false;
	}
	
	WriteObjectToKeyValues(stream, index, 0);
	
	delete stream;
	return true;
}

stock void WriteObjectToKeyValues(File stream, int index, int indent)
{
	// Create indent
	char indextext[16];
	for (int i = 0; i < indent; i++)
		indextext[i] = 9;
	indextext[indent] = 0;
	int length = 1024;

	int count = _Dynamic_GetMemberCount(view_as<int>(index));
	int memberoffset;
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	for (int i = 0; i < count; i++)
	{
		memberoffset = _Dynamic_GetMemberOffsetByIndex(view_as<int>(index), i);
		_Dynamic_GetMemberNameByIndex(index, i, membername, sizeof(membername));
		Dynamic_MemberType type = _Dynamic_GetMemberTypeByOffset(index, memberoffset);
		
		if (type == DynamicType_Object)
		{
			stream.WriteLine("%s\"%s\"", indextext, membername);
			stream.WriteLine("%s{", indextext);
			WriteObjectToKeyValues(stream, _Dynamic_GetObjectByOffset(index, memberoffset), indent+1);
			stream.WriteLine("%s}", indextext);
		}
		else
		{
			//length = GetStringLengthByOffset(view_as<int>(index), memberoffset);
			char[] membervalue = new char[length];
			_Dynamic_GetStringByOffset(index, memberoffset, membervalue, length);
			stream.WriteLine("%s\"%s\"\t\"%s\"", indextext, membername, membervalue);
		}
	}
}