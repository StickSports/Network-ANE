package com.sticksports.nativeExtensions.network
{
	import com.sticksports.nativeExtensions.network.signals.NetworkSignal1;

	import flash.events.TimerEvent;
	import flash.external.ExtensionContext;
	import flash.net.InterfaceAddress;
	import flash.net.NetworkInterface;
	import flash.utils.Timer;

	public class NetworkStatus
	{
		public static var networkStatusChanged : NetworkSignal1 = new NetworkSignal1( Boolean );
		
		private static var checkTimer : Timer;
		private static var hadConnection : Boolean;
		
		private static var extensionContext : ExtensionContext;
		
		private static function initialise() : void
		{
			if( !extensionContext )
			{
				extensionContext = ExtensionContext.createExtensionContext( "com.sticksports.nativeExtensions.Network", null );
			}
		}
		
		public static function get isSupported() : Boolean
		{
			return true;
		}

		public static function findInterfaces() : Vector.<NetworkInterface>
		{
			initialise();
			var tempArray : Array = extensionContext.call( "findInterfaces" ) as Array;
			var interfaces : Vector.<NetworkInterface> = new Vector.<NetworkInterface>();
			for each( var tempInterface : TempNetworkInterface in tempArray )
			{
				var networkInterface : NetworkInterface = new NetworkInterface();
				networkInterface.name = tempInterface.name;
				networkInterface.displayName = tempInterface.displayName;
				networkInterface.mtu = tempInterface.mtu;
				networkInterface.hardwareAddress = tempInterface.hardwareAddress;
				networkInterface.active = tempInterface.active;
				networkInterface.addresses = new Vector.<InterfaceAddress>();
				for each( var tempAddress : TempInterfaceAddress in tempInterface.addresses )
				{
					var address : InterfaceAddress = new InterfaceAddress();
					address.address = tempAddress.address;
					address.broadcast = tempAddress.broadcast;
					address.prefixLength = tempAddress.prefixLength;
					address.ipVersion = tempAddress.ipVersion;
					networkInterface.addresses.push( address );
				}
				interfaces.push( networkInterface );
			}
			return interfaces;
		}
		
		public static function get hasConnection() : Boolean
		{
			initialise();
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

