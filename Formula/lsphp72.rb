class Lsphp72 < Formula
    homepage "https://secure.php.net"
    url "https://secure.php.net/get/php-7.2.10.tar.xz/from/this/mirror"
    sha256 "01c2154a3a8e3c0818acbdbc1a956832c828a0380ce6d1d14fea495ea21804f0"

    option "with-default", "Install php as default lsphp for Openlitespeed"


    depends_on "puleeno/openlitespeed/openlitespeed" => [:build, :test]
    depends_on "curl"
    depends_on "gettext"
    depends_on "libpq"
    depends_on "openssl"
    depends_on "pcre"
    depends_on "sqlite"

    def install
        config_path = etc/"lsphp/#{php_version}"
        args = %W[
            --prefix=#{prefix}
            --with-litespeed
            --enable-mbstring
            --enable-mysqlnd
            --enable-zip
            --with-gd
            --with-gettext=#{Formula["gettext"].opt_prefix}
            --with-mysqli=mysqlnd
            --with-openssl=#{Formula["openssl"].opt_prefix}
            --with-pdo-mysql=mysqlnd
            --with-pdo-pgsql=#{Formula["libpq"].opt_prefix}
            --with-pdo-sqlite=#{Formula["sqlite"].opt_prefix}
            --with-pgsql=#{Formula["libpq"].opt_prefix}
            --with-sqlite3=#{Formula["sqlite"].opt_prefix}
            --with-xmlrpc
        ]
        system "./configure", *args
        system "make"
        system "make", "install"
    end

    def php_version
        version.to_s.split(".")[0..1].join(".")
    end
end
