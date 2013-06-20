/*
 * Based on ideas used in Robert Penner's AS3-signals - https://github.com/robertpenner/as3-signals
 */

package com.sticksports.nativeExtensions.network.signals
{
	/**
	 * Provides a fast signal for use where no parameters are dispatched with the signal.
	 */
	public class NetworkSignal0 extends SignalBase
	{
		public function NetworkSignal0()
		{
		}

		public function dispatch() : void
		{
			startDispatch();
			var node : ListenerNode;
			for ( node = head; node; node = node.next )
			{
				node.listener();
				if( node.once )
				{
					remove( node.listener );
				}
			}
			endDispatch();
		}
	}
}
