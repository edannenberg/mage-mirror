mage-mirror
==========

Small Bash script to create a local Magento CE mirror.

Features
--------

* Applies official Magento CE patches to downloaded archives (configurable)
* Replaces 1.9.x sample data with [mp3 free](https://github.com/Vinai/compressed-magento-sample-data) versions (configurable), courtesy of Vinai <3
* Created file structure matches official Magento mirror for easy drop in replacement in existing code (configurable)

Quick Start
-----------

    $ git clone https://github.com/edannenberg/mage-mirror.git
    $ cd mage-mirror/
    $ ./mage-mirror.sh

The script supports POSIX parameter expansion for most options:

    $ APPLY_PATCHES=false MIRROR_VERSIONS="1.9.0.0 1.9.0.1" ./mage-mirror.sh

Once the script finishes you can simply upload the contents of the `mirror/` folder to a web server of your choice.

Managing Patches
----------------

* Drop new patches into the `patches/` folder, file structure should be fairly obvious
* Currently only patch scripts provided by Magento are supported, shouldn't be too hard to add plain `.diff` support though

`PATCH_SUPEE-4334_EE_1.11.0.0-1.13.0.2_v1.sh` and `PATCH_SUPEE-1868_EE_1.13.x_v1.sh` are currently excluded,
seems to be broken for Magento 1.8.x. Both patches are supposed to address USPS api changes.

Developer
---------
Erik Dannenberg [@edannenberg](https://twitter.com/edannenberg)

Licence
-------
[OSL - Open Software Licence 3.0](http://opensource.org/licenses/osl-3.0.php)

Copyright
---------
(c) 2015 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>
