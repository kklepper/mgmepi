%% =============================================================================
%% Copyright 2013-2014 AONO Tomohiko
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

%% -- public --
-export([unpack/1, unpack/2, unpack/3]).
-export([get_connection/3]).

-export([config/2]). % TODO

%% -- private --

%% -- storage/ndb/include/util/ConfigValues.hpp --

%% enum: ConfigValues::ValueType
-define(VALUETYPE_INT,     1).
-define(VALUETYPE_STRING,  2).
-define(VALUETYPE_SECTION, 3).
-define(VALUETYPE_INT64,   4).

%% -- storage/ndb/src/common/util/ConfigValues.cpp --

-define(KEYVAL(I),  (I band 16#00003FFF)).          % KP_KEYVAL_(MASK|SHIFT)
-define(SECTION(I), (I band (16#00003FFF bsl 14))). % KP_SECTION_(MASK|SHIFT)
-define(TYPE(I),    ((I bsr 28) band 16#0000000F)). % KP_TYPE_(MASK|SHIFT)

%% == public ==

%% @see storage/ndb/src/common/util/ConfigValues.cpp: ConfigValuesFactory::unpack/2

-spec unpack(binary()) -> proplists:proplist().
unpack(Binary)
  when is_binary(Binary) ->
    unpack(Binary, big). % TODO

-spec unpack(binary(),atom()) -> proplists:proplist().
unpack(Binary, Endianess)
  when is_binary(Binary), is_atom(Endianess) ->
    unpack(Binary, Endianess, byte_size(Binary)).

-spec unpack(binary(),atom(),non_neg_integer()) -> proplists:proplist().
unpack(Binary, Endianess, Size)
  when is_binary(Binary), is_atom(Endianess), is_integer(Size), 12 =< Size, 0 == Size rem 4 ->
    M = binary:part(Binary, 0, 8),
    C = binary:decode_unsigned(binary:part(Binary,Size,-4), Endianess),
    case {M, checksum(Binary,Size-4,0)} of
        {<<"NDBCONFV">>, C}->
            unpack(Binary, 8, Size-12, Endianess, []);
        _ ->
            {error, eproto}
    end;
unpack(_Binary, _Endianess, _Size) ->
    {error, badarg}.


-spec get_connection([proplists:proplist()],integer(),atom()) -> [proplists:proplist()].
get_connection(List, Node, tcp)
  when is_list(List), is_integer(Node) ->
    F = fun (L) ->
                lists:member({?CFG_CONNECTION_NODE_1,Node}, L)
                    orelse lists:member({?CFG_CONNECTION_NODE_2,Node}, L)
        end,
    filter(List, ?CFG_SECTION_CONNECTION, ?CONNECTION_TYPE_TCP, F). % unzup?, TODO

%% === private ===

checksum(Binary, Size, Digit) ->
    lists:foldl(fun(E,A) -> A bxor binary:decode_unsigned(E) end, Digit,
                [ binary:part(Binary,E,4) || E <- lists:seq(0,Size-1,4) ]).

filter(List, Section, Type, Fun) ->
    case lists:keyfind(Section, 1, List) of
        {Section, L} ->
            [ E || E <- L, lists:member({?CFG_TYPE_OF_SECTION,Type},E), Fun(E) ]
    end.


unpack(_Binary, _Pos, 0, _Endianess, [{S,_,_}|_]=L) ->
    zip(S, L, [], []);
unpack(Binary, Pos, Len, Endianess, List) ->
    {I, PI} = unpack_integer(Binary, Pos, Endianess),
    {V, PV} = unpack_value(?TYPE(I), Binary, PI, Endianess),
    unpack(Binary, PV, Len-(PV-Pos), Endianess, [{?SECTION(I),?KEYVAL(I),V}|List]).

unpack_binary(Binary, Pos, Endianess) ->
    {L, P} = unpack_integer(Binary, Pos, Endianess),
    S = 4 - (L rem 4),                  % right-aligned
    {binary:part(Binary,P,L-1), P+L+S}. % ignore '\0'

unpack_integer(Binary, Pos, big) ->
    <<I:4/integer-signed-big-unit:8>> = binary:part(Binary, Pos, 4),
    {I, Pos+4};
unpack_integer(Binary, Pos, little) ->
    <<I:4/integer-signed-little-unit:8>> = binary:part(Binary, Pos, 4),
    {I, Pos+4}.

unpack_long(Binary, Pos, Endianess) ->
    {H, PH} = unpack_integer(Binary, Pos, Endianess),
    {L, PL} = unpack_integer(Binary, PH,  Endianess),
    {(H bsl 32) bor L, PL}.

unpack_value(?VALUETYPE_INT, Binary, Pos, Endianess) ->
    unpack_integer(Binary, Pos, Endianess);
unpack_value(?VALUETYPE_STRING, Binary, Pos, Endianess) ->
    unpack_binary(Binary, Pos, Endianess);
unpack_value(?VALUETYPE_INT64, Binary, Pos, Endianess) ->
    unpack_long(Binary, Pos, Endianess);
unpack_value(?VALUETYPE_SECTION, Binary, Pos, Endianess) ->
    unpack_integer(Binary, Pos, Endianess).


zip(List) ->
    case lists:keyfind(0, 1, List) of
        {0, L} ->
            [ {S,zip(K,List)} || {S,K} <- L ]
    end.

zip(Key, List) ->
    case lists:keyfind(Key, 1, List) of
        {Key, V} ->
            case lists:keyfind(?CFG_TYPE_OF_SECTION, 1, V) of
                false ->
                    [ zip(I,List) || {_,I} <- V ];
                _ ->
                    V
            end
    end.

zip(Section, [], List1, List2) ->
    zip([{Section,List1}|List2]);
zip(Section, [{Section,K,V}|T], List1, List2) ->
    zip(Section, T, [{K,V}|List1], List2);
zip(Previous, [{Section,K,V}|T], List1, List2) ->
    zip(Section, T, [{K,V}], [{Previous,List1}|List2]).

%% ---

%% storage/ndb/src/mgmsrv/ConfigInfo.cpp

config(?CFG_SECTION_SYSTEM, ?CFG_SECTION_SYSTEM) ->
    [
     {?CFG_SYS_NAME, str, <<"Name">>},
     {?CFG_SYS_PRIMARY_MGM_NODE, int, <<"PrimaryMGMNode">>},
     {?CFG_SYS_CONFIG_GENERATION, int, <<"ConfigGenerationNumber">>}
    ];
config(?CFG_SECTION_NODE, ?NODE_TYPE_DB) ->
    %% http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-ndbd-definition.html
    [
     %% -- Identifying data nodes --
     {?CFG_NODE_ID, int, <<"NodeId">>},
     {-1, str, <<"ExecuteOnComputer">>},
     {?CFG_NODE_HOST, str, <<"HostName">>},
     {-1, int, <<"ServerPort">>},
     {?CFG_TCP_BIND_INADDR_ANY, int, <<"TcpBind_INADDR_ANY">>},
     {?CFG_DB_NODEGROUP, int, <<"NodeGroup">>},
     {?CFG_DB_NO_REPLICAS, int, <<"NoOfReplicas">>},
     {?CFG_NODE_DATADIR, str, <<"DataDir">>},
     {?CFG_DB_FILESYSTEM_PATH, str, <<"FileSystemPath">>},
     {?CFG_DB_BACKUP_DATADIR, str, <<"BackupDataDir">>},
     %% -- Data Memory, Index Memory, and String Memory --
     {?CFG_DB_DATA_MEM, int, <<"DataMemory">>},
     {?CFG_DB_INDEX_MEM, int, <<"IndexMemory">>},
     {?CFG_DB_STRING_MEMORY, int, <<"StringMemory">>},
     {?CFG_DB_FREE_PCT, int, <<"MinFreePct">>},
     %% -- Transaction parameters --
     {?CFG_DB_NO_TRANSACTIONS, int, <<"MaxNoOfConcurrentTransactions">>},
     {?CFG_DB_NO_OPS, int, <<"MaxNoOfConcurrentOperations">>},
     {?CFG_DB_NO_LOCAL_OPS, int, <<"MaxNoOfLocalOperations">>},
     {?CFG_DB_MAX_DML_OPERATIONS_PER_TRANSACTION, int, <<"MaxDMLOperationsPerTransaction">>},
     %% -- Transaction temporary storage --
     {?CFG_DB_NO_INDEX_OPS, int, <<"MaxNoOfConcurrentIndexOperations">>},
     {?CFG_DB_NO_TRIGGER_OPS, int, <<"MaxNoOfFiredTriggers">>},
     {?CFG_DB_TRANS_BUFFER_MEM, int, <<"TransactionBufferMemory">>},
     %% -- Scans and buffering --
     {?CFG_DB_NO_SCANS, int, <<"MaxNoOfConcurrentScans">>},
     {?CFG_DB_NO_LOCAL_SCANS, int, <<"MaxNoOfLocalScans">>},
     {?CFG_DB_BATCH_SIZE, int, <<"BatchSizePerLocalScan">>},
     {?CFG_DB_LONG_SIGNAL_BUFFER, int, <<"LongMessageBuffer">>},
     {?CFG_DB_PARALLEL_SCANS_PER_FRAG, int, <<"MaxParallelScansPerFragment">>},
     %% -- Memory Allocation --
     {?CFG_DB_MAX_ALLOCATE, int, <<"MaxAllocate">>},
     %% -- Hash Map Size --
     {?CFG_DEFAULT_HASHMAP_SIZE, int, <<"DefaultHashMapSize">>},
     %% -- Logging and checkpointing --
     {?CFG_DB_NO_REDOLOG_FILES, int, <<"NoOfFragmentLogFiles">>},
     {?CFG_DB_REDOLOG_FILE_SIZE, int, <<"FragmentLogFileSize">>},
     {?CFG_DB_INIT_REDO, str, <<"InitFragmentLogFiles">>},
     {?CFG_DB_MAX_OPEN_FILES, int, <<"MaxNoOfOpenFiles">>},
     {?CFG_DB_INITIAL_OPEN_FILES, int, <<"InitialNoOfOpenFiles">>},
     {?CFG_DB_NO_SAVE_MSGS, int, <<"MaxNoOfSavedMessages">>},
     {?CFG_DB_LCP_TRY_LOCK_TIMEOUT, int, <<"MaxLCPStartDelay">>},
     %% -- Metadata objects --
     {?CFG_DB_NO_ATTRIBUTES, int, <<"MaxNoOfAttributes">>},
     {?CFG_DB_NO_TABLES, int, <<"MaxNoOfTables">>},
     {?CFG_DB_NO_ORDERED_INDEXES, int, <<"MaxNoOfOrderedIndexes">>},
     {?CFG_DB_NO_UNIQUE_HASH_INDEXES, int, <<"MaxNoOfUniqueHashIndexes">>},
     {?CFG_DB_NO_TRIGGERS, int, <<"MaxNoOfTriggers">>},
     {?CFG_DB_NO_INDEXES, int, <<"MaxNoOfIndexes">>}, % deprecated
     {?CFG_DB_SUBSCRIPTIONS, int, <<"MaxNoOfSubscriptions">>},
     {?CFG_DB_SUBSCRIBERS, int, <<"MaxNoOfSubscribers">>},
     {?CFG_DB_SUB_OPERATIONS, int, <<"MaxNoOfConcurrentSubOperations">>},
     %% -- Boolean parameters --
     {?CFG_DB_MEMLOCK, int, <<"LockPagesInMainMemory">>},
     {?CFG_DB_STOP_ON_ERROR, int, <<"StopOnError">>},
     {?CFG_DB_CRASH_ON_CORRUPTED_TUPLE, int, <<"CrashOnCorruptedTuple">>},
     {?CFG_DB_DISCLESS, int, <<"Diskless">>},
     {?CFG_DB_O_DIRECT, int, <<"ODirect">>},
     {?CFG_DB_STOP_ON_ERROR_INSERT, int, <<"RestartOnErrorInsert">>},
     {?CFG_DB_COMPRESSED_BACKUP, int, <<"CompressedBackup">>},
     {?CFG_DB_COMPRESSED_LCP, int, <<"CompressedLCP">>},
     %% -- Controlling Timeouts, Intervals, and Disk Paging --
     {?CFG_DB_WATCHDOG_INTERVAL, int, <<"TimeBetweenWatchDogCheck">>},
     {?CFG_DB_WATCHDOG_INTERVAL_INITIAL, int, <<"TimeBetweenWatchDogCheckInitial">>},
     {?CFG_DB_START_PARTIAL_TIMEOUT, int, <<"StartPartialTimeout">>},
     {?CFG_DB_START_PARTITION_TIMEOUT, int, <<"StartPartitionedTimeout">>},
     {?CFG_DB_START_FAILURE_TIMEOUT, int, <<"StartFailureTimeout">>},
     {?CFG_DB_START_NO_NODEGROUP_TIMEOUT, int, <<"StartNoNodeGroupTimeout">>},
     {?CFG_DB_HEARTBEAT_INTERVAL, int, <<"HeartbeatIntervalDbDb">>},
     {?CFG_DB_API_HEARTBEAT_INTERVAL, int, <<"HeartbeatIntervalDbApi">>},
     {?CFG_DB_HB_ORDER, int, <<"HeartbeatOrder">>},
     {?CFG_DB_CONNECT_CHECK_DELAY, int, <<"ConnectCheckIntervalDelay">>},
     {?CFG_DB_LCP_INTERVAL, int, <<"TimeBetweenLocalCheckpoints">>},
     {?CFG_DB_GCP_INTERVAL, int, <<"TimeBetweenGlobalCheckpoints">>},
     {?CFG_DB_MICRO_GCP_INTERVAL, int, <<"TimeBetweenEpochs">>},
     {?CFG_DB_MICRO_GCP_TIMEOUT, int, <<"TimeBetweenEpochsTimeout">>},
     {?CFG_DB_MAX_BUFFERED_EPOCHS, int, <<"MaxBufferedEpochs">>},
     {?CFG_DB_TRANSACTION_CHECK_INTERVAL, int, <<"TimeBetweenInactiveTransactionAbortCheck">>},
     {?CFG_DB_TRANSACTION_INACTIVE_TIMEOUT, int, <<"TransactionInactiveTimeout">>},
     {?CFG_DB_TRANSACTION_DEADLOCK_TIMEOUT, int, <<"TransactionDeadlockDetectionTimeout">>},
     {?CFG_DB_DISK_SYNCH_SIZE, int, <<"DiskSyncSize">>},
     {?CFG_DB_CHECKPOINT_SPEED, int, <<"DiskCheckpointSpeed">>},
     {?CFG_DB_CHECKPOINT_SPEED_SR, int, <<"DiskCheckpointSpeedInRestart">>},
     {?CFG_DB_LCP_DISC_PAGES_TUP, int, <<"NoOfDiskPagesToDiskAfterRestartTUP">>},
     {?CFG_DB_LCP_DISC_PAGES_ACC, int, <<"NoOfDiskPagesToDiskAfterRestartACC">>},
     {?CFG_DB_LCP_DISC_PAGES_TUP_SR, int, <<"NoOfDiskPagesToDiskDuringRestartTUP">>},
     {?CFG_DB_LCP_DISC_PAGES_ACC_SR, int, <<"NoOfDiskPagesToDiskDuringRestartACC">>},
     {?CFG_DB_ARBIT_TIMEOUT, int, <<"ArbitrationTimeout">>},
     {?CFG_DB_ARBIT_METHOD, str, <<"Arbitration">>},
     %% -- Buffering and logging --
     {?CFG_DB_UNDO_INDEX_BUFFER, int, <<"UndoIndexBuffer">>},
     {?CFG_DB_UNDO_DATA_BUFFER, int, <<"UndoDataBuffer">>},
     {?CFG_DB_REDO_BUFFER, int, <<"RedoBuffer">>},
     %% -- Controlling log messages --
     {?CFG_LOGLEVEL_STARTUP, int, <<"LogLevelStartup">>},
     {?CFG_LOGLEVEL_SHUTDOWN, int, <<"LogLevelShutdown">>},
     {?CFG_LOGLEVEL_STATISTICS, int, <<"LogLevelStatistic">>},
     {?CFG_LOGLEVEL_CHECKPOINT, int, <<"LogLevelCheckpoint">>},
     {?CFG_LOGLEVEL_NODERESTART, int, <<"LogLevelNodeRestart">>},
     {?CFG_LOGLEVEL_CONNECTION, int, <<"LogLevelConnection">>},
     {?CFG_LOGLEVEL_ERROR, int, <<"LogLevelError">>},
     {?CFG_LOGLEVEL_CONGESTION, int, <<"LogLevelCongestion">>},
     {?CFG_LOGLEVEL_INFO, int, <<"LogLevelInfo">>},
     {?CFG_DB_MEMREPORT_FREQUENCY, int, <<"MemReportFrequency">>},
     {?CFG_DB_STARTUP_REPORT_FREQUENCY, int, <<"StartupStatusReportFrequency">>},
     %% -- Debugging Parameters --
     {?CFG_DB_DICT_TRACE, int, <<"DictTrace">>},
     %% -- Backup parameters --
     {?CFG_DB_BACKUP_DATA_BUFFER_MEM, int, <<"BackupDataBufferSize">>},
     {?CFG_DB_BACKUP_LOG_BUFFER_MEM, int, <<"BackupLogBufferSize">>},
     {?CFG_DB_BACKUP_MEM, int, <<"BackupMemory">>},
     {?CFG_DB_BACKUP_REPORT_FREQUENCY, int, <<"BackupReportFrequency">>},
     {?CFG_DB_BACKUP_WRITE_SIZE, int, <<"BackupWriteSize">>},
     {?CFG_DB_BACKUP_MAX_WRITE_SIZE, int, <<"BackupMaxWriteSize">>},
     %% -- MySQL Cluster Realtime Performance Parameters --
     {?CFG_DB_EXECUTE_LOCK_CPU, int, <<"LockExecuteThreadToCPU">>},
     {?CFG_DB_MAINT_LOCK_CPU, int, <<"LockMaintThreadsToCPU">>},
     {?CFG_DB_REALTIME_SCHEDULER, int, <<"RealtimeScheduler">>},
     {?CFG_DB_SCHED_EXEC_TIME, int, <<"SchedulerExecutionTimer">>},
     {?CFG_DB_SCHED_SPIN_TIME, int, <<"SchedulerSpinTimer">>},
     {?CFG_DB_MT_BUILD_INDEX, int, <<"BuildIndexThreads">>},
     {?CFG_DB_2PASS_INR, int, <<"TwoPassInitialNodeRestartCopy">>},
     {?CFG_DB_NUMA, int, <<"Numa">>},
     %% -- Multi-Threading Configuration Parameters (ndbmtd) --
     {?CFG_DB_MT_THREADS, int, <<"MaxNoOfExecutionThreads">>},
     {?CFG_DB_NO_REDOLOG_PARTS, int, <<"NoOfFragmentLogParts">>},
     {?CFG_DB_MT_THREAD_CONFIG, str, <<"ThreadConfig">>},
     %% -- Disk Data Configuration Parameters --
     {?CFG_DB_DISK_PAGE_BUFFER_MEMORY, int, <<"DiskPageBufferMemory">>},
     {?CFG_DB_SGA, int, <<"SharedGlobalMemory">>},
     {?CFG_DB_THREAD_POOL, int, <<"DiskIOThreadPool">>},
     %% -- Disk Data file system parameters --
     {?CFG_DB_DD_FILESYSTEM_PATH, str, <<"FileSystemPathDD">>},
     {?CFG_DB_DD_DATAFILE_PATH, str, <<"FileSystemPathDataFiles">>},
     {?CFG_DB_DD_UNDOFILE_PATH, str, <<"FileSystemPathUndoFiles">>},
     %% -- Disk Data object creation parameters --
     {?CFG_DB_DD_LOGFILEGROUP_SPEC, str, <<"InitialLogFileGroup">>}, % InitialLogfileGroup?, TODO
     {?CFG_DB_DD_TABLEPACE_SPEC, str, <<"InitialTablespace">>},
     %% -- Parameters for configuring send buffer memory allocation --
     {?CFG_RESERVED_SEND_BUFFER_MEMORY, int, <<"ReservedSendBufferMemory">>}, % deprecated
     %% -- Redo log over-commit handling --
     {?CFG_DB_REDO_OVERCOMMIT_COUNTER, int, <<"RedoOverCommitCounter">>},
     {?CFG_DB_REDO_OVERCOMMIT_LIMIT, int, <<"RedoOverCommitLimit">>},
     %% -- Controlling restart attempts --
     {?CFG_DB_START_FAIL_DELAY_SECS, int, <<"StartFailRetryDelay">>},
     {?CFG_DB_MAX_START_FAIL, int, <<"MaxStartFailRetries">>},
     %% -- ? --
     {?CFG_DB_PARALLEL_BACKUPS, int, <<"ParallelBackups">>},
     {?CFG_MIN_LOGLEVEL, int, <<"?CFG_MIN_LOGLEVEL">>},
     {?CFG_DB_MAX_BUFFERED_EPOCH_BYTES, int, <<"MaxBufferedEpochBytes">>},
     {?CFG_DB_EVENTLOG_BUFFER_SIZE, int, <<"?CFG_DB_EVENTLOG_BUFFER_SIZE">>},
     {?CFG_DB_LATE_ALLOC, int, <<"LateAlloc">>},
     {?CFG_DB_INDEX_STAT_AUTO_CREATE, int, <<"IndexStatAutoCreate">>},
     {?CFG_DB_INDEX_STAT_AUTO_UPDATE, int, <<"IndexStatAutoUpdate">>},
     {?CFG_DB_INDEX_STAT_SAVE_SIZE, int, <<"IndexStatSaveSize">>},
     {?CFG_DB_INDEX_STAT_SAVE_SCALE, int, <<"IndexStatSaveScale">>},
     {?CFG_DB_INDEX_STAT_TRIGGER_PCT, int, <<"IndexStatTriggerPct">>},
     {?CFG_DB_INDEX_STAT_TRIGGER_SCALE, int, <<"IndexStatTriggerScale">>},
     {?CFG_DB_INDEX_STAT_UPDATE_DELAY, int, <<"IndexStatUpdateDelay">>}
    ];
config(?CFG_SECTION_NODE, ?NODE_TYPE_API) ->
    %% http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-api-definition.html
    [
     {?CFG_NODE_ID, int, <<"NodeId">>},
     { -1, str, <<"ExecuteOnComputer">>},
     {?CFG_NODE_HOST, str, <<"HostName">>},
     {?CFG_NODE_ARBIT_RANK, int, <<"ArbitrationRank">>},
     {?CFG_NODE_ARBIT_DELAY, int, <<"ArbitrationDelay">>},
     {?CFG_BATCH_BYTE_SIZE, int, <<"BatchByteSize">>},
     {?CFG_BATCH_SIZE, int, <<"BatchSize">>},
     {?CFG_HB_THREAD_PRIO, str, <<"HeartbeatThreadPriority">>},
     {?CFG_MAX_SCAN_BATCH_SIZE, int, <<"MaxScanBatchSize">>},
     {?CFG_TOTAL_SEND_BUFFER_MEMORY, int, <<"TotalSendBufferMemory">>},
     {?CFG_AUTO_RECONNECT, int, <<"AutoReconnect">>},
     {?CFG_DEFAULT_OPERATION_REDO_PROBLEM_ACTION, str, <<"DefaultOperationRedoProblemAction">>},
     {?CFG_DEFAULT_HASHMAP_SIZE, int, <<"DefaultHashMapSize">>}
    ];
config(?CFG_SECTION_NODE, ?NODE_TYPE_MGM) ->
    %% http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-mgm-definition.html
    [
     {?CFG_NODE_ID, int, <<"NodeId">>},
     { -1, str, <<"ExecuteOnComputer">>},
     {?CFG_MGM_PORT, int, <<"PortNumber">>},
     {?CFG_NODE_HOST, str, <<"HostName">>},
     {?CFG_LOG_DESTINATION, str, <<"LogDestination">>},
     {?CFG_NODE_ARBIT_RANK, int, <<"ArbitrationRank">>},
     {?CFG_NODE_ARBIT_DELAY, int, <<"ArbitrationDelay">>},
     {?CFG_NODE_DATADIR, str, <<"DataDir">>},
     {?CFG_EXTRA_SEND_BUFFER_MEMORY, int, <<"HeartbeatThreadPriority">>},
     {?CFG_TOTAL_SEND_BUFFER_MEMORY, int, <<"TotalSendBufferMemory">>}
    ];
config(?CFG_SECTION_CONNECTION, ?CONNECTION_TYPE_TCP) ->
    %% http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-tcp-definition.html
    [
     {?CFG_CONNECTION_NODE_1, int, <<"NodeId1">>},
     {?CFG_CONNECTION_NODE_2, int, <<"NodeId2">>},
     {?CFG_CONNECTION_HOSTNAME_1, str, <<"HostName1">>},
     {?CFG_CONNECTION_HOSTNAME_2, str, <<"HostName2">>},
     {?CFG_CONNECTION_OVERLOAD, int, <<"OverloadLimit">>},
     {?CFG_TCP_SEND_BUFFER_SIZE, int, <<"SendBufferMemory">>},
     {?CFG_CONNECTION_SEND_SIGNAL_ID, int, <<"SendSignalId">>},
     {?CFG_CONNECTION_CHECKSUM, int, <<"Checksum">>},
     {?CFG_CONNECTION_SERVER_PORT, int, <<"PortNumber">>}, % deprecated
     {?CFG_TCP_RECEIVE_BUFFER_SIZE, int, <<"ReceiveBufferMemory">>},
     {?CFG_TCP_RCV_BUF_SIZE, int, <<"TCP_RCV_BUF_SIZE">>},
     {?CFG_TCP_SND_BUF_SIZE, int, <<"TCP_SND_BUF_SIZE">>},
     %%
     {?CFG_CONNECTION_NODE_1_SYSTEM, str, <<"NodeId1_System">>},
     {?CFG_CONNECTION_NODE_2_SYSTEM, str, <<"NodeId2_System">>},
     {?CFG_CONNECTION_GROUP, int, <<"Group">>},
     {?CFG_CONNECTION_NODE_ID_SERVER, int, <<"NodeIdServer">>},
     {?CFG_TCP_PROXY, str, <<"Proxy">>},
     {?CFG_TCP_MAXSEG_SIZE, int, <<"TCP_MAXSEG_SIZE">>}
    ].
%% config(?CFG_SECTION_CONNECTION, ?CONNECTION_TYPE_SHM) ->
%%     %% http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-shm-definition.html
%%     [
%%      {?CFG_CONNECTION_NODE_1, int, <<"NodeId1">>},
%%      {?CFG_CONNECTION_NODE_2, int, <<"NodeId2">>},
%%      {?CFG_CONNECTION_HOSTNAME_1, str, <<"HostName1">>},
%%      {?CFG_CONNECTION_HOSTNAME_2, str, <<"HostName2">>},
%%      {?CFG_SHM_KEY, int, <<"ShmKey">>},
%%      {?CFG_SHM_BUFFER_MEM, int, <<"ShmSize">>},
%%      {?CFG_SHM_SEND_SIGNAL_ID, int, <<"SendSignalId">>},
%%      {?CFG_SHM_CHECKSUM, int, <<"Checksum">>},
%%      {?CFG_SHM_SIGNUM, int, <<"SigNum">>}
%%     ];
%% config(?CFG_SECTION_CONNECTION, ?CONNECTION_TYPE_SCI) ->
%%     %% http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-sci-definition.html
%%     [
%%      {?CFG_CONNECTION_NODE_1, int, <<"NodeId1">>},
%%      {?CFG_CONNECTION_NODE_2, int, <<"NodeId2">>},
%%      {?CFG_SCI_HOST1_ID_0, int, <<"Host1SciId0">>},
%%      {?CFG_SCI_HOST1_ID_1, int, <<"Host1SciId1">>},
%%      {?CFG_SCI_HOST2_ID_0, int, <<"Host2SciId0">>},
%%      {?CFG_SCI_HOST2_ID_1, int, <<"Host2SciId1">>},
%%      {?CFG_CONNECTION_HOSTNAME_1, str, <<"HostName1">>},
%%      {?CFG_CONNECTION_HOSTNAME_2, str, <<"HostName2">>},
%%      {?CFG_SCI_BUFFER_MEM, int, <<"SharedBufferSize">>},
%%      {?CFG_SCI_SEND_LIMIT, int, <<"SendLimit">>},
%%      {?CFG_CONNECTION_SEND_SIGNAL_ID, int, <<"SendSignalId">>},
%%      {?CFG_CONNECTION_CHECKSUM, int, <<"Checksum">>},
%%      {?CFG_CONNECTION_OVERLOAD, int, <<"OverloadLimit">>}
%%     ];
%% config(?CFG_SECTION_CONNECTION, ?CONNECTION_TYPE_OSE) ->
%%     [
%%      %% TODO
%%     ].
