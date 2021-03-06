%% =============================================================================
%% =============================================================================

%% == define ==

%% -- ~/include/mgmapi/ndb_logevent.h --

%% enum Ndb_logevent_type
%%efine(NDB_LE_ILLEGAL_TYPE,              -1).
-define(NDB_LE_Connected,                  0).
-define(NDB_LE_Disconnected,               1).
-define(NDB_LE_CommunicationClosed,        2).
-define(NDB_LE_CommunicationOpened,        3).
-define(NDB_LE_GlobalCheckpointStarted,    4).
-define(NDB_LE_GlobalCheckpointCompleted,  5).
-define(NDB_LE_LocalCheckpointStarted,     6).
-define(NDB_LE_LocalCheckpointCompleted,   7).
-define(NDB_LE_LCPStoppedInCalcKeepGci,    8).
-define(NDB_LE_LCPFragmentCompleted,       9).
-define(NDB_LE_NDBStartStarted,           10).
-define(NDB_LE_NDBStartCompleted,         11).
-define(NDB_LE_STTORRYRecieved,           12).
-define(NDB_LE_StartPhaseCompleted,       13).
-define(NDB_LE_CM_REGCONF,                14).
-define(NDB_LE_CM_REGREF,                 15).
-define(NDB_LE_FIND_NEIGHBOURS,           16).
-define(NDB_LE_NDBStopStarted,            17).
-define(NDB_LE_NDBStopAborted,            18).
-define(NDB_LE_StartREDOLog,              19).
-define(NDB_LE_StartLog,                  20).
-define(NDB_LE_UNDORecordsExecuted,       21).
-define(NDB_LE_NR_CopyDict,               22).
-define(NDB_LE_NR_CopyDistr,              23).
-define(NDB_LE_NR_CopyFragsStarted,       24).
-define(NDB_LE_NR_CopyFragDone,           25).
-define(NDB_LE_NR_CopyFragsCompleted,     26).
-define(NDB_LE_NodeFailCompleted,         27).
-define(NDB_LE_NODE_FAILREP,              28).
-define(NDB_LE_ArbitState,                29).
-define(NDB_LE_ArbitResult,               30).
-define(NDB_LE_GCP_TakeoverStarted,       31).
-define(NDB_LE_GCP_TakeoverCompleted,     32).
-define(NDB_LE_LCP_TakeoverStarted,       33).
-define(NDB_LE_LCP_TakeoverCompleted,     34).
-define(NDB_LE_TransReportCounters,       35).
-define(NDB_LE_OperationReportCounters,   36).
-define(NDB_LE_TableCreated,              37).
-define(NDB_LE_UndoLogBlocked,            38).
-define(NDB_LE_JobStatistic,              39).
-define(NDB_LE_SendBytesStatistic,        40).
-define(NDB_LE_ReceiveBytesStatistic,     41).
-define(NDB_LE_TransporterError,          42).
-define(NDB_LE_TransporterWarning,        43).
-define(NDB_LE_MissedHeartbeat,           44).
-define(NDB_LE_DeadDueToHeartbeat,        45).
-define(NDB_LE_WarningEvent,              46).
-define(NDB_LE_SentHeartbeat,             47).
-define(NDB_LE_CreateLogBytes,            48).
-define(NDB_LE_InfoEvent,                 49).
-define(NDB_LE_MemoryUsage,               50).
-define(NDB_LE_ConnectedApiVersion,       51).
-define(NDB_LE_SingleUser,                52).
-define(NDB_LE_NDBStopCompleted,          53).
-define(NDB_LE_BackupStarted,             54).
-define(NDB_LE_BackupFailedToStart,       55).
-define(NDB_LE_BackupCompleted,           56).
-define(NDB_LE_BackupAborted,             57).
-define(NDB_LE_EventBufferStatus,         58).
-define(NDB_LE_NDBStopForced,             59).
-define(NDB_LE_StartReport,               60).
%%                                        61
-define(NDB_LE_BackupStatus,              62).
-define(NDB_LE_RestoreMetaData,           63).
-define(NDB_LE_RestoreData,               64).
-define(NDB_LE_RestoreLog,                65).
-define(NDB_LE_RestoreStarted,            66).
-define(NDB_LE_RestoreCompleted,          67).
-define(NDB_LE_ThreadConfigLoop,          68).
-define(NDB_LE_SubscriptionStatus,        69).
-define(NDB_LE_MTSignalStatistics,        70).
-define(NDB_LE_LogFileInitStatus,         71).
-define(NDB_LE_LogFileInitCompStatus,     72).
-define(NDB_LE_RedoStatus,                73).
-define(NDB_LE_CreateSchemaObject,        74).
-define(NDB_LE_AlterSchemaObject,         75).
-define(NDB_LE_DropSchemaObject,          76).
-define(NDB_LE_StartReadLCP,              77).
-define(NDB_LE_ReadLCPComplete,           78).
-define(NDB_LE_RunRedo,                   79).
-define(NDB_LE_RebuildIndex,              80).
-define(NDB_LE_SavedEvent,                81).
-define(NDB_LE_ConnectCheckStarted,       82).
-define(NDB_LE_ConnectCheckCompleted,     83).
-define(NDB_LE_NodeFailRejected,          84).
