module Data.Post exposing (Post, decoder)

import Data.Comment as Comment exposing (Comment)
import Json.Decode as Json exposing (field, list, string)


type alias Post =
    { title : String
    , body : String
    , comments : List Comment
    }


decoder : Json.Decoder Post
decoder =
    Json.map3 Post
        (field "title" string)
        (field "body" string)
        (field "comments" (list Comment.decoder))
