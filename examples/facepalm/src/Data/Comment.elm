module Data.Comment exposing (Comment, decoder)

import Json.Decode as Json exposing (field, int, string)


type alias Comment =
    { id : Int
    , postId : Int
    , email : String
    , body : String
    }


decoder : Json.Decoder Comment
decoder =
    Json.map4 Comment
        (field "id" int)
        (field "postId" int)
        (field "email" string)
        (field "body" string)
