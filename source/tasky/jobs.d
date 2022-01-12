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
	/* TODO: Static (and gsharea cross threads) ID tracker */

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

	/**
	* Checks whether a Descriptor class has been registered
	* previously that has the same ID but not the same
	* equality (i.e. not spawned from the same object)
	*/
	public static bool isDescriptorClass(Descriptor descriptor)
	{
		/* TODO: Add the implementation for this */
		return false;
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

		/* TODO: Call descriotor class checker */
		if(Job.isDescriptorClass(this))
		{
			throw new JobException("Descriptor class ID already in use by another descriptor");
		}

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
			throw new JobException("JobSpawnError: Empty payloads not allowed");
		}
		else
		{
			instantiatedDescriptor = new Job(this, payload);
		}

		return instantiatedDescriptor;
	}
}


