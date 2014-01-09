#!/bin/sh
rm bitcoin.tar.gz
pushd bitcoin
git checkout coingen_scrypt
git rebase -i coingen_base
git checkout coingen_sha256
git rebase -i coingen_base
git checkout master
cd ..
tar -czf bitcoin.tar.gz bitcoin
cd bitcoin
git checkout coingen_base
popd
