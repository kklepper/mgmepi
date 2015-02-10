%% =============================================================================
%% =============================================================================

-module(mgmepi_SUITE).

-include("internal.hrl").

%% -- callback: ct --
-export([all/0,
         groups/0, init_per_group/2, end_per_group/2]).

%% -- public --
-export([start_test/2, stop_test/2, version_test/1]).
-export([checkout_test/2, checkin_test/2]).

-export([get_version_test/2, check_connection_test/1]).
-export([alloc_nodeid_test/1, alloc_nodeid_test/2, end_session_test/2]).
-export([get_configuration_test/1]).
-export([listen_event_test/1]).
-export([exit_socket_test/1]).

%% == callback: ct ==

%% Cluster Configuration
%% ---------------------
%% [ndbd(NDB)]	2 node(s)
%% id=1	@127.0.0.1  (mysql-5.6.21 ndb-7.3.7, Nodegroup: 0, *)
%% id=4	@127.0.0.1  (mysql-5.6.21 ndb-7.3.7, Nodegroup: 0)
%%
%% [ndb_mgmd(MGM)]	1 node(s)
%% id=91	@127.0.0.1  (mysql-5.6.21 ndb-7.3.7)
%%
%% [mysqld(API)]	3 node(s)
%% id=201 (not connected, accepting connect from localhost)
%% id=202 (not connected, accepting connect from localhost)
%% id=203 (not connected, accepting connect from localhost)

all() -> [
          version_test,
          {group, config_v73}
         ].

groups() -> [

             {config_v73, [], [
                               {group, groups_public}
                              ]},

             {groups_public, [parallel], [
                                          {group, group_parallel_1},
                                          {group, group_parallel_2},
                                          {group, group_parallel_3}
                                         ]},

             {group_parallel_1, [sequence], [
                                             check_connection_test,
                                             get_configuration_test
                                            ]},
             {group_parallel_2, [sequence], [
                                             check_connection_test,
                                             listen_event_test
                                            ]},
             {group_parallel_3, [sequence], [
                                             check_connection_test,
                                             alloc_nodeid_test,
                                             exit_socket_test
                                            ]}
            ].

init_per_group(Group, Config) ->
    loop(Group, Config, [
                         {<<"config_">>, [
                                          fun start_test/2
                                         ]},
                         {<<"group_">>, [
                                         fun checkout_test/2,
                                         fun get_version_test/2,
                                         fun alloc_nodeid_test/2
                                        ]}
                        ]).

end_per_group(Group, Config) ->
    loop(Group, Config, [
                         {<<"config_">>, [
                                          fun stop_test/2
                                         ]},
                         {<<"group_">>, [
                                         fun end_session_test/2,
                                         fun checkin_test/2
                                        ]}
                        ]).

%% == public ==

start_test(Group, Config) ->
    case ok =:= set_env(ct:get_config(Group,Config)) andalso test(start,[]) of
        ok ->
            Config;
        {error, Reason} ->
            {fail, Reason}
    end.

stop_test(_Group, Config) ->
    case test(stop, []) of
        ok ->
            Config;
        {error, Reason} ->
            {fail, Reason}
    end.

version_test(_Config) ->
    [0,3] = test(version, []).


checkout_test(_Group, Config) ->
    case test(checkout, []) of
        {ok, Handle} ->
            [{handle,Handle}|Config];
        {error, Reason} ->
            {skip, Reason}
    end.

checkin_test(_Group, Config) ->
    case test(checkin, [?config(handle,Config)]) of
        ok ->
            proplists:delete(handle,Config);
        {error, Reason} ->
            {fail, Reason}
    end.


get_version_test(_Group, Config) ->
    case test(get_version, [?config(handle,Config)]) of
        {ok, Version} when ?NDB_VERSION_ID < Version ->
            {skip, max_version};
        {ok, Version} when ?VERSION(7,3,0) > Version ->
            {skip, min_version};
        {ok, Version} ->
            [{version,Version}|Config];
        {error, Reason} ->
            {skip, Reason}
    end.

check_connection_test(Config) ->
    ok = test(check_connection, [?config(handle,Config)]).


alloc_nodeid_test(Config) ->
    H = ?config(handle,Config),
    N = ?config(node, Config),
    L = [
         {
           [H, N],
           {error, list_to_binary([
                                   "Id ",
                                   integer_to_list(N),
                                   " already allocated by another node."
                                  ])}
         },
         {
           [H],
           {error, <<"No free node id found for mysqld(API).">>}
         }
        ],
    [ E = test(alloc_nodeid,A) || {A,E} <- L ].

alloc_nodeid_test(Group, Config) ->
    case test(alloc_nodeid, [?config(handle,Config),0,atom_to_binary(Group,latin1)]) of
        {ok, Node} ->
            [{node,Node}|Config];
        {error, Reason} ->
            {skip, Reason}
    end.

end_session_test(_Group, Config) ->
    case test(end_session, [?config(handle,Config)]) of
        ok ->
            proplists:delete(node,Config);
        {error, Reason} ->
            {fail, Reason}
    end.


get_configuration_test(Config) ->
    {ok, L} = test(get_configuration, [?config(handle,Config),?config(version,Config)]),
    [ E(Config, L) || E <- [
                            fun get_connection_configuration_test/2,
                            fun get_node_configuration_test/2,
                            fun get_nodes_configuration_test/2,
                            fun get_system_configuration_test/2
                           ] ].

get_connection_configuration_test(Config, List) ->
    F = test(get_connection_configuration, [List,?config(node,Config)]),
    T = test(get_connection_configuration, [List,?config(node,Config),true]),
    [ 2 = length(L) - length(R) || {L,R} <- lists:zip(F,T) ]. % TODO

get_node_configuration_test(Config, List) ->
    [ get_node_configuration_test(Config,List,E) || E <- [1,91,?config(node,Config)] ].

get_node_configuration_test(_Config, List, Node) ->
    F = test(get_node_configuration, [List,Node]),
    T = test(get_node_configuration, [List,Node,true]),
    [ 2 = length(L) - length(R) || {L,R} <- lists:zip(F,T) ]. % TODO

get_nodes_configuration_test(Config, List) ->
    [ get_nodes_configuration_test(Config,List,E)
      || E <- [?NDB_MGM_NODE_TYPE_NDB,?NDB_MGM_NODE_TYPE_API,?NDB_MGM_NODE_TYPE_MGM] ].

get_nodes_configuration_test(_Config, List, Type) ->
    F = test(get_nodes_configuration, [List,Type]),
    T = test(get_nodes_configuration, [List,Type,true]),
    [ 2 = length(L) - length(R) || {L,R} <- lists:zip(F,T) ]. % TODO

get_system_configuration_test(_Config, List) ->
    F = test(get_system_configuration, [List]),
    T = test(get_system_configuration, [List,true]),
    [ 2 = length(L) - length(R) || {L,R} <- lists:zip(F,T) ]. % TODO


listen_event_test(_Config) ->
    case test(checkout, []) of
        {ok, Handle} ->
            L = [
                 {?NDB_MGM_EVENT_CATEGORY_CHECKPOINT, 15}
                ],
            try test(listen_event, [Handle,L]) of
                {ok, Reference} ->
                    get_event_test(Reference)
            after
                ignore = test(end_session, [Handle]),
                ok = test(checkin, [Handle]) % = stop
            end
    end.

get_event_test(Reference) ->
    L = [
         ?NDB_LE_GlobalCheckpointStarted,
         ?NDB_LE_GlobalCheckpointCompleted
        ],
    L = get_event_test(Reference, 2, []).

get_event_test(_Reference, 0, List) ->
    lists:reverse(List);
get_event_test(Reference, N, List) ->
    receive
        {Reference, Binary} ->
            L = test(get_event, [Binary]),
            get_event_test(Reference, N-1, [proplists:get_value(<<"type">>,L)|List])
    end.


exit_socket_test(_Config) ->
    case test(checkout, []) of
        {ok, Mgmepi} ->
            %% -- CAUTION --
            mgmepi = element(1, Mgmepi), 3 = size(Mgmepi),
            Pid = element(3, Mgmepi),
            true = is_pid(Pid),
            State = sys:get_state(Pid),
            true = (state =:= element(1, State) andalso 7 =:= size(State)),
            Handle = element(4, State),
            true = (handle =:= element(1, Handle) andalso 3 =:= size(Handle)),
            Socket = element(2, Handle),
            true = is_port(Socket),
            %% -- CAUTION --
            true = test(erlang, exit, [Socket,kill]),
            ok = timer:sleep(500),
            false = test(erlang, is_process_alive, [Pid])
    end.

%% == internal ==

loop(_G, C, []) -> % TODO
    C;
loop(G, C, [{P,L}|T]) ->
    X = case prefix(G, P) of
            true ->
                lists:foldl(fun(E,A) -> E(G,A) end, C, L);
            false ->
                C
        end,
    loop(G, X, T).

prefix(Atom, Binary) -> baseline_binary:prefix(atom_to_binary(Atom,latin1), Binary).
set_env(List) -> baseline_ct:set_env(List).
test(Function, Args) -> test(mgmepi, Function, Args).
test(Module, Function, Args) -> baseline_ct:test(Module, Function, Args).
