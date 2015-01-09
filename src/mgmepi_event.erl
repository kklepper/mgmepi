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

-module(mgmepi_event).

-include("../include/mgmepi_event.hrl").

%% -- private --
-export([params/1]).

%% == private ==

%% @see
%%  ~/src/mgmapi/ndb_logevent.cpp: ndb_logevent_body
%%  ~/src/kernel/bloks/dblqh/DblqhMain.cpp: logfileInitCompleteReport/1
%%  ~/src/kernel/vm/FastScheduler.cpp: reportThreadConfigLoop/6

%% -- NDB_MGM_EVENT_CATEGORY_STARTUP --
params(?NDB_LE_NDBStartStarted) -> % INFO,1
    [
     {<<"version">>, integer, mandatory}
    ];
params(?NDB_LE_NDBStartCompleted) -> % INFO,1
    [
     {<<"version">>, integer, mandatory}
    ];
params(?NDB_LE_STTORRYRecieved) -> % INFO,15
    [
     {<<"unused">>, integer, mandatory}
    ];
params(?NDB_LE_StartPhaseCompleted) -> % INFO,4
    [
     {<<"phase">>, integer, mandatory},
     {<<"starttype">>, integer, mandatory}
    ];
params(?NDB_LE_CM_REGCONF) -> % INFO,3
    [
     {<<"own_id">>, integer, mandatory},
     {<<"president_id">>, integer, mandatory},
     {<<"dynamic_id">>, integer, mandatory}
    ];
params(?NDB_LE_CM_REGREF) -> % INFO,8
    [
     {<<"own_id">>, integer, mandatory},
     {<<"other_id">>, integer, mandatory},
     {<<"dynamic_id">>, integer, mandatory}
    ];
params(?NDB_LE_FIND_NEIGHBOURS) -> % INFO,8
    [
     {<<"own_id">>, integer, mandatory},
     {<<"left_id">>, integer, mandatory},
     {<<"right_id">>, integer, mandatory},
     {<<"dynamic_id">>, integer, mandatory}
    ];
params(?NDB_LE_NDBStopStarted) -> % INFO,1
    [
     {<<"stoptype">>, integer, mandatory}
    ];
params(?NDB_LE_NDBStopCompleted) -> % INFO,1
    [
     {<<"action">>, integer, mandatory},
     {<<"signum">>, integer, mandatory}
    ];
params(?NDB_LE_NDBStopForced) -> % ALERT,1
    [
     {<<"action">>, integer, mandatory},
     {<<"signum">>, integer, mandatory},
     {<<"error">>, integer, mandatory},
     {<<"sphase">>, integer, mandatory},
     {<<"extra">>, integer, mandatory}
    ];
params(?NDB_LE_NDBStopAborted) -> % INFO,1
    [
     {<<"_unused">>, integer, mandatory}
    ];
params(?NDB_LE_StartREDOLog) -> % INFO,4
    [
     {<<"node">>, integer, mandatory},
     {<<"keep_gci">>, integer, mandatory},
     {<<"completed_gci">>, integer, mandatory},
     {<<"restorable_gci">>, integer, mandatory}
    ];
params(?NDB_LE_StartLog) -> % INFO,10
    [
     {<<"log_part">>, integer, mandatory},
     {<<"start_mb">>, integer, mandatory},
     {<<"stop_mb">>, integer, mandatory},
     {<<"gci">>, integer, mandatory}
    ];
params(?NDB_LE_UNDORecordsExecuted) -> % INFO,15
    [
     {<<"block">>, integer, mandatory},
     {<<"data1">>, integer, mandatory},
     {<<"data2">>, integer, mandatory},
     {<<"data3">>, integer, mandatory},
     {<<"data4">>, integer, mandatory},
     {<<"data5">>, integer, mandatory},
     {<<"data6">>, integer, mandatory},
     {<<"data7">>, integer, mandatory},
     {<<"data8">>, integer, mandatory},
     {<<"data9">>, integer, mandatory},
     {<<"data10">>, integer, mandatory}
    ];
params(?NDB_LE_StartReport) -> % INFO,4
    [
     {<<"report_type">>, integer, mandatory},
     {<<"remaining_time">>, integer, mandatory},
     {<<"bitmask_size">>, integer, mandatory},
     {<<"bitmask_data">>, integer, mandatory} % [1]?
    ];
params(?NDB_LE_LogFileInitStatus) -> % INFO,7
    [
     {<<"node_id">>, integer, mandatory},
     {<<"total_files">>, integer, mandatory},
     {<<"file_done">>, integer, mandatory},
     {<<"total_mbytes">>, integer, mandatory},
     {<<"mbytes_done">>, integer, mandatory}
    ];
params(?NDB_LE_LogFileInitCompStatus) -> % INFO,7
    [
     {<<"reference">>, integer, mandatory},
     {<<"total_log_files">>, integer, mandatory},
     {<<"log_file_init_done">>, integer, mandatory},
     {<<"total_log_mbytes">>, integer, mandatory},
     {<<"log_mbytes_init_done">>, integer, mandatory}
    ];
params(?NDB_LE_StartReadLCP) -> % INFO,10
    [
     {<<"tableid">>, integer, mandatory},
     {<<"fragmentid">>, integer, mandatory}
    ];
params(?NDB_LE_ReadLCPComplete) -> % INFO,10
    [
     {<<"tableid">>, integer, mandatory},
     {<<"fragmentid">>, integer, mandatory},
     {<<"rows_hi">>, integer, mandatory},
     {<<"rows_lo">>, integer, mandatory}
    ];
params(?NDB_LE_RunRedo) -> % INFO,8
    [
     {<<"logpart">>, integer, mandatory},
     {<<"phase">>, integer, mandatory},
     {<<"startgci">>, integer, mandatory},
     {<<"currgci">>, integer, mandatory},
     {<<"stopgci">>, integer, mandatory},
     {<<"startfile">>, integer, mandatory},
     {<<"startmb">>, integer, mandatory},
     {<<"currfile">>, integer, mandatory},
     {<<"currmb">>, integer, mandatory},
     {<<"stopfile">>, integer, mandatory},
     {<<"stopmb">>, integer, mandatory}
    ];
params(?NDB_LE_RebuildIndex) -> % INFO,10
    [
     {<<"instance">>, integer, mandatory},
     {<<"indexid">>, integer, mandatory}
    ];

%% -- NDB_MGM_EVENT_CATEGORY_SHUTDOWN --
%%
%% -- NDB_MGM_EVENT_CATEGORY_STATISTIC --
params(?NDB_LE_TransReportCounters) -> % INFO,8
    [
     {<<"trans_count">>, integer, mandatory},
     {<<"commit_count">>, integer, mandatory},
     {<<"read_count">>, integer, mandatory},
     {<<"simple_read_count">>, integer, mandatory},
     {<<"write_count">>, integer, mandatory},
     {<<"attrinfo_count">>, integer, mandatory},
     {<<"conc_op_count">>, integer, mandatory},
     {<<"abort_count">>, integer, mandatory},
     {<<"scan_count">>, integer, mandatory},
     {<<"range_scan_count">>, integer, mandatory}
    ];
params(?NDB_LE_OperationReportCounters) -> % INFO,8
    [
     {<<"ops">>, integer, mandatory}
    ];
params(?NDB_LE_TableCreated) -> % INFO,7
    [
     {<<"table_id">>, integer, mandatory}
    ];
params(?NDB_LE_JobStatistic) -> % INFO,9
    [
     {<<"mean_loop_count">>, integer, mandatory}
    ];
params(?NDB_LE_ThreadConfigLoop) -> % INFO,9
    [
     {<<"expired_time">>, integer, mandatory},
     {<<"extra_constant">>, integer, mandatory},
     {<<"exec_time">>, integer, mandatory}, % tot_exec_time / no_exec_loops
     {<<"no_extra_loops">>, integer, mandatory},
     {<<"extra_time">>, integer, mandatory} % tot_extra_time / no_extra_loops
    ];
params(?NDB_LE_SendBytesStatistic) -> % INFO,9
    [
     {<<"to_node">>, integer, mandatory},
     {<<"mean_sent_bytes">>, integer, mandatory}
    ];
params(?NDB_LE_ReceiveBytesStatistic) -> % INFO,9
    [
     {<<"from_node">>, integer, mandatory},
     {<<"mean_received_bytes">>, integer, mandatory}
    ];
params(?NDB_LE_MemoryUsage) -> % INFO,5
    [
     {<<"gh">>, integer, mandatory},
     {<<"page_size_bytes">>, integer, mandatory}, % page_size_kb?
     {<<"page_used">>, integer, mandatory},
     {<<"page_total">>, integer, mandatory},
     {<<"block">>, integer, mandatory}
    ];
params(?NDB_LE_MTSignalStatistics) -> % INFO,9
    [
     {<<"thr_no">>, integer, mandatory},
     {<<"prioa_count">>, integer, mandatory},
     {<<"prioa_size">>, integer, mandatory},
     {<<"priob_count">>, integer, mandatory},
     {<<"priob_size">>, integer, mandatory}
    ];
%% -- NDB_MGM_EVENT_CATEGORY_CHECKPOINT --
params(?NDB_LE_GlobalCheckpointStarted) -> % INFO,9
    [
     {<<"gci">>, integer, mandatory}
    ];
params(?NDB_LE_GlobalCheckpointCompleted) -> % INFO,10
    [
     {<<"gci">>, integer, mandatory}
    ];
params(?NDB_LE_LocalCheckpointStarted) -> % INFO,7
    [
     {<<"lci">>, integer, mandatory},
     {<<"keep_gci">>, integer, mandatory},
     {<<"restore_gci">>, integer, mandatory}
    ];
params(?NDB_LE_LocalCheckpointCompleted) -> % INFO,7
    [
     {<<"lci">>, integer, mandatory}
    ];
params(?NDB_LE_LCPStoppedInCalcKeepGci) -> % ALERT,0
    [
     {<<"data">>, integer, mandatory}
    ];
params(?NDB_LE_LCPFragmentCompleted) -> % INFO,11
    [
     {<<"node">>, integer, mandatory},
     {<<"table_id">>, integer, mandatory},
     {<<"fragment_id">>, integer, mandatory}
    ];
params(?NDB_LE_UndoLogBlocked) -> % INFO,7
    [
     {<<"acc_count">>, integer, mandatory},
     {<<"tup_count">>, integer, mandatory}
    ];
params(?NDB_LE_RedoStatus) -> % INFO,7
    [
     {<<"log_part">>, integer, mandatory},
     {<<"head_file_no">>, integer, mandatory},
     {<<"head_mbyte">>, integer, mandatory},
     {<<"tail_file_no">>, integer, mandatory},
     {<<"tail_mbyte">>, integer, mandatory},
     {<<"total_hi">>, integer, mandatory},
     {<<"total_lo">>, integer, mandatory},
     {<<"free_hi">>, integer, mandatory},
     {<<"free_lo">>, integer, mandatory},
     {<<"no_logfiles">>, integer, mandatory},
     {<<"logfilesize">>, integer, mandatory}
    ];
%% -- NDB_MGM_EVENT_CATEGORY_NODE_RESTART --
params(?NDB_LE_NR_CopyDict) -> % INFO,7
    [
     {<<"_unused">>, integer, mandatory}
    ];
params(?NDB_LE_NR_CopyDistr) -> % INFO,7
    [
     {<<"_unused">>, integer, mandatory}
    ];
params(?NDB_LE_NR_CopyFragsStarted) -> % INFO,7
    [
     {<<"dest_node">>, integer, mandatory}
    ];
params(?NDB_LE_NR_CopyFragDone) -> % INFO,10
    [
     {<<"dest_node">>, integer, mandatory},
     {<<"table_id">>, integer, mandatory},
     {<<"fragment_id">>, integer, mandatory}
    ];
params(?NDB_LE_NR_CopyFragsCompleted) -> % INFO,7
    [
     {<<"dest_node">>, integer, mandatory}
    ];
params(?NDB_LE_NodeFailCompleted) -> % ALERT,8
    [
     {<<"block">>, integer, mandatory},
     {<<"failed_node">>, integer, mandatory},
     {<<"completing_node">>, integer, mandatory}
    ];
params(?NDB_LE_NODE_FAILREP) -> % ALERT,8
    [
     {<<"failed_node">>, integer, mandatory},
     {<<"failure_state">>, integer, mandatory}
    ];
params(?NDB_LE_ArbitState) -> % INFO,6
    [
     {<<"code">>, integer, mandatory},
     {<<"arbit_node">>, integer, mandatory},
     {<<"ticket_0">>, integer, mandatory},
     {<<"ticket_1">>, integer, mandatory}
    ];
params(?NDB_LE_ArbitResult) -> % ALERT,2
    [
     {<<"code">>, integer, mandatory},
     {<<"arbit_node">>, integer, mandatory},
     {<<"ticket_0">>, integer, mandatory},
     {<<"ticket_1">>, integer, mandatory}
    ];
params(?NDB_LE_GCP_TakeoverStarted) -> % INFO,7
    [
     {<<"_unused">>, integer, mandatory}
    ];
params(?NDB_LE_GCP_TakeoverCompleted) -> % INFO,7
    [
     {<<"_unused">>, integer, mandatory}
    ];
params(?NDB_LE_LCP_TakeoverStarted) -> % INFO,7
    [
     {<<"_unused">>, integer, mandatory}
    ];
params(?NDB_LE_LCP_TakeoverCompleted) -> % INFO,7
    [
     {<<"state">>, integer, mandatory}
    ];
params(?NDB_LE_ConnectCheckStarted) -> % INFO,6
    [
     {<<"other_node_count">>, integer, mandatory},
     {<<"reason">>, integer, mandatory},
     {<<"causing_node">>, integer, mandatory}
    ];
params(?NDB_LE_ConnectCheckCompleted) -> % INFO,6
    [
     {<<"nodes_checked">>, integer, mandatory},
     {<<"nodes_suspect">>, integer, mandatory},
     {<<"nodes_failed">>, integer, mandatory}
    ];
params(?NDB_LE_NodeFailRejected) -> % ALERT,6
    [
     {<<"reason">>, integer, mandatory},
     {<<"failed_node">>, integer, mandatory},
     {<<"source_node">>, integer, mandatory}
    ];
%% -- NDB_MGM_EVENT_CATEGORY_CONNECTION --
params(?NDB_LE_Connected) -> % ,INFO,8
    [
     {<<"node">>, integer, mandatory}
    ];
params(?NDB_LE_Disconnected) -> % ALERT,8
    [
     {<<"node">>, integer, mandatory}
    ];
params(?NDB_LE_CommunicationClosed) -> % INFO,8
    [
     {<<"node">>, integer, mandatory}
    ];
params(?NDB_LE_CommunicationOpened) -> % INFO,8
    [
     {<<"node">>, integer, mandatory}
    ];
params(?NDB_LE_ConnectedApiVersion) -> % INFO,8
    [
     {<<"node">>, integer, mandatory},
     {<<"version">>, integer, mandatory}
    ];
%% -- NDB_MGM_EVENT_CATEGORY_BACKUP --
params(?NDB_LE_BackupStarted) -> % INFO,7
    [
     {<<"starting_node">>, integer, mandatory},
     {<<"backup_id">>, integer, mandatory}
    ];
params(?NDB_LE_BackupStatus) -> % INFO,7
    [
     {<<"starting_node">>, integer, mandatory},
     {<<"backup_id">>, integer, mandatory},
     {<<"n_records_lo">>, integer, mandatory},
     {<<"n_records_hi">>, integer, mandatory},
     {<<"n_log_records_lo">>, integer, mandatory},
     {<<"n_log_records_hi">>, integer, mandatory},
     {<<"n_bytes_lo">>, integer, mandatory},
     {<<"n_bytes_hi">>, integer, mandatory},
     {<<"n_log_bytes_lo">>, integer, mandatory},
     {<<"n_log_bytes_hi">>, integer, mandatory}
    ];
params(?NDB_LE_BackupCompleted) -> % INFO,7
    [
     {<<"starting_node">>, integer, mandatory},
     {<<"backup_id">>, integer, mandatory},
     {<<"start_gci">>, integer, mandatory},
     {<<"stop_gci">>, integer, mandatory},
     {<<"n_records">>, integer, mandatory},
     {<<"n_log_records">>, integer, mandatory},
     {<<"n_bytes">>, integer, mandatory},
     {<<"n_log_bytes">>, integer, mandatory},
     {<<"n_records_hi">>, integer, mandatory},
     {<<"n_log_records_hi">>, integer, mandatory},
     {<<"n_bytes_hi">>, integer, mandatory},
     {<<"n_log_bytes_hi">>, integer, mandatory}
    ];
params(?NDB_LE_BackupFailedToStart) -> % ALERT,7
    [
     {<<"starting_node">>, integer, mandatory},
     {<<"error">>, integer, mandatory}
    ];
params(?NDB_LE_BackupAborted) -> % ALERT,7
    [
     {<<"starting_node">>, integer, mandatory},
     {<<"backup_id">>, integer, mandatory},
     {<<"error">>, integer, mandatory}
    ];
params(?NDB_LE_RestoreStarted) -> % INFO,7
    [
     {<<"backup_id">>, integer, mandatory},
     {<<"node_id">>, integer, mandatory}
    ];
params(?NDB_LE_RestoreMetaData) -> % INFO,7
    [
     {<<"backup_id">>, integer, mandatory},
     {<<"node_id">>, integer, mandatory},
     {<<"n_tables">>, integer, mandatory},
     {<<"n_tablespaces">>, integer, mandatory},
     {<<"n_logfilegroups">>, integer, mandatory},
     {<<"n_datafiles">>, integer, mandatory},
     {<<"n_undofiles">>, integer, mandatory}
    ];
params(?NDB_LE_RestoreData) -> % INFO,7
    [
     {<<"backup_id">>, integer, mandatory},
     {<<"node_id">>, integer, mandatory},
     {<<"n_records_lo">>, integer, mandatory},
     {<<"n_records_hi">>, integer, mandatory},
     {<<"n_bytes_lo">>, integer, mandatory},
     {<<"n_bytes_hi">>, integer, mandatory}
    ];
params(?NDB_LE_RestoreLog) -> % INFO,7
    [
     {<<"backup_id">>, integer, mandatory},
     {<<"node_id">>, integer, mandatory},
     {<<"n_records_lo">>, integer, mandatory},
     {<<"n_records_hi">>, integer, mandatory},
     {<<"n_bytes_lo">>, integer, mandatory},
     {<<"n_bytes_hi">>, integer, mandatory}
    ];
params(?NDB_LE_RestoreCompleted) -> % INFO,7
    [
     {<<"backup_id">>, integer, mandatory},
     {<<"node_id">>, integer, mandatory}
    ];
%% -- NDB_MGM_EVENT_CATEGORY_CONGESTION --
%%
%% -- NDB_MGM_EVENT_CATEGORY_DEBUG --
%%
%% -- NDB_MGM_EVENT_CATEGORY_INFO --
params(?NDB_LE_SentHeartbeat) -> % INFO,12
    [
     {<<"node">>, integer, mandatory}
    ];
params(?NDB_LE_CreateLogBytes) -> % INFO,11
    [
     {<<"node">>, integer, mandatory}
    ];
params(?NDB_LE_InfoEvent) -> % INFO,2
    [
     %%{<<"_unused">>, integer, mandatory} % TODO
     {<<"data">>, string, mandatory}
    ];
params(?NDB_LE_EventBufferStatus) -> % INFO,7
    [
     {<<"usage">>, integer, mandatory},
     {<<"alloc">>, integer, mandatory},
     {<<"max">>, integer, mandatory},
     {<<"apply_gci_l">>, integer, mandatory},
     {<<"apply_gci_h">>, integer, mandatory},
     {<<"latest_gci_l">>, integer, mandatory},
     {<<"latest_gci_h">>, integer, mandatory}
    ];
params(?NDB_LE_SingleUser) -> % INFO,7
    [
     {<<"type">>, integer, mandatory},
     {<<"node_id">>, integer, mandatory}
    ];
params(?NDB_LE_SavedEvent) -> % INFO,7
    [
     {<<"len">>, integer, mandatory},
     {<<"seq">>, integer, mandatory},
     {<<"time">>, integer, mandatory},
     {<<"data">>, integer, mandatory} % [1]
    ];
%% -- NDB_MGM_EVENT_CATEGORY_WARNING --
%%
%% -- NDB_MGM_EVENT_CATEGORY_ERROR --
params(?NDB_LE_TransporterError) -> % ERROR,2
    [
     {<<"to_node">>, integer, mandatory},
     {<<"code">>, integer, mandatory}
    ];
params(?NDB_LE_TransporterWarning) -> % WARNING,8
    [
     {<<"to_node">>, integer, mandatory},
     {<<"code">>, integer, mandatory}
    ];
params(?NDB_LE_MissedHeartbeat) -> % WARNING,8
    [
     {<<"node">>, integer, mandatory},
     {<<"count">>, integer, mandatory}
    ];
params(?NDB_LE_DeadDueToHeartbeat) -> % ALERT,8
    [
     {<<"node">>, integer, mandatory}
    ];
params(?NDB_LE_WarningEvent) -> % WARNING,2
    [
     {<<"_unused">>, integer, mandatory}
    ];
params(?NDB_LE_SubscriptionStatus) -> % WARMNING,4
    [
     {<<"report_type">>, integer, mandatory},
     {<<"node_id">>, integer, mandatory}
    ];
%% -- NDB_MGM_EVENT_CATEGORY_SCHEMA --
params(?NDB_LE_CreateSchemaObject) -> % INFO,8
    [
     {<<"objectid">>, integer, mandatory},
     {<<"version">>, integer, mandatory},
     {<<"type">>, integer, mandatory},
     {<<"node">>, integer, mandatory}
    ];
params(?NDB_LE_AlterSchemaObject) -> % INFO,8
    [
     {<<"objectid">>, integer, mandatory},
     {<<"version">>, integer, mandatory},
     {<<"type">>, integer, mandatory},
     {<<"node">>, integer, mandatory}
    ];
params(?NDB_LE_DropSchemaObject) -> % INFO,8
    [
     {<<"objectid">>, integer, mandatory},
     {<<"version">>, integer, mandatory},
     {<<"type">>, integer, mandatory},
     {<<"node">>, integer, mandatory}
    ].

%% category(?NDB_MGM_EVENT_CATEGORY_STARTUP - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_STARTUP~n");
%% category(?NDB_MGM_EVENT_CATEGORY_SHUTDOWN - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_SHUTDOWN~n");
%% category(?NDB_MGM_EVENT_CATEGORY_STATISTIC - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_STATISTIC~n");
%% category(?NDB_MGM_EVENT_CATEGORY_CHECKPOINT - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_CHECKPOINT~n");
%% category(?NDB_MGM_EVENT_CATEGORY_NODE_RESTART - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_NODE_RESTART~n");
%% category(?NDB_MGM_EVENT_CATEGORY_CONNECTION - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_CONNECTION~n");
%% category(?NDB_MGM_EVENT_CATEGORY_BACKUP - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_BACKUP~n");
%% category(?NDB_MGM_EVENT_CATEGORY_CONGESTION - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_CONGESTION~n");
%% category(?NDB_MGM_EVENT_CATEGORY_DEBUG - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_DEBUG~n");
%% category(?NDB_MGM_EVENT_CATEGORY_INFO - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_INFO~n");
%% category(?NDB_MGM_EVENT_CATEGORY_WARNING - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_WARNING~n");
%% category(?NDB_MGM_EVENT_CATEGORY_ERROR - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_ERROR~n");
%% category(?NDB_MGM_EVENT_CATEGORY_SCHEMA - ?NDB_MGM_MIN_EVENT_CATEGORY, _, _) ->
%%     io:format("category: NDB_MGM_EVENT_CATEGORY_SCHEMA~n");
%% category(N, _, _) ->
%%     io:format("category: n=~p~n", [N]).
