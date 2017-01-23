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

#if defined _dynamic_system_methomaps_dynamicobject
  #endinput
#endif
#define _dynamic_system_methomaps_dynamicobject
 
#define Dynamic_Index					0
// Size isn't yet implement for optimisation around _Dynamic_ExpandIfRequired()
#define Dynamic_Size					1
#define Dynamic_Blocksize				2
#define Dynamic_Offsets					3
#define Dynamic_MemberNames				4
#define Dynamic_Data					5
#define Dynamic_Forwards				6
#define Dynamic_NextOffset				7
#define Dynamic_CallbackCount			8
#define Dynamic_ParentObject			9
#define Dynamic_MemberCount				10
#define Dynamic_OwnerPlugin				11
#define Dynamic_Persistent				12
#define Dynamic_ParentOffset			13
#define Dynamic_Field_Count				14
#define me                view_as<int>(this)

// this should be static
ArrayList s_Collection = null;

methodmap DynamicObject
{
	public DynamicObject()
	{
		int index = PushArrayCell(s_Collection, -1);
		s_CollectionSize++;
		return view_as<DynamicObject>(index);
	}
	
	public void Initialise(Handle plugin, int blocksize=64, int startsize=0, bool persistent=false)
	{
		SetArrayCell(s_Collection, me, me, Dynamic_Index);
		SetArrayCell(s_Collection, me, 0, Dynamic_Size);
		SetArrayCell(s_Collection, me, blocksize, Dynamic_Blocksize);
		SetArrayCell(s_Collection, me, new StringMap(), Dynamic_Offsets);
		SetArrayCell(s_Collection, me, new ArrayList(blocksize, startsize), Dynamic_Data);
		SetArrayCell(s_Collection, me, 0, Dynamic_Forwards);
		SetArrayCell(s_Collection, me, new ArrayList(g_iDynamic_MemberLookup_Offset+1), Dynamic_MemberNames);
		SetArrayCell(s_Collection, me, 0, Dynamic_NextOffset);
		SetArrayCell(s_Collection, me, 0, Dynamic_CallbackCount);
		SetArrayCell(s_Collection, me, INVALID_DYNAMIC_OBJECT, Dynamic_ParentObject);
		SetArrayCell(s_Collection, me, INVALID_DYNAMIC_OFFSET, Dynamic_ParentOffset);
		SetArrayCell(s_Collection, me, 0, Dynamic_MemberCount);
		SetArrayCell(s_Collection, me, plugin, Dynamic_OwnerPlugin);
		SetArrayCell(s_Collection, me, persistent, Dynamic_Persistent);
	}
	
	public void Dispose(bool reuse=false)
	{
		CloseHandle(GetArrayCell(s_Collection, me, Dynamic_Offsets));
		CloseHandle(GetArrayCell(s_Collection, me, Dynamic_Data));
		if (GetArrayCell(s_Collection, me, Dynamic_Forwards) != 0)
			CloseHandle(GetArrayCell(s_Collection, me, Dynamic_Forwards));
		CloseHandle(GetArrayCell(s_Collection, me, Dynamic_MemberNames));
		if (!reuse)
			SetArrayCell(s_Collection, me, Invalid_Dynamic_Object, Dynamic_Index);
	}
	
	property int BlockSize
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_Blocksize);
		}
	}
	
	public void Reset(int blocksize=0, int startsize=0)
	{
		SetArrayCell(s_Collection, me, CreateTrie(), Dynamic_Offsets);
		
		if (blocksize == 0)
			blocksize = this.BlockSize;
		SetArrayCell(s_Collection, me, CreateArray(blocksize, startsize), Dynamic_Data);
		SetArrayCell(s_Collection, me, 0, Dynamic_Forwards);
		SetArrayCell(s_Collection, me, CreateArray(g_iDynamic_MemberLookup_Offset+1), Dynamic_MemberNames);
		SetArrayCell(s_Collection, me, 0, Dynamic_NextOffset);
		SetArrayCell(s_Collection, me, 0, Dynamic_CallbackCount);
		SetArrayCell(s_Collection, me, 0, Dynamic_Size);
		SetArrayCell(s_Collection, me, 0, Dynamic_MemberCount);
	}
	
	property int Index
	{
		public get()
		{
			return me;
		}
	}
	
	public bool IsValid(bool throwerror=false)
	{
		return _Dynamic_IsValid(me, throwerror);
	}
	
	public bool GetName(char[] buffer, int length)
	{
		return _Dynamic_GetName(this, buffer, length);
	}
	
	public bool SetName(const char[] objectname, bool replace)
	{
		return _Dynamic_SetName(this, objectname, replace);
	}
	
	property int Size
	{
		public get()
		{
			return 0;
		}
	}
	
	property ArrayList MemberNames
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_MemberNames);
		}
	}
	
	property StringMap Offsets 
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_Offsets);
		}
	}
	
	property ArrayList Data
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_Data);
		}
	}
	
	property Handle Forwards
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_Forwards);
		}
		public set(Handle value)
		{
			SetArrayCell(s_Collection, me, value, Dynamic_Forwards);
		}
	}
	
	property DynamicOffset NextOffset
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_NextOffset);
		}
		public set(DynamicOffset value)
		{
			SetArrayCell(s_Collection, me, value, Dynamic_NextOffset);
		}
	}
	
	property int HookCount
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_CallbackCount);
		}
		public set(int value)
		{
			SetArrayCell(s_Collection, me, value, Dynamic_CallbackCount);
		}
	}
	
	property DynamicObject Parent
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_ParentObject);
		}
		public set(DynamicObject value)
		{
			SetArrayCell(s_Collection, me, value, Dynamic_ParentObject);
		}
	}
	
	property DynamicOffset ParentOffset
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_ParentOffset);
		}
		public set(DynamicOffset value)
		{
			SetArrayCell(s_Collection, me, value, Dynamic_ParentOffset);
		}
	}
	
	property int MemberCount
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_MemberCount);
		}
		public set(int value)
		{
			SetArrayCell(s_Collection, me, value, Dynamic_MemberCount);
		}
	}
	
	property int OwnerPlugin
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_OwnerPlugin);
		}
		public set(int value)
		{
			SetArrayCell(s_Collection, me, value, Dynamic_OwnerPlugin);
		}
	}
	
	property Handle OwnerPluginHandle
	{
		public get()
		{
			return _Dynamic_Plugins_GetHandleFromIndex(GetArrayCell(s_Collection, me, Dynamic_OwnerPlugin));
		}
	}
	
	property bool Persistent
	{
		public get()
		{
			return GetArrayCell(s_Collection, me, Dynamic_Persistent);
		}
		public set(bool value)
		{
			SetArrayCell(s_Collection, me, value, Dynamic_Persistent);
		}
	}
}
