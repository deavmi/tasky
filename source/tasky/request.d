module tasky.request;

import tristanable.encoding : TaggedMessage;

public alias ResponseHandler = void function(byte[]);

public abstract class Request
{
    private byte[] requestMessage;
    
    private ResponseHandler respFunc;

    protected this(byte[] requestMessage, ResponseHandler respFunc)
    {
        this.requestMessage = requestMessage;
        this.respFunc = respFunc;
    }

    protected this(byte[] requestMessage)
    {
        this(requestMessage, null);
    }

    package final byte[] getRequestData()
    {
        return requestMessage;
    }

    package final void process(byte[] responseData)
    {
        respFunc(responseData);
    }
}