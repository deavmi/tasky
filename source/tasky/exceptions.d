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

public final class SubmissionException : TaskyException
{
	this(string msg)
	{
		super("SubmissionException: "~msg);
	}
}