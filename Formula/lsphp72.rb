class Lsphp72 < Formula
    homepage "https://secure.php.net"
    url "https://secure.php.net/get/php-7.2.10.tar.xz/from/this/mirror"
    sha256 "01c2154a3a8e3c0818acbdbc1a956832c828a0380ce6d1d14fea495ea21804f0"

    option "with-default", "Install php as default lsphp for Openlitespeed"

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
            --with-fpm-user=_www
            --with-fpm-group=_www
            --with-freetype-dir=#{Formula["freetype"].opt_prefix}
            --with-gd
            --with-gettext=#{Formula["gettext"].opt_prefix}
            --with-gmp=#{Formula["gmp"].opt_prefix}
            --with-icu-dir=#{Formula["icu4c"].opt_prefix}
            --with-jpeg-dir=#{Formula["jpeg"].opt_prefix}
            --with-layout=GNU
            --with-libzip
            --with-mysql-sock=/tmp/mysql.sock
            --with-mysqli=mysqlnd
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
        ]

        if MacOS.version < :lion
            args << "--with-curl=#{Formula["curl"].opt_prefix}"
        else
            args << "--with-curl#{headers_path}"
        end

        if MacOS.sdk_path_if_needed
            args << "--with-iconv=#{Formula["libiconv"].opt_prefix}"
        end

        system "./configure", *args
        system "make"
        system "make", "install"

        if build.with? "with-default"
            ln_s #{Formula["openlitespeed"].prefix}/lsphp72/bin/lsphp, #{Formula["openlitespeed"].prefix}/admin/fcgi-bin/admin_php
            ln_s #{Formula["openlitespeed"].prefix}/lsphp72/bin/lsphp, #{Formula["openlitespeed"].prefix}/fcgi-bin/lsphp5
        end

        # Allow pecl to install outside of Cellar
        extension_dir = Utils.popen_read("#{bin}/php-config --extension-dir").chomp
        orig_ext_dir = File.basename(extension_dir)
        inreplace bin/"php-config", lib/"php", prefix/"pecl"
        inreplace "php.ini-development", %r{; ?extension_dir = "\./"},
        "extension_dir = \"#{HOMEBREW_PREFIX}/lib/lsphp/pecl/#{orig_ext_dir}\""

        config_files = {
            "php.ini-development" => "php.ini",
            "sapi/fpm/php-fpm.conf" => "php-fpm.conf",
            "sapi/fpm/www.conf" => "php-fpm.d/www.conf",
        }
        config_files.each_value do |dst|
            dst_default = config_path/"#{dst}.default"
            rm dst_default if dst_default.exist?
        end
        config_path.install config_files

        unless (var/"log/php-fpm.log").exist?
            (var/"log").mkpath
            touch var/"log/php-fpm.log"
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
