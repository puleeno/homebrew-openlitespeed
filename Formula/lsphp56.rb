class Lsphp56 < Formula
    homepage "https://secure.php.net"
    url "https://secure.php.net/get/php-5.6.38.tar.xz/from/this/mirror"
    sha256 "c2fac47dc6316bd230f0ea91d8a5498af122fb6a3eb43f796c9ea5f59b04aa1e"

    option "with-npm", "Install PHP-FPM"
    option "with-default", "Install php as default lsphp for Openlitespeed"

    bottle do
        root_url "https://dl.bintray.com/puleeno/openlitespeed"
        sha256 "795663e57ca11483c2a8dcc2ffbaa08e6963ffdade5980e213e56328d7577fa1" => :high_sierra
    end

    depends_on "puleeno/openlitespeed/openlitespeed" => [:build, :test]
    depends_on "curl"
    depends_on "gettext"
    depends_on "glib"
    depends_on "icu4c"
    depends_on "gmp"
    depends_on "jpeg"
    depends_on "libpng"
    depends_on "libpq"
    depends_on "libzip"
    depends_on "openssl"
    depends_on "pcre"
    depends_on "sqlite"
    depends_on "webp"

    def install
        config_path = etc/"lsphp/#{php_version}"

        # Required due to icu4c dependency
        ENV.cxx11

        # icu4c 61.1 compatability
        ENV.append "CPPFLAGS", "-DU_USING_ICU_NAMESPACE=1"

        args = %W[
            --prefix=#{prefix}
            --localstatedir=#{var}
            --sysconfdir=#{config_path}
            --with-config-file-path=#{config_path}
            --with-config-file-scan-dir=#{config_path}/conf.d
            --with-pear=#{pkgshare}/pear
            --with-litespeed
            --enable-exif
            --enable-ftp
            --enable-intl
            --enable-mbregex
            --enable-mbstring
            --enable-mysqlnd
            --enable-zip
            --with-libzip
            --with-bz2
            --with-mysqli=mysqlnd
            --with-openssl=#{Formula["openssl"].opt_prefix}
            --with-pdo-mysql=mysqlnd
            --with-pdo-pgsql=#{Formula["libpq"].opt_prefix}
            --with-pdo-sqlite=#{Formula["sqlite"].opt_prefix}
            --with-icu-dir=#{Formula["icu4c"].opt_prefix}
            --with-pic
            --with-gd
            --with-gmp=#{Formula["gmp"].opt_prefix}
            --with-png-dir=#{Formula["libpng"].opt_prefix}
            --with-webp-dir=#{Formula["webp"].opt_prefix}
            --with-gettext=#{Formula["gettext"].opt_prefix}
            --with-pgsql=#{Formula["libpq"].opt_prefix}
            --with-sqlite3=#{Formula["sqlite"].opt_prefix}
            --with-curl
            --with-icon
            --with-xmlrpc
            --with-zlib
        ]

        if build.with? "fpm"
            args << "--enable-fpm"
            args << "--with-fpm-user=_www"
            args << "--with-fpm-group=_www"
        end

        system "./configure", *args
        system "make"
        system "make", "install"
    end

    def php_version
        version.to_s.split(".")[0..1].join(".")
    end
end
