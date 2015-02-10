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
-export([checkout/0, checkout/1, checkin/1]).

-export([get_version/1, get_version/2,
         check_connection/1, check_connection/2]).
-export([alloc_nodeid/1, alloc_nodeid/2, alloc_nodeid/3, alloc_nodeid/4, alloc_nodeid/5,
         end_session/1, end_session/2]).
-export([get_configuration/2, get_configuration/3,
         get_connection_configuration/2, get_connection_configuration/3,
         get_node_configuration/2, get_node_configuration/3,
         get_nodes_configuration/2, get_nodes_configuration/3,
         get_system_configuration/1, get_system_configuration/2]).
-export([listen_event/2, listen_event/3, get_event/1]).

%% -- internal --
-record(mgmepi, {
          sup    :: pid(),
          worker :: pid()
         }).

-type(mgmepi() :: #mgmepi{}).

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


-spec checkout() -> {ok,mgmepi()}|{error,_}.
checkout() ->
    checkout(baseline_sup:children(mgmepi_sup)).

checkout([]) ->
    {error, not_found};
checkout([H|T]) ->
    case supervisor:start_child(H, []) of
        {ok, Pid} ->
            {ok, #mgmepi{sup = H, worker = Pid}};
        {error, _Reason} ->
            checkout(T)
    end.

-spec checkin(mgmepi()) -> ok.
checkin(#mgmepi{sup=S,worker=W})
  when is_pid(S), is_pid(W) ->
    supervisor:terminate_child(S, W).


-spec get_version(mgmepi()) -> {ok,integer()}|{error,_}.
get_version(Handle) ->
    get_version(Handle, ?TIMEOUT).

-spec get_version(mgmepi(),timeout()) -> {ok,integer()}|{error,_}.
get_version(#mgmepi{worker=W}, Timeout)
  when is_pid(W), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:get_version(W, Timeout).

-spec check_connection(mgmepi()) -> ok|{error,_}.
check_connection(Handle) ->
    check_connection(Handle, ?TIMEOUT).

-spec check_connection(mgmepi(),timeout()) -> ok|{error,_}.
check_connection(#mgmepi{worker=W}, Timeout)
  when is_pid(W), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:check_connection(W, Timeout).


-spec alloc_nodeid(mgmepi()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Handle) ->
    alloc_nodeid(Handle, 0).

-spec alloc_nodeid(mgmepi(),integer()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Handle, Node) ->
    alloc_nodeid(Handle, Node, <<>>).

-spec alloc_nodeid(mgmepi(),integer(),binary()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Handle, Node, Name) ->
    alloc_nodeid(Handle, Node, Name, true).

-spec alloc_nodeid(mgmepi(),integer(),binary(),boolean()) -> {ok,integer()}|{error,_}.
alloc_nodeid(Handle, Node, Name, LogEvent) ->
    alloc_nodeid(Handle, Node, Name, LogEvent, ?TIMEOUT).

-spec alloc_nodeid(mgmepi(),integer(),binary(),boolean(),timeout()) -> {ok,integer()}|{error,_}.
alloc_nodeid(#mgmepi{worker=W}, Node, Name, LogEvent, Timeout)
  when is_pid(W), (0 =:= Node orelse ?IS_NODE(Node)),
       is_binary(Name), ?IS_BOOLEAN(LogEvent), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:alloc_nodeid(W, Node, Name, LogEvent, Timeout).

-spec end_session(mgmepi()) -> {ok,integer()}|{error,_}.
end_session(Handle) ->
    end_session(Handle, ?TIMEOUT).

-spec end_session(mgmepi(),timeout()) -> {ok,integer()}|{error,_}.
end_session(#mgmepi{worker=W}, Timeout)
  when is_pid(W), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:end_session(W, Timeout).


-spec get_configuration(mgmepi(),integer()) -> {ok,config()}|{error,_}.
get_configuration(Handle, Version) ->
    get_configuration(Handle, Version, ?TIMEOUT).

-spec get_configuration(mgmepi(),integer(),timeout()) -> {ok,config()}|{error,_}.
get_configuration(#mgmepi{worker=W}, Version, Timeout)
  when is_pid(W), ?IS_VERSION(Version), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:get_configuration(W, Version, Timeout).

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


-spec listen_event(mgmepi(),[{integer(),integer()}]) -> {ok,reference()}|{error,_}.
listen_event(Handle, Filter) ->
    listen_event(Handle, Filter, ?TIMEOUT).

-spec listen_event(mgmepi(),[{integer(),integer()}],timeout()) -> {ok,reference()}|{error,_}.
listen_event(#mgmepi{worker=W}, Filter, Timeout)
  when is_list(Filter), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:listen_event(W, Filter, Timeout).

-spec get_event(binary()) -> [{binary(),term()}].
get_event(Binary)
  when is_binary(Binary) ->
    mgmepi_protocol:get_event(Binary).
