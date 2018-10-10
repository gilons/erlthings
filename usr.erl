%%% File : usr:erl.
%%% Description : API and server code for cell user db

-module(usr).
-export([start/0,start/1,stop/0,init/2]).
-export([add_usr/3,delete_usr/1,set_service/3,set_status/2,delete_disable/0,lookup_id/1]).
-export([lookup_msisdn/1,service_flag/2]).

-include("usr.hrl").
-define(TimeOut,30000).


%%Exported Client Functions
%%Operation & Maintenence API

start() ->
    start(usrDb).
start(FileName) ->
    register(?MODULE,spawn(?MODULE,init,[FileName,self()])),
    receive
started -> ok after ?TimeOut -> {error,stating}
            
    end.

stop() ->
    call(stop).

%% Customer SERVICE API

add_usr(PhoneNum,CustID,Plane) when Plane == prepay; Plane == postpay ->
    call({add_usr,PhoneNum,CustID,Plane}).

delete_usr(CustID) ->
    call({delete_usr,CustID}).

set_service(CustID,Service,Flag) when Flag == true ; Flag == false ->
    call({service,CustID,Service,Flag}).

set_status(CustID,Status)  when Status == enabled ; Status == disabled ->
    call({set_status,CustID,Status}).

delete_disable() ->
    call(delete_disable).

lookup_id(CustID) ->
    usr_db:lookup_id(CustID).

%% SERVICE API

lookup_msisdn(PhoneNo) ->
    usr_db:lookup_msisdn(PhoneNo).

service_flag(PhoneNo,Service) ->
    case usr_db:lookup_msisdn(PhoneNo) of
        {ok,#usr{service = Services,status = enabled}} ->
            lists:member(Service,Services);
        {ok,#usr{status = disable}} ->
            {error,disable};
        {error,Reason} ->
            {error,Reason}
    end.

%% Message Functions

call(Resquest) ->
    Ref = make_ref(),
    ?MODULE ! {request,{self(),Ref},Resquest},
    receive
        {reply,Ref,Reply} ->
            Reply
        after ?TimeOut ->
            {error,?TimeOut}
    end.

reply({From,Ref},Reply) ->
    From ! {reply,Ref,Reply}.

%% Internal Server Functions

init(FileName,Pid) ->
    usr_db:create_tables(FileName),
    ysr_db:restore_backup(),
    Pid ! started,
    loop().

loop() ->
    receive
        {request,From,stop} -> reply(From,usr:close_tables());
        {request,From,Resquest} -> Reply = request(Resquest),
        reply(From,Reply),
        loop()
    end.

%% Handling Client Requests

request({add_usr,PhoneNo,CustID,Plan}) ->
    usr_db:add_usr(#usr{
                    msisdn = PhoneNo,
                    id = CustID,
                    plan = Plan    
                });

request({delete_usr,CustID}) ->
    usr_db:delete_usr(CustID);

request({set_service,CustID,Service,Flag}) ->
    case usr_db:lookup_id(CustID) of
        {ok,Usr} -> Services = lists:delete(Service,#usr.service),
        NewService = case Flag of
            true -> [Service|Services];
            false ->   Services
        end,
        usr_db:update_usr(Usr#usr{service = NewService});
        {error,instance} -> {error,instance}
    end;

request({set_status,CustId,Status}) ->
    case usr_db:lookup_id(CustId) of
        {ok,Usr} -> usr_db:update_usr(Usr#usr{status = Status});
        {error,instance} -> {error,instance}
    end;

request(delete_disable) ->
    usr_db:delete_disable().