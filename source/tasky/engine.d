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

public final class Engine
{
	private EvEngine evEngine;

	this()
	{
		/* Create a new event engine */
		evEngine = new EvEngine();
		evEngine.start();
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
	}
}
