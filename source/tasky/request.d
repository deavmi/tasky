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

    package final byte[] getRequestData()
    {
        return requestMessage;
    }

    package final void process(byte[] responseData)
    {
        respFunc(responseData);
    }
}