module Data.DbRecord exposing (DbRecord, dbRecordDecoder)

import Json.Decode as Json exposing (field, int)


type alias DbRecord a =
    { id : Int
    , item : a
    }


dbRecordDecoder : Json.Decoder a -> Json.Decoder (DbRecord a)
dbRecordDecoder =
    Json.map2 DbRecord (field "id" int)
