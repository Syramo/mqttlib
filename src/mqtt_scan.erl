%%%-----------------------------------------------------------------------------
%%% @author helge
%%% @copyright (C) 2021, Syramo Technologies
%%% @doc
%%% 
%%% @end
%%% Created : 03. January 2021 @ 02:22:53
%%%-----------------------------------------------------------------------------
-module(mqtt_scan).
-author("helge").

-include ("mqtt_errors.hrl").

-export ([sbyte/1,sint2/1,sint4/1]).

-spec sbyte (Data) -> {ok, Byte, Rest} | {error, Reason} when
        Data :: binary(),
        Byte :: <<_:8>>,
        Rest :: binary(),
        Reason :: string().
sbyte (<<B:8,R/binary>>) ->
    {ok, B, R};
sbyte (<<>>) ->
    {error, ?MQTTERR_NODATA};
sbyte (_) ->
    {error, ?MQTTERR_INVDATA}.


-spec sint2 (Data) -> {ok, Int, Rest} | {error, Reason} when
        Data :: binary(),
        Int :: integer(),
        Rest :: binary(),
        Reason :: string().
sint2 (<<A:16/big,R/binary>>) ->
    {ok, A, R};
sint2 (X) when is_binary(X) ->
    {error, ?MQTTERR_NODATA};
sint2 (_) ->
    {errorm, ?MQTTERR_INVDATA}.


-spec sint4 (Data) -> {ok, Int, Rest} | {error, Reason} when
        Data :: binary(),
        Int :: integer(),
        Rest :: binary(),
        Reason :: string().
sint4 (<<A:32/big,R/binary>>) ->
    {ok, A, R};
sint4 (X) when is_binary(X) ->
    {error, ?MQTTERR_NODATA};
sint4 (_) ->
    {errorm, ?MQTTERR_INVDATA}.

