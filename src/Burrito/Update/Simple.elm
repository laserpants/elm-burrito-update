module Burrito.Update.Simple exposing (Update)

{-| A simpler version of `Update` which is sufficient in most cases.


@docs Update

-}

import Burrito.Update


{-| See [`Burrito.Update.Update`](Burrito.Update#Update). 
-}
type alias Update a msg =
    Burrito.Update.Update a msg ()
