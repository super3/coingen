#!/bin/sh
#args testcoin Testcoin website github(coingen/testcoin) TST
set -e
mv .git ../bitcoingit

# General replaces
find . -type f -print0 | xargs -0 sed -b "s/BTC/$5/g" -i
mv README.md ../
find . -type f -print0 | xargs -0 sed -b "s|github.com/bitcoin/bitcoin|github.com/$4|g" -i
mv ../README.md ./

find . -type f -print0 | xargs -0 sed -b "s/bitcoin.org/$3/g" -i
find . -type f -print0 | xargs -0 sed -b "s/bitcoin.conf/"$1".conf/g" -i

mv README.md README-btc.md
cat README-btc.md | grep -B1000 "Development process" > README2.md
cat README2.md | head -n $(expr `wc -l README2.md | awk '{ print $1 }'` - 1) > README.md
rm README2.md

for FILE in .gitignore README.md INSTALL share/setup.nsi share/qt/make_windows_icon.sh src/qt/res/bitcoin-qt.rc src/qt/locale/* `find ./contrib/gitian-descriptors -type f` `find ./contrib/gitian-downloader -type f`; do
	sed -b "s/bitcoin/$1/g" -i $FILE
	sed -b "s/Bitcoin/$2/g" -i $FILE
done

sed -b "s/(c) 2009-2013 $2/(c) 2009-2013 Bitcoin/g" -i README.md
echo "$2 is based on Bitcoin." >> README.md
echo "Its development tracks Bitcoin's, the following information applies to Bitcoin's developemnt." >> README.md
cat README-btc.md | grep -A1000 "Development process" >> README.md
rm README-btc.md

sed -b "s/TARGET = bitcoin/TARGET = $1/g" -i bitcoin-qt.pro

find . -type f -print0 | xargs -0 sed -b "s/Bitcoin-Qt/$2-Qt/g" -i

for FILE in ./src/makefile.*; do
	find . -type f -print0 | xargs -0 sed -b "s/bitcoind.exe/"$1"d.exe/g" -i $FILE
	find . -type f -print0 | xargs -0 sed -b "s/test_bitcoin.exe/test_"$1".exe/g" -i $FILE
	find . -type f -print0 | xargs -0 sed -b "s/bitcoin-qt.exe/"$1"-qt.exe/g" -i $FILE
	find . -type f -print0 | xargs -0 sed -b "s/test_bitcoin/test_"$1"/g" -i $FILE
	find . -type f -print0 | xargs -0 sed -b "s/bitcoind/"$1"d/g" -i $FILE
done

sed "s/bitcoin.png/$1.png/g" -i src/qt/bitcoin.qrc
sed "s/bitcoin_testnet.png/$1_testnet.png/g" -i src/qt/bitcoin.qrc

for FILE in src/*.cpp src/*.h src/*/*.cpp src/*/*.h; do
	if [ "$FILE" = "src/qt/transactiondesc.cpp" ]; then
		continue
	fi
	sed -b '/^[^#include]/ s/"\(.*\)bitcoin\(.*\)"/"\1'$1'\2"/g' -i $FILE
	sed -b '/^[^#include]/ s/"\(.*\)Bitcoin\(.*\)"/"\1'$2'\2"/g' -i $FILE
	ALLCAPS=`echo $2 | tr '[:lower:]' '[:upper:]'`
	sed -b '/^[^#include]/ s/"\(.*\)BITCOIN\(.*\)"/"\1'$ALLCAPS'\2"/g' -i $FILE
done

rm doc/release-process.md
echo "To get an updated client, go to http://coingen.io" > doc/release-process.md

mv ../bitcoingit ./.git
