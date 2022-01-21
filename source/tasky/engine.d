/**
* Engine
*
* Contains the core components of the tasky
* library, this is effectively the entry
* point to the library
*/
module tasky.engine;

import eventy.engine : EvEngine = Engine;
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


	/**
	* Worker thread function which checks the tristanable
	* queues for whichever has messages on them and then
	* dispatches a job-response for them via eventy
	*/
	private void worker()
	{
		while(true)
		{
		}
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
