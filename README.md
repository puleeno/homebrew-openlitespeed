Install Openlitespeed on MacOSX
=

OpenLiteSpeed is a high-performance, lightweight, open source HTTP server developed and copyrighted by LiteSpeed Technologies. Users are free to download, use, distribute, and modify OpenLiteSpeed and its source code in accordance with the precepts of the GPLv3 license.

# Install Openlitespeed

If you want to install Openlitespeed on your Mac OS X or macOS systems via [homebrew](https://brew.sh/) package manager, This is what you need:

```
brew tap puleeno/openlitespeed
brew install openlitespeed
```

# How to start services
You can start Openlitespeed Service via brew services manager
```
brew services start openlitespeed
```

# Litespeed WebAdmin
URL: https://localhost:7080

**Default user info**
```
ID: admin
Password: 123456
```


# Multi PHP versions
Default Openlitespeed for homebrew use admin_php for WebAdmin with basic features.
You can install other PHP version via this homebrew package.

List PHP version supports
- [ ] lsphp53
- [ ] lsphp54
- [ ] lsphp55
- [ ] lsphp56
- [ ] lsphp70
- [ ] lsphp71
- [ ] lsphp72
- [ ] lsphp73


**E.g: Litespeed PHP version 7.2**

```
brew install lsphp72
```
