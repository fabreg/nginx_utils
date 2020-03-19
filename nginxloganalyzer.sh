#!/bin/sh

_check_cmd () {

	command -v $1 >/dev/null 2>&1 && echo "1";
    
}

_init () {

	# Default configuration:

	NGINX_LOG_FILE="./nginx2.log"

	SCRIPT_VERSION="0.0.1-alpha"

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

	_print "Usage: $0 [-h]"
	_print
	_print "Analyzes nginx logs with requests aggregation"
	_print "$SCRIPT_VERSION"
	_print
	_print "General options:"
	_print
	_print -e "\t-h\tThis usage help"
	_print

}

_parse_options () {

	while getopts "h" opt
	do
		case "$opt" in
			h)
				_usage
				exit 0;
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

_main () {

    awk "
function sortAndPrint(inArr,	sorted,idx){
    asorti(inArr,sorted);
    for (idx in sorted){
        print inArr[sorted[idx]];
    }
}

function cleanup(){
    delete currDay;
    delete currWeek;
    delete currMonth;
    delete currYear;
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
    monthNum = 1 + (index(\"JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC\", toupper(month)) - 1) / 3;
    year = dateArr[3];
    weekNum = strftime(\"%W\", mktime(year\" \"monthNum\" \"day\" 00 00 00\"))
    
    # Extracting time parts
    hour = dateTimeArr[2];
    minute = dateTimeArr[3];
    second = dateTimeArr[4];
    
    # Extracting request method
    method = substr(\$6, 2);
    
    # Extracting result
    result = \$9;
    
    yearly[year,result]++;
    lastYear = year;
    
    monthly[year,month,result]++;
    lastMonth = month;
    
    weekly[year,weekNum,result]++;
    lastWeek = weekNum;
    
    daily[year,month,day,result]++;
    lastDay = day;
    
}
END {

    delete output;

    asorti(yearly,sorted);

    for (idx in sorted){
	split(sorted[idx], idxs, SUBSEP);
	if (idxs[1] != currYear){
	    if (length(output) > 0) {
		sortAndPrint(output);
	    }
	    currYear = idxs[1];
	    print \"Yearly (\"currYear\")\";
	    delete output;

	}
	#print \"\\t\"idxs[2]\" : \"yearly[idx];
	output[idxs[2]] = \"\\t\"idxs[2]\" : \"yearly[sorted[idx]];
    }

    sortAndPrint(output);
    delete output;

    asorti(monthly,sorted);
    
    for (idx in sorted){
	split(sorted[idx], idxs, SUBSEP);
	if (idxs[1] != currYear || idxs[2] != currMonth){
	    if (length(output) > 0) {
		sortAndPrint(output);
	    }
	    currYear = idxs[1];
	    currMonth = idxs[2];
	    print \"Monthly (\"currMonth,currYear\")\";
	    delete output;
	}
	#print \"\\t\"idxs[3]\" : \"monthly[idx];
	output[idxs[3]] = \"\\t\"idxs[3]\" : \"monthly[sorted[idx]];
    }

    sortAndPrint(output);
    delete output;

    asorti(weekly,sorted);
    
    for (idx in sorted){
	split(sorted[idx], idxs, SUBSEP);
	if (idxs[1] != currYear || idxs[2] != currWeek){
	    if (length(output) > 0) {
		sortAndPrint(output);
	    }
	    currYear = idxs[1];
	    currWeek = idxs[2];
	    print \"Weekly (\"currWeek\" week of \"currYear\")\";
	    delete output;
	}
	#print \"\\t\"idxs[3]\" : \"weekly[idx];
	output[idxs[3]] = \"\\t\"idxs[3]\" : \"weekly[sorted[idx]];
    }

    sortAndPrint(output);
    delete output;
    
    asorti(daily,sorted);
    
    for (idx in sorted){
	split(sorted[idx], idxs, SUBSEP);
	if (idxs[1] != currYear || idxs[2] != currMonth || idxs[3] != currDay){
	    if (length(output) > 0) {
		sortAndPrint(output);
	    }
	    currYear = idxs[1];
	    currMonth = idxs[2];
	    currDay = idxs[3];
	    print \"Daily (\"currDay,currMonth,currYear\")\";
	    delete output;
	}
    	#print \"\\t\"idxs[4]\" : \"daily[idx];
	output[idxs[4]] = \"\\t\"idxs[4]\" : \"daily[sorted[idx]];
    }

    sortAndPrint(output);

}" < $NGINX_LOG_FILE

}

_init
_parse_options "$@"
shift $((OPTIND-1));
_main
