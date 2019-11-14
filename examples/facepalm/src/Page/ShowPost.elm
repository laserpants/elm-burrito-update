module Page.ShowPost exposing (Msg(..), State, init, subscriptions, update, view)

import Bulma.Elements exposing (..)
import Bulma.Modifiers exposing (..)
import Burrito.Api as Api
import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Burrito.Update.Form as Form
import Data.Comment as Comment exposing (Comment)
import Data.Post as Post exposing (Post)
import Form.Comment
import Helpers exposing (..)
import Helpers.Api exposing (resourceErrorMessage)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Ui exposing (spinner)
import Ui.Page


type Msg
    = NoMsg


type alias State =
    {}


init =
    save
        {}


update msg =
    save


subscriptions state =
    Sub.none


view state =
    div
        []
        []



--type Msg
--    = PostApiMsg (Api.Msg Post)
--    | CommentApiMsg (Api.Msg Comment)
--    | FetchPost
--    | CommentFormMsg Form.Msg
--
--
--type alias State =
--    { id : Int
--    , post : Api.Model Post
--    , comment : Api.Model Comment
--    , commentForm : Form.Model Never Form.Comment.Fields
--    }
--
--
--inPostApi : Wrap State (Api.Model Post) Msg (Api.Msg Post) a
--inPostApi =
--    wrapModel .post (\state post -> { state | post = post }) PostApiMsg
--
--
--inCommentApi : Wrap State (Api.Model Comment) Msg (Api.Msg Comment) a
--inCommentApi =
--    wrapModel .comment (\state comment -> { state | comment = comment }) CommentApiMsg
--
--
--inCommentForm : Wrap State (Form.Model Never Form.Comment.Fields) Msg Form.Msg a
--inCommentForm =
--    wrapModel .commentForm (\state form -> { state | commentForm = form }) CommentFormMsg
--
--
--init : Int -> Update State Msg a
--init id =
--    let
--        post =
--            Api.init
--                { endpoint = "/posts/" ++ String.fromInt id
--                , method = Api.HttpGet
--                , decoder = Json.field "post" Post.decoder
--                }
--
--        comment =
--            Api.init
--                { endpoint = "/posts/" ++ String.fromInt id ++ "/comments"
--                , method = Api.HttpPost
--                , decoder = Json.field "comment" Comment.decoder
--                }
--    in
--    save State
--        |> andMap (save id)
--        |> andMap post
--        |> andMap comment
--        |> andMap (Form.init [] Form.Comment.validate)
--
--
--handleSubmit : Form.Comment.Fields -> State -> Update State Msg a
--handleSubmit form state =
--    let
--        json =
--            form |> Form.Comment.toJson state.id |> Http.jsonBody
--    in
--    state
--        |> inCommentApi (Api.sendRequest "" (Just json))
--
--
--update : { onCommentCreated : Comment -> a } -> Msg -> State -> Update State Msg a
--update { onCommentCreated } msg =
--    let
--        commentCreated comment =
--            inCommentForm (Form.reset [])
--                >> andThen (inPostApi Api.sendSimpleRequest)
--                >> andApply (onCommentCreated comment)
--    in
--    case msg of
--        PostApiMsg apiMsg ->
--            inPostApi (Api.update { onSuccess = always save, onError = always save } apiMsg)
--
--        FetchPost ->
--            inPostApi Api.sendSimpleRequest
--
--        CommentFormMsg formMsg ->
--            inCommentForm (Form.update { onSubmit = handleSubmit } formMsg)
--
--        CommentApiMsg apiMsg ->
--            inCommentApi (Api.update { onSuccess = commentCreated, onError = always save } apiMsg)
--
--
--subscriptions : State -> (Msg -> msg) -> Sub msg
--subscriptions state toMsg =
--    Sub.none
--
--
--view : State -> (Msg -> msg) -> Html msg
--view { post, comment, commentForm } toMsg =
--    let
--        { form, disabled } =
--            commentForm
--
--        commentItem { email, body } =
--            [ p [ style "margin-bottom" ".5em" ] [ b [] [ text "From: " ], text email ]
--            , p [] [ text body ]
--            , hr [] []
--            ]
--
--        subtitle title =
--            h5 [ class "title is-5", style "margin-top" "1.5em" ] [ text title ]
--
--        postView =
--            case post.resource of
--                Api.Error error ->
--                    case error of
--                        Http.BadStatus 404 ->
--                            [ h3 [ class "title is-3" ] [ text "Page not found" ]
--                            , p [] [ text "That post doesn’t exist." ]
--                            ]
--
--                        _ ->
--                            [ resourceErrorMessage post.resource ]
--
--                Api.Available { title, body, comments } ->
--                    [ h3 [ class "title is-3" ] [ text title ]
--                    , p [] [ text body ]
--                    , hr [] []
--                    , subtitle "Comments"
--                    , div []
--                        (if List.isEmpty comments then
--                            [ p [] [ text "No comments" ] ]
--
--                         else
--                            List.concatMap commentItem comments
--                        )
--                    , subtitle "Leave a comment"
--                    , resourceErrorMessage comment.resource
--                    , Form.Comment.view form disabled (toMsg << CommentFormMsg)
--                    ]
--
--                _ ->
--                    []
--
--        loading =
--            Api.Requested == post.resource || disabled
--    in
--    Ui.Page.layout
--        [ if loading then
--            spinner
--
--          else
--            div [] postView
--        ]
