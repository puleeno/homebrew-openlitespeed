class OpenlitespeedAT19 < Formula
  desc "High-performance open source HTTP server by LiteSpeed Technologies"
  homepage "https://openlitespeed.org/"
  url "https://github.com/litespeedtech/openlitespeed/archive/refs/tags/v1.9.1.tar.gz"
  sha256 "ef262323276a2435c1d8e52c2e1a88fb038e65d3fa891fbfeccc8e9a65991384"

  head "https://github.com/litespeedtech/openlitespeed.git"

  bottle do
    root_url "https://github.com/puleeno/homebrew-openlitespeed/releases/download/1.9.1-RC1"
    sha256 cellar: :any, arm64_sonoma: "4d0d53a539b5bec85c6784475dd8a0cfbdb90011fa4309691c877fbab9bc1179"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "cmake" => :build
  depends_on "libtool" => :build
  depends_on "expat"
  depends_on "pcre2"
  depends_on "puleeno/openlitespeed/udns"
  depends_on "zlib"

  # OpenLiteSpeed ships src/liblsquic and src/lshpack as git submodules
  # that are empty in the release tarball. Pin the exact commits OLS 1.9.1
  # expects (LSQUICCOMMIT and the lsquic submodule tree).
  resource "lsquic" do
    url "https://github.com/litespeedtech/lsquic/archive/f8ebaf838d2f4db836bda1182ee35b05d5191cee.tar.gz"
    sha256 "b1f850f7ec342e47d297369bfa0e34bd99cf4e309f5a3644212da61b923a24d5"
  end

  resource "lshpack" do
    url "https://github.com/litespeedtech/ls-hpack/archive/cf0f70dd10b352194c97448eb5d00b4aa484f531.tar.gz"
    sha256 "b138d8fc71e5f7f353b5784942cf08ad57050d7b321121f095627f696757f9f8"
  end

  resource "ls-qpack" do
    url "https://github.com/litespeedtech/ls-qpack/archive/475dfa8064fc6ef80035541405b22965cfbd7244.tar.gz"
    sha256 "9e4f6fc49ecf48af00034876b7a4e0aa7b5338ac6a12b82c705e00a46b3bd4fb"
  end

  # BoringSSL provides the QUIC/TLS 1.3 API OpenLiteSpeed needs. Pin the
  # commit and add the LiteSpeed LSTLS API shims.
  resource "boringssl" do
    url "https://github.com/google/boringssl/archive/9fc1c33e9c21439ce5f87855a6591a9324e569fd.tar.gz"
    sha256 "3e2a15d002634e4cfd44a74be286ed99c8ed138118479181a3099e16913e3942"
  end

  # Brotli is compiled statically into an out/ dir that OLS configure expects.
  resource "brotli" do
    url "https://github.com/google/brotli/archive/refs/heads/master.tar.gz"
    sha256 "f9f59444d95cea49c490e7d59ac0e8c9d27feff252349c901e9e27f3a9e0a578"
  end

  # LiteSpeed's bcrypt wrapper (see third-party/script/build_bcrypt.sh).
  resource "libbcrypt" do
    url "https://github.com/litespeedtech/libbcrypt/archive/55ff64349dec3012cfbbb1c4f92d4dbd46920213.tar.gz"
    sha256 "ebe28e4791f5ad778b95ad7c3edff158bcc476d07d1503dd82fec1fad2a47f88"
  end

  patch do
    file "patches/ols191-macos.patch"
  end

  def install
    # ---- BoringSSL: build once, then lay out into ssl/ like dlbssl.sh ----
    bssl_dir = buildpath/"boringssl-src"
    resource("boringssl").stage bssl_dir
    cd bssl_dir do
      # Apply LiteSpeed LSTLS API shims required by OLS's lsquic
      system "patch", "-p1", "-i", "#{Pathname(__dir__).parent}/patches/bssl-lstls.patch"
      mkdir "build" do
        system "cmake", "..", "-DCMAKE_BUILD_TYPE=RelWithDebInfo",
               "-DCMAKE_C_FLAGS=-fPIC", "-DCMAKE_CXX_FLAGS=-fPIC"
        system "make", "-j#{ENV.make_jobs}"
      end
      # Populate buildpath/ssl per dlbssl.sh layout (headers + static libs)
      ssl = buildpath/"ssl"
      ssl.mkpath
      cp_r "include", ssl
      cp "build/crypto/libcrypto.a", ssl
      cp "build/ssl/libssl.a", ssl
      cp "build/decrepit/libdecrepit.a", ssl
    end

    # ---- Brotli: static libs into brotli-master/out ----
    brotli_dir = buildpath/"brotli-master"
    resource("brotli").stage brotli_dir
    cd brotli_dir do
      mkdir "out" do
        system "cmake", "..", "-DCMAKE_BUILD_TYPE=Release",
               "-DBROTLI_BUILD_FOR_PACKAGE=ON"
        system "make", "-j#{ENV.make_jobs}"
      end
    end

    # ---- Populate empty git submodules in the OLS source ----
    resource("lsquic").stage do
      # lsquic/src/liblsquic -> OLS src/liblsquic
      rm_r buildpath/"src/liblsquic", force: true
      cp_r "src/liblsquic/.", buildpath/"src/liblsquic"
      # ls-qpack submodule -> OLS src/liblsquic/ls-qpack
      resource("ls-qpack").stage do
        rm_r buildpath/"src/liblsquic/ls-qpack", force: true
        cp_r "./.", buildpath/"src/liblsquic/ls-qpack"
      end
      # lsquic/include -> OLS include (replaces broken symlinks to
      # the empty top-level lsquic/ submodule)
      rm_r buildpath/"include/lsquic.h", force: true
      cp_r "include/lsquic.h", buildpath/"include/lsquic.h"
      rm_r buildpath/"include/lsquic_types.h", force: true
      cp_r "include/lsquic_types.h", buildpath/"include/lsquic_types.h"
    end
    resource("lshpack").stage do
      rm_r buildpath/"src/lshpack", force: true
      cp_r "./.", buildpath/"src/lshpack"
    end

    # ---- bcrypt (third-party/lib/libbcrypt.a + include/bcrypt.h) ----
    resource("libbcrypt").stage do
      system "make"
      (buildpath/"third-party").mkpath
      (buildpath/"third-party/lib").mkpath
      cp "bcrypt.a", buildpath/"third-party/lib/libbcrypt.a"
      cp "bcrypt.h", buildpath/"include/bcrypt.h"
    end

    # ---- Apply the liblsquic include-path fix after populating source ----
    system "patch", "-p1", "-i", "#{Pathname(__dir__).parent}/patches/liblsquic-macos.patch"

    # ---- Drop the cache module (segfaults at startup on macOS) ----
    inreplace "dist/conf/httpd_config.conf.in",
              /module cache \{\n.*?\n\}/m, ""

    # ---- Disable QUIC by default (shm init crashes on macOS) ----
    inreplace "dist/conf/httpd_config.conf.in",
              /quicEnable\s+1/, "quicEnable                    0"

    # ---- Regenerate autotools files (config.sub/config.guess absent) ----
    system "autoreconf", "--install", "--force"

    # ---- Configurations ----
    get_user = `id -un`.strip
    args = %W[
      --prefix=#{prefix}
      --sysconfdir=#{etc}/openlitespeed@1.9
      --with-user=#{get_user}
      --with-group=admin
      --with-adminport=7081
      --with-exampleport=8089
      --with-libdir=lib
      --with-openssl=#{buildpath}/ssl
      --with-brotli=#{brotli_dir}
      --with-udns=#{formula_opt_prefix("udns")}
      --with-pcre=#{formula_opt_prefix("pcre2")}
      --with-expat=#{formula_opt_prefix("expat")}
      --with-zlib=#{formula_opt_prefix("zlib")}
      --without-lsphp7
      CPPFLAGS=-I#{HOMEBREW_PREFIX}/include
      LDFLAGS=-L#{HOMEBREW_PREFIX}/lib
    ]

    system "./configure", *args

    # Install
    system "make", "-j#{ENV.make_jobs}"
    system "make", "install"

    # Replace relative path by absolute path for Openlitespeed binary
    inreplace bin/"lswsctrl.open", "$BASE_DIR/..", prefix.to_s
    inreplace bin/"lswsctrl.open", "$BASE_DIR\"/\"..", prefix.to_s
    inreplace bin/"lswsctrl.open", "./", "#{bin}/"
  end

  def post_install
    litespeed_dirs = %w[
      logs
      admin/logs
      admin/cgid
      admin/tmp
      cgid
      Example/logs
    ]

    litespeed_dirs.each do |d|
      (prefix/d).mkpath
    end

    # dist/install.sh (via the Makefile install-data-hook) writes
    # bin/lsws_env at the end of `make install`; restore the exec bit.
    chmod "+x", bin/"lsws_env"
  end

  test do
    assert_match "LiteSpeed/", shell_output("#{bin}/openlitespeed -v 2>&1")
  end
end
