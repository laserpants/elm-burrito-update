module Helpers exposing (..)

--import Burrito.Callback exposing (..)

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



--type alias Wrap state state1 msg msg1 t =
--    (state1 -> Update state1 msg1 (state -> Update state msg t)) -> state -> Update state msg t
--wrapModel :
--    (c -> a)
--    -> (c -> a -> b)
--    -> (msg -> msg1)
--    -> (a -> Update a msg (b -> Update b msg1 t))
--    -> c
--    -> Update b msg1 t
--wrapModel getter setter toMsg fun state =
--    getter state
--        |> fun
--        |> Burrito.Update.map (setter state)
--        |> mapCmd toMsg
--        |> runCallbacks
