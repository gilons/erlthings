-module(ds).
-export([showall/0,stop/0,add/1,update/1,retreive/1,dataManip/1,start/0,delete/1]).



start() ->
    register(datastore,spawn(ds,dataManip,[[]])).

stop() -> datastore ! stop.
add({Key,Data}) -> 
    datastore ! {add,{Key,Data},self()},
    receive
        {ok,Message} -> io:format("~w~n",[Message]);
        {error,Message} -> io:format("~w~n",[Message])
            
    end.
update({Key,Data}) -> 
    datastore ! {update,{Key,Data},self()},
    receive
        {ok,Message} -> io:format("~w~n",[Message]);
        {error,Message} -> io:format("~w~n",[Message])
            
    end.
retreive(Key) -> 
    datastore ! {retreive,Key,self()},
    receive
        {ok,Data} -> io:format("~w ~n",[Data]);
        {error,Message} -> io:format("~w~n",[Message])
    end.
delete(Key) ->
    datastore ! {delete,Key,self()},
    receive
        {ok,Message} -> io:format("~w~n",[Message]);
        {error,Message} -> io:format("~w~n",[Message])
            
    end.
showall() ->
    datastore ! {showall,self()},
    receive
       Data -> io:format("~w~n",[Data])
    end.

dataManip([]) ->
    receive
        {retreive,_,Pid} -> 
            Pid ! {error,no_data_in_the_datastore},
            dataManip([]);
        {add,{Key,Data},Pid} ->
            Pid ! {ok,data_succesfully_added },
            dataManip([{Key,Data}]);
        stop ->
            true;
        {delete,_,Pid} -> Pid ! {error,no_data_in_the_datastore},
        dataManip([]);
        {update,_,Pid} -> Pid ! {error,no_data_in_the_datastore},
        dataManip([]);
    {showall,Pid} -> Pid ! []
    end;

dataManip(DataStore) -> receive
    {retreive,Key,Pid} -> 
        case proplists:get_value(Key,DataStore,false) of
            false -> Pid ! {error,no_data_with_such_key},
            dataManip(DataStore);
           Data -> Pid ! {ok,Data},
           dataManip(DataStore)
        end;
    {delete,Key,Pid} ->
        Original = exercise:countList(DataStore),
        NewDataStore = proplists:delete(Key,DataStore),
        case Original == exercise:countList(NewDataStore) of
            false -> Pid ! {ok,data_succesfully_deleted},
            dataManip(NewDataStore);
            true -> Pid ! {error,no_data_with_such_key},
            dataManip(DataStore)
        end;
    {add,{Key,Data},Pid} ->
        Pid ! {ok,added_successfully},
        dataManip(lists:flatten([DataStore,{Key,Data}]));
    {update,{Key,Data},Pid} ->
        case proplists:get_value(Key,DataStore,false) of
            false -> Pid ! {error,no_data_with_such_key};
            _ -> Pid ! {ok,successfully_updated}, 
            dataManip(lists:flatten([proplists:delete(Key,DataStore),{Key,Data}]))
            
                
        end;
    {showall,Pid} -> Pid ! DataStore,
        dataManip(DataStore);
      stop -> true
        
end.

