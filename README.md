mage-mirror
==========

Small Bash script to create and maintain a fully patched Magento CE mirror.

Features
--------

* Applies official Magento CE and custom diff style patches to downloaded archives (configurable)
* Replaces 1.9.x sample data with [mp3 free](https://github.com/Vinai/compressed-magento-sample-data) versions (configurable), courtesy of Vinai <3
* Creates file structure matching official Magento mirror, for easy drop in replacement with existing code, or a flat mirror

Quick Start
-----------

    $ git clone https://github.com/edannenberg/mage-mirror.git
    $ cd mage-mirror/
    $ ./mage-mirror.sh

POSIX parameter expansion is supported for most options:

    $ APPLY_PATCHES=false MIRROR_VERSIONS="1.9.0.0 1.9.0.1" ./mage-mirror.sh

Downloaded archives are kept unmodified at `$DL_PATH` to avoid downloading again on script rerun.
The mirror is created at `$MIRROR_PATH`, default: `mirror/`.

NOTE: Automated downloads are broken since Magento 1.9.2.0, you will need to download them manually to `$DL_PATH`. Also remove any timestamp from the filename.

Managing Patches
----------------

* Patch files are kept at `$PATCHES_PATH`, default: `patches/`
* Sub folder names are used to define the Magento version range each patch should be applied to
* Patch dependencies are defined via `$PATCH_DEPENDENCIES` in `mage-mirror.sh` (rarely needed)

Patch Status
------------

The repo comes with all [official](http://www.magentocommerce.com/download) Magento CE Patches, except:

`PATCH_SUPEE-4334_EE_1.11.0.0-1.13.0.2_v1.sh`
`PATCH_SUPEE-1868_EE_1.13.x_v1.sh`

Which are excluded only for Magento 1.8.x.

`PATCH_SUPEE-1868` is broken for Magento 1.8.x and `PATCH_SUPEE-4334` depends on the former.
Both patches are supposed to address USPS api changes. 1.7.x is unaffected and fully patched.

Unofficial Patches:

[magento_url_rewrite.patch](https://gist.github.com/edannenberg/5310008)

Developer
---------
Erik Dannenberg [@edannenberg](https://twitter.com/edannenberg)

Licence
-------
[OSL - Open Software Licence 3.0](http://opensource.org/licenses/osl-3.0.php)

Copyright
---------
(c) 2015 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>
