#!/bin/bash
#CURDIR=$(cd `dirname $0`; pwd)
pushd ../../ > /dev/null

ansible-playbook -i hosts hibench.yml  --user=root --extra-vars "ansible_sudo_pass=root" &

popd > /dev/null

pushd ../../../../opt/hibench

echo  "---------`pwd`---------"
./bin/build-all.sh

popd > /dev/null

