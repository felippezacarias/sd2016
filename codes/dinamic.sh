#!/bin/bash

#No servidor não tem bc instalado, então tive que instalar localmente
PATH=$PATH:/home/user/felippe/bc-1.06/bin

OUTPUT="perf.txt"
ATTRIBUTES=6
ipc_ant=1
ttl=5
ttl_prob=0
FATOR=0.20
WATT_MIN=11
WATT_MAX=23
elapsed=0
STARTTIME=0

while [ 1 -lt 2 ]; do
     tail_cmd=$(tail -n $ATTRIBUTES $OUTPUT)
     cycles=$(echo "$tail_cmd" | grep cycles  | awk '{print $2}')
     cycles_array=($cycles)
     instructions=$(echo "$tail_cmd" | grep instructions | awk '{print $2}')
     instructions_array=($instructions)
     #cache=$(echo "$tail_cmd" | grep cache | awk '{print $2}')
     #cache_array=($cache)
     ipc=$(echo "scale=2; ${instructions_array[0]}/${cycles_array[0]}" | bc )
     if [ -z $ipc ]; then
	ipc=$ipc_ant
     fi
     
     if [ "$ttl_prob" -eq 1 ]; then
        if [ "$(echo "scale=20; ($ipc/$ipc_ant)-1 >= 0.20"  | bc)" -eq 1 ]; then
           ipc_ant=$ipc
        else
           echo "1.IPC medido $ipc / anterior $ipc_ant - 1 = ($(echo "scale=20; ($ipc/$ipc_ant)-1"  | bc)) >= 0.20  == $(echo "scale=20; ($ipc/$ipc_ant)-1 >= 0.20"  | bc)"
           power_gov -r POWER_LIMIT -s $WATT_MIN  -d PP0 -p 1    
	   ttl=10  
           STARTTIME=$(date +%s)  
        fi
	ttl_prob=0
     else
	if [ "$(echo $ipc '>' $ipc_ant | bc)" -eq 1 ] && [ "$(echo "$STARTTIME == 0" | bc)" -eq 1 ]; then
           ipc_ant=$ipc
        fi
     fi
   
     if [ "$(echo "scale=20; 1-($ipc/$ipc_ant) >= 0.20"  | bc)" -eq 1 ]; then
           echo "2.IPC 1 - medido $ipc / anterior $ipc_ant = ($(echo "scale=20; 1-($ipc/$ipc_ant)"  | bc)) >= 0.20 == $(echo "scale=20; 1-($ipc/$ipc_ant) >= 0.20"  | bc)"
           power_gov -r POWER_LIMIT -s $WATT_MIN  -d PP0 -p 1
           ipc_ant=$ipc
	   STARTTIME=$(date +%s) 	  
     fi

     if [ "$(echo "$STARTTIME > 0" | bc)" -eq 1 ]; then	
          ENDTIME=$(date +%s)
          elapsed=$(($ENDTIME - $STARTTIME))
     fi

     if [ "$(echo "$elapsed >= $ttl"  | bc)" -eq 1 ]; then
	  power_gov -r POWER_LIMIT -s $WATT_MAX  -d PP0 -p 1
          ttl_prob=1
	  STARTTIME=0
	  elapsed=0
     fi
 
done
