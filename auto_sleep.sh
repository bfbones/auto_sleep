#!/bin/bash                             
logger -i -t auto-suspend -- Starting System idle-detection
#CIDLE=$(TERM=vt100 top -n 1 | grep -i cpu\(s\) | gawk -F, '{print $4}' | sed 's/%.*//' | cut -d" " -f2 | cut -d"." -f1)
CIDLE=$(mpstat | grep -A 5 "%idle" | tail -n 1 | awk '{print $11}' | cut -d"," -f1)
LOAD=$(cat /proc/loadavg | cut -d"." -f1)
PROCESSLIST=( xbmc chromium )
USERCOUNT=$(who | grep -c "pts")
MASTERPC='10.10.1.10'
NETBOOK='10.10.1.35'
SUSPEND=1
SUSPENDIFILE='/root/suspendcount'
SUSPENDCOUNT=$(cat /root/suspendcount)
SL_FILE='/home/controluser/sleeplock'
LOCKFILE='/var/log/sleeplog'

for i in "${PROCESSLIST[@]}"
do
	if pgrep $i>/dev/null; then 
		logger -i -t auto-suspend -- proccess $i running
		SUSPEND=0
	fi
done

if [ "$LOAD" -ge 1 ]; then 
	logger -i -t auto-suspend -- load over 1
	SUSPEND=0
fi

if [ "$CIDLE" -le 95 ]; then
	SUSPEND=0
	logger -i -t auto-suspend -- CPU idle time less than 95%
fi

if [ "$USERCOUNT" -gt 0 ]; then
	SUSPEND=0
	logger -i -t auto-suspend -- SSH Users detected 
fi

ping -c1 -w1 -r $MASTERPC > /dev/null
if [ "$?" -lt 1 ]; then
	SUSPEND=0
	logger -i -t auto-suspend -- MasterPC powered on
fi

ping -c1 -w1 -r $NETBOOK > /dev/null
if [ "$?" -lt 1 ]; then
        SUSPEND=0
        logger -i -t auto-suspend -- Netbook powered on
fi

if [ -f $SL_FILE ]; then
	SUSPEND=0
	logger -i -t auto-suspend -- Sleeplock activated
fi

if [ $SUSPEND -eq 1 ]; then
	SUSPENDCOUNT=$((SUSPENDCOUNT + 1))
	#echo $SUSPENDCOUNT
	echo $SUSPENDCOUNT > $SUSPENDIFILE
	if [ $SUSPENDCOUNT -eq 3 ]; then
		SUSPENDCOUNT=0
		echo $SUSPENDCOUNT > $SUSPENDIFILE
		#echo "Server wurde in den Standby gefahren." | mail -r home@konradmallok.de -s "Server im Standby" zabbix@konradmallok.de
		echo "$(date +%c): Server suspended due to no system-usage." >> $LOCKFILE
		date "+%S" > suspendtime
		/bin/sh /usr/sbin/pm-suspend
		if [ "$(date +%S)" -le "$(cat suspendtime)" ]; then
			NOW=$(($(date +%S) + 60))
		else
			NOW=$(date +%S)
		fi
		DIFF=$((NOW - $(cat suspendtime)))
		if [ $DIFF -le 30 ]; then
			sleep 3
			/bin/sh /usr/sbin/pm-suspend
		fi
		echo "$(date +%c): Server back online." >> $LOCKFILE
		#logger -i -t auto-suspend -- Server suspended due to no system-usage
	else
		logger -i -t auto-suspend -- Server not suspended because system not in idle for 30 minutes
	fi
else
	logger -i -t auto-suspend -- Server not suspended because not in idle
	SUSPENDCOUNT=0
	echo $SUSPENDCOUNT > $SUSPENDIFILE
fi
