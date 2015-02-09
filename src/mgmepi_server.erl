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

-module(mgmepi_server).

-include("internal.hrl").

%% -- private --
-export([start_link/1, stop/1]).
-export([call/2, cast/2]).

%% -- behaviour: gen_server --
-behaviour(gen_server).
-export([init/1, terminate/2, code_change/3,
         handle_call/3, handle_cast/2, handle_info/2]).

%% -- internal --
-record(state, {
          module  :: module(),
          args    :: proplist(),
          handle  :: tuple(),                   % baseline_socket::handle()
          from    :: {pid(),term()},
          pattern :: binary()|[binary()]|binary:cp(),
          timeout :: timeout()
         }).

-define(SOCKET(Handle), element(2,Handle)).     % !CAUTION!

%% == private ==

-spec start_link(proplist()) -> {ok,pid()}|{error,_}.
start_link(Args) ->
    case gen_server:start_link(?MODULE, {baseline_socket,Args}, []) of
        {ok, Pid} ->
            case call(Pid, connect) of
                ok ->
                    {ok, Pid};
                {error, Reason} ->
                    ok = stop(Pid),
                    {error, Reason}
            end
    end.

-spec stop(pid()) -> ok.
stop(Pid) ->
    cast(Pid, stop).


-spec call(pid(),term()) -> term().
call(Pid, Term) ->
    gen_server:call(Pid, Term, infinity).

-spec cast(pid(),term()) -> ok.
cast(Pid, Term) ->
    gen_server:cast(Pid, Term).

%% == behaviour: gen_server ==

init(Args) ->
    setup(Args).

terminate(_Reason, State) ->
    cleanup(State).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

handle_call({call,Packet,Term,Timeout}, _From, #state{from=undefined}=S) ->
    ready(Packet, Term, Timeout, S);
handle_call({recv,Term,Timeout}, _From, #state{from=undefined}=S) ->
    ready(Term, Timeout, S);
handle_call({active,Pattern}, From, #state{from=undefined}=S) ->
    ready(Pattern, S#state{from = From});
handle_call(connect, _From, #state{from=undefined}=S) ->
    loaded(S).

handle_cast(stop, State) ->
    {stop, normal, State}.

handle_info({tcp,Socket,Data}, #state{handle=H,from=F}=S)
  when Socket =:= ?SOCKET(H), undefined =/= F ->
    listen(Data, S);
handle_info({tcp_closed,Socket}, #state{handle=H}=S)
  when Socket =:= ?SOCKET(H) ->
    closed(tcp_closed, S);
handle_info({'EXIT',Socket,Reason}, #state{handle=H}=S)
  when Socket =:= ?SOCKET(H) ->
    closed(Reason, S).

%% == internal ==

cleanup(#state{module=M,handle=H}=S)
  when undefined =/= H ->
    ok = M:close(H),
    cleanup(S#state{handle = undefined});
cleanup(#state{}) ->
    baseline:flush().

setup({Module,Args}) ->
    _ = process_flag(trap_exit, true),
    {ok, #state{module = Module, args = Args}}.


loaded(#state{module=M,args=A,handle=undefined}=S) ->
    case apply(M, connect, A) of
        {ok, Handle} ->
            {reply, ok, S#state{handle = Handle}};
        {error, Reason} ->
            {stop, {error,Reason}, {error,Reason}, S}
    end.


ready(Pattern, #state{module=M,handle=H,from={_,R}}=S) ->
    case M:setopt_active(H, once) of
        true ->
            {reply, {ok,R}, S#state{pattern = Pattern, timeout = timer:seconds(1)}}
    end.

ready(Term, Timeout, #state{module=M,handle=H}=S) ->
    case M:recv(H, Term, Timeout) of
        {ok, Binary, Handle} ->
            {reply, {ok,Binary}, S#state{handle = Handle}};
        {error, Reason, Handle} ->
            {stop, {error,Reason}, {error,Reason}, S#state{handle = Handle}}
    end.

ready(Packet, Term, Timeout, #state{module=M,handle=H}=S) ->
    case M:call(H, Packet, Term, Timeout) of
        {ok, Binary, Handle} ->
            {reply, {ok,Binary}, S#state{handle = Handle}};
        {error, Reason, Handle} ->
            {stop, {error,Reason}, {error,Reason}, S#state{handle = Handle}}
    end.


listen(Data, #state{module=M,handle=H,from=F,pattern=P,timeout=T}=S) ->
    case M:setopt_active(H, false) andalso M:recv(H, Data, P, T) of
        {ok, Binary, Handle} ->
            0 < size(Binary) andalso gen_server:reply(F, Binary),
            true = M:setopt_active(Handle, once),
            {noreply, S#state{handle = Handle}};
        {error, Reason, Handle} ->
            {stop, {error,Reason}, S#state{handle = Handle}}
    end.


closed(Reason, #state{}=S) ->
    {stop, Reason, S#state{handle = undefined}}.
