/**
 * ...
 * @author Olivier Arteau
 */

;(function() {
	JS.namespace("Flash");
	
	var callbackIncrement = 0;	
	
	// Class Utilities //
	Flash.Utilities = function () {}
	
	// static function ASCallback //
	Flash.Utilities.ASCallback = function(fnct) {
		var n = "fnct" + (callbackIncrement++);
		
		Flash.Utilities.ASCallback.dump[n] = function () {
			return fnct.apply(null, arguments);
		};
		
		return "Flash.Utilities.ASCallback.dump." + n;
	};
	
	Flash.Utilities.ASCallback.dump = {};
})();
