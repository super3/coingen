#!/bin/bash
# ARGS: name pow source(1/0) port branding256.png BTC magic customload rate initValue halfRate premine
set -e
cd /scratch/
rm -rf bitcoin binaries
git clone /scratch/git/bitcoin-cp bitcoin
cd bitcoin
git reset --hard origin/coingen_$2
if [ $3 = "0" ]; then
	git cherry-pick 1001e5a # NOSOURCE: setup.nsi
fi
git remote rm origin
git config gc.reflogexpire 0
git config gc.reflogexpireUnreachable 0
git gc --aggressive --prune=all
git config --unset gc.reflogexpire
git config --unset gc.reflogexpireUnreachable

cd share/pixmaps/
cp $5 ./bitcoin256.png
convert -resize 128x128 bitcoin256.png "$1"128.png
convert -resize 64x64 bitcoin256.png "$1"64.png
convert -resize 32x32 bitcoin256.png "$1"32.png
convert -resize 16x16 bitcoin256.png "$1"16.png
convert -resize 55x55 bitcoin256.png ../../doc/$1_logo_doxygen.png
rm ../../doc/bitcoin_logo_doxygen.png
convert -resize 300x300 -gravity Center -extent 164x314 bitcoin256.png nsis-wizard.bmp
convert -resize 57x57 -gravity Center -extent 150x57 ./bitcoin256.png nsis-header.bmp
cp bitcoin256.png ../../src/qt/res/icons/bitcoin.png
cp "$1"16.png ../../src/qt/res/icons/toolbar.png
mv bitcoin256.png "$1"256.png
cd ../qt
./make_windows_icon.sh
rm bitcoin-48.png bitcoin-32.png bitcoin-16.png
cd ../../src/qt/res/icons
rm bitcoin_testnet.png bitcoin_testnet.ico
cp bitcoin.png "$1"_testnet.png
cp bitcoin.ico "$1"_testnet.ico
mv bitcoin.png "$1".png
cp bitcoin.ico /scratch/bitcoin/share/pixmaps/"$1".ico
rm /scratch/bitcoin/share/pixmaps/bitcoin.ico
mv bitcoin.ico "$1".ico
cp toolbar.png toolbar_testnet.png
cd ../images
if [ "$8" = "1" ]; then
	convert -resize 400x400 -roll -130-110 -gravity SouthEast -chop 130x110 -gravity NorthWest -extent 480x320 ../../../../share/pixmaps/"$1"256.png splash_testnet.png
	cp splash_testnet.png splash.png
else
	cp /scratch/git/splash.png ./
	cp ./splash.png ./splash_testnet.png
fi
cd /scratch/bitcoin

git add share/pixmaps/*.png
git add share/pixmaps/*.ico
git add doc/*.png
git add src/qt/res/icons/*
git commit -a -m "Add $1 branding"

mv .git ../bitcoingit
find . -type f -print0 | xargs -0 sed -b "s/8333/$4/g" -i
find . -type f -print0 | xargs -0 sed -b "s/8332/`expr $4 - 1`/g" -i
mv ../bitcoingit .git
git commit -a -m "Change port numbers to $4/1$4/`expr $4 - 1`/1`expr $4 - 1`"

/scratch/git/brandname.sh $1 "${1^}" "coingen.io" "coingen/$1" $6
git commit -a -m "Change names"

MAGIC="0x${7:0:2}, 0x${7:2:2}, 0x${7:4:2}, 0x${7:6:2}"
sed "s/0xf9, 0xbe, 0xb4, 0xd9/$MAGIC/g" -i src/main.cpp
sed "s/486604799/0x$7/g" -i src/main.cpp
sed "s/1231006505/"`date +%s`"/g" -i src/main.cpp
git commit -a -m "Change network magic and genesis block"

if [ "${11}" != "210000" -o "${10}" != "50" -o "${9}" != "600"]; then
	sed "s/210000/${11}/g" -i src/main.cpp
	sed "s/nSubsidy = 50/nSubsidy = ${10}/g" -i src/main.cpp
	sed "s/600.0/$9.0/g" -i src/main.cpp
	MAXMONEY=`expr ${11} \* ${10} \* 2`
	sed "s/21000000/$MAXMONEY/g" -i src/main.h
	git commit -a -m "Change block rate/subsidy/block value"
fi

export PATH=$PATH:/scratch/bin/

/scratch/mingw/qt/bin/qmake -spec unsupported/win32-g++-cross MINIUPNPC_LIB_PATH=/scratch/mingw/miniupnpc/ MINIUPNPC_INCLUDE_PATH=/scratch/mingw/ BDB_LIB_PATH=/scratch/mingw/db-4.8.30.NC/build_unix/ BDB_INCLUDE_PATH=/scratch/mingw/db-4.8.30.NC/build_unix/ BOOST_LIB_PATH=/scratch/mingw/boost_1_51_0/stage/lib/ BOOST_INCLUDE_PATH=/scratch/mingw/boost_1_51_0/ BOOST_LIB_SUFFIX=-mt-s BOOST_THREAD_LIB_SUFFIX=_win32-mt-s OPENSSL_LIB_PATH=/scratch/mingw/openssl-1.0.1e OPENSSL_INCLUDE_PATH=/scratch/mingw/openssl-1.0.1e/include/ QRENCODE_LIB_PATH=/scratch/mingw/qrencode-3.4.3/.libs/ QRENCODE_INCLUDE_PATH=/scratch/mingw/qrencode-3.4.3/ USE_QRCODE=1 INCLUDEPATH=/scratch/mingw/ DEFINES=BOOST_THREAD_USE_LIB BITCOIN_NEED_QT_PLUGINS=1 QMAKE_LRELEASE=lrelease USE_BUILD_INFO=1 QMAKE_UIC=uic QMAKE_RCC=rcc QMAKE_MOC=moc
make -j2
mkdir -p /scratch/binaries/win32
i686-w64-mingw32-strip release/"$1"-qt.exe
cp release/"$1"-qt.exe /scratch/binaries/win32/

cd src
make -f makefile.linux-mingw DEPSDIR=/scratch/mingw/ "$1"d.exe USE_UPNP=0 -j2 "xLDFLAGS=-static-libgcc -static-libstdc++"
i686-w64-mingw32-strip "$1"d.exe
cp "$1"d.exe /scratch/binaries/win32/
cd ..

make clean
qmake RELEASE=1
sed 's/-march=x86-64/-m32/g' -i Makefile
sed 's/-m64/-m32/g' -i Makefile
make -j2
mkdir -p /scratch/binaries/linux
strip "$1"-qt
cp "$1"-qt /scratch/binaries/linux/

cd src
make -f makefile.unix clean
make -f makefile.unix STATIC=1 USE_UPNP=0 DEBUGFLAGS=-m32 -j2 CXXFLAGS=-m32
strip "$1"d
cp "$1"d /scratch/binaries/linux/

cd ..
git clean -f -x -d

mkdir -p nsis/src
if [ $3 = "1" ]; then
	git archive HEAD | tar -x -C nsis
	cd nsis
else
	cd nsis
	mkdir share
	cp ../share/setup.nsi ./share/
	mkdir share/pixmaps
	cp ../share/pixmaps/"$1".ico ./share/pixmaps/
	cp ../share/pixmaps/nsis-header.bmp ./share/pixmaps/
	cp ../share/pixmaps/nsis-wizard.bmp ./share/pixmaps/
fi
mkdir release
cp /scratch/binaries/win32/"$1"-qt.exe release/
cp /scratch/binaries/win32/"$1"d.exe src/
cd src
makensis ../share/setup.nsi

cd /scratch
mkdir $1
cd $1
cp /scratch/bitcoin/nsis/share/*.exe ./
if [ $3 = "1" ]; then
	mv ../bitcoin $1
	cd $1
	git reset --hard
	git clean -f -x -d
	cd ..
	tar -czf $1-src.tar.gz $1
	rm -rf $1
fi
mv /scratch/binaries ./
cd /scratch
zip --recurse-paths $1 $1
rm -r $1/
mv $1.zip /scratch/output/$7/
