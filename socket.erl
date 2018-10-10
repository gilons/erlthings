-module(socket).
-export([start_socket/0,handles/3,respond/3,simply_handle/0,
        wait_connection/2,wait_parallel_conn/2,decode_about_json/1,
        decode_event_json_to_records/1,decode_participant_json/2,
        connection/1,decode_about/1,decode_from_tupel/1,collect_participant/2]).
-include("socket.hrl").


start_socket() ->
    {ok,ListenSocket} = gen_tcp:listen(4500,[{active,true}]),
    mnesia:create_schema([node()]),
    mnesia:start(),
    connection(ListenSocket).
    %%wait_parallel_conn(ListenSocket,0).
    %%wait_connection(ListenSocket,0).

wait_connection(ListenSocket,Count) ->
   {ok,Socket} = gen_tcp:accept(ListenSocket),
   io:format("~w connection accepted~n",[Count]),
   case whereis(handle_proc) of
        undefined -> register(handle_proc,spawn_link(?MODULE,handles,[[],0,ListenSocket])),
                    ok = gen_tcp:controlling_process(Socket,whereis(handle_proc));
        Pid       -> ok = gen_tcp:controlling_process(Socket,Pid)
            
    end,
   wait_connection(ListenSocket,Count+1).

handles(_,700,ListenSocket) ->
    %%TODO: test to see the bottle neck effect when timer:sleep(100),
    %%respond(Sockets,700,ListenSocket);
    %%proc_lib:stop(whereis(handle_proc));
    io:format("700 more connections accepted ~n",[]),
    handles([],0,ListenSocket);



handles(Sockets,Count,ListenSocket) ->
    %%io:format("entring into handle func~n",[]),
    receive
        {tcp,Sock,Data} ->
            Result =  (catch binary:bin_to_list(Data)) ,
            case Result of 
                {'EXIT',{badarg,_}} -> io:format("~w~n",[lists:flatten(Data)]);
                %% gen_tcp:send(Sock,"Server Response for ");
                _ -> io:format("~w~n",[Result])
                 %%gen_tcp:send(Sock,"Server Response for ")
            end ,

        handles(lists:append(Sockets,[Sock]),Count+1,ListenSocket)
end.

respond([Head|Tail],Count,ListenSocket) ->
    gen_tcp:send(Head,"Server Response for "),
   % timer:sleep(15),
    respond(Tail,Count-1,ListenSocket);
respond(_,0,ListenSocket) ->
    handles([],0,ListenSocket).
    %%gen_tcp:close(ListenSocket).


simply_handle() ->
    receive
        {tcp,Sock,Data} ->
            Result =  (catch binary:bin_to_list(Data)) ,
            case Result of 
                {'EXIT',{badarg,_}} -> 
                    ErlangTerm = decode_event_json_to_records(jsx:decode(binary:list_to_bin(Data),[return_maps])),
                    io:format("~w~n",[ErlangTerm]),
                    gen_tcp:send(Sock,"Server Response for ");
                _ -> io:format("~w~n",[Result]),
                 gen_tcp:send(Sock,"Server Response for ")
            end,
            simply_handle() 
    end.

wait_parallel_conn(ListenSocket,Count) ->
    {ok,Socket} = gen_tcp:accept(ListenSocket),
    io:format("parallel connection ~w~n",[Count]),
    Pid = spawn_link(socket,simply_handle,[]),
    ok = gen_tcp:controlling_process(Socket,Pid),
    wait_parallel_conn(ListenSocket,Count+1).

decode_event_json_to_records(JsonBin) ->

    Event = #event{
    id = maps:get(<<"id">>,JsonBin),
    creator_phone = maps:get(<<"creator_phone">>,JsonBin),
    period = maps:get(<<"period">>,JsonBin),
    location = maps:get(<<"location">>,JsonBin),
    participant = decode_participant_json(maps:get(<<"participant">>,JsonBin),[]),
    about = decode_about_json(maps:get(<<"about">>,JsonBin))
},
Event.

decode_participant_json([],Acc) ->
    Acc;
decode_participant_json([Head|Tail],Acc) ->
decode_participant_json(Tail,lists:append(Acc,[
        #participant{
            phone = maps:get(<<"phone">>,Head),
            master = maps:get(<<"master">>,Head)
        }
    ])).


decode_about_json(About) ->
    #about{
        title = maps:get(<<"title">>,About),
        description = maps:get(<<"description">>,About)
    }.




receive_client_message(Socket) ->
    case gen_tcp:recv(Socket,0) of 
         {ok,Packet} ->
    gen_tcp:close(Socket),
    EventJSON = jsx:decode(binary:list_to_bin(Packet),[return_maps]),
    EventRec = decode_event_json_to_records(EventJSON),
    ID = EventRec#event.id,
    mnesia:create_table(event,[{type,bag},{attributes,record_info(fields,event)}]),
    mnesia:add_table_index(event,creator_phone),
    %%mnesia:table_info(TableName,all);
    AddEvent = fun() ->
                mnesia:write(event,EventRec,write),
                mnesia:read(event,ID,read) end,
    mnesia:transaction(AddEvent);
    %decode_from_tupel(EventMap);
        Result -> gen_tcp:close(Socket),
                Result
end.
connection(ListenSocket) ->
    inet:setopts(ListenSocket,[{active,false}]),
    {ok,Socket} = gen_tcp:accept(ListenSocket),
    receive_client_message(Socket).

decode_from_tupel(EventMap) ->
    {Id,_} = dict:take(<<"id">>,EventMap),
    {Creator_phone,_} = dict:take(<<"creator_phone">>,EventMap),
    {Period,_} = dict:take(<<"period">>,EventMap),
    {Location,_} = dict:take(<<"location">>,EventMap),
    {Participant,_} = collect_participant(dict:take(<<"participant">>,EventMap),[]),
    {About,_} = decode_about(dict:take(<<"about">>,EventMap)),

    Event = #event {
                id = Id,
                creator_phone = Creator_phone,
                period = Period,
                location = Location,
                participant = collect_participant(Participant,[]),
                about = decode_about(About)
            },
    Event.

collect_participant([],Acc) -> Acc;
collect_participant([Head,Tail],Acc) ->
    {Phone,_} = dict:take(<<"phone">>,Head),
    {Master,_} = dict:take(<<"master">>,Head),
    Participant = #participant{
        phone = Phone,
        master = Master
    },
    collect_participant(Tail,lists:append(Acc,[Participant])).

decode_about(About) ->
    {Title,_} =  dict:take(<<"title">>,About),
    {Desctiption,_} = dict:take(<<"description">>,About),
    #about {
        title = Title,
        description = Desctiption
    }.

%table_name(ID,Table) ->
 %%%%   list_to_atom(lists:append(binary:bin_to_list(ID),"_"++Table)).