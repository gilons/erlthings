%% FILE : usr.hrl
%% Description : Include Files for user db

-record(usr, {
    msisdn,  %init()
    id, %term()
    status = enabled, %atom() enable|disabled
    plan, %atom() prepay|postpay
    service = [] %[atom()],service flag Lists
}).

