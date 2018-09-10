-module(demo).
-export([guard/2,double/1,trial/1,convert/1,listlen/1,index/2,f/1,g/1,relativeTo1/1,factorial/1,preferred/1]).
%this is a conmment

%everything on a line after % isa comment .

double(Value) ->
    times(Value,2).

times(X,Y) -> 
    X*Y.

trial(Foo) ->
    TempList = [foo,bare,santers,gillons],
    case lists:member(Foo,TempList) of
        true -> ok;
        false -> {error,unknown_error}
    end.

    convert(Day) ->
        case Day of
        monday -> 1;
        tuesday -> 2;
        wednesday -> 3;
        thursday -> 4;
        friday -> 5;
        saturday -> 6;
        sunday -> 7;
    %This is not recommended to add a catch_all clause like this because the error will%
    % not be apparent and will not point where it occured%
        _ -> {error, unknown_day}
        end.

listlen([]) -> 0;
listlen([_|Xs]) -> 1+listlen(Xs).

index(0,[X|_]) -> X;
index(N,[_|Xs]) when N>0 ->index(N-1,Xs).

f(X) -> Y=X+1,Y*X.

g([Y|X])  -> Y+g(X);
g([])     -> 0.

preferred(X) ->
    Y = case X of
         one -> 12;
        _ -> 196
    end,
    Y+X.


%determining whether a number is greater than 1 or less than 1%

relativeTo1(X) ->
    if
    X > 1  -> greater;
    X < 1  -> smaller;
    X == 1 -> equal
    end.

factorial(N) when N > 0 -> N*factorial(N-1);
factorial(0) -> 1.


%, here stands for and and ; stands for or .Not to be implemented in practice since it can easyly to logic misunderstanding%
guard(X,Y) when not(X > Y),is_atom(X) ; not(is_atom(Y)),X=/=3.4 ->
    X+Y.
