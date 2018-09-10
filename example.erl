-module(example).
-export([type/1,even/1,member/2,sum_acc/2]).

type(Number) when is_integer(Number) -> interger;
type(Number) when is_atom(Number) -> atom;
type(Number) when is_tuple(Number) -> tuple;
type(_Other)                      -> unknowntype.

even(Var) when Var rem 2 == 0 -> true;
even(Var) when Var rem 2 == 1 -> false.

%As show by the function below erlang is all about matching%
member(_,[])    -> false;
member(H,[H|_]) -> true;
member(H,[_|T]) -> member(H,T).

sum_acc([],Sum) ->Sum;
sum_acc([Head|Tail],Sum) ->sum_acc(Tail,Sum+Head).
