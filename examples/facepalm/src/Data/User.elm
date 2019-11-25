module Data.User exposing (User, decoder)

import Json.Decode as Json exposing (bool, field, string)


type alias User =
    { name : String
    , email : String
    , rememberMe : Bool
    }


decoder : Json.Decoder User
decoder =
    Json.map3 User
        (field "name" string)
        (field "email" string)
        (field "rememberMe" bool)
