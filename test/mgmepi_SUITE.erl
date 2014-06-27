%% =============================================================================
%% =============================================================================

-module(mgmepi_SUITE).

-include("internal.hrl").

%% -- callback: ct --
-export([all/0]).
-export([init_per_suite/1, end_per_suite/1]).

%% -- public --
-export([
         flush_test/1
        ]).

%% == callback: ct ==

all() -> [
          flush_test
         ].

init_per_suite(Config) ->
    L = [
         %{mnesia, dir, ?config(priv_dir,Config)}
        ],
    [ application:set_env(A,P,V) || {A,P,V} <- L ],
    Config.

end_per_suite(Config) ->
    Config.

%% == public ==

flush_test(_Config) ->
    ct:log("info: ~p~n", [mnesia:info()]).

%% == private ==

%%test(Function, Args) ->
%%    baseline_ct:test(baseline, Function, Args).
