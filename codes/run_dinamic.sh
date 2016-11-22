#!/bin/bash

SEQ="1 2 3 4 5"

for i in `echo $SEQ`
do
	power_gov -r POWER_LIMIT -s 23  -d PP0 -p 1

	perf stat -I 1000 -C 1,3,5,7 -e cycles,instructions,cache-misses,power/energy-ram/,power/energy-cores/,power/energy-pkg/ &> perf.txt &

	perf=$(echo $!)

	power_gov -e 1000 -p 1 >> gov.txt &

	gov=$(echo $!)

	nohup ./dinamic.sh &

	dinamic=$(echo $!)

	time GOMP_CPU_AFFINITY=1-7:2 ./heat.out 1000 500 250

	kill -9 $dinamic $perf $gov

	mv gov.txt gov_$i.txt
	mv perf.txt perf_$i.txt
	rm output.txt
done

