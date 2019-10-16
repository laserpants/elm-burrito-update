module Burrito.Update exposing
   ( Update, save, addCmd, map, mapCmd, join, kleisli
    , andThen
    , andMap, ap, map2, map3, map4, map5, map6, map7
    , run, run2, run3
    , andAddCmd
    , sequence
    )

{-| Monadic-style interface for state updates.


# Update

@docs Update, save, addCmd, map, mapCmd, join, kleisli


## Chaining Updates

@docs andThen, sequence


## Applicative Interface

These functions address the need to map over functions of more than one argument.

@docs andMap, ap, map2, map3, map4, map5, map6, map7


# Program Integration

@docs run, run2, run3


# Helpers

@docs andAddCmd

-}


{-| A type alias wrapper for Elm's `( model, Cmd msg )` tuple.
-}
type alias Update a m =
    ( a, List (Cmd m) )


{-| Lifts a value into the `Update` context. For example,

    save model

corresponds to `( model, Cmd.none )` in code that doesn't use this library.

-}
save : a -> Update a m
save model =
    ( model, [] )


{-| See [`andMap`](#andMap). This function is the same but with the arguments interchanged.
-}
ap : Update (a -> b) m -> Update a m -> Update b m
ap ( f, cmds1 ) ( model, cmds2 ) =
    ( f model, cmds1 ++ cmds2 )


{-| Apply a function to the state portion of a value.
-}
map : (a -> b) -> Update a m -> Update b m
map f ( model, cmds ) =
    ( f model, cmds )


{-| Apply a function of two arguments to the state portion of a value.
Equivalently, we can think of this as taking a function `a -> b -> c` and
transforming it into a “lifted” function of type `Update a m -> Update b m -> Update c m`.
-}
map2 : (p -> q -> r) -> Update p m -> Update q m -> Update r m
map2 f =
    ap << map f


{-| Apply a function of three arguments to the state portion of a value.
-}
map3 : (p -> q -> r -> s) -> Update p m -> Update q m -> Update r m -> Update s m
map3 f a =
    ap << map2 f a


{-| Apply a function of four arguments to the state portion of a value.
-}
map4 : (p -> q -> r -> s -> t) -> Update p m -> Update q m -> Update r m -> Update s m -> Update t m
map4 f a b =
    ap << map3 f a b


{-| Apply a function of five arguments to the state portion of a value.
-}
map5 : (p -> q -> r -> s -> t -> u) -> Update p m -> Update q m -> Update r m -> Update s m -> Update t m -> Update u m
map5 f a b c =
    ap << map4 f a b c


{-| Apply a function of six arguments to the state portion of a value.
-}
map6 : (p -> q -> r -> s -> t -> u -> v) -> Update p m -> Update q m -> Update r m -> Update s m -> Update t m -> Update u m -> Update v m
map6 f a b c d =
    ap << map5 f a b c d


{-| Apply a function of seven arguments to the state portion of a value.
-}
map7 : (p -> q -> r -> s -> t -> u -> v -> w) -> Update p m -> Update q m -> Update r m -> Update s m -> Update t m -> Update u m -> Update v m -> Update w m
map7 f a b c d e =
    ap << map6 f a b c d e


{-| Trying to map over a function `number -> number -> number`,

    map (+) (save 4)

we end up with a result of type `Update (number -> number) c e`. To apply the function inside this value to another `Update number c e` value, we can write&hellip;

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
andMap : Update a m -> Update (a -> b) m -> Update b m
andMap a b =
    ap b a


{-| Remove one level of monadic structure. It may suffice to know that some other
functions in this library are implemented in terms of `join`. In particular, `andThen f = join << map f`
-}
join : Update (Update a m) m -> Update a m
join ( ( model, cmds1 ), cmds2 ) =
    ( model, cmds1 ++ cmds2 )


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
andThen : (b -> Update a m) -> Update b m -> Update a m
andThen fun =
    join << map fun


{-| Right-to-left (Kleisli) composition of two functions that return `Update` values,
passing the state part of the first return value to the second function.
-}
kleisli : (b -> Update d m) -> (a -> Update b m) -> a -> Update d m
kleisli f g =
    andThen f << g


{-| TODO
-}
sequence : List (a -> Update a m) -> a -> Update a m
sequence list model =
    List.foldr andThen (save model) list


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
addCmd : Cmd m -> a -> Update a m
addCmd cmd model =
    ( model, [ cmd ] )


{-| Map over the `Cmd` contained in the provided `Update`.
-}
mapCmd : (ma -> mb) -> Update a ma -> Update a mb
mapCmd f ( model, cmds ) =
    ( model, List.map (Cmd.map f) cmds )


{-| Shortcut for `andThen << addCmd`
-}
andAddCmd : Cmd m -> Update a m -> Update a m
andAddCmd =
    andThen << addCmd


exec : Update a m -> ( a, Cmd m )
exec ( model, cmds ) =
    ( model, Cmd.batch cmds )


{-| TODO
-}
run : (p -> Update a m) -> p -> ( a, Cmd m )
run f =
    exec << f


{-| TODO
-}
run2 : (p -> q -> Update a m) -> p -> q -> ( a, Cmd m )
run2 f a =
    exec << f a


{-| TODO
-}
run3 : (p -> q -> r -> Update a m) -> p -> q -> r -> ( a, Cmd m )
run3 f a b =
    exec << f a b
