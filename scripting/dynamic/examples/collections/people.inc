#if defined _dynamic_collection_people
  #endinput
#endif
#define _dynamic_collection_people

/*
	This example demonstrates how to easily create a collection
	methodmap by inheriting Dynamic.
*/

// We inherit Dynamic's collection methodmap
methodmap People < Collection
{
	public People()
	{
		// Return a new Dynamic Collection
		return view_as<People>(new Collection());
	}
	
	// Override Items method to return type Person
	public Person Items(int index)
	{
		return view_as<Person>(this.Items(index));
	}
}
