
-module(bleashup_db).

-export([init/0,new_event_manager/1,add_current_event/1,add_to_event_table/1,
        event_accepted/4,event_denied/3,remove_new_event/3,update_participant/3,
        update_about/3,update_location/3,add_to_new_event/3,remove_current_event/3,
        list_len/1,add_multiple_new_event/4,load_current_events/1]).

-include("bleashup_rec.hrl").

-define(TIMEOUT,15000).

%% Following My design ....
    %% New event......gillon
        %% is considered to be mnesia table of the form {participant_phone,[event_id]}.
        %% It content is goten from the current_event Mnesia table.
        %% Events that are not yet notified to the user are are stored here.
        %% If the event are accepted by the user it's removed from this table
        %% if the event aren't accepted by the users they are the events are removed from this table and the
        %% phone number of this user is removed among the list of participant
        %% of that event in  the current event table.

    %% Current event....
        %% is considered to be a mnesia table containing all events that are not yet passed.
        %% know the info about this table by typing record_info(fields,current_event). in the erlang shell
        %% while being in this directory after typing rr("bleashup_db.erl") on this erlang shell.
        %% All newly created events by a user are stored in this Mnesia table.

    %% Old event.....
        %% is considered to be a Mnesia table of the same form as the current_table.
        %% all events that had passed are store in this table.
        %% this is the table that is assumed to growing and hence should be backed up frequently to a database.
    %% Events ......
        %% is a table of the form {Phone,[Eventid]}.
        %% IT holds ,for a partivular user all the events to which that user partains to.
        %% It is implement to avoid the overhead of searching through the whole of current_event table 
        %% to have have all the events a particular user partains to.eg when the user changes his phone,
        %% he should be capable to have back all his current and past events.
%% end

%%TODO:TO BE TESTED
init() ->
    mnesia:create_schema([node()]),
    mnesia:start(),
    case mnesia:create_table(new_event,[{attributes,
         record_info(fields,new_event)},{type,set},{disc_copies,[node()]}]) of 
        {atomic,ok} ->
         case mnesia:create_table(past_event,[{attributes,
            record_info(fields,past_event)},{type,set},{disc_copies,[node()]}]) of
                {atomic,ok} ->
                    case mnesia:create_table(current_event,[{attributes,
                         record_info(fields,current_event)},{type,set},{disc_copies,[node()]}]) of
                         {atomic,ok} ->
                             case mnesia:create_table(events,[{attributes,
                                  record_info(fields,events)},{type,set},{disc_copies,node()}]) of
                                {atomic,ok}  ->
                                    %%RefOld = make_ref(), 
                                    %%Refold is a reference to ensure that cominication between current_event process and 
                                    %%old_event process is effective.
                                    RefNew = make_ref(), %%RefNew is a reference to ensure tha communication between current_event process and 
                                    %%new_event process is always effective.
                                    process_flag(trap_exit,true),
                                    true = register(new_event,spawn_link(bleashup_db,new_event_manager,[RefNew])); %%spawning new_event creation handler
                                    %%true = register(old_evnet,spawn_link(bleashup_db,past_event_manager,[RefOld])),%%spawning old_event creation handler
                                    %%true = register(current_event,spawn_link(bleashup_db,current_manager,[RefNew,RefOld])). %%spawning current_event creation handler
                                {aborted,Message} -> io:format("~w~n",[Message])
                            end;
                        {aborted,Message} ->
                            io:format("~w~n",[Message])
                    end;
                {aborted,Message} ->
                    io:format("~w~n",[Message])
                    end;
        {aborted,Message} -> 
            io:format("~w~n",[{error,Message}])
                end.


%%TODO:TO BE TESTED
new_event_manager(RefNew) ->
    receive
        {add_event,RefNew,Pid,Data} -> 
            SubRef = make_ref(),
            SubPid = spawn_link(bleashup_db,add_multiple_new_event,[self(),SubRef,Data,[]]),
            receive
                {SubRef,SubPid,ok} -> Pid ! {RefNew,ok};
                {SubRef,SubPid,error,ErrorEvents} -> Pid ! {RefNew,error,ErrorEvents}
                    
            end,
            new_event_manager(RefNew);
        {accepted,Pid,Ref,Data} ->
            SubRef = make_ref(), 
            SubPid = spawn_link(bleashup_db,event_accepted,
            [Data#new_event.parti_phone,Data#new_event.event_id,self(),SubRef]),
            receive
                {SubRef,SubPid,ok} -> 
                    Pid ! {ok,Ref};
                {SubRef,SubPid,aborted,Message} -> 
                    Pid ! {Ref,error,Message};
                {'EXIT',_P,Reson} -> 
                    Pid ! {error,Reson}
                after ?TIMEOUT -> 
                    Pid ! {Ref,timeout}
            end,
            new_event_manager(RefNew);
        {denie,Pid,Ref,Data} -> 
            SubRef = make_ref(),
            SubPid = spawn_link(bleashup_db,event_denied,
            [Data#new_event.parti_phone,Data#new_event.event_id,self(),SubRef]),
            receive
                {SubRef,SubPid,ok} -> 
                    Pid ! {ok,Ref};
                {SubRef,Pid,error,Message} -> 
                    Pid ! {Ref,error,Message};
                {'EXIT',_P,Reson} -> 
                    Pid ! {Ref,error,Reson}
                after ?TIMEOUT ->
                    Pid ! {Ref,timeout}
                    
            end,
            new_event_manager(RefNew)
    end.


%%TODO:TO BE TESTED
event_accepted(Phone,EventID,Pid,Reference) ->
    Ref = make_ref(),
    SubPid = spawn_link(bleashup_db,remove_new_event,[Phone,EventID,self(),Ref]),
    receive
        {Ref,SubPid,aborted,Message} -> 
            ok = add_to_event_table({Phone,EventID}),
            Pid !  {Reference,self(),aborted,Message};
        {Ref,SubPid,atomic,Message} -> 
            add_to_event_table({Phone,EventID}),
            Pid ! {Reference,self(),ok,Message}
    end.

%%TODO:TOBE TESTED
load_current_events(Phone) ->
    case mnesia:dirty_read(events,Phone) of
        [] ->
            {error,no_such_key};
        [Event] -> 
            EventIDs = Event#events.id,
            collect_current_events(EventIDs,[])
    end.

%%TODO:TOBE TESTED
collect_current_events([],Store) -> Store;
collect_current_events([Head|Tail],Store) ->
    collect_current_events(Tail,lists:append(Store,mnesia:dirty_read(current_event,Head))).

add_to_event_table({Phone,EventID}) ->
    case mnesia:dirty_read(events,Phone) of 
        [] ->
            Event = #events{
                        phone = Phone,
                        id = EventID
                    },
            mnesia:dirty_write(events,Event);
        [Event] -> 
            EventIDs = Event#events.id,
            NewID = lists:append(EventIDs,[EventID]),
            NewEvent = Event#events{
                                id = NewID
                            },
            mnesia:dirty_write(events,NewEvent)

    end.

%% GOOD
add_multiple_new_event(Pid,Ref,[],ErrorEvents) ->
    case ErrorEvents of
        [] -> Pid ! {Ref,self(),ok};
         _ -> Pid ! {Ref,self(),error,ErrorEvents}
            
    end;

add_multiple_new_event(Pid,Ref,[{Phone,EventID,Master}|Tail],ErrorEvents) ->
    NewRef = make_ref(),
    NewPid = spawn_link(bleashup_db,add_to_new_event,[self(),NewRef,{Phone,EventID,Master}]),
    receive
        {NewRef,NewPid,atomic,no_such_key} -> add_multiple_new_event(Pid,Ref,Tail,lists:append(ErrorEvents,
                                                                [{error,no_such_key,Phone,EventID,Master}]));
        {NewRef,NewPid,atomic,_} -> add_multiple_new_event(Pid,Ref,Tail,ErrorEvents);

        {NewRef,NewPid,aborted,_} -> add_multiple_new_event(Pid,Ref,Tail,lists:append(ErrorEvents,
                                                                [{error,no_such_key,Phone,EventID,Master}]))
    end.

%% GOOD
remove_new_event({Phone,EventID},Pid,Ref) ->
    F = fun() ->
            case  mnesia:wread({new_event,Phone}) of
                [Event] ->
                    EventIDs = Event#new_event.event_id,
                    case list_len(EventIDs) =< 1 of 
                        true -> 
                            mnesia:delete({new_event,Phone});
                        false ->
                            NewEventIDs = [NewEventID||NewEventID <- EventIDs,NewEventID /= EventID],
                            NewEvent = Event#new_event{event_id = NewEventIDs},
                            mnesia:write(new_event,NewEvent,write) 
                    end;
                [] -> no_such_key
            end
        end,
    ok = make_transaction(F,Pid,Ref).


%% GOOD
event_denied({Phone,EventID},Pid,Ref) ->
   SubRef = make_ref(),
   SubPid = spawn_link(bleashup_db,remove_new_event,[{Phone,EventID},self(),SubRef]),
    receive
        {SubRef,SubPid,atomic,_} ->
            UpdateRef = make_ref(),
            UpdatePid = spawn_link(bleashup_db,update_participant,[UpdateRef,self(),{remove,EventID,Phone}]),
            receive
                {UpdateRef,UpdatePid,atomic,_} -> Pid ! {Ref,self(),ok};
                {UpdateRef,UpdatePid,aborted,Message} -> Pid ! {Ref,self(),aborted,Message}
                    
            end;
        {SubRef,SubPid,aborted,Message} ->  Pid !{Ref,self(),aborted,Message}
            
    end.

list_len([]) -> 0;
list_len([_|Tail]) ->
  1+list_len(Tail).

%% GOOD
%% TODO: This function is to be implemented using dirty operations
add_to_new_event(Pid,Ref,{Phone,EventID,Master}) ->
    SubRef = make_ref(),
    SubPid =  spawn_link(bleashup_db,update_participant,[SubRef,self(),{add,EventID,Phone,Master}]),
    receive
        {SubRef,SubPid,atomic,_} -> 
            F = fun() ->
                     case mnesia:wread({new_event,Phone}) of
                        []  -> mnesia:write(new_event,#new_event{
                                                        parti_phone = Phone,
                                                        event_id = [EventID]
                                                    },write);
                        [Event] ->
                            io:format("~w~n",[Event]),
                            EventIDs = Event#new_event.event_id,
                            NewEventIDs = lists:append(EventIDs,[EventID]),
                            NewEvent = Event#new_event{
                                                event_id = NewEventIDs
                                            },
                            mnesia:write(new_event,NewEvent,write)
                             
                     end
            end,
            make_transaction(F,Pid,Ref);

        {SubRef,SubPid,aborted,Message} -> Pid ! {error,Message}
            
    end.



%%TODO:TESTED
remove_current_event(Ref,Pid,{EventID,Phone}) ->
    F = fun() ->
            case mnesia:wread({current_event,EventID}) of
                [] -> no_such_key;
                [Event] ->
                    case Event#current_event.creator_phone == Phone of
                        true -> 
                            mnesia:delete({current_event,EventID});
                        false ->
                            permission_deneid
                    end
                    
            end
        end,
    make_transaction(F,Pid,Ref).


%%%%%%%%%%%%%%%%%%%%%%%% EVENT PARTICIPANT DATA MANIPULATOR FUNCTIONS %%%%%%%%%%%%%%%%%%
%% GOOD
update_participant(Ref,Pid,{add,EventID,Parti_Phone,Master}) ->
    F = fun() ->
            case mnesia:wread({current_event,EventID}) of 
                 [Event] ->
                    Participant = Event#current_event.participant,
                    NewParticipant = lists:flatten(Participant,[#participant{
                                                                     phone  = Parti_Phone,
                                                                     master = Master}]),
                    NewEvent = Event#current_event{participant = NewParticipant},
                    mnesia:write(current_event,NewEvent,write);
                [] -> no_such_key

                end
            end,
    ok = make_transaction(F,Pid,Ref);



%% GOOD
update_participant(Ref,Pid,{remove,EventID,Parti_Phone}) ->
    F = fun() ->
            case mnesia:wread({current_event,EventID}) of
                [Event] ->
                    Participant = Event#current_event.participant,
                    NewParticipant = [NewParticipant || 
                    NewParticipant <- Participant,NewParticipant#participant.phone /= Parti_Phone],
                    NewEvent = Event#current_event{participant = NewParticipant},
                    mnesia:write(current_event,NewEvent,write);
                [] -> no_such_key
            end
        end,
    ok = make_transaction(F,Pid,Ref);


%% GOOD
update_participant(Ref,Pid,{master,EventID,Master,Parti_Phone}) ->
    F = fun () ->
           case mnesia:wread({current_event,EventID}) of
               [Event] ->
                    Participant = Event#current_event.participant,
                    Func = fun(NewParticipant) ->
                                case NewParticipant#participant.phone == Parti_Phone of
                                    true -> #participant{
                                                phone = Parti_Phone,
                                                master = Master
                                            };
                                    false -> NewParticipant
                               end
                            end, 
                    NewParticipant = [Func(NewParticipant)||NewParticipant<-Participant],
                    NewEvent = Event#current_event{participant = NewParticipant},
                    mnesia:write(current_event,NewEvent,write);
                [] -> no_such_key
            end
        end,
    ok = make_transaction(F,Pid,Ref).
    

%%%%%%%%%%%%%%%%%%%%%%%%%% END OF PARTICIPANT DATA MANIPULATOR %%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%% EVENT ABOUT DATA MANIPULATOR FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%

%% GOOD
update_about(Ref,Pid,{title,EventID,NewTitle}) ->
    F = fun() ->
           case mnesia:wread({current_event,EventID}) of
               [Event] ->
                    About = Event#current_event.about,
                    NewAbout = About#about{title = NewTitle},
                    NewEvent = Event#current_event{about = NewAbout},
                    mnesia:write(current_event,NewEvent,write);
                [] -> no_such_key
            end    
        end,
    ok = make_transaction(F,Pid,Ref);

update_about(Ref,Pid,{description,EventID,NewDescription}) ->

    F = fun() ->
          case mnesia:wread({current_event,EventID}) of
              [Event] ->
                About = Event#current_event.about,
                NewAbout = About#about{description = NewDescription},
                NewEvent = Event#current_event{about = NewAbout},
                mnesia:write(current_event,NewEvent,write);
             [] -> no_such_key
            end
        end,
    ok = make_transaction(F,Pid,Ref).

%%%%%%%%%%%%%%%%%%%%%%% END OF EVENT ABOUT DATA MANIPULATOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% GOOD
%% This function is implemented to send a feedback message... 
%% to spawing function of any event data manipulator based on which the spawning function...
%% shall react accordinly.
make_transaction(F,Pid,Ref) ->
    case mnesia:transaction(F) of
        {atomic,Message} -> Pid ! {Ref,self(),atomic,Message};
        {aborted,Message} -> Pid ! {Ref,self(),aborted,Message}
    end,
    ok.
        
%% GOOD
update_location(Ref,Pid,{string,EventID,NewString}) ->
    F = fun() ->
            case mnesia:wread({current_event,EventID}) of
              [Event] ->
                  NewLocation = Event#current_event.location#location{string = NewString},
                  NewEvent = Event#current_event{location = NewLocation},
                  mnesia:write(current_event,NewEvent,write);
              [] -> no_such_key
          end
        end,
    ok = make_transaction(F,Pid,Ref);

update_location(Ref,Pid,{url,EventID,NewUrl}) ->
    F = fun() ->
             case mnesia:wread({current_event,EventID}) of
                 [Event] ->
                    NewLocation = Event#current_event.location#location{url = NewUrl},
                    NewEvent = Event#current_event{location = NewLocation},
                    mnesia:write(current_event,NewEvent,write);
                [] -> no_such_key
             end
        end,
    ok = make_transaction(F,Pid,Ref).

%% GOOD
add_current_event(Event) ->
    mnesia:dirty_write(current_event,Event),
    Phone = Event#current_event.creator_phone,
    ID = Event#current_event.id,
    SubEvent = #events{
                    phone = Phone,
                    id = ID 
                },
    mnesia:dirty_write(events,SubEvent).


