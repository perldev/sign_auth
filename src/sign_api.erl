-module(sign_api).
-export([last/1,
         get_from_reverse/4, 
         put_new_message/2,
         create_store/1,
         get_last_count/4,
         delete_firstN_msgs/3,
         get_firstN_msgs/3
         ]).


-record(message_record, 
                {
                id,
                time,
                value
                }
).


create_store(Tab)->
        ets:new(Tab, [public, named_table, ordered_set, {keypos, 2} ])
.

last(Tab)->
        ets:last(Tab)
.

get_last_count(Tab, From, Count, Fun)->
           RevesedList  =
           case 
                ets:lookup(Tab, From) of
             [Msg] ->
                NewFrom = ets:prev(Tab, From),
                get_from_reverse3(Tab, NewFrom,  Count - 1, [ Msg ]);
              [] -> []
           end,
           lists:foldl(fun(Msg, Accum)-> 
                           NewItem =
                              Fun(Msg#message_record.id,
                                  Msg#message_record.time,
                                  Msg#message_record.value
                              ),
                           [NewItem | Accum]                    
                       end, [],
                       RevesedList
                       )
        
.

get_from_reverse(_Tab, _Index, _Index, _Fun)->
        []
;
get_from_reverse(Tab, From, Index, Fun)->
        RevesedList  =
           case 
                ets:lookup(Tab, From) of
             [Msg] ->
                NewFrom = ets:prev(Tab, From),
                get_from_reverse2(Tab, NewFrom,  Index, [ Msg ]);
                
             [] -> []
           end,
           lists:foldl(fun(Msg, Accum)-> 
                           NewItem =
                              Fun(Msg#message_record.id,
                                Msg#message_record.time,
                                Msg#message_record.value
                              ),
                           [NewItem | Accum]                    
                       end, [],
                       RevesedList
                       )
           
.


delete_firstN_msgs(Tab, Count, Fun)->
        Key  = ets:first(Tab),
        delete_firstN_msgs(Tab, Key,  1, Count, Fun)
.


delete_firstN_msgs(_Tab, '$end_of_table',  _Index, _Count, _Fun)->
        true
;
delete_firstN_msgs(_Tab, _Key,  _Count, _Count, _Fun)->
        true
;
delete_firstN_msgs(Tab, Key,  Index, Count, Fun)->
        case ets:lookup(Tab, Key ) of
             [Msg] ->
                Fun(Msg#message_record.id,
                    Msg#message_record.time,
                    Msg#message_record.value
                   ),
                ets:delete(Tab, Key);
             [] ->        
                ets:delete(Tab, Key)
        end,     
        NewKey  = ets:first(Tab),
        delete_firstN_msgs(Tab, NewKey, Index + 1, Count, Fun)
.

get_firstN_msgs(Tab, Count, Fun)->
          ets:safe_fixtable(Tab,true),
          From = ets:first(Tab),
          RevesedList  =
           case 
                ets:lookup(Tab, From) of
             [Msg] ->
                NewFrom = ets:next(Tab, From),
                get_firstN_msgs(Tab, NewFrom,  1, Count,  [ Msg ]);
                
             [] -> []
           end,
           ets:safe_fixtable(Tab, false),
           lists:foldl(fun(Msg, Accum)-> 
                           NewItem =
                              Fun(Msg#message_record.id,
                                Msg#message_record.time,
                                Msg#message_record.value
                              ),
                           [NewItem | Accum]                    
                       end, [],
                       RevesedList
                       )

.

get_firstN_msgs(_Tab, '$end_of_table',  _Index, _Count, Accum)->
        Accum
;
get_firstN_msgs(_Tab, _NewFrom,  _Count, _Count, Accum)->
        Accum
;
get_firstN_msgs(Tab, From,  Index, Count, Accum)->
         case 
                ets:lookup(Tab, From) of
             [Msg] ->
                NewFrom = ets:next(Tab, From),
                get_firstN_msgs(Tab, NewFrom,  Index + 1, Count,  [ Msg | Accum]);
             [] -> Accum
           end.

get_from_reverse3(_Tab, _Index, 0, Accum)->
        Accum
;
get_from_reverse3(Tab, From, Index, Accum)->
        case 
                ets:lookup(Tab, From) of
        [ Msg ] ->         
                NewForm = ets:prev(Tab, From),
                get_from_reverse3(Tab, NewForm, Index - 1, [Msg|Accum]);
        [] ->
                Accum
        end
.



get_from_reverse2(Tab, Index, Index, Accum)->
 
                Accum
;
get_from_reverse2(Tab, From, Index, Accum)->
        case 
                ets:lookup(Tab, From) of
        [ Msg ] ->         
                NewForm = ets:prev(Tab, From),
                get_from_reverse2(Tab, NewForm, Index, [Msg|Accum]);
        [] ->
                Accum
        end
.


-spec put_new_message(atom(), binary()  )-> true.

put_new_message(Tab, MessBin  )->
       Ref = erlang:crc32(MessBin),
       Ref1 = erlang:crc32(rev(MessBin,<<>>))*10000000000 + Ref,  
       ets:insert( Tab,  #message_record{ 
                                id = Ref1,
                                time = now(),
                                value = MessBin
                          }),
       Ref1                   
.

rev(<<>>, Acc) -> Acc;
rev(<<H:1/binary, Rest/binary>>, Acc) ->
    rev(Rest, <<H/binary, Acc/binary>>).