class AdminPhp < Formula
    desc "General-purpose scripting language"
    homepage "https://www.php.net/"
    # Should only be updated if the new version is announced on the homepage, https://www.php.net/
    url "https://www.php.net/distributions/php-7.3.27.tar.xz"
    mirror "https://fossies.org/linux/www/php-7.3.27.tar.xz"
    sha256 "65f616e2d5b6faacedf62830fa047951b0136d5da34ae59e6744cbaf5dca148d"
    license "PHP-3.01"
    revision 1


    keg_only :versioned_formula

    deprecate! date: "2021-12-06", because: :versioned_formula

    depends_on "expat"
    depends_on "openssl"
    depends_on "libzip"
    depends_on "sqlite"

    uses_from_macos "bzip2"
    uses_from_macos "libxml2"
    uses_from_macos "zlib"

    on_macos do
      # PHP build system incorrectly links system libraries
      # see https://github.com/php/php-src/pull/3472
      patch :DATA
    end

    def install
      on_macos do
        # Ensure that libxml2 will be detected correctly in older MacOS
        ENV["SDKROOT"] = MacOS.sdk_path if MacOS.version == :el_capitan || MacOS.version == :sierra
      end

      # Required due to icu4c dependency
      ENV.cxx11

      # PHP 7.3 uses RSA_SSLV23_PADDING removed in OpenSSL 3.x
      # RSA_PKCS1_PADDING is the equivalent replacement
      ENV.append "CFLAGS", "-DRSA_SSLV23_PADDING=RSA_PKCS1_PADDING"

      # Newer Clang (ISO C99+) treats implicit function declarations as errors.
      # PHP 7.3's LiteSpeed SAPI has missing includes (e.g. php_header in lsapi_main.c).
      ENV.append "CFLAGS", "-Wno-implicit-function-declaration"

      # DNS resolver symbols (_res_9_init etc.) live in -lresolv on macOS arm64.
      ENV.append "LDFLAGS", "-lresolv"

      # Newer macOS SDK only provides the 3-arg POSIX readdir_r.
      # PHP 7.3 still calls the old 2-arg BSD version inside HAVE_OLD_READDIR_R.
      # Patch the source directly since -U flags are overridden by configure-generated config.h.
      # A temporary variable captures the 3rd arg since 'dp' is not in scope at the call site.
      inreplace "main/reentrancy.c",
        "readdir_r(dirp, entry);",
        "{ struct dirent *_readdir_result; readdir_r(dirp, entry, &_readdir_result); }"

      config_path = etc/"admin_php/#{php_version}"
      # Prevent system pear config from inhibiting pear install
      (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?

      # Prevent homebrew from hardcoding path to sed shim in phpize script
      ENV["lt_cv_path_SED"] = "sed"

      # Each extension that is built on Mojave needs a direct reference to the
      # sdk path or it won't find the headers
      headers_path = ""
      on_macos do
        headers_path = "=#{MacOS.sdk_path_if_needed}/usr"
      end

      args = %W[
        --prefix=#{prefix}
        --disable-all
        --with-litespeed
        --enable-zip
        --enable-xml
        --enable-json
        --enable-sockets
        --enable-session
        --enable-posix
        --enable-bcmath
        --with-libzip
        --with-openssl=#{Formula["openssl"].opt_prefix}
        --with-sqlite3=#{Formula["sqlite"].opt_prefix}
        --with-libexpat-dir=#{Formula["expat"].opt_prefix}
      ]

      on_macos do
        args << "--enable-dtrace"
        args << "--with-zlib#{headers_path}"
        args << "--with-bz2#{headers_path}"
        args << "--with-libxml-dir#{headers_path}"
      end

      system "./configure", *args
      system "make"
      system "make", "install"
    end

    def php_version
      version.to_s.split(".")[0..1].join(".")
    end
  end
