%% =============================================================================
%% Copyright 2013-2014 AONO Tomohiko
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

-module(mgmepi_socket).

-include("internal.hrl").

%% -- public --
-export([connect/4, close/1]).
-export([setopts/2, setopt_active/2]).
-export([recv/2, recv/3, send/3]).
-export([match/2, parse/3, parse/4, split/2]).

%% -- private --
-record(handle, {
          socket :: port(), % gen_tcp:socket(), >> mgmepi_server.erl
          timeout = 3000 :: timeout(),
          field_separator = binary:compile_pattern(<<?FS>>) :: binary:cp(),
          line_separator  = binary:compile_pattern(<<?LS>>) :: binary:cp(),
          end_of_protocol = binary:compile_pattern(<<?LS,?LS>>) :: binary:cp(),
          buf = <<>> :: binary()
         }).

-type(handle() :: #handle{}).

%% == public ==

-spec connect(inet:ip_address()|inet:hostname(),inet:port_number(),
              [gen_tcp:connect_option()],timeout()) -> {ok,handle()}|{error,_}.
connect(Address, Port, Options, Timeout) ->
    try gen_tcp:connect(Address, Port, Options, Timeout) of
        {ok, Socket} ->
            {ok, #handle{socket = Socket}};
        {error, Reason} ->
            {error, Reason}
    catch
        _:Reason ->
            {error, Reason}
    end.

-spec close(handle()) -> ok.
close(#handle{socket=S}) ->
    gen_tcp:close(S).


-spec setopts(handle(),[gen_tcp:option()]) -> boolean().
setopts(#handle{socket=S}, Options) ->
    ok =:= inet:setopts(S, Options).

-spec setopt_active(handle(),atom()|integer()) -> boolean().
setopt_active(Handle, Value) ->
    setopts(Handle, [{active,Value}]).


-spec recv(handle(),integer()) -> {ok,binary(),handle()}|{error,_}.
recv(#handle{end_of_protocol=E,buf=B}=H, Length) ->
    case recv(H#handle{buf = <<>>}, B, E) of
        {ok, Binary, Handle} when (Length - 1) =:= size(Binary) -> % CAUTION
            {ok, Binary, Handle};
        {error, Reason} ->
            {error, Reason}
    end.

-spec recv(handle(),binary(),undefined|binary:cp()) -> {ok,binary(),handle()}|{error,_}.
recv(#handle{end_of_protocol=E}=H, Binary, undefined) ->
    recv(H, Binary, E);
recv(#handle{buf= <<>>}=H, Binary, Pattern) ->
    recv(H, Binary, Pattern, binary:matches(Binary,Pattern));
recv(#handle{buf=B}=H, Binary, Pattern) ->
    recv(H#handle{buf = <<>>}, <<B/binary,Binary/binary>>, Pattern).

-spec send(handle(),binary(),[fragment()]) -> ok.
send(#handle{socket=S}, Cmd, Args) ->
    B = << <<K/binary,?FS,V/binary,?LS>> || {K,V} <- Args >>,
    gen_tcp:send(S, <<Cmd/binary,?LS,B/binary,?LS>>).


-spec match([argument()],[fragment()]) -> {[property()],[fragment()]}.
match(List1, List2) ->
    match(List1, List2, []).

-spec parse(handle(),[argument()],binary()) -> {[property()],[fragment()]}.
parse(#handle{field_separator=P}=H, List, Binary) ->
    parse(H, List, Binary, P).

-spec parse(handle(),[argument()],binary(),binary:cp()) -> {[property()],[fragment()]}.
parse(#handle{line_separator=P}, List, Binary, Pattern) ->
    match(List, [ split(E,Pattern) || E <- split(Binary,P) ], []).

%% == private ==

match([], Rest, List) ->
    {lists:reverse(List), Rest};
match([{K,string,_}|L], [[K,V]|R], List) ->
    match(L, R, [{K,V}|List]);
match([{K,integer,_}|L], [[K,V]|R], List) ->
    match(L, R, [{K,binary_to_integer(V)}|List]);
match([{K,null,_}|L],[[K]|R], List) ->
    match(L, R, List);
match([{K,V,_}|L], [[K,V]|R], List) ->
    match(L, R, [{K,V}|List]);
match([{_,_,optional}|L], R, List) ->
    match(L, R, List).

recv(#handle{socket=S,timeout=T}=H, Binary, Pattern, []) ->
    case gen_tcp:recv(S, 0, T) of
        {ok, Packet} ->
            recv(H, <<Binary/binary,Packet/binary>>, Pattern);
        {error, Reason} ->
            {error, Reason}
    end;
recv(#handle{}=H, Binary, _Pattern, Parts) ->
    [R|L] = split(Binary, 0, Parts, []),
    {ok, list_to_binary(lists:reverse(L)), H#handle{buf = R}}.

split(Subject, Pattern) ->
    lists:reverse(split(Subject,0,binary:matches(Subject,Pattern),[])).

split(Subject, Start, [], List) ->
    [binary:part(Subject,Start,size(Subject)-Start)|List];
split(Subject, Start, [{P,L}|T], List) ->
    split(Subject, P+L, T, [binary:part(Subject,Start,P-Start)|List]).
