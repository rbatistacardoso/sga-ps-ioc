#!/opt/epics-R7.0.9/modules/StreamDevice-2.8.23/bin/linux-x86_64/streamApp

epicsEnvSet("STREAMDEVICE", "/opt/epics-R7.0.9/modules/StreamDevice-2.8.23")
epicsEnvSet("STREAM_PROTOCOL_PATH", "../protocol")

dbLoadDatabase("${STREAMDEVICE}/dbd/streamApp.dbd")
streamApp_registerRecordDeviceDriver(pdbbase)

drvAsynIPPortConfigure("PS1", "192.168.1.100:9221")
drvAsynIPPortConfigure("PS2", "192.168.1.233:9221")

dbLoadRecords("../db/ps.db", "port = PS1, PS = SGI")
dbLoadRecords("../db/ps.db", "port = PS2, PS = SGA")

iocInit
