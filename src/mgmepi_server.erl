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
          handle :: tuple(),         % mgmepi_socket::handle()
          from :: {pid(),term()},
          params :: [argument()],
          pattern :: binary:cp(),
          callback :: function()
         }).

-define(SOCKET(Handle), element(2,Handle)). % !CAUTION!

%% == private ==

-spec start_link(proplists:proplist()) -> {ok,pid()}|{error,_}.
start_link(Args)
  when is_list(Args) ->
    case gen_server:start_link(?MODULE, [], []) of
        {ok, Pid} ->
            case call(Pid, {connect,Args}) of
                ok ->
                    {ok, Pid};
                {error, Reason} ->
                    ok = stop(Pid),
                    {error, Reason}
            end
    end.

-spec stop(pid()) -> ok.
stop(Pid)
  when is_pid(Pid) ->
    cast(Pid, stop).


-spec call(pid(),term()) -> term().
call(Pid, Term)
  when is_pid(Pid) ->
    gen_server:call(Pid, Term, infinity). % timeout -> socket

-spec cast(pid(),term()) -> ok.
cast(Pid, Term)
  when is_pid(Pid) ->
    gen_server:cast(Pid, Term).

%% == behaviour: gen_server ==

init(Args) ->
    setup(Args).

terminate(_Reason, State) ->
    cleanup(State).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

handle_call(Request, From, #state{handle=H}=S)
  when undefined =/= H ->
    ready(Request, From, S);
handle_call(Request, From, State) ->
    initialized(Request, From, State).

handle_cast(stop, State) ->
    {stop, normal, State};
handle_cast({active,Pattern,Callback,From}, State) ->
    ready({active,Pattern,Callback,From}, State);
handle_cast(_Request, State) ->
    {noreply, State}.

handle_info({tcp,Socket,Data}, #state{handle=H,from=F}=S)
  when Socket =:= ?SOCKET(H), undefined =/= F ->
    accepted(Data, S);
handle_info({'EXIT',_Pid,Reason}, State) ->
    {stop, Reason, State};
handle_info(_Info, State) ->
    {noreply, State}.

%% == internal ==

cleanup(#state{handle=H}=S)
  when undefined =/= H ->
    ok = mgmepi_socket:close(H),
    cleanup(S#state{handle = undefined});
cleanup(#state{}) ->
    baseline:flush().

setup([]) ->
    _ = process_flag(trap_exit, true),
    {ok, #state{}}.


initialized({connect,Args}, _From, #state{handle=undefined}=S) ->
    case apply(mgmepi_socket, connect, Args) of
        {ok, Handle} ->
            {reply, ok, S#state{handle = Handle}};
        {error, Reason} ->
            {stop, {error,Reason}, {error,Reason}, S}
    end.


ready({active,Pattern,Callback,From}, #state{handle=H,from=undefined}=S) ->
    case mgmepi_socket:setopt_active(H, once) of
        true ->
            {noreply, S#state{from = From, pattern = Pattern, callback = Callback}}
    end;
ready(_Request, #state{from=F}=S)
  when undefined =/= F ->
    {reply, {error,ebusy}, S};
ready(_Request, State) ->
    {noreply, State}.

ready({call,Cmd,Args,Params,Callback}, From, #state{handle=H,from=undefined}=S) ->
    case mgmepi_socket:setopt_active(H, once) andalso mgmepi_socket:send(H, Cmd, Args) of
        ok ->
            {noreply, S#state{from = From, params = Params, callback = Callback}}
    end;
ready(_Request, _From, #state{from=F}=S)
  when undefined =/= F ->
    {reply, {error,ebusy}, S};
ready(_Request, _From, State) ->
    {noreply, State}.


accepted(Binary, #state{handle=H,pattern=P,callback=C}=S) ->
    %%io:format("accepted=~p~n", [Binary]),
    case mgmepi_socket:setopt_active(H, false) andalso mgmepi_socket:recv(H, Binary, P) of
        {ok, Packet, Handle} ->
            received(Packet, S#state{handle = Handle}, C);
        {error, Reason} ->
            {stop, {error,Reason}, S}
    end.

received(Binary, #state{params=P}=S, undefined) ->
    %%io:format("received=~p~n", [Binary]),
    received(Binary, S, fun(H,B) -> {L,_} = mgmepi_socket:parse(H,P,B), {ok,L,H} end);
received(Binary, #state{handle=H,from=F}=S, Callback) ->
    %%io:format("received=~p~n", [Binary]),
    case Callback(H, Binary) of
        {ok, Reply, Handle} ->
            _ = gen_server:reply(F, {ok,Reply}),
            {noreply, S#state{handle = Handle, from = undefined}};
        {continue, Reply, Handle} ->
            case mgmepi_socket:setopt_active(Handle, once) andalso Reply of
                ignore ->
                    ok;
                _ ->
                    {Pid, Ref} = F,
                    Pid ! {Ref, Reply}
            end,
            {noreply, S#state{handle = Handle}};
        {error, Reason} ->
            _ = gen_server:reply(F, {error,Reason}),
            {stop, {error,Reason}, S}
    end.
