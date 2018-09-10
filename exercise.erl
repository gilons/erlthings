-module(exercise).
-import(oi,[read/1]).
-export([trimList/2,countList/1,returnList/3,split/2,splits/4,create/1,reverse_create/1,filter/2,replaceAll/3,sort/2,findHighest/2,readLines/1]).



%----Cool Implementation------%

     splits(Text,_,Result,_) when Text == [] -> Result;
     splits([Head|Tail],Separator,Result,WordSummer) when Head == Separator ->
       splits(Tail,Separator,Result ++ [lists:flatten(WordSummer)],[]);
     splits([Head|Tail],Separator,Result,WordSummer) ->
       splits(Tail,Separator,Result,[WordSummer,Head]).



create(0)->[0];
create(Number) -> lists:flatten([Number,create(Number-1)]).

reverse_create(0) -> [0];
reverse_create(Number) -> lists:flatten([reverse_create(Number-1),Number]).

filter([],_) -> [];
filter([Head|Tail],Element) when Head == Element -> [filter(Tail,Element)];
filter([Head|Tail],Element) -> [Head|filter(Tail,Element)].


findHighest([],Highest) -> Highest;
findHighest([Head|Tail],Highest) when Head > Highest -> findHighest(Tail,Head);
findHighest([_|Tail],Highest) -> findHighest(Tail,Highest).


sort([],Result) -> Result;
sort([Head|Tail],Result) -> 
    sort(replaceOnce(Tail,findHighest([Head|Tail],0),
    Head),Result++findHighest([Head|Tail],0)).
       

replaceAll([],_,_) -> [];
replaceAll([Head|Tail],OldValue,NewValue) when Head == OldValue ->
    [NewValue|replaceAll(Tail,OldValue,NewValue)];
replaceAll([Head|Tail],OldValue,NewValue) -> 
    [Head|replaceAll(Tail,OldValue,NewValue)].

replaceOnce([],_,_) -> [];
replaceOnce([Head|Tail],OldValue,NewValue) when Head == OldValue -> [NewValue|Tail];
replaceOnce([Head|Tail],OldValue,NewValue) -> 
    [Head|replaceOnce(Tail,OldValue,NewValue)].


%function to read from a file in erlang%
readLines(Filname) -> 
 {ok,Data} = file:read_file(Filname),
 allSpliter(binList_to_listList(binary:split(Data,<<"\n">>,[global]),[]),"").

binList_to_listList([],Result) -> Result;
binList_to_listList([Head|Tail],Result) -> binList_to_listList(Tail,Result ++ [binary:bin_to_list(Head)]).

countList([]) -> 0;
countList([_|Tail]) -> 1+countList(Tail).

collector([],Result,_,_) -> {Result,[]};
collector(Text,Result,Limit,Position) when Position == Limit -> {lists:flatten(Result),Text};
collector([Head|Tail],Result,Limit,Position) -> collector(Tail,[Result,Head],Limit,Position+1).



newList(Collector,[Head|_]) when Collector == [] -> [Head];
newList([_|Tail],[Head1|Tail2]) -> {lists:flatten([Tail,Head1]),Tail2}.

returnList(Collector,MainList,Limit) when Collector == [] -> collector(MainList,[],Limit,0);
returnList(Collector,MainList,_) -> newList(Collector,MainList).


spliter([],_,NewValue,Result,_) -> Result++[lists:flatten(NewValue)];

spliter(Text,Separator,NewValue,Result,[]) -> 
    {NewList,NewTail} = returnList([],Text,countList(Separator)),
    case NewList == Separator of
        true -> spliter(NewTail,Separator,[],Result,[]);

        false -> spliter(NewTail,Separator,NewValue ++ NewList,Result,NewList)
    end;


spliter(Text,Separator,NewValue,Result,Acc) ->
    {NewList,NewTail} = returnList(Acc,Text,countList(Separator)),
    case NewList == Separator of
         true  -> spliter(NewTail,Separator,[],
                  Result++[lists:flatten(trimList(lists:flatten(NewValue),countList(Separator)))],[]);
    
         false -> spliter(NewTail,Separator,[NewValue,lastElement(NewList)],Result,NewList)
    end.
    

lastElement([Head|[]]) -> Head;
lastElement([_|Tail]) -> lastElement(Tail).

trimLastElement([],Result) -> list:flatten(Result);
trimLastElement([_|[]],Result) -> lists:flatten(Result);
trimLastElement([Head|Tail],Result) -> trimLastElement(Tail,[Result,Head]).

trimList(Text,Limit) when Limit-1 == 0 -> Text;
trimList(Text,Limit) -> trimList(trimLastElement(Text,""),Limit-1).

split(Text,Separator) -> spliter(Text,Separator,[],[],[]). 

allSpliter([],Result) -> Result;
allSpliter([Head|Tail],[]) -> allSpliter(Tail,split(Head," "));
allSpliter([Head|Tail],Result) -> allSpliter(Tail,[Result,split(Head," ")]).
