desc "General-purpose scripting language"
  homepage "https://www.php.net/"
  # Should only be updated if the new version is announced on the homepage, https://www.php.net/
  url "https://www.php.net/distributions/php-8.0.3.tar.xz"
  mirror "https://fossies.org/linux/www/php-8.0.3.tar.xz"
  sha256 "c9816aa9745a9695672951eaff3a35ca5eddcb9cacf87a4f04b9fb1169010251"
  license "PHP-3.01"

  livecheck do
    url "https://www.php.net/releases/feed.php"
    regex(/PHP (\d+(?:\.\d+)+) /i)
  end

  head do
    url "https://github.com/php/php-src.git"

    depends_on "bison" => :build # bison >= 3.0.0 required to generate parsers
    depends_on "re2c" => :build # required to generate PHP lexers
  end

  depends_on "expat"
  depends_on "libxml2"
  depends_on "openssl"
  depends_on "zlib"
  depends_on "libzip"

  def install
      config_path = etc/"lsphp/admin/#{php_version}"

      # Each extension that is built on Mojave needs a direct reference to the
      # sdk path or it won't find the headers
      headers_path = "=#{MacOS.sdk_path_if_needed}/usr"

      # Required due to icu4c dependency
      ENV.cxx11

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
          --with-bz2#{headers_path}
          --with-zlib=#{Formula["zlib"].opt_prefix}
          --with-openssl
          --with-sqlite3=#{Formula["sqlite"].opt_prefix}
          --with-libexpat-dir=#{Formula["expat"].opt_prefix}
      ]


      system "./configure", *args
      system "make"
      system "make", "install"
  end

  def php_version
      version.to_s.split(".")[0..1].join(".")
  end
end
