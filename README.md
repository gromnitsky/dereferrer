# dereferrer

Chrome 25+ extension.

TODO: write a description

## Build requirements:

* jsontool in global mode.
* GNU m4
* xxd utility.
* GNU make.

## Compilation

To compile, run

    $ make compile

To make a .crx file, you'll need a private RSA key named `private.pem`
in the same directory where Makefile is. For testing purposes, generate
it with openssl:

    $ openssl genrsa -out private.pem 1024

and run:

    $ make crx

If everything was fine, `dereferrer-x.y.z.crx` file will
appear.

## License

MIT.
