-module(bleashup_test).

-export([init/0,test1/1,test2/1,destroy/0,sample_record_event/0]).

-record(test,{id,number}).

-include("bleashup_rec.hrl").

init() ->
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(test,[{ram_copies,[node()]},{attributes,record_info(fields,test)},{type,bag}]).

test1(Num) ->
    Data = lists:seq(1,Num),
    F = fun () ->
		write_all(Data) end,
        mnesia:transaction(F).

write_all([]) -> ok;
write_all([Head|Tail]) ->
	mnesia:write(test,#test{id = Head,number = Head},write),
	write_all(Tail).

test2(Num) ->
	Data = lists:seq(1,Num),
			write_all1(Data).

write_all1([]) ->ok;
write_all1([Head|Tail]) ->
    F = fun() -> mnesia:write(test,{Head,Head},write) end,
	mnesia:transaction(F),
	write_all1(Tail).

destroy() ->
    mnesia:delete_table(test),
    mnesia:delete_schema([node()]).

sample_record_event() ->
    [#current_event{
    id = <<"santers_gillons">>,
    creator_phone = <<"650594616">>,
    location = #location{
        string = <<"douala djoga palce">>,
        url = <<"sgdfbmer:b!d:fb;ermùgùgdf;bd:gem">>
    },
    period = #period{
        time = {12,50,45},
        date = {05,12,2015}
    },
    about = #about{
        title = <<"best player event">>,
        description = <<"this event shall gather the best eater of the world \n
                         and the best competitors of the univers">>
    },
    participant = [#participant{
        phone = <<"5825986654">>,
        master = true
    },#participant{
        phone = <<"744932146">>,
        master = false
    },#participant{
        phone = <<"167969644323">>,
        master = true
    },#participant{
        phone = <<"456932655435">>,
        master = false
    }]
},#current_event{
    id = <<"gillons_santers">>,
    creator_phone = <<"650594616">>,
    location = #location{
        string = <<"bertoua">>,
        url = <<"sgdfbmer:b!d:fb;ermùgùgdf;bd:gem">>
    },
    period = #period{
        time = {13,50,45},
        date = {06,12,2015}
    },
    about = #about{
        title = <<"best drinkers event">>,
        description = <<"this event shall gather the best drinkers of the world \n
                         and the best competitors of the univers">>
    },
    participant = [#participant{
        phone = <<"5825986654">>,
        master = false
    },#participant{
        phone = <<"744932146">>,
        master = true
    },#participant{
        phone = <<"167969644323">>,
        master = false
    },#participant{
        phone = <<"456932655435">>,
        master = true
    }]
}].