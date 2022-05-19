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
import core.thread : Thread, dur;
import tasky.exceptions : SessionError;

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

	private bool running;

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
		tmanager = new Manager(socket, dur!("msecs")(100), true);

		/* Start the loop */
		running = true;
		start();
	}

	/**
	* Starts the Tasky engine
	*
	* FIXME: Pivot to using this
	* FIXME: This code should be private and rather called at the beginning
	* of `.start()`
	*/
	public void startTasky()
	{
		/* Start the event engine */
		//evEngine.start();

		/* TODO: TManager should not start immediately either I guess */
		//tmanager.start();
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
		while(running)
		{
			/** 
			 * Loop through each queue, poll for
			 * any new data, pull off one item
			 * at most
			 *
			 * TODO: Different queuing systems
			 */
            Queue[] tQueues = tmanager.getQueues();
            foreach(Queue tQueue; tQueues)
            {
                /* Descriptor ID */
                ulong descID = tQueue.getTag();


				try
				{
					/* Check if the queue has mail */
					if(tQueue.poll())
					{
						/** 
						* Dequeue the data item and push
						* event into the event loop containing
						* it
						*/
						QueueItem data = tQueue.dequeue();
						evEngine.push(new TaskyEvent(descID, data.getData()));
					}
				}
				/* Catch the error when the underlying socket for Manager dies */
				catch(ManagerError e)
				{
					/* TODO: We can only enablke this if off thread, doesn't make sense on thread, in other words it maybe makes sense */
					/* TO call engine .run() that start a new thread seeing as thie point is to make this the backbone */
					import std.stdio;
					// writeln("YOO");
					// throw new SessionError("Underlying socket (TManager) is dead");
					// break;
				}

                
            }

			/* TODO: Yield away somehow */
			import core.thread : dur;
			// sleep(dur!("msecs")(500));
		}
	}

	/**
	* Stop the task engine
	*/
	public void shutdown()
	{
		/* Stop the loop */
		running = false;
		
		/* TODO: Stop tristsnable (must be implemented in tristanable first) */
		tmanager.shutdown();

		/* TODO: Stop eventy (mjst be implemented in eventy first) */
		evEngine.shutdown();
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

		/* Create a new queue for this Job */
		Queue tQueue = new Queue(tmanager, desc.getDescriptorClass());

		/* Add the Queue to tristanable */
		tmanager.addQueue(tQueue);
	}


	unittest
	{
		/* Results array for unit testing */
		bool[4] results;

		import std.conv : to;
		import core.thread : dur;
		import std.string : cmp;
		import std.datetime.stopwatch : StopWatch;

		bool runDone;

		/* Job type */
		Descriptor jobType = new class Descriptor {
				public override void handler(Event e)
				{
					import std.stdio : writeln;
					writeln("Event id ", e.id);

					TaskyEvent eT = cast(TaskyEvent)e;
					string data = cast(string)eT.payload;
					writeln(data);

					if(cmp(data, "Hello 1") == 0)
					{
						results[0] = true;
					}
					else if(cmp(data, "Hello 2") == 0)
					{
						results[1] = true;
					}
				}
		};

		ulong jobTypeDI = jobType.getDescriptorClass;

		ulong job2C = 0;

		/* Job type */
		Descriptor jobType2 = new class Descriptor {
				public override void handler(Event e)
				{
					import std.stdio : writeln;
					writeln("Event id ", e.id);

					writeln("OTHER event type");

					TaskyEvent eT = cast(TaskyEvent)e;
					string data = cast(string)eT.payload;
					writeln(data);
					// job2C++;
					// assert(cmp(cast(string)eT.payload, ""))

					if(cmp(data, "Bye-bye! 3") == 0)
					{
						results[2] = true;
					}
					else if(cmp(data, "Bye-bye! 4") == 0)
					{
						results[3] = true;
					}
				}
		};

		ulong jobTypeDI2 = jobType2.getDescriptorClass;


		import std.socket;
		import std.stdio;
		Socket serverSocket = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
		serverSocket.bind(parseAddress("::1", 0));
		Address serverAddress = serverSocket.localAddress();

		Thread serverThread = new class Thread {
			this()
			{
				super(&worker);
				serverSocket.listen(0);

			}

			public void worker()
			{

				Socket clientSocket = serverSocket.accept();

				sleep(dur!("seconds")(2));

				import tristanable.encoding : DataMessage, encodeForSend;
				DataMessage dMesg = new DataMessage(jobTypeDI, cast(byte[])"Hello 1");
				writeln("Server send 1: ", clientSocket.send(encodeForSend(dMesg)));
				dMesg = new DataMessage(jobTypeDI, cast(byte[])"Hello 2");
				writeln("Server send 2: ", clientSocket.send(encodeForSend(dMesg)));

				sleep(dur!("seconds")(1));

				dMesg = new DataMessage(jobTypeDI2, cast(byte[])"Bye-bye! 3");
				writeln("Server send 3: ", clientSocket.send(encodeForSend(dMesg)));
				dMesg = new DataMessage(jobTypeDI2, cast(byte[])"Bye-bye! 4");
				writeln("Server send 4: ", clientSocket.send(encodeForSend(dMesg)));
				

				while(!runDone)
				{
					
				}
				
			}
		};

		serverThread.start();

		Socket clientSocket = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
		clientSocket.connect(parseAddress("::1", to!(ushort)(serverAddress.toPortString())));

		

		
		Engine e = new Engine(clientSocket);


		

		/**
		* Setup the job types that are wanted
		*/
		e.registerDescriptor(jobType);
		e.registerDescriptor(jobType2);


		/* TODO: Use this in future */
		// e.start();


		/**
		* Await the expected result, but if this does not complete
		* within 4 seconds then expect it failed
		*/
		StopWatch watch;
		watch.start();
		while(!results[0] || !results[1] || !results[2] || !results[3])
		{
			if(watch.peek() > dur!("seconds")(4))
			{
				runDone = true;
				assert(false);
			}
		}

		writeln("Got to done testcase");

		runDone = true;


		/* TODO: Shutdown tasky here (shutdown eventy and tristanable) */
		// e.shutdown();

		// clientSocket.close;
	}
}
