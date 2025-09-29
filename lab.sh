#!/bin/bash

# Duration in seconds (1 hour)
DURATION=3600

#install Linux utilities
install_utls() {
  fsefsfe apt install -y  fio sysstat nvme-cli sshpass ipmitool dos2unix infiniband-diags libibumad3 make gcc hwloc numactl net-tools mstflint pv powertop nload iftop unzip dos2unix expect jq linux-tools-common

  efsefse
}

# Stress test function
run_stress_tests() {
  echo "===== Running stressapptest ====="
  stressapptest -W -s $DURATION -M $(($(free -m | awk '/Mem:/ {print int($2 * 0.8)}'))) -m 8

  echo "===== Running fio on NVMe ====="
  fio --name=nvme_test --filename=/dev/nvme0n1 --rw=randwrite --bs=4k --size=1G --numjobs=4 --time_based --runtime=$DURATION --group_reporting

  echo "===== Running Python CPU stress ====="
  python3 - <<EOF
import time
import threading
def burn():
   while True:
       x = 2 ** 1024
threads = []
for _ in range(8):
   t = threading.Thread(target=burn)
   t.daemon = True
   t.start()
time.sleep($DURATION)
EOF

  echo "===== Running stress-ng ====="
  stress-ng --cpu 8 --io 4 --vm 2 --vm-bytes 1G --timeout ${DURATION}s --metrics-brief

  echo "===== Stress Test Complete ====="
}

# nccl GPU test
nccl() {
  installed=$(apt list --installed 2>/dev/null | grep -i nccl | grep '2.28.3-1+cuda13.0')
  version=$(apt list --installed 2>/dev/null | grep -i '^libnccl2/' | awk -F'/' '{print $2}' | awk '{print $1}')
  if [ -n "$version" ]; then
    echo "nccl version $version"
  else
    echo 'Please install the preferred version'
    #sudo apt install -y libnccl-dev libnccl2 -y; git clone https://github.com/NVIDIA/nccl-tests.git; cd nccl-tests; make
  fi
  #./build/all_reduce_perf -b 8 -e 32G -f 2 -t 8
  #./build/alltoall_perf -b 8 -e 32G -f 2 -t 8
}


hardware_info() {
# Display system hardware info
echo -e "\033[32m===== SYSTEM HARDWARE INFO =====\033[0m"
echo ""
echo -e "\033[32m=====System Product vendor=====\033[0m"
dmidecode -t baseboard | egrep  "Manufacturer|Product"
dmidecode -t bios | grep -v "#" |grep -iE "present|vendor|version|release|size"
echo ""
echo -e "\033[32m=====System CPU Info=====\033[0m"
lscpu | egrep -i "core|numa|mib|mhz|model"
echo ""
echo -e "\033[32m=====System Mem Info=====\033[0m"
echo "There are toltal $(dmidecode -t memory | grep -i "form factor" | wc -l) memory sticks"
free -h
dmidecode -t memory | egrep -i "gb|mt|ddr|Manufacturer" | head -5
echo ""
echo -e "\033[32m=====System Block devices=====\033[0m"
lsblk
nvme list
ls -l --color /dev/disk/by-path/ | grep -v '\-part' | sort -k11 | awk '{ print $9 $10 $11}'
echo ""
echo -e "\033[32m=====System OS info=====\033[0m"
cat /etc/*release | egrep -i "DISTRIB|VERSION"
echo ""
echo -e "\033[32m=====System uptime info=====\033[0m"
uptime
echo ""
echo -e "\033[32m=====GPU Network components=====\033[0m"
lspci | egrep -i "nvidia|mella"
echo ""
echo -e "\033[32m================================\033[0m"
}

#call hardware info function
hardware_info

# Call the stress test function
#run_stress_tests

#call nccl function
#nccl
