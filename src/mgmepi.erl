%% =============================================================================
%% Copyright 2013-2015 AONO Tomohiko
%%
%% This library is free software; you can redistribute it and/or
%% modify it under the terms of the GNU Lesser General Public
%% License version 2.1 as published by the Free Software Foundation.
%%
%% This library is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
%% Lesser General Public License for more details.
%%
%% You should have received a copy of the GNU Lesser General Public
%% License along with this library; if not, write to the Free Software
%% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
%% =============================================================================

-module(mgmepi).

-include("internal.hrl").

%% -- public --
-export([start/0, start/1, stop/0, version/0]).
-export([get_version/0, get_version/1, get_version/2,
         check_connection/0, check_connection/1, check_connection/2]).


-export([get_config/0, get_config/1]).
-export([alloc_nodeid/2, alloc_nodeid/3, alloc_nodeid/4, alloc_nodeid/5]).

-define(TIMEOUT, 3000).

%% == public ==

-spec start() -> ok|{error,_}.
start() ->
    start(temporary).

-spec start(atom()) -> ok|{error,_}.
start(Type)
  when is_atom(Type) ->
    baseline_app:ensure_start(?MODULE, Type).

-spec stop() -> ok|{error,_}.
stop() ->
    application:stop(?MODULE).

-spec version() -> [non_neg_integer()].
version() ->
    baseline_app:version(?MODULE).


-spec get_version() -> {ok,integer()}|{error,_}.
get_version() ->
    get_version(mgmepi_pool).

-spec get_version(atom()) -> {ok,integer()}|{error,_}.
get_version(Pool)
  when is_atom(Pool) ->
    get_version(Pool, ?TIMEOUT).

-spec get_version(atom(),timeout()) -> {ok,integer()}|{error,_}.
get_version(Pool, Timeout)
  when is_atom(Pool) ->
    poolboy:transaction(Pool, fun(P) -> mgmepi_protocol:get_version(P,Timeout) end).

-spec check_connection() -> ok|{error,_}.
check_connection() ->
    check_connection(mgmepi_pool).

-spec check_connection(atom()) -> ok|{error,_}.
check_connection(Pool)
  when is_atom(Pool) ->
    check_connection(Pool, ?TIMEOUT).

-spec check_connection(atom(),timeout()) -> ok|{error,_}.
check_connection(Pool, Timeout)
  when is_atom(Pool) ->
    poolboy:transaction(Pool, fun(P) -> mgmepi_protocol:check_connection(P,Timeout) end).


-spec alloc_nodeid(integer(),boolean()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Node, LogEvent)
  when (0 =:= Node orelse ?IS_NODE(Node)), ?IS_BOOLEAN(LogEvent) ->
    alloc_nodeid(Node, undefined, LogEvent).

-spec alloc_nodeid(integer(),term(),boolean()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Node, Name, LogEvent)
  when (0 =:= Node orelse ?IS_NODE(Node)), ?IS_BOOLEAN(LogEvent) ->
    alloc_nodeid(mgmepi_pool, Node, Name, LogEvent).

-spec alloc_nodeid(atom(),integer(),term(),boolean()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pool, Node, Name, LogEvent)
  when is_atom(Pool), (0 =:= Node orelse ?IS_NODE(Node)), ?IS_BOOLEAN(LogEvent) ->
    alloc_nodeid(Pool, Node, Name, LogEvent, ?TIMEOUT).

-spec alloc_nodeid(atom(),integer(),term(),boolean(),timeout()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pool, Node, Name, LogEvent, Timeout)
  when is_atom(Pool), (0 =:= Node orelse ?IS_NODE(Node)), ?IS_BOOLEAN(LogEvent) ->
    poolboy:transaction(Pool, fun(P) -> mgmepi_protocol:alloc_nodeid(P,Node,Name,LogEvent,Timeout) end).


%% --

get_config() ->
    get_config(mgmepi_pool).

get_config(Pool) ->
    case poolboy:checkout(Pool) of
        Pid ->
            Result = case mgmepi_protocol:get_version(Pid, ?TIMEOUT) of
                         {ok, Version} ->
                             case mgmepi_protocol:get_configuration(Pid, Version, ?TIMEOUT) of
                                 {ok, Config} ->
                                     mgmepi_config:get_connection(Config, 201, tcp)
                             end
                     end,
            ok = poolboy:checkin(Pool, Pid),
            Result
    end.
