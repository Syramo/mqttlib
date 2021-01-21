%%%-----------------------------------------------------------------------------
%%% @author helge
%%% @copyright (C) 2021, Syramo Technologies
%%% @doc
%%% 
%%% @end
%%% Created : 08. January 2021 @ 11:46:08
%%%-----------------------------------------------------------------------------
-module(mqttdec).
-author("helge").

-include ("mqtt_types.hrl").

-export ([decode/1]).



%----------------------------------------decode raw binary into control packet-

-spec decode (RawData) -> {ok, ControlPacket} | {error, Reason} 
    when
        RawData :: binary(),
        ControlPacket :: mqtt_ctrl_pac(),
        Reason :: mqtt_pac_err().
decode (Data) ->
    try
        case mqtt_scan:sfixedhead(Data) of
            {Type, Fl, RLen, Rest} when RLen =:= byte_size(Rest) ->
                build_ctrl_packet(Type,Fl,Rest);
            {ok, _, _, _, _} ->
                {error, incomplete}
        end
    catch
        throw:Reason -> {error, Reason};
        error:{{badmatch,_},_} -> {error, malformed}
    end.


%----------------------------------------assemble control packets--------------

-spec build_ctrl_packet (Type, Flags, Data) -> ControlPacket | ?THROWS
    when    
        Type :: mqtt_pac_type(),
        Flags :: mqtt_pac_flags(),
        Data :: binary(),
        ControlPacket :: mqtt_ctrl_pac().
build_ctrl_packet (connect, <<0:4>>, Data) ->
    {Prot, R1} = mqtt_scan:sutf8_bin(Data),
    {Ver, R2} = mqtt_scan:sbyte(R1),
    {<<_:7,0:1>>=CFlags, R3} = mqtt_scan:sbyte(R2),
    CP = #connect{
        protocol = Prot,
        version = Ver,
        conn_flags = CFlags
    },
    {ok, ValidCP} = validate_ctrl_packet(CP),
    ValidCP.


%----------------------------------------validating control packets------------

-spec validate_ctrl_packet (ControlPacket) -> {ok, ControlPacket} | ?THROWS
    when
        ControlPacket :: mqtt_ctrl_pac().
validate_ctrl_packet (#connect{}=CP) ->
    <<"MQTT">> =:= CP#connect.protocol orelse throw(unsupprot),
    <<5:8>> =:= CP#connect.version orelse throw(unsupprot),
    {ok, CP};
validate_ctrl_packet (_) ->
    throw(malformed).

