;(function () {
	JS.namespace("Flash");
	
	var ASCallback = JS.include("Flash.Utilities").ASCallback;
	
	// Class RTMFP //
	Flash.RTMFP = function (_serverURL) {
		var self = {};
		
		var _bridge;
		var _peerPool = {};
		
		// Event callback //
		var _onInit = function () {};
		var _onPeerConnect = function () {};
		var _onMessageReceive = function () {};
		
		// Private //
		
		function initSWF () {
			// Create a container box for the SWF //
			var RTMFPContainer = document.createElement("div");
			RTMFPContainer.id = "RTMFPContainer";
			RTMFPContainer.style.display = "none";
			
			document.body.appendChild(RTMFPContainer);
			
			swfobject.embedSWF(
				"RTMPBridge.swf", "RTMFPContainer", "0px", "0px", "10.0.0", 
				"expressInstall.swf", {}, {}, { id : "RTMFPBridge" });
				
			_bridge = document.getElementById("RTMFPBridge");
			
			waitForSWF();
		}
		
		function waitForSWF () {
			if (!_bridge.init) {
				setTimeout(function () {
					waitForSWF();
				}, 1000);
			} else {
				swfLoaded();
			}
		}
		
		function swfLoaded () {
			// Initialization of the listener //
			_bridge.onInit(ASCallback(initCompleted));
			_bridge.onMessage(ASCallback(messageReceive));
			
			// Initialization of the RTMFP Connection to the server //
			_bridge.init(_serverURL);
		}
		
		function initCompleted() {
			_onInit();
			
			// Listening for peer connection //
			_bridge.listen(ASCallback(peerConnection));
		}
		
		function peerConnection (peerID) {
			_peerPool[peerID] = {};
			_onPeerConnect(peerID);
		}
		
		function messageReceive(peerID, message) {
			_onMessageReceive(peerID, JSON.parse(message));
		}
		
		// Public //
		
		// public function ready (function () {[...]}) : void//
		self.ready = function (fnct) {
			if (typeof fnct != "function") {
				throw new TypeError("Parameter must be a function.");
			}
			
			_onInit = fnct;
		}
		
		// public function messageReceive(function (peerID : String, message : *) {[...]}) : void //
		self.messageReceive = function (fnct) {
			if (typeof fnct != "function") {
				throw new TypeError("Parameter must be a function.");
			}
			
			_onMessageReceive = fnct;
		}
		
		// public function peerConnect (function (peerID : String) {}) : void //
		self.peerConnect = function (fnct) {
			if (typeof fnct != "function") {
				throw new TypeError("Parameter must be a function.");
			}
			
			_onPeerConnect = fnct;
		}
		
		
		// public function addPeer(peerID : String) : void //
		self.addPeer = function (peerID) {
			_peerPool[peerID] = {};
			_bridge.connect(peerID);
		}
		
		// public function id() : String //
		self.id = function () {
			if (!_bridge.getMyID) {
				throw new Error("SWF is not loaded");
			}
			
			return _bridge.getMyID();
		}
		
		// public function send(text : *) : void //
		self.send = function (data) {
			if (!_bridge.broadcast) {
				throw new Error("SWF is not loaded");
			}
			
			_bridge.broadcast(JSON.stringify(data));
		}
		
		// Initialise the component //
		initSWF();
		
		return self;
	};
})();