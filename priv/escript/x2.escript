#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ebin -config priv/conf/n2 -s mgmepi

main(_) ->
    case mgmepi:checkout() of
        {ok, Pid} ->
            {ok, Version} = mgmepi:get_version(Pid),
            case mgmepi:get_configuration(Pid, Version) of
                {ok, Config} ->
                    io:format("~p~n", [mgmepi:get_system_configuration(Config,true)]),
                    io:format("~p~n", [mgmepi:get_node_configuration(Config,91,true)]),
                    io:format("~p~n", [mgmepi:get_connection_configuration(Config,201,true)]),
                    ok
            end,
            mgmepi:checkin(Pid)
    end.
