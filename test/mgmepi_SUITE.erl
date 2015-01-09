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
%% [mysqld(API)]	1 node(s)
%% id=201 (not connected, accepting connect from localhost)

all() -> [
          version_test,
          {group, pool_v73}
         ].

groups() -> [

             {pool_v73, [], [{group, test_normal}]},

             {test_normal, [], [
                                check_connection_test
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

%% == test ==

version_test(_Config) ->
    X = [
         { [], [0,1] }
        ],
    [ E = test(version,A) || {A,E} <- X ].

%% -- group: test_normal --

check_connection_test(_Config) ->
    X = [
         { [], ok }
        ],
    [ E = test(check_connection,A) || {A,E} <- X ].

%% == other ==

prefix(Atom, Binary) ->
    nomatch =/= binary:match(atom_to_binary(Atom,latin1), Binary, [{scope,{0,size(Binary)}}]).

set_env([]) ->
    ok;
set_env([{P,V}|T]) ->
    ok = test(application, set_env, [mgmepi,P,V]),
    set_env(T).

test(Function, Args) ->
    test(mgmepi, Function, Args).

test(Module, Function, Args) ->
    baseline_ct:test(Module, Function, Args).
