-module(erws_sup).  
-behaviour(supervisor).  
-export([start_link/0]).  
-export([init/1]).  
  
start_link() ->  
        supervisor:start_link({local, ?MODULE}, ?MODULE, []).  
      
init([]) -> 
        Api_table_holder ={
                "api_table_holder",
             {api_table_holder, start_link, [] },
             permanent, infinity, worker , [ api_table_holder]   
        
        },
                
        {ok, { {one_for_one, 5, 10}, [  Api_table_holder ] } }.  
