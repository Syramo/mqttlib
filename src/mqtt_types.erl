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

-export ([is_mqtt_utf8/1,
          is_mqtt_int2/1,
          mqtt_utf8_to_binary/1,
          mqtt_utf8_to_string/1,
          iodata_to_mqtt_utf8/1
]).



%%-----------------------------------------------------------------------------
%% Typen checking functions

-spec is_mqtt_utf8 (String :: mqtt_utf8()) -> boolean().
is_mqtt_utf8 (<<L:16,Str/binary>>) ->
    case unicode:characters_to_binary(Str,unicode,unicode) of
        {error,_,_} -> false;
        {incomplete,_,_} -> false;
        _ ->
            if
                byte_size(Str) =:= L -> true;
                true -> false
            end
    end;
is_mqtt_utf8 (_) ->
    false.

-spec is_mqtt_int2 (Data :: mqtt_int2()) -> boolean().
is_mqtt_int2 (<<_A:16>>) ->
    true;
is_mqtt_int2 (_) ->
    false.





%%-----------------------------------------------------------------------------
%% type conversion and construction

-spec mqtt_utf8_to_binary (String :: mqtt_utf8()) -> binary().
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

-spec mqtt_utf8_to_string (String :: mqtt_utf8()) -> string().
mqtt_utf8_to_string (Str) ->
    binary_to_list(mqtt_utf8_to_binary(Str)).

-spec iodata_to_mqtt_utf8 (Data :: iodata()) -> mqtt_utf8().
iodata_to_mqtt_utf8 (Data) ->
    Str = case unicode:characters_to_binary(Data,unicode,unicode) of
        {error,B,_} -> B;
        {incomplete,B,_} -> B;
        B -> B
    end,
    L = min(byte_size(Str),65535),
    <<L:16,(binary:part(Str,{0,L}))/binary>>.




