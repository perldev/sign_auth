-module(api_table_holder).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0, stop/0, status/0, start_archive/0, flush/0, flush/1, archive/2 ]).

-include("erws_console.hrl").

-record(monitor, {signs}).


           
start_link() ->
          gen_server:start_link({local, ?MODULE},?MODULE, [],[]).

init([]) ->
        Ets = sign_api:create_store(?MESSAGES),
        {ok, #monitor{signs = Ets} }.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

handle_call(status,_From ,State) ->
    ?LOG_DEBUG("get msg call ~p ~n", [status]),
    {reply, ets:info(State#monitor.signs), State};
handle_call(Info,_From ,State) ->
    ?LOG_DEBUG("get msg call ~p ~n", [Info]),
    {reply, false , State}.

 
start_archive()->
      gen_server:cast(?MODULE, archive_mysql_start).  

flush()->
    gen_server:cast(?MODULE, {flush, ?DEFAULT_FLUSH_SIZE})   
.

flush(Count)->
    gen_server:cast(?MODULE, {flush, Count})      
.        
    
stop() ->
    gen_server:cast(?MODULE, stop).
 
 
process_to_archive(Msid,  Msgtime,  _Msgmessage  )->
    emysql:execute(?MYSQL_POOL, stmt_arhive, [Msid, sign_api:timestamp(Msgtime)]).
    
handle_cast({flush, Count }, MyState) ->
    sign_api:delete_firstN_msgs(MyState#monitor.signs, Count, fun process_to_archive/3),     
    {noreply, MyState};
    
handle_cast( archive_mysql_start, MyState) ->
    ?LOG_DEBUG("start archiving ~p ~n", [MyState]),
    {ok, User} = application:get_env(erws, mysql_user),
    {ok, Pwd} = application:get_env(erws,
                                      mysql_pwd),
    {ok, Base} = application:get_env(erws,
                                      database), 
    {ok, MaxSize } = application:get_env(erws, ets_max_size),
    {ok, Interval } = application:get_env(erws, archive_interval),
    {ok, Table } = application:get_env(erws, sign_table),
    
    
    emysql:add_pool(?MYSQL_POOL, [{size, 1},
                     {user, User},
                     {password, Pwd},
                     {database, Base},
                     {encoding, utf8}]),
%% TODO change NOW() to the value of ets table                     
    emysql:prepare(stmt_arhive, 
                 <<"INSERT INTO ">>, Table/binary, <<"(sign, pub_date) VALUES(?,?)">>),
    archive(MyState#monitor.signs, MaxSize),
    timer:apply_after(Interval, api_table_holder, start_archive, [ ] ),
    emysql:remove_pool(?MYSQL_POOL),
    {noreply, MyState}.
    
archive(Tab, MaxSize)->
        Size = ets:info(Tab, size),
        case MaxSize < Size  of
                true->
                       ?MODULE:flush(Size - MaxSize);
                false-> do_nothing
        end
.

handle_info(_,  State)->
   
    {noreply,  State}.

terminate(_Reason, _State) ->
   terminated.

status() ->
        gen_server:call(?MODULE, status)
    .




