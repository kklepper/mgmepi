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
                                             check_connection_test
                                            ]},
             {group_parallel_2, [sequence], [
                                             check_connection_test
                                            ]},
             {group_parallel_3, [sequence], [
                                             check_connection_test,
                                             alloc_nodeid_test
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
    [0,1] = test(version, []).

%% -- pool --

checkout_test(_Group, Config) ->
    case test(checkout, []) of
        {ok, Pid} ->
            [{pid,Pid}|Config];
        {error, Reason} ->
            {skip, Reason}
    end.

checkin_test(_Group, Config) ->
    case test(checkin, [?config(pid,Config)]) of
        ok ->
            proplists:delete(pid,Config);
        {error, Reason} ->
            {fail, Reason}
    end.

%% -- pid --

get_version_test(_Group, Config) ->
    case test(get_version, [?config(pid,Config)]) of
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
    ok = test(check_connection, [?config(pid,Config)]).


alloc_nodeid_test(Config) ->
    P = ?config(pid,Config),
    N = ?config(node, Config),
    L = [
         {
           [P, N],
           {error, list_to_binary([
                                   "Id ",
                                   integer_to_list(N),
                                   " already allocated by another node."
                                  ])}
         }
        ],
    [ E = test(alloc_nodeid,A) || {A,E} <- L ].

alloc_nodeid_test(Group, Config) ->
    case test(alloc_nodeid, [?config(pid,Config),0,atom_to_binary(Group,latin1)]) of
        {ok, Node} ->
            [{node,Node}|Config];
        {error, Reason} ->
            {skip, Reason}
    end.

end_session_test(_Group, Config) ->
    case test(end_session, [?config(pid,Config)]) of
        ok ->
            proplists:delete(node,Config);
        {error, Reason} ->
            {fail, Reason}
    end.

%% == internal ==

loop(_G, C, []) ->
    C;
loop(G, C, [{P,L}|T]) ->
    X = case prefix(G, P) of
            true ->
                lists:foldl(fun(E,A) -> E(G,A) end, C, L);
            false ->
                C
        end,
    loop(G, X, T).

prefix(Atom, Binary) ->
    B = atom_to_binary(Atom,latin1),
    prefix(B, size(B), Binary, size(Binary)).

prefix(Term1, Size1, Term2, Size2) ->
    Size1 >= Size2 andalso nomatch =/= binary:match(Term1, Term2, [{scope,{0,Size2}}]).

set_env([]) ->
    ok;
set_env([{P,V}|T]) ->
    ok = test(application, set_env, [mgmepi,P,V]),
    set_env(T).

test(Function, Args) ->
    test(mgmepi, Function, Args).

test(Module, Function, Args) ->
    baseline_ct:test(Module, Function, Args).
