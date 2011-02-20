var JS = {};

;(function () {
	JS.namespace = function (namespace) {
		var parts = namespace.split(".");
		var obj = window;
		
		for (var i=0; i<parts.length; i++) {
			if (!obj[parts[i]]) {
				obj[parts[i]] = {};
			}
			
			obj = obj[parts[i]];
		}
	};
	
	JS.include = function (className) {
		var parts = className.split(".");
		var obj = window;
		
		for (var i=0; i<parts.length; i++) {
			if (!obj[parts[i]]) {
				return;
			}
			
			obj = obj[parts[i]];
		}
		
		return obj;
	};
})();