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
		public var onDisconnectCallback:String = null;
		
		public function Main():void {
			Security.allowDomain("*"); // TODO: Fix this //
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		// Initialize the function that we can use from Javascript //
		private function init(e:Event = null):void {
			Main.log("RTMP Bridge v0.0.1.16");
			
			var self:Main = this;
			
			// Call function //
			ExternalInterface.addCallback("connect", this.connect);
			ExternalInterface.addCallback("listen", this.listen);
			ExternalInterface.addCallback("broadcast", this.broadcast);
			ExternalInterface.addCallback("init", this.initRTMFP);
			ExternalInterface.addCallback("sendTo", this.sendTo);
			ExternalInterface.addCallback("disconnect", this.disconnect);
			ExternalInterface.addCallback("disconnectPeer", this.disconnectPeer);
			
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
			
			ExternalInterface.addCallback("onPeerDisconnect", function (callback:String):void {
				self.onDisconnectCallback = callback;
			});
		}
		
		// Initialize the connection to the RTMFP server ///
		public function initRTMFP(serverAddr:String):void {
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, ncStatus);
			nc.connect(serverAddr);
		}
		
		// Returns the object associated to a peerID and connects to it if we are not connected to him //
		public function getPeer (farID:String):Peer {
			var self:Main = this;
			
			if (peers[farID] == undefined) {
				peers[farID] = new Peer(farID, nc, this.peerMessageReceived, this.peerDisconnected);
			}
			
			return peers[farID];
		}
		
		// Connect to a peer //
		public function connect (farID:String):void {
			this.getPeer(farID);
		}
		
		// Disconnect of all peer and close all incomming connection //
		public function disconnect ():void {
			this.sendStream.close();
		}
		
		// Disconnect from a specific peer //
		public function disconnectPeer (peerID:String):void {
			for each (var peer:NetStream in sendStream.peerStreams) {
				if (peer.farID == peerID) {
					peer.close(); // Close the send stream //
					peers[peerID].close(); // Close the receive stream //
					delete peers[peerID];
					break;
				}
			}
		}
		
		// Sends a message to all connected peer //
		public function broadcast(str:String):void {
			Main.log("Sending to all ... ");
			sendStream.send("receiveMessage", str);
			Main.log("Sent");
		}
		
		// When we receive a message from a peer //
		public function peerMessageReceived (peerID:String, msg:String):void {
			if (this.onMessageCallback != null) {
				ExternalInterface.call(this.onMessageCallback, Main.flashSucks(peerID), Main.flashSucks(msg));
			}
		}
		
		// Sends a message to a specific peer //
		public function sendTo(peerID:String, str:String):void {
			
			// We find the peer in the peer list //
			for each(var peer:NetStream in sendStream.peerStreams) {
				if (peer.farID == peerID) {
					Main.log("Sending to " + peerID + "... ");
					peer.send("receiveMessage", str);
					Main.log("Sent");
					break;
				}
			}
		}
		
		// Function that receives all the status change of the RTMFP server connection //
		public function ncStatus(event:NetStatusEvent):void {
			Main.log(event.info.code);
			
			// This status code indicates we are connected with the RTMFP server successfully //
			if (event.info.code == "NetConnection.Connect.Success") {
				Main.log(nc.nearID);
				this.myID = nc.nearID;
				
				if (this.onInitCallback != null) {
					ExternalInterface.call(this.onInitCallback);
				}
			}
			
			// This status code indicates that a peer disconnected //
			if (event.info.code == "NetStream.Connect.Closed") {
				if (this.onDisconnectCallback != null) {
					peerDisconnected(event.info.stream.farID);
				}
			}
		}
		
		// Looks for the peer that are now disconnected //
		public function peerDisconnected(peerID:String):void {
			if (peers[peerID] != null) {
				ExternalInterface.call(this.onDisconnectCallback, peerID);
				delete peers[peerID];
			}
		}
		
		// Set this peer in a listen mode that will accept incomming connection //
		public function listen(callback:String):void {
			var self:Main = this;
			
			Main.log("(AS) Listen ...");
			
			sendStream = new NetStream(nc, NetStream.DIRECT_CONNECTIONS);
			sendStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			sendStream.publish("media"); // "media" is the name of channel we publish to //
			
			// Object that holds the callback //
			var sendStreamClient:Object = new Object();
			sendStreamClient.onPeerConnect = function(callerns:NetStream):Boolean {
				Main.log("(AS) Receive connection from " + callerns.farID);
				ExternalInterface.call(callback, Main.flashSucks(callerns.farID));
				
				// We connect back to any peer that is connecting to us //
				// We need to do this with some delay, because it can only be done after the peer is accepted //
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
		
		// This function receives all the status code of the send stream //
		public function netStatusHandler(event:NetStatusEvent):void{
			Main.log("(AS) Listener : " + event.info.code);
		}
		
		public static function log (message:String):void {
			if (Main.IS_DEBUG) {
				ExternalInterface.call("console.log", Main.flashSucks((message)));
			}
		}
		
		// Crazy escaping, because some version of Flash can't handle \ without breaking your code //
		public static function flashSucks (data:String):String {
			return data.split("%").join("%25")
					   .split("\\").join("%5c")
					   .split("\"").join("%22")
					   .split("&").join("%26");
		}
	}
	
}