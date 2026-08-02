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

If you use port 80 for Listener please run brew service with *sudo* user
```
sudo brew services start openlitespeed
```

# Litespeed WebAdmin
URL: https://localhost:7080

**Default user info**
```
ID: admin
Password: 123456
```


# Multi PHP versions
Default Openlitespeed for homebrew uses lsphp81 (PHP 8.1) for WebAdmin and the default `lsphp` external app.
You can install other PHP version via this homebrew package.

List PHP version supports
- [x] lsphp56
- [x] lsphp73
- [x] lsphp80
- [x] lsphp81
- [x] lsphp82
- [x] lsphp83
- [x] lsphp84

**E.g: Litespeed PHP version 8.0**

```
brew install lsphp80
```
# Bug reports
If you have any issue please send me via [Github Issue](https://github.com/puleeno/homebrew-openlitespeed/issues)

# Donate
If this project help you reduce time to develop, you can give me a cup of coffee :)


[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/puleeno)

# Bottles
Binary bottles for all formulae are built and published automatically via GitHub Actions to the GitHub Container Registry
(`ghcr.io/v2/puleeno/openlitespeed`).

**Release workflow**
1. Open a pull request touching the formula(s) you want to release.
2. The `brew test-bot` workflow builds bottles for the PR and uploads them as artifacts.
3. Add the `pr-pull` label to the PR. The `brew pr-pull` workflow publishes the bottles to GHCR,
   commits the new bottle hashes back to `main`, and closes the PR.

Currently published for `arm64_sonoma` (macOS 14, Apple Silicon).
