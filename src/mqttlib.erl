%%%-----------------------------------------------------------------------------
%%% @author helge
%%% @copyright (C) 2021, Syramo Technologies
%%% @doc
%%% 
%%% @end
%%% Created : 19. January 2021 @ 11:32:40
%%%-----------------------------------------------------------------------------
-module(mqttlib).
-author("helge").

-include ("mqtt_types.hrl").

-export ([new_cpac/1]).
-export ([has_will/1]).


%%-----------------------------------------------------------------------------
%% creration of control packets
%%-----------------------------------------------------------------------------

-spec new_cpac (Type) -> {ok, CPack} | {error, Reason}
    when
        Type :: mqtt_pac_type(),
        CPack :: mqtt_ctrl_pac(),
        Reason :: mqtt_pac_err().
new_cpac (connect) -> {ok, #connect{}};
new_cpac (_) -> {error, unsuppac}.


%%-----------------------------------------------------------------------------
%% manipulation and control packet inquiry 
%%-----------------------------------------------------------------------------

-spec has_will (CPack) -> Result
    when
        CPack :: mqtt_ctrl_pac,
        Result :: boolean().
has_will (#connect{conn_flags = <<_:5,F:1,_:2>>}) when F == 1 -> true;
has_will (_) -> false.