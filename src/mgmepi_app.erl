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

-module(mgmepi_app).

-include("internal.hrl").

%% -- behaviour: application --
-behaviour(application).
-export([start/2, prep_stop/1, stop/1]).

%% == behaviour: application ==

start(_StartType, StartArgs) ->
    baseline_sup:start_link({local, mgmepi_sup},
                            {
                              {one_for_one, 10, timer:seconds(5)},
                              get_childspecs(args(StartArgs))
                            }).

prep_stop(State) ->
    ok = baseline_sup:stop(mgmepi_sup),
    State.

stop([]) ->
    void.

%% == internal ==

args(List) ->
    args(element(2,application:get_application()), List).

args(Application, List) ->
    baseline_lists:merge(baseline_app:env(Application), List).

get_childspecs(Args) ->
    L = proplists:get_value(connect, Args),
    [ get_childspec(E,lists:nth(E,L), Args) || E <- lists:seq(1,length(L)) ]. % TODO

get_childspec(N, {H,P}, Args)
  when is_list(H), is_integer(P) ->
    {
      N,
      {
        baseline_sup,
        start_link,
        [
         {
           {simple_one_for_one, 10, timer:seconds(5)},
           [
            {
              undefined,
              {
                mgmepi_server,
                start_link,
                [
                 [
                  H,
                  P,
                  proplists:get_value(options, Args),
                  proplists:get_value(timeout, Args)
                 ]
                ]
              },
              temporary,
              timer:seconds(5),
              worker,
              [gen_server]
            }
           ]
         }
        ]
      },
      transient,
      timer:seconds(5),
      supervisor,
      []
    };
get_childspec(N, H, Args) ->
    get_childspec(N, {H,1186}, Args).
