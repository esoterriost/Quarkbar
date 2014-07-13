#!/bin/bash

set -e

. scripts/include.sh

export STAGING=$HOME/staging
mkdir -p $STAGING
cd $STAGING
unzip -o $OUTDIR/qt-win32-4.8.3-gitian-r4.zip
unzip -o $OUTDIR/boost-win32-1.54.0-gitian-r6.zip
unzip -o $OUTDIR/bitcoin-deps-win32-gitian-r9.zip
cd ~/deps
rm -rf quarkbar
git clone -b devel https://github.com/esoterriost/Quarkbar.git	# or just unpack a .tar archive
cd ~/deps/quarkbar
export PATH=$STAGING/host/bin:$PATH
ln -sf $STAGING $HOME/qt

# coin qt
$HOME/staging/host/bin/qmake -spec unsupported/win32-g++-cross MINIUPNPC_LIB_PATH=$STAGING/lib MINIUPNPC_INCLUDE_PATH=$STAGING/include BDB_LIB_PATH=$STAGING/lib BDB_INCLUDE_PATH=$STAGING/include BOOST_LIB_PATH=$STAGING/lib BOOST_INCLUDE_PATH=$STAGING/include BOOST_LIB_SUFFIX=-mt-s BOOST_THREAD_LIB_SUFFIX=_win32-mt-s OPENSSL_LIB_PATH=$STAGING/lib OPENSSL_INCLUDE_PATH=$STAGING/include QRENCODE_LIB_PATH=$STAGING/lib QRENCODE_INCLUDE_PATH=$STAGING/include USE_QRCODE=1 INCLUDEPATH=$STAGING/include DEFINES=BOOST_THREAD_USE_LIB BITCOIN_NEED_QT_PLUGINS=1 QMAKE_LRELEASE=lrelease QMAKE_CXXFLAGS=-frandom-seed=quarkbar USE_BUILD_INFO=1 USE_SSE2=1
make clean
make $MAKEOPTS
$HOST-strip release/*-qt.exe
rm -rf $OUTDIR/client
mkdir $OUTDIR/client
cp release/*-qt.exe $OUTDIR/client

# coind
cd src
make -f makefile.linux-mingw clean
echo "
--- a/makefile.linux-mingw      2014-04-02 11:32:16.471594423 +0300
+++ b/makefile.linux-mingw      2014-04-02 11:32:59.631051835 +0300
@@ -52,7 +52,7 @@
        DEFS += -DUSE_IPV6=$(USE_IPV6)
 endif
 
-LIBS += -l mingwthrd -l kernel32 -l user32 -l gdi32 -l comdlg32 -l winspool -l winmm -l shell32 -l comctl32 -l ole32 -l oleaut32 -l uuid -l rpcrt4 -l advapi32 -l ws2_32 -l mswsock -l shlwapi
+LIBS += -l mingwthrd -l kernel32 -l user32 -l gdi32 -l comdlg32 -l winspool -l winmm -l shell32 -l comctl32 -l ole32 -l oleaut32 -l uuid -l rpcrt4 -l advapi32 -l ws2_32 -l mswsock -l shlwapi -lz -lcrypt32 STAGING_HERE/lib/libevent.a STAGING_HERE/lib/libevent.dll.a -lws2_32
 
 # TODO: make the mingw builds smarter about dependencies, like the linux/osx builds are
 HEADERS = $(wildcard *.h) " | sed s2"STAGING_HERE"2"$(echo $STAGING)"2g | patch -l
make -f makefile.linux-mingw $MAKEOPTS DEPSDIR=$STAGING quarkbard.exe USE_UPNP=0 DEBUGFLAGS="-frandom-seed=quarkbar" USE_SSE2=1
$HOST-strip *.exe
rm -rf $OUTDIR/daemon
mkdir $OUTDIR/daemon
cp *.exe $OUTDIR/daemon

. ./nsis.sh