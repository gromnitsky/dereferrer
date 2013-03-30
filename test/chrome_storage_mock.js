runtime = {
	lastError: undefined
}

chrome = {
	mock: {
		value: {},
		getBytesInUse: 0
	}
}

chrome.mock.updateBytesInUse = function() {
	var bytes = 0
	for (var idx in chrome.mock.value) {
		bytes += 1
	}
	chrome.mock.getBytesInUse = bytes
}

chrome.storage = {
	local: {
		get: function(key, callback) {
			if (key === null) {
				callback(chrome.mock.value)
			} else {
				callback(chrome.mock.value[key])
			}
		},
		getBytesInUse: function(obj, callback) {
			chrome.mock.updateBytesInUse()
			callback(chrome.mock.getBytesInUse)
		},
		set: function(obj, callback) {
			for (var idx in obj) chrome.mock.value[idx] = obj[idx]

			callback()
		},
		remove: function(key, callback) {
			delete chrome.mock.value[key]
			callback()
		},
		clear: function(callback) {
			chrome.mock.value = {}
			callback()
		}
	}
}

chrome.storage.sync = chrome.storage.local
