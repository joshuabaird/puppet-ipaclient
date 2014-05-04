[![Build Status](https://travis-ci.org/stbenjam/puppet-ipaclient.svg?branch=master)](https://travis-ci.org/stbenjam/puppet-ipaclient)

IPAclient
========

This module supports configuring clients to use FreeIPA.

What's New
----------

Version 2 of this module has more features, like
simplifying the way that sudoers is configured and
managed.  Note that it's not backwards compatible
with 1.x and 0.x versions of this module.

Supported Platforms
-------------------

Tested on RHEL 6, CentOS 6, and Fedora 20.  It should work on any
Red Hat family OS that has IPA packages.

Examples
--------

See the manifests for full descriptions of the various parameters
available.

Discovery register:

    class { 'ipaclient':
      password => "rainbows"
    }

Another:

    class { 'ipaclient':
       user            => "admin",
       password        => "unicorns",
       server          => ["ipa01.pixiedust.com", "ipa02.pixiedust.com"]
       domain          => "pixiedust.com",
       realm           => "PIXEDUST.COM",
       mkhomedir       => false,
       automount       => true
       fixed_primary   => true,
    }

Default and simple sudoers:

    class { 'ipaclient::sudoers': }

Manual sudoers:

    class { 'ipaclient::sudoers':
        server  => "_srv_, ipa01.pixiedust.com",
        domain  => "pixiedust.com",
    }

Automounter only:

    class { 'ipaclient::automount':
        location    => 'home',
        server      => 'ipa01.pixiedust.com',
    }

Known Issues
------------

You must run puppet twice to get sudo working the first time, because it
relies on facts that are available AFTER ipa-client-install is run.

A workaround is to load them separately, and set the sudoer configuration
manually:

    class { 'ipaclient':
        sudo     => false,
        password => 'password',
    }

    class { 'ipaclient::sudoers':
        server    => "_srv_",
        domain    => "pixiedust.com",
        require   => Class['ipaclient'],
    }

MIT License
-----------
Copyright (c) 2014 Stephen Benjamin

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

