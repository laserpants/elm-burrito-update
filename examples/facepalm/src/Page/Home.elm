module Page.Home exposing (Msg(..), State, init, subscriptions, update, view)

import Bulma.Elements exposing (..)
import Bulma.Modifiers exposing (..)
import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Burrito.Update.Api as Api
import Data.Post as Post exposing (Post)
import Helpers exposing (..)
import Helpers.Api exposing (resourceErrorMessage)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Ui exposing (spinner)
import Ui.Page


type Msg
    = ApiMsg (Api.Msg (List Post))
    | FetchPosts


type alias State =
    { posts : Api.Model (List Post) }


inPosts : Wrap State (Api.Model (List Post)) Msg (Api.Msg (List Post)) t
inPosts =
    wrapModel .posts (\state posts -> { state | posts = posts }) ApiMsg


init : Update State Msg a
init =
    let
        api =
            Api.init
                { endpoint = "/posts"
                , method = Api.HttpGet
                , decoder = Json.field "posts" (Json.list Post.decoder)
                }
    in
    save State
        |> andMap api


update : Msg -> State -> Update State Msg a
update msg =
    case msg of
        ApiMsg apiMsg ->
            inPosts (Api.update { onSuccess = always save, onError = always save } apiMsg)

        FetchPosts ->
            inPosts Api.sendSimpleRequest


subscriptions : State -> (Msg -> msg) -> Sub msg
subscriptions state toMsg =
    Sub.none


view : State -> (Msg -> msg) -> Html msg
view { posts } toMsg =
    let
        listItem { id, comments, title, body } =
            let
                postUrl =
                    "/posts/" ++ String.fromInt id

                commentsLink =
                    case List.length comments of
                        0 ->
                            text "No comments"

                        n ->
                            a [ href postUrl ]
                                [ text
                                    (if 1 == n then
                                        "1 comment"

                                     else
                                        String.fromInt n ++ " comments"
                                    )
                                ]
            in
            content Standard
                []
                [ h4 [ class "title is-4" ] [ a [ href postUrl ] [ text title ] ]
                , p [] [ text body ]
                , p []
                    [ i [ class "fa fa-comments", style "margin-right" ".5em" ] []
                    , commentsLink
                    ]
                ]

        listView =
            case posts.resource of
                Api.NotRequested ->
                    []

                Api.Requested ->
                    [ spinner ]

                Api.Error error ->
                    [ resourceErrorMessage posts.resource ]

                Api.Available items ->
                    List.map listItem items
    in
    Ui.Page.container "Posts" listView
