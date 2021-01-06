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
-include ("mqtt_types.hrl").

-export ([sbyte/1,sint2/1,sint4/1,svarint/1]).

%%---------------------------------------scan single bytes from stream---------

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


%%---------------------------------------scan a 2byte integer------------------

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


%%---------------------------------------scan a 4 byte integer-----------------

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


%%---------------------------------------
-spec svarint (Data) -> {ok, Int, Rest} | {error, Reason} when
        Data :: binary(),
        Int :: integer(),
        Rest :: binary(),
        Reason :: string().
svarint (<<>>) ->
    {error, ?MQTTERR_NODATA};
svarint (Data) when is_binary(Data) ->
    {B,R} = colbytes (Data,<<>>),
    case mqtt_types:is_mqtt_varint(B) of
        true -> {ok, mqtt_types:mqtt_varint_to_int(B),R};
        false -> {error, ?MQTTERR_INVDATA}
    end;
svarint (_) ->
    {error, ?MQTTERR_INVDATA}.

-spec colbytes (Data, Acc) -> {VBytes, Rest} when
        Data :: binary(),
        Acc :: binary(),
        VBytes :: mqtt_varint(),
        Rest ::  binary().
colbytes (R,Acc) when byte_size(Acc) =:= ?MAX_VARINT_BYTES ->
    {Acc,R};
colbytes (<<0:1,A:7,R/binary>>,Acc) ->
    {<<Acc/binary,0:1,A:7>>,R};
colbytes (<<1:1,A:7,R/binary>>,Acc) ->
    colbytes(R,<<Acc/binary,1:1,A:7>>).