class Lsphp56 < Formula
  desc "General-purpose scripting language"
  homepage "https://secure.php.net/"
  url "https://github.com/shivammathur/php-src-backports/archive/ebb82d7337885ac0d4346a943e336e9784d3af55.tar.gz"
  version "5.6.40"
  sha256 "9d556c089a7cde5341744691920b482dc90013a8420973822235a5758502f797"
  license "PHP-3.01"
  revision 4

  bottle do
    root_url "https://ghcr.io/v2/puleeno/openlitespeed"
    sha256 cellar: :any, arm64_sonoma: "80688a481a19b817a6dce7ac2b6919f6b0bfc6b2ab8030bbbeabde7362d53376"
  end

  keg_only :versioned_formula

  # This PHP version is not supported upstream as of 2018-12-31.
  # Although, this was built with back-ported security patches,
  # we recommended to use a currently supported PHP version.
  # For more details, refer to https://www.php.net/eol.php

  depends_on "puleeno/openlitespeed/openlitespeed" => [:build]

  depends_on "bison" => :build
  depends_on "httpd" => [:build, :test]
  depends_on "pkg-config" => :build
  depends_on "re2c" => :build
  depends_on "apr"
  depends_on "apr-util"
  depends_on "aspell"
  depends_on "autoconf"
  depends_on "curl"
  depends_on "freetds"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "gmp"
  depends_on "icu4c"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libpq"
  depends_on "libtool"
  depends_on "libzip"
  depends_on "openldap"
  depends_on "openssl"
  depends_on "pcre"
  depends_on "sqlite"
  depends_on "tidy-html5"
  depends_on "unixodbc"

  uses_from_macos "bzip2"
  uses_from_macos "libedit"
  uses_from_macos "libxml2"
  uses_from_macos "libxslt"
  uses_from_macos "zlib"

  on_macos do
    # PHP build system incorrectly links system libraries
    # see https://github.com/php/php-src/pull/3472
    patch :DATA
  end

  def install
    # Work around configure issues with Xcode 12
    # See https://bugs.php.net/bug.php?id=80171
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"
    ENV.append "CFLAGS", "-Wno-incompatible-function-pointer-types"
    ENV.append "CFLAGS", "-Wno-implicit-int"

    # Workaround for https://bugs.php.net/80310
    ENV.append "CFLAGS", "-DU_DEFINE_FALSE_AND_TRUE=1"
    ENV.append "CXXFLAGS", "-DU_DEFINE_FALSE_AND_TRUE=1"

    # PHP 5.6 uses RSA_SSLV23_PADDING removed in OpenSSL 3.x
    # RSA_PKCS1_PADDING is the equivalent replacement
    ENV.append "CFLAGS", "-DRSA_SSLV23_PADDING=RSA_PKCS1_PADDING"

    # DNS resolver symbols (_res_9_init etc.) live in -lresolv on macOS arm64.
    ENV.append "LDFLAGS", "-lresolv"

    # Newer macOS SDK only provides the 3-arg POSIX readdir_r.
    # PHP 5.6 still calls the old 2-arg BSD version inside HAVE_OLD_READDIR_R.
    inreplace "main/reentrancy.c",
      "readdir_r(dirp, entry);",
      "{ struct dirent *_readdir_result; readdir_r(dirp, entry, &_readdir_result); }"

    # buildconf required due to system library linking bug patch
    system "./buildconf", "--force"

    # API compatibility with tidy-html5 v5.0.0 - https://github.com/htacg/tidy-html5/issues/224
    inreplace "ext/tidy/tidy.c", "buffio.h", "tidybuffio.h"

    # Required due to icu4c dependency. ICU 78 headers (bytestream.h,
    # char16ptr.h) use C++17 features (std::void_t, std::enable_if_t), so a
    # plain C++11 toolchain can no longer compile PHP 5.6's ext/intl.
    ENV.append "CXXFLAGS", "-std=c++17"
    ENV.append "CXXFLAGS", "-Wno-register"

    # icu4c 61.1 compatability
    ENV.append "CPPFLAGS", "-DU_USING_ICU_NAMESPACE=1"

    config_path = etc/"lsphp/#{php_version}"
    # Prevent system pear config from inhibiting pear install
    (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?

    # Prevent homebrew from harcoding path to sed shim in phpize script
    ENV["lt_cv_path_SED"] = "sed"

    # Each extension that is built on Mojave needs a direct reference to the
    # sdk path or it won't find the headers
    headers_path = ""
    headers_path = "=#{MacOS.sdk_path_if_needed}/usr" if OS.mac?

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
      --enable-exif
      --enable-ftp
      --enable-fpm
      --enable-intl
      --enable-mbregex
      --enable-mbstring
      --enable-mysqlnd
      --enable-opcache
      --enable-pcntl
      --enable-phpdbg
      --enable-shmop
      --enable-soap
      --enable-sockets
      --enable-sysvmsg
      --enable-sysvsem
      --enable-sysvshm
      --enable-wddx
      --enable-zip
      --with-curl=#{Formula["curl"].opt_prefix}
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
      --with-libzip
      --with-mhash#{headers_path}
      --with-mysql-sock=/tmp/mysql.sock
      --with-mysqli=mysqlnd
      --with-mysql=mysqlnd
      --with-openssl=#{Formula["openssl"].opt_prefix}
      --with-pdo-dblib=#{Formula["freetds"].opt_prefix}
      --with-pdo-mysql=mysqlnd
      --with-pdo-odbc=unixODBC,#{Formula["unixodbc"].opt_prefix}
      --with-pdo-pgsql=#{Formula["libpq"].opt_prefix}
      --with-pdo-sqlite=#{Formula["sqlite"].opt_prefix}
      --with-pgsql=#{Formula["libpq"].opt_prefix}
      --with-pic
      --with-png-dir=#{Formula["libpng"].opt_prefix}
      --with-pspell=#{Formula["aspell"].opt_prefix}
      --with-sqlite3=#{Formula["sqlite"].opt_prefix}
      --with-tidy=#{Formula["tidy-html5"].opt_prefix}
      --with-unixODBC=#{Formula["unixodbc"].opt_prefix}
      --with-xmlrpc
    ]

    if OS.mac?
      args << "--with-bz2#{headers_path}"
      args << "--with-libedit#{headers_path}"
      args << "--with-libxml-dir#{headers_path}"
      args << "--with-ndbm#{headers_path}"
      args << "--with-zlib#{headers_path}"
    end

    if OS.linux?
      args << "--with-zlib=#{Formula["zlib"].opt_prefix}"
      args << "--with-bzip2=#{Formula["bzip2"].opt_prefix}"
      args << "--with-libedit=#{Formula["libedit"].opt_prefix}"
      args << "--with-libxml-dir=#{Formula["libxml2"].opt_prefix}"
      args << "--with-xsl=#{Formula["libxslt"].opt_prefix}"
      args << "--without-ldap-sasl"
      args << "--without-ndbm"
      args << "--without-gdbm"
    end

    system "./configure", *args
    system "make"
    system "make", "install"

    # Allow pecl to install outside of Cellar
    extension_dir = Utils.safe_popen_read("#{bin}/php-config", "--extension-dir").chomp
    orig_ext_dir = File.basename(extension_dir)
    inreplace bin/"php-config", lib/"php", prefix/"pecl"
    %w[development production].each do |mode|
      inreplace "php.ini-#{mode}", %r{; ?extension_dir = "\./"},
        "extension_dir = \"#{HOMEBREW_PREFIX}/lib/lsphp/pecl/#{orig_ext_dir}\""
    end

    # Use OpenSSL cert bundle
    openssl = Formula["openssl"]
    %w[development production].each do |mode|
      inreplace "php.ini-#{mode}", /; ?openssl\.cafile=/,
        "openssl.cafile = \"#{openssl.pkgetc}/cert.pem\""
      inreplace "php.ini-#{mode}", /; ?openssl\.capath=/,
        "openssl.capath = \"#{openssl.pkgetc}/certs\""
    end

    config_files = {
      "php.ini-development"   => "php.ini",
      "php.ini-production"    => "php.ini-production",
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

  def post_install
    pear_prefix = pkgshare/"pear"
    pear_files = %W[
      #{pear_prefix}/.depdblock
      #{pear_prefix}/.filemap
      #{pear_prefix}/.depdb
      #{pear_prefix}/.lock
    ]

    %W[
      #{pear_prefix}/.channels
      #{pear_prefix}/.channels/.alias
    ].each do |f|
      chmod 0755, f
      pear_files.concat(Dir["#{f}/*"])
    end

    chmod 0644, pear_files

    # Custom location for extensions installed via pecl
    pecl_path = HOMEBREW_PREFIX/"lib/lsphp/pecl"
    pecl_path.mkpath
    ln_s pecl_path, prefix/"pecl" unless (prefix/"pecl").exist?
    extension_dir = Utils.safe_popen_read("#{bin}/php-config", "--extension-dir").chomp
    php_basename = File.basename(extension_dir)
    php_ext_dir = opt_prefix/"lib/php"/php_basename

    # fix pear config to install outside cellar
    pear_path = HOMEBREW_PREFIX/"share/pear@#{php_version}"
    cp_r pkgshare/"pear/.", pear_path
    {
      "php_ini"  => etc/"lsphp/#{php_version}/php.ini",
      "php_dir"  => pear_path,
      "doc_dir"  => pear_path/"doc",
      "ext_dir"  => pecl_path/php_basename,
      "bin_dir"  => opt_bin,
      "data_dir" => pear_path/"data",
      "cfg_dir"  => pear_path/"cfg",
      "www_dir"  => pear_path/"htdocs",
      "man_dir"  => HOMEBREW_PREFIX/"share/man",
      "test_dir" => pear_path/"test",
      "php_bin"  => opt_bin/"php",
    }.each do |key, value|
      value.mkpath if /(?<!bin|man)_dir$/.match?(key)
      system bin/"pear", "config-set", key, value, "system"
    end

    system bin/"pear", "update-channels"

    %w[
      opcache
    ].each do |e|
      ext_config_path = etc/"php/#{php_version}/conf.d/ext-#{e}.ini"
      extension_type = (e == "opcache") ? "zend_extension" : "extension"
      if ext_config_path.exist?
        inreplace ext_config_path,
          /#{extension_type}=.*$/, "#{extension_type}=#{php_ext_dir}/#{e}.so"
      else
        ext_config_path.write <<~EOS
          [#{e}]
          #{extension_type}="#{php_ext_dir}/#{e}.so"
        EOS
      end
    end
  end

  def php_version
    version.to_s.split(".")[0..1].join(".")
  end
end

__END__
diff --git a/acinclude.m4 b/acinclude.m4
index 168c465f8d..6c087d152f 100644
--- a/acinclude.m4
+++ b/acinclude.m4
@@ -441,7 +441,11 @@ dnl
 dnl Adds a path to linkpath/runpath (LDFLAGS)
 dnl
 AC_DEFUN([PHP_ADD_LIBPATH],[
-  if test "$1" != "/usr/$PHP_LIBDIR" && test "$1" != "/usr/lib"; then
+  case "$1" in
+  "/usr/$PHP_LIBDIR"|"/usr/lib"[)] ;;
+  /Library/Developer/CommandLineTools/SDKs/*/usr/lib[)] ;;
+  /Applications/Xcode*.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/*/usr/lib[)] ;;
+  *[)]
     PHP_EXPAND_PATH($1, ai_p)
     ifelse([$2],,[
       _PHP_ADD_LIBPATH_GLOBAL([$ai_p])
@@ -452,8 +456,8 @@ AC_DEFUN([PHP_ADD_LIBPATH],[
       else
         _PHP_ADD_LIBPATH_GLOBAL([$ai_p])
       fi
-    ])
-  fi
+    ]) ;;
+  esac
 ])

 dnl
@@ -487,7 +491,11 @@ dnl add an include path.
 dnl if before is 1, add in the beginning of INCLUDES.
 dnl
 AC_DEFUN([PHP_ADD_INCLUDE],[
-  if test "$1" != "/usr/include"; then
+  case "$1" in
+  "/usr/include"[)] ;;
+  /Library/Developer/CommandLineTools/SDKs/*/usr/include[)] ;;
+  /Applications/Xcode*.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/*/usr/include[)] ;;
+  *[)]
     PHP_EXPAND_PATH($1, ai_p)
     PHP_RUN_ONCE(INCLUDEPATH, $ai_p, [
       if test "$2"; then
@@ -495,8 +503,8 @@ AC_DEFUN([PHP_ADD_INCLUDE],[
       else
         INCLUDES="$INCLUDES -I$ai_p"
       fi
-    ])
-  fi
+    ]) ;;
+  esac
 ])

 dnl internal, don't use
@@ -2411,7 +2419,8 @@ AC_DEFUN([PHP_SETUP_ICONV], [
     fi

     if test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.a ||
-       test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.$SHLIB_SUFFIX_NAME
+       test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.$SHLIB_SUFFIX_NAME ||
+       test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.tbd
     then
       PHP_CHECK_LIBRARY($iconv_lib_name, libiconv, [
         found_iconv=yes

diff --git a/acinclude.m4 b/acinclude.m4
index 0fd9623..dc7bb5e 100644
--- a/acinclude.m4
+++ b/acinclude.m4
@@ -1963,21 +1963,19 @@ dnl
 AC_DEFUN([PHP_TEST_BUILD], [
   old_LIBS=$LIBS
   LIBS="$4 $LIBS"
-  AC_TRY_RUN([
+  AC_LINK_IFELSE([AC_LANG_SOURCE([[
     $5
     char $1();
     int main() {
       $1();
       return 0;
     }
-  ], [
+  ]])],[
     LIBS=$old_LIBS
     $2
   ],[
     LIBS=$old_LIBS
     $3
-  ],[
-    LIBS=$old_LIBS
   ])
 ])
 
 diff --git a/Zend/zend_compile.h b/Zend/zend_compile.h
index a0955e34fe..09b4984f90 100644
--- a/Zend/zend_compile.h
+++ b/Zend/zend_compile.h
@@ -414,9 +414,6 @@ struct _zend_execute_data {

 #define EX(element) execute_data.element

-#define EX_TMP_VAR(ex, n)	   ((temp_variable*)(((char*)(ex)) + ((int)(n))))
-#define EX_TMP_VAR_NUM(ex, n)  (EX_TMP_VAR(ex, 0) - (1 + (n)))
-
 #define EX_CV_NUM(ex, n)       (((zval***)(((char*)(ex))+ZEND_MM_ALIGNED_SIZE(sizeof(zend_execute_data))))+(n))


diff --git a/Zend/zend_execute.h b/Zend/zend_execute.h
index a7af67bc13..ae71a5c73f 100644
--- a/Zend/zend_execute.h
+++ b/Zend/zend_execute.h
@@ -71,6 +71,15 @@ ZEND_API int zend_eval_stringl_ex(char *str, int str_len, zval *retval_ptr, char
 ZEND_API char * zend_verify_arg_class_kind(const zend_arg_info *cur_arg_info, ulong fetch_type, const char **class_name, zend_class_entry **pce TSRMLS_DC);
 ZEND_API int zend_verify_arg_error(int error_type, const zend_function *zf, zend_uint arg_num, const char *need_msg, const char *need_kind, const char *given_msg, const char *given_kind TSRMLS_DC);

+static zend_always_inline temp_variable *EX_TMP_VAR(void *ex, int n)
+{
+	return (temp_variable *)((zend_uintptr_t)ex + n);
+}
+static inline temp_variable *EX_TMP_VAR_NUM(void *ex, int n)
+{
+	return (temp_variable *)((zend_uintptr_t)ex - (1 + n) * sizeof(temp_variable));
+}
+
 static zend_always_inline void i_zval_ptr_dtor(zval *zval_ptr ZEND_FILE_LINE_DC TSRMLS_DC)
 {
 	if (!Z_DELREF_P(zval_ptr)) {

diff --git a/TSRM/threads.m4 b/TSRM/threads.m4
index 38494ce..90c106f 100644
--- a/TSRM/threads.m4
+++ b/TSRM/threads.m4
@@ -66,7 +66,7 @@ dnl
 dnl Check whether the current setup can use POSIX threads calls
 dnl
 AC_DEFUN([PTHREADS_CHECK_COMPILE], [
-AC_TRY_RUN( [
+AC_LINK_IFELSE([ AC_LANG_SOURCE([
 #include <pthread.h>
 #include <stddef.h>
 
@@ -80,18 +80,11 @@ int main() {
     int data = 1;
     pthread_mutexattr_init(&mattr);
     return pthread_create(&thd, NULL, thread_routine, &data);
-} ], [
+} ]) ], [
   pthreads_working=yes
   ], [
   pthreads_working=no
-  ], [
-  dnl For cross compiling running this test is of no use. NetWare supports pthreads
-  pthreads_working=no
-  case $host_alias in
-  *netware*)
-    pthreads_working=yes
-  esac
-]
+  ]
 ) ] )dnl
 dnl
 dnl PTHREADS_CHECK()
@@ -135,7 +128,6 @@ else
       fi
     done
   fi
-fi
 ])
 
 AC_CACHE_CHECK(for pthreads_lib, ac_cv_pthreads_lib,[
@@ -153,6 +145,7 @@ if test "$pthreads_working" != "yes"; then
   done
 fi
 ])
+fi
 
 if test "$pthreads_working" = "yes"; then
   threads_result="POSIX-Threads found"
