#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ebin -config priv/conf/n1 -s mgmepi

-include_lib("mgmepi/include/mgmepi.hrl").

%% 6.4.0=394240, 7.0.27=458779, 7.1.16=459024, 7.5.6=459525

run(3, Pid) ->
    L = [
         {?NDB_MGM_EVENT_CATEGORY_STATISTIC,  15},
         {?NDB_MGM_EVENT_CATEGORY_CHECKPOINT, 15},
         {?NDB_MGM_EVENT_CATEGORY_WARNING,    15}
        ],
    T = infinity,
    case mgmepi_protocol:listen_event(Pid,L,T) of
        {ok, R}->
            io:format("wait...\n"),
            handle(R, 10)
    end;
run(2, Pid) ->
    L = [
         394239,394240, 458778,458779, 459023,459024
        ],
    T = infinity,
    F = fun (E) ->
                io:format("server=~p, ", [E]),
                case mgmepi_protocol:get_configuration(Pid, E, T) of
                    {ok, C} ->
                        mgmepi_config:get_connection(C, 201, tcp)
                end
        end,
    [ F(E) || E <- L ];
run(1, Pid) ->
    V = 459525,
    T = timer:seconds(3),
    L = [
         {true,  fun(E) -> mgmepi_protocol:get_version(E,T) end},
         {false, fun(E) -> mgmepi_protocol:alloc_nodeid(E,201,<<"x1">>,false,T) end},
         {false, fun(E) -> mgmepi_protocol:check_connection(E,T) end},
         {false, fun(E) -> mgmepi_protocol:get_status(E,T) end},
         {false, fun(E) -> mgmepi_protocol:get_status2(E,[2],T) end},
         {false, fun(E) -> mgmepi_protocol:get_status2(E,[1,2],T) end},
         {false, fun(E) -> mgmepi_protocol:dump_state(E,1,[1000],T) end},
         {false, fun(E) -> mgmepi_protocol:start(E,V,T) end},
         {false, fun(E) -> mgmepi_protocol:start(E,V,[1,4],T) end},
         {false, fun(E) -> mgmepi_protocol:stop(E,V,0,T) end},
         {false, fun(E) -> mgmepi_protocol:stop(E,V,0,[1,2],T) end},
         {false, fun(E) -> mgmepi_protocol:stop(E,V,0,0,[4],T) end},
         {false, fun(E) -> mgmepi_protocol:restart(E,V,0,1,0,T) end},
         {false, fun(E) -> mgmepi_protocol:restart(E,V,0,0,1,0,[4],T) end},
         {false, fun(E) -> mgmepi_protocol:get_clusterlog_severity_filter(E,T) end},
         {false, fun(E) -> mgmepi_protocol:set_clusterlog_severity_filter(E,2,1,T) end},
         {false, fun(E) -> mgmepi_protocol:get_clusterlog_severity_filter(E,T) end},
         {false, fun(E) -> mgmepi_protocol:get_clusterlog_loglevel(E,T) end},
         {false, fun(E) -> mgmepi_protocol:set_clusterlog_loglevel(E,188,256,0,T) end},
         {false, fun(E) -> mgmepi_protocol:get_clusterlog_loglevel(E,T) end},
         {false, fun(E) -> mgmepi_protocol:start_backup(E,V,0,100,0,T) end},
         {false, fun(E) -> mgmepi_protocol:start_backup(E,V,1,100,0,T) end},
         {false, fun(E) -> mgmepi_protocol:abort_backup(E,V,100,T) end},
         {false, fun(E) -> mgmepi_protocol:enter_single_user(E,201,T) end},
         {false, fun(E) -> mgmepi_protocol:exit_single_user(E,T) end},
         {false, fun(E) -> mgmepi_protocol:get_configuration(E,V,T) end},
         {false, fun(E) -> mgmepi_protocol:get_configuration_from_node(E,V,1,T) end},
         {false, fun(E) -> run(2,E) end},
         {false, fun(E) -> run(3,E) end},
         {false, fun(E) -> mgmepi_protocol:create_nodegroup(E,[2,5],T) end},
         {false, fun(E) -> mgmepi_protocol:drop_nodegroup(E,1,T) end},
         {true,  fun(E) -> mgmepi_protocol:end_session(E,T) end}
        ],
    [ io:format("~p~n", [timer:tc(F,[Pid])]) || {true,F} <- L ];
run(0, app) ->
    N = mgmepi_pool,
    case poolboy:checkout(N) of
        P when is_pid(P)->
            run(1, P),
            poolboy:checkin(N, P)
    end;
run(0, server) ->
    L = [
         {active, false},
         {buffer, 100},
         {keepalive, true},
         {mode, binary},
         {packet, raw},
         {recbuf, 50},
         {sndbuf, 50}
        ],
    case mgmepi_server:start_link(["127.0.0.1",9001,L,3000]) of
        {ok, P} ->
            run(1, P),
            mgmepi_server:stop(P)
    end.

handle(_, 0) ->
    ok;
handle(R, N) ->
    receive
        {R, B} ->
            E = mgmepi_protocol:get_event(B),
            io:format("[~p] recv=~p~n", [N,E])
    after
        3000 ->
            ok 
    end,
    handle(R, N - 1).

main(_) ->
    L = [
         %%app
         server
        ],
    [ run(0, E) || E <- L ].
