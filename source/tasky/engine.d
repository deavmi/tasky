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

		start();
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

	import std.stdio;

	/**
	* Worker thread function which checks the tristanable
	* queues for whichever has messages on them and then
	* dispatches a job-response for them via eventy
	*/
	private void worker()
	{
		while(true)
		{
			//writeln("WHITE BOY SUMMER");

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

			/* TODO: Yield away somehow */
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
		import std.conv : to;
		import core.thread : dur;

		/* Job type */
		Descriptor jobType = new class Descriptor {
				public override void handler(Event e)
				{
					import std.stdio : writeln;
					writeln("Event id ", e.id);

					TaskyEvent eT = cast(TaskyEvent)e;
					writeln(cast(string)eT.payload);
				}
		};

		ulong jobTypeDI = jobType.getDescriptorClass;


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
				DataMessage dMesg = new DataMessage(jobTypeDI, cast(byte[])"Hello");
				writeln("Server send: ", clientSocket.send(encodeForSend(dMesg)));
				
			}
		};

		serverThread.start();

		Socket clientSocket = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
		clientSocket.connect(parseAddress("::1", to!(ushort)(serverAddress.toPortString())));

		/* FIXME: Don't pass in null */
		Engine e = new Engine(clientSocket);

		

		e.registerDescriptor(jobType);


		while(true)
		{

		}
		
	}
}
