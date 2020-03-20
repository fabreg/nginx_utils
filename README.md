# nginx log analyzer

The goal of this script is to count various http return code parsing "live" nginx_access.log and rotated gzipped files under a subfolder.
You can specify as optional parameter the range of date: daily, weekly, monthly and yearly.
Simply download script and configuration file in the same folder.

Usage example:

Use custom path from command-line switch:
./nginxanalyzer.sh -p /var/log/nginx > out.txt

Declutter output. Show only GET & POST methods, counting the rest as OTHER.
./nginxanalyzer.sh -D > out_declutter.txt

Count week-by-week omitting day-by-day
./nginxanalyzer.sh -wd > out_weekly.txt
