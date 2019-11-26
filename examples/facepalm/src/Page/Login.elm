module Page.Login exposing (Msg(..), State, StateUpdate, init, subscriptions, update, view)

import Bulma.Columns exposing (columnsModifiers, narrowColumnModifiers)
import Bulma.Components exposing (..)
import Bulma.Modifiers exposing (..)
import Burrito.Api as Api exposing (Resource(..))
import Burrito.Api.Json as JsonApi
import Burrito.Form as Form exposing (Variant(..))
import Burrito.Update exposing (..)
import Data.Session as Session exposing (Session)
import Form.Login as LoginForm exposing (Fields(..))
import Helpers exposing (empty)
import Helpers.Api exposing (requestErrorMessage)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json


type Msg
    = ApiMsg (Api.Msg Session)
    | FormMsg LoginForm.Msg


type alias State =
    { api : Api.Model Session
    , form : LoginForm.Model
    }


type alias StateUpdate a =
    State -> Update State Msg a


insertAsApiIn : State -> Api.Model Session -> Update State msg a
insertAsApiIn state api =
    save { state | api = api }


insertAsFormIn : State -> LoginForm.Model -> Update State msg a
insertAsFormIn state form =
    save { state | form = form }


inAuthApi : Api.ModelUpdate Session (StateUpdate a) -> StateUpdate a
inAuthApi doUpdate state =
    state.api
        |> doUpdate
        |> andThen (insertAsApiIn state)
        |> mapCmd ApiMsg
        |> runCallbacks


inLoginForm : LoginForm.ModelUpdate (StateUpdate a) -> StateUpdate a
inLoginForm doUpdate state =
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
                { endpoint = "/auth/login"
                , method = Api.HttpPost
                , decoder = Json.field "session" Session.decoder
                , headers = []
                }
    in
    save State
        |> andMap api
        |> andMap LoginForm.init


handleSubmit : LoginForm.Data -> StateUpdate a
handleSubmit data =
    let
        json =
            Http.jsonBody (LoginForm.toJson data)
    in
    inAuthApi (Api.sendRequest "" (Just json))


update : Msg -> { onAuthResponse : Maybe Session -> a } -> StateUpdate a
update msg { onAuthResponse } =
    let
        handleApiResponse maybeSession =
            inLoginForm Form.reset
                >> andApply (onAuthResponse maybeSession)
    in
    case msg of
        ApiMsg apiMsg ->
            inAuthApi
                (Api.update apiMsg
                    { onSuccess = handleApiResponse << Just
                    , onError = always (handleApiResponse Nothing)
                    }
                )

        FormMsg formMsg ->
            inLoginForm
                (Form.update formMsg
                    { onSubmit = handleSubmit
                    }
                )


subscriptions : State -> Sub Msg
subscriptions _ =
    Sub.none


view : State -> Html Msg
view { api, form } =
    Bulma.Columns.columns
        { columnsModifiers | centered = True }
        [ class "is-mobile"
        , style "margin" "6em 0"
        ]
        [ Bulma.Columns.column
            narrowColumnModifiers
            []
            [ card []
                [ cardContent []
                    [ h3 [ class "title is-3" ] [ text "Log in" ]
                    , message { messageModifiers | color = Info }
                        [ style "max-width" "360px" ]
                        [ messageBody []
                            [ text "This is just a demo. Log in with email address 'test@test.com' and password 'test'." ]
                        ]
                    , case api.resource of
                        Error error ->
                            requestErrorMessage error

                        _ ->
                            empty
                    , Html.map FormMsg (LoginForm.view form)
                    ]
                ]
            ]
        ]
