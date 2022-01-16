/**
* Jobs
*
* Contains tools for describing different types
* of jobs and what event handlers will be triggered
* for them along with the creation of actual
* Jobs (schedulable units).
*/
module tasky.jobs;

/* TODO: Remove this import */
import std.stdio;

import tasky.exceptions : TaskyException;
/* TODO: DList stuff */
import std.container.dlist;
import core.sync.mutex : Mutex;

import std.string : cmp;

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
	private static __gshared DList!(string) descQueue;

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


	/**
	* TODO: Add comment
	*
	* This method is not thread safe, it is only to
	* be called from thread safe functions that
	* correctly lock the queue
	*/
	private static bool isDescIDInUse(string descID)
	{
		foreach(string descIDCurr; descQueue)
		{
			if(cmp(descID, descIDCurr) == 0)
			{
				return true;
			}
		}

		return false;
	}




	/**
	* Test unique descriptor class ID generation
	* and tracking
	*/
	unittest
	{
		string s1 = addDescQueue();
		string s2 = addDescQueue();

		assert(cmp(s1, s2) != 0);
	}



	/**
	* Finds the next valid descriptor class ID,
	* reserves it and returns it
	*/
	private static string addDescQueue()
	{
		string descID;

		descQueueLock.lock();


		do
		{
			descID = generateDescID();
		}
		while(isDescIDInUse(descID));


		descQueue ~= descID;


		descQueueLock.unlock();

		return descID;
	}

	/**
	* Gneerates a Descriptor ID
	*
	* This returns a string that is a hash of
	* the current time
	*/
	private static string generateDescID()
	{
		/* Get current time */
		import std.datetime.systime : Clock;
		string time = Clock.currTime().toString();

		/* Get random number */
		/* TODO: Get random number */
		string randnum;

		/* Create data string */
		string data = time~randnum;

		/* Calculate the hash */
		import std.digest.sha;
		import std.digest;

		SHA1Digest sha = new SHA1Digest();

		string digest = toHexString(sha.digest(data));

		return digest;
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


