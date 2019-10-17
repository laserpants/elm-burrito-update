module Burrito.Callback exposing (apply, runCallbacks)

{-| Callbacks to allow for information to be passed *up* in the update tree.

@docs apply, runCallbacks

-}

import Burrito.Update exposing (..)


{-| Append a partially applied callback to the list of functions which will be applied to the returned value.
-}
apply : t -> a -> Update a msg t
apply call model =
    ( model, [], [ call ] )


{-| Sequentially compose the list of monadic functions (callbacks) produced by a nested update call.
-}
runCallbacks : Update a msg (a -> Update a msg t) -> Update a msg t1
runCallbacks ( model1, cmds1, calls ) =
    let
        ( model2, cmds2, _ ) =
            sequence calls model1
    in
    ( model2, cmds1 ++ cmds2, [] )
