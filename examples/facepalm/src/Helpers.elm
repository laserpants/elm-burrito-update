module Helpers exposing (andIf, empty, when)

import Burrito.Update exposing (..)
import Html exposing (..)


when : Bool -> (a -> Update a msg t) -> a -> Update a msg t
when cond f =
    if cond then
        f

    else
        save


andIf : Bool -> (a -> Update a msg t) -> Update a msg t -> Update a msg t
andIf cond =
    andThen << when cond


empty : Html msg
empty =
    text ""
