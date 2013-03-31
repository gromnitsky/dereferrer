/*
  A very simple Chrome's storage mocking. Pollutes global namespace.
  Original API: https://developer.chrome.com/extensions/storage.html

  The differences in the mock:

  - 1st parameter in get(), getBytesInUse() or remove() can only be
    string or null.

  - getBytesInUse() just return some nonsense number > 0 if the storage
    isn't empty.
*/

/*global root:true */
var getGlobal = function() {
	var _getGlobal = function() { return this }
	return _getGlobal()
}
root = getGlobal()


root.runtime = {
	lastError: undefined
}

root.chrome = {
	mock: {
		value: {},
		getBytesInUse: 0
	}
}

root.chrome.mock.updateBytesInUse = function() {
	var bytes = 0
	for (var idx in root.chrome.mock.value) {
		bytes += 1
	}
	root.chrome.mock.getBytesInUse = bytes
}

root.chrome.storage = {
	local: {
		get: function(key, callback) {
			if (key === null) {
				callback(root.chrome.mock.value)
			} else {
				callback(root.chrome.mock.value[key])
			}
		},
		getBytesInUse: function(obj, callback) {
			root.chrome.mock.updateBytesInUse()
			callback(root.chrome.mock.getBytesInUse)
		},
		set: function(obj, callback) {
			for (var idx in obj) root.chrome.mock.value[idx] = obj[idx]

			callback()
		},
		remove: function(key, callback) {
			delete root.chrome.mock.value.key
			callback()
		},
		clear: function(callback) {
			root.chrome.mock.value = {}
			callback()
		}
	}
}

root.chrome.storage.sync = root.chrome.storage.local
