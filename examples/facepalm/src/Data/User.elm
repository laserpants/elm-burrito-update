module Data.User exposing (User, decoder)

import Json.Decode as Json exposing (bool, field, int, string)


type alias User =
    { id : Int
    , username : String
    , name : String
    , email : String
    , rememberMe : Bool
    }


decoder : Json.Decoder User
decoder =
    Json.map5 User
        (field "id" int)
        (field "username" string)
        (field "name" string)
        (field "email" string)
        (field "rememberMe" bool)
