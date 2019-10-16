module Burrito.Unwrap exposing (..)

import Burrito.Update exposing (..)


apply : z -> a -> UpdateT a m z
apply z model =
    ( model, [], [ z ] )


unwrap : UpdateT a m (a -> UpdateT a m z) -> UpdateT a m x
unwrap ( a, cmds1, zs ) =
    let
        ( b, cmds2, _ ) = sequence zs a
    in
    ( b, cmds1 ++ cmds2, [] )
