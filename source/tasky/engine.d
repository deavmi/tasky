module tasky.engine;

import std.container.dlist : DList;
import core.sync.mutex : Mutex;
import tristanable.manager;
import std.socket : Socket;
import tristanable.queue : Queue;
import tristanable.encoding : DataMessage, encodeForSend;
import eventy;

import core.thread : Thread;

public final class TaskManager : Thread
{
    /**
    * Job queue
    */
    private DList!(Job) jobs;
    private Mutex jobsLock;

    /*
    * Tristanable queue filter
    */
    private Manager manager;

    /**
    * Event-loop
    */
    private Engine eventEngine;

    this(Socket socket)
    {
        super(&worker);

        /* Initialize tristanable */
        manager = new Manager(socket);

        /* Initialize the event-loop */
        eventEngine = new Engine();

        /* Start the thread */
        start();
    }

    private void worker()
    {
        while(true)
        {
            /* Lock the job queue */
            jobsLock.lock();

            /* Clean list (list of jobs to be removed) */
            Job[] cleanList;

            foreach(Job job; jobs)
            {
                /* If the job is fulfilled */
                if(job.isFulfilled())
                {
                    /* Get the job's task */
                    Task jobTask = job.getTask();

                    /* Free the tristanable tag for this job */
                    job.complete();

                    /* Add job to the deletion queue */
                    cleanList ~= job;
                }
            }

            /* Delete tje jobs */
            foreach(Job job; cleanList)
            {
                jobs.linearRemoveElement(job);
            }

            /* Unlock the job queue */
            jobsLock.unlock();
        }
    }


    /**
    * Job
    *
    * Represents an enqueued (in-progress) task with
    * an associated tristanable tag
    *
    * Created by the task manager and not to be used
    * by the user at all
    */
    private final class Job
    {
        private Task task;
        private Queue tristanableTag;

        this(Task task, Queue tristanableTag)
        {
            this.task = task;
            this.tristanableTag = tristanableTag;
        }

        public Task getTask()
        {
            return task;
        }

        public DataMessage encode()
        {
            /* Get the Task's data to be sent */
            byte[] taskPayload = task.getData();

            /* Encode into tristanable format */
            DataMessage tEncoded = new DataMessage(tristanableTag.getTag(), taskPayload);

            return tEncoded;
        }

        public bool isFulfilled()
        {
            return tristanableTag.poll();
        }

        public void complete()
        {
            manager.removeQueue(tristanableTag);
        }
    }

    /*
    * Registers the type of Task by the Event it returns
    *
    * This is always called by `submitTask` but is only
    * ever used once to
    */
    public void registerTaskType(Task task)
    {
        /* Task typeID */
        ulong typeID = task.getTypeID();

        /* Get the EventHandler */
        EventHandler handler = task.getHandler();

        /* Check if there is already such a handler */
        /* FIXME: This should (in eventy) take a ulong, semantics of taking in EVent give it a weird meaning */
        bool signalExists = eventEngine.getSignalsForEvent(new Event(typeID)).length > 0;

        /* If no such signal handler exists, then add it */
        if(!signalExists)
        {
            Signal signalHandler = new Signal([typeID], handler);
            eventEngine.addSignalHandler(signalHandler);
        }
        
    }

    /**
    * Submits a new Task, enqueues it as a job,
    * sends the payload
    */
    public void submitTask(Task task)
    {
        /* Get a unique tristanable ID for the new job */
        Queue newQueue = manager.generateQueue();

        /* If the queue generation was successful */
        if(newQueue)
        {
            /* Register the task (if not already done) */
            registerTaskType(task);

            /* Create a new job */
            Job newJob = new Job(task, newQueue);

            /* Lock the job queue */
            jobsLock.lock();

            /* Enqueue the job */
            jobs ~= newJob;

            /* Unlock the job queue */
            jobsLock.unlock();

            /* Get the DataMessage of the job */
            DataMessage jobDMessage = newJob.encode();

            /* Encode for sending (bformat) */
            byte[] bEncoded = encodeForSend(jobDMessage);

            /* Send the payload */
            manager.getSocket().send(bEncoded);
        }
        /* If unsuccessful, throw exception */
        else
        {
            /* TODO: Add an exception */
        }

        /* Lock the jobs */
    }
    
}



/**
* Represents a Task
*/
public abstract class Task
{
    private byte[] data;
    private ulong typeID;
    private EventHandler handler;

    /*
    * Constructs a new Task with the given data to be
    * sent and a typeID that reoresents which Signal
    * handler to call
    */
    this(byte[] data, ulong typeID, EventHandler handler)
    {
        this.data = data;
        this.typeID = typeID;
        this.handler = handler;
    }

    public byte[] getData()
    {
        return data;
    }

    public ulong getTypeID()
    {
        return typeID;
    }

    public EventHandler getHandler()
    {
        return handler;
    }

    /**
    * Intended to take the received data from the Job's
    * tristanable queue and decode it as per this Task's
    * type
    */
    public abstract Event getEvent(byte[] dataIn);
}

public final class TestTask : Task
{
    this(string payloadOut)
    {
        super(cast(byte[])payloadOut, 69, &TestTaskHandlerFunc);
    }

    private static void TestTaskHandlerFunc(Event e)
    {
        import std.stdio;
        writeln("Poes", e);
    }

    public override Event getEvent(byte[] dataIn)
    {
        auto event = new class Event
        {
            this()
            {
                /* TestTask is of type 69 for signal dispatching in Eventy */
                super(getTypeID());
            }
        };

        return event;
    }
}