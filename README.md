# nginx log analyzer

The goal of this script is to count various http return code parsing "live" nginx_access.log and rotated gzipped files under a subfolder.

You can specify as optional parameter the range of date: daily, weekly, monthly and yearly.
Simply download script and configuration file in the same folder.

**Usage example:**

Use custom path from command-line switch:
> ./nginxanalyzer.sh -p /var/log/nginx > out.txt

Declutter output. Show only GET & POST methods, counting the rest as OTHER.
> ./nginxanalyzer.sh -D > out_declutter.txt

Count week-by-week omitting day-by-day
> ./nginxanalyzer.sh -wd > out_weekly.txt


**Sample output**

<pre>
Monday 16 Mar
   00x - 16 (16 MALFORMED)
   200 - 292730 (292500 GET, 203 HEAD, 13 OPTIONS, 14 POST)
   206 - 4 (4 GET)
   301 - 3452 (1 ACL, 1 BASELINE-CONTROL, 1 BCOPY, 1 BDELETE, 1 BMOVE, 1 BPROPFIND, 1 BPROPPATCH, 1 CHECKIN, 1 CHECKOUT, 1            CONNECT, 1 COPY, 1 DEBUG, 1 DELETE, 1 ESSUZZ, 3079 GET, 4 HEAD, 1 OPTIONS, 352 POST, 1 PROPFIND, 1 TRACK)
   302 - 66 (40 GET, 26 POST)
   303 - 31 (31 GET)
   304 - 8953 (8950 GET, 3 HEAD)
   307 - 82184 (82184 GET)
   308 - 4131 (4111 GET, 20 HEAD)
   400 - 35626 (3 CONNECT, 35616 GET, 1 HEAD, 2 OPTIONS, 4 POST)
   401 - 3 (2 GET, 1 POST)
   403 - 6 (4 GET, 2 POST)
   404 - 17229 (2 ACL, 2 BASELINE-CONTROL, 1 BCOPY, 2 BDELETE, 2 BMOVE, 1 BPROPPATCH, 1 CHECKIN, 2 CHECKOUT, 1 COPY, 10772            GET, 6346 HEAD, 3 LABEL, 3 LOCK, 2 MERGE, 3 MKACTIVITY, 2 MKCOL, 3 MKWORKSPACE, 2 MOVE, 2 NOTIFY, 2 OPTIONS, 3                ORDERPATCH, 2 PATCH, 3 POLL, 42 POST, 2 PROPFIND, 2 PROPPATCH, 3 PUT, 1 REPORT, 3 RPC_IN_DATA, 2 RPC_OUT_DATA, 2              SEARCH, 1 SUBSCRIBE, 2 TESTZZZ, 1 UNCHECKOUT, 3 UNLOCK, 1 UPDATE, 2 X-MS-ENUMATTS)
   405 - 2 (1 DELETE, 1 TRACE)
   499 - 26 (24 GET, 2 HEAD)
   500 - 148075 (1 CONNECT, 148056 GET, 12 HEAD, 6 OPTIONS)
   502 - 100 (100 GET)
Total - 592634
</pre>
