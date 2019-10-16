module Burrito.Update exposing
    ( Update, PlainUpdate, save, addCmd, map, mapCmd, join, kleisli
    , andThen, sequence
    , andMap, ap, map2, map3, map4, map5, map6, map7
    , run, run2, run3
    , andAddCmd, with
    )

{-| Monadic-style interface for state updates.


# Update

@docs Update, PlainUpdate, save, addCmd, map, mapCmd, join, kleisli


## Chaining Updates

@docs andThen, sequence


## Applicative Interface

These functions address the need to map over functions of more than one argument.

@docs andMap, ap, map2, map3, map4, map5, map6, map7


# Program Integration

@docs run, run2, run3


# Helpers

@docs andAddCmd, with

-}


{-| Type wrapper for Elm's `( model, Cmd msg )` tuple.
-}
type alias Update a x o =
    ( a, List (Cmd x), List o )


{-| A simpler version of `Update` which is sufficient in most cases.
-}
type alias PlainUpdate a x =
    Update a x ()


{-| Lifts a value into the `Update` context. For example,

    save model

corresponds to `( model, Cmd.none )` in code that doesn't use this library.

-}
save : a -> Update a x o
save model =
    ( model, [], [] )


{-| See [`andMap`](#andMap). This function is the same but with the arguments interchanged.
-}
ap : Update (a -> b) x o -> Update a x o -> Update b x o
ap ( f, cmds1, zs1 ) ( model, cmds2, zs2 ) =
    ( f model, cmds1 ++ cmds2, zs1 ++ zs2 )


{-| Apply a function to the state portion of a value.
-}
map : (a -> b) -> Update a x o -> Update b x o
map f ( model, cmds, zs ) =
    ( f model, cmds, zs )


{-| Apply a function of two arguments to the state portion of a value.
Equivalently, we can think of this as taking a function `a -> b -> c` and
transforming it into a “lifted” function of type `Update a m -> Update b m -> Update c m`.
-}
map2 : (p -> q -> r) -> Update p x o -> Update q x o -> Update r x o
map2 f =
    ap << map f


{-| Apply a function of three arguments to the state portion of a value.
-}
map3 : (p -> q -> r -> s) -> Update p x o -> Update q x o -> Update r x o -> Update s x o
map3 f a =
    ap << map2 f a


{-| Apply a function of four arguments to the state portion of a value.
-}
map4 : (p -> q -> r -> s -> t) -> Update p x o -> Update q x o -> Update r x o -> Update s x o -> Update t x o
map4 f a b =
    ap << map3 f a b


{-| Apply a function of five arguments to the state portion of a value.
-}
map5 : (p -> q -> r -> s -> t -> u) -> Update p x o -> Update q x o -> Update r x o -> Update s x o -> Update t x o -> Update u x o
map5 f a b c =
    ap << map4 f a b c


{-| Apply a function of six arguments to the state portion of a value.
-}
map6 : (p -> q -> r -> s -> t -> u -> v) -> Update p x o -> Update q x o -> Update r x o -> Update s x o -> Update t x o -> Update u x o -> Update v x o
map6 f a b c d =
    ap << map5 f a b c d


{-| Apply a function of seven arguments to the state portion of a value.
-}
map7 : (p -> q -> r -> s -> t -> u -> v -> w) -> Update p x o -> Update q x o -> Update r x o -> Update s x o -> Update t x o -> Update u x o -> Update v x o -> Update w x o
map7 f a b c d e =
    ap << map6 f a b c d e


{-| Trying to map over a function `number -> number -> number`,

    map (+) (save 4)

we end up with a result of type `Update (number -> number) c`. To apply the function inside this value to another `Update number c` value, we can write&hellip;

    map (+) (save 4) |> andMap (save 5)

in `elm repl`, we can verify that the result is what we expect:

    > (map (+) (save 4) |> andMap (save 5)) == save 9
    True : Bool

This pattern scales in a nice way to functions of any number of arguments:

    let
        f x y z =
            x + y + z
    in
    map f (save 1)
        |> andMap (save 1)
        |> andMap (save 1)

If not sooner, you'll need this when you want to `mapN` and N > 7.

See also [`map2`](#map2), [`map3`](#map3), etc.

-}
andMap : Update a x o -> Update (a -> b) x o -> Update b x o
andMap a b =
    ap b a


{-| Remove one level of monadic structure. It may suffice to know that some other
functions in this library are implemented in terms of `join`. In particular, `andThen f = join << map f`
-}
join : Update (Update a x o) x o -> Update a x o
join ( ( model, cmds1, zs1 ), cmds2, zs2 ) =
    ( model, cmds1 ++ cmds2, zs1 ++ zs2 )


{-| Sequential composition of updates. This function is especially useful in combination
with the forward pipe operator (`|>`), for writing code in the style of pipelines. To chain
updates, we compose functions of the form `something -> State -> Update State m`:

    say : String -> State -> Update State m
    say what state = ...

    save state
        |> andThen (say "hello")
        |> andThen doSomethingElse

_Aside:_ `andThen` is like the monadic bind `(>>=)` operator in Haskell, but with the arguments interchanged.

-}
andThen : (b -> Update a x o) -> Update b x o -> Update a x o
andThen fun =
    join << map fun


{-| Right-to-left (Kleisli) composition of two functions that return `Update` values,
passing the state part of the first return value to the second function.
-}
kleisli : (b -> Update d x o) -> (a -> Update b x o) -> a -> Update d x o
kleisli f g =
    andThen f << g


{-| Take a list of `a -> Update a m` values and run them sequentially, in a left-to-right manner.
-}
sequence : List (a -> Update a x o) -> a -> Update a x o
sequence list model =
    List.foldl andThen (save model) list


{-| Add a command to an `Update` pipeline. For example;

    update msg state =
        case msg of
            SomeMsg someMsg ->
                state
                    |> addCmd someCommand
                    |> andThen (addCmd someOtherCommand)
                    |> andThen (setStatus Done)

In this example, `andThen (addCmd someOtherCommand)` can also be shortened to
[`andAddCmd`](#andAddCmd)`someOtherCommand`.

-}
addCmd : Cmd x -> a -> Update a x o
addCmd cmd model =
    ( model, [ cmd ], [] )


{-| Map over the `Cmd` contained in the provided `Update`.
-}
mapCmd : (x -> y) -> Update a x o -> Update a y o
mapCmd f ( model, cmds, zs ) =
    ( model, List.map (Cmd.map f) cmds, zs )


{-| Shortcut for `andThen << addCmd`
-}
andAddCmd : Cmd x -> Update a x o -> Update a x o
andAddCmd =
    andThen << addCmd


{-| Combinator useful for pointfree style. For example, to get rid of the lambda in the following code;

    update msg state =
        case msg of
            Click ->
                state
                    |> updateSomething
                    |> andThen (\s -> setCounterValue (s.counter + 1) s)

we can write:

    update msg state =
        case msg of
            Click ->
                state
                    |> updateSomething
                    |> andThen (with .counter (setCounterValue << (+) 1))

-}
with : (a -> b) -> (b -> a -> c) -> a -> c
with get f model =
    f (get model) model


exec : Update a x o -> ( a, Cmd x )
exec ( model, cmds, _ ) =
    ( model, Cmd.batch cmds )


{-| Translate a function that returns an `Update` into one that returns a plain `( model, cmd )` pair.
-}
run : (p -> Update a x o) -> p -> ( a, Cmd x )
run f =
    exec << f


{-| Same as [`run`](#run), but for functions of two arguments.
-}
run2 : (p -> q -> Update a x o) -> p -> q -> ( a, Cmd x )
run2 f a =
    exec << f a


{-| Same as [`run`](#run), but for functions of three arguments.
-}
run3 : (p -> q -> r -> Update a x o) -> p -> q -> r -> ( a, Cmd x )
run3 f a b =
    exec << f a b
