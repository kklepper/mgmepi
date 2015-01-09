%% =============================================================================
%% =============================================================================

-module(mgmepi_SUITE).

-include("internal.hrl").

-compile(export_all).

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
          {group, pool_v73}
         ].

groups() -> [

             {pool_v73, [], [{group, test_sequence}]},

             {test_sequence, [sequence], [
                                          alloc_nodeid_test,
                                          {group, test_parallel}
                                         ]},

             {test_parallel, [parallel], [
                                          {group, test_parallel_1},
                                          {group, test_parallel_2}
                                         ]},

             {test_parallel_1, [], [
                                    check_connection_test,
                                    alloc_nodeid_test_1
                                   ]},
             {test_parallel_2, [], [
                                    check_connection_test,
                                    alloc_nodeid_test_2
                                   ]}
            ].

init_per_group(Group, Config) ->
    init_per_group(Group, Config, prefix(Group,<<"pool_">>)).

init_per_group(_Group, Config, false) ->
    Config;
init_per_group(Group, Config, true) ->
    ok = set_env(ct:get_config(Group,Config)),
    ok = test(start, []),
    case test(get_version, []) of
        {ok, Version} when ?NDB_VERSION_ID < Version ->
            {skip, max_version};
        {ok, Version} when ?VERSION(7,3,0) > Version ->
            {skip, min_version};
        {ok, Version} ->
            [{version,Version}|Config];
        {error, Reason} ->
            {skip, Reason}
    end.

end_per_group(Group, Config) ->
    end_per_group(Group, Config, prefix(Group,<<"pool_">>)).

end_per_group(_Group, Config, false) ->
    Config;
end_per_group(_Group, Config, true) ->
    ok = test(stop, []),
    proplists:delete(version,Config).

init_per_testcase(Testcase, Config) ->
    init_per_testcase(Testcase, Config, prefix(Testcase,<<"alloc_nodeid_">>)).

init_per_testcase(_Testcase, Config, false) ->
    Config;
init_per_testcase(Testcase, Config, true) ->
    {ok, Node} = test(alloc_nodeid, [0,atom_to_binary(Testcase,latin1),false]),
    ct:log("alloc_nodeid=~p", [Node]),
    [{node,Node}|Config].

end_per_testcase(TestCase, Config) ->
    end_per_testcase(TestCase, Config, ?config(node,Config)).

end_per_testcase(_TestCase, Config, undefined) ->
    Config;
end_per_testcase(_TestCase, Config, Node) ->
    ct:log("end_session=~p", [Node]),
    ok = test(end_session, []),
    proplists:delete(node,Config).

%% == test ==

version_test(_Config) ->
    X = [
         { [], [0,1] }
        ],
    [ E = test(version,A) || {A,E} <- X ].

%% -- group: test_sequence --

alloc_nodeid_test(Config) ->
    N = ?config(node,Config),
    X = [
         %% {
         %%   [0, <<"alloc_nodeid_test">>, true],
         %%   {ok, _} !
         %% }
         {
           [N, true],
           {error, list_to_binary([
                                   "Id ",
                                   integer_to_list(N),
                                   " already allocated by another node."
                                  ])}
         }
        ],
    [ E = test(alloc_nodeid,A) || {A,E} <- X ].

%% -- group: test_parallel_* --

alloc_nodeid_test_1(Config) ->
    undefined =/= ?config(node, Config).

alloc_nodeid_test_2(Config) ->
    undefined =/= ?config(node, Config).

check_connection_test(_Config) ->
    ok = test(check_connection, []).

%% == other ==

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
