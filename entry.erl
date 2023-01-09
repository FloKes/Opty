-module(entry).
-export([new/1]).

new(Value) ->
    spawn_link(fun() -> init(Value) end).

init(Value) ->
    entry(Value, make_ref(), []).

entry(Value, Time, ActiveReads) ->
    receive
        {read, Ref, From, TransactionId} ->
            From ! {Ref, self(), Value, Time},
            case lists:member(TransactionId, ActiveReads) of
                true ->
                    entry(Value, Time, ActiveReads);
                false -> 
                    entry(Value, Time, [TransactionId | ActiveReads])
            end;
        {write, New} ->
            entry(New, make_ref(), ActiveReads);
        {check, Ref, From} ->
            case ActiveReads of 
                [] -> From ! {Ref, ok};
                _ -> From ! {Ref, abort}
            end,
            entry(Value, Time, ActiveReads);
        {deleteReads, TransactionId, Ref, From} ->
            From ! Ref,
            entry(Value, Time, lists:delete(TransactionId, ActiveReads));
        stop ->
            ok
    end.