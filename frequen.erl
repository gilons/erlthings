-module(frequen).
-export([start/0,stop/0,allocate/0,deallocate/1]).
-export([init/0]).



%% These are the start functions used to create and  initialize the server

start() ->
        register(frequency,spawn(frequen,init,[])).

init() ->
    process_flag(trap_exit,true),
    Frequencies = {get_frequencies(),[]},
    loop(Frequencies).

%Hard coded
get_frequencies() -> [10,11,12,13,14,15].

%%Client functions

stop() -> call(stop).
allocate() -> call(allocate).
deallocate(Freq) -> call({deallocate,Freq}).

%%We hide all message passing and the message protocol in a functional interface
call(Message) -> 
    frequency ! {request,self(),Message},
    receive
        {reply,Reply} -> Reply
            
    end.

%%The main loop 
loop(Frequencies) -> receive
    {request,Pid,allocate} -> 
        {NewFrequencies,Reply} = allocate(Frequencies,Pid),
        reply(Pid,Reply),
        loop(NewFrequencies);
    {request,Pid,{deallocate,Freq}} ->
        NewFrequencies = deallocate(Frequencies,Freq),
        reply(Pid,ok),
        loop(NewFrequencies);
    {request,Pid,ok} ->
        reply(Pid,ok);
    {'EXIT',Pid,_Reason} -> 
        NewFrequencies = exit(Frequencies,Pid),
        loop(NewFrequencies)
        
end.
reply(Pid,Reply) ->
    Pid ! {reply,Reply}.

%% Internal Functions Used to Allocate and Deallocate Frequencies

allocate({[],Allocated},_Pid) ->
    {{[],Allocated},{error,no_frequency}};
allocate({[Freq|Free],Allocated},Pid) ->
    link(Pid),
    {{Free,[{Freq,Pid}|Allocated]},{ok,Freq}}.

deallocate({Free,Allocated},Freq) ->
    {value,{Freq,Pid}} = lists:keysearch(Freq,1,Allocated),
    unlink(Pid),
    NewAllocated = lists:keydelete(Freq,1,Allocated),
    {[Freq|Free],NewAllocated}.

exit({Free,Allocated},Pid) ->
    case lists:keysearch(Pid,1,Allocated) of
         {value,{Freq,Pid}} -> NewAllocated = lists:keydelete(Freq,1,Allocated),
         {[Freq|Free],NewAllocated};
        false -> {Free,Allocated}
    end.