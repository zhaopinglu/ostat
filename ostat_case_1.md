
In a recent customer support, I used "ostat" tool to monitor the database status during migrating a 10M+ rows table in 48 parallel streams. The following is the ostat output:



```
SYS@xxxdb1 (OPEN) > @ostat 2
-- Author: zhaopinglu77@gmail.com, Created: 20110904. Last Update: 20170224
-- Note: 1, Use Ctrl-C to break the execution. 2, The unit in output values: k = 1000, m = 1000k, etc.

         %Idle|%Tota|DBCPU|PhyIO|Trans|%IOWa|Rollb|UsrCa|LgcRd|PhyRd|CeFCW|PhyWt|CePhy|PhyRd|BlkCh|PhyWt|RedoM|UndoV|WArea|Parse|ExecS|%BufN|WArea|%BufH|%Libr|%FCHi|%Redo|%Soft|%NPrs|FreBu|FreBu|EnqRe|LogFi|
              |lCPU |(ms) |     |     |it   |ack  |lls  |Blk  |MB   |t    |MB   |ICMB |Blk  |g    |Blk  |B    |ecMB |Optm |Hard |QL   |owait|Npass|it   |yHit |t    |NWait|Prse |eCPU |fInsp|fReq |qs   |lSync|
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
00:30:56  43.5  55.7 33.5k 88.3k   271  12.8     0     5  1.6m 400.8     0  1.2k  1.6k 47.7k  854k 85.3k 263.4  74.4  1.6k   743 15.9k  99.7     0  99.1  97.3     0   100  91.9  98.6 70.9k   62k  260k     1
00:30:58  32.7  68.4 43.6k  126k     3  17.9     0    17  1.9m 822.1     0  1.8k  2.6k 56.8k    1m 91.9k 322.7  91.7     6    38    58  99.6     0    99  96.9     0   100  44.1  99.6  130k 72.1k  315k     3
00:31:00  32.8  61.5   36k  121k     3  17.8     0    13  1.6m 850.8     0  1.7k  2.6k 53.5k  903k 99.2k 282.2    79     2    14    26  99.6     0  98.9  97.7     0   100  48.1  99.6 91.2k 69.6k  275k     2
00:31:02  31.5  62.1 36.1k  119k     0  17.6     0     3  1.9m 549.1     0  1.5k    2k   56k    1m 93.4k 310.3  87.3     2     0    19  99.5     0    99   100     0   100   100   100 99.4k 74.8k  308k     1
00:31:04  33.7  62.7 35.8k  109k     2  16.8     0    12  1.6m 895.1     0  1.6k  2.5k 49.7k  873k   87k 267.2  74.9     5     1    28  99.5     0  99.1  99.8     0   100  95.5  99.8 95.4k 69.8k  270k     1
00:31:07  30.2  63.1 36.2k  115k     3  16.1     0    13  1.5m 910.5     0  1.7k  2.6k 53.8k  891k 87.6k 280.7  78.8     2     3    23  99.9     0  98.9  99.4     0   100  88.5  99.4 85.7k 66.6k  272k     3
00:31:09  30.7  63.7 37.6k  126k     2  17.9     0     8  1.7m 515.2     0  1.5k    2k 58.9k  970k 94.1k 309.5  88.1     2     1    18  99.8     0  98.9  99.8     0   100  94.7  99.8  123k 76.4k  295k     2
00:31:11  32.9  62.2 35.4k  121k     0  20.3     0     5  1.6m 888.2     0  1.7k  2.6k 55.4k  872k 88.7k 276.6  76.9     2     0    17  99.7     0  98.9   100     0   100   100   100  117k 64.4k  268k     0
00:31:13  36.4  59.9 34.3k  126k     2  20.3     0    12  1.5m 677.1     0  1.5k  2.2k 51.2k  842k 99.6k 263.6  73.2     2     2    26  99.6     0    99  99.6     0   100  92.3  99.6  108k 65.2k  255k     0
```

You can see many real-time key metrics at a quick glance. Cool!!!
