#!/bin/bash
   
NDK_VERSION="r25c"
NDK_DIR="$(pwd)/android-ndk-$NDK_VERSION"
NDK_URL="https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip"
   
echo -e "\e[1;32m RESOLVING NDK... \e[0m"
if [ ! -d "$NDK_DIR" ]; then
  echo -e "\e[1;35m DOWNLOADING NDK \e[0m"
 wget $NDK_URL -O android-ndk-${NDK_VERSION}.zip
 unzip android-ndk-${NDK_VERSION}.zip
fi
  
export ANDROID_NDK_HOME=$NDK_DIR
export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
  
echo -e "\e[1;32m SETTING ENVIRONMENT \e[0m"
  
cat << 'EOF' > setenv.sh
#!/bin/bash
  
# Setting the target architecture to ARM64 (Helio G90T)
export CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android30-clang
export CXX=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android30-clang++
export LD=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-ld
export AR=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar
export AS=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-as
export NM=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm
export RANLIB=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib  # Use llvm-ranlib

# Setting static linking and optimization flags for smaller binaries
export LDFLAGS="-static"
export CFLAGS="-Os -s"
  
EOF
  
chmod +x setenv.sh
source setenv.sh
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                               OPENSSL                                                   #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OPENSSL_VERSION='3.0.14'
OPENSSL_SRC="openssl-${OPENSSL_VERSION}.tar.gz"
OPENSSL_DOWNLOAD_URL="https://www.openssl.org/source/${OPENSSL_SRC}"
echo -e "\e[1;32m RESOLVING OPENSSL... \e[0m"
if [ -f "$OPENSSL_SRC" ] && [ ! -d "openssl-$OPENSSL_VERSION" ]; then
  echo -e "\e[1;35m EXTRACTING OPENSSL... \e[0m"
  tar -xzf "${OPENSSL_SRC}"
  elif [ ! -f "$OPENSSL_SRC" ] && [ ! -d "openssl-$OPENSSL_VERSION" ]; then
    echo -e "\e[1;35m DOWNLOADING AND EXTRACTING OPENSSL... \e[0m"
    wget "${OPENSSL_DOWNLOAD_URL}" -O "${OPENSSL_SRC}"
    tar -xzf "${OPENSSL_SRC}"
fi

if [ -f "$OPENSSL_SRC" ] && [ -d "openssl-$OPENSSL_VERSION" ]; then
  if [ ! -f "openssl-$OPENSSL_VERSION/down" ]; then
    cd openssl-$OPENSSL_VERSION

    export CXXFLAGS="-fPIC"
    export CPPFLAGS="-DANDROID -fPIC"

    echo -e "\e[1;32m CONFIGURING OPENSSL... \e[0m"
    ./Configure android-arm64 -D__ANDROID_API__=30 -static no-asm no-shared no-tests

    echo -e "\e[1;32m COMPILING OPENSSL... \e[0m"
    make
    touch down
    mkdir lib
    cp libcrypto.a lib/
    cp libssl.a lib/
    cd ..
  fi
  elif [ -f "openssl-$OPENSSL_VERSION/down" ]; then
    echo -e "\e[1;32m OPENSSL READY... \e[0m"
fi
export OPENSSL_DIR="$(pwd)/openssl-$OPENSSL_VERSION"
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                                 NMAP                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

NMAP_VERSION="7.95"
echo -e "\e[1;32m RESOLVING NMAP... \e[0m"
if [ -f "nmap-$NMAP_VERSION.tar.bz2" ] && [ ! -d "nmap-$NMAP_VERSION" ]; then
  echo -e "\e[1;35m EXTRACTING NMAP... \e[0m"
  tar -xjf nmap-$NMAP_VERSION.tar.bz2
  elif [ ! -f "nmap-$NMAP_VERSION.tar.bz2" ] && [ ! -d "nmap-$NMAP_VERSION" ]; then
    echo -e "\e[1;35m DOWNLOADING AND EXTRACTING NMAP... \e[0m"
    wget https://nmap.org/dist/nmap-$NMAP_VERSION.tar.bz2
    tar -xjf nmap-$NMAP_VERSION.tar.bz2
fi
 
SSH2_DIR="/home/$USER/nmap-integration-android/nmap-$NMAP_VERSION/libssh2/"

cd nmap-$NMAP_VERSION

echo -e "\e[1;32m CONFIGURING NMAP... \e[0m"
echo -e "\e[1;33m ADD\e[0m"
echo -e "\e[1;33m # define SUN_LEN(ptr) (offsetof (struct sockaddr_un, sun_path)		      \\ \e[0m"
echo -e "\e[1;33m 	      + strlen ((ptr)->sun_path)) \e[0m"
echo -e "\e[1;33m TO ncat/sockaddr_u.h BEFORE PROCEEDING\e[0m"

echo -e "\e[1;33m PRESS ANY KEY TO CONTINUE... \e[0m"
read a

./configure --host=aarch64-linux-android \
            --without-zenmap \
            --with-openssl="${OPENSSL_DIR}" \
            --with-libssh2=included \
            --with-libpcap=included \
            --with-liblinear=included \
            --with-libpcre=included \
            --with-liblua=included \

echo -e "\e[1;32m COMPILING RAW NMAP... \e[0m"
make STATIC='-static-libstdc++'

echo -e "\e[1;32m CONFIGURING RELEASE NMAP... \e[0m"
./configure --host=aarch64-linux-android \
            --without-zenmap \
            --with-openssl="${OPENSSL_DIR}" \
            --with-libssh2=included \
            --with-libpcap=included \
            --with-liblinear=included \
            --with-libpcre=included \
            --with-liblua=included \
            CFLAGS="-Os -s" \
            LDFLAGS="-s"

echo -e "\e[1;32m COMPILING RELEASE NMAP... \e[0m"
make STATIC='-static-libstdc++'

