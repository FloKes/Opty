-module(validator).
-export([start/0]).

start() ->
    spawn_link(fun() -> init() end).

init()->
    validator().

validator() ->
    receive
        {validate, Ref, Reads, Writes, Client, TransactionId} ->
            Tag = make_ref(),

            send_write_checks(Writes, Tag), 
            case check_writes(length(Writes), Tag) of  %% TODO: COMPLETE
                ok ->
                    update(Writes),  %% TODO: COMPLETE

                    send_read_deletes(Reads, Tag, TransactionId),
                    delete_reads(length(Reads), Tag),

                    Client ! {Ref, ok};
                abort ->
                    send_read_deletes(Reads, Tag, TransactionId),
                    delete_reads(length(Reads), Tag),

                    Client ! {Ref, abort}
            end,
            validator();
        stop ->
            ok;
        _Old ->
            validator()
    end.
    


send_read_deletes(Reads, Tag, TransactionId) ->
    Self = self(),
    lists:foreach(fun({Entry, _}) -> 
                  Entry ! {deleteReads, TransactionId, Tag, Self}
                  end, 
                  Reads).

delete_reads(0, _) ->
    ok;

delete_reads(N, Tag) ->
    receive 
        Tag ->
            delete_reads(N-1, Tag)
    end.


update(Writes) ->
    lists:foreach(fun({_, Entry, Value}) -> 
                  Entry ! {write, Value}
                  end, 
                  Writes).

send_write_checks(Writes, Tag) ->
    Self = self(),
    lists:foreach(fun({_, Entry, _}) -> 
                  Entry ! {check, Tag, Self}
                  end, 
                  Writes).

check_writes(0, _) ->
    ok;
check_writes(N, Tag) ->
    receive
        {Tag, ok} ->
            check_writes(N-1, Tag);
        {Tag, abort} ->
            abort
    end.


