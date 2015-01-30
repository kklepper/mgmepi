%% =============================================================================
%% Copyright 2013-2015 AONO Tomohiko
%%
%% This library is free software; you can redistribute it and/or
%% modify it under the terms of the GNU Lesser General Public
%% License version 2.1 as published by the Free Software Foundation.
%%
%% This library is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
%% Lesser General Public License for more details.
%%
%% You should have received a copy of the GNU Lesser General Public
%% License along with this library; if not, write to the Free Software
%% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
%% =============================================================================

-module(mgmepi_config).

-include("internal.hrl").

%% -- private --
-export([unpack/1, unpack/2, unpack/3]).
-export([get_connection/3, get_node/3, get_nodes/3, get_system/2]).

%% -- internal --

%% -- ~/include/mgmapi/mgmapi_config_parameters.h --

-define(CFG_TYPE_OF_SECTION,     999).
-define(CFG_SECTION_SYSTEM,     1000).
-define(CFG_SECTION_NODE,       2000).
-define(CFG_SECTION_CONNECTION, 3000).

-define(NODE_TYPE_DB,  ?NDB_MGM_NODE_TYPE_NDB).
-define(NODE_TYPE_API, ?NDB_MGM_NODE_TYPE_API).
-define(NODE_TYPE_MGM, ?NDB_MGM_NODE_TYPE_MGM).

-define(CONNECTION_TYPE_TCP, 0).
%%efine(CONNECTION_TYPE_SHM, 1).
%%efine(CONNECTION_TYPE_SCI, 2).
%%efine(CONNECTION_TYPE_OSE, 3).

%% -- ~/include/util/ConfigValues.hpp --

%% enum: ConfigValues::ValueType
-define(VALUETYPE_INT,     1).
-define(VALUETYPE_STRING,  2).
-define(VALUETYPE_SECTION, 3).
-define(VALUETYPE_INT64,   4).

%% -- ~/src/common/util/ConfigValues.cpp --

-define(KEYVAL(I),  (I band 16#00003FFF)).          % KP_KEYVAL_(MASK|SHIFT)
-define(SECTION(I), (I band (16#00003FFF bsl 14))). % KP_SECTION_(MASK|SHIFT)
-define(TYPE(I),    ((I bsr 28) band 16#0000000F)). % KP_TYPE_(MASK|SHIFT)

-define(CFV_KEY_PARENT, 16#3ffe). % KP_KEYVAL_MASK - 1

%% == private ==

%% @see
%%  ~/src/common/util/ConfigValues.cpp: ConfigValuesFactory::unpack/2

-spec unpack(binary()) -> config().
unpack(Binary) ->
    unpack(Binary, byte_size(Binary)).

-spec unpack(binary(),non_neg_integer()) -> config().
unpack(Binary, Size) ->
    unpack(Binary, Size, big). % TODO

-spec unpack(binary(),non_neg_integer(),atom()) -> config().
unpack(Binary, Size, Endianness) -> % 12 =< Size, 0 == Size rem 4
    C = baseline_binary:binary_to_word(Binary, Size, -4, Endianness),
    case {binary:part(Binary,0,8), checksum(Binary,Size-4,0)} of
        {<<"NDBCONFV">>, C}->
            unpack(Binary, 8, Size-12, Endianness, 0, [], [])
    end.


-spec get_connection(config(),integer(),boolean()) -> [config()].
get_connection(Config, Node, false) ->
    F = fun (L) ->
                lists:member({?CFG_CONNECTION_NODE_1,Node}, L)
                    orelse lists:member({?CFG_CONNECTION_NODE_2,Node}, L)
        end,
    lists:filter(F, find(Config,[0,?CFG_SECTION_CONNECTION]));
get_connection(Config, Node, true) ->
    [ combine(E,?CFG_SECTION_CONNECTION) || E <- get_connection(Config,Node,false) ].

-spec get_node(config(),integer(),boolean()) -> [config()].
get_node(Config, Node, false) ->
    F = fun (L) ->
                lists:member({?CFG_NODE_ID,Node}, L)
        end,
    lists:filter(F, find(Config,[0,?CFG_SECTION_NODE]));
get_node(Config, Node, true) ->
    [ combine(E,?CFG_SECTION_NODE) || E <- get_node(Config,Node,false) ].

-spec get_nodes(config(),integer(),boolean()) -> [config()].
get_nodes(Config, Type, false) ->
    F = fun (L) ->
                lists:member({?CFG_TYPE_OF_SECTION,Type}, L)
        end,
    lists:filter(F, find(Config,[0,?CFG_SECTION_NODE]));
get_nodes(Config, Type, true) ->
    [ combine(E,?CFG_SECTION_NODE) || E <- get_nodes(Config,Type,false) ].

-spec get_system(config(),boolean()) -> [config()].
get_system(Config, false) ->
    find(Config, [0,?CFG_SECTION_SYSTEM]);
get_system(Config, true) ->
    [ combine(E,?CFG_SECTION_SYSTEM) || E <- get_system(Config,false) ].

%% === internal ===

checksum(Binary, Size, Digit) -> % TODO, ndbepi
    lists:foldl(fun(E,A) -> A bxor binary:decode_unsigned(E) end, Digit,
                [ binary:part(Binary,E,4) || E <- lists:seq(0,Size-1,4) ]).

combine(List, Section) ->
    case lists:keyfind(?CFG_TYPE_OF_SECTION, 1, List) of
        {_, Type} ->
            baseline_lists:combine(List, names(Section,Type), [
                                                               ?CFG_TYPE_OF_SECTION,
                                                               ?CFV_KEY_PARENT
                                                              ])
    end.

find(Config, List) ->
    find(Config, Config, List).

find(Config, Key, []) ->
    case lists:keyfind(Key, 1, Config) of
        {Key, List} ->
            [ proplists:get_value(N,Config) || {_,N} <- List ] % TODO
    end;
find(Config, List, [H|T]) ->
    case lists:keyfind(H, 1, List) of
        {H, L} ->
            find(Config, L, T)
    end.

unpack(Binary, Pos, Len, Endianness) ->
    {I, PI} = unpack_integer(Binary, Pos, Endianness),
    {V, PV} = unpack_value(?TYPE(I), Binary, PI, Endianness),
    {
      PV,
      Len - (PV - Pos),
      {?SECTION(I), ?KEYVAL(I), V}
    }.

unpack(_Binary, _Pos, 0, _Endianness, Section, L1, L2) ->
    [{Section,L2}|L1];
unpack(Binary, Pos, Len, Endianness, Section, L1, L2) ->
    {P, L, T} = unpack(Binary, Pos, Len, Endianness),
    unpack(Binary, P, L, Endianness, Section, T, L1, L2).

unpack(Binary, Pos, Len, Endianness, S, {S,K,V}, L1, L2) ->
    unpack(Binary, Pos, Len, Endianness, S, L1, [{K,V}|L2]);
unpack(Binary, Pos, Len, Endianness, P, {N,K,V}, L1, L2) ->
    unpack(Binary, Pos, Len, Endianness, N, [{P,L2}|L1], [{K,V}]).

unpack_binary(Binary, Pos, Endianness) ->
    {L, P} = unpack_integer(Binary, Pos, Endianness),
    S = 4 - (L rem 4),                  % right-aligned
    {binary:part(Binary,P,L-1), P+L+S}. % ignore '\0'

unpack_integer(Binary, Pos, big) ->
    <<I:4/integer-signed-big-unit:8>> = binary:part(Binary, Pos, 4),
    {I, Pos+4}.

unpack_long(Binary, Pos, Endianness) ->
    {H, PH} = unpack_integer(Binary, Pos, Endianness),
    {L, PL} = unpack_integer(Binary, PH,  Endianness),
    {(H bsl 32) bor L, PL}.

unpack_value(?VALUETYPE_INT, Binary, Pos, Endianness) ->
    unpack_integer(Binary, Pos, Endianness);
unpack_value(?VALUETYPE_STRING, Binary, Pos, Endianness) ->
    unpack_binary(Binary, Pos, Endianness);
unpack_value(?VALUETYPE_INT64, Binary, Pos, Endianness) ->
    unpack_long(Binary, Pos, Endianness);
unpack_value(?VALUETYPE_SECTION, Binary, Pos, Endianness) ->
    unpack_integer(Binary, Pos, Endianness).


%%
%% @see
%%  ~/src/mgmsrv/ConfigInfo.cpp
%%
names(?CFG_SECTION_SYSTEM, ?CFG_SECTION_SYSTEM) ->
    [
     {?CFG_SYS_NAME, <<"Name">>},
     {?CFG_SYS_PRIMARY_MGM_NODE, <<"PrimaryMGMNode">>},
     {?CFG_SYS_CONFIG_GENERATION, <<"ConfigGenerationNumber">>}
    ];
names(?CFG_SECTION_NODE, ?NODE_TYPE_MGM) ->
    %%
    %% @see
    %%  http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-mgm-definition.html
    %%
    [
     {?CFG_NODE_ID, <<"NodeId">>},
     %%{-1, <<"ExecuteOnComputer">>},
     {?CFG_MGM_PORT, <<"PortNumber">>},
     {?CFG_NODE_HOST, <<"HostName">>},
     {?CFG_LOG_DESTINATION, <<"LogDestination">>},
     {?CFG_NODE_ARBIT_RANK, <<"ArbitrationRank">>},
     {?CFG_NODE_ARBIT_DELAY, <<"ArbitrationDelay">>},
     {?CFG_NODE_DATADIR, <<"DataDir">>},
     %%{-1, <<"PortNumberStats">>},
     %%{-1, <<"Wan">>},
     {?CFG_HB_THREAD_PRIO, <<"HeartbeatThreadPriority">>},
     {?CFG_TOTAL_SEND_BUFFER_MEMORY, <<"TotalSendBufferMemory">>},
     {?CFG_MGMD_MGMD_HEARTBEAT_INTERVAL, <<"HeartbeatIntervalMgmdMgmd">>},
     %% -- ? --
     {?CFG_EXTRA_SEND_BUFFER_MEMORY, <<"ExtraSendBufferMemory">>}
    ];
names(?CFG_SECTION_NODE, ?NODE_TYPE_DB) ->
    %%
    %% @see
    %%  http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-ndbd-definition.html
    %%
    [
     %% -- "Identifying data nodes" --
     {?CFG_NODE_ID, <<"NodeId">>},
     {?CFG_NODE_HOST, <<"HostName">>},
     {?CFG_DB_SERVER_PORT, <<"ServerPort">>},
     {?CFG_DB_TCPBIND_INADDR_ANY, <<"TcpBind_INADDR_ANY">>},
     {?CFG_DB_NODEGROUP, <<"NodeGroup">>},
     {?CFG_DB_NO_REPLICAS, <<"NoOfReplicas">>},
     {?CFG_NODE_DATADIR, <<"DataDir">>},
     {?CFG_DB_FILESYSTEM_PATH, <<"FileSystemPath">>},
     {?CFG_DB_BACKUP_DATADIR, <<"BackupDataDir">>},
     %% -- "Data Memory, Index Memory, and String Memory" --
     {?CFG_DB_DATA_MEM, <<"DataMemory">>},
     {?CFG_DB_INDEX_MEM, <<"IndexMemory">>},
     {?CFG_DB_STRING_MEMORY, <<"StringMemory">>},
     {?CFG_DB_FREE_PCT, <<"MinFreePct">>},
     %% -- "Transaction parameters" --
     {?CFG_DB_NO_TRANSACTIONS, <<"MaxNoOfConcurrentTransactions">>},
     {?CFG_DB_NO_OPS, <<"MaxNoOfConcurrentOperations">>},
     {?CFG_DB_NO_LOCAL_OPS, <<"MaxNoOfLocalOperations">>},
     {?CFG_DB_MAX_DML_OPERATIONS_PER_TRANSACTION, <<"MaxDMLOperationsPerTransaction">>},
     %% -- "Transaction temporary storage" --
     {?CFG_DB_NO_INDEX_OPS, <<"MaxNoOfConcurrentIndexOperations">>},
     {?CFG_DB_NO_TRIGGER_OPS, <<"MaxNoOfFiredTriggers">>},
     {?CFG_DB_TRANS_BUFFER_MEM, <<"TransactionBufferMemory">>},
     %% -- "Scans and buffering" --
     {?CFG_DB_NO_SCANS, <<"MaxNoOfConcurrentScans">>},
     {?CFG_DB_NO_LOCAL_SCANS, <<"MaxNoOfLocalScans">>},
     {?CFG_DB_BATCH_SIZE, <<"BatchSizePerLocalScan">>},
     {?CFG_DB_LONG_SIGNAL_BUFFER, <<"LongMessageBuffer">>},
     {?CFG_DB_PARALLEL_SCANS_PER_FRAG, <<"MaxParallelScansPerFragment">>},
     %% -- "Memory Allocation" --
     {?CFG_DB_MAX_ALLOCATE, <<"MaxAllocate">>},
     %% -- "Hash Map Size" --
     {?CFG_DEFAULT_HASHMAP_SIZE, <<"DefaultHashMapSize">>},
     %% -- "Logging and checkpointing" --
     {?CFG_DB_NO_REDOLOG_FILES, <<"NoOfFragmentLogFiles">>},
     {?CFG_DB_REDOLOG_FILE_SIZE, <<"FragmentLogFileSize">>},
     {?CFG_DB_INIT_REDO, <<"InitFragmentLogFiles">>},
     {?CFG_DB_MAX_OPEN_FILES, <<"MaxNoOfOpenFiles">>},
     {?CFG_DB_INITIAL_OPEN_FILES, <<"InitialNoOfOpenFiles">>},
     {?CFG_DB_NO_SAVE_MSGS, <<"MaxNoOfSavedMessages">>},
     {?CFG_DB_LCP_TRY_LOCK_TIMEOUT, <<"MaxLCPStartDelay">>},
     {?CFG_DB_LCP_SCAN_WATCHDOG_LIMIT, <<"LcpScanProgressTimeout">>},
     %% -- "Metadata objects" --
     {?CFG_DB_NO_ATTRIBUTES, <<"MaxNoOfAttributes">>},
     {?CFG_DB_NO_TABLES, <<"MaxNoOfTables">>},
     {?CFG_DB_NO_ORDERED_INDEXES, <<"MaxNoOfOrderedIndexes">>},
     {?CFG_DB_NO_UNIQUE_HASH_INDEXES, <<"MaxNoOfUniqueHashIndexes">>},
     {?CFG_DB_NO_TRIGGERS, <<"MaxNoOfTriggers">>},
     {?CFG_DB_NO_INDEXES, <<"MaxNoOfIndexes">>}, % deprecated
     {?CFG_DB_SUBSCRIPTIONS, <<"MaxNoOfSubscriptions">>},
     {?CFG_DB_SUBSCRIBERS, <<"MaxNoOfSubscribers">>},
     {?CFG_DB_SUB_OPERATIONS, <<"MaxNoOfConcurrentSubOperations">>},
     %% -- "Boolean parameters" --
     {?CFG_DB_LATE_ALLOC, <<"LateAlloc">>},
     {?CFG_DB_MEMLOCK, <<"LockPagesInMainMemory">>},
     {?CFG_DB_STOP_ON_ERROR, <<"StopOnError">>},
     {?CFG_DB_CRASH_ON_CORRUPTED_TUPLE, <<"CrashOnCorruptedTuple">>},
     {?CFG_DB_DISCLESS, <<"Diskless">>},
     {?CFG_DB_O_DIRECT, <<"ODirect">>},
     %%{?CFG_DB_STOP_ON_ERROR_INSERT, <<"RestartOnErrorInsert">>}, % internal
     {?CFG_DB_COMPRESSED_BACKUP, <<"CompressedBackup">>},
     {?CFG_DB_COMPRESSED_LCP, <<"CompressedLCP">>},
     %% -- "Controlling Timeouts, Intervals, and Disk Paging" --
     {?CFG_DB_WATCHDOG_INTERVAL, <<"TimeBetweenWatchDogCheck">>},
     {?CFG_DB_WATCHDOG_INTERVAL_INITIAL, <<"TimeBetweenWatchDogCheckInitial">>},
     {?CFG_DB_START_PARTIAL_TIMEOUT, <<"StartPartialTimeout">>},
     {?CFG_DB_START_PARTITION_TIMEOUT, <<"StartPartitionedTimeout">>},
     {?CFG_DB_START_FAILURE_TIMEOUT, <<"StartFailureTimeout">>},
     {?CFG_DB_START_NO_NODEGROUP_TIMEOUT, <<"StartNoNodeGroupTimeout">>},
     {?CFG_DB_HEARTBEAT_INTERVAL, <<"HeartbeatIntervalDbDb">>},
     {?CFG_DB_API_HEARTBEAT_INTERVAL, <<"HeartbeatIntervalDbApi">>},
     {?CFG_DB_HB_ORDER, <<"HeartbeatOrder">>},
     {?CFG_DB_CONNECT_CHECK_DELAY, <<"ConnectCheckIntervalDelay">>},
     {?CFG_DB_LCP_INTERVAL, <<"TimeBetweenLocalCheckpoints">>},
     {?CFG_DB_GCP_INTERVAL, <<"TimeBetweenGlobalCheckpoints">>},
     {?CFG_DB_MICRO_GCP_INTERVAL, <<"TimeBetweenEpochs">>},
     {?CFG_DB_MICRO_GCP_TIMEOUT, <<"TimeBetweenEpochsTimeout">>},
     {?CFG_DB_MAX_BUFFERED_EPOCHS, <<"MaxBufferedEpochs">>},
     {?CFG_DB_MAX_BUFFERED_EPOCH_BYTES, <<"MaxBufferedEpochBytes">>},
     {?CFG_DB_TRANSACTION_CHECK_INTERVAL, <<"TimeBetweenInactiveTransactionAbortCheck">>},
     {?CFG_DB_TRANSACTION_INACTIVE_TIMEOUT, <<"TransactionInactiveTimeout">>},
     {?CFG_DB_TRANSACTION_DEADLOCK_TIMEOUT, <<"TransactionDeadlockDetectionTimeout">>},
     {?CFG_DB_DISK_SYNCH_SIZE, <<"DiskSyncSize">>},
     {?CFG_DB_CHECKPOINT_SPEED, <<"DiskCheckpointSpeed">>}, % deprecated
     {?CFG_DB_CHECKPOINT_SPEED_SR, <<"DiskCheckpointSpeedInRestart">>}, % deprecated
     {?CFG_DB_LCP_DISC_PAGES_TUP, <<"NoOfDiskPagesToDiskAfterRestartTUP">>}, % deprecated
     %%{-1, <<"MaxDiskWriteSpeed">>},
     %%{-1, <<"MaxDiskWriteSpeedOtherNodeRestart">>},
     %%{-1, <<"MaxDiskWriteSpeedOwnRestart">>},
     %%{-1, <<"MinDiskWriteSpeed">>},
     {?CFG_DB_LCP_DISC_PAGES_ACC, <<"NoOfDiskPagesToDiskAfterRestartACC">>}, % deprecated
     {?CFG_DB_LCP_DISC_PAGES_TUP_SR, <<"NoOfDiskPagesToDiskDuringRestartTUP">>}, % deprecated
     {?CFG_DB_LCP_DISC_PAGES_ACC_SR, <<"NoOfDiskPagesToDiskDuringRestartACC">>}, % deprecated
     {?CFG_DB_ARBIT_TIMEOUT, <<"ArbitrationTimeout">>},
     {?CFG_DB_ARBIT_METHOD, <<"Arbitration">>},
     %% -- "Buffering and logging" --
     {?CFG_DB_UNDO_INDEX_BUFFER, <<"UndoIndexBuffer">>},
     {?CFG_DB_UNDO_DATA_BUFFER, <<"UndoDataBuffer">>},
     {?CFG_DB_REDO_BUFFER, <<"RedoBuffer">>},
     {?CFG_DB_EVENTLOG_BUFFER_SIZE, <<"EventLogBufferSize">>},
     %% -- "Controlling log messages" --
     {?CFG_LOGLEVEL_STARTUP, <<"LogLevelStartup">>},
     {?CFG_LOGLEVEL_SHUTDOWN, <<"LogLevelShutdown">>},
     {?CFG_LOGLEVEL_STATISTICS, <<"LogLevelStatistic">>},
     {?CFG_LOGLEVEL_CHECKPOINT, <<"LogLevelCheckpoint">>},
     {?CFG_LOGLEVEL_NODERESTART, <<"LogLevelNodeRestart">>},
     {?CFG_LOGLEVEL_CONNECTION, <<"LogLevelConnection">>},
     {?CFG_LOGLEVEL_ERROR, <<"LogLevelError">>},
     {?CFG_LOGLEVEL_CONGESTION, <<"LogLevelCongestion">>},
     {?CFG_LOGLEVEL_INFO, <<"LogLevelInfo">>},
     {?CFG_DB_MEMREPORT_FREQUENCY, <<"MemReportFrequency">>},
     {?CFG_DB_STARTUP_REPORT_FREQUENCY, <<"StartupStatusReportFrequency">>},
     %% -- "Debugging Parameters" --
     {?CFG_DB_DICT_TRACE, <<"DictTrace">>},
     %% -- "Backup parameters" --
     {?CFG_DB_BACKUP_DATA_BUFFER_MEM, <<"BackupDataBufferSize">>},
     {?CFG_DB_BACKUP_LOG_BUFFER_MEM, <<"BackupLogBufferSize">>},
     {?CFG_DB_BACKUP_MEM, <<"BackupMemory">>},
     {?CFG_DB_BACKUP_REPORT_FREQUENCY, <<"BackupReportFrequency">>},
     {?CFG_DB_BACKUP_WRITE_SIZE, <<"BackupWriteSize">>},
     {?CFG_DB_BACKUP_MAX_WRITE_SIZE, <<"BackupMaxWriteSize">>},
     %% -- "MySQL Cluster Realtime Performance Parameters" --
     {?CFG_DB_EXECUTE_LOCK_CPU, <<"LockExecuteThreadToCPU">>},
     {?CFG_DB_MAINT_LOCK_CPU, <<"LockMaintThreadsToCPU">>},
     {?CFG_DB_REALTIME_SCHEDULER, <<"RealtimeScheduler">>},
     {?CFG_DB_SCHED_EXEC_TIME, <<"SchedulerExecutionTimer">>},
     {?CFG_DB_SCHED_SPIN_TIME, <<"SchedulerSpinTimer">>},
     {?CFG_DB_MT_BUILD_INDEX, <<"BuildIndexThreads">>},
     {?CFG_DB_2PASS_INR, <<"TwoPassInitialNodeRestartCopy">>},
     {?CFG_DB_NUMA, <<"Numa">>},
     %% -- "Multi-Threading Configuration Parameters (ndbmtd)" --
     {?CFG_DB_MT_THREADS, <<"MaxNoOfExecutionThreads">>},
     {?CFG_DB_NO_REDOLOG_PARTS, <<"NoOfFragmentLogParts">>},
     {?CFG_DB_MT_THREAD_CONFIG, <<"ThreadConfig">>},
     %% -- "Disk Data Configuration Parameters" --
     {?CFG_DB_DISK_PAGE_BUFFER_MEMORY, <<"DiskPageBufferMemory">>},
     {?CFG_DB_SGA, <<"SharedGlobalMemory">>},
     {?CFG_DB_THREAD_POOL, <<"DiskIOThreadPool">>},
     %% -- "Disk Data file system parameters" --
     {?CFG_DB_DD_FILESYSTEM_PATH, <<"FileSystemPathDD">>},
     {?CFG_DB_DD_DATAFILE_PATH, <<"FileSystemPathDataFiles">>},
     {?CFG_DB_DD_UNDOFILE_PATH, <<"FileSystemPathUndoFiles">>},
     %% -- "Disk Data object creation parameters" --
     {?CFG_DB_DD_LOGFILEGROUP_SPEC, <<"InitialLogFileGroup">>},
     {?CFG_DB_DD_TABLEPACE_SPEC, <<"InitialTablespace">>},
     %% -- "Parameters for configuring send buffer memory allocation" --
     {?CFG_EXTRA_SEND_BUFFER_MEMORY, <<"ExtraSendBufferMemory">>},
     {?CFG_TOTAL_SEND_BUFFER_MEMORY, <<"TotalSendBufferMemory">>},
     {?CFG_RESERVED_SEND_BUFFER_MEMORY, <<"ReservedSendBufferMemory">>}, % deprecated
     %% -- "Redo log over-commit handling" --
     {?CFG_DB_REDO_OVERCOMMIT_COUNTER, <<"RedoOverCommitCounter">>},
     {?CFG_DB_REDO_OVERCOMMIT_LIMIT, <<"RedoOverCommitLimit">>},
     %% -- "Controlling restart attempts" --
     {?CFG_DB_START_FAIL_DELAY_SECS, <<"StartFailRetryDelay">>},
     {?CFG_DB_MAX_START_FAIL, <<"MaxStartFailRetries">>},
     %% -- "NDB index statistics parameters" --
     {?CFG_DB_INDEX_STAT_AUTO_CREATE, <<"IndexStatAutoCreate">>},
     {?CFG_DB_INDEX_STAT_AUTO_UPDATE, <<"IndexStatAutoUpdate">>},
     {?CFG_DB_INDEX_STAT_SAVE_SIZE, <<"IndexStatSaveSize">>},
     {?CFG_DB_INDEX_STAT_SAVE_SCALE, <<"IndexStatSaveScale">>},
     {?CFG_DB_INDEX_STAT_TRIGGER_PCT, <<"IndexStatTriggerPct">>},
     {?CFG_DB_INDEX_STAT_TRIGGER_SCALE, <<"IndexStatTriggerScale">>},
     {?CFG_DB_INDEX_STAT_UPDATE_DELAY, <<"IndexStatUpdateDelay">>},
     %% -- ? --
     {?CFG_DB_STOP_ON_ERROR_INSERT, <<"RestartOnErrorInsert">>},
     {?CFG_DB_PARALLEL_BACKUPS, <<"ParallelBackups">>},
     {?CFG_NDBMT_LQH_THREADS, <<"__ndbmt_lqh_threads">>},
     {?CFG_NDBMT_LQH_WORKERS, <<"__ndbmt_lqh_workers">>},
     {?CFG_NDBMT_CLASSIC, <<"__ndbmt_classic">>},
     {?CFG_DB_AT_RESTART_SKIP_INDEXES, <<"__at_restart_skip_indexes">>},
     {?CFG_DB_AT_RESTART_SKIP_FKS, <<"__at_restart_skip_fks">>},
     {?CFG_DB_AT_RESTART_SUBSCRIBER_CONNECT_TIMEOUT,  <<"RestartSubscriberConnectTimeout">>}
    ];
names(?CFG_SECTION_NODE, ?NODE_TYPE_API) ->
    %%
    %% @see
    %%  http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-api-definition.html
    %%
    [
     %%{-1, <<"ConnectionMap">>},
     {?CFG_NODE_ID, <<"NodeId">>},
     %%{-1, <<"ExecuteOnComputer">>},
     {?CFG_NODE_HOST, <<"HostName">>},
     {?CFG_NODE_ARBIT_RANK, <<"ArbitrationRank">>},
     {?CFG_NODE_ARBIT_DELAY, <<"ArbitrationDelay">>},
     {?CFG_BATCH_BYTE_SIZE, <<"BatchByteSize">>},
     {?CFG_BATCH_SIZE, <<"BatchSize">>},
     {?CFG_EXTRA_SEND_BUFFER_MEMORY, <<"ExtraSendBufferMemory">>},
     {?CFG_HB_THREAD_PRIO, <<"HeartbeatThreadPriority">>},
     {?CFG_MAX_SCAN_BATCH_SIZE, <<"MaxScanBatchSize">>},
     {?CFG_TOTAL_SEND_BUFFER_MEMORY, <<"TotalSendBufferMemory">>},
     {?CFG_AUTO_RECONNECT, <<"AutoReconnect">>},
     {?CFG_DEFAULT_OPERATION_REDO_PROBLEM_ACTION, <<"DefaultOperationRedoProblemAction">>},
     {?CFG_DEFAULT_HASHMAP_SIZE, <<"DefaultHashMapSize">>},
     %%{-1, <<"Wan">>},
     {?CFG_CONNECT_BACKOFF_MAX_TIME, <<"ConnectBackoffMaxTime">>},
     {?CFG_START_CONNECT_BACKOFF_MAX_TIME, <<"StartConnectBackoffMaxTime">>}
    ];
names(?CFG_SECTION_CONNECTION, ?CONNECTION_TYPE_TCP) ->
    %%
    %% @see
    %%  http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-tcp-definition.html
    %%
    [
     {?CFG_CONNECTION_NODE_1, <<"NodeId1">>},
     {?CFG_CONNECTION_NODE_2, <<"NodeId2">>},
     {?CFG_CONNECTION_HOSTNAME_1, <<"HostName1">>},
     {?CFG_CONNECTION_HOSTNAME_2, <<"HostName2">>},
     {?CFG_CONNECTION_OVERLOAD, <<"OverloadLimit">>},
     {?CFG_TCP_SEND_BUFFER_SIZE, <<"SendBufferMemory">>},
     {?CFG_CONNECTION_SEND_SIGNAL_ID, <<"SendSignalId">>},
     {?CFG_CONNECTION_CHECKSUM, <<"Checksum">>},
     {?CFG_CONNECTION_SERVER_PORT, <<"PortNumber">>}, % OBSOLETE
     {?CFG_TCP_RECEIVE_BUFFER_SIZE, <<"ReceiveBufferMemory">>},
     {?CFG_TCP_RCV_BUF_SIZE, <<"TCP_RCV_BUF_SIZE">>},
     {?CFG_TCP_SND_BUF_SIZE, <<"TCP_SND_BUF_SIZE">>},
     {?CFG_TCP_MAXSEG_SIZE, <<"TCP_MAXSEG_SIZE">>},
     {?CFG_TCP_BIND_INADDR_ANY, <<"TcpBind_INADDR_ANY">>},
     %% -- ? --
     {?CFG_CONNECTION_GROUP, <<"Group">>},
     {?CFG_CONNECTION_NODE_ID_SERVER, <<"NodeIdServer">>},
     {?CFG_TCP_PROXY, <<"Proxy">>}
    ].
%%
%% @see
%%  CFG_SECTION_CONNECTION, CONNECTION_TYPE_SHM ->
%%    http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-shm-definition.html
%%  CFG_SECTION_CONNECTION, CONNECTION_TYPE_SCI ->
%%    http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-sci-definition.html
%%  CFG_SECTION_CONNECTION, CONNECTION_TYPE_OSE ->
%%    ?
%%
