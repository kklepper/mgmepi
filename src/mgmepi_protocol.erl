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

-module(mgmepi_protocol).

-include("internal.hrl").

%% -- private: http://dev.mysql.com/doc/ndbapi/en/mgm-functions.html --
-export([listen_event/3, get_event/1]).
-export([get_version/2, check_connection/2]).
-export([get_status/2, get_status2/3, dump_state/4]).
-export([start/3, start/4, stop/4, stop/5, stop/6, restart/6, restart/8]).
-export([get_clusterlog_severity_filter/2, set_clusterlog_severity_filter/4,
         get_clusterlog_loglevel/2, set_clusterlog_loglevel/5]).
-export([start_backup/6,abort_backup/4]).
-export([enter_single_user/3, exit_single_user/2]).

%% -- private: ~/include/mgmapi/mgmapi.h --
-export([match_node_type/1, get_node_type_string/1, get_node_type_alias_string/1,
         match_node_status/1, get_node_status_string/1, get_event_severity_string/1,
         match_event_category/1, get_event_category_string/1]).
-export([get_configuration/3, get_configuration_from_node/4]).
-export([alloc_nodeid/5, end_session/2]).
-export([create_nodegroup/3, drop_nodegroup/3]).

%% == private: http://dev.mysql.com/doc/ndbapi/en/mgm-functions.html ==

%% -- 3.2.1. Log Event Functions --

-spec listen_event(pid(),[{integer(),integer()}],timeout()) -> {ok,reference()}|{error,_}.
listen_event(Pid, Filter, Timeout)
  when is_pid(Pid), is_list(Filter) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp : ndb_mgm_listen_event/2, 3.2.1.1
    %%
    F = fun({C,L}) -> implode(fun integer_to_list/1,[C,L],<<"=">>) end,
    case call(Pid,
              <<"listen event">>,
              [
               {<<"parsable">>, <<"1">>},
               {<<"filter">>, implode(F,Filter,<<" ">>)}
              ],
              [
               {<<"listen event">>, null, mandatory},
               {<<"result">>, integer, mandatory},
               {<<"msg">>, string, optional}
              ],
              fun(B,P) -> {L,[]} = parse(B,P), get_result(L,<<"msg">>) end,
              Timeout) of
        ok ->
            call(Pid, {active,[<<"<PING>",?LS>>,<<?LS,?LS>>]});
        {error, Reason} ->
            {error, Reason}
    end.

%% unlisten_event -> STOP!

-spec get_event(binary()) -> [{binary(),term()}].
get_event(Binary)
  when is_binary(Binary) ->
    %%
    %% @see
    %%  ~/src/mgmapi/ndb_logevent.cpp: ndb_logevent_get_next2/3, 3.2.1.6
    %%
    {H, R} = parse(Binary,
                   [
                    {<<"log event reply">>, null, mandatory},
                    {<<"type">>, integer, mandatory},
                    {<<"time">>, integer, mandatory},
                    {<<"source_nodeid">>, integer, mandatory}
                   ],
                   <<"=">>),
    case match(mgmepi_event:params(get_value(<<"type">>,H)), R, H) of
        {L, []} ->
            L
    end.

%%  2 ndb_mgm_create_logevent_handle/2
%%  3 ndb_mgm_destroy_logevent_handle/1
%%  4 ndb_logevent_get_fd/1
%%  5 ndb_logevent_get_next/3
%%  7 ndb_logevent_get_latest_error/1
%%  8 ndb_logevent_get_latest_error_msg/1

%% -- 3.2.2. MGM API Error Handling Functions --
%%  1 ndb_mgm_get_latest_error/1
%%  2 ndb_mgm_get_latest_error_msg/1
%%  3 ndb_mgm_get_latest_error_desc/1
%%  4 ndb_mgm_set_error_stream/2

%% -- 3.2.3. Management Server Handle Functions --
%%  1 ndb_mgm_create_handle/1
%%  2 ndb_mgm_set_name/2
%%  3 ndb_mgm_set_ignore_sigpipe/2
%%  4 ndb_mgm_destroy_handle/1

%% -- 3.2.4. Management Server Connection Functions --

-spec get_version(pid(),timeout()) -> {ok,integer()}|{error,_}.
get_version(Pid, Timeout)
  when is_pid(Pid) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_version/6, 3.2.4.5
    %%
    call(Pid,
         <<"get version">>,
         [],
         [
          {<<"version">>, null, mandatory},
          {<<"id">>, integer, mandatory},
          {<<"major">>, integer, mandatory},
          {<<"minor">>, integer, mandatory},
          {<<"build">>, integer, optional},
          {<<"string">>, string, mandatory},
          {<<"mysql_major">>, integer, optional},
          {<<"mysql_minor">>, integer, optional},
          {<<"mysql_build">>, integer, optional}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), io:format("~p~n",[L]),{ok,get_value(<<"id">>,L)} end,
         Timeout).

-spec check_connection(pid(),timeout()) -> ok|{error,_}.
check_connection(Pid, Timeout)
  when is_pid(Pid) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_check_connection/1, 3.2.4.7
    %%
    call(Pid,
         <<"check connection">>,
         [],
         [
          {<<"check connection reply">>, null, mandatory},
          {<<"result">>, string, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L) end,
         Timeout).

%%  1 ndb_mgm_get_connectstring/3
%%  2 ndb_mgm_get_configuration_nodeid/1
%%  3 ndb_mgm_get_connected_port/1
%%  4 ndb_mgm_get_connected_host/1
%%  6 ndb_mgm_is_connected/1
%%  8 ndb_mgm_number_of_mgmd_in_connect_string/1
%%  9 ndb_mgm_set_bindaddress/2
%% 10 ndb_mgm_set_connectstring/2
%% 11 ndb_mgm_set_configuration_nodeid/2
%% 12 ndb_mgm_set_timeout/2
%% 13 ndb_mgm_connect/4
%% 14 ndb_mgm_disconnect/1

%% -- 3.2.5. Cluster Status Functions --

-spec get_status(pid(),timeout()) -> {ok,[term()]}|{error,_}.
get_status(Pid, Timeout)
  when is_pid(Pid) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_status/1, 3.2.5.1
    %%
    get_status2(Pid, [], Timeout).

-spec get_status2(pid(),[integer()],timeout()) -> {ok,[term()]}|{error,_}.
get_status2(Pid, Types, Timeout)
  when is_pid(Pid), is_list(Types) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_status2/2, 3.2.5.2
    %%
    call(Pid,
         <<"get status">>,
         if 0 < length(Types) ->
                 [
                  {<<"types">>, implode(fun get_node_type_string/1,Types,<<" ">>)}
                 ];
            true ->
                 []
         end,
         [
          {<<"node status">>, null, mandatory}
         ],
         fun(B,P) -> {[],R} = parse(B,P), {ok,R} end, % TODO
         Timeout).

-spec dump_state(pid(),integer(),[integer()],timeout()) -> ok|{error,_}.
dump_state(Pid, Node, Args, Timeout)
  when is_pid(Pid), ?IS_NODE(Node), is_list(Args) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_dump_state/5, 3.2.5.3
    %%
    call(Pid,
         <<"dump state">>, % size(Packet) < 256?
         [
          {<<"node">>, integer_to_binary(Node)},
          {<<"args">>, implode(fun integer_to_binary/1,Args,<<" ">>)}
         ],
         [
          {<<"dump state reply">>, null, mandatory},
          {<<"result">>, string, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L) end,
         Timeout).

%% -- 3.2.6. Functions for Starting & Stopping Nodes --

-spec start(pid(),integer(),timeout()) -> {ok,integer()}|{error,_}.
start(Pid, Version, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_start/3, 3.2.6.1 (1/2)
    %%
    call(Pid,
         <<"start all">>,
         [],
         [
          {<<"start reply">>, null, mandatory},
          {<<"started">>, integer, optional},   % ?
          {<<"result">>, string, mandatory},
          {<<"started">>, integer, optional}    % !
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L,<<"started">>) end,
         Timeout).

-spec start(pid(),integer(),[integer()],timeout()) -> {ok,integer()}|{error,_}.
start(Pid, Version, Nodes, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), is_list(Nodes) ->
    start(Pid, Version, Nodes, Timeout, 0).

start(_Pid, _Version, [], _Timeout, Started) ->
    {ok, Started};
start(Pid, Version, [H|T], Timeout, Started) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_start/3, 3.2.6.1 (2/2)
    %%
    case call(Pid,
              <<"start">>,
              [
               {<<"node">>, integer_to_binary(H)} % = NDB (--nostart,-n)
              ],
              [
               {<<"start reply">>, null, mandatory},
               {<<"result">>, string, mandatory}
              ],
              fun(B,P) -> {L,[]} = parse(B,P), get_result(L) end,
              Timeout) of
        ok ->
            start(Pid, Version, T, Timeout, Started+1);
        {error, Reason} ->
            {error, Reason}
    end.

-spec stop(pid(),integer(),integer(),timeout()) -> {ok,{integer(),integer()}}|{error,_}.
stop(Pid, Version, Abort, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), ?IS_BOOLEAN(Abort) ->
    stop(Pid, Version, Abort, [?NDB_MGM_NODE_TYPE_NDB], Timeout).

-spec stop(pid(),integer(),integer(),[integer()],timeout()) -> {ok,{integer(),integer()}}|{error,_}.
stop(Pid, Version, Abort, Types, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), ?IS_BOOLEAN(Abort), is_list(Types) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_stop4/6, 3.2.6.[6-9] (!=, 1/2)
    %%
    F = fun (?NDB_MGM_NODE_TYPE_NDB) -> <<"db">>; % != ndb
            (?NDB_MGM_NODE_TYPE_MGM) -> <<"mgm">>
        end,
    call(Pid,
         <<"stop all">>, % v2
         [
          {<<"abort">>, integer_to_binary(Abort)},
          {<<"stop">>, implode(F,Types,<<",">>)}
         ],
         [
          {<<"stop reply">>, null, mandatory},
          {<<"stopped">>, integer, optional},     % ?
          {<<"result">>, string, mandatory},
          {<<"stopped">>, integer, optional},     % !
          {<<"disconnect">>, integer, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L,[<<"stopped">>,<<"disconnect">>]) end,
         Timeout).

-spec stop(pid(),integer(),integer(),integer(),[integer()],timeout()) -> {ok,{integer(),integer()}}|{error,_}.
stop(Pid, Version, Abort, Force, Nodes, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version),
       ?IS_BOOLEAN(Abort), ?IS_BOOLEAN(Force), is_list(Nodes) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_stop4/6, 3.2.6.[6-9] (2/2)
    %%
    call(Pid,
         <<"stop v2">>,
         fold([
               fun () when (?MIN_VERSION(Version,7,0,19) and ?MAX_VERSION(Version,7,1,0)) orelse
                           (?MIN_VERSION(Version,7,1,8)) ->
                       {<<"force">>, integer_to_binary(Force)};
                   () ->
                       undefined
               end
              ],
              [
               {<<"node">>, implode(fun integer_to_binary/1,Nodes,<<" ">>)},
               {<<"abort">>, integer_to_binary(Abort)}
              ]),
         [
          {<<"stop reply">>, null, mandatory},
          {<<"stopped">>, integer, optional},     % ?
          {<<"result">>, string, mandatory},
          {<<"stopped">>, integer, optional},     % !
          {<<"disconnect">>, integer, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L,[<<"stopped">>,<<"disconnect">>]) end,
         Timeout).

-spec restart(pid(),integer(),integer(),integer(),integer(),timeout()) -> {ok,integer()}|{error,_}.
restart(Pid, Version, Abort, Initial, NoStart, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), ?IS_BOOLEAN(Abort),
       ?IS_BOOLEAN(Initial), ?IS_BOOLEAN(NoStart) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_restart4/8, 3.2.6.[2-5] (!=, 1/2)
    %%
    call(Pid,
         <<"restart all">>, % v1
         [
          {<<"abort">>, integer_to_binary(Abort)},
          {<<"initialstart">>, integer_to_binary(Initial)},
          {<<"nostart">>, integer_to_binary(NoStart)}
         ],
         [
          {<<"restart reply">>, null, mandatory},
          {<<"result">>, string, mandatory},
          {<<"restarted">>, integer, optional}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L,<<"restarted">>) end,
         Timeout).

-spec restart(pid(),integer(),integer(),integer(),integer(),integer(),[integer()],timeout())
             -> {ok,{integer(),integer()}}|{error,_}.
restart(Pid, Version, Abort, Initial, NoStart, Force, Nodes, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), ?IS_BOOLEAN(Abort),
       ?IS_BOOLEAN(Initial), ?IS_BOOLEAN(NoStart), ?IS_BOOLEAN(Force), is_list(Nodes) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_restart4/8, 3.2.6.[2-5] (2/2)
    %%
    call(Pid,
         <<"restart node v2">>,
         fold([
               fun () when (?MIN_VERSION(Version,7,0,19) and ?MAX_VERSION(Version,7,1,0)) orelse
                           (?MIN_VERSION(Version,7,1,8)) ->
                       {<<"force">>, integer_to_binary(Force)};
                   () ->
                       undefined
               end
              ],
              [
               {<<"node">>, implode(fun integer_to_binary/1,Nodes,<<" ">>)},
               {<<"abort">>, integer_to_binary(Abort)},
               {<<"initialstart">>, integer_to_binary(Initial)},
               {<<"nostart">>, integer_to_binary(NoStart)}
              ]),
         [
          {<<"restart reply">>, null, mandatory},
          {<<"result">>, string, mandatory},
          {<<"restarted">>, integer, optional},
          {<<"disconnect">>, integer, optional}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L,[<<"restarted">>,<<"disconnect">>]) end,
         Timeout).

%% -- 3.2.7. Cluster Log Functions --

-spec get_clusterlog_severity_filter(pid(),timeout()) -> {ok,[{integer(),integer()}]}|{error,_}.
get_clusterlog_severity_filter(Pid, Timeout)
  when is_pid(Pid) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_clusterlog_severity_filter/3, 3.2.7.1
    %%
    call(Pid,
         <<"get info clusterlog">>,
         [],
         [
          {<<"clusterlog">>, null, mandatory},
          {<<"enabled">>, integer, mandatory},
          {<<"debug">>, integer, mandatory},
          {<<"info">>, integer, mandatory},
          {<<"warning">>, integer, mandatory},
          {<<"error">>, integer, mandatory},
          {<<"critical">>, integer, mandatory},
          {<<"alert">>, integer, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), lists:keymap(fun match_event_severity/1,1,L) end,
         Timeout).

-spec set_clusterlog_severity_filter(pid(),integer(),integer(),timeout()) -> {ok,integer()}|{error,_}.
set_clusterlog_severity_filter(Pid, Severity, Enable, Timeout)
  when is_pid(Pid), ?IS_EVENT_SEVERITY(Severity), ?IS_BOOLEAN(Enable) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_set_clusterlog_severity_filter/4, 3.2.7.2
    %%
    call(Pid,
         <<"set logfilter">>,
         [
          {<<"level">>, integer_to_binary(Severity)},
          {<<"enable">>, integer_to_binary(Enable)}
         ],
         [
          {<<"set logfilter reply">>, null, mandatory},
          {<<"result">>, integer, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), {ok,get_value(<<"result">>,L)} end,
         Timeout).

-spec get_clusterlog_loglevel(pid(),timeout()) -> {ok,[{integer(),integer()}]}|{error,_}.
get_clusterlog_loglevel(Pid, Timeout)
  when is_pid(Pid) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_clusterlog_loglevel/3, 3.2.7.3
    %%
    call(Pid,
         <<"get cluster loglevel">>,
         [],
         [
          {<<"get cluster loglevel">>, null, mandatory},
          {<<"startup">>, integer, mandatory},
          {<<"shutdown">>, integer, mandatory},
          {<<"statistics">>, integer, mandatory},
          {<<"checkpoint">>, integer, mandatory},
          {<<"noderestart">>, integer, mandatory},
          {<<"connection">>, integer, mandatory},
          {<<"info">>, integer, mandatory},
          {<<"warning">>, integer, mandatory},
          {<<"error">>, integer, mandatory},
          {<<"congestion">>, integer, mandatory},
          {<<"debug">>, integer, mandatory},
          {<<"backup">>, integer, mandatory},
          {<<"schema">>, integer, optional}     % !, mandatory?
         ],
         fun(B,P) -> {L,[]} = parse(B,P), lists:keymap(fun match_event_category3/1,1,L) end,
         Timeout).

-spec set_clusterlog_loglevel(pid(),integer(),integer(),integer(),timeout()) -> ok|{error,_}.
set_clusterlog_loglevel(Pid, Node, Category, Level, Timeout)
  when is_pid(Pid), ?IS_NODE(Node), ?IS_EVENT_CATEGORY(Category), ?IS_LOGLEVEL(Level) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_set_clusterlog_loglevel/5, 3.2.7.4
    %%
    call(Pid,
         <<"set cluster loglevel">>,
         [
          {<<"node">>, integer_to_binary(Node)}, % ignore?
          {<<"category">>, integer_to_binary(Category)},
          {<<"level">>, integer_to_binary(Level)}
         ],
         [
          {<<"set cluster loglevel reply">>, null, mandatory},
          {<<"result">>, string, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L) end,
         Timeout).

%% -- 3.2.8. Backup Functions --

-spec start_backup(pid(),integer(),integer(),integer(),integer(),timeout()) -> {ok,integer()}|{error,_}.
start_backup(Pid, Version, Completed, BackupId, Backuppoint, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version),
       ?IS_BACKUP_WAIT(Completed), ?IS_BACKUP_ID(BackupId), ?IS_BOOLEAN(Backuppoint) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_start_backup/4, 3.2.8.1
    %%
    call(Pid,
         <<"start backup">>,
         fold([
               fun () ->
                       {<<"completed">>, integer_to_binary(Completed)}
               end,
               fun () when 0 < BackupId ->
                       {<<"backupid">>, integer_to_binary(BackupId)};
                   () ->
                       undefined
               end,
               fun () when ?MIN_VERSION(Version,6,4,0) ->
                       {<<"backuppoint">>, integer_to_binary(Backuppoint)};
                   () ->
                       undefined
               end
              ], []),
         [
          {<<"start backup reply">>, null, mandatory},
          {<<"result">>, string, mandatory},
          {<<"id">>, integer, optional}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L,<<"id">>) end,
         Timeout).

-spec abort_backup(pid(),integer(),integer(),timeout()) -> {ok,integer()}|{error,_}.
abort_backup(Pid, Version, BackupId, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), is_integer(BackupId) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_abort_backup/3, 3.2.8.2
    %%
    call(Pid,
         <<"abort backup">>,
         [
          {<<"id">>, integer_to_binary(BackupId)}
         ],
         [
          {<<"abort backup reply">>, null, mandatory},
          {<<"result">>, string, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L) end,
         Timeout).

%% -- 3.2.9. Single-User Mode Functions --

-spec enter_single_user(pid(),integer(),timeout()) -> ok|{error,_}.
enter_single_user(Pid, Node, Timeout)
  when is_pid(Pid), ?IS_NODE(Node) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_enter_single_user/3, 3.2.9.1
    %%
    call(Pid,
         <<"enter single user">>,
         [
          {<<"nodeId">>, integer_to_binary(Node)} % ignore?
         ],
         [
          {<<"enter single user reply">>, null, mandatory},
          {<<"result">>, string, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L) end,
         Timeout).

-spec exit_single_user(pid(),timeout()) -> ok|{error,_}.
exit_single_user(Pid, Timeout)
  when is_pid(Pid) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: exit_single_user/2, 3.2.9.2
    %%
    call(Pid,
         <<"exit single user">>,
         [],
         [
          {<<"exit single user reply">>, null, mandatory},
          {<<"result">>, string, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L) end,
         Timeout).

%% == private: ~/include/mgmapi/mgmapi.h ==

%% -- "Connect/Disconnect Management Server" --
%%   ndb_mgm_get_connected_bind_address/1

%% -- "Listening to log events" --
%%   ndb_mgm_set_loglevel_node/5

%% -- "Used to convert between different data formats" --

-spec match_node_type(binary()) -> integer().
match_node_type(NodeType)
  when is_binary(NodeType) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_match_node_type/1
    %%
    get_value(NodeType, 2, node_type(), 1, ?NDB_MGM_NODE_TYPE_UNKNOWN).

-spec get_node_type_string(integer()) -> binary().
get_node_type_string(NodeType)
  when is_integer(NodeType) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_node_type_string/1
    %%
    get_value(NodeType, 1, node_type(), 2, <<"">>).

-spec get_node_type_alias_string(integer()) -> binary().
get_node_type_alias_string(NodeType)
  when is_integer(NodeType) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_node_type_alias_string/2
    %%
    get_value(NodeType, 1, node_type(), 3, <<"">>).

-spec match_node_status(binary()) -> integer().
match_node_status(Status)
  when is_binary(Status) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_match_node_status/1
    %%
    get_value(Status, 2, node_status(), 1, ?NDB_MGM_NODE_STATUS_UNKNOWN).

-spec get_node_status_string(integer()) -> binary().
get_node_status_string(Status)
  when is_integer(Status) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_node_status_string/1
    %%
    get_value(Status, 1, node_status(), 2, <<"UNKNOWN">>).

match_event_severity(Severity) ->
    get_value(Severity, 2, event_severity(), 1, ?NDB_MGM_ILLEGAL_EVENT_SEVERITY).

-spec get_event_severity_string(integer()) -> binary().
get_event_severity_string(Severity)
  when is_integer(Severity) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_event_severity_string/1
    %%
    get_value(Severity, 1, event_severity(), 2, <<"">>).

-spec match_event_category(binary()) -> integer().
match_event_category(Category)
  when is_binary(Category) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_match_event_category/1
    %%
    match_event_category(Category, 2).

match_event_category3(Category) ->
    match_event_category(Category, 3).

match_event_category(Category, N) ->
    get_value(Category, N, event_category(), 1, ?NDB_MGM_ILLEGAL_EVENT_CATEGORY).

-spec get_event_category_string(integer()) -> binary().
get_event_category_string(Category)
  when is_integer(Category) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_event_category_string/1
    %%
    get_value(Category, 1, event_category(), 2, <<"">>).

%% -- "Configuration handling" --

-spec get_configuration(pid(),integer(),timeout()) -> {ok,term()}|{error,_}.
get_configuration(Pid, Version, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_configuration/2
    %%
    get_configuration2(Pid, Version, ?NDB_VERSION_ID, ?NDB_MGM_NODE_TYPE_UNKNOWN, 0, Timeout).

-spec get_configuration_from_node(pid(),integer(),integer(),timeout()) -> {ok,term()}|{error,_}.
get_configuration_from_node(Pid, Version, Node, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), ?IS_NODE(Node) -> % = NDB
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_configuration_from_node/2
    %%
    get_configuration2(Pid, Version, 0, ?NDB_MGM_NODE_TYPE_UNKNOWN, Node, Timeout).

get_configuration2(Pid, Server, Client, NodeType, Node, Timeout) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_get_configuration2/4 (!=)
    %%
    case call(Pid,
              <<"get config">>,
              fold([
                    fun () when ?MIN_VERSION(Server,6,4,0) ->
                            {<<"nodetype">>, integer_to_binary(NodeType)};
                        () ->
                            undefined
                    end,
                    fun () when (?MIN_VERSION(Server,7,0,27) and ?MAX_VERSION(Server,7,1,0))
                                orelse
                                (?MIN_VERSION(Server,7,1,16)) ->
                            {<<"from_node">>, integer_to_binary(Node)};
                        () ->
                            undefined
                    end
                   ],
                   [
                    {<<"version">>, integer_to_binary(Client)}
                   ]),
              [
               {<<"get config reply">>, null, mandatory},
               {<<"result">>, string, mandatory},
               {<<"Content-Length">>, integer, optional},
               {<<"Content-Type">>, <<"ndbconfig/octet-stream">>, optional},
               {<<"Content-Transfer-Encoding">>, <<"base64">>, optional}
              ],
              fun(B,P) -> {L,[]} = parse(B,P), get_result(L,<<"Content-Length">>) end,
              Timeout) of
        {ok, Size} ->
            case recv(Pid, Size+1, infinity) of % 1=end_of_protocol=?LS
                {ok, Binary} ->
                    {Base64, <<?LS>>} = split_binary(Binary, Size),
                    {ok, mgmepi_config:unpack(base64:decode(Base64))};
                {error, Reason} ->
                    {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

-spec alloc_nodeid(pid(),integer(),binary(),integer(),timeout()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid, Node, Name, LogEvent, Timeout)
  when is_pid(Pid), ?IS_NODE(Node), is_binary(Name), ?IS_BOOLEAN(LogEvent) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_alloc_nodeid/4 (!=)
    %%
    call(Pid,
         <<"get nodeid">>,
         [
          {<<"version">>, integer_to_binary(?NDB_VERSION_ID)},
          {<<"nodetype">>, integer_to_binary(?NDB_MGM_NODE_TYPE_API)},
          {<<"nodeid">>, integer_to_binary(Node)},
          {<<"user">>, <<"mysqld">>},
          {<<"password">>, <<"mysqld">>},
          {<<"public key">>, <<"a public key">>},
          {<<"endian">>, endianness()},
          {<<"name">>, Name},
          {<<"log_event">>, integer_to_binary(LogEvent)} % "only log last retry"?
         ],
         [
          {<<"get nodeid reply">>, null, mandatory},
          {<<"error_code">>, integer, optional},
          {<<"nodeid">>, integer, optional},
          {<<"result">>, string, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L,<<"nodeid">>) end,
         Timeout).


-spec end_session(pid(),timeout()) -> ok|ignore|{error,_}.
end_session(Pid, Timeout)
  when is_pid(Pid) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_end_session/1
    %%  ~/src/mgmsrv/Services.cpp: MgmApiSession::endSession/2, NOTEXIST end_of_protocol="\n"
    %%
    call(Pid,
         <<"end session">>,
         [],
         [
          {<<"end session reply">>, null, mandatory}
         ],
         <<?LS>>,
         fun(B,P) -> {[],[]} = parse(B,P), ok end,
         Timeout).

%%   ndb_mgm_destroy_configuration/1
%%   ndb_mgm_get_fd/1
%%   ndb_mgm_get_mgmd_nodeid/1
%%   ndb_mgm_create_configuration_iterator/2 << mgmapi_configuration.cpp
%%   ndb_mgm_destroy_iterator/1
%%   ndb_mgm_first/1
%%   ndb_mgm_next/1
%%   ndb_mgm_valid/1
%%   ndb_mgm_find/3
%%   ndb_mgm_get_int_parameter/3
%%   ndb_mgm_get_int64_parameter/3
%%   ndb_mgm_get_string_parameter/3
%%   ndb_mgm_purge_stale_sessions/2
%%   ndb_mgm_report_event/3
%%   ndb_mgm_get_db_parameter_info/3 << mgmapi_configuration.cpp

%% -- "?" --

%% @see http://dev.mysql.com/doc/refman/5.6/en/mysql-cluster-online-add-node-example.html

-spec create_nodegroup(pid(),[integer()],timeout()) -> {ok,integer()}|{error,_}.
create_nodegroup(Pid, Nodes, Timeout)
  when is_pid(Pid), is_list(Nodes) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_create_nodegroup/4
    %%
    call(Pid,
         <<"create nodegroup">>,
         [
          {<<"nodes">>, implode(fun integer_to_binary/1,Nodes,<<" ">>)}
         ],
         [
          {<<"create nodegroup reply">>, null, mandatory},
          {<<"ng">>, integer, mandatory},
          {<<"error_code">>, integer, optional},
          {<<"result">>, string, mandatory}
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L,<<"ng">>) end,
         Timeout).

-spec drop_nodegroup(pid(),integer(),timeout()) -> ok|{error,_}.
drop_nodegroup(Pid, NodeGroup, Timeout) ->
    %%
    %% @see
    %%  ~/src/mgmapi/mgmapi.cpp: ndb_mgm_drop_nodegroup/3
    %%
    %% BUG: NO nodegroup -> <<"drop nodegroup reply\nresult: error: -1">>,  NO "\n"
    %%                                                      ^
    call(Pid,
         <<"drop nodegroup">>,
         [
          {<<"ng">>, integer_to_binary(NodeGroup)}
         ],
         [
          {<<"drop nodegroup reply">>, null, mandatory},
          {<<"error_code">>, integer, optional}, % ?
          {<<"result">>, string, mandatory},
          {<<"error_code">>, integer, optional}  % !
         ],
         fun(B,P) -> {L,[]} = parse(B,P), get_result(L) end,
         Timeout).

%%   ndb_mgm_dump_events/4
%%   ndb_mgm_call/5, cmd_bulk? TODO
%%   ndb_mgm_call_slow/6, timout=5*60*1000 (ms)
%%   get_mgmd_version/1
%%   status_ackumulate/3
%%   cmp_state/2
%%   ndb_mgm_match_event_severity/1
%%   ndb_mgm_listen_event_internal/4
%%   cmp_event/2
%%   free_log_handle/1
%%   set_dynamic_ports_batched/4

%% == private: ~/include/mgmapi/mgmapi_debug.h ==

%%   ndb_mgm_start_signallog/3
%%   ndb_mgm_stop_signallog/3
%%   ndb_mgm_log_signals/5
%%   ndb_mgm_set_trace/4
%%   ndb_mgm_insert_error/4
%%   ndb_mgm_insert_error2/5
%%   ndb_mgm_set_int_parameter/5
%%   ndb_mgm_set_int64_parameter/5
%%   ndb_mgm_set_string_parameter/5
%%   ndb_mgm_get_session_id/1
%%   ndb_mgm_get_session/3

%% ? ndb_mgm_insert_error_impl/5

%% == private: ~/include/mgmapi/mgmapi_internal.h ==

%%   ndb_mgm_set_connection_int_parameter/6
%%   ndb_mgm_set_dynamic_ports/4
%%   ndb_mgm_get_connection_int_parameter/6
%%   ndb_mgm_convert_to_transporter/1
%%   ndb_mgm_disconnect_quiet/1
%%   ndb_mgm_set_configuration/2
%%   _ndb_mgm_get_socket/1
%%   ndb_mgm_get_configuration2/4

%% == internal ==

call(Pid, Term) ->
    mgmepi_server:call(Pid, Term).

call(Pid, Cmd, Args, Params, Callback, Timeout) ->
    call(Pid, Cmd, Args, Params, <<?LS,?LS>>, Callback, Timeout).

call(Pid, Cmd, Args, Params, Pattern, Callback, Timeout) ->
    case call(Pid, {call,to_packet(Cmd,Args),Pattern,Timeout}) of
        {ok, Binary} ->
            Callback(Binary, Params);
        ignore ->
            ignore;
        {error, Reason} ->
            {error, Reason}
    end.

recv(Pid, Size, Timeout) ->
    call(Pid, {recv,Size,Timeout}).


endianness() ->
    <<N:2/native-unsigned-integer-unit:8>> = <<0,1>>,
    case N of 1 -> <<"big">>; 256 -> <<"little">> end.

fold(List, Acc) ->
    F = fun(E,A) -> case E() of undefined -> A; T -> [T|A] end end,
    lists:reverse(lists:foldl(F,lists:reverse(Acc),List)).

get_result(List) ->
    case get_value(<<"result">>, List) of
        <<"Ok">> ->
            ok;
        Reason ->
            {error, Reason}
    end.

get_result(List, Other) ->
    get_result(List, Other, undefined).

get_result(List, Other, Default) when is_binary(Other) ->
    case get_value(<<"result">>, List) of
        <<"Ok">> ->
            {ok, get_value(Other,List,Default)};
        0 ->
            ok;
        -1 ->
            {error, get_value(Other,List,Default)};
        Reason ->
            {error, Reason}
    end;
get_result(List, Other, Default) when is_list(Other) ->
    case get_value(<<"result">>, List) of
        <<"Ok">> ->
            {ok, list_to_tuple([ get_value(E,List,Default) || E <- Other ])};
        Reason ->
            {error, Reason}
    end.

get_value(Key, List) ->
    get_value(Key, List, undefined).

get_value(Key, List, Default) ->
    get_value(Key, 1, List, 2, Default).

get_value(Key, N, List, M, Default) ->
    case lists:keyfind(Key, N, List) of
        false  ->
            Default;
        Tuple ->
            element(M, Tuple)
    end.

implode(Fun, List, Separator) ->
    implode(Fun, List, Separator, []).

implode(_Fun, [], _Separator, []) ->
    <<"">>;
implode(_Fun, [], _Separator, [_|T]) ->
    list_to_binary(lists:reverse(T));
implode(Fun, [H|T], Separator, List) ->
    implode(Fun, T, Separator, [Separator|[Fun(H)|List]]).

match([], Rest, List) ->
    {lists:reverse(List), Rest};
match([{K,string,_}|L], [[K,V]|R], List) ->
    match(L, R, [{K,V}|List]);
match([{K,integer,_}|L], [[K,V]|R], List) ->
    match(L, R, [{K,binary_to_integer(V)}|List]);
match([{K,null,_}|L],[[K]|R], List) ->
    match(L, R, List);
match([{K,V,_}|L], [[K,V]|R], List) ->
    match(L, R, [{K,V}|List]);
match([{_,_,optional}|L], R, List) ->
    match(L, R, List).

parse(Binary, Params) ->
    parse(Binary, Params, <<?FS>>).

parse(Binary, Params, FieldPattern) ->
    match(Params, split(Binary,FieldPattern), []).

split(Binary, FieldPattern) ->
    split(Binary, FieldPattern, <<?LS>>).

split(Binary, FieldPattern, LinePattern) ->
    [ binary:split(E,FieldPattern) || E <- binary:split(Binary,LinePattern,[global]) ].

to_packet(Cmd, []) ->
    <<Cmd/binary, ?LS, ?LS>>;
to_packet(Cmd, Args) ->
    B = << <<K/binary,?FS,V/binary,?LS>> || {K,V} <- Args >>,
    <<Cmd/binary, ?LS, B/binary, ?LS>>.

%% -- --

event_category() ->
    [
     {?NDB_MGM_EVENT_CATEGORY_STARTUP,      <<"STARTUP">>,     <<"startup">>},
     {?NDB_MGM_EVENT_CATEGORY_SHUTDOWN,     <<"SHUTDOWN">>,    <<"shutdown">>},
     {?NDB_MGM_EVENT_CATEGORY_STATISTIC,    <<"STATISTICS">>,  <<"statistics">>},
     {?NDB_MGM_EVENT_CATEGORY_CHECKPOINT,   <<"CHECKPOINT">>,  <<"checkpoint">>},
     {?NDB_MGM_EVENT_CATEGORY_NODE_RESTART, <<"NODERESTART">>, <<"noderestart">>},
     {?NDB_MGM_EVENT_CATEGORY_CONNECTION,   <<"CONNECTION">>,  <<"connection">>},
     {?NDB_MGM_EVENT_CATEGORY_BACKUP,       <<"BACKUP">>,      <<"backup">>},
     {?NDB_MGM_EVENT_CATEGORY_CONGESTION,   <<"CONGESTION">>,  <<"congestion">>},
     {?NDB_MGM_EVENT_CATEGORY_DEBUG,        <<"DEBUG">>,       <<"debug">>},
     {?NDB_MGM_EVENT_CATEGORY_INFO,         <<"INFO">>,        <<"info">>},
     {?NDB_MGM_EVENT_CATEGORY_WARNING,      <<"WARNING">>,     <<"warning">>},
     {?NDB_MGM_EVENT_CATEGORY_ERROR,        <<"ERROR">>,       <<"error">>},
     {?NDB_MGM_EVENT_CATEGORY_SCHEMA,       <<"SCHEMA">>,      <<"schema">>}
    ].

event_severity() ->
    [
     {?NDB_MGM_EVENT_SEVERITY_ON,       <<"enabled">>},
     {?NDB_MGM_EVENT_SEVERITY_DEBUG,    <<"debug">>},
     {?NDB_MGM_EVENT_SEVERITY_INFO,     <<"info">>},
     {?NDB_MGM_EVENT_SEVERITY_WARNING,  <<"warning">>},
     {?NDB_MGM_EVENT_SEVERITY_ERROR,    <<"error">>},
     {?NDB_MGM_EVENT_SEVERITY_CRITICAL, <<"critical">>},
     {?NDB_MGM_EVENT_SEVERITY_ALERT,    <<"alert">>},
     {?NDB_MGM_EVENT_SEVERITY_ALL,      <<"all">>}
    ].

node_status() ->
    [
     {?NDB_MGM_NODE_STATUS_NO_CONTACT,    <<"NO_CONTACT">>},
     {?NDB_MGM_NODE_STATUS_NOT_STARTED,   <<"NOT_STARTED">>},
     {?NDB_MGM_NODE_STATUS_STARTING,      <<"STARTING">>},
     {?NDB_MGM_NODE_STATUS_STARTED,       <<"STARTED">>},
     {?NDB_MGM_NODE_STATUS_SHUTTING_DOWN, <<"SHUTTING_DOWN">>},
     {?NDB_MGM_NODE_STATUS_RESTARTING,    <<"RESTARTING">>},
     {?NDB_MGM_NODE_STATUS_SINGLEUSER,    <<"SINGLE USER MODE">>},
     {?NDB_MGM_NODE_STATUS_RESUME,        <<"RESUME">>},
     {?NDB_MGM_NODE_STATUS_CONNECTED,     <<"CONNECTED">>}
    ].

node_type() ->
    [
     {?NDB_MGM_NODE_TYPE_API, <<"API">>, <<"mysqld">>},
     {?NDB_MGM_NODE_TYPE_NDB, <<"NDB">>, <<"ndbd">>},
     {?NDB_MGM_NODE_TYPE_MGM, <<"MGM">>, <<"ndb_mgmd">>}
    ].
