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
         get_system_configuration/1, get_system_configuration/2]).

%% -- internal --
-record(mgmepi, {
          pool   :: pid(),
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
    checkout(false).

-spec checkout(boolean()) -> {ok,mgmepi()}|{error,_}.
checkout(Block)
  when ?IS_BOOLEAN(Block) ->
    checkout(Block, baseline_sup:children(mgmepi_sup)).

checkout(_Block, []) ->
    {error, full};
checkout(Block, [H|T]) ->
    case poolboy:checkout(H, Block) of
        full ->
            checkout(Block, T);
        Pid ->
            {ok, #mgmepi{pool = H, worker = Pid}}
    end.

-spec checkin(mgmepi()) -> ok.
checkin(#mgmepi{pool=P,worker=W})
  when is_pid(P), is_pid(W) ->
    poolboy:checkin(P, W).


-spec get_version(mgmepi()) -> {ok,integer()}|{error,_}.
get_version(#mgmepi{}=R) ->
    get_version(R, ?TIMEOUT).

-spec get_version(mgmepi(),timeout()) -> {ok,integer()}|{error,_}.
get_version(#mgmepi{worker=W}, Timeout)
  when is_pid(W), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:get_version(W, Timeout).

-spec check_connection(mgmepi()) -> ok|{error,_}.
check_connection(#mgmepi{}=R) ->
    check_connection(R, ?TIMEOUT).

-spec check_connection(mgmepi(),timeout()) -> ok|{error,_}.
check_connection(#mgmepi{worker=W}, Timeout)
  when is_pid(W), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:check_connection(W, Timeout).


-spec alloc_nodeid(mgmepi()) -> {ok,integer()}|{error,_}.
alloc_nodeid(#mgmepi{}=R) ->
    alloc_nodeid(R, 0).

-spec alloc_nodeid(mgmepi(),integer()) -> {ok,integer()}|{error,_}.
alloc_nodeid(#mgmepi{}=R, Node) ->
    alloc_nodeid(R, Node, <<>>).

-spec alloc_nodeid(mgmepi(),integer(),binary()) -> {ok,integer()}|{error,_}.
alloc_nodeid(#mgmepi{}=R, Node, Name) ->
    alloc_nodeid(R, Node, Name, true).

-spec alloc_nodeid(mgmepi(),integer(),binary(),boolean()) -> {ok,integer()}|{error,_}.
alloc_nodeid(#mgmepi{}=R, Node, Name, LogEvent) ->
    alloc_nodeid(R, Node, Name, LogEvent, ?TIMEOUT).

-spec alloc_nodeid(mgmepi(),integer(),binary(),boolean(),timeout()) -> {ok,integer()}|{error,_}.
alloc_nodeid(#mgmepi{worker=W}, Node, Name, LogEvent, Timeout)
  when is_pid(W), (0 =:= Node orelse ?IS_NODE(Node)),
       is_binary(Name), ?IS_BOOLEAN(LogEvent), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:alloc_nodeid(W, Node, Name, LogEvent, Timeout).

-spec end_session(mgmepi()) -> {ok,integer()}|{error,_}.
end_session(#mgmepi{}=R) ->
    end_session(R, ?TIMEOUT).

-spec end_session(mgmepi(),timeout()) -> {ok,integer()}|{error,_}.
end_session(#mgmepi{worker=W}, Timeout)
  when is_pid(W), ?IS_TIMEOUT(Timeout) ->
    mgmepi_protocol:end_session(W, Timeout).


-spec get_configuration(mgmepi(),integer()) -> {ok,config()}|{error,_}.
get_configuration(#mgmepi{}=R, Version) ->
    get_configuration(R, Version, ?TIMEOUT).

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

-spec get_system_configuration(config()) -> [config()].
get_system_configuration(Config) ->
    get_system_configuration(Config, false).

-spec get_system_configuration(config(),boolean()) -> [config()].
get_system_configuration(Config, Debug)
  when ?IS_CONFIG(Config), ?IS_BOOLEAN(Debug) ->
    mgmepi_config:get_system(Config, Debug).
