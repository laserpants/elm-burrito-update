module Page.Home exposing (Msg(..), State, init, subscriptions, update, view)

import Bulma.Elements exposing (..)
import Bulma.Modifiers exposing (..)
import Burrito.Api as Api exposing (Resource(..))
import Burrito.Api.Json as JsonApi
import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Data.DbRecord exposing (..)
import Data.Post as Post exposing (Post)
import Helpers.Api exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Ui exposing (spinner)
import Ui.Page


type alias Posts =
    List (DbRecord Post)


type Msg
    = ApiMsg (Api.Msg Posts)


type alias State =
    { posts : Api.Model Posts
    }


type alias StateUpdate a =
    State -> Update State Msg a


insertAsPostsIn : State -> Api.Model Posts -> Update State msg a
insertAsPostsIn state posts =
    save { state | posts = posts }


inPostsApi : Api.ModelUpdate Posts (StateUpdate a) -> StateUpdate a
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
subscriptions _ =
    Sub.none


view : State -> Html Msg
view { posts } =
    let
        listItem { id, item } =
            let
                { comments, title, body } =
                    item

                postUrl =
                    "/posts/" ++ String.fromInt id

                commentsLink =
                    if List.isEmpty comments then
                        text "No comments"

                    else
                        let
                            len =
                                List.length comments
                        in
                        a [ href postUrl ]
                            [ text
                                (if 1 == len then
                                    "1 comment"

                                 else
                                    String.fromInt len ++ " comments"
                                )
                            ]
            in
            content Standard
                []
                [ h4
                    [ class "title is-4" ]
                    [ a [ href postUrl ]
                        [ text title ]
                    ]
                , p [] [ text body ]
                , p []
                    [ i
                        [ class "fa fa-comments"
                        , style "margin-right" ".5em"
                        ]
                        []
                    , commentsLink
                    ]
                ]
    in
    div []
        (case posts.resource of
            NotRequested ->
                []

            Requested ->
                [ spinner ]

            Error error ->
                [ requestErrorMessage error ]

            Available items ->
                [ Ui.Page.container "Posts" (List.map listItem items)
                ]
        )
