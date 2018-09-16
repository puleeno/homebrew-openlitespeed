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

    depends_on "pcre"
    depends_on "expat"
    depends_on "openssl"
    depends_on "rcs"
    depends_on "libgeoip"
    depends_on "zlib"
    depends_on "udns"
    depends_on "luajit" => :optional

    def install
        # Configurations
        get_user = `USERS`
        args = %W[
            --prefix=#{prefix}
            --sysconfdir=#{etc}/#{name}
            --with-openssl=#{Formula["openssl"].opt_prefix}
            --with-user=#{get_user}
            --with-group=staff
            CPPFLAGS=-I#{HOMEBREW_PREFIX}/include
            LDFLAGS=-L#{HOMEBREW_PREFIX}/lib
        ]

        args << "--enable-http2=no" if build.without? "http2"
        args << "--with-lua=#{Formula["luajit"].opt_prefix}/include/luajit-2.0" if build.with? "luajit"
        args << "--enable-debug" if build.with? "debug"

        # Create logs folder
        unless (prefix/"logs").exist?
            (prefix/"logs").mkpath
        end
        unless (prefix/"admin/logs").exist?
            (prefix/"admin/logs").mkpath
        end
        unless (prefix/"Example/logs").exist?
            (prefix/"Example/logs").mkpath
        end

        # Create admin cgid directory
        unless (prefix/"admin/cgid").exist?
            (prefix/"admin/cgid").mkpath
        end

        # Create admin tmp directories
        unless (prefix/"admin/tmp").exist?
            (prefix/"admin/tmp").mkpath
        end

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