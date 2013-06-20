package com.sticksports.nativeExtensions.network
{
	import com.sticksports.nativeExtensions.network.signals.NetworkSignal1;

	import flash.events.TimerEvent;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	import flash.utils.Timer;

	public class NetworkStatus
	{
		public static var networkStatusChanged : NetworkSignal1 = new NetworkSignal1( Boolean );
		
		private static var checkTimer : Timer;
		private static var hadConnection : Boolean;
		
		public static function get isSupported() : Boolean
		{
			return NetworkInfo.isSupported;
		}

		public static function findInterfaces() : Vector.<NetworkInterface>
		{
			if( NetworkInfo.networkInfo )
			{
				return NetworkInfo.networkInfo.findInterfaces();
			}
			else
			{
				return new Vector.<NetworkInterface>();
			}
		}
		
		public static function get hasConnection() : Boolean
		{
			return containsConnection( findInterfaces() );
		}
		
		private static function containsConnection( interfaces : Vector.<NetworkInterface> ) : Boolean
		{
			for each( var networkInterface : NetworkInterface in interfaces )
			{
				if( networkInterface.active )
				{
					return true;
				}
				if( networkInterface.subInterfaces && containsConnection( networkInterface.subInterfaces ) )
				{
					return true;
				}
			}
			return false;
		}
		
		public static function startCheckingForConnection( interval : int ) : void
		{
			if( checkTimer )
			{
				stopCheckingForConnection();
			}
			hadConnection = hasConnection;
			checkTimer = new Timer( interval * 1000 );
			checkTimer.addEventListener( TimerEvent.TIMER, checkConnections );
			checkTimer.start();
		}
		
		public static function stopCheckingForConnection() : void
		{
			if( checkTimer )
			{
				checkTimer.removeEventListener( TimerEvent.TIMER, checkConnections );
				checkTimer.stop();
				checkTimer = null;
			}
		}
		
		private static function checkConnections( event : TimerEvent ) : void
		{
			var now : Boolean = hasConnection;
			if( now != hadConnection )
			{
				hadConnection = now;
				networkStatusChanged.dispatch( now );
			}
		}
	}
}

