class Lsphp72 < Formula
    homepage "https://secure.php.net"
    url "http://php.net/get/php-7.1.22.tar.xz/from/this/mirror"
    sha256 "9194c9b3a592d8376fde837dde711ec01ee26f8607fc2884047ef6f7c089b15d"

    depends_on "puleeno/openlitespeed/openlitespeed" => [:build, :test]
    depends_on "pkg-config" => :build
    depends_on "apr"
    depends_on "apr-util"
    depends_on "argon2"
    depends_on "aspell"
    depends_on "autoconf"
    depends_on "curl" if MacOS.version < :lion
    depends_on "freetds"
    depends_on "freetype"
    depends_on "gettext"
    depends_on "glib"
    depends_on "gmp"
    depends_on "icu4c"
    depends_on "jpeg"
    depends_on "libiconv" if DevelopmentTools.clang_build_version >= 1000
    depends_on "libpng"
    depends_on "libpq"
    depends_on "libsodium"
    depends_on "libzip"
    depends_on "openldap" if DevelopmentTools.clang_build_version >= 1000
    depends_on "openssl"
    depends_on "pcre"
    depends_on "sqlite"
    depends_on "unixodbc"
    depends_on "webp"

    def install
        config_path = etc/"lsphp/#{php_version}"
        (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?
        headers_path = "=#{MacOS.sdk_path_if_needed}/usr"

        args = %W[
            --prefix=#{Formula["openlitespeed"].prefix}/lsphp72
            --localstatedir=#{var}
            --sysconfdir=#{config_path}
            --with-config-file-path=#{config_path}
            --with-config-file-scan-dir=#{config_path}/conf.d
            --with-pear=#{pkgshare}/pear
            --with-litespeed
            --enable-bcmath
            --enable-calendar
            --enable-dba
            --enable-dtrace
            --enable-exif
            --enable-ftp
            --enable-fpm
            --enable-intl
            --enable-mbregex
            --enable-mbstring
            --enable-mysqlnd
            --enable-opcache-file
            --enable-pcntl
            --enable-phpdbg
            --enable-phpdbg-webhelper
            --enable-shmop
            --enable-soap
            --enable-sockets
            --enable-sysvmsg
            --enable-sysvsem
            --enable-sysvshm
            --enable-wddx
            --enable-zip
            --with-bz2#{headers_path}
            --with-fpm-user=_www
            --with-fpm-group=_www
            --with-freetype-dir=#{Formula["freetype"].opt_prefix}
            --with-gd
            --with-gettext=#{Formula["gettext"].opt_prefix}
            --with-gmp=#{Formula["gmp"].opt_prefix}
            --with-icu-dir=#{Formula["icu4c"].opt_prefix}
            --with-jpeg-dir=#{Formula["jpeg"].opt_prefix}
            --with-kerberos#{headers_path}
            --with-layout=GNU
            --with-ldap-sasl#{headers_path}
            --with-libxml-dir#{headers_path}
            --with-libedit#{headers_path}
            --with-libzip
            --with-mhash#{headers_path}
            --with-mysql-sock=/tmp/mysql.sock
            --with-mysqli=mysqlnd
            --with-ndbm#{headers_path}
            --with-openssl=#{Formula["openssl"].opt_prefix}
            --with-password-argon2=#{Formula["argon2"].opt_prefix}
            --with-pdo-dblib=#{Formula["freetds"].opt_prefix}
            --with-pdo-mysql=mysqlnd
            --with-pdo-odbc=unixODBC,#{Formula["unixodbc"].opt_prefix}
            --with-pdo-pgsql=#{Formula["libpq"].opt_prefix}
            --with-pdo-sqlite=#{Formula["sqlite"].opt_prefix}
            --with-pgsql=#{Formula["libpq"].opt_prefix}
            --with-pic
            --with-png-dir=#{Formula["libpng"].opt_prefix}
            --with-pspell=#{Formula["aspell"].opt_prefix}
            --with-sodium=#{Formula["libsodium"].opt_prefix}
            --with-sqlite3=#{Formula["sqlite"].opt_prefix}
            --with-unixODBC=#{Formula["unixodbc"].opt_prefix}
            --with-webp-dir=#{Formula["webp"].opt_prefix}
            --with-xmlrpc
            --with-xsl#{headers_path}
            --with-zlib#{headers_path}
        ]
        system "./configure", *args
        system "make"
        system "make", "install"

        if build.with? "with-default"
            ln_s #{Formula["openlitespeed"].prefix}/lsphp72/bin/lsphp, #{Formula["openlitespeed"].prefix}/admin/fcgi-bin/admin_php
            ln_s #{Formula["openlitespeed"].prefix}/lsphp72/bin/lsphp, #{Formula["openlitespeed"].prefix}/fcgi-bin/lsphp5
        end
    end

    def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>KeepAlive</key>
            <true/>
            <key>Label</key>
            <string>#{plist_name}</string>
            <key>ProgramArguments</key>
            <array>
            <string>#{opt_sbin}/php-fpm</string>
            <string>--nodaemonize</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>WorkingDirectory</key>
            <string>#{var}</string>
            <key>StandardErrorPath</key>
            <string>#{var}/log/php-fpm.log</string>
        </dict>
        </plist>
    EOS
    end

    def php_version
        version.to_s.split(".")[0..1].join(".")
    end
end
