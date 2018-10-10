-record(new_event,{
    parti_phone :: binary(),
    event_id :: [binary()]
    }).
-record(current_event,{
    id :: binary(),
    creator_phone :: binary(),
    location :: location(),
    period :: period(),
    about :: about(),
    participant :: participant()
}).
-record(about,{
    title :: binary(),
    description :: binary()
}).
-record(participant,{
    phone :: binary(),
    master :: boolean()
}).
-record(past_event,{
    id :: binary(),
    creator_phone :: binary(),
    location :: location(),
    period :: period(),
    about :: about(),
    participant :: [participant()]
    }).
-record(location,{
    string :: binary(),
    url :: binary()
}).
-record(period,{
    time :: tuple(),
    date :: tuple()
}).
-record(events,{
    phone :: binary(),
    id :: binary()
}).

-type period() :: #period{}.
-type participant() :: #participant{}.
-type location() :: #location{}.
-type about() :: #about{}.
-type new_event() :: #new_event{}.
-type old_event() :: #past_event{}.
-type current_event() :: #current_event{}.
-type event() :: #events{}.