{
	"manifest_version": 2,
	"name": "dereferrer",
	"description": "TODO: add a description",
	"version": "syscmd(`json < package.json version | tr -d \\n')",

	"background": {
		"scripts": ["lib/background.js"]
	},
	"options_page": "lib/options.html",
	"permissions": [
		"storage",
		"webRequest",
		"webRequestBlocking",
		"<all_urls>"
	]
}
