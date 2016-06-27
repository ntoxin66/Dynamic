#include <dynamic>
#include "dynamic/examples/collections/person.mm"
#include "dynamic/examples/collections/people.mm"
#pragma newdecls required
#pragma semicolon 1

public void OnPluginStart()
{
	// New people collection as defined in `collection.inc`
	People people = People();
	
	// New person as defined in `methodmap.inc`
	Person person = Person();
	person.SetName("Neuro Toxin");
	person.Age = 32;
	person.Height = 6.4;
	person.IsAlive = true;
	
	// Add person to people
	people.AddItem(person);
	
	// Lets add another person
	person = Person();
	person.SetName("Nouse");
	person.Age = 21;
	person.Height = 5.7;
	person.IsAlive = true;
	people.AddItem(person);
	
	// Iterating people
	for (int index = 0; index < people.MemberCount; index++)
	{
		person = view_as<Person>(people.Items(index));
		if (!person.IsValid)
			continue;
		
		char name[1024];
		person.GetName(name, sizeof(name));
		
		PrintToServer("Found Person {Name:'%s', Age:%d, Height:%f, IsAlive:%d}", 
						name, person.Age, person.Height, person.IsAlive);
	}
	
	// Always clean up when your done
	people.Dispose();
}