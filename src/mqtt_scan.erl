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

-include ("mqtt_types.hrl").

-export ([sbyte/1,sint2/1,sint4/1,svarint/1,sutf8_str/1,sutf8_bin/1,sbin/1,spair_str/1,sfixedhead/1]).

%%---------------------------------------scan single bytes from stream---------

-spec sbyte (Data) -> {ok, Byte, Rest} | {error, Reason} when
        Data :: binary(),
        Byte :: <<_:8>>,
        Rest :: binary(),
        Reason :: mqtt_pac_err().
sbyte (<<B:8,R/binary>>) ->
    {ok, B, R};
sbyte (<<>>) ->
    {error, incomplete};
sbyte (_) ->
    {error, malformed}.


%%---------------------------------------scan a 2byte integer------------------

-spec sint2 (Data) -> {ok, Int, Rest} | {error, Reason} when
        Data :: binary(),
        Int :: integer(),
        Rest :: binary(),
        Reason :: mqtt_pac_err().
sint2 (<<A:16/big,R/binary>>) ->
    {ok, A, R};
sint2 (X) when is_binary(X) ->
    {error, incomplete};
sint2 (_) ->
    {errorm, malformed}.


%%---------------------------------------scan a 4 byte integer-----------------

-spec sint4 (Data) -> {ok, Int, Rest} | {error, Reason} when
        Data :: binary(),
        Int :: integer(),
        Rest :: binary(),
        Reason :: mqtt_pac_err().
sint4 (<<A:32/big,R/binary>>) ->
    {ok, A, R};
sint4 (X) when is_binary(X) ->
    {error, incomplete};
sint4 (_) ->
    {errorm, malformed}.


%%---------------------------------------scan a up to 4 byte varint------------

-spec svarint (Data) -> {ok, Int, Rest} | {error, Reason} when
        Data :: binary(),
        Int :: integer(),
        Rest :: binary(),
        Reason :: mqtt_pac_err().
svarint (<<>>) ->
    {error, incomplete};
svarint (Data) when is_binary(Data) ->
    {B,R} = colbytes (Data,<<>>),
    case mqtt_types:is_mqtt_varint(B) of
        true -> {ok, mqtt_types:mqtt_varint_to_int(B),R};
        false -> {error, malformed}
    end;
svarint (_) ->
    {error, malformed}.

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


%%---------------------------------------scan utf8 strings-----------------------

-spec sutf8_str (Data) -> {ok, String, Rest} | {error, Reason} when
        Data :: binary(),
        String :: string(),
        Rest :: binary(),
        Reason :: mqtt_pac_err().
sutf8_str (Data) ->
    case sutf8_bin (Data) of
        {ok, Str, Rest} -> {ok, binary_to_list(Str), Rest};
        {error, Reason} -> {error, Reason}
    end.

-spec sutf8_bin (Data) -> {ok, String, Rest} | {error, Reason} when
        Data :: binary(),
        String :: binary(),
        Rest :: binary(),
        Reason :: mqtt_pac_err().
sutf8_bin (Data) ->
    case sbin(Data) of
        {ok, Bin, Rest} ->
            L = byte_size(Bin),
            case mqtt_types:is_mqtt_utf8(<<L:16,Bin/binary>>) of
                true -> {ok, Bin, Rest};
                false -> {error, malformed}
            end;
        {error, Reason} ->
            {error, Reason}
    end.


%----------------------------------------scan binaries-------------------------

-spec sbin (Data) -> {ok, Bin, Rest} | {error, Reason} when
        Data :: binary(),
        Bin :: binary(),
        Rest :: binary(),
        Reason :: mqtt_pac_err().
sbin (<<Len:16,RBin/binary>>) when byte_size(RBin) >= Len ->
    Bin = binary:part(RBin,{0,Len}),
    Rest = binary:part(RBin,{Len,byte_size(RBin)-Len}),
    {ok, Bin, Rest};
sbin (<<Len:16,RBin/binary>>) when byte_size(RBin) < Len ->
    {error, incomplete};
sbin (_) ->
    {error, malformed}.


%----------------------------------------scan string pairs---------------------

-spec spair_str (Data) -> {ok, {Key, Val}, Rest} | {error, Reason} when
        Data :: binary(),
        Key :: string(),
        Val :: string(),
        Rest :: binary(),
        Reason :: mqtt_pac_err().
spair_str (Data) ->
    case spair_bin(Data) of
        {ok, {Key, Val}, Rest} ->
            {ok, binary_to_list(Key), binary_to_list(Val), Rest};
        {error, Reason} ->
            {error, Reason}
    end.

-spec spair_bin (Data) -> {ok, {Key, Val}, Rest} | {error, Reason} when
        Data :: binary(),
        Key :: binary(),
        Val :: binary(),
        Rest :: binary(),
        Reason :: mqtt_pac_err().
spair_bin (Data) ->
    case sbin(Data) of
        {ok, Key, Rest} ->
            case sbin(Rest) of
                {ok, Val, Rem} -> 
                    {ok, {Key, Val}, Rem};
                {error, Reason} ->
                    {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.


%------------------------------------scan fixed header-------------------------

-spec sfixedhead (Data) -> {ok, Type, Flags, RestLen, Rest} | {error, Reason} when
        Data :: binary(),
        Type :: mqtt_pac_type(),
        Flags :: mqtt_pac_flags(),
        RestLen :: integer(),
        Rest :: binary(),
        Reason :: mqtt_pac_err().
sfixedhead (<<1:4,F:4,R/binary>>) when F == 0 ->  fixedhead(connect,F,R);
sfixedhead (<<2:4,F:4,R/binary>>) when F == 0 ->  fixedhead(connack,F,R);
sfixedhead (<<3:4,F:4,R/binary>>) ->  fixedhead(publish,F,R);
sfixedhead (<<4:4,F:4,R/binary>>) when F == 0 ->  fixedhead(puback,F,R);
sfixedhead (<<5:4,F:4,R/binary>>) when F == 0 ->  fixedhead(pubrec,F,R);
sfixedhead (<<6:4,F:4,R/binary>>) when F == 2 ->  fixedhead(pubrel,F,R);
sfixedhead (<<7:4,F:4,R/binary>>) when F == 0 ->  fixedhead(pubcomp,F,R);
sfixedhead (<<8:4,F:4,R/binary>>) when F == 2 ->  fixedhead(subscribe,F,R);
sfixedhead (<<9:4,F:4,R/binary>>) when F == 0 ->  fixedhead(suback,F,R);
sfixedhead (<<10:4,F:4,R/binary>>) when F == 2 ->  fixedhead(unsubscribe,F,R);
sfixedhead (<<11:4,F:4,R/binary>>) when F == 0 ->  fixedhead(unsuback,F,R);
sfixedhead (<<12:4,F:4,R/binary>>) when F == 0 ->  fixedhead(pingreq,F,R);
sfixedhead (<<13:4,F:4,R/binary>>) when F == 0 ->  fixedhead(pingresp,F,R);
sfixedhead (<<14:4,F:4,R/binary>>) when F == 0 ->  fixedhead(disconnect,F,R);
sfixedhead (<<15:4,F:4,R/binary>>) when F == 0 ->  fixedhead(auth,F,R);
sfixedhead (<<0:4,_:4,_/binary>>) ->  {error, malformed}.

-spec fixedhead(Type, Flags, Data) -> {ok, Type, Flags, RestLen, Data} | {error, Reason} when
        Type :: mqtt_pac_type(),
        Flags :: mqtt_pac_flags(),
        RestLen :: integer(),
        Data :: binary(),
        Reason :: mqtt_pac_err().
fixedhead (Type, Flags, Data) ->
    case svarint(Data) of
        {ok, Len, Rest} -> {ok, Type, Flags, Len, Rest};
        {error, Reason} -> {error, Reason}
    end.