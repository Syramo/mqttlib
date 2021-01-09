%%%-----------------------------------------------------------------------------
%%% @author helge
%%% @copyright (C) 2020, Syramo Technologies Inc.
%%% @doc
%%% 
%%% @end
%%% Created : 28. December 2020 @ 14:00:54
%%%-----------------------------------------------------------------------------
-module (mqtt_types).
-author ("helge").

-include ("mqtt_types.hrl").

-export ([is_mqtt_utf8/1, is_mqtt_int2/1, is_mqtt_int4/1, is_mqtt_varint/1, is_mqtt_binary/1]).
-export ([mqtt_utf8_to_binary/1, mqtt_utf8_to_string/1, iodata_to_mqtt_utf8/1]).
-export ([int_to_mqtt_varint/1, mqtt_varint_to_int/1]).
-export ([binary_to_mqtt_binary/1, mqtt_binary_to_binary/1]).



%%-----------------------------------------------------------------------------
%% Typen checking functions

-spec is_mqtt_utf8 (String) -> Result when
        String  :: mqtt_utf8(),
        Result :: boolean().
is_mqtt_utf8 (<<L:16,Str/binary>>) ->
    case unicode:characters_to_list(Str,unicode) of
        {error,_,_} -> false;
        {incomplete,_,_} -> false;
        Chars ->
            case io_lib:printable_unicode_list(Chars) of
                true ->
                    byte_size(Str) =:= L;
                false ->
                    false
            end
    end;
is_mqtt_utf8 (_) ->
    false.

-spec is_mqtt_binary (Data) -> Result when
        Data :: mqtt_binary(),
        Result :: boolean().
is_mqtt_binary (<<L:16,D/binary>>) ->
    case byte_size(D) of
        L -> true;
        _ -> false
    end;
is_mqtt_binary (_) ->
    false.

-spec is_mqtt_int2 (Data) -> Result when
        Data :: mqtt_int2(),
        Result :: boolean().
is_mqtt_int2 (<<_A:16>>) ->
    true;
is_mqtt_int2 (_) ->
    false.

-spec is_mqtt_int4 (Data) -> Result when
        Data :: mqtt_int4(),
        Result :: boolean().
is_mqtt_int4 (<<_A:32>>) ->
    true;
is_mqtt_int4 (_) ->
    false.

-spec is_mqtt_varint (Binary) -> Result 
    when
        Binary :: mqtt_varint(),
        Result :: boolean().
is_mqtt_varint (<<0:1,_:7>>) ->
    true;
is_mqtt_varint (<<1:1,_:7,0:1,_:7>>) ->
    true;
is_mqtt_varint (<<1:1,_:7,1:1,_:7,0:1,_:7>>) ->
    true;
is_mqtt_varint (<<1:1,_:7,1:1,_:7,1:1,_:7,0:1,_:7>>) ->
    true;
is_mqtt_varint (_) ->
    false.


%%-----------------------------------------------------------------------------
%% type conversion and construction
%%-----------------------------------------------------------------------------

%----------------------------------------MQTT-UTF8-STRINGS---------------------
-spec mqtt_utf8_to_binary (String) -> ResultBinary when
        String :: mqtt_utf8(),
        ResultBinary :: binary().
mqtt_utf8_to_binary (<<_L:16,Str/binary>>) ->
    case unicode:characters_to_binary(Str,unicode,unicode) of
        {error,B,_} -> B;
        {incomplete,B,_} -> B;
        B -> B
    end;
mqtt_utf8_to_binary (Str) when is_binary(Str) ->
    Str;
mqtt_utf8_to_binary (Str) when is_list(Str) ->
    iolist_to_binary(Str).

-spec mqtt_utf8_to_string (InString) -> ResultString when
        InString :: mqtt_utf8(),
        ResultString :: string().
mqtt_utf8_to_string (Str) ->
    binary_to_list(mqtt_utf8_to_binary(Str)).

-spec iodata_to_mqtt_utf8 (Data) -> MqttString when
        Data :: iodata(),
        MqttString :: mqtt_utf8().
iodata_to_mqtt_utf8 (Data) ->
    Str = case unicode:characters_to_binary(Data,unicode,unicode) of
        {error,B,_} -> B;
        {incomplete,B,_} -> B;
        B -> B
    end,
    L = min(byte_size(Str),65535),
    <<L:16,(binary:part(Str,{0,L}))/binary>>.


%----------------------------------------MQTT-VARINT---------------------------
-spec int_to_mqtt_varint (IntNumber) -> MqttVarInt when
        IntNumber :: integer(),
        MqttVarInt  :: mqtt_varint().
int_to_mqtt_varint (N) when is_integer(N) andalso N >= 0 andalso N < 128 ->
    <<N:8>>;
int_to_mqtt_varint (N) when is_integer(N) andalso N >= 0 andalso N < 268435455 ->
    <<1:1,(N rem 128):7,(int_to_mqtt_varint(N div 128))/binary>>.

-spec mqtt_varint_to_int (MqttVarInt) -> IntNumber when
        MqttVarInt :: mqtt_varint(),
        IntNumber :: non_neg_integer().
mqtt_varint_to_int (<<0:1,A:7>>) ->
    A;
mqtt_varint_to_int (<<1:1,A:7,0:1,B:7>>) ->
    A + B * 128;
mqtt_varint_to_int (<<1:1,A:7,1:1,B:7,0:1,C:7>>) ->
    A + B * 128 + C * 16384;
mqtt_varint_to_int (<<1:1,A:7,1:1,B:7,1:1,C:7,0:1,D:7>>) ->
    A + B * 128 + C * 16384 + D * 2097152.


%----------------------------------------MQTT-BINARY---------------------------

-spec binary_to_mqtt_binary (Data) -> MqttBinary when
        Data :: binary(),
        MqttBinary :: mqtt_binary().
binary_to_mqtt_binary (Data) ->
    L = byte_size(Data),
    <<L:16,Data/binary>>.

-spec mqtt_binary_to_binary (MqttBinary) -> Binary when
        MqttBinary :: mqtt_binary(),
        Binary :: binary().
mqtt_binary_to_binary (<<_:16,D/binary>>) ->
    D.

