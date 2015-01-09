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
                                get_version_test
                               ]}
            ].

init_per_suite(Config) ->
    ok = application:load(mgmepi),
    Config.

init_per_group(Group, Config) ->
    init_per_group(Group, Config, prefix(Group,<<"pool_">>)).

init_per_group(_Group, Config, false) ->
    Config;
init_per_group(Group, Config, true) ->
    [ ok = application:set_env(mgmepi,P,V) || {P,V} <- ct:get_config(Group,Config) ],
    ok = test(start, []),
    init_per_group(Group, Config, false).

end_per_group(Group, Config) ->
    end_per_group(Group, Config, prefix(Group,<<"pool_">>)).

end_per_group(_Group, Config, false) ->
    Config;
end_per_group(Group, Config, _) ->
    ok = test(stop, []),
    end_per_group(Group, Config, false).

%% == test ==

version_test(_Config) ->
    X = [
         { [], [0,1] }
        ],
    [ E = test(version,A) || {A,E} <- X ].

%% -- group: test_normal --

get_version_test(_Config) ->
    X = [
         { [], {ok,?NDB_VERSION_ID} }
        ],
    [ E = test(get_version,A) || {A,E} <- X ].

%% == other ==

prefix(Atom, Binary) ->
    nomatch =/= binary:match(atom_to_binary(Atom,latin1), Binary, [{scope,{0,size(Binary)}}]).

test(Function, Args) ->
    baseline_ct:test(mgmepi, Function, Args).
