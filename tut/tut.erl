-module(tut).

-import(string,[len/1,concat/2,chr/2,substr/3,str/2,to_lower/1,to_upper/1]).

%%-export([hello_world/0,add/2,add/3]).

%%hello_world() ->
  %%  io:fwrite("hello world\n").
%%add(A,B) ->
  %%  hello_world(),
   %% A+B.
%%add(A,B,C) ->
  %%  hello_world(),
    %%A+B+C.

-export([main/0]).
 main() -> 
  string_stuff().

preschool() -> 
    'Go to preschool'.

kindergarten() ->
    'Go to kindergarten'.
grade_school() ->
    'Go to grade school'.

what_grade(X) ->
    %%IF ELSE IN ERLANG.
    if X < 5 -> preschool()
    ;X == 5 -> kindergarten()
    ;X > 5 -> grade_school()
    end.

%%Case Erlang Implementation
say_hello(X) ->
    case X of 
        french -> 'bonjour';
        german -> 'Guten tag';
        english ->'hello'
    end.

%%Working With Strings
string_stuff() ->
    str1 = "Random string",
    str2 = "Another string",

    io:fwrite("string: ~p ~p\n",[str1,str2]).