module Data.Comment exposing (Comment, decoder)

import Json.Decode as Json exposing (field, string)


type alias Comment =
    { email : String
    , body : String
    }


decoder : Json.Decoder Comment
decoder =
    Json.map2 Comment
        (field "email" string)
        (field "body" string)
