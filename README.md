# Plugin providing SquashFS mounting functionality

This plugin adds SquashFS mounting functionality in Kirikiri2 / 吉里吉里2 / KirikiriZ / 吉里吉里Z

## Building

After cloning submodulesy, a simple `make` will generate `krsquashfs.dll`.

## How to use

After `Plugins.link("krsquashfs.dll");` is used, `mountSquashFs` will be exposed under the `Storages` class.

## License

This project is licensed under the MIT license. Please read the `LICENSE` file for more information.
