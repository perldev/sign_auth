-module(erws_handler).

-include("erws_console.hrl").


% Behaviour cowboy_http_handler
-export([init/3, handle/2, terminate/3]).

% Behaviour cowboy_http_websocket_handler



% Called to know how to dispatch a new connection.
init({tcp, http}, Req, Opts) ->
    { Path, Req3} = cowboy_req:path_info(Req),
    io:format("Request: ~p ~n", [ {Req, Path, Opts} ]),
    % we're not interested in serving any other content.
    {ok, Req3, undefined}
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
      { Path, Req1} = cowboy_req:path_info(Req),
      ?CONSOLE_LOG("request: ~p~n", [Path]),
      Session = generate_key(<<"G">>),
      Res =  ( catch echo(Path, Req, State) ),
      ?CONSOLE_LOG("got request result: ~p~n", [Res]),
      {ok, NewReq} = Res,      
      {ok, NewReq,State}.

terminate(_Req, _State) -> ok.


% 
% echo([<<"config">>], Req, State)->
%     
%      {ok, Message, NewReq } = cowboy_req:body(Req),
%      json_decode
%      case sign_api:check(Message) of
%         [] ->  cowboy_req:reply(404, headers_json_plain(),<<"{\"status\":\"not_found\"}">> , Req);
%         [ #pin_state{current_value = Val } ] ->
%                 NewVal  = lists:reverse(Val),
%                ?CONSOLE_LOG(" ~p get : ~p~n", [ {?MODULE, ?LINE}, NewVal]),
%                 BVal  = list_to_binary(NewVal),
%                 ets:delete(?SESSIONS, LSes),
%                 cowboy_req:reply(200, headers_json_plain(),
%                 <<"{\"status\": true}">>, Req)
%                 
%      end
% .

echo([<<"check">>], Req, State)->
    
     {ok, Message, NewReq } = cowboy_req:body(Req),
     case sign_api:check(Message) of
        [] ->
            sign_api:put_new_message(?MESSAGES , Message),  
            cowboy_req:reply(200, headers_json_plain(),<<"{\"status\":\"true\"}">> , Req);
        [ _ ] ->
            cowboy_req:reply(200, headers_json_plain(),<<"{\"status\":\"false\"}">> , Req)

                
     end.
     


generate_key(Salt)->
        {A,B,C} = random:seed(now()),
        String = crypto:rand_bytes(64),
        hexstring( crypto:hash(sha256, <<Salt/binary, String/binary >>)  ) 
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
