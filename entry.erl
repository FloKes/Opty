-module(entry).
-export([new/1]).

new(Value) ->
    spawn_link(fun() -> init(Value) end).

init(Value) ->
    entry(Value, []).

entry(Value, ActiveReads) ->
    receive
        {read, Ref, From, TransactionId} ->
            From ! {Ref, self(), Value},
            case lists:member(TransactionId, ActiveReads) of
                true ->
                    entry(Value, ActiveReads);
                false -> 
                    entry(Value, [TransactionId | ActiveReads])
            end;
        {write, New} ->
            entry(New, ActiveReads);
        {check, Ref, From, TransactionId} ->
            WoList = lists:delete(TransactionId,ActiveReads),
            case WoList of 
                [] -> From ! {Ref, ok};
                _ -> From ! {Ref, abort}
            end,
            entry(Value, ActiveReads);
        {deleteReads, TransactionId, Ref, From} ->
            From ! Ref,
            entry(Value, lists:delete(TransactionId, ActiveReads));
        stop ->
            ok
    end.