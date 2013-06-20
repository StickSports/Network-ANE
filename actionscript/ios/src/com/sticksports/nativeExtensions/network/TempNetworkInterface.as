package com.sticksports.nativeExtensions.network
{
	public class TempNetworkInterface
	{
		private var _name : String = "";
		private var _displayName : String = "";
		private  var _addresses : Vector.<TempInterfaceAddress> = new Vector.<TempInterfaceAddress> ;
		private var _mtu : int = -1;
		private var _hardwareAddress : String = "";
		private var _active : Boolean = false;

		public function TempNetworkInterface( nm : String, dName : String, mt : int, active : Boolean, hwaddrs : String, addrs : Array ) : void
		{
			_name = nm;
			_addresses = Vector.<TempInterfaceAddress>( addrs );
			_displayName = dName;
			_mtu = mt;
			_hardwareAddress = hwaddrs;
			_active = active;

		}

		public function get name() : String
		{
			return (_name);
		}

		public function get displayName() : String
		{
			return (_displayName);
		}

		public function get mtu() : int
		{
			return (_mtu);
		}

		public function get hardwareAddress() : String
		{
			return (_hardwareAddress);
		}

		public function get active() : Boolean
		{
			return (_active);
		}

		public function get addresses() : Vector.<TempInterfaceAddress>
		{
			return (_addresses);
		}
	}
}
