/**
* Exceptions
*
* Base definitions for exceptions appear here
*/
module tasky.exceptions;

import std.exception;

public abstract class TaskyException : Exception
{
	this(string msg)
	{
		super("TaskyException:"~msg);
	}
}
