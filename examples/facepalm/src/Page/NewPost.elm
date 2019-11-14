module Page.NewPost exposing (Msg(..), State, init, subscriptions, update, view)

import Bulma.Form exposing (controlInputModifiers, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Api as Api
import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Burrito.Update.Form as Form
import Data.Post as Post exposing (Post)
import Form.Field exposing (FieldValue(..))
import Form.NewPost
import Helpers exposing (..)
import Helpers.Api exposing (resourceErrorMessage)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Ui.Page


type Msg
    = NoMsg



--    = ApiMsg (Api.Msg Post)
--    | FormMsg Form.Msg


type alias State =
    {}



--    { api : Api.Model Post
--    , formModel : Form.Model Never Form.NewPost.Fields
--    }
--inApi : Wrap State (Api.Model Post) Msg (Api.Msg Post) t
--inApi =
--    wrapModel .api (\state api -> { state | api = api }) ApiMsg
--
--
--inForm : Wrap State (Form.Model Never Form.NewPost.Fields) Msg Form.Msg t
--inForm =
--    wrapModel .formModel (\state form -> { state | formModel = form }) FormMsg


init : Update State Msg a
init =
    save {}



--    let
--        api =
--            Api.init
--                { endpoint = "/posts"
--                , method = Api.HttpPost
--                , decoder = Json.field "post" Post.decoder
--                }
--    in
--    save State
--        |> andMap api
--        |> andMap (Form.init [] Form.NewPost.validate)
--handleSubmit : Form.NewPost.Fields -> State -> Update State Msg a
--handleSubmit form =
--    let
--        json =
--            form |> Form.NewPost.toJson |> Http.jsonBody in
--    inApi (Api.sendRequest "" (Just json))


update msg =
    save



--update : { onPostAdded : Post -> a } -> Msg -> State -> Update State Msg a
--update { onPostAdded } msg =
--    case msg of
--        ApiMsg apiMsg ->
--            inApi (Api.update { onSuccess = apply << onPostAdded, onError = always save } apiMsg)
--
--        FormMsg formMsg ->
--            inForm (Form.update { onSubmit = handleSubmit } formMsg)


subscriptions =
    Sub.none



--subscriptions : State -> (Msg -> msg) -> Sub msg
--subscriptions state toMsg =
--    Sub.none


view state =
    div
        []
        [ text "new post"
        ]



--view : State -> (Msg -> msg) -> Html msg
--view { api, formModel } toMsg =
--    let
--        { form, disabled } =
--            formModel
--    in
--    Ui.Page.container "New post"
--        [ resourceErrorMessage api.resource
--        , Form.NewPost.view form disabled (toMsg << FormMsg)
--        ]
