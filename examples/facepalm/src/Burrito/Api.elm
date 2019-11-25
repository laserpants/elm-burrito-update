module Burrito.Api exposing (HttpMethod(..), Model, ModelUpdate, Msg(..), Request, RequestConfig, Resource(..), apiDefaultHandlers, init, resetResource, sendRequest, sendSimpleRequest, setResource, update, updateResourceWith)

import Burrito.Callback exposing (andApply)
import Burrito.Update exposing (Update, andAddCmd, save, using)
import Http exposing (Expect, emptyBody)


type Msg resource
    = Response (Result Http.Error resource)


type Resource resource
    = NotRequested
    | Requested
    | Error Http.Error
    | Available resource


type alias Request resource =
    String -> Maybe Http.Body -> Cmd (Msg resource)


type alias Model resource =
    { resource : Resource resource
    , request : Request resource
    }


type alias ModelUpdate resource a =
    Model resource -> Update (Model resource) (Msg resource) a


setResource : Resource resource -> ModelUpdate resource a
setResource resource state =
    save { state | resource = resource }


updateResourceWith : (resource -> resource) -> ModelUpdate resource a
updateResourceWith updater =
    using
        (\{ resource } ->
            case resource of
                Available available ->
                    setResource (Available <| updater available)

                _ ->
                    save
        )


type HttpMethod
    = HttpGet
    | HttpPost
    | HttpPut


type alias RequestConfig resource =
    { endpoint : String
    , method : HttpMethod
    , expect : Expect (Msg resource)
    , headers : List ( String, String )
    }


init : RequestConfig resource -> Update (Model resource) msg a
init { endpoint, method, expect, headers } =
    let
        methodStr =
            case method of
                HttpGet ->
                    "GET"

                HttpPost ->
                    "POST"

                HttpPut ->
                    "PUT"

        request suffix body =
            Http.request
                { method = methodStr
                , headers = List.map toHeader headers
                , url = endpoint ++ suffix
                , expect = expect
                , body = Maybe.withDefault emptyBody body
                , timeout = Nothing
                , tracker = Nothing
                }
    in
    save { resource = NotRequested, request = request }


toHeader : ( String, String ) -> Http.Header
toHeader ( a, b ) =
    Http.header a b


sendRequest : String -> Maybe Http.Body -> ModelUpdate resource a
sendRequest suffix maybeBody =
    using
        (\{ request } ->
            setResource Requested
                >> andAddCmd (request suffix maybeBody)
        )


sendSimpleRequest : ModelUpdate resource a
sendSimpleRequest =
    sendRequest "" Nothing


resetResource : ModelUpdate resource a
resetResource =
    setResource NotRequested


apiDefaultHandlers :
    { onError : Http.Error -> a1 -> Update a1 msg1 t1
    , onSuccess : resource -> a -> Update a msg t
    }
apiDefaultHandlers =
    { onSuccess = always save
    , onError = always save
    }


update :
    Msg resource
    -> { onSuccess : resource -> a, onError : Http.Error -> a }
    -> ModelUpdate resource a
update msg { onSuccess, onError } =
    case msg of
        Response (Ok resource) ->
            setResource (Available resource)
                >> andApply (onSuccess resource)

        Response (Err error) ->
            setResource (Error error)
                >> andApply (onError error)
