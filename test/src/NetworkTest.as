package
{
	import com.sticksports.nativeExtensions.network.NetworkStatus;

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.NetworkInterface;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	[SWF(width='320', height='480', frameRate='30', backgroundColor='#000000')]
	
	public class NetworkTest extends Sprite
	{
		private var direction : int = 1;
		private var shape : Shape;
		private var feedback : TextField;
		
		private var buttonFormat : TextFormat;
		
		public function NetworkTest()
		{
			shape = new Shape();
			shape.graphics.beginFill( 0x666666 );
			shape.graphics.drawCircle( 0, 0, 100 );
			shape.graphics.endFill();
			shape.x = 0;
			shape.y = 240;
			addChild( shape );
			
			feedback = new TextField();
			var format : TextFormat = new TextFormat();
			format.font = "_sans";
			format.size = 16;
			format.color = 0xFFFFFF;
			feedback.defaultTextFormat = format;
			feedback.width = 320;
			feedback.height = 270;
			feedback.x = 10;
			feedback.y = 210;
			feedback.multiline = true;
			feedback.wordWrap = true;
			feedback.text = "Hello";
			addChild( feedback );
			
			createButtons();
			
			addEventListener( Event.ENTER_FRAME, animate );
			addEventListener( Event.ENTER_FRAME, init );
		}
		
		private function init( event : Event ) : void
		{
			removeEventListener( Event.ENTER_FRAME, init );
		}
		
		private function createButtons() : void
		{
			var tf : TextField;
			
			tf = createButton( "isSupported" );
			tf.x = 10;
			tf.y = 10;
			tf.addEventListener( MouseEvent.MOUSE_DOWN, isSupported );
			addChild( tf );
			
			tf = createButton( "hasConnection" );
			tf.x = 10;
			tf.y = 50;
			tf.addEventListener( MouseEvent.MOUSE_DOWN, hasConnection );
			addChild( tf );
			
			tf = createButton( "findInterfaces" );
			tf.x = 170;
			tf.y = 50;
			tf.addEventListener( MouseEvent.MOUSE_DOWN, findInterfaces );
			addChild( tf );
			
			tf = createButton( "startCheck" );
			tf.x = 10;
			tf.y = 90;
			tf.addEventListener( MouseEvent.MOUSE_DOWN, startCheck );
			addChild( tf );
			
			tf = createButton( "stopCheck" );
			tf.x = 170;
			tf.y = 90;
			tf.addEventListener( MouseEvent.MOUSE_DOWN, stopCheck );
			addChild( tf );
		}
		
		private function createButton( label : String ) : TextField
		{
			if( !buttonFormat )
			{
				buttonFormat = new TextFormat();
				buttonFormat.font = "_sans";
				buttonFormat.size = 14;
				buttonFormat.bold = true;
				buttonFormat.color = 0xFFFFFF;
				buttonFormat.align = TextFormatAlign.CENTER;
			}
			
			var textField : TextField = new TextField();
			textField.defaultTextFormat = buttonFormat;
			textField.width = 140;
			textField.height = 30;
			textField.text = label;
			textField.backgroundColor = 0xCC0000;
			textField.background = true;
			textField.selectable = false;
			textField.multiline = false;
			textField.wordWrap = false;
			return textField;
		}
				
		private function isSupported( event : MouseEvent ) : void
		{
			feedback.text = ( "NetworkStatus.isSupported - " + NetworkStatus.isSupported );
		}
				
		private function hasConnection( event : MouseEvent ) : void
		{
			feedback.appendText( "\nNetworkStatus.hasConnection - " + NetworkStatus.hasConnection );
		}
				
		private function findInterfaces( event : MouseEvent ) : void
		{
			feedback.appendText( "\nNetworkStatus.findInterfaces() - " );
			var interfaces : Vector.<NetworkInterface> = NetworkStatus.findInterfaces();
			for each( var networkInterface : NetworkInterface in interfaces )
			{
				feedback.appendText( "\n  " + networkInterface.name + " - " + ( networkInterface.active ? "active" : "inactive" ) );
			}
		}

		private function startCheck( event : MouseEvent ) : void
		{
			feedback.appendText( "\nNetworkStatus.startCheckingForConnection( 10 )" );
			NetworkStatus.networkStatusChanged.add( networkStatusChanged );
			NetworkStatus.startCheckingForConnection( 10 );
		}
				
		private function stopCheck( event : MouseEvent ) : void
		{
			feedback.appendText( "\nNetworkStatus.stopCheckingForConnection()" );
			NetworkStatus.networkStatusChanged.remove( networkStatusChanged );
			NetworkStatus.stopCheckingForConnection();
		}
		
		private function networkStatusChanged( status : Boolean ) : void
		{
			feedback.appendText( "\nNetworkStatusChanged - " + status );
		}
				
		private function animate( event : Event ) : void
		{
			shape.x += direction;
			if( shape.x <= 0 )
			{
				direction = 1;
			}
			if( shape.x > 320 )
			{
				direction = -1;
			}
		}
	}
}