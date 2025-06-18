#!/opt/epics-R7.0.9/modules/StreamDevice-2.8.23/bin/linux-x86_64/streamApp

epicsEnvSet("STREAMDEVICE", "/opt/epics-R7.0.9/modules/StreamDevice-2.8.23")
epicsEnvSet("STREAM_PROTOCOL_PATH", "../protocol")

dbLoadDatabase("${STREAMDEVICE}/dbd/streamApp.dbd")
streamApp_registerRecordDeviceDriver(pdbbase)

drvAsynIPPortConfigure("PS1", "192.168.1.101:9221")

#dbLoadRecords("../db/sga.db", "port = PS1")
dbLoadRecords("../db/sga.db", "port = PS1")

iocInit
