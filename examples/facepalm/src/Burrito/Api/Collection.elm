module Burrito.Api.Collection exposing (..)

import Burrito.Api as Api exposing (Resource(..), apiDefaultHandlers)
import Burrito.Update exposing (Update, andMap, andThen, mapCmd, runCallbacks, save, using, with)
import Http exposing (Expect)


type alias Envelope item =
    { page : List item
    , total : Int
    }


type Msg item
    = ApiMsg (Api.Msg (Envelope item))
    | NextPage
    | PrevPage
    | GoToPage Int


type alias Collection item =
    { api : Api.Model (Envelope item)
    , current : Int
    , pages : Int
    , limit : Int
    , query : Int -> Int -> String
    }


type alias CollectionUpdate item a =
    Collection item -> Update (Collection item) (Msg item) a


insertAsApiIn : Collection item -> Api.Model (Envelope item) -> Update (Collection item) msg a
insertAsApiIn state api =
    save { state | api = api }


inApi : Api.ModelUpdate (Envelope item) (CollectionUpdate item a) -> CollectionUpdate item a
inApi doUpdate state =
    state.api
        |> doUpdate
        |> andThen (insertAsApiIn state)
        |> mapCmd ApiMsg
        |> runCallbacks


setCurrent : Int -> CollectionUpdate item a
setCurrent page state =
    save { state | current = page }


setPages : Int -> CollectionUpdate item a
setPages pages state =
    save { state | pages = pages }


setLimit : Int -> CollectionUpdate item a
setLimit limit state =
    save { state | limit = limit }


fetchPage : CollectionUpdate item a
fetchPage state =
    let
        { limit, current, query } =
            state

        offset =
            limit * (current - 1)
    in
    state
        |> inApi (Api.sendRequest (query offset limit) Nothing)


goToPage : Int -> CollectionUpdate item a
goToPage page =
    setCurrent page >> andThen fetchPage


nextPage : CollectionUpdate item a
nextPage =
    using (\{ current } -> goToPage (current + 1))


prevPage : CollectionUpdate item a
prevPage =
    using (\{ current } -> goToPage (max 1 (current - 1)))


type alias RequestConfig item =
    { limit : Int
    , endpoint : String
    , expect : Expect (Api.Msg (Envelope item))
    , headers : List ( String, String )
    , queryString : Int -> Int -> String
    }


defaultQuery : Int -> Int -> String
defaultQuery offset limit =
    "?offset=" ++ String.fromInt offset ++ "&limit=" ++ String.fromInt limit


init : RequestConfig item -> Update (Collection item) (Msg item) a
init { limit, endpoint, expect, headers, queryString } =
    let
        api =
            Api.init
                { endpoint = endpoint
                , method = Api.HttpGet
                , expect = expect
                , headers = headers
                }
    in
    save Collection
        |> andMap api
        |> andMap (save 1)
        |> andMap (save 0)
        |> andMap (save limit)
        |> andMap (save queryString)


updateCurrentPage : Envelope item -> CollectionUpdate item a
updateCurrentPage { total } =
    using
        (\{ limit } ->
            let
                pages =
                    (total + limit - 1) // limit
            in
            setPages pages
                >> andThen (with .current (setCurrent << clamp 1 pages))
        )


update : Msg item -> CollectionUpdate item a
update msg =
    case msg of
        ApiMsg apiMsg ->
            inApi (Api.update apiMsg { apiDefaultHandlers | onSuccess = updateCurrentPage })

        NextPage ->
            nextPage

        PrevPage ->
            prevPage

        GoToPage page ->
            goToPage page
