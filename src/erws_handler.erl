-module(erws_handler).

-include("erws_console.hrl").


% Behaviour cowboy_http_handler
-export([init/3, handle/2, terminate/3]).

% Behaviour cowboy_http_websocket_handler



% Called to know how to dispatch a new connection.
init({tcp, http}, Req, Opts) ->
    { Path, Req3} = cowboy_req:path_info(Req),
    ?CONSOLE_LOG("Request: ~p ~n", [ {Req, Path, Opts} ]),
    % we're not interested in serving any other content.
    {ok, Req3, Opts}
.
    
terminate(_Req, _State, _Reason) ->
    ok.

headers_text_plain() ->
        [ {<<"access-control-allow-origin">>, <<"*">>},  {<<"Content-Type">>, <<"text/plain">>} ].
        
headers_text_html() ->
        [ {<<"access-control-allow-origin">>, <<"*">>},  {<<"Content-Type">>, <<"text/html">>}  ].      

headers_json_plain() ->
        [ {<<"access-control-allow-origin">>, <<"*">>},  {<<"Content-Type">>, <<"application/json">>} ].
        
headers_png() ->
        [ {<<"access-control-allow-origin">>, <<"*">>},
          {<<"Cache-Control">>, <<"no-cache, must-revalidate">>},
          {<<"Pragma">>, <<"no-cache">>},
          {<<"Content-Type">>, <<"image/png">>} 
        ].
        
% Should never get here.
handle(Req, State) ->
      ?FACT_LOG("====================================~nrequest: ~p ~n", [Req]),
      {Path, Req1} = cowboy_req:path_info(Req),
      {ok, Body, Req2 } = cowboy_req:body(Req1),
      {Sign, Req3 }  = cowboy_req:header(<<"api-sign">>, Req2),
      Res = case check_sign(Sign, Body, State) of 
                true ->  ( catch echo(Path, Body, Req3) );
                false -> ?FACT_LOG("salt false ~n", []), 
                         false_response(Req3)
            end,    
      ?CONSOLE_LOG("got request result: ~p~n", [Res]),
      {ok, NewReq} = Res,      
      {ok, NewReq, State}.

terminate(_Req, _State) -> ok.

false_response(Req)->
     cowboy_req:reply(200, headers_json_plain(),<<"{\"status\":\"false\"}">> , Req).
 
 
-spec check_sign(binary(), binary(), list())-> true|false. 
check_sign(Sign, Body, State)->
    {value, {_, Salt} } = lists:keysearch(sign, 1, State),
    CheckSign = generate_key(Salt, Body),
    ?CONSOLE_LOG("got salt result: calc sign ~p~n got sign ~p~n salt ~p~n body ~p~n ", 
                [CheckSign, Sign, Salt, Body ]),
    case list_to_binary(CheckSign)  of 
        Sign -> true;
        _ -> false
   end
.

echo([<<"check">>], Body, Req)->
     case sign_api:check(?MESSAGES, Body) of
        [] ->
            sign_api:put_new_message(?MESSAGES , Body),  
            ?FACT_LOG("check sign true ~n", []), 
            cowboy_req:reply(200, headers_json_plain(),<<"{\"status\":\"true\"}">> , Req);
        _ ->
            ?FACT_LOG("check sign false ~n", []),
            false_response(Req)
     end;
     
echo(_, Body, Req)->
     ?FACT_LOG("undefined request from ~p ~n",[Req]),
     false_response(Req).
     


generate_key(Salt, Body)->
        hexstring( crypto:hash(sha256, <<Salt/binary, Body/binary >>)  ) 
.

json_decode(Json)->
        jiffy:decode(Json).

json_encode(Doc)->
        jiffy:encode(Doc).

%     Doc4 =   [ {[{<<"bing">>,1},{<<"test">>,2}]}, 2.3, true] .
% [{[{<<"bing">>,1},{<<"test">>,2}]},2.3,true]
% (shellchat@localhost.localdomain)16> jiffy:encode( Doc4).                                      
% <<"[{\"bing\":1,\"test\":2},2.3,true]">>
% 


-spec hexstring( binary() ) -> list().

hexstring(<<X:128/big-unsigned-integer>>) ->
    lists:flatten(io_lib:format("~32.16.0b", [X]));
hexstring(<<X:160/big-unsigned-integer>>) ->
    lists:flatten(io_lib:format("~40.16.0b", [X]));
hexstring(<<X:256/big-unsigned-integer>>) ->
    lists:flatten(io_lib:format("~64.16.0b", [X]));
hexstring(<<X:512/big-unsigned-integer>>) ->
    lists:flatten(io_lib:format("~128.16.0b", [X])).
