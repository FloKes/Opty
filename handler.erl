-module(handler).
-export([start/3]).

start(Client, Validator, Store) ->
    spawn_link(fun() -> init(Client, Validator, Store) end).

init(Client, Validator, Store) ->
    handler(Client, Validator, Store, [], []).

handler(Client, Validator, Store, Reads, Writes) ->         
    receive
        {read, Ref, N} ->
            case lists:keyfind(..., ..., ...) of  %% TODO: COMPLETE
                {N, _, Value} ->
                    Client ! {value, Ref, Value}, %TODO done
                    handler(Client, Validator, Store, Reads, Writes);
                false ->
                    Entry = store:lookup(N, Store), %TODO done
		            Entry ! {read, Ref, self()}, %TODO done
                    handler(Client, Validator, Store, Reads, Writes)
            end;
        {Ref, Entry, Value, Time} ->
            Client ! {value, Ref, Value}, %TODO done
            handler(Client, Validator, Store, [{Entry, Time}|Reads], Writes);
        {write, N, Value} ->
            Entry = store:lookup(N, Store), %TODO done
            Added = lists:keystore(N, 1, Writes, {N, Entry, Value}), %TODO done
            handler(Client, Validator, Store, Reads, Added);
        {commit, Ref} ->
            Validator ! {validate, Ref, Reads, Writes, Client};
        abort ->
            ok
    end.
