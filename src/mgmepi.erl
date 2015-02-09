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
-export([checkout/0, checkin/1]).

-export([get_version/1, get_version/2,
         check_connection/1, check_connection/2]).
-export([alloc_nodeid/1, alloc_nodeid/2, alloc_nodeid/3, alloc_nodeid/4, alloc_nodeid/5,
         end_session/1, end_session/2]).
-export([get_configuration/2, get_configuration/3,
         get_connection_configuration/2, get_connection_configuration/3,
         get_node_configuration/2, get_node_configuration/3,
         get_nodes_configuration/2, get_nodes_configuration/3,
         get_system_configuration/1, get_system_configuration/2]).

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


-spec checkout() -> {ok,pid()}|{error,_}.
checkout() ->
    supervisor:start_child(mgmepi_sup, []).

-spec checkin(pid()) -> ok.
checkin(Pid)
  when is_pid(Pid) ->
    supervisor:terminate_child(mgmepi_sup, Pid).


-spec get_version(pid()) -> {ok,integer()}|{error,_}.
get_version(Pid) ->
    get_version(Pid, ?TIMEOUT).

-spec get_version(pid(),timeout()) -> {ok,integer()}|{error,_}.
get_version(Pid, Timeout)
  when is_pid(Pid), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:get_version(Pid, Timeout).

-spec check_connection(pid()) -> ok|{error,_}.
check_connection(Pid) ->
    check_connection(Pid, ?TIMEOUT).

-spec check_connection(pid(),timeout()) -> ok|{error,_}.
check_connection(Pid, Timeout)
  when is_pid(Pid), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:check_connection(Pid, Timeout).


-spec alloc_nodeid(pid()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid) ->
    alloc_nodeid(Pid, 0).

-spec alloc_nodeid(pid(),integer()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid, Node) ->
    alloc_nodeid(Pid, Node, <<>>).

-spec alloc_nodeid(pid(),integer(),binary()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid, Node, Name) ->
    alloc_nodeid(Pid, Node, Name, true).

-spec alloc_nodeid(pid(),integer(),binary(),boolean()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid, Node, Name, LogEvent) ->
    alloc_nodeid(Pid, Node, Name, LogEvent, ?TIMEOUT).

-spec alloc_nodeid(pid(),integer(),binary(),boolean(),timeout()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Pid, Node, Name, LogEvent, Timeout)
  when is_pid(Pid), (0 =:= Node orelse ?IS_NODE(Node)),
       is_binary(Name), ?IS_BOOLEAN(LogEvent), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:alloc_nodeid(Pid, Node, Name, LogEvent, Timeout).

-spec end_session(pid()) -> {ok,integer()}|{error,_}.
end_session(Pid) ->
    end_session(Pid, ?TIMEOUT).

-spec end_session(pid(),timeout()) -> {ok,integer()}|{error,_}.
end_session(Pid, Timeout)
  when is_pid(Pid), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:end_session(Pid, Timeout).


-spec get_configuration(pid(),integer()) -> {ok,config()}|{error,_}.
get_configuration(Pid, Version) ->
    get_configuration(Pid, Version, ?TIMEOUT).

-spec get_configuration(pid(),integer(),timeout()) -> {ok,config()}|{error,_}.
get_configuration(Pid, Version, Timeout)
  when is_pid(Pid), ?IS_VERSION(Version), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:get_configuration(Pid, Version, Timeout).

-spec get_connection_configuration(config(),integer()) -> [config()].
get_connection_configuration(Config, Node) ->
    get_connection_configuration(Config, Node, false).

-spec get_connection_configuration(config(),integer(),boolean()) -> [config()].
get_connection_configuration(Config, Node, Debug)
  when ?IS_CONFIG(Config), ?IS_NODE(Node), ?IS_BOOLEAN(Debug) ->
    mgmepi_config:get_connection(Config, Node, Debug).

-spec get_node_configuration(config(),integer()) -> [config()].
get_node_configuration(Config, Node) ->
    get_node_configuration(Config, Node, false).

-spec get_node_configuration(config(),integer(),boolean()) -> [config()].
get_node_configuration(Config, Node, Debug)
  when ?IS_CONFIG(Config), ?IS_NODE(Node), ?IS_BOOLEAN(Debug) ->
    mgmepi_config:get_node(Config, Node, Debug).

-spec get_nodes_configuration(config(),integer()) -> [config()].
get_nodes_configuration(Config, Type) ->
    get_nodes_configuration(Config, Type, false).

-spec get_nodes_configuration(config(),integer(),boolean()) -> [config()].
get_nodes_configuration(Config, Type, Debug)
  when ?IS_CONFIG(Config), ?IS_NODE_TYPE(Type), ?IS_BOOLEAN(Debug) ->
    mgmepi_config:get_nodes(Config, Type, Debug).

-spec get_system_configuration(config()) -> [config()].
get_system_configuration(Config) ->
    get_system_configuration(Config, false).

-spec get_system_configuration(config(),boolean()) -> [config()].
get_system_configuration(Config, Debug)
  when ?IS_CONFIG(Config), ?IS_BOOLEAN(Debug) ->
    mgmepi_config:get_system(Config, Debug).
