class Lsphp72 < Formula
    desc "General-purpose scripting language"
    homepage "https://secure.php.net/"
    url "https://php.net/get/php-7.2.13.tar.xz/from/this/mirror"
    sha256 "14b0429abdb46b65c843e5882c9a8c46b31dfbf279c747293b8ab950c2644a4b"
  
    bottle do
      sha256 "6dfcf4baffb4a9b929725a69d6d162dcf38f403788ef45740a2572cb1b610765" => :mojave
      sha256 "30f1ada91bee7fe2fb2ee69ce6b7714dae947f2fafe8a408ca4e19b2d4e5d3da" => :high_sierra
      sha256 "7a1c6d536b23d1c2fc06b17ada65c8d62ad56cf4304b3f1fdb41dd66db48e38b" => :sierra
    end
  
    keg_only :versioned_formula
  
    depends_on "puleeno/openlitespeed/openlitespeed" => [:build, :test]
    depends_on "pkg-config" => :build
    depends_on "apr"
    depends_on "apr-util"
    depends_on "argon2"
    depends_on "aspell"
    depends_on "autoconf"
    depends_on "curl-openssl"
    depends_on "freetds"
    depends_on "freetype"
    depends_on "gettext"
    depends_on "glib"
    depends_on "libiconv" if DevelopmentTools.clang_build_version >= 1000
    depends_on "gmp"
    depends_on "icu4c"
    depends_on "jpeg"
    depends_on "libpng"
    depends_on "libpq"
    depends_on "libsodium"
    depends_on "libzip"
    depends_on "openldap"
    depends_on "openssl"
    depends_on "pcre"
    depends_on "sqlite"
    depends_on "unixodbc"
    depends_on "webp"
  
    # PHP build system incorrectly links system libraries
    # see https://github.com/php/php-src/pull/3472
    patch :DATA
  
    needs :cxx11
  
    def install
      # Ensure that libxml2 will be detected correctly in older MacOS
      if MacOS.version == :el_capitan || MacOS.version == :sierra
        ENV["SDKROOT"] = MacOS.sdk_path
      end
  
      # buildconf required due to system library linking bug patch
      system "./buildconf", "--force"

      # compile a thread safe version of PHP and therefore it is not
      ENV.cxx11
  
      config_path = etc/"lsphp/#{php_version}"
      # Prevent system pear config from inhibiting pear install
      (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?
  
      # Prevent homebrew from harcoding path to sed shim in phpize script
      ENV["lt_cv_path_SED"] = "sed"
  
      # Each extension that is built on Mojave needs a direct reference to the
      # sdk path or it won't find the headers
      headers_path = "=#{MacOS.sdk_path_if_needed}/usr"
  
      args = %W[
        --prefix=#{prefix}
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
        --enable-intl
        --enable-mbregex
        --enable-mbstring
        --enable-mysqlnd
        --enable-pcntl
        --enable-shmop
        --enable-soap
        --enable-sockets
        --enable-sysvmsg
        --enable-sysvsem
        --enable-sysvshm
        --enable-wddx
        --enable-zip
        --with-bz2#{headers_path}
        --with-curl=#{Formula["curl-openssl"].opt_prefix}
        --with-freetype-dir=#{Formula["freetype"].opt_prefix}
        --with-gd
        --with-gettext=#{Formula["gettext"].opt_prefix}
        --with-gmp=#{Formula["gmp"].opt_prefix}
        --with-iconv#{headers_path}
        --with-icu-dir=#{Formula["icu4c"].opt_prefix}
        --with-jpeg-dir=#{Formula["jpeg"].opt_prefix}
        --with-kerberos#{headers_path}
        --with-layout=GNU
        --with-ldap=#{Formula["openldap"].opt_prefix}
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

      if MacOS.sdk_path_if_needed
        args << "--with-iconv=#{Formula["libiconv"].opt_prefix}"
      end

  
      system "./configure", *args
      system "make"
      system "make", "install"
  
      # Allow pecl to install outside of Cellar
      extension_dir = Utils.popen_read("#{bin}/php-config --extension-dir").chomp
      orig_ext_dir = File.basename(extension_dir)
      inreplace bin/"php-config", lib/"lsphp", prefix/"pecl"
      inreplace "php.ini-development", %r{; ?extension_dir = "\./"},
        "extension_dir = \"#{HOMEBREW_PREFIX}/lib/lsphp/pecl/#{orig_ext_dir}\""
  
      config_files = {
        "php.ini-development"   => "php.ini",
      }
      config_files.each_value do |dst|
        dst_default = config_path/"#{dst}.default"
        rm dst_default if dst_default.exist?
      end
    end
  
    def php_version
      version.to_s.split(".")[0..1].join(".")
    end
  
  end