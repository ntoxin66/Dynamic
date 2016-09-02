#include <dynamic>
#include "person.inc"
#include "people.inc"
#pragma newdecls required
#pragma semicolon 1

public void OnPluginStart()
{
	// New people collection as defined in `people.inc`
	People people = new People();
	
	// New person as defined in `person.inc`
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
	
	// Iterating people in the collection
	for (int index = 0; index < people.Count; index++)
	{
		person = people.Items(index);
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
