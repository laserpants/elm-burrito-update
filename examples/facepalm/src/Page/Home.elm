module Page.Home exposing (Msg(..), State, init, subscriptions, update, view)

import Burrito.Api as Api exposing (Resource(..))
import Burrito.Api.Json as JsonApi
import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Data.DbRecord exposing (..)
import Data.Post as Post exposing (Post)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Ui exposing (spinner)
import Ui.Page


type alias DbPost =
    DbRecord Post


type Msg
    = ApiMsg (Api.Msg (List DbPost))


type alias State =
    { posts : Api.Model (List DbPost)
    }


type alias StateUpdate a =
    State -> Update State Msg a


insertAsPostsIn : State -> Api.Model (List DbPost) -> Update State msg a
insertAsPostsIn state posts =
    save { state | posts = posts }


inPostsApi : Api.ModelUpdate (List DbPost) (StateUpdate a) -> StateUpdate a
inPostsApi doUpdate state =
    doUpdate state.posts
        |> andThen (insertAsPostsIn state)
        |> mapCmd ApiMsg
        |> runCallbacks


init : Update State Msg a
init =
    let
        postDecoder =
            dbRecordDecoder Post.decoder

        api =
            JsonApi.init
                { endpoint = "/posts"
                , method = Api.HttpGet
                , decoder = Json.field "posts" (Json.list postDecoder)
                , headers = []
                }
    in
    save State
        |> andMap (mapCmd ApiMsg api)
        |> andThen (inPostsApi Api.sendSimpleRequest)


update : Msg -> StateUpdate a
update msg =
    case msg of
        ApiMsg apiMsg ->
            inPostsApi
                (Api.update apiMsg
                    { onSuccess = always save
                    , onError = always save
                    }
                )


subscriptions : State -> Sub Msg
subscriptions state =
    Sub.none


view : State -> Html Msg
view { posts } =
    let
        listItem { id, item } =
            div
                []
                [ text item.title
                ]
    in
    div []
        (case posts.resource of
            NotRequested ->
                [ text "nil" ]

            Requested ->
                [ spinner ]

            Error error ->
                [ text "error" ]

            -- resourceErrorMessage posts.resource ]
            Available items ->
                [ Ui.Page.container "Posts" (List.map listItem items)
                ]
        )



--List.map listItem items
--    div
--        []
--        []
--import Bulma.Elements exposing (..)
--import Bulma.Modifiers exposing (..)
--import Burrito.Callback exposing (..)
--import Burrito.Update exposing (..)
--import Burrito.Api as Api
--import Data.Post as Post exposing (Post)
--import Helpers exposing (..)
--import Helpers.Api exposing (resourceErrorMessage)
--import Html exposing (..)
--import Html.Attributes exposing (..)
--import Html.Events exposing (..)
--import Json.Decode as Json
--import Ui exposing (spinner)
--import Ui.Page
--
--
--type Msg
--    = ApiMsg (Api.Msg (List Post))
--    | FetchPosts
--
--
--type alias State =
--    { posts : Api.Model (List Post) }
--
--
--inPostsApi : Wrap State (Api.Model (List Post)) Msg (Api.Msg (List Post)) t
--inPostsApi =
--    wrapModel .posts (\state posts -> { state | posts = posts }) ApiMsg
--
--
--init : Update State Msg a
--init =
--    let
--        api =
--            Api.init
--                { endpoint = "/posts"
--                , method = Api.HttpGet
--                , decoder = Json.field "posts" (Json.list Post.decoder)
--                }
--    in
--    save State
--        |> andMap api
--
--
--update : Msg -> State -> Update State Msg a
--update msg =
--    case msg of
--        ApiMsg apiMsg ->
--            inPostsApi (Api.update { onSuccess = always save, onError = always save } apiMsg)
--
--        FetchPosts ->
--            inPostsApi Api.sendSimpleRequest
--
--
--subscriptions : State -> (Msg -> msg) -> Sub msg
--subscriptions state toMsg =
--    Sub.none
--
--
--view : State -> (Msg -> msg) -> Html msg
--view { posts } toMsg =
--    let
--        listItem { id, comments, title, body } =
--            let
--                postUrl =
--                    "/posts/" ++ String.fromInt id
--
--                commentsLink =
--                    case List.length comments of
--                        0 ->
--                            text "No comments"
--
--                        n ->
--                            a [ href postUrl ]
--                                [ text
--                                    (if 1 == n then
--                                        "1 comment"
--
--                                     else
--                                        String.fromInt n ++ " comments"
--                                    )
--                                ]
--            in
--            content Standard
--                []
--                [ h4 [ class "title is-4" ] [ a [ href postUrl ] [ text title ] ]
--                , p [] [ text body ]
--                , p []
--                    [ i [ class "fa fa-comments", style "margin-right" ".5em" ] []
--                    , commentsLink
--                    ]
--                ]
--
--        listView =
--            case posts.resource of
--                Api.NotRequested ->
--                    []
--
--                Api.Requested ->
--                    [ spinner ]
--
--                Api.Error error ->
--                    [ resourceErrorMessage posts.resource ]
--
--                Api.Available items ->
--                    List.map listItem items
--    in
--    Ui.Page.container "Posts" listView
