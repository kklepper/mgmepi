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

-export([checkout/0, checkout/1, checkout/2, checkin/1, checkin/2]).

-export([get_version/1, get_version/2,
         check_connection/1, check_connection/2]).
-export([alloc_nodeid/1, alloc_nodeid/2, alloc_nodeid/3, alloc_nodeid/4, alloc_nodeid/5,
         end_session/1, end_session/2]).

-export([get_configuration/2, get_configuration/3,
         get_configuration_from_node/3, get_configuration_from_node/4]).

%% -- internal --
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

%% -- pool --

-spec checkout() -> {ok,pid()}|{error,_}.
checkout() ->
    checkout(mgmepi_pool).

-spec checkout(atom()|pid()) -> {ok,pid()}|{error,_}.
checkout(Pool)
  when is_atom(Pool); is_pid(Pool) ->
    checkout(Pool, true).

-spec checkout(atom()|pid(),boolean()) -> {ok,pid()}|{error,_}.
checkout(Pool, Block)
  when is_pid(Pool), ?IS_BOOLEAN(Block) ->
    case poolboy:checkout(Pool, Block) of
        full ->
            {error, full};
        Pid ->
            {ok, Pid}
    end;
checkout(Pool, Block)
  when is_atom(Pool), ?IS_BOOLEAN(Block) ->
    case baseline_sup:find(mgmepi_sup, Pool) of
        undefined ->
            {error, badarg};
        Pid ->
            checkout(Pid, Block)
    end.

-spec checkin(pid()) -> ok|{error,_}.
checkin(Worker)
  when is_pid(Worker) ->
    checkin(mgmepi_pool, Worker).

-spec checkin(atom()|pid(),pid()) -> ok|{error,_}.
checkin(Pool, Worker)
  when is_pid(Pool), is_pid(Worker) ->
    poolboy:checkin(Pool, Worker);
checkin(Pool, Worker)
  when is_atom(Pool), is_pid(Worker) ->
    case baseline_sup:find(mgmepi_sup, Pool) of
        undefined ->
            {error, badarg};
        Pid ->
            checkin(Pid, Worker)
    end.

%% -- pid --

-spec get_version(pid()) -> {ok,integer()}|{error,_}.
get_version(Pid)
  when is_pid(Pid) ->
    get_version(Pid, ?TIMEOUT).

-spec get_version(pid(),timeout()) -> {ok,integer()}|{error,_}.
get_version(Pid, Timeout)
  when is_pid(Pid), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:get_version(Pid, Timeout).

-spec check_connection(pid()) -> ok|{error,_}.
check_connection(Pid)
  when is_pid(Pid) ->
    check_connection(Pid, ?TIMEOUT).

-spec check_connection(pid(),timeout()) -> ok|{error,_}.
check_connection(Pid, Timeout)
  when is_pid(Pid), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:check_connection(Pid, Timeout).


-spec alloc_nodeid(pid()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid)
  when is_pid(Pid) ->
    alloc_nodeid(Pid, 0).

-spec alloc_nodeid(pid(),integer()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid, Node)
  when is_pid(Pid), (0 =:= Node orelse ?IS_NODE(Node)) ->
    alloc_nodeid(Pid, Node, <<>>).

-spec alloc_nodeid(pid(),integer(),binary()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid, Node, Name)
  when is_pid(Pid), (0 =:= Node orelse ?IS_NODE(Node)), is_binary(Name) ->
    alloc_nodeid(Pid, Node, Name, true).

-spec alloc_nodeid(pid(),integer(),binary(),boolean()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid, Node, Name, LogEvent)
  when is_pid(Pid), (0 =:= Node orelse ?IS_NODE(Node)),
       is_binary(Name), ?IS_BOOLEAN(LogEvent) ->
    alloc_nodeid(Pid, Node, Name, LogEvent, ?TIMEOUT).

-spec alloc_nodeid(pid(),integer(),binary(),boolean(),timeout()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid, Node, Name, LogEvent, Timeout)
  when is_pid(Pid), (0 =:= Node orelse ?IS_NODE(Node)),
       is_binary(Name), ?IS_BOOLEAN(LogEvent), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:alloc_nodeid(Pid, Node, Name, LogEvent, Timeout).

-spec end_session(pid()) -> {ok,integer()}|{error,_}.
end_session(Pid)
  when is_pid(Pid) ->
    end_session(Pid, ?TIMEOUT).

-spec end_session(pid(),timeout()) -> {ok,integer()}|{error,_}.
end_session(Pid, Timeout)
  when is_pid(Pid), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:end_session(Pid, Timeout).


-spec get_configuration(pid(),integer()) -> {ok,config()}|{error,_}.
get_configuration(Pid, Version)
  when is_pid(Pid), ?IS_VERSION(Version) ->
    get_configuration(Pid, Version, ?TIMEOUT).

-spec get_configuration(pid(),integer(),timeout()) -> {ok,config()}|{error,_}.
get_configuration(Pid, Version, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:get_configuration(Pid, Version, Timeout).

-spec get_configuration_from_node(pid(),integer(),integer()) -> {ok,config()}|{error,_}.
get_configuration_from_node(Pid, Version, Node)
  when is_pid(Pid), ?IS_VERSION(Version), ?IS_NODE(Node) ->
    get_configuration_from_node(Pid, Version, Node, ?TIMEOUT).

-spec get_configuration_from_node(pid(),integer(),integer(),timeout()) -> {ok,config()}|{error,_}.
get_configuration_from_node(Pid, Version, Node, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), ?IS_NODE(Node), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:get_configuration_from_node(Pid, Version, Node, Timeout).
