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
import eventy.signal : Signal;
import eventy.event : Event;

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
* This represents a type of Job, represented
* by a unique ID. Along with this is an associated
* signal handler provided by the user which is
* to be run on completion of said Job
*
* TODO: Add support for custom IDs
*/
public abstract class Descriptor : Signal
{
	/**
	* Descriptor ID reservation sub-system
	*/
	private static __gshared Mutex descQueueLock;
	private static __gshared DList!(ulong) descQueue;

	/**
	* All descriptors (pool)
	*/
	private static __gshared DList!(Descriptor) descPool;

	/**
	* Descriptor data
	*
	* The signal handler that handles the running
	* of any job associated with this Descriptor
	*
	* We should `alias  can we?
	*/
	private immutable ulong descriptorClass;

	/**
	* Static initialization of the descriptor
	* class ID queue's lock
	*
	* FIXME: BIG BUG FOR MULTITHREADED THIS MUST BE SET TO GSHARED TOO, else each thread
	* will be overwriting the global descQueuLock
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
	* Returns true if the given descriptor ID is in
	* use, false otherwise
	*
	* @param
	*/
	private static bool isDescIDInUse(ulong descID)
	{
		descQueueLock.lock();

		foreach(ulong descIDCurr; descQueue)
		{
			if(descID == descIDCurr)
			{
				descQueueLock.unlock();
				return true;
			}
		}

		descQueueLock.unlock();

		return false;
	}




	/**
	* Test unique descriptor class ID generation
	* and tracking
	*/
	unittest
	{
		ulong s1 = addDescQueue();
		ulong s2 = addDescQueue();

		assert(s1 != s2);
	}



	/**
	* Finds the next valid descriptor class ID,
	* reserves it and returns it
	*/
	private static ulong addDescQueue()
	{
		ulong descID;

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
	private static ulong generateDescID()
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

		/**
		* We will store the digest as the first 8
		* bytes of the hash
		*/
		ulong digest;
		ubyte[] hashDigest = sha.digest(data);

		digest = *(cast(ulong*)hashDigest.ptr);

		return digest;
	}








	/**
	* Creates a new Descriptor
	*/
	this()
	{
		/* Grab a descripor ID */
		descriptorClass = addDescQueue();

		/**
		* Setup a new Eventy Signal handler
		* which handles only the typeID
		* of `descriptorClass`
		*/
		super([descriptorClass]);
	}

	/**
	* Creates a new Descriptor (with a given fixed descriptor class)
	*
	* TODO: Future support (add this in after TaskyEvent things)
	*/
	this(ulong descriptorClass)
	{
		/* TODO: Check if it is available */
		/* TODO: Add to queue */

		/* Set the descriptor ID */
		this.descriptorClass = descriptorClass;

		/**
		* Setup a new Eventy Signal handler
		* which handles only the typeID
		* of `descriptorClass`
		*/
		super([descriptorClass]);
	}


	unittest
	{


		try
		{
			/**
			* Create a uniqye Descriptor for a future
			* Job that will run the function `test`
			* on completion (reply)
			*/
			class DescTest : Descriptor
			{
				this()
				{

				}


				public override void handler(Event e)
				{
					writeln("Event id ", e.id);
				}

			}

			new DescTest();

			assert(true);
		}
		catch(TaskyException)
		{
			assert(false);
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

	/**
	* Override this to handle Event
	*/
	public abstract override void handler(Event e);
}


