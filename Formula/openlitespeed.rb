class Openlitespeed < Formula
    desc "OpenLiteSpeed is a high-performance, lightweight, open source HTTP server developed and copyrighted by LiteSpeed Technologies. Users are free to download, use, distribute, and modify OpenLiteSpeed and its source code in accordance with the precepts of the GPLv3 license."
    homepage "https://openlitespeed.org/"
    url "https://openlitespeed.org/packages/openlitespeed-1.4.51.src.tgz"
    sha256 "3fb8163666ca9ce396d857eb84385e4ba278abfbf522fdf004528670bb233185"

    head "https://github.com/litespeedtech/openlitespeed.git"
    version "1.4.51"

    bottle do
      root_url "https://ghcr.io/v2/puleeno/openlitespeed"
      rebuild 2
      sha256 cellar: :any, arm64_sonoma: "3bc4b3c05c0c38b2451ebf42631ec956090de15f08c70aaf9c40523e26d0b9a3"
    end

    option "with-luajit", "use liblua (located in directory DIR, if supplied) for compiling mod_lua module.  [default=no]"
    option "with-debug", "Enable debugging symbols (Debug is disabled by default)"

    option "without-http2", "Disable SPDY and http2 over HTTPS"

    depends_on "puleeno/openlitespeed/lsphp81"
    depends_on "pcre"
    depends_on "expat"
    depends_on "openssl"
    depends_on "rcs"

    depends_on "zlib"
    depends_on "puleeno/openlitespeed/udns"
    depends_on "sqlite"
    depends_on "luajit" => :optional

    patch :DATA

    def install
        # Disable PHP-Builtin
        cd  "dist" do
            inreplace "install.sh", "SETUP_PHP=1", "SETUP_PHP=0"
            inreplace "install.sh", "PHP_INSTALLED=n", "PHP_INSTALLED=y"
            inreplace "install.sh", "inst_admin_php\n", "echo \"Disable PHP-Builtin\"\n#inst_admin_php\n"
            inreplace "functions.sh", "SETUP_PHP=1", "SETUP_PHP=0"
        end

        # Use system OpenSSL instead of building bundled old version
        inreplace "configure", "usedynossl=no", "usedynossl=yes"
        inreplace "configure", ' -I../../ssl/include $CPPFLAGS', ' $CPPFLAGS'
        inreplace "configure", "echo \"Will build latest stable openssl libraries for you, this may take several minutes ...\"\n    OSSL=`. $srcdir/dlossl.sh`\n    echo \"Finsihed building openssl.\"", "echo \"Skipping bundled openssl build, using system openssl...\""

        # Remove old 32-bit linker flags that break Mach-O on arm64
        inreplace "configure", "-Wl,-export_dynamic -pagezero_size 10000 -image_base 100000000", "-Wl,-export_dynamic"

        # Disable PCRE JIT in the admin console PHP (lsphp81 8.1 bundles
        # PCRE 10.44 whose JIT segfaults on Apple Silicon during login)
        inreplace "dist/admin/conf/php.ini", "; Local Variables:", "pcre.jit = 0\n\n; Local Variables:"

        # The WebAdmin PHP code targets PHP 7.x and uses curly-brace offset
        # access (e.g. $var{0}) which was removed in PHP 8.0. Rewrite those
        # expressions to bracket syntax so the admin console runs on lsphp81.
        Dir["dist/admin/**/*.php"].each do |php|
          next unless File.binread(php).match?(/\$(\w+)\s*\{([^}]*)\}/)
          inreplace php, /\$(\w+)\s*\{([^}]*)\}/, '$\1[\2]'
        end

        # get_magic_quotes_gpc() was removed in PHP 8.0 (magic quotes are
        # gone, it always returns false), so drop the dead stripslashes call.
        inreplace "dist/admin/html.open/lib/DAttrBase.php",
                  "            if (get_magic_quotes_gpc()) {\n                $value = stripslashes($value);\n            }", ""

        # Configurations
        get_user = `USERS`
        args = %W[
            --prefix=#{prefix}
            --sysconfdir=#{etc}/#{name}
            --with-user=#{get_user}
            --with-group=admin

            --with-libdir=lib
            --with-zlib=#{Formula["zlib"].opt_prefix}
            --with-openssl=#{Formula["openssl"].opt_prefix}
            --with-pcre=#{Formula["pcre"].opt_prefix}
            --with-udns=#{Formula["udns"].opt_prefix}
            --with-expat=#{Formula["expat"].opt_prefix}

            CPPFLAGS=-I#{HOMEBREW_PREFIX}/include
            LDFLAGS=-L#{HOMEBREW_PREFIX}/lib
            --enable-iptogeo=no
        ]

        args << "--enable-http2=no" if build.without? "http2"
        args << "--with-lua=#{Formula["luajit"].opt_prefix}/include/luajit-2.0" if build.with? "luajit"
        args << "--enable-debug" if build.with? "debug"

        system "./configure", *args

        # Install
        system "make"
        system "make", "install"

        # Create Lsphp81 Symlink
        ln_sf "#{Formula["lsphp81"].bin}/lsphp", "#{prefix}/admin/fcgi-bin/admin_php"
        ln_sf "#{Formula["lsphp81"].bin}/lsphp", "#{prefix}/fcgi-bin/lsphp"
        ln_sf "#{Formula["lsphp81"].bin}/lsphp", "#{prefix}/fcgi-bin/lsphp5"

        # Replace relative path by absolute path for Openlitespeed binary
        inreplace "#{bin}/lswsctrl.open", "$BASE_DIR/..", "#{prefix}"
        inreplace "#{bin}/lswsctrl.open", "$BASE_DIR\"/\"..", "#{prefix}"
        inreplace "#{bin}/lswsctrl.open", "\.\/", "#{bin}\/"
        `echo "admin:#{`#{Formula["lsphp81"].bin}/lsphp -q #{prefix}/admin/misc/htpasswd.php 123456`}" > #{prefix}/admin/conf/htpasswd`
    end

    def post_install
        litespeed_dirs = %w[
            logs
            admin/logs
            admin/cgid
            admin/tmp
            Example/logs
        ]

        litespeed_dirs.each do |d|
            (prefix/d).mkpath
        end

        # Write launchd plist for brew services
        plist_path = prefix/"homebrew.mxcl.openlitespeed.plist"
        plist_path.unlink if plist_path.exist?
        plist_path.write <<~EOS
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
              <dict>
                  <key>Label</key>
                  <string>homebrew.mxcl.openlitespeed</string>
                  <key>ProgramArguments</key>
                  <array>
                      <string>#{opt_bin}/lswsctrl</string>
                      <string>start</string>
                  </array>
                  <key>RunAtLoad</key>
                  <true/>
                  <key>KeepAlive</key>
                  <false/>
                  <key>WorkingDirectory</key>
                  <string>#{prefix}</string>
              </dict>
          </plist>
        EOS
    end

    # Modern `brew services` requires a `service` block. The old `plist`
    # method is no longer recognized by brew services.
    service do
      run [opt_bin/"lswsctrl", "start"]
      keep_alive false
      working_dir opt_prefix
      run_at_load true
    end
end

__END__
--- a/include/lsr/ls_atomic.h
+++ b/include/lsr/ls_atomic.h
@@ -25,10 +25,9 @@
  * @file
  */
 
-#if defined(__aarch64__)
-#include <bits/types.h>
+#if defined(__aarch64__) && defined(__linux__)
+#include <stdint.h>
 #endif
-
 #define ls_atomic_inline ls_always_inline
 
 typedef volatile int32_t  ls_atom_32_t;
