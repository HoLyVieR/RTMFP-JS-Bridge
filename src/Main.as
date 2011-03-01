package 
{
	import flash.display.Sprite;
	import flash.events.*;
	import flash.external.*;
	import flash.net.*;
	import flash.system.Security;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Olivier Arteau
	 */
	public class Main extends Sprite 
	{
		private static var IS_DEBUG:Boolean = true;
		
		// Stream variable //
		private var nc:NetConnection;
		private var sendStream:NetStream;
		private var peers:Dictionary = new Dictionary();
		public var myID:String;
		
		// Event callback variable //
		public var onInitCallback:String = null;
		public var onMessageCallback:String = null;
		
		public function Main():void {
			Security.allowDomain("*");
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void {
			Main.log("RTMP Bridge v0.0.1.6");
			
			var self:Main = this;
			
			// Call function //
			ExternalInterface.addCallback("connect", this.connect);
			ExternalInterface.addCallback("listen", this.listen);
			ExternalInterface.addCallback("broadcast", this.broadcast);
			ExternalInterface.addCallback("init", this.initRTMFP);
			
			ExternalInterface.addCallback("getMyID", function ():String {
				return self.myID;
			});
			
			// Event related function //
			ExternalInterface.addCallback("onInit", function (callback:String):void {
				self.onInitCallback = callback;
			});
			
			ExternalInterface.addCallback("onMessage", function (callback:String):void {
				self.onMessageCallback = callback;
			});
		}
		
		public function initRTMFP(serverAddr:String):void {
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, ncStatus);
			nc.connect(serverAddr);
		}
		
		public function getPeer (farID:String):Peer {
			var self:Main = this;
			
			if (peers[farID] == undefined) {
				peers[farID] = new Peer(farID, nc, function (peerID:String, msg:String):void {
					if (self.onMessageCallback != null) {
						ExternalInterface.call(self.onMessageCallback, Main.flashSucks(peerID), Main.flashSucks(msg));
					}
				});
			}
			
			return peers[farID];
		}
		
		public function connect (farID:String):void {
			this.getPeer(farID);
		}
		
		public function broadcast(str:String):void {
			Main.log("Sending ... ");
			sendStream.send("receiveMessage", str);
			Main.log("Sent");
		}
		
		private function ncStatus(event:NetStatusEvent):void {
			Main.log(event.info.code);
			Main.log(nc.nearID);
			
			this.myID = nc.nearID;
			
			if (event.info.code == "NetConnection.Connect.Success") {
				Main.log(this.onInitCallback);
				
				if (this.onInitCallback != null) {
					ExternalInterface.call(this.onInitCallback);
				}
			}
		}
		
		public function listen(callback:String):void {
			var self:Main = this;
			
			Main.log("(AS) Listen ...");
			
			sendStream = new NetStream(nc, NetStream.DIRECT_CONNECTIONS);
			sendStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			sendStream.publish("media");
			
			var sendStreamClient:Object = new Object();
			sendStreamClient.onPeerConnect = function(callerns:NetStream):Boolean {
				Main.log("(AS) Receive connection from " + callerns.farID);
				ExternalInterface.call(callback, Main.flashSucks(callerns.farID));
				
				var delay:Timer = new Timer(10, 1);
				delay.addEventListener(TimerEvent.TIMER, function ():void {
					Main.log("Subscribing back to " + callerns.farID);
					self.getPeer(callerns.farID);
				});
				delay.start();
				
				return true;
			}
			
			sendStream.client = sendStreamClient;
		}
		
		private function netStatusHandler(event:NetStatusEvent):void{
			Main.log("(AS) Listener : " + event.info.code);
		}
		
		public static function log (message:String):void {
			if (Main.IS_DEBUG) {
				ExternalInterface.call("console.log", Main.flashSucks((message)));
			}
		}
		
		public static function flashSucks (data:String):String {
			return data.split("%").join("%25")
					   .split("\\").join("%5c")
					   .split("\"").join("%22")
					   .split("&").join("%26");
		}
	}
	
}