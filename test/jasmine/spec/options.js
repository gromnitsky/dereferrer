/*global jasmine, beforeEach, afterEach, describe, it, expect, waitsFor,
  runs, startHere */

var container

$(function() {
	$('<div id="my_jasmine_content">\
<table><tbody id="refrefs"></tbody></table>\
<button id="refrefs-add">Add</button>\
</div>').appendTo('body')

	startHere() // start options.js
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
	beforeEach(function() {
		container = $('#refrefs')
	})

	it("contains a table & 2 refrefs from the storage", function() {
		expect(container).toBe('tbody')
		waitsFor(function() {
			if ($('tr', container).length === 2) return true
		}, "2 refrefs to appear", 1000)
	})
})

describe("Modifying refrefs", function() {
	it("adds new refref", function() {
		waitsFor(function() {
			$('#refrefs-add').click()
			if ($('tr', container).length === 3) return true
		}, "1 refref to appear", 1000)

		waitsFor(function() {
			$('#refrefs-add').click()
			if ($('tr', container).length === 4) return true
		}, "another refref to appear", 1000)
	})
})
