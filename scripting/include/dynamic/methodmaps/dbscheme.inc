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
#if defined _dynamic_class_dbscheme_
  #endinput
#endif
#define _dynamic_class_dbscheme_

public void DBScheme_Objects_MemberChanged(Dynamic obj, DynamicOffset offset, const char[] member, Dynamic_MemberType type)
{
	obj.SetBool("DBScheme_UpdateRequired", true);
}

methodmap DBScheme < Dynamic
{
	public DBScheme(const char[] updatequery, const char[] deletequery)
	{
		Dynamic myclass = Dynamic(64, 0);
		myclass.SetDynamic("Objects", Dynamic());
		myclass.SetString("UpdateQuery", updatequery);
		myclass.SetString("DeleteQuery", deletequery);
		return view_as<DBScheme>(myclass);
	}
	
	property Dynamic Objects
	{
		public get()
		{
			static DynamicOffset offset = INVALID_DYNAMIC_OFFSET;
			if (offset == INVALID_DYNAMIC_OFFSET)
			{
				offset = this.GetMemberOffset("Objects");
				if (offset == INVALID_DYNAMIC_OFFSET)
					SetFailState("A serious error occured in Dynamic!");
			}
			return this.GetDynamicByOffset(offset);
		}
	}
	
	public bool GetUpdateQuery(char[] buffer, int length)
	{
		static DynamicOffset offset = INVALID_DYNAMIC_OFFSET;
		if (offset == INVALID_DYNAMIC_OFFSET)
		{
			offset = this.GetMemberOffset("UpdateQuery");
			if (offset == INVALID_DYNAMIC_OFFSET)
				SetFailState("A serious error occured in Dynamic!");
		}
		this.GetStringByOffset(offset, buffer, length);
		return true;
	}
	
	public bool GetDeleteQuery(char[] buffer, int length)
	{
		static DynamicOffset offset = INVALID_DYNAMIC_OFFSET;
		if (offset == INVALID_DYNAMIC_OFFSET)
		{
			offset = this.GetMemberOffset("DeleteQuery");
			if (offset == INVALID_DYNAMIC_OFFSET)
				SetFailState("A serious error occured in Dynamic!");
		}
		this.GetStringByOffset(offset, buffer, length);
		return true;
	}
	
	public bool AddObject(Dynamic obj)
	{
		Dynamic objects = this.Objects;
		int count = obj.MemberCount;
		DynamicOffset offset;
		Dynamic member;
		int freeindex = -1;
		
		for (int i = 0; i < count; i++)
		{
			offset = objects.GetMemberOffsetByIndex(i);
			
			if (obj.GetMemberType(offset) != DynamicType_Dynamic)
				continue;
			
			member = objects.GetDynamicByOffset(offset);
			if (member == obj)
				return false;
				
			if (!member.IsValid && freeindex == -1)
				freeindex = i;
		}
		
		obj.SetBool("DBScheme_UpdateRequired", false);
		obj.HookChanges(DBScheme_Objects_MemberChanged);
		
		if (freeindex == -1)
			objects.SetDynamicByIndex(freeindex, obj);
		else
			objects.PushDynamic(obj);
			
		return true;
	}
	
	public bool RemoveObject(Dynamic obj)
	{
		Dynamic objects = this.Objects;
		int count = obj.MemberCount;
		DynamicOffset offset;
		Dynamic member;
		
		for (int i = 0; i < count; i++)
		{
			offset = objects.GetMemberOffsetByIndex(i);
			
			if (obj.GetMemberType(offset) != DynamicType_Dynamic)
				continue;
			
			member = objects.GetDynamicByOffset(offset);
			if (member != obj)
				continue;
				
			objects.SetDynamicByIndex(i, INVALID_DYNAMIC_OBJECT);
			member.UnHookChanges(DBScheme_Objects_MemberChanged);
			return true;
		}
		return false;
	}
	
	public bool BeginUpdateObject(Dynamic obj, SQLQueryCallback callback)
	{
		// Can probably parse a database name from the database.cfg file
		
		// Get query string from class
		
		// Create buffer string to send to db query
		
		// Loop object members
		
			// Replace all instances of `membername`=? with `membername`=sql escaped value
			// Note: We need to check every type to update ? properly
			//			Eg: String should be in ''
			//				> String values need to be escaped
			//				Int/Float should not be in
			//				Bool needs to be converted to 1 or 0
		
		
		// Set the DBScheme_UpdateRequired member to false as we are about to send the query to update it
		
		// Send the query to the database engine
		// Note: Parse the callback parameter through
		return false;
	}
	
	public bool BeginDeleteObject(Dynamic obj, SQLQueryCallback callback)
	{
		return false;
	}
}

