#include <dynamic>
#pragma newdecls required
#pragma semicolon 1

public void OnPluginStart()
{	
	// Creating a dynamic object
	Dynamic dynamic = Dynamic();
	
	// Dynamic will convert member types automatically based on
	// the type used when they were first set. 
	
	// Lets show each types setter
	dynamic.SetBool("Bool", false);
	dynamic.SetDynamic("Dynamic", INVALID_DYNAMIC_OBJECT);
	dynamic.SetFloat("Float", 77.7);
	dynamic.SetHandle("Handle", null);
	dynamic.SetInt("Int", 66);
	dynamic.SetString("String", "Hello!");
	dynamic.SetVector("Vector", NULL_VECTOR);
	
	// Each member above has it's type set because the first setter
	// determines the members lifetime type.
	
	// Lets give some examples
	dynamic.SetString("Bool", "True"); 		// Bool == bool:true
	dynamic.GetFloat("Int"); 					// returns float:66.0
	dynamic.GetInt("Float"); 					// returns int:78 (rounds to closest whole number)
	
	// Bool, Float, Int and String can all be all freely type
	// converted between eachother.
	
	// Dynamic and Int are convertable with eachother
	
	// Handle is not convertable with any other type
	
	// Vector and String are convertable with eachother
	
	// Any unconvertable types will receive an 
	// `Unsupported member datatype` error
	
	// Dont forget to dispose!
	dynamic.Dispose();
}