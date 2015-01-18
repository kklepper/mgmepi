#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ebin -config priv/conf/n2 -s mgmepi

%% CFG_DB_API_HEARTBEAT_INTERVAL
%% CFG_AUTO_RECONNECT

%% child_spec(List) ->
%%     io:format("~p~n", [List]),
%%     {
%%       { transporter, proplists:get_value(401,List) },
%%       { ndbepi_transporter, start_link, [List] },
%%       temporary,
%%       5000,
%%       worker,
%%       []
%%     }.

main(_) ->
    case mgmepi:checkout() of
        {ok, Pid} ->
            {ok, Version} = mgmepi:get_version(Pid),
            case mgmepi:get_configuration(Pid, Version) of
                {ok, List} ->
                    %% io:format("~p~n", [List]),
                    %% io:format("~p~n", [mgmepi_config:get_system(List,true)]),
                    %% io:format("~p~n", [mgmepi_config:get_node(List,91,true)]),
                    io:format("~p~n", [mgmepi_config:get_connection(List,201,true)]),
                    %% case baseline_sup:start_link({{one_for_one,10,1},[]}) of
                    %%     {ok, Sup} ->
                    %%         case mgmepi:alloc_nodeid(Pid) of
                    %%             {ok, Node} ->
                    %%                 [ supervisor:start_child(Sup,child_spec(E)) ||
                    %%                     E <- mgmepi_config:get_connection(List,Node)]
                    %%         end,
                    %%         io:format("~p~n", [supervisor:which_children(Sup)]),

                    %%         timer:sleep(5000),

                    %%         baseline_sup:stop(Sup)
                    %% end
                    ok
            end,
            mgmepi:checkin(Pid)
    end.
