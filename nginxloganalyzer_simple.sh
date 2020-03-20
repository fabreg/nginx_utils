#!/bin/bash
#
# Analyze nginx logs.
# This script show various return code of the last week.
# NOTE: nginx.tar.*.gz files are in binary format, for that reason zgrep command has been used.


LOGFILES="logfiles/nginx_access.log"
LOGFILESZIP="logfiles/oldlogs/nginx.tar.*.gz"

cat <<INFO

File Name: 	$LOGFILES
File Size: 	$(ls -lh $LOGFILES | awk '{print $5}' )
Status:		Calclulating...
	
INFO

cat $LOGFILES \
	| awk '{print $4}' \
	| sed 's/\[//g' \
	| sed 's/:.*//g' \
	| sort -u \
		| while read days; do 
			data="$(grep -a "$days" $LOGFILES)"
			d=$(echo $days | sed 's/\//-/g')
			dayName=$(date -d "$d" +%A)
			echo -e "\n$dayName -> $days\n-----------------------"
			nm=$(echo $days | sed 's/\//_/g')
			echo "$data" \
				| awk '{ count=0;if ($9 == 200) { count++; if($6 == "\"GET" || $6 == "\"POST" || $6 == "\"PUT" ) { print $9"\t"$6 } print count } else { print $9 }}' > ${nm}.tmp
			cat ${nm}.tmp \
				| sort -n \
				| uniq -c
		done 2> /dev/null \
			| sed -r '/\s[0-9]{1,} [^0-9]/d' \
			| sed 's/"//g' \
			| sed -r '/-----------------------/{n;s/[0-9]{1,}/TOTAL 200OK: &/};s/ 1$//'
rm *.tmp

echo
echo
echo
echo

ls $LOGFILESZIP | while read archive; do
	size=$(ls -lh $archive | awk '{print $5}')
	cat<<-INFO

	Archive Name:	$archive
	Archive Size:	$size
	Status:		Calclulating...
	
	INFO

	zgrep -a . $archive \
		| grep -a -E '[0-9]{1,2}/[A-Z]{1}[a-z]{2}/[0-9]{4}' \
		| awk '{print $4}' \
		| sed 's/\[//g' \
		| sed 's/:.*//g' \
		| sort -u \
		| grep -a -E '[0-9]{1,2}/[A-Z]{1}[a-z]{2}/[0-9]{4}' \
			| while read days; do
				data="$(zgrep -a "$days" $archive)"
				d=$(echo $days | sed 's/\//-/g')
				dayName=$(date -d "$d" +%A)

				echo -e "\n$dayName -> $days\n-----------------------"

				nm=$(echo $days | sed 's/\//_/g')
				echo "$data" \
					| awk '{ count=0;if ($9 == 200) { count++; if($6 == "\"GET" || $6 == "\"POST" || $6 == "\"PUT" ) { print $9"\t"$6 } print count } else { print $9 }}' > ${nm}.tmp
				cat ${nm}.tmp \
					| sort -n \
					| uniq -c
			done 2> /dev/null \
				| sed -r '/\s[0-9]{1,} [^0-9]/d' \
				| sed 's/"//g' \
				| sed -r '/-----------------------/{n;s/[0-9]{1,}/TOTAL 200OK: &/};s/ 1$//'
done
rm *.tmp
