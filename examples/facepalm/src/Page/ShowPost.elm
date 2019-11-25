module Page.ShowPost exposing (Msg(..), State, init, subscriptions, update, view)

import Bulma.Modifiers exposing (..)
import Burrito.Api as Api exposing (Resource(..))
import Burrito.Api.Json as JsonApi
import Burrito.Callback exposing (..)
import Burrito.Form as Form exposing (Variant(..))
import Burrito.Update exposing (..)
import Data.Comment as Comment exposing (Comment)
import Data.Post as Post exposing (Post)
import Form.Comment as CommentForm exposing (Fields(..))
import Helpers exposing (empty)
import Helpers.Api exposing (requestErrorMessage)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Ui exposing (spinner)
import Ui.Page


type Msg
    = PostApiMsg (Api.Msg Post)
    | CommentApiMsg (Api.Msg Comment)
    | CommentFormMsg CommentForm.Msg
    | FetchPost


type alias State =
    { id : Int
    , postApi : Api.Model Post
    , commentApi : Api.Model Comment
    , commentForm : CommentForm.Model
    }


type alias StateUpdate a =
    State -> Update State Msg a


insertAsPostApiIn : State -> Api.Model Post -> Update State msg a
insertAsPostApiIn state postApi =
    save { state | postApi = postApi }


insertAsCommentApiIn : State -> Api.Model Comment -> Update State msg a
insertAsCommentApiIn state commentApi =
    save { state | commentApi = commentApi }


insertAsCommentFormIn : State -> CommentForm.Model -> Update State msg a
insertAsCommentFormIn state commentForm =
    save { state | commentForm = commentForm }


inPostApi : Api.ModelUpdate Post (StateUpdate a) -> StateUpdate a
inPostApi doUpdate state =
    state.postApi
        |> doUpdate
        |> andThen (insertAsPostApiIn state)
        |> mapCmd PostApiMsg
        |> runCallbacks


inCommentApi : Api.ModelUpdate Comment (StateUpdate a) -> StateUpdate a
inCommentApi doUpdate state =
    state.commentApi
        |> doUpdate
        |> andThen (insertAsCommentApiIn state)
        |> mapCmd CommentApiMsg
        |> runCallbacks


inCommentForm : CommentForm.ModelUpdate (StateUpdate a) -> StateUpdate a
inCommentForm doUpdate state =
    state.commentForm
        |> doUpdate
        |> andThen (insertAsCommentFormIn state)
        |> mapCmd CommentFormMsg
        |> runCallbacks


init : Int -> Update State Msg a
init id =
    let
        post =
            JsonApi.init
                { endpoint = "/posts/" ++ String.fromInt id
                , method = Api.HttpGet
                , decoder = Json.field "post" Post.decoder
                , headers = []
                }

        comment =
            JsonApi.init
                { endpoint = "/posts/" ++ String.fromInt id ++ "/comments"
                , method = Api.HttpPost
                , decoder = Json.field "comment" Comment.decoder
                , headers = []
                }
    in
    save State
        |> andMap (save id)
        |> andMap post
        |> andMap comment
        |> andMap CommentForm.init
        |> andThen (inPostApi Api.sendSimpleRequest)


handleSubmit : CommentForm.Data -> StateUpdate a
handleSubmit data =
    let
        json =
            Http.jsonBody (CommentForm.toJson data)
    in
    inCommentApi (Api.sendRequest "" (Just json))


update : Msg -> { onCommentCreated : Comment -> a } -> StateUpdate a
update msg { onCommentCreated } =
    let
        commentCreated comment =
            inCommentForm Form.reset
                >> andThen (inPostApi Api.sendSimpleRequest)
                >> andApply (onCommentCreated comment)
    in
    case msg of
        PostApiMsg apiMsg ->
            inPostApi
                (Api.update apiMsg
                    { onSuccess = always save
                    , onError = always save
                    }
                )

        CommentApiMsg apiMsg ->
            inCommentApi
                (Api.update apiMsg
                    { onSuccess = commentCreated
                    , onError = always save
                    }
                )

        CommentFormMsg commentFormMsg ->
            inCommentForm
                (Form.update commentFormMsg
                    { onSubmit = handleSubmit
                    }
                )

        FetchPost ->
            inPostApi Api.sendSimpleRequest


subscriptions : State -> Sub Msg
subscriptions _ =
    Sub.none


view : State -> Html Msg
view { postApi, commentApi, commentForm } =
    let
        loading =
            Api.Requested == postApi.resource || commentForm.disabled

        commentItem { email, body } =
            [ p
                [ style "margin-bottom" ".5em" ]
                [ b
                    []
                    [ text "From: "
                    ]
                , text email
                ]
            , p [] [ text body ]
            , hr [] []
            ]

        subtitle title =
            h5
                [ class "title is-5"
                , style "margin-top" "1.5em"
                ]
                [ text title ]

        postView =
            case postApi.resource of
                Api.Error error ->
                    case error of
                        Http.BadStatus 404 ->
                            [ h3 [ class "title is-3" ] [ text "Page not found" ]
                            , p [] [ text "That post doesn’t exist." ]
                            ]

                        _ ->
                            [ requestErrorMessage error ]

                Api.Available { title, body, comments } ->
                    [ h3 [ class "title is-3" ] [ text title ]
                    , p [] [ text body ]
                    , hr [] []
                    , subtitle "Comments"
                    , div []
                        (if List.isEmpty comments then
                            [ p [] [ text "No comments" ] ]

                         else
                            List.concatMap commentItem comments
                        )
                    , subtitle "Leave a comment"
                    , case commentApi.resource of
                        Error error ->
                            requestErrorMessage error

                        _ ->
                            empty
                    , Html.map CommentFormMsg (CommentForm.view commentForm)
                    ]

                _ ->
                    []
    in
    Ui.Page.layout
        (if loading then
            [ spinner ]

         else
            postView
        )
