%%%-----------------------------------------------------------------------------
%%% @author helge
%%% @copyright (C) 2020, Syramo Technologies Inc.
%%% @doc
%%% 
%%% @end
%%% Created : 28. December 2020 @ 14:02:24
%%%-----------------------------------------------------------------------------
-author ("helge").

-define (MAX_VARINT_BYTES,4).

-type mqtt_int2() :: <<_:16>>.
-type mqtt_int4() :: <<_:32>>.
-type mqtt_varint() :: <<_:8>> | <<_:16>> | <<_:24>> | <<_:32>>.

-type mqtt_utf8() :: <<_:16,_:_*8>>.
-type mqtt_binary() :: <<_:16,_:_*8>>.

-type mqtt_pac_type() :: connect | connack | publish | puback | pubrec | pubrel | pubcomp | subscribe | suback | unsubscribe | unsuback | pingreq | pingresp | disconnect | auth.
-type mqtt_pac_flags() :: <<_:4>>.
-type mqtt_pac_err() :: incomplete | malformed.


-type mqtt_properties() :: [{Key :: mqtt_varint(), Val :: byte() | mqtt_int4() | mqtt_utf8() | mqtt_binary() | mqtt_varint() | mqtt_int2()}].

%%=============================================================================
%% property id definition

-define (MQTTPR_PFI,16#01).         % Payload Format Indicator (Byte)           -> PUBLISH, Will Properties
-define (MQTTPR_MEI,16#02).         % Message Expiry Interval (Int4)            -> PUBLISH, Will Properties
-define (MQTTPR_CT,16#03).          % Content Type (Utf8)                       -> PUBLISH, Will Properties
-define (MQTTPR_RT,16#08).          % Response Topic (Utf8)                     -> PUBLISH, Will Properties
-define (MQTTPR_CD,16#09).          % Correlation Data (Binary)                 -> PUBLISH, Will Properties
-define (MQTTPR_SI,16#0B).          % Subscription Identifier (VarInt)          -> PUBLISH, SUBSCRIBE
-define (MQTTPR_SEI,16#11).         % Session Expiry Interval (Int4)            -> CONNECT, CONNACK, DISCONNECT
-define (MQTTPR_ACI,16#12).         % Assigned Client Identifier (Utf8)         -> CONNACK
-define (MQTTPR_SKA,16#13).         % Server Keep Alive (Int2)                  -> CONNACK
-define (MQTTPR_AM,16#15).          % Authentication Method (Utf8)              -> CONNECT, CONNACK, AUTH
-define (MQTTPR_AD,16#16).          % Authentication Data (Binary)              -> CONNECT, CONNACK, AUTH
-define (MQTTPR_RPI,16#17).         % Request Problem Information (Byte)        -> CONNECT
-define (MQTTPR_WDI,16#18).         % Will Delay Interval (Int4)                -> Will Properties
-define (MQTTPR_RRI,16#19).         % Request Response Information (Byte)       -> CONNECT
-define (MQTTPR_RI,16#1A).          % Response Information (Utf8)               -> CONNACK
-define (MQTTPR_SR,16#1C).          % Server Reference (Utf8)                   -> CONNACK, DISCONNECT
-define (MQTTPR_RS,16#1F).          % Reason String (Utf8)                      -> CONNACK, PUBACK, PUBREC, PUBREL, PUBCOMP, SUBACK, UNSUBACK, DISCONNECT, AUTH
-define (MQTTPR_RM,16#21).          % Receive Maximum (Int2)                    -> CONNECT, CONNACK
-define (MQTTPR_TAM,16#22).         % Topic Alias Maximum (Int2)                -> CONNECT, CONNACK
-define (MQTTPR_TA,16#23).          % Topic Alias (Int2)                        -> PUBLISH
-define (MQTTPR_MQ,16#24).          % Maximum QoS (Byte)                        -> CONNACK
-define (MQTTPR_RA,16#25).          % Retain Available (Byte)                   -> CONNACK
-define (MQTTPR_UP,16#26).          % User Property (Utf8-Pair)                 -> CONNECT, CONNACK, PUBLISH, PUBACK, PUBREC, PUBREL, PUBCOMP, SUBSCRIBE, SUBACK, UNSUBSCRIBE, UNSUBACK, DISCONNECT, AUTH, Will Properties
-define (MQTTPR_MPS,16#27).         % Maximum Packet Size (Int4)                -> CONNECT, CONNACK
-define (MQTTPR_WSA,16#28).         % Wildcard Subscription Available (Byte)    -> CONNACK
-define (MQTTPR_SIA,16#29).         % Subscription Identifier Available (Byte)  -> CONNACK
-define (MQTTPR_SIA,16#2A).         % Shared Subscription Available (Byte)      -> CONNACK


%%=============================================================================
%% control packet types

-record (connect,{
    protocol = <<4:16,"MQTT">> :: mqtt_utf8(),
    version = <<5:8>> :: byte(),
    clean_start = true :: boolean(),
    keep_alive = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties(),
    clinet_id = none :: none | mqtt_utf8(),
    will_properties = none :: none | mqtt_properties(),
    will_topic = none :: none | mqtt_utf8(),
    will_payload = none :: none | mqtt_binary(),
    will_qos = <<0:2>> :: <<_:2>>,
    will_retain = false :: boolean(),
    username = none :: none | mqtt_utf8(),
    password = none :: none | mqtt_binary()
}).

-record (connack,{
    flags = <<0:4>> :: mqtt_pac_flags(),
    properties = [] :: mqtt_properties()
}).

-record (publish,{
    flags = <<0:4>> :: mqtt_pac_flags(),
    pacid = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties()
}).

-record (puback,{
    flags = <<0:4>> :: mqtt_pac_flags(),
    pacid = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties()
}).

-record (pubrec,{
    flags = <<0:4>> :: mqtt_pac_flags(),
    pacid = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties()
}).

-record (pubrel,{
    flags = <<2:4>> :: mqtt_pac_flags(),
    pacid = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties()
}).

-record (pubcomp,{
    flags = <<0:4>> :: mqtt_pac_flags(),
    pacid = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties()
}).

-record (subscribe,{
    flags = <<2:4>> :: mqtt_pac_flags(),
    pacid = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties()
}).

-record (suback,{
    flags = <<0:4>> :: mqtt_pac_flags(),
    pacid = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties()
}).

-record (unsubscribe,{
    flags = <<2:4>> :: mqtt_pac_flags(),
    pacid = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties()
}).

-record (unsuback,{
    flags = <<0:4>> :: mqtt_pac_flags(),
    pacid = <<0:16>> :: mqtt_int2(),
    properties = [] :: mqtt_properties()
}).

-record (pingreq,{
    flags = <<0:4>> :: mqtt_pac_flags()
}).

-record (pingresp,{
    flags = <<0:4>> :: mqtt_pac_flags()
}).

-record (disconnect,{
    flags = <<0:4>> :: mqtt_pac_flags(),
    properties = [] :: mqtt_properties()
}).

-record (auth,{
    flags = <<0:4>> :: mqtt_pac_flags(),
    properties = [] :: mqtt_properties()
}).