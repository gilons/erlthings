-module(concu).
-export([messager/1,go/0,loop/0,messagee/0,looperMain/1,looper/3]).


go() -> 
     register(concu,spawn(concu,loop,[])),
    concu ! {self(),hello},
    receive
        {_Pid,Msg} -> io:format("~w~n",[Msg])
    end.

loop() -> 
    receive
        {From,Msg} -> From ! {self(),Msg},
        loop();
        stop -> true
    end.

messager(Option) ->
    register(message,spawn(concu,messagee,[])),
    message ! {Option,"Santer the godzil!"},
    message ! {stop,nothing}.

messagee() -> 
    receive
        {print,Mesage} -> io:format("~w~n",[Mesage]),
        messagee();
        {stop,_} -> true
            
    end.

looper(NodePid,PreviousPid,IterNumber) -> 
    receive
        {FromPid,Msg} -> 
            io:format("~w from ~w ~n",[Msg,FromPid]),
            timer:sleep(1000),
            case IterNumber == 0 of
                true ->
                    io:format("stopping!!! ~w ~n",[IterNumber]),
                    timer:sleep(1000), 
                    NodePid !stop ,
                    looper(NodePid,PreviousPid,IterNumber);
                false ->
                    Pid = whereis(list_to_atom(string:concat("loop",integer_to_list(IterNumber-1)))),
                    case Pid of
                    undefined -> 
                        Pider = list_to_atom(string:concat("loop",integer_to_list(IterNumber-1))),
                        register(Pider,spawn(concu,looper,[NodePid,self(),IterNumber-1])),
                        whereis(Pider) ! {self(),"say hello to the world"},
                        looper(NodePid,PreviousPid,IterNumber);
                    _ ->
                        Pid ! {self(),"say hello to the world"},
                        looper(NodePid,PreviousPid,IterNumber)
                    end

                    
            end;
        stop -> 
            case IterNumber == 0 of
                true ->true;
                    %io:format("stopping!!! ~w ~n",[IterNumber]);
                false -> 
                    io:format("stopping!!! ~w ~n",[IterNumber]),
                    Pid = whereis(list_to_atom(string:concat("loop",integer_to_list(IterNumber-1)))),
                    Pid ! stop
            end
           
           
    end.

looperMain(IterNumber) ->
    io:format("Chain started ~n",[]),
    timer:sleep(1000),
    Pid = list_to_atom(string:concat("loop",integer_to_list(IterNumber-1))),
    case whereis(Pid) of
        undefined ->  
            register(Pid,spawn(concu,looper,[self(),self(),IterNumber-1])),
            whereis(Pid) ! {self(),"say hello to the world"};
        Pider -> 
             Pider ! {self(),"say hello to the world"}
    end,
    receive
        {FromPid,Msg} -> io:format("~w from ~w ~n",[Msg,FromPid]),
                        looperMain(IterNumber);
            stop -> 
                io:format("stopping!!! ~w ~n",[IterNumber]),
                Pid ! stop
    end.
    
