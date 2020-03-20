#!/bin/sh

_check_cmd () {

	command -v $1 >/dev/null 2>&1 && echo "1";
    
}

_init () {

	# Default configuration:

	NGINX_LOG_DIR="./logfiles"
	NGINX_ARCHIVED_LOG_DIR="./logfiles/oldlogs"
	DAILY=1

	SCRIPT_VERSION="0.0.3-beta"

	CONF_SCRIPT_DIR="nginxanalyzer";
	SCRIPT_DIR=$(dirname "$0")
	SCRIPT_NAME=$(basename "$0")
	LOCKDIR="$LOCKDIR_PREFIX/var/lock/${SCRIPT_NAME}_${USER}"
	PIDFILE="${LOCKDIR}/pid"

	if [ -f "$SCRIPT_DIR/nginxanalyzer.conf" ]; then
		. "$SCRIPT_DIR/nginxanalyzer.conf"
	fi
    
	if [ $(_check_cmd printf) ]; then
		PRINT="printf %s\n";
		PRINT_E="printf %b\n";
		PRINT_N="printf %s";
		PRINT_EN="printf %b";
	elif [ $(_check_cmd echo) ]; then
		PRINT="echo";
		PRINT_E="echo -e";
		PRINT_N="echo -n";
		PRINT_EN="echo -en";
	else
		exit 1;
	fi
    
}

_print () {

	if [ ! "$PRINT" ] || [ ! "$PRINT_E" ] || [ ! "$PRINT_N" ] || [ ! "$PRINT_EN" ]; then
		exit 1;
	fi

	if [ ! "$2" ]; then
		PRINT_ARG="$1";
	else
		PRINT_MOD="$1";
		PRINT_ARG="$2";
	fi

	case "$PRINT_MOD" in
		-e)
			$PRINT_E "$PRINT_ARG"
		;;
		-n)
			$PRINT_N "$PRINT_ARG"
		;;
		-en|-ne)
			$PRINT_EN "$PRINT_ARG"
		;;
		*)
			$PRINT "$PRINT_ARG"
		;;
	esac

}

_print_err () {
	_print "$@" >&2
}

_usage () {

	_print "Usage: $0 [-hymwdcD]"
	_print
	_print "Analyzes nginx logs with requests aggregation"
	_print "$SCRIPT_VERSION"
	_print
	_print "General options:"
	_print
	_print -e "\t-h\t\tThis usage help"
	_print -e "\t-y\t\tDisplay stats yearly"
	_print -e "\t-m\t\tDisplay stats monthly"
	_print -e "\t-w\t\tDisplay stats weekly"
	_print -e "\t-d\t\tTurn off daily stats display"
	_print -e "\t-c\t\tShow stats for current period instead of last one"
	_print -e "\t-D\t\tDeclutter output (Show only GET,POST,OTHER methods)"
	_print -e "\t-p <PATH>\t\tPath to nginx logs"
	_print -e "\t-P <PATH>\t\tPath to archived nginx logs"
	_print -e "\t-C\t\tUse calendar week (starting at Monday) instead of last 7 days"
	_print

}

_parse_options () {

	while getopts "hymwdcDp:P:C" opt
	do
		case "$opt" in
			h)
				_usage
				exit 0;
			;;
			y)
				YEARLY=1;
			;;
			m)
				MONTHLY=1;
			;;
			w)
				WEEKLY=1;
			;;
			d)
				DAILY=0;
			;;
			c)
				CURRENT=1;
			;;
			D)
				DECLUTTER=1;
			;;
			p)
				NGINX_LOG_DIR=$OPTARG;
			;;
			P)
				NGINX_ARCHIVED_LOG_DIR=$OPTARG;
			;;
			C)
				CALENDAR=1;
			;;
		esac
	done
    
}

_lock_set () {

	LOCK_NAME="$1";

	while ! mkdir $LOCKDIR_$LOCK_NAME 2>/dev/null; do
		LOCK_PID=$(cat $LOCKDIR_$LOCK_NAME/pid)
		[ -f $LOCKDIR_$LOCK_NAME/pid ] && ! kill -0 $LOCK_PID 2>/dev/null && rm -rf "$LOCKDIR_$LOCK_NAME"
	done

	echo $$ > $LOCKDIR_$LOCK_NAME/pid
	
	trap "rm -rf $LOCKDIR_$LOCK_NAME" QUIT INT TERM EXIT

}

_lock_remove () {

	LOCK_NAME="$1";

	rm -rf $LOCKDIR_$LOCK_NAME;

}

_xcat () {

	for f in $@; do
	    [ ! -z "$(file -i $f | grep "gzip")" ] && tar -xOf $f --wildcards "nginx_access*" || cat $f
	done

}

_main () {

    _xcat $NGINX_LOG_DIR/*.gz $NGINX_LOG_DIR/nginx_access* $NGINX_ARCHIVED_LOG_DIR/*.gz $NGINX_ARCHIVED_LOG_DIR/nginx_access* 2>/dev/null | awk -vYEARLY="$YEARLY" \
								-vMONTHLY="$MONTHLY" \
								-vWEEKLY="$WEEKLY" \
								-vDAILY="$DAILY" \
								-vDECLUTTER="$DECLUTTER" \
								-vCURRENT="$CURRENT" \
								-vCALENDAR="$CALENDAR" "
function floor(x) {

    return x - (x % 1);

}

function getMonthNum(monthStr){
    return 1 + (index(\"JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC\", toupper(monthStr)) - 1) / 3;
}

function sortAndPrint(inArr,	sorted,idx){
    asorti(inArr,sorted);
    for (idx in sorted){
        print inArr[sorted[idx]];
    }
    print \"--------------------\";
}

function countMethods(){
    if (DECLUTTER > 0) {
	for (idx2 in methods) {
	    if (idx2 != \"GET\" && idx2 != \"POST\"){
		methods[\"OTHER\"] += methods[idx2];
		delete methods[idx2];
	    }
	}
	sorted2[1] = \"GET\";
	sorted2[2] = \"POST\";
	sorted2[3] = \"OTHER\";
    } else {
	asorti(methods,sorted2);
    }
    tmpStr = \" (\";
    sum = 0;
    for (idx2 in sorted2){
	if (methods[sorted2[idx2]]){
	    sum += methods[sorted2[idx2]];
	    tmpStr = tmpStr methods[sorted2[idx2]] \" \" sorted2[idx2] \", \";
	}
    }
    tmpStr = \"\\t\" currResult \" - \" sum substr(tmpStr, 1, length(tmpStr)-2) \")\";
    output[currResult] = tmpStr;
    delete methods;
    return sum;
}

{
    # Extracting date-time field
    split(substr(\$4, 2), dateTimeArr, \":\");
    # Splitting to date and time parts
    split(dateTimeArr[1], dateArr, \"/\");
    
    # Extracting date parts
    day = dateArr[1];
    month = dateArr[2];
    # Calculating month num from Jan,Feb,Mar etc.
    monthNum = getMonthNum(month);
    year = dateArr[3];
    thisTimestamp = mktime(year\" \"monthNum\" \"day\" 00 00 00\");
    if (thisTimestamp > maxTimestamp) { maxTimestamp = thisTimestamp; }
    weekNum = strftime(\"%W\", thisTimestamp);
    
    # Extracting time parts
    hour = dateTimeArr[2];
    minute = dateTimeArr[3];
    second = dateTimeArr[4];

    if (!match(\$8, /^HTTP\\/1\.[01]\"/)){

	method = \"MALFORMED\"
	result = \"00x\";

    } else {

	# Extracting request method
	method = substr(\$6, 2);
	
	# Extracting result
	result = \$9;

    }

    yearFlag = 0;

    yearly[year,result,method]++;
    if (thisYear != year) {
	if (year > maxYear) {
	    prevYear = maxYear;
	    maxYear = year;
	    yearFlag = 1;
	}
	thisYear = year;
    }
    
    monthly[year,month,result,method]++;
    if (thisMonth != month) {
	if (yearFlag || getMonthNum(month) > getMonthNum(maxMonth)){
	    prevMonth = maxMonth;
	    maxMonth = month;
	}
	if (getMonthNum(month) == getMonthNum(maxMonth) - 1){
	    prevMonth = month;
	}
	thisMonth = month;
    }

    weekFlag = 0;

    weekly[year,weekNum,result,method]++;
    if (thisWeek != weekNum) {
	if (yearFlag || weekNum > maxWeek) {
	    if (maxWeek) {
		prevWeek = maxWeek;
	    } else {
		prevWeek = weekNum;
	    }
	    maxWeek = weekNum;
	    weekFlag = 1;
	}
	if (weekNum == maxWeek - 1){
	    prevWeek = weekNum;
	}
	thisWeek = weekNum;
    }
    
    daily[year,month,day,result,method]++;
    if (thisDay != day) {
	if (weekFlag || day > maxDay){
	    prevDay = maxDay;
	    maxDay = day;
	}
	if (day == maxDay - 1){
	    prevDay = day;
	}
	thisDay = day;
    }

    
}

END {

    if (!prevYear || CURRENT) { prevYear = maxYear; }
    if (!prevMonth || CURRENT) { prevMonth = maxMonth; }
    if (!prevWeek || CURRENT) { prevWeek = maxWeek; }
    if (!prevDay || CURRENT) { prevDay = maxDay; }

    delete output;
    delete methods;

    if (YEARLY) {
	asorti(yearly,sorted);

	for (idx in sorted){
	    split(sorted[idx], idxs, SUBSEP);
	    if (idxs[1] != currYear){
		if (length(output) > 0) {
		    output[\"Total\"] = \"\\tTotal - \" totalSum;
		    sortAndPrint(output);
		}
		currYear = idxs[1];
		totalSum = 0;
		print \"Yearly (\"currYear\")\";
		delete output;
		delete methods;

	    }
	    if (idxs[2] != currResult){
		if (length(methods) > 0){
		    totalSum += countMethods();
		}
		currResult = idxs[2];
	    }
	    methods[idxs[3]] = yearly[sorted[idx]];
	
	}

	totalSum += countMethods();
	output[\"Total\"] = \"\\tTotal - \" totalSum;
	sortAndPrint(output);
	delete output;
	delete methods;

    }

    if (MONTHLY) {
	asorti(monthly,sorted);
    
	for (idx in sorted){
	    split(sorted[idx], idxs, SUBSEP);
	    if (idxs[1] != currYear || idxs[2] != currMonth){
		if (length(output) > 0) {
		    output[\"Total\"] = \"\\tTotal - \" totalSum;
		    sortAndPrint(output);
		}
		currYear = idxs[1];
		currMonth = idxs[2];
		totalSum = 0;
		print \"Monthly (\"currMonth,currYear\")\";
		delete output;
		delete methods;
	    }
	    if (idxs[3] != currResult){
		if (length(methods) > 0){
		    totalSum += countMethods();
		}
		currResult = idxs[3];
	    }
	    methods[idxs[4]] = monthly[sorted[idx]];
	}

	totalSum += countMethods();
	output[\"Total\"] = \"\\tTotal - \" totalSum;
	sortAndPrint(output);
	delete output;
	delete methods;
    }

    if (WEEKLY) {
	asorti(weekly,sorted);
    
	for (idx in sorted){
	    split(sorted[idx], idxs, SUBSEP);
	    if (idxs[1] != currYear || idxs[2] != currWeek){
		if (length(output) > 0) {
		    output[\"Total\"] = \"\\tTotal - \" totalSum;
		    sortAndPrint(output);
		}
		currYear = idxs[1];
		currWeek = idxs[2];
		totalSum = 0;
		print \"Weekly (\"currWeek\" week of \"currYear\")\";
		delete output;
	    }
	    if (idxs[3] != currResult){
		if (length(methods) > 0){
		    totalSum += countMethods();
		}
		currResult = idxs[3];
	    }
	    methods[idxs[4]] = weekly[sorted[idx]];
	}

	totalSum += countMethods();
	output[\"Total\"] = \"\\tTotal - \" totalSum;
	sortAndPrint(output);
	delete output;
	delete methods;
    }

    if (DAILY) {
	asorti(daily,sorted);
    
	for (idx in sorted){
	    split(sorted[idx], idxs, SUBSEP);
	    monthNum = 1 + (index(\"JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC\", toupper(idxs[2])) - 1) / 3;
	    if (WEEKLY || MONTHLY || YEARLY ||
	    (CALENDAR && strftime(\"%W\", mktime(idxs[1]\" \"monthNum\" \"idxs[3]\" 00 00 00\")) == prevWeek && idxs[2] == maxMonth && idxs[1] == maxYear) ||
	    (!CALENDAR && maxTimestamp - mktime(idxs[1]\" \"monthNum\" \"idxs[3]\" 00 00 00\") < 604800)){
		if (MONTHLY || YEARLY || (idxs[2] == prevMonth && idxs[1] == maxYear)){
		    if (YEARLY || idxs[1] == prevYear){
			if (idxs[1] != currYear || idxs[2] != currMonth || idxs[3] != currDay){
			    if (length(output) > 0) {
				output[\"Total\"] = \"\\tTotal - \" totalSum;
				sortAndPrint(output);
			    }
			    currYear = idxs[1];
			    currMonth = idxs[2];
			    currDay = idxs[3];
			    totalSum = 0;
			    if (YEARLY || MONTHLY || WEEKLY) {
				print \"Daily (\"currDay,currMonth,currYear\")\";
			    } else {
				print strftime(\"%A\", mktime(idxs[1]\" \"monthNum\" \"idxs[3]\" 00 00 00\")),currDay,currMonth;
			    }
			    delete output;
			}
			if (idxs[4] != currResult){
			    if (length(methods) > 0){
				totalSum += countMethods();
			    }
			    currResult = idxs[4];
			}
			methods[idxs[5]] = daily[sorted[idx]];
		    }
		}
	    }
	}

	totalSum += countMethods();
	output[\"Total\"] = \"\\tTotal - \" totalSum;
	sortAndPrint(output);
    }

}"

}

_init
_parse_options "$@"
shift $((OPTIND-1));
_main
