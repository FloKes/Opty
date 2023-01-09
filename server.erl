-module(server).
-export([start/1]).

start(N) ->
    spawn(fun() -> init(N) end).

init(N) ->
    io:format("Initializing server with pid: ~w~n", 
         [self()]),
    Store = store:new(N),
    Validator = validator:start(),
    server(Validator, Store).
    
server(Validator, Store) ->
    receive 
        {open, Client} ->
            Client ! {transaction, Validator, Store}, % // TODO add code: done
            server(Validator, Store);
        stop ->
            Validator ! stop,
            store:stop(Store)
    end.
