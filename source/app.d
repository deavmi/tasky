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

				DataMessage outMsg = new DataMessage(1, cast(byte[])"Hello there");
				
				/* Await one byte (let it setup) */
				byte[] l1bytebuf = [1];
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
	TQueue q = new TQueue(1);
	manager.addQueue(q);



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
	// TaskManager tman = new TaskManager();
}

public class Task
{
	private Event e;

	private byte[] dataToSend;

	this(byte[] dataToSend)
	{
		this.dataToSend = dataToSend;
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
	} 

	private void worker()
	{
		while(true)
		{
			currentTasksLock.lock();

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
				}
			}

			currentTasksLock.unlock();
		}
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

