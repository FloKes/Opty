-module(validator).
-export([start/0]).

start() ->
    spawn_link(fun() -> init() end).

init()->
    validator().

validator() ->
    receive
        {validate, Ref, Reads, Writes, Client} ->
            Tag = make_ref(),
            send_read_checks(Reads, Tag),  %% TODO: maybe
            case check_reads(length(Reads), Tag) of  %% TODO: maybe
                ok ->
                    update(Writes),  %% TODO: maybe
                    Client ! {Ref, ok};
                abort ->
                    Client ! {Ref, abort} % TODO add code : done
            end,
            validator();
        stop ->
            ok;
        _Old ->
            validator()
    end.
    
update(Writes) ->
    lists:foreach(fun({_, Entry, Value}) -> 
                    Entry ! {write, Value} % TODO add code: maybe
                  end, 
                  Writes).

send_read_checks(Reads, Tag) ->
    Self = self(),
    lists:foreach(fun({Entry, Time}) -> 
                    Entry ! {check, Tag, Time, Self} % TODO add code maybe
                  end, 
                  Reads).

check_reads(0, _) ->
    ok;
check_reads(N, Tag) ->
    receive
        {Tag, ok} ->
            check_reads(N-1, Tag);
        {Tag, abort} ->
            abort
    end.
