require "formula"

class Openlitespeed < Formula
    desc "OpenLiteSpeed is a high-performance, lightweight, open source HTTP server developed and copyrighted by LiteSpeed Technologies. Users are free to download, use, distribute, and modify OpenLiteSpeed and its source code in accordance with the precepts of the GPLv3 license."
    homepage "https://openlitespeed.org/"
    url "https://openlitespeed.org/packages/openlitespeed-1.4.38.tgz"
    sha256 "d6dd9d0a4ca96175d091306c900962e774ba409ea80ff60fe5a566e0e374dad1"
    head "https://github.com/litespeedtech/openlitespeed.git"
    version "1.4.38"

    option "with-luajit", "use liblua (located in directory DIR, if supplied) for compiling mod_lua module.  [default=no]"
    option "with-debug", "Enable debugging symbols (Debug is disabled by default)"

    option "without-http2", "Disable SPDY and http2 over HTTPS"

    bottle do
        root_url "https://dl.bintray.com/puleeno/openlitespeed"
        sha256 "2b65098675f5bdca74e7915a701235c80bce7aeed5c99c8f346d865e108ac831" => :high_sierra
    end

    depends_on "puleeno/openlitespeed/admin_php"
    depends_on "pcre"
    depends_on "expat"
    depends_on "openssl"
    depends_on "rcs"
    depends_on "libgeoip"
    depends_on "zlib"
    depends_on "udns"
    depends_on "luajit" => :optional

    def install
        # Disable PHP-Builtin
        cd  "dist" do
            inreplace "install.sh", "SETUP_PHP=1", "SETUP_PHP=0"
            inreplace "install.sh", "PHP_INSTALLED=n", "PHP_INSTALLED=y"
            inreplace "install.sh", "inst_admin_php\n", "echo \"Disable PHP-Builtin\"\n#inst_admin_php\n"
            inreplace "functions.sh", "SETUP_PHP=1", "SETUP_PHP=0"
        end

        # Configurations
        get_user = `USERS`
        args = %W[
            --prefix=#{prefix}
            --sysconfdir=#{etc}/#{name}
            --with-user=#{get_user}
            --with-group=admin

            --with-libdir=#{HOMEBREW_PREFIX}/lib
            --with-zlib=#{Formula["zlib"].opt_prefix}
            --with-openssl=#{Formula["openssl"].opt_prefix}
            --with-pcre=#{Formula["pcre"].opt_prefix}
            --with-udns=#{Formula["udns"].opt_prefix}
            --with-expat=#{Formula["expat"].opt_prefix}

            CPPFLAGS=-I#{HOMEBREW_PREFIX}/include
            LDFLAGS=-L#{HOMEBREW_PREFIX}/lib
        ]

        args << "--enable-http2=no" if build.without? "http2"
        args << "--with-lua=#{Formula["luajit"].opt_prefix}/include/luajit-2.0" if build.with? "luajit"
        args << "--enable-debug" if build.with? "debug"

        system "./configure", *args

        # Install
        system "make"
        system "make", "install"

        # Replace relative path by absolute path for Openlitespeed binary
        inreplace "#{bin}/lswsctrl.open", "$BASE_DIR/..", "#{prefix}"
        inreplace "#{bin}/lswsctrl.open", "$BASE_DIR\"/\"..", "#{prefix}"
        inreplace "#{bin}/lswsctrl.open", "\.\/", "#{bin}\/"
    end

    def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>#{plist_name}</string>
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
end
