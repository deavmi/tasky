module tasky.engine;

import tristanable : Manager, Queue, TaggedMessage;
import tasky.request : Request;

public class Engine
{
    private Manager tManager;

    this(Manager tristanableManager)
    {
        this.tManager = tristanableManager;
    }

    // TODO: Continue working on this

    public void makeRequest(Request req)
    {
        /* Get a unique queue */
        Queue newQueue = tManager.getUniqueQueue();

        /* Create a tagged message with the tag */
        ulong tag = newQueue.getID();
        TaggedMessage tReq = new TaggedMessage(tag, req.getRequestData());

        /* Send the message */
        tManager.sendMessage(tReq);

        /* Await for a response */
        byte[] resp = newQueue.dequeue().getPayload();

        /* Run the response handler with the response */
        req.process(resp);
    }
}