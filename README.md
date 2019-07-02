# Ostat
Oracle Database Real Time Performance Monitoring Tool.

\<WIP\>

Example:
![alt text](screenshots/ostat.png)


1. Installation
Use sqlplus to connection to a database with sys user. Then run 
@ostat/pipe_ostat

Done.

2. Run ostat script to get the 'almost' real time performance metrics output.

Example 1: Query CPU usage with script ostat_cpu.sql

```
SYS@XXX/ORCLCDB (OPEN) > @ostat_cpu 1
-- Author: zhaopinglu77@gmail.com, Created: 20110904. Last Update: 20170224
-- Note: 1, Use Ctrl-C to break the execution. 2, The unit in output values: k = 1000, m = 1000k, etc.

         LOAD        |VM_IN_BYTES |VM_OUT_BYTES|%Idle       |%User       |%Sys        |%WIO        |%TotalCPU   |%BusyCPU    |
------------------------------------------------------------------------------------------------------------------------------
02:47:41           .3            0            0         98.7          1.3            0            0          1.3         98.9
02:47:43           .3            0            0         98.7          1.3            0            0          1.3         98.3
02:47:45           .3            0            0         98.7          1.3            0            0          1.3         95.1
02:47:47           .3            0            0         98.7          1.3            0            0          1.3         98.4
02:47:49           .3            0            0         98.3          1.4           .3            0          1.3         73.6
02:47:51           .4            0            0         98.3          1.5           .2            0          1.3         73.9
02:47:53           .4            0            0         98.7          1.3            0            0          1.3         96.9
02:47:55           .4            0            0         98.7          1.3            0            0          1.3         97.4
02:47:57           .4            0            0         98.7          1.3            0            0          1.3         92.9
02:47:59           .4            0            0         98.5          1.3           .2            0          2.1        144.5
02:48:01           .4            0            0         99.9            0            0            0            0         14.5
02:48:03           .4            0            0          100            0            0            0            0         17.6
02:48:05           .4            0            0          100            0            0            0            0         34.6
```
