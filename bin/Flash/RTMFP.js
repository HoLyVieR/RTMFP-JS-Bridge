;(function () {
	JS.namespace("Flash");
	
	var ASCallback = JS.include("Flash.Utilities").ASCallback;
	
	// Class RTMFP //
	Flash.RTMFP = function (_serverURL) {
		var self = {};
		
		var _bridge;
		var _peerPool = {};
		var _isSupported;
		
		// Event callback //
		var _onInit = function () {};
		var _onPeerConnect = function () {};
		var _onMessageReceive = function () {};
		var _onError = function () {};
		var _onPeerDisconnect = function () {};
		
		// Private //
		
		// Adds the SWF control in the page //
		function initSWF () {
			// Create a container box for the SWF //
			var RTMFPContainer = document.createElement("div");
			RTMFPContainer.id = "RTMFPContainer";
			RTMFPContainer.style.display = "none";
			
			document.body.appendChild(RTMFPContainer);
			
			swfobject.embedSWF(
				"RTMPBridge.swf", "RTMFPContainer", "0px", "0px", "10.0.0", 
				"expressInstall.swf", {}, {}, { id : "RTMFPBridge" },
				function (result) {
					_isSupported = result.success;
					
					if (result.success) {
						_bridge = document.getElementById("RTMFPBridge");
						waitForSWF();
					} else {
						_onError();
					}
				});
		}
		
		// Wait till the API callback are available //
		function waitForSWF () {
			if (!_bridge.onInit) {
				setTimeout(function () {
					waitForSWF ();
				}, 200);
			} else {
				swfLoaded();
			}
		}
		
		// Adds the callback for the initialization //
		function swfLoaded () {
			// Initialization of the listener //
			_bridge.onInit(ASCallback(initCompleted));
			_bridge.onMessage(ASCallback(messageReceive));
			
			// Initialization of the RTMFP Connection to the server //
			_bridge.init(_serverURL);
		}
		
		// When the connection to the RTMFP server is done we had the callback for the peer connection/deconnection //
		function initCompleted() {
			_onInit();
			
			// Listening for peer connection //
			_bridge.listen(ASCallback(peerConnection));
			_bridge.onPeerDisconnect(ASCallback(peerDisconnect));
		}
		
		// When someone connects //
		function peerConnection (peerID) {
			_peerPool[peerID] = {};
			_onPeerConnect(peerID);
		}
		
		// When someone disconnects //
		function peerDisconnect (peerID) {
			delete _peerPool[peerID];
			_onPeerDisconnect(peerID);
		}
		
		// When we receive a message from a peer //
		function messageReceive(peerID, message) {
			// Ugly hack because Flash can't handle \ //
			// Ya, that's how bad ExternalInterface is //
			// Not escaping \ in string ... WOW ... who had that horrible idea //
			message = message.replace(/%22/g, "\"")
						   .replace(/%5c/g, "\\")
						   .replace(/%26/g, "&")
						   .replace(/%25/g, "%");
			
			_onMessageReceive(peerID, JSON.parse(message));
		}
		
		// Public //
		
		// public function ready (function () {[...]}) : void//
		self.ready = function (fnct) {
			if (typeof fnct != "function") {
				throw new TypeError("Parameter must be a function.");
			}
			
			_onInit = fnct;
		};
		
		// public function messageReceive(function (peerID : String, message : *) {[...]}) : void //
		self.messageReceive = function (fnct) {
			if (typeof fnct != "function") {
				throw new TypeError("Parameter must be a function.");
			}
			
			_onMessageReceive = fnct;
		};
		
		// public function peerConnect (function (peerID : String) {}) : void //
		self.peerConnect = function (fnct) {
			if (typeof fnct != "function") {
				throw new TypeError("Parameter must be a function.");
			}
			
			_onPeerConnect = fnct;
		};
		
		// public function error (function () { ... }) : void //
		self.error = function (fnct) {
			if (typeof fnct != "function") {
				throw new TypeError("Parameter must be a function.");
			}
			
			_onError = fnct;
		};
		
		// public function peerDisconnect (function (peerID : String) { ... }) : void //
		self.peerDisconnect = function (fnct) {
			if (typeof fnct != "function") {
				throw new TypeError("Parameter must be a function.");
			}
			
			_onPeerDisconnect = fnct;
		};
		
		// public function addPeer(peerID : String) : void //
		self.addPeer = function (peerID) {
			_peerPool[peerID] = {};
			_bridge.connect(peerID);
		};
		
		// public function id() : String //
		self.id = function () {
			if (!_bridge.getMyID) {
				throw new Error("SWF is not loaded");
			}
			
			return _bridge.getMyID();
		};
		
		// public function send(text : *) : void //
		self.send = function (data) {
			if (!_bridge.broadcast) {
				throw new Error("SWF is not loaded");
			}
			
			_bridge.broadcast(JSON.stringify(data));
		};
		
		// public function sentTo(peerID : String, data : *):void //
		self.sendTo = function (peerID, data) {
			if (!_bridge.sendTo) {
				throw new Error("SWF is not loaded");
			}
			
			_bridge.sendTo(peerID, JSON.stringify(data));
		};
		
		// public function disconnect():void //
		self.disconnect = function () {
			if (!_bridge.disconnect) {
				throw new Error("SWF is not loaded");
			}
			
			_bridge.disconnect();
		};
		
		// public function disconnect(peerID : String):void //
		self.disconnectPeer = function (peerID) {
			if (!_bridge.disconnectPeer) {
				throw new Error("SWF is not loaded");
			}
			
			_bridge.disconnectPeer(peerID);
		};
		
		// public function support () : boolean //
		self.support = function () {
			return !!_isSupported;
		};
		
		// public function init () : void //
		self.init = function () {
			initSWF();
		};
		
		return self;
	};
})();