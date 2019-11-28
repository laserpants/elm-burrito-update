module Burrito.Update exposing
    ( Update, save, addCmd, map, mapCmd, join, kleisli, when
    , andThen, sequence
    , andMap, ap, map2, map3, map4, map5, map6, map7
    , apply, runCallbacks, andApply
    , run, run2, run3
    , andAddCmd, using, with, andWith, andUsing, andIf
    )

{-| Monadic-style interface for state updates.


# Update

@docs Update, save, addCmd, map, mapCmd, join, kleisli, when


## Chaining Updates

@docs andThen, sequence


## Applicative Interface

These functions address the need to map over functions having more than one argument.

@docs andMap, ap, map2, map3, map4, map5, map6, map7


## Callbacks

Callbacks allow for information to be passed _up_ in the update tree.

@docs apply, runCallbacks, andApply


## Program Integration

@docs run, run2, run3


## Pointfree Helpers

@docs andAddCmd, using, with, andWith, andUsing, andIf

-}


{-| Type wrapper for Elm's `( model, Cmd msg )` tuple.
-}
type alias Update a msg t =
    ( a, List (Cmd msg), List t )


{-| Lifts a value into the `Update` context. For example,

    save model

corresponds to `( model, Cmd.none )` in code that doesn't use this library.

-}
save : a -> Update a msg t
save model =
    ( model, [], [] )


{-| This function is like [`andMap`](#andMap), but with the arguments interchanged.
-}
ap : Update (a -> b) msg t -> Update a msg t -> Update b msg t
ap ( f, cmds1, extra1 ) ( model, cmds2, extra2 ) =
    ( f model, cmds1 ++ cmds2, extra1 ++ extra2 )


{-| Apply a function to the state portion of an `Update`.
-}
map : (a -> b) -> Update a msg t -> Update b msg t
map f ( model, cmds, extra ) =
    ( f model, cmds, extra )


{-| Combine the state of two `Update`s using a function of two arguments.
Equivalently, we can think of this as taking a function `a -> b -> c` and
transforming it into a “lifted” function of type `Update a msg t -> Update b msg t -> Update c msg t`.
-}
map2 : (p -> q -> r) -> Update p msg t1 -> Update q msg t1 -> Update r msg t1
map2 f =
    ap << map f


{-| Combine the state of three `Update`s using a function of three arguments.
-}
map3 : (p -> q -> r -> s) -> Update p msg t1 -> Update q msg t1 -> Update r msg t1 -> Update s msg t1
map3 f a =
    ap << map2 f a


{-| Combine the state of four `Update`s using a function of four arguments.
-}
map4 : (p -> q -> r -> s -> t) -> Update p msg t1 -> Update q msg t1 -> Update r msg t1 -> Update s msg t1 -> Update t msg t1
map4 f a b =
    ap << map3 f a b


{-| Combine the state of five `Update`s using a function of five arguments.
-}
map5 : (p -> q -> r -> s -> t -> u) -> Update p msg t1 -> Update q msg t1 -> Update r msg t1 -> Update s msg t1 -> Update t msg t1 -> Update u msg t1
map5 f a b c =
    ap << map4 f a b c


{-| Combine the state of six `Update`s using a function of six arguments.
-}
map6 : (p -> q -> r -> s -> t -> u -> v) -> Update p msg t1 -> Update q msg t1 -> Update r msg t1 -> Update s msg t1 -> Update t msg t1 -> Update u msg t1 -> Update v msg t1
map6 f a b c d =
    ap << map5 f a b c d


{-| Combine the state of seven `Update`s using a function of seven arguments.
-}
map7 : (p -> q -> r -> s -> t -> u -> v -> w) -> Update p msg t1 -> Update q msg t1 -> Update r msg t1 -> Update s msg t1 -> Update t msg t1 -> Update u msg t1 -> Update v msg t1 -> Update w msg t1
map7 f a b c d e =
    ap << map6 f a b c d e


{-| Trying to map over a function `number -> number -> number`,

    map (+) (save 4)

we end up with a result of type `Update (number -> number) msg t`. To apply the function inside this value to another `Update number msg t` value, we can write&hellip;

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
andMap : Update a msg t -> Update (a -> b) msg t -> Update b msg t
andMap a b =
    ap b a


{-| Remove one level of monadic structure. It may suffice to know that some other
functions in this library are implemented in terms of `join`. In particular, `andThen f = join << map f`
-}
join : Update (Update a msg t) msg t -> Update a msg t
join ( ( model, cmds1, extra1 ), cmds2, extra2 ) =
    ( model, cmds1 ++ cmds2, extra2 ++ extra1 )


{-| Sequential composition of updates. This function is especially useful in conjunction
with the forward pipe operator (`|>`), for writing code in the style of pipelines. To chain
updates, we compose functions of the form `State -> Update State msg t`:

    say : String -> State -> Update State msg t
    say what state = ...

    save state
        |> andThen (say "hello")
        |> andThen doSomethingElse

_Aside:_ `andThen` is like the monadic bind `(>>=)` operator in Haskell, but with the arguments interchanged.

-}
andThen : (b -> Update a msg t) -> Update b msg t -> Update a msg t
andThen fun =
    join << map fun


{-| Right-to-left (Kleisli) composition of two functions that return `Update` values,
passing the state part of the first return value to the second function.
-}
kleisli : (b -> Update c msg t) -> (a -> Update b msg t) -> a -> Update c msg t
kleisli f g =
    andThen f << g


{-| Take a list of `a -> Update a msg t` values and run them sequentially, in a left-to-right manner.
-}
sequence : List (a -> Update a msg t) -> a -> Update a msg t
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
addCmd : Cmd msg -> a -> Update a msg t
addCmd cmd model =
    ( model, [ cmd ], [] )


{-| Map over the `Cmd` contained in the provided `Update`.
-}
mapCmd : (msg -> msg1) -> Update a msg t -> Update a msg1 t
mapCmd f ( model, cmds, extra ) =
    ( model, List.map (Cmd.map f) cmds, extra )


{-| Shortcut for `andThen << addCmd`
-}
andAddCmd : Cmd msg -> Update a msg t -> Update a msg t
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
with get f =
    using (f << get)


{-| Combinator useful for pointfree style. For example;

    nextPage state =
        goToPage (state.current + 1) state

can be changed to

    nextPage =
        using (\{ current } -> goToPage (current + 1))

-}
using : (a -> a -> b) -> a -> b
using f model =
    f model model


{-| Run an update if the given condition is `True`, otherwise do nothing.
-}
when : Bool -> (a -> Update a msg t) -> a -> Update a msg t
when cond f =
    if cond then
        f

    else
        save


{-| Shortcut for `\fun -> andThen << with fun`
-}
andWith : (b -> c) -> (c -> b -> Update a msg t) -> Update b msg t -> Update a msg t
andWith get =
    andThen << with get


{-| Shortcut for `andThen << using`
-}
andUsing : (b -> b -> Update a msg t) -> Update b msg t -> Update a msg t
andUsing =
    andThen << using


{-| Shortcut for `\cond -> andThen << when cond`
-}
andIf : Bool -> (a -> Update a msg t) -> Update a msg t -> Update a msg t
andIf cond =
    andThen << when cond


exec : Update a msg t -> ( a, Cmd msg )
exec ( model, cmds, _ ) =
    ( model, Cmd.batch cmds )


{-| Append a callback to the list of functions that subsequently get applied to the returned value using `runCallbacks`.
-}
apply : t -> a -> Update a msg t
apply call model =
    ( model, [], [ call ] )


{-| Compose and apply the list of monadic functions (callbacks) produced by a nested update call.
-}
runCallbacks : Update a msg (a -> Update a msg t) -> Update a msg t
runCallbacks ( model1, cmds1, calls1 ) =
    let
        ( model2, cmds2, calls2 ) =
            sequence calls1 model1
    in
    ( model2, cmds1 ++ cmds2, calls2 )


{-| Shortcut for `andThen << apply`
-}
andApply : t -> Update a msg t -> Update a msg t
andApply =
    andThen << apply


{-| Translate a function that returns an `Update` into one that returns a plain `( model, cmd )` pair.
-}
run : (p -> Update a msg t) -> p -> ( a, Cmd msg )
run f =
    exec << f


{-| Same as [`run`](#run), but for functions of two arguments.
-}
run2 : (p -> q -> Update a msg t) -> p -> q -> ( a, Cmd msg )
run2 f a =
    exec << f a


{-| Same as [`run`](#run), but for functions of three arguments.
-}
run3 : (p -> q -> r -> Update a msg t) -> p -> q -> r -> ( a, Cmd msg )
run3 f a b =
    exec << f a b
