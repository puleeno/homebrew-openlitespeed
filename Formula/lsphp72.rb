class Lsphp72 < Formula
    homepage "https://secure.php.net"
    url "https://secure.php.net/get/php-7.2.10.tar.xz/from/this/mirror"
    sha256 "01c2154a3a8e3c0818acbdbc1a956832c828a0380ce6d1d14fea495ea21804f0"

    option "with-npm", "Install PHP-FPM"
    option "with-default", "Install php as default lsphp for Openlitespeed"

    bottle do
        root_url "https://dl.bintray.com/puleeno/openlitespeed"
        sha256 "91ea63454527ebfd0ec84192733f69e2640e938b5b6a8d195b8013424c78365e" => :high_sierra
    end


    depends_on "puleeno/openlitespeed/openlitespeed" => [:build, :test]
    depends_on "curl"
    depends_on "gettext"
    depends_on "glib"
    depends_on "icu4c"
    depends_on "libiconv" if DevelopmentTools.clang_build_version >= 1000
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

        # Each extension that is built on Mojave needs a direct reference to the
        # sdk path or it won't find the headers
        headers_path = "=#{MacOS.sdk_path_if_needed}/usr"

        # Required due to icu4c dependency
        ENV.cxx11

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
            --with-bz2#{headers_path}
            --with-icu-dir=#{Formula["icu4c"].opt_prefix}
            --with-mysqli=mysqlnd
            --with-openssl=#{Formula["openssl"].opt_prefix}
            --with-pdo-mysql=mysqlnd
            --with-pdo-pgsql=#{Formula["libpq"].opt_prefix}
            --with-pdo-sqlite=#{Formula["sqlite"].opt_prefix}
            --with-pic
            --with-gd
            --with-gmp=#{Formula["gmp"].opt_prefix}
            --with-png-dir=#{Formula["libpng"].opt_prefix}
            --with-webp-dir=#{Formula["webp"].opt_prefix}
            --with-gettext=#{Formula["gettext"].opt_prefix}
            --with-pgsql=#{Formula["libpq"].opt_prefix}
            --with-sqlite3=#{Formula["sqlite"].opt_prefix}
            --with-curl=#{Formula["curl"].opt_prefix}
            --with-icon
            --with-xmlrpc
            --with-zlib=#{Formula["zlib"].opt_prefix}
        ]

        if build.with? "fpm"
            args << "--enable-fpm"
            args << "--with-fpm-user=_www"
            args << "--with-fpm-group=_www"
        end

        if MacOS.sdk_path_if_needed
            args << "--with-iconv=#{Formula["libiconv"].opt_prefix}"
        end

        system "./configure", *args
        system "make"
        system "make", "install"

        config_files = {
            "php.ini-development" => "php.ini",
        }

        config_files.each_value do |dst|
            dst_default = config_path/"#{dst}.default"
            rm dst_default if dst_default.exist?
        end
        config_path.install config_files

        if build.with? "fpm"
            unless (var/"log/php-fpm.log").exist?
                (var/"log").mkpath
                touch var/"log/php-fpm.log"
            end
        end
    end

    def php_version
        version.to_s.split(".")[0..1].join(".")
    end
end
