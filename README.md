[![Build Status](https://travis-ci.org/joshuabaird/puppet-ipaclient.svg?branch=master)](https://travis-ci.org/joshuabaird/puppet-ipaclient)

IPAclient
========

This module configures clients to use FreeIPA with as little fuss as possible.  This module used to be known as stbenjam/puppet-ipaclient, but is now being maintained at joshuabaird/puppet-ipaclient.

Thanks to all the [contributors](https://github.com/stbenjam/puppet-ipaclient/graphs/contributors)!

What's New
----------

  * FreeIPA 4 Support

Contributing
------------

Feedback and pull requests are very welcome.  New functionality should have tests.

Supported Platforms
-------------------

  * Enterprise Linux 6, 7 (RHEL, CentOS, etc)
  * Fedora 20 or newer
  * Ubuntu 14.04 or newer

Basically, any Red Hat or Debian derivative with packages.

Examples
--------

See the manifests for full descriptions of the various parameters
available.

Discovery register (w/ sane defaults: sudo, mkhomedir, ssh, etc):

    class { 'ipaclient':
      password => "rainbows"
    }

More complex:

    class { 'ipaclient':
       principal       => "admin",
       password        => "unicorns",
       server          => ["ipa01.pixiedust.com", "ipa02.pixiedust.com"]
       domain          => "pixiedust.com",
       realm           => "PIXEDUST.COM",
       mkhomedir       => false,
       automount       => true,
       ssh             => false,
       fixed_primary   => true
       automount_location => "home",
    }

Simple sudoers setup (only needed for older FreeIPA 3.x clients):

    class { 'ipaclient::sudoers': }

Note that starting with RHEL 6.6 and RHEL 7.1, ```ipa-client-install``` automatically takes care of all sudo configuration.  If you are running these versions, this module will not attempt to perform any sudo configuration.

Automounter only:

    class { 'ipaclient::automount':
        location    => 'home',
        server      => 'ipa01.pixiedust.com',
    }

MIT License
-----------
Copyright (c) 2015 Stephen Benjamin & Josh Baird

Permission is hereby granted, free of charge, to any person obtaining 
a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software 
is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.

