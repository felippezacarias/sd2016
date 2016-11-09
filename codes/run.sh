#!/bin/sh

result_heat="heat"
result_heat_limit="heat_limit"

mkdir $result_heat
for i in {1..5}
do
 echo "Executando heat rodada $i"
 power_gov -e 1000 >> $result_heat/gov_$i.txt &
 power=$(echo $!)
 perf stat -I 1000 -C 1,3,5,7  -e cycles,instructions,cache-misses,power/energy-ram/,power/energy-cores/,power/energy-pkg/ &> $result_heat/perf_$i.txt &
 perf=$(echo $!)
 time GOMP_CPU_AFFINITY=1-7:2 ./heat.out 1000 500 250 | tee -a $result_heat/res_heat.txt
 kill -9 $power $perf
done

mkdir $result_heat_limit
for i in {1..5}
do
  echo "Executando heat com limite rodada $i"
  power_gov -e 1000 >> $result_heat_limit/gov_$i.txt &
  power=$(echo $!)
  perf stat -I 1000 -C 1,3,5,7  -e cycles,instructions,cache-misses,power/energy-ram/,power/energy-cores/,power/energy-pkg/ &>  $result_heat_limit/perf_$i.txt &
  perf=$(echo $!)
  time GOMP_CPU_AFFINITY=1-7:2 ./heat_limit.out 1000 500 250 | tee -a $result_heat_limit/res_heat_limit.txt
  kill -9 $power $perf
done
