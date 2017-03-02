#!/bin/bash
#@author JonZhang jon.r.zhang@gmail.com
set -o xtrace
c=$(lscpu |awk '$1=="CPU(s):" {print $2}')
for (( i=0; i  < $c; ++i )); do
    cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor
    echo performance > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor
done;
grep -i mhz /proc/cpuinfo
