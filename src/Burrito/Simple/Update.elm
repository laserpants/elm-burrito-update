module Burrito.Simple.Update exposing (..)

import Burrito.Update


{-| A simpler version of `Burrito.Update.Update` which is sufficient in most cases.
-}
type alias Update a msg =
    Burrito.Update.Update a msg ()
