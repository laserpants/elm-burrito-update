module Data.Session exposing (Session, decoder)

import Data.DbRecord exposing (DbRecord, dbRecordDecoder)
import Data.User as User exposing (User)
import Json.Decode as Json exposing (field)


type alias Session =
    { user : DbRecord User
    }


decoder : Json.Decoder Session
decoder =
    Json.map Session (field "user" (dbRecordDecoder User.decoder))
