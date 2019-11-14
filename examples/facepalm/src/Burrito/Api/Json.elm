module Burrito.Api.Json exposing (JsonRequestConfig, init, sendJson)

import Burrito.Api as Api exposing (HttpMethod, Model, ModelUpdate, Msg(..))
import Burrito.Update exposing (Update)
import Http
import Json.Decode as Json


sendJson : String -> Json.Value -> ModelUpdate resource a
sendJson suffix =
    Http.jsonBody >> Just >> Api.sendRequest suffix


type alias JsonRequestConfig resource =
    { endpoint : String
    , method : HttpMethod
    , decoder : Json.Decoder resource
    , headers : List ( String, String )
    }


init : JsonRequestConfig resource -> Update (Model resource) msg a
init { endpoint, method, decoder, headers } =
    Api.init
        { endpoint = endpoint
        , method = method
        , expect = Http.expectJson Response decoder
        , headers = headers
        }
