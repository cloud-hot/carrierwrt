/*
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
*/

var fon_json_count = 0;
var fon_events_handled = {};

function json_call(uri, method, params, win, fail) {
	fon_json_count = fon_json_count + 1;
	var request = {"method": method, "id": fon_json_count, "params": params};
	new Ajax.Request(uri, {
		contentType: 'application/json',
		evalJSON: true,
		method: 'post',
		postBody: Object.toJSON(request),
		onSuccess: function(transport) {
			var json = transport.responseJSON;
			if (json && !json.error) {
				win(json.result);
			} else if (fail) {
				fail(transport, (json.error || false));
			}
		},
		onFailure: fail
	})
}

function fon_xhr_load(uri, div, win, complete) {
	fon_spinner(div);
	new Ajax.Updater($(div), uri, {
		evalScripts: true,
		onComplete: function() {
			fon_xhr_hijack(
				div,
				win,
				complete,
				fon_spinner
			);
		}
	})
}


function fon_xhr_hijack(div, win, complete, load) {
	cbi_hijack_forms($(div), function(transport) {
		var cbi_state = transport.getHeader("X-CBI-State")
		if (!win || !cbi_state || parseInt(cbi_state) <= 0) {
			var done = function() {
				$(div).update(transport.responseText);
				fon_xhr_hijack(div, win, complete, load);
			};
			fon_xhr_evalscripts(transport.responseText, false, done);
			try {
				done();
			} catch(e) {
				// do nothing
			}
		} else {
			new Ajax.Updater($(div), win, {
				evalScripts: true
			});
		}
		if (complete) {
			complete(div);
		}
	}, null, function() {
		if (load) {
			load(div);
		}
	});
}

// Derived from Prototype's extractScripts and Stefan Hayden's onJSReady Prototype plugin
// Searches for script tags inside given text, loads external scripts and evals inline-scripts
// afterwards
function fon_xhr_evalscripts(text, eval, done) {
	// Extract external scripts
	var pattern = '<script[^>]+src=\'?\"?([^\"\'>]+)\"?\'?[^>]*>';
    var matchAll = new RegExp(pattern, 'img');
    var matchOne = new RegExp(pattern, 'im');
    var scripts = (text.match(matchAll) || []).map(function(scriptTag) {
      return (scriptTag.match(matchOne) || ['', ''])[1];
    });

    var loaded = {};
    var on_load = function() {
    	for (var i in loaded) {
    		if (!loaded[i]) {
    			return false;
    		}
    	}

    	if (eval) {
    		text.evalScripts();
    	}

    	if (done) {
    		done();
    	}
    	return true;
    }
    
    if (scripts.size() < 1) {
    	on_load();
    } else {
    	var head = document.getElementsByTagName('head')[0];
    	scripts._each(function(file) {
    		loaded[file] = false;

    		head.appendChild(
    				new Element('script', { type: 'text/javascript', src: file.strip() })
    		)
    		.observe('readystatechange', function () {
    			if (!this.loaded && /^(loaded|complete)$/.test(this.readyState)) {
    				this.loaded = true;
    				loaded[file] = true;
    				on_load();
    			}
    		})
    		.observe('load', function () {
    			if (this.loaded) return;
    			this.loaded = true;
    			loaded[file] = true;
    			on_load();
    		});
    	});
    }
}
