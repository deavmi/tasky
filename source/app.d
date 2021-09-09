import std.stdio;

import tristanable.manager;
import tristanable.queue : TQueue = Queue;
import tristanable.queueitem : QueueItem;
import tristanable.encoding;
import eventy;
import core.thread;
import core.sync.mutex;
import std.container.dlist;


unittest
{
	import std.socket;
	Socket servSocket = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
	servSocket.bind(parseAddress("::1", 0));
	servSocket.listen(0);

	auto serverThread = new class Thread
	{
		this()
		{
			super(&worker);
		}

		private void worker()
		{
			runing = true;
			while(runing)
			{
				Socket client = servSocket.accept();

				import tristanable.encoding;

				DataMessage outMsg = new DataMessage(0, cast(byte[])"Hello there");
				
				/* Await one byte (let it setup) */
				byte[] l1bytebuf = [0];
				client.receive(l1bytebuf);

				/* Encode tristanable encode */
				client.send(encodeForSend(outMsg));
				

				

			}
		
		}

		private bool runing;

		public void stopThread()
		{
			runing=false;
		}
	};

	serverThread.start();

	Socket clientSocket = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
	clientSocket.connect(servSocket.localAddress);
	
	

	Manager manager = new Manager(clientSocket);
	TQueue q = new TQueue(6);
	manager.addQueue(q);

	TaskManager tMan = new TaskManager(manager);
	tMan.start();

	


	ReverseTask task = new ReverseTask("");
	
	tMan.pushJob(task);


	clientSocket.send([cast(byte)1]);

	QueueItem item = q.dequeue();
	writeln("Received:", cast(string)item.getData());

	import std.string;

	if(cmp(cast(string)item.getData(), "Hello there") == 0)
	{
		assert(true);
	}
	else
	{
		assert(false);
	}

	manager.shutdown();

	serverThread.stopThread();

	//manager.start();
	//TaskManager tman = new TaskManager();
}

// unittest
// {
// 	import std.socket;
// 	Socket servSocket = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
// 	servSocket.bind(parseAddress("::1", 0));
// 	servSocket.listen(0);

// 	auto serverThread = new class Thread
// 	{
// 		this()
// 		{
// 			super(&worker);
// 		}

// 		private void worker()
// 		{
// 			runing = true;
// 			while(runing)
// 			{
// 				Socket client = servSocket.accept();

// 				import tristanable.encoding;

// 				DataMessage outMsg = new DataMessage(1, cast(byte[])"Hello there");
				
// 				/* Await one byte (let it setup) */
// 				byte[] l1bytebuf = [1];
// 				client.receive(l1bytebuf);

// 				/* Encode tristanable encode */
// 				client.send(encodeForSend(outMsg));
				

				

// 			}
		
// 		}

// 		private bool runing;

// 		public void stopThread()
// 		{
// 			runing=false;
// 		}
// 	};

// 	serverThread.start();

// 	Socket clientSocket = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
// 	clientSocket.connect(servSocket.localAddress);
	
// 	Manager manager = new Manager(clientSocket);
// 	TQueue q = new TQueue(1);
// 	manager.addQueue(q);



// 	clientSocket.send([cast(byte)1]);

// 	QueueItem item = q.dequeue();
// 	writeln("Received:", cast(string)item.getData());

// 	import std.string;

// 	if(cmp(cast(string)item.getData(), "Hello there") == 0)
// 	{
// 		assert(true);
		
// 	}
// 	else
// 	{
// 		assert(false);
// 	}

// 	manager.shutdown();

// 	serverThread.stopThread();

// 	//manager.start();
// 	//TaskManager tman = new TaskManager();
// }




public class ReverseEvent : Event
{
	public string message;

	this(ulong id, string message)
	{
		super(id);

		this.message = message;
	}
}

public final class ReverseTask : Task
{
	

	this(string words)
	{
		ReverseEvent revEvent = new ReverseEvent(1, words);

		super(revEvent, [&reverseHandler], cast(byte[])"d");
	}

	public static void reverseHandler(Event e)
	{
		import std.stdio;
		import std.string;
		writeln(capitalize((cast(ReverseEvent)e).message));
	}

	

}

public class Task
{
	/**
	* Event-loop tag
	*
	* To know which signal handler should be used
	*/
	private Event eventType;
	private Signal[] handlers;
	
	public Event getEvent()
	{
		return eventType;
	}

	private void setEvent(Event eventType, EventHandler[] handlers)
	{
		this.eventType = eventType;
		foreach(EventHandler handler; handlers)
		{
			this.handlers ~= [new Signal([eventType.id], handler)];
		}
	}

	private byte[] dataToSend;

	this(Event eventType, EventHandler[] handlers, byte[] dataToSend)
	{
		setEvent(eventType, handlers);
		this.dataToSend = dataToSend;
	}

	public Signal[] getHandlers()
	{
		return handlers;
	}

	public ulong getID()
	{
		return id;
	}


	private ulong id;
	private bool isSet;

	public final void setId(ulong id)
	{
		if(!isSet)
		{
			this.id=id;
			isSet=true;
		}
		else
		{
			/* TODO: Throw exception */
			/* TODO: Static manager */
			/* TODO: Task should do this for us */
		}
	}

	public byte[] getData()
	{
		return dataToSend;
	}
}

public final class TaskManager : Thread
{
	/**
	* Tristanable instance
	*/
	private Manager manager;

	/**
	* Task management
	*/
	private DList!(Task) currentTasks;
	private Mutex currentTasksLock;

	/**
	* Event-loop system
	*/
	private Engine eventEngine;

	this(Manager manager)
	{
		super(&worker);
		this.manager = manager;
		this.currentTasksLock = new Mutex();

		eventEngine = new Engine();
		eventEngine.start();
	} 

	private void worker()
	{
		while(true)
		{
			currentTasksLock.lock();

			Task[] tasksToBeRemoved;

			foreach(Task task; currentTasks)
			{
				/* Find the matching tristananble queue */
				TQueue tQueue = manager.getQueue(task.getID());				

				/* TODO: Poll queue here */
				if(tQueue.poll())
				{
					/* Dequeue the item */
					QueueItem tQueueItem = tQueue.dequeue();

					/* Delete the queue */
					manager.removeQueue(tQueue);

					/* TODO: Add dispatch here */
					eventEngine.push(task.getEvent());

					/* Add to list of tasks to delete (for-loop list safety) */
					tasksToBeRemoved~=task;

					writeln("disp");
					writeln(eventEngine.getSignalsForEvent(task.getEvent()));
				}
			}

			/* Delete the tasks marked for deletion */
			foreach(Task task; tasksToBeRemoved)
			{
				removeTask(task);
			}

			currentTasksLock.unlock();
		}
	}

	private void removeTask(Task task)
	{
		currentTasksLock.lock();

		currentTasks.linearRemoveElement(task);

		currentTasksLock.unlock();
	}

	/**
	* Given a Task, `task`, this will
	*/
	public void pushJob(Task task)
	{
		/* Reserve a queue for this task */
		TQueue taskQueue = manager.generateQueue();

		/* If sucessful */
		if(taskQueue)
		{
			/* Set the task's ID */
			task.setId(taskQueue.getTag());

			/* Install this task's type's handlers */
			/* TODO: Install Like, event types */
			foreach(Signal signal; task.getHandlers())
			{
				eventEngine.addSignalHandler(signal);
			}

			/* Lock the pending tasks queue */
			currentTasksLock.lock();

			/* Add to the pending task queue */
			currentTasks ~= task;

			/* Unlock the pending tasks queue */
			currentTasksLock.unlock();

			/* TODO: Send encoded message here */
			DataMessage msg = new DataMessage(task.getID(), task.getData());
			import std.socket : Socket;
			Socket socket = manager.getSocket();
			socket.send(encodeForSend(msg));

		}
		/* If unsuccessful at reserving a quque */
		else
		{
			/* TODO: Throw error */
		}

		
	}


}

