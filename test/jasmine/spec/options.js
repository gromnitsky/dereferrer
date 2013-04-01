/*global jasmine, beforeEach, afterEach, describe, it, expect, waitsFor,
  runs, startHere, spyOn, chrome */

var container

$(function() {
	$('<div id="my_jasmine_content">\
<table><tbody id="refrefs"></tbody></table>\
<button id="refrefs-add">Add</button>\
<button id="refrefs-reset">Reset</button>\
</div>').appendTo('body')

	startHere() // start options.js
	spyOn(window, 'alert')
	container = $('#refrefs')
//	console.log(document.querySelector('#jasmine_content'))
})

// Runs after finishing everything
var jasmineEnv = jasmine.getEnv()
var origJasmineFinishCallback = jasmineEnv.currentRunner().finishCallback
jasmineEnv.currentRunner().finishCallback = function () {
	origJasmineFinishCallback.apply(this, arguments)

	$('#my_jasmine_content').remove()
}

describe("First time load", function() {
	it("contains a table & 2 refrefs from the storage", function() {
		expect(container).toBe('tbody')
		waitsFor(function() {
			if ($('tr', container).length === 3) return true
		}, "2 refrefs to appear", 1000)
	})
})

describe("Modifying refrefs", function() {
	it("press 'add' button twice", function() {
		waitsFor(function() {
			$('#refrefs-add').click()
			if ($('tr', container).length === 4) return true
		}, "1 refref to appear", 1000)

		waitsFor(function() {
			$('#refrefs-add').click()
			if ($('tr', container).length === 5) return true
		}, "another refref to appear", 1000)
	})

	it("adds new refref", function() {
		runs(function() {
			var domain = $('#refrefs tr:last input:first')
			domain.get(0).value = '12'
			domain.trigger('change')
			expect(window.alert.calls.length).toEqual(1)

			domain.get(0).value = '123'
			domain.trigger('change')
			expect(window.alert.calls.length).toEqual(1)

			var storage_contents
			chrome.storage.local.get(null, function(val) {
				storage_contents = Object.keys(val)
			})
			waitsFor(function() {
				if (storage_contents.length == 3) return true
			}, "3 storage objects to be in the storage", 1000)
		})
	})
})

describe("Reset", function() {
	it("resets to defaults", function() {
		runs(function() {
			$('#refrefs-reset').click()
		})
		waitsFor(function() {
			if ($('tr', container).length === 3) return true
		}, "2 refrefs to appear", 1000)
	})
})
