#!/bin/bash
#default execute "./${bench_build} -i ./tests/inventory ./tests/test.yml

##################################################################################
# Const Variables, PATH
###################################################################################
export LANG=C
export LC_ALL=C
set -e
default_site='tests/test.yml'
default_inventory='tests/inventory'
default_remote_user='root'
default_extra_vars='ansible_sudo_pass=root'
SITE=${default_site}
DEBUG=''
bench_build=`filename ${0}`
bench_name=${bench_build%%\_*}
bench_home=${bench_name}_home
install_path=`grep -r ${bench_home} ./defaults/main.yml | awk '{print $2}'`
INVENTORY=${default_inventory}
REMOTE_USER=${default_remote_user}
EXTRA_VARS=${default_extra_vars}
curdir=$(cd `dirname $0`; pwd)
bench_path=${curdir##*/}
bench_role_git='ansible-role-hibench'
bench_role_galaxy='hubzhangxj.hibench'
###################################################################################
# Usage
###################################################################################
Usage()
{

cat << EOF
Usage: ./${bench_build} [options]
Options:
	-h, --help: Display help information
	-i INVENTORY, --inventory-file=INVENTORY
                        specify inventory host path
                        (default=/etc/ansible/hosts)
	-u REMOTE_USER, --user=REMOTE_USER
			connect as this user (default=None)
	-e EXTRA_VARS, --extra-vars=EXTRA_VARS
                        set additional variables as key=value or YAML/JSON
	-d, --debug     debug mode (-vvv for more, -vvvv to enable
                        connection debugging)
Example:
	./${bench_build}
	./${bench_build} --help
	./${bench_build} -i ../../hosts ../site.yml --debug
	./${bench_build} -i ../../hosts ../site.yml --debug --user=root --extra-vars "ansible_sudo_pass=root"
EOF
}

###################################################################################
# Get all args
###################################################################################

while test $# != 0
do
        case $1 in
		--*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ; ac_shift=: ;;
		-*) ac_option=$1 ; ac_optarg=$2; ac_shift=shift ;;
		*) ac_option=$1 ; ac_shift=: ;;
        esac

        case $ac_option in
                clean) CLEAN=yes ;;
                -h | --help) Usage ; exit 0 ;;
		-i | --inventory-file) INVENTORY=$ac_optarg ;;
                -u | --user) REMOTE_USER=$ac_optarg ;;
		-d | --debug) DEBUG="-vvvv" ;;
		-e | --extra-vars) EXTRA_VARS=$ac_optarg ;;
                #-a) if [ x"$ac_optarg" = x"China" ]; then DOWNLOAD_FTP_ADDR=$CHINA_INTERAL_FTP_ADDR; fi ;;
                *) Usage ; echo "Unknown option $1" ; exit 1 ;;
        esac

        $ac_shift
        shift
done

###################################################################################
# Benchmark tests/test.yml judge and replace according to directory's name
###################################################################################
benchmark_role()
{
    if  grep -r ${bench_path} ${default_site};then
        echo "${default_site} not necessary to replace of ${bench_path} "
	#sed -i '5s/hubzhangxj.hibench/ansible-role-hibench/'  ${default_site}
    elif [ "$bench_path" == "$bench_role_galaxy" ];then
	echo "${bench_role_galaxy} necessary to replace of ${bench_role_git} "
	sed -i '5s/ansible-role-hibench/hubzhangxj.hibench/'  ${default_site}
    elif [ "$bench_path" == "$bench_role_git" ];then
	echo "${bench_role_git} necessary to replace of ${bench_role_galaxy} "
	sed -i '5s/hubzhangxj.hibench/ansible-role-hibench/'  ${default_site}
    fi
}

###################################################################################
# Deployment benchmark
###################################################################################
benchmark_deploy()
{
    source /etc/profile
    ansible-playbook -i ${INVENTORY} ${SITE} ${DEBUG} --user=${REMOTE_USER} --extra-vars=${EXTRA_VARS}
    pushd ${install_path} > /dev/null
    ./bin/build-all.sh
    popd > /dev/null
}

if ! benchmark_role; then
	echo -e "\033[31mError! Benchmark role error!\033[0m" ; exit 1
fi

if ! benchmark_deploy; then
	echo -e "\033[31mError! Benchmark deploy failed!\033[0m" ; exit 1
fi
