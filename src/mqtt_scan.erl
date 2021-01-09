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

-spec sbyte (Data) -> {Byte, Rest} | ?THROWS
    when
        Data :: binary(),
        Byte :: <<_:8>>,
        Rest :: binary().
sbyte (<<B:8,R/binary>>) ->
    {B, R};
sbyte (<<>>) ->
    throw(incomplete);
sbyte (_) ->
    throw(malformed).


%%---------------------------------------scan a 2byte integer------------------

-spec sint2 (Data) -> {Int, Rest} | ?THROWS
    when
        Data :: binary(),
        Int :: integer(),
        Rest :: binary().
sint2 (<<A:16/big,R/binary>>) ->
    {A, R};
sint2 (X) when is_binary(X) ->
    throw(incomplete);
sint2 (_) ->
    throw(malformed).


%%---------------------------------------scan a 4 byte integer-----------------

-spec sint4 (Data) -> {Int, Rest} | ?THROWS
    when
        Data :: binary(),
        Int :: integer(),
        Rest :: binary().
sint4 (<<A:32/big,R/binary>>) ->
    {A, R};
sint4 (X) when is_binary(X) ->
     throw(incomplete);
sint4 (_) ->
    throw(malformed).


%%---------------------------------------scan a up to 4 byte varint------------

-spec svarint (Data) -> {Int, Rest} | ?THROWS
    when
        Data :: binary(),
        Int :: integer(),
        Rest :: binary().
svarint (<<>>) ->
     throw(incomplete);
svarint (Data) when is_binary(Data) ->
    {B,R} = colbytes (Data,<<>>),
    case mqtt_types:is_mqtt_varint(B) of
        true -> {mqtt_types:mqtt_varint_to_int(B),R};
        false -> throw(malformed)
    end;
svarint (_) ->
    throw(malformed).

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

-spec sutf8_str (Data) -> {String, Rest} | ?THROWS
    when
        Data :: binary(),
        String :: string(),
        Rest :: binary().
sutf8_str (Data) ->
    {Str, Rest} = sutf8_bin(Data),
    {binary_to_list(Str), Rest}.
    
-spec sutf8_bin (Data) -> {String, Rest} | ?THROWS
    when
        Data :: binary(),
        String :: binary(),
        Rest :: binary().
sutf8_bin (Data) ->
    {Bin, Rest} = sbin(Data),
    L = byte_size(Bin),
    case mqtt_types:is_mqtt_utf8(<<L:16,Bin/binary>>) of
        true -> {Bin, Rest};
        false -> throw(malformed)
    end.


%----------------------------------------scan binaries-------------------------

-spec sbin (Data) -> {Bin, Rest} | ?THROWS
    when
        Data :: binary(),
        Bin :: binary(),
        Rest :: binary().
sbin (<<Len:16,RBin/binary>>) when byte_size(RBin) >= Len ->
    Bin = binary:part(RBin,{0,Len}),
    Rest = binary:part(RBin,{Len,byte_size(RBin)-Len}),
    {Bin, Rest};
sbin (<<Len:16,RBin/binary>>) when byte_size(RBin) < Len ->
    throw(incomplete);
sbin (_) ->
    throw(malformed).


%----------------------------------------scan string pairs---------------------

-spec spair_str (Data) -> {{Key, Val}, Rest} | ?THROWS
    when
        Data :: binary(),
        Key :: string(),
        Val :: string(),
        Rest :: binary().
spair_str (Data) ->
    {{Key, Val}, Rest} = spair_bin(Data),
    {{binary_to_list(Key), binary_to_list(Val)}, Rest}.

-spec spair_bin (Data) -> {{Key, Val}, Rest} | ?THROWS
    when
        Data :: binary(),
        Key :: binary(),
        Val :: binary(),
        Rest :: binary().
spair_bin (Data) ->
    {Key, Rest} = sbin(Data),
    {Val, Rem} = sbin(Rest),
    {{Key, Val}, Rem}.


%------------------------------------scan fixed header-------------------------

-spec sfixedhead (Data) -> {Type, Flags, RestLen, Rest} | ?THROWS
    when
        Data :: binary(),
        Type :: mqtt_pac_type(),
        Flags :: mqtt_pac_flags(),
        RestLen :: integer(),
        Rest :: binary().
sfixedhead (<<1:4,F:4,R/binary>>) when F == 0 ->  fixedhead(connect,<<F:4>>,R);
sfixedhead (<<2:4,F:4,R/binary>>) when F == 0 ->  fixedhead(connack,<<F:4>>,R);
sfixedhead (<<3:4,F:4,R/binary>>) ->  fixedhead(publish,<<F:4>>,R);
sfixedhead (<<4:4,F:4,R/binary>>) when F == 0 ->  fixedhead(puback,<<F:4>>,R);
sfixedhead (<<5:4,F:4,R/binary>>) when F == 0 ->  fixedhead(pubrec,<<F:4>>,R);
sfixedhead (<<6:4,F:4,R/binary>>) when F == 2 ->  fixedhead(pubrel,<<F:4>>,R);
sfixedhead (<<7:4,F:4,R/binary>>) when F == 0 ->  fixedhead(pubcomp,<<F:4>>,R);
sfixedhead (<<8:4,F:4,R/binary>>) when F == 2 ->  fixedhead(subscribe,<<F:4>>,R);
sfixedhead (<<9:4,F:4,R/binary>>) when F == 0 ->  fixedhead(suback,<<F:4>>,R);
sfixedhead (<<10:4,F:4,R/binary>>) when F == 2 ->  fixedhead(unsubscribe,<<F:4>>,R);
sfixedhead (<<11:4,F:4,R/binary>>) when F == 0 ->  fixedhead(unsuback,<<F:4>>,R);
sfixedhead (<<12:4,F:4,R/binary>>) when F == 0 ->  fixedhead(pingreq,<<F:4>>,R);
sfixedhead (<<13:4,F:4,R/binary>>) when F == 0 ->  fixedhead(pingresp,<<F:4>>,R);
sfixedhead (<<14:4,F:4,R/binary>>) when F == 0 ->  fixedhead(disconnect,<<F:4>>,R);
sfixedhead (<<15:4,F:4,R/binary>>) when F == 0 ->  fixedhead(auth,<<F:4>>,R);
sfixedhead (<<0:4,_:4,_/binary>>) ->  throw(malformed).

-spec fixedhead(Type, Flags, Data) -> {Type, Flags, RestLen, Data} | ?THROWS 
    when
        Type :: mqtt_pac_type(),
        Flags :: mqtt_pac_flags(),
        RestLen :: non_neg_integer(),
        Data :: binary().
fixedhead (Type, <<Flags:4>>, Data) ->
    {Len, Rest} = svarint(Data),
    {Type, <<Flags:4>>, Len, Rest}.