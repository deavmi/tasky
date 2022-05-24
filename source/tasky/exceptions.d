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

public final class DescriptorException : TaskyException
{
	this(string msg)
	{
		super("DescriptorException: "~msg);
	}
}

/**
* Raised if the underlying socket dies (connection closes)
* or (TODO: check that Tasky shutdown does not cause this to weirdly go off by calling tmanager.shutdown())
*/
public final class SessionError : TaskyException
{
	this(string msg)
	{
		super("SessionError: "~msg);
	}
}