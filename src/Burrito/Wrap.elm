module Burrito.Wrap exposing (apply, unwrap)

{-| TODO

@docs apply, unwrap

-}

import Burrito.Update exposing (..)


{-| TODO
-}
apply : t -> a -> Update a msg t
apply call model =
    ( model, [], [ call ] )


{-| TODO
-}
unwrap : Update a msg (a -> Update a msg t) -> Update a msg t1
unwrap ( model1, cmds1, calls ) =
    let
        ( model2, cmds2, _ ) =
            sequence calls model1
    in
    ( model2, cmds1 ++ cmds2, [] )
