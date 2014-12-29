#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ebin -config priv/conf/n1 -s mgmepi

%% 6.4.0=394240, 7.0.27=458779, 7.1.16=459024, 7.5.6=459525

run(3, Pid) ->
    L = [<<"256=15 ">>,<<"257=15 ">>,<<"258=15 ">>],
    case mgmepi_protocol:listen_event(Pid,L) of
        {ok, Ref} ->
            handle(Ref, 10)
    end;
run(2, Pid) ->
    L = [
         394239,394240, 458778,458779, 459023,459024
        ],
    F = fun (E) ->
                io:format("server=~p, ", [E]),
                case mgmepi_protocol:get_configuration(Pid, E) of
                    {ok, C} ->
                        mgmepi_config:get_connection(C, 201, tcp)
                end
        end,
    [ F(E) || E <- L ];
run(1, Pid) ->
    V = 459525,
    L = [
         {true,  fun(E) -> mgmepi_protocol:get_version(E) end},
         {false,  fun(E) -> mgmepi_protocol:alloc_nodeid(E,201,<<"x1">>,1) end},
         {true,  fun(E) -> mgmepi_protocol:check_connection(E) end},
         {false, fun(E) -> mgmepi_protocol:get_status(E) end},
         {false, fun(E) -> mgmepi_protocol:get_status2(E,[2]) end},
         {false, fun(E) -> mgmepi_protocol:get_status2(E,[1,2]) end},
         {false, fun(E) -> mgmepi_protocol:dump_state(E,1,[1000]) end},
         {false, fun(E) -> mgmepi_protocol:start(E,V) end},
         {false, fun(E) -> mgmepi_protocol:start(E,V,[4,7]) end},
         {false, fun(E) -> mgmepi_protocol:stop(E,V,0) end},
         {false, fun(E) -> mgmepi_protocol:stop(E,V,0,[1,2]) end},
         {false, fun(E) -> mgmepi_protocol:stop(E,V,0,0,[4]) end},
         {false, fun(E) -> mgmepi_protocol:restart(E,V,0,1,0) end},
         {false, fun(E) -> mgmepi_protocol:restart(E,V,0,0,1,0,[4]) end},
         {false, fun(E) -> mgmepi_protocol:get_clusterlog_severity_filter(E) end},
         {false, fun(E) -> mgmepi_protocol:set_clusterlog_severity_filter(E,2,1) end},
         {false, fun(E) -> mgmepi_protocol:get_clusterlog_severity_filter(E) end},
         {false, fun(E) -> mgmepi_protocol:get_clusterlog_loglevel(E) end},
         {false, fun(E) -> mgmepi_protocol:set_clusterlog_loglevel(E,188,256,0) end},
         {false, fun(E) -> mgmepi_protocol:get_clusterlog_loglevel(E) end},
         {false, fun(E) -> mgmepi_protocol:start_backup(E,V,0,100,0) end},
         {false, fun(E) -> mgmepi_protocol:start_backup(E,V,1,100,0) end},
         {false, fun(E) -> mgmepi_protocol:abort_backup(E,V,100) end},
         {false, fun(E) -> mgmepi_protocol:enter_single_user(E,201) end},
         {false, fun(E) -> mgmepi_protocol:exit_single_user(E) end},
         {false, fun(E) -> mgmepi_protocol:get_configuration(E,V) end},
         {false, fun(E) -> mgmepi_protocol:get_configuration_from_node(E,V,1) end},
         {false, fun(E) -> run(2,E) end},
         {false, fun(E) -> run(3,E) end},
         {false, fun(E) -> mgmepi_protocol:create_nodegroup(E,[2,5]) end},
         {false, fun(E) -> mgmepi_protocol:drop_nodegroup(E,1) end},
         {false,  fun(E) -> mgmepi_protocol:end_session(E) end}
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
    case mgmepi_server2:start_link(["127.0.0.1",9001,L,3000]) of
        {ok, P} ->
            run(1, P),
            mgmepi_server2:stop(P)
    end.

handle(_Ref, 0) ->
    ok;
handle(Ref, N) ->
    receive
        {Ref, Term} ->
            io:format("receive[~p]: ~p~n", [N,Term]);
        _ ->
            ok
    end,
    handle(Ref, N - 1).

main(_) ->
    L = [
         %%app
         server
        ],
    [ run(0, E) || E <- L ].
