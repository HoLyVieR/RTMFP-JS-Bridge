package  
{
	import flash.net.*;
	import flash.events.*;
	import flash.external.*;
	/**
	 * ...
	 * @author Olivier Arteau
	 */
	public class Peer 
	{
		private var recvStream:NetStream = null;
		private var onMessageCallback:Function;
		private var onDisconnectCallback:Function;
		private var peerID:String;
		
		private var isInit:Boolean = false;
		
		public function Peer (farID:String, nc:NetConnection, onMessageCallback:Function, onDisconnectCallback:Function ) {
			this.recvStream = new NetStream(nc, farID);
			this.recvStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			this.recvStream.play("media");
			
			this.recvStream.client = this;
			this.peerID = farID;
			this.onMessageCallback = onMessageCallback;
			this.onDisconnectCallback = onDisconnectCallback;
		}
		
		public function receiveMessage (str:String):void {
			Main.log("(AS) P - " + str);
			this.onMessageCallback(peerID, str);
		}
		
		public function close ():void {
			this.recvStream.close();
		}
		
		private function netStatusHandler(event:NetStatusEvent):void{
			Main.log("(AS) P - " + event.info.code);
			
			if (event.info.code == "NetStream.Play.UnpublishNotify") {
				this.onDisconnectCallback(this.peerID);
			}
		}
	}

}