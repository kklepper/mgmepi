%% =============================================================================
%% =============================================================================

-include("../include/mgmepi.hrl").

%% == define ==

%% -- storage/ndb/include/kernel/ndb_limits.h --
-define(MAX_NODES_ID, 255).

%% -- storage/ndb/include/mgmapi/mgmapi.h --

%% enum ndb_mgm_node_type
-define(NDB_MGM_NODE_TYPE_UNKNOWN, -1).
-define(NDB_MGM_NODE_TYPE_API,      1). % NODE_TYPE_API
-define(NDB_MGM_NODE_TYPE_NDB,      0). % NODE_TYPE_DB
-define(NDB_MGM_NODE_TYPE_MGM,      2). % NODE_TYPE_MGM
-define(NDB_MGM_NODE_TYPE_MIN,      0).
-define(NDB_MGM_NODE_TYPE_MAX,      3).

%% enum ndb_mgm_node_status
-define(NDB_MGM_NODE_STATUS_UNKNOWN,       0).
-define(NDB_MGM_NODE_STATUS_NO_CONTACT,    1).
-define(NDB_MGM_NODE_STATUS_NOT_STARTED,   2).
-define(NDB_MGM_NODE_STATUS_STARTING,      3).
-define(NDB_MGM_NODE_STATUS_STARTED,       4).
-define(NDB_MGM_NODE_STATUS_SHUTTING_DOWN, 5).
-define(NDB_MGM_NODE_STATUS_RESTARTING,    6).
-define(NDB_MGM_NODE_STATUS_SINGLEUSER,    7).
-define(NDB_MGM_NODE_STATUS_RESUME,        8).
-define(NDB_MGM_NODE_STATUS_CONNECTED,     9).
%%efine(NDB_MGM_NODE_STATUS_MIN,           0).
%%efine(NDB_MGM_NODE_STATUS_MAX,           9).

%% -- storage/ndb/include/mgmapi/mgmapi_config_parameters.h --

%% "Internal"
-define(CFG_DB_STOP_ON_ERROR_INSERT, 1). % ?

-define(CFG_TYPE_OF_SECTION,     999).
-define(CFG_SECTION_SYSTEM,     1000).
-define(CFG_SECTION_NODE,       2000).
-define(CFG_SECTION_CONNECTION, 3000).

-define(NODE_TYPE_DB,  0).
-define(NODE_TYPE_API, 1).
-define(NODE_TYPE_MGM, 2).

-define(CONNECTION_TYPE_TCP, 0).
%%efine(CONNECTION_TYPE_SHM, 1).
%%efine(CONNECTION_TYPE_SCI, 2).
%%efine(CONNECTION_TYPE_OSE, 3).

%%efine(ARBIT_METHOD_DISABLED,     0).
%%efine(ARBIT_METHOD_DEFAULT,      1).
%%efine(ARBIT_METHOD_WAITEXTERNAL, 2).

%%efine(OPERATION_REDO_PROBLEM_ACTION_ABORT, 0).
%%efine(OPERATION_REDO_PROBLEM_ACTION_QUEUE, 1).

%% -- storage/ndb/include/mgmapi/ndb_logevent.h --

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

%% -- --

-define(FS, ": ").
-define(LS, $\n).

-define(IS_BACKUP_ID(T), (is_integer(T) and (0 =< T))).

-define(IS_BACKUP_WAIT(T), (is_integer(T) and (0 =< T) and (2 >= T))).

-define(IS_BOOLEAN(T), (is_integer(T) and (0 =< T) and (1 >= T))).

-define(IS_EVENT_CATEGORY(T), (is_integer(T)
                               and (?NDB_MGM_MIN_EVENT_CATEGORY =< T)
                               and (?NDB_MGM_MAX_EVENT_CATEGORY >= T))).

-define(IS_EVENT_SEVERITY(T), (is_integer(T)
                               and (?NDB_MGM_MIN_EVENT_SEVERITY =< T)
                               and (?NDB_MGM_MAX_EVENT_SEVERITY >= T))).

-define(IS_LOGLEVEL(T), (is_integer(T) and (0 =< T) and (15 >= T))).

-define(IS_NODE(T), (is_integer(T) and (1 =< T) and (?MAX_NODES_ID >= T))).

-define(IS_NODE_TYPE(T), (is_integer(T)
                          and (?NDB_MGM_NODE_TYPE_MIN =< T)
                          and (?NDB_MGM_NODE_TYPE_MAX >  T))).

-define(IS_VERSION(T), (is_integer(T))). % > 5.1 (restart:V2)

-define(VERSION(Major,Minor,Build), ((Major bsl 16) bor (Minor bsl 8) bor (Build bsl 0))).

-define(MIN_VERSION(Target,Major,Minor,Build), (Target >= ?VERSION(Major,Minor,Build))).

-define(MAX_VERSION(Target,Major,Minor,Build), (Target < ?VERSION(Major,Minor,Build))).

%% -- --

-type(argument() :: {binary(),term(),atom()}).
-type(fragment() :: {binary(),binary()}).
-type(property() :: {binary(),term()}).
