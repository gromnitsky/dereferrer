# dereferrer

Chrome 26+ extension.

(Download the compiled extension [here](http://gromnitsky.users.sourceforge.net/js/chrome/).)

Does a [referer spoofing](http://en.wikipedia.org/wiki/Referer_spoofing)
for a selected list of (sub)domains.

## Features

* Replaces/deletes HTTP `referer` header.
* Uses a straiforward domain matching algo (no regexps, just natural
  to users `example.com` or `foo.example.net` strings).
* Auto-syncs preferences (for 'signed in Chrome' users).

![options page](https://raw.github.com/gromnitsky/dereferrer/master/README.options.png)

## Build requirements

	$ npm -g i json browserify

* xxd utility
* GNU make

## Compilation

To compile the extension for the "unpacked mode", run

    $ make

Resulting files should be in `_build/ext`.

To generate a .crx:

    $ openssl genrsa -out private.pem 1024
    $ make crx

Then look for `_build/dereferrer-x.y.z.crx`.

## License

MIT.

The icon is from [openclipart](http://openclipart.org/detail/24798/-by--24798).
