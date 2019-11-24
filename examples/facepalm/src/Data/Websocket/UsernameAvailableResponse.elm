module Data.Websocket.UsernameAvailableResponse exposing (..)

import Json.Decode as Json exposing (bool, field, string)


type alias UsernameAvailableResponse =
    { username : String
    , available : Bool
    }


decoder : Json.Decoder UsernameAvailableResponse
decoder =
    Json.map2 UsernameAvailableResponse
        (field "username" string)
        (field "available" bool)
