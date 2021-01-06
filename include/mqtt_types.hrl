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

