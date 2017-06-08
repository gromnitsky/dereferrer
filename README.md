# dereferrer

Chrome 26+ extension.

Does a [referer spoofing](http://en.wikipedia.org/wiki/Referer_spoofing)
for a selected list of (sub)domains.

## Features

* Replaces/deletes HTTP `referer` header.
* A straiforward domain matching (no regexps, just natural to users
  `example.com` or `foo.example.net` strings).
* Auto-sync preferences (for signed users).

![options page](https://raw.github.com/gromnitsky/dereferrer/master/doc/ss-options.png)

## Download & Install

For a latest .crx file look
[here](http://gromnitsky.users.sourceforge.net/js/chrome/).

Save the file, then open Chrome's extensions page (`Alt-F`
`More tools->Extensions`) and drag & drop the file into the page.

## Build requirements:

	npm -g i json browserify

* xxd utility
* GNU make

## Compilation

To compile, run

    $ make

To make a .crx file, you'll need a private RSA key named `private.pem`
in the same directory where Makefile is. For testing purposes, generate
it with openssl:

    $ openssl genrsa -out private.pem 1024

and run:

    $ make crx

If everything was fine, `_build/dereferrer-x.y.z.crx` file will appear.

## License

MIT.

The icon is from [openclipart](http://openclipart.org/detail/24798/-by--24798).
