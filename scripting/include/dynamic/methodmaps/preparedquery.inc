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
#if defined _dynamic_class_preparedquery_
  #endinput
#endif
#define _dynamic_class_preparedquery_

methodmap PreparedQuery < Dynamic
{
	public PreparedQuery()
	{
		Dynamic myclass = Dynamic(64, 0);
		return view_as<PreparedQuery>(myclass);
	}
	
	public bool CompileQuery(const char[] query)
	{
		_Dynamic_PreparedQuery_CompileQuery(query, this);
	}
	
	public bool SendQuery(Dynamic parameters, const char[] database, SQLQueryCallback callback=INVALID_FUNCTION, int buffersize=512)
	{
		_Dynamic_PreparedQuery_SendQuery(this, parameters, database, callback, buffersize);
	}
}