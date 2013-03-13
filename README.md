ipaclient
========

This is the ipaclient module.  You can use it to configure your servers
to use FreeIPA (only tested with version 2).  It handles automatic
IPA SUDOers setup, and also has the notion of supporting a "VIP."  Initial
registration must occur to the real hostname of the IDM server ($enrollment\_host)
then you can switch to using a VIP without problems ($ipa\_server).

Really, you should use the DNS Server that comes with IPA, or setup
your own SRV records to point to IPA, but that's not always possible.

This module's not meant to serve everyone's IPA needs.  Just something
I wrote for a specific use case.  Feel free to make it more generic.

Maybe you'd prefer to have a look at the proper provider and type that 
can also register to IPA:

    https://github.com/stbenjam/puppet-authconfig


MIT License
-----------
Copyright (c) 2013 Stephen Benjamin

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

