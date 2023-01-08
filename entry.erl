-module(entry).
-export([new/1]).

new(Value) ->
    spawn_link(fun() -> init(Value) end).

init(Value) ->
    entry(Value, make_ref()).

entry(Value, Time) ->
    receive
        {read, Ref, From} ->
            From ! {Ref, self(), Value, Time}, %TODO done
            entry(Value, Time);
        {write, New} ->
            entry(New , make_ref());  %% TODO: maybe
        {check, Ref, Readtime, From} ->
            if 
                Time == Readtime ->   %% TODO: COMPLETE
                    From ! {Ref, ok}; %% TODO: maybe
                true ->
                    From ! {Ref, abort}
            end,
            entry(Value, Time);
        stop ->
            ok
    end.
