%%%-----------------------------------------------------------------------------
%%% @author helge
%%% @copyright (C) 2021, Syramo Technologies
%%% @doc
%%% 
%%% @end
%%% Created : 19. January 2021 @ 15:19:20
%%%-----------------------------------------------------------------------------
-module(user_default).
-author("helge").

-export ([load_cps/0]).

load_cps () ->
    case code:priv_dir(mqttlib) of 
        {error, bad_name} -> #{};
        Priv ->
            {ok, [Cps|_]} = file:consult(filename:join(Priv,"ctrl_packets.cfg")),
            Cps
    end.