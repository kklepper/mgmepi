%% =============================================================================
%% =============================================================================

-module(mgmepi_server2).

-include("internal.hrl").

%% -- private --
-export([start_link/1, start_link/2, stop/1]).
-export([call/2, cast/2]).

%% -- behaviour: gen_server --
-behaviour(gen_server).
-export([init/1, terminate/2, code_change/3,
         handle_call/3, handle_cast/2, handle_info/2]).

%% -- internal --

-record(state,
        {
          module  :: module(),
          args    :: proplists:proplist(),
          pattern :: binary:cp(),
          timeout :: timeout(),
          handle  :: term()                     % baseline_socket:handle()
        }).

%% == private ==

-spec start_link(config()) -> {ok,pid()}|{error,_}.
start_link(Args)
  when is_list(Args) ->
    start_link(Args, 3000).

-spec start_link(config(),timeout()) -> {ok,pid()}|{error,_}.
start_link(Args, Timeout)
  when is_list(Args) ->
    case gen_server:start_link(?MODULE, {baseline_socket,Args,Timeout}, []) of
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
stop(Pid)
  when is_pid(Pid) ->
    cast(Pid, stop).


-spec call(pid(),term()) -> term().
call(Pid, Term)
  when is_pid(Pid) ->
    gen_server:call(Pid, Term, infinity).

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

handle_call({command,Binary}, _From, #state{pattern=P,timeout=T}=S) ->
    ready(Binary, P, T, S);
handle_call({command,Binary,Pattern}, _From, #state{timeout=T}=S) ->
    ready(Binary, Pattern, T, S);
handle_call(connect, _From, State) ->
    loaded(State);
handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(stop, State) ->
    {stop, normal, State};
handle_cast(_Request, State) ->
    {noreply, State}.

handle_info({'EXIT',_Pid,Reason}, State) ->
    {stop, Reason, State};
handle_info(_Info, State) ->
    {noreply, State}.

%% == internal ==

cleanup(#state{module=M,handle=H}=S)
  when undefined =/= H ->
    ok = M:close(H),
    cleanup(S#state{handle = undefined});
cleanup(#state{}) ->
    baseline:flush().

setup({Module,Args,Timeout}) ->
    _ = process_flag(trap_exit, true),
    {ok, #state{module = Module, args = Args,
                pattern = binary:compile_pattern(<<?LS,?LS>>), timeout = Timeout}}.


loaded(#state{module=M,args=A,handle=undefined}=S) ->
    case apply(M, connect, A) of % TODO, timeout...
        {ok, Handle} ->
            {reply, ok, S#state{handle = Handle}};
        {error, Reason} ->
            {stop, {error,Reason}, {error,Reason}, S}
    end.

ready(Packet, Pattern, Timeout, #state{module=M,handle=H}=S) ->
    case M:sync(H, Packet, Pattern, Timeout) of
        {ok, Binary, Handle} ->
            {reply, {ok,Binary}, S#state{handle = Handle}};
        {error, Reason, Handle} ->
            {stop, {error,Reason}, {error,Reason}, S#state{handle = Handle}}
    end.
