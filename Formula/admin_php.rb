class AdminPhp < Formula
    homepage "https://secure.php.net"
    url "https://secure.php.net/get/php-7.2.10.tar.xz/from/this/mirror"
    sha256 "01c2154a3a8e3c0818acbdbc1a956832c828a0380ce6d1d14fea495ea21804f0"

    bottle do
        root_url "https://dl.bintray.com/puleeno/openlitespeed"
        sha256 "91ea63454527ebfd0ec84192733f69e2640e938b5b6a8d195b8013424c78365e" => :high_sierra
    end

    depends_on "expat"

    ## Resources
    resource "additional_files" do
        url "https://www.litespeedtech.com/packages/lsapi/php-litespeed-7.1.tgz"
        sha256 "540209b98139c1613f4bb5331d96ced01f53b97aa5f5fc11c03804c447ef27ab"
      end

    def install
        config_path = etc/"lsphp/admin/#{php_version}"

        # Required due to icu4c dependency
        ENV.cxx11

        args = %W[
            --prefix=#{prefix}
            --disable-all
            --with-litespeed
            --enable-zip
            --with-libzip
            --with-bz2
            --enable-xml
            --enable-json
            --enable-sockets
            --enable-session
            --enable-posix
            --with-zlib
            --enable-bcmath
            --with-libexpat-dir=#{Formula["expat"].opt_prefix}
        ]
        

        system "./configure", *args
        system "make"
        system "make", "install"
    end

    def php_version
        version.to_s.split(".")[0..1].join(".")
    end
end
