module Page.NewPost exposing (Msg(..), State, init, subscriptions, update, view)

import Bulma.Form exposing (controlInputModifiers, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Api as Api exposing (..)
import Burrito.Api.Json as JsonApi
import Burrito.Callback exposing (..)
import Burrito.Form as Form
import Burrito.Update exposing (..)
import Data.Post as Post exposing (Post)
import Form.NewPost as NewPostForm
import Helpers exposing (..)
import Helpers.Api exposing (requestErrorMessage)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Ui.Page


type Msg
    = ApiMsg (Api.Msg Post)
    | FormMsg NewPostForm.Msg


type alias State =
    { api : Api.Model Post
    , form : NewPostForm.Model
    }


type alias StateUpdate a =
    State -> Update State Msg a


insertAsApiIn : State -> Api.Model Post -> Update State msg a
insertAsApiIn state api =
    save { state | api = api }


insertAsFormIn : State -> NewPostForm.Model -> Update State msg a
insertAsFormIn state form =
    save { state | form = form }


inPostApi : Api.ModelUpdate Post (StateUpdate a) -> StateUpdate a
inPostApi doUpdate state =
    state.api
        |> doUpdate
        |> andThen (insertAsApiIn state)
        |> mapCmd ApiMsg
        |> runCallbacks


inNewPostForm : NewPostForm.ModelUpdate (StateUpdate a) -> StateUpdate a
inNewPostForm doUpdate state =
    state.form
        |> doUpdate
        |> andThen (insertAsFormIn state)
        |> mapCmd FormMsg
        |> runCallbacks


init : Update State Msg a
init =
    let
        api =
            JsonApi.init
                { endpoint = "/posts"
                , method = Api.HttpPost
                , decoder = Json.field "post" Post.decoder
                , headers = []
                }
    in
    save State
        |> andMap api
        |> andMap NewPostForm.init


handleSubmit : NewPostForm.Data -> StateUpdate a
handleSubmit data =
    let
        json =
            Http.jsonBody (NewPostForm.toJson data)
    in
    inPostApi (Api.sendRequest "" (Just json))


update : Msg -> { onPostAdded : Post -> a } -> StateUpdate a
update msg { onPostAdded } =
    case msg of
        ApiMsg apiMsg ->
            inPostApi
                (Api.update apiMsg
                    { onSuccess = apply << onPostAdded
                    , onError = always save
                    }
                )

        FormMsg newPostFormMsg ->
            inNewPostForm
                (Form.update newPostFormMsg
                    { onSubmit = handleSubmit
                    }
                )


subscriptions : State -> Sub Msg
subscriptions _ =
    Sub.none


view : State -> Html Msg
view { api, form } =
    Ui.Page.container "New post"
        [ case api.resource of
            Error error ->
                requestErrorMessage error

            _ ->
                empty
        , Html.map FormMsg (NewPostForm.view form)
        ]
