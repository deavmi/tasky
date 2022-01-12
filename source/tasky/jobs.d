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
/* TODO: DList stuff */
import std.container.dlist;
import core.sync.mutex : Mutex;

/**
* A Job to be scheduled
*/
public final class Job
{


	/**
	* TODO: Comment
	*/
	private Descriptor descriptor;
	private byte[] payload;

	/**
	* Returns the classification of this Job, i.e.
	* its Descriptor number
	*/
	public ulong getJobTypeID()
	{
		return descriptor.getDescriptorClass();
	}

	private this(Descriptor jobType, byte[] payload)
	{
		/* TODO: Extract needed information from here */
		this.descriptor = jobType;
		this.payload = payload;
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
	private static __gshared Mutex descQueueLock;
	private static __gshared DList!(ulong) descQueue;

	/**
	* Static initialization of the descriptor
	* class ID queue's lock
	*/
	static this()
	{
		descQueueLock = new Mutex();
	}

	/* TODO: Static (and _gshared cross threads) ID tracker */
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



	private ulong descriptorClass;

	/**
	* For this "class of Job" the unique
	* id is taken in as `descriptorClass`
	*/
	this(ulong descriptorClass)
	{
		this.descriptorClass = descriptorClass;

		/* TODO: Call descriotor class checker */
		if(isDescriptorClass(this))
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

	public final ulong getDescriptorClass()
	{
		return descriptorClass;
	}
}


