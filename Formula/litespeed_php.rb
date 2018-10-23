class LitespeedPhp < Formular 
    homepage "https://secure.php.net"
    url "https://secure.php.net/get/php-7.2.10.tar.xz/from/this/mirror"
    sha256 "01c2154a3a8e3c0818acbdbc1a956832c828a0380ce6d1d14fea495ea21804f0"

    option "with-npm", "Install PHP-FPM"
    option "with-default", "Install php as default lsphp for Openlitespeed"

    bottle do
        root_url "https://dl.bintray.com/puleeno/openlitespeed"
        sha256 "91ea63454527ebfd0ec84192733f69e2640e938b5b6a8d195b8013424c78365e" => :high_sierra
    end

    depends_on "puleeno/openlitespeed/litespeed_php"

    def install
    end
end