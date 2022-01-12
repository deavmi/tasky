/**
* Jobs
*
* Contains tools for describing different types
* of jobs and what event handlers will be triggered
* for them along with the creation of actual
* Jobs (schedulable units).
*/
module tasky.jobs;

import tasky.exceptions : TaskyException;

/**
* A Job to be scheduled
*/
public class Job
{
	private this(Descriptor jobType, byte[] payload)
	{
		/* TODO: Extract needed information from here */
	}

	protected Job newJob(Descriptor jobType, byte[] payload)
	{
		/**
		* This is mark protected for a reason, don't
		* try and call this directly
		*/
		assert(jobType);
		assert(payload.length);

		return new Job(jobType, payload);
	}
}

public final class JobException : TaskyException
{
	this(string message)
	{
		super("(JobError) "~message);
	}
}

/**
* Descriptor
*
* This represents a type of Job, complete
* with the data to be sent and a type ID
*/
public abstract class Descriptor
{
	private ulong descriptorClass;

	/**
	* For this "class of Job" the unique
	* id is taken in as `descriptorClass`
	*/
	final this(ulong descriptorClass)
	{
		this.descriptorClass = descriptorClass;
	}

	/**
	* Instantiates a Job based on this Descriptor
	* ("Job template") with the given payload
	* to be sent
	*/
	public final Job spawnJob(byte[] payload)
	{
		Job instantiatedDescriptor;



		if(payload.length == 0)
		{
			throw new Exception("JobSpawnError: Empty payloads not allowed");
		}


		return instantiatedDescriptor;
	}
}


