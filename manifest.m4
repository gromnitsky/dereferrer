{
	"manifest_version": 2,
	"name": "dereferrer",
	"description": "Referer spoofing",
	"version": "syscmd(`json < package.json version | tr -d \\n')",
	"icons": {
		"128": "icons/128.png"
	},

	"page_action": {
		"default_icon": {
			"19": "icons/19.png"
		}
	},
	"background": {
		"scripts": ["lib/background.js"]
	},
	"options_page": "lib/options.html",
	"permissions": [
		"tabs",
		"storage",
		"webRequest",
		"webRequestBlocking",
		"<all_urls>"
	]
}
