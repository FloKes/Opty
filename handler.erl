-module(handler).
-export([start/3]).

start(Client, Validator, Store) ->
    spawn_link(fun() -> init(Client, Validator, Store) end).

init(Client, Validator, Store) ->
    TransactionId = make_ref(),
    handler(Client, Validator, Store, [], [], TransactionId).

handler(Client, Validator, Store, Reads, Writes, TransactionId) ->         
    receive
        {read, Ref, N} ->
            case lists:keyfind(N, 1, Writes) of
                {N, _, Value} ->
                    Client ! {value, Ref, Value},
                    handler(Client, Validator, Store, Reads, Writes, TransactionId);
                false ->
                    Entry = store:lookup(N, Store),
                    Entry ! {read, Ref, self(), TransactionId},
                    handler(Client, Validator, Store, Reads, Writes, TransactionId)
            end;
        {write, N, Value} ->
            Entry = store:lookup(N, Store),
            Added = lists:keystore(N, 1, Writes, {N, Entry, Value}),
            handler(Client, Validator, Store, Reads, Added, TransactionId);
        {commit, Ref} ->
            Validator ! {validate, Ref, Reads, Writes, Client, TransactionId};
        {Ref, Entry, Value} -> 
            Client ! {value, Ref, Value},
            handler(Client, Validator, Store, [{Entry}|Reads], Writes, TransactionId);
        abort ->
            Tag = make_ref(),
            lists:foreach(fun({Entry}) -> 
                  Entry ! {deleteReads, TransactionId, Tag, self()}
                  end, 
                  Reads),
            ok
    end.