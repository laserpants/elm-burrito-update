module Burrito.Update.Simple exposing (Update, save, addCmd, map, mapCmd, join, kleisli, andThen, sequence, andMap, ap, map2, map3, map4, map5, map6, map7, run, run2, run3, andAddCmd, using, with)

{-| This module exposes an API identical to [`Burrito.Update`](Burrito.Update) except a simpler
version of the `Update` type alias with two type parameters instead of three, which is sufficient in most cases.

@docs Update, save, addCmd, map, mapCmd, join, kleisli, andThen, sequence, andMap, ap, map2, map3, map4, map5, map6, map7, run, run2, run3, andAddCmd, using, with

-}

import Burrito.Update exposing (..)


{-| See [`Burrito.Update.Update`](Burrito.Update#Update).
-}
type alias Update a msg =
    Burrito.Update.Update a msg ()


{-| See [`Burrito.Update.save`](Burrito.Update#save).
-}
save : a -> Update a msg
save =
    Burrito.Update.save


{-| See [`Burrito.Update.ap`](Burrito.Update#ap).
-}
ap : Update (a -> b) msg -> Update a msg -> Update b msg
ap =
    Burrito.Update.ap


{-| See [`Burrito.Update.map`](Burrito.Update#map).
-}
map : (a -> b) -> Update a msg -> Update b msg
map =
    Burrito.Update.map


{-| See [`Burrito.Update.map2`](Burrito.Update#map2).
-}
map2 : (p -> q -> r) -> Update p msg -> Update q msg -> Update r msg
map2 =
    Burrito.Update.map2


{-| See [`Burrito.Update.map3`](Burrito.Update#map3).
-}
map3 : (p -> q -> r -> s) -> Update p msg -> Update q msg -> Update r msg -> Update s msg
map3 =
    Burrito.Update.map3


{-| See [`Burrito.Update.map4`](Burrito.Update#map4).
-}
map4 : (p -> q -> r -> s -> t) -> Update p msg -> Update q msg -> Update r msg -> Update s msg -> Update t msg
map4 =
    Burrito.Update.map4


{-| See [`Burrito.Update.map5`](Burrito.Update#map5).
-}
map5 : (p -> q -> r -> s -> t -> u) -> Update p msg -> Update q msg -> Update r msg -> Update s msg -> Update t msg -> Update u msg
map5 =
    Burrito.Update.map5


{-| See [`Burrito.Update.map6`](Burrito.Update#map6).
-}
map6 : (p -> q -> r -> s -> t -> u -> v) -> Update p msg -> Update q msg -> Update r msg -> Update s msg -> Update t msg -> Update u msg -> Update v msg
map6 =
    Burrito.Update.map6


{-| See [`Burrito.Update.map7`](Burrito.Update#map7).
-}
map7 : (p -> q -> r -> s -> t -> u -> v -> w) -> Update p msg -> Update q msg -> Update r msg -> Update s msg -> Update t msg -> Update u msg -> Update v msg -> Update w msg
map7 =
    Burrito.Update.map7


{-| See [`Burrito.Update.andMap`](Burrito.Update#andMap).
-}
andMap : Update a msg -> Update (a -> b) msg -> Update b msg
andMap =
    Burrito.Update.andMap


{-| See [`Burrito.Update.join`](Burrito.Update#join).
-}
join : Update (Update a msg) msg -> Update a msg
join =
    Burrito.Update.join


{-| See [`Burrito.Update.andThen`](Burrito.Update#andThen).
-}
andThen : (b -> Update a msg) -> Update b msg -> Update a msg
andThen =
    Burrito.Update.andThen


{-| See [`Burrito.Update.kleisli`](Burrito.Update#kleisli).
-}
kleisli : (b -> Update d msg) -> (a -> Update b msg) -> a -> Update d msg
kleisli =
    Burrito.Update.kleisli


{-| See [`Burrito.Update.sequence`](Burrito.Update#sequence).
-}
sequence : List (a -> Update a msg) -> a -> Update a msg
sequence =
    Burrito.Update.sequence


{-| See [`Burrito.Update.addCmd`](Burrito.Update#addCmd).
-}
addCmd : Cmd msg -> a -> Update a msg
addCmd =
    Burrito.Update.addCmd


{-| See [`Burrito.Update.mapCmd`](Burrito.Update#mapCmd).
-}
mapCmd : (msg -> msg1) -> Update a msg -> Update a msg1
mapCmd =
    Burrito.Update.mapCmd


{-| See [`Burrito.Update.andAddCmd`](Burrito.Update#andAddCmd).
-}
andAddCmd : Cmd msg -> Update a msg -> Update a msg
andAddCmd =
    Burrito.Update.andAddCmd


{-| See [`Burrito.Update.with`](Burrito.Update#with).
-}
with : (a -> b) -> (b -> a -> c) -> a -> c
with =
    Burrito.Update.with


{-| See [`Burrito.Update.using`](Burrito.Update#using).
-}
using : (a -> a -> b) -> a -> b
using =
    Burrito.Update.using


{-| See [`Burrito.Update.run`](Burrito.Update#run).
-}
run : (p -> Update a msg) -> p -> ( a, Cmd msg )
run =
    Burrito.Update.run


{-| See [`Burrito.Update.run2`](Burrito.Update#run2).
-}
run2 : (p -> q -> Update a msg) -> p -> q -> ( a, Cmd msg )
run2 =
    Burrito.Update.run2


{-| See [`Burrito.Update.run3`](Burrito.Update#run3).
-}
run3 : (p -> q -> r -> Update a msg) -> p -> q -> r -> ( a, Cmd msg )
run3 =
    Burrito.Update.run3
