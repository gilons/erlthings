-module(client).
-export([message/1,make1000conn/1]).


message(Message) ->
    {ok,Socket} = gen_tcp:connect("localhost",8080,[{active,false}]),
    gen_tcp:send(Socket,Message),
    Ans = gen_tcp:recv(Socket,0),
    io:format("~w~n",[Ans]),
    gen_tcp:close(Socket),
    Ans.

make1000conn(0) -> ok;
make1000conn(Count) ->
    spawn_link(client,message,["hello world 1"]),
    timer:sleep(1),
    make1000conn(Count-1).