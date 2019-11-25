module Burrito.Api.Collection.Json exposing (JsonRequestConfig(..), envelopeDecoder, init)

import Burrito.Api exposing (Msg(..))
import Burrito.Api.Collection as Collection exposing (Collection, Envelope, Msg)
import Burrito.Update exposing (..)
import Http
import Json.Decode as Json


type alias JsonRequestConfig item =
    { limit : Int
    , endpoint : String
    , decoder : Json.Decoder (Envelope item)
    , headers : List ( String, String )
    , queryString : Int -> Int -> String
    }


envelopeDecoder : String -> Json.Decoder item -> Json.Decoder (Envelope item)
envelopeDecoder key itemDecoder =
    Json.map2 Envelope
        (Json.field key (Json.list itemDecoder))
        (Json.field "total" Json.int)


init : JsonRequestConfig item -> Update (Collection item) (Msg item) a
init { limit, endpoint, decoder, headers, queryString } =
    Collection.init
        { limit = limit
        , endpoint = endpoint
        , expect = Http.expectJson Response decoder
        , headers = headers
        , queryString = queryString
        }
