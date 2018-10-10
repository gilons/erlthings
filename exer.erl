-module(exer).
-export([printer/1,smaller/2,even/1,concate/1,extractInt/1,intersection/2]).


printer(Limit) ->
    Print = fun(X) ->
        lists:seq(1,X)
    end,
    Print(Limit).

smaller(Int,IntList) ->
    Lesserthan = fun (Intin,IntListin) ->
        [Ls || Ls <- IntListin,Ls =< Intin]
end,
Lesserthan(Int,IntList).

even(N) ->
    EventInt = fun(Int) ->
        [En || En <- lists:seq(0,Int),En rem 2 == 0]
end,
EventInt(N).

concate([]) ->[];
concate(ListList) ->
    Con = fun([Head|Tail]) ->
        Head++concate(Tail)
end,
Con(ListList).

extractInt(List) ->
    [Int||Int <- List,is_integer(Int) == true].

intersection(List1,List2) -> 
    [Xs||Xs <- List1,Xss <- List2,Xs == Xss].

