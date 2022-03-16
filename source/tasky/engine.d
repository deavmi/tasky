/**
* Engine
*
* Contains the core components of the tasky
* library, this is effectively the entry
* point to the library
*/
module tasky.engine;

import eventy.engine : EvEngine = Engine;
import eventy.event : Event;
import tasky.jobs : Descriptor;
import tristanable;
import std.socket : Socket;
import core.thread : Thread;

public final class Engine : Thread
{
	/**
	* Tristanable sub-system
	*/
	private Manager tmanager;

	/**
	* Eventy sub-system
	*/
	private EvEngine evEngine;

	this(Socket socket)
	{
		/* Set the worker function */
		super(&worker);

		/* TODO: Check for exceptions */
		/* Create a new event engine */
		evEngine = new EvEngine();
		evEngine.start();

		/* TODO: Check for exceptions */
		/* Create a new tristanable manager */
		tmanager = new Manager(socket);
	}

	public class TaskyEvent : Event 
	{
		private byte[] payload;

		this(ulong descID, byte[] payload)
		{
			super(descID);
			this.payload = payload;
		}
	}


	/**
	* Worker thread function which checks the tristanable
	* queues for whichever has messages on them and then
	* dispatches a job-response for them via eventy
	*/
	private void worker()
	{
		while(true)
		{
            /* TODO: Get all tristanable queues */
            Queue[] tQueues = tmanager.getQueues();

            foreach(Queue tQueue; tQueues)
            {
                /* Descriptor ID */
                ulong descID = tQueue.getTag();

                /* Check if the queue has mail */
                /* TODO: Different discplines here, full-exhaust or round robin queue */
                if(tQueue.poll())
                {
                    

                    /* Get the data */
                    QueueItem data = tQueue.dequeue();


                    evEngine.push(new TaskyEvent(descID, data.getData()));

                    // d.
                    // data.getData()

                    // evEngine.push
                }
                

                

            }
            /* TODO: Use queue ID to match to descriptor id for later job dispatch */
            /* TODO: Per each queue */
		}
	}


    /**
    * TODO: Dispatcher
    */
    private void dispatch()
    {

    }


	/**
	* Register a Descriptor with tasky
	*/
	public void registerDescriptor(Descriptor desc)
	{
		/* Add a queue based on the descriptor ID */
		evEngine.addQueue(desc.getDescriptorClass());

		/* Add a signal handler that handles said descriptor ID */
		evEngine.addSignalHandler(desc);

		/* TODO: Tristanable queue addition here */

		/* Create a new queue for this Job */
		Queue tQueue = new Queue(desc.getDescriptorClass());

		/* Add the Queue to tristanable */
		tmanager.addQueue(tQueue);
	}


	unittest
	{
		/* FIXME: Don't pass in null */
		Engine e = new Engine(null);


	}
}
