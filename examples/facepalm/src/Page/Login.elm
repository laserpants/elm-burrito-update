module Page.Login exposing (..)

-- Msg(..), State, init, subscriptions, update, view)
--import Bulma.Form exposing (controlInputModifiers)
--import Burrito.Update.Form as Form
--import Form.Login
--import Helpers exposing (..)
--import Helpers.Api exposing (resourceErrorMessage)
--import Helpers.Form exposing (..)
--import Http

import Bulma.Components exposing (..)
import Bulma.Form exposing (controlCheckBox, controlHelp, controlInput, controlInputModifiers, controlLabel, controlPassword, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Api as Api
import Burrito.Api.Json as JsonApi
import Burrito.Callback exposing (..)
import Burrito.Form2 as Form exposing (FieldValue(..))
import Burrito.Update exposing (..)
import Data.Session as Session exposing (Session)
import Form.Login as LoginForm
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json


type Msg
    = ApiMsg (Api.Msg Session)
    | FormMsg LoginForm.Msg


type alias State =
    { api : Api.Model Session
    , form : Form.Model LoginForm.Fields
    }


insertAsApiIn : State -> Api.Model Session -> Update State msg a
insertAsApiIn state api =
    save { state | api = api }


insertAsFormIn : State -> Form.Model LoginForm.Fields -> Update State msg a
insertAsFormIn state form =
    save { state | form = form }


inAuthApi : Api.ModelUpdate Session (StateUpdate a) -> StateUpdate a
inAuthApi doUpdate state =
    doUpdate state.api
        |> andThen (insertAsApiIn state)
        |> mapCmd ApiMsg
        |> runCallbacks


inLoginForm : Form.ModelUpdate LoginForm.Fields LoginForm.Msg (StateUpdate a) -> StateUpdate a
inLoginForm doUpdate state =
    doUpdate state.form
        |> andThen (insertAsFormIn state)
        |> mapCmd FormMsg
        |> runCallbacks


type alias StateUpdate a =
    State -> Update State Msg a


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
        |> andMap (LoginForm.init |> mapCmd FormMsg)


update : Msg -> StateUpdate a
update msg =
    case msg of
        ApiMsg apiMsg ->
            inAuthApi
                (Api.update apiMsg
                    { onSuccess = always save
                    , onError = always save
                    }
                )

        FormMsg formMsg ->
            inLoginForm
                (LoginForm.update formMsg)


subscriptions : State -> Sub Msg
subscriptions _ =
    Sub.none


formView : State -> Bool -> Html LoginForm.Msg
formView { form } disabled =
    let
        { email, password, rememberMe } =
            form.fields
    in
    [ fieldset
        [ Html.Attributes.disabled disabled ]
        [ Bulma.Form.field []
            [ controlLabel [] [ text "Username" ]
            , Html.map LoginForm.EmailFieldMsg
                (controlInput controlInputModifiers
                    []
                    ([ placeholder "Email" ] ++ Form.inputAttrs email)
                    []
                )
            , div [] [ text (Debug.toString email) ]
            ]
        , Bulma.Form.field []
            [ controlLabel [] [ text "Password" ]
            , Html.map LoginForm.PasswordFieldMsg
                (controlPassword controlInputModifiers
                    []
                    ([ placeholder "Password" ] ++ Form.inputAttrs password)
                    []
                )
            , div [] [ text (Debug.toString password) ]
            ]
        , Bulma.Form.field []
            [ Html.map LoginForm.RememberMeFieldMsg
                (controlCheckBox False
                    []
                    (Form.checkboxAttrs rememberMe)
                    []
                    [ text "Remember me"
                    ]
                )
            ]
        , Bulma.Form.field []
            [ div [ class "control" ]
                [ button
                    [ type_ "submit"
                    , class "button is-primary"
                    ]
                    [ text
                        (if disabled then
                            "Please wait"

                         else
                            "Log in"
                        )
                    ]
                ]
            ]
          ]
        ]
            |> Html.form [ onSubmit (LoginForm.Submit) ]


view : State -> Html Msg
view state =
    let
        disabled =
            False
    in
    div
        [ class "columns is-centered is-mobile"
        , style "margin" "6em 0"
        ]
        [ div
            [ class "column is-narrow" ]
            [ card []
                [ cardContent []
                    [ h3 [ class "title is-3" ] [ text "Log in" ]
                    , message { messageModifiers | color = Info }
                        [ style "max-width" "360px" ]
                        [ messageBody []
                            [ text "This is a demo. Log in with username 'test' and password 'test'." ]
                        ]

                    --                    , resourceErrorMessage api.resource
                    , Html.map FormMsg (formView state disabled)
                    ]
                ]
            ]
        ]



--type alias State =
--    { api : Api.Model Session
--    , formModel : Form.Model Never Form.Login.Fields
--    }
--
--
--inApi : Wrap State (Api.Model Session) Msg (Api.Msg Session) t
--inApi =
--    wrapModel .api (\state api -> { state | api = api }) ApiMsg
--
--
--inForm : Wrap State (Form.Model Never Form.Login.Fields) Msg Form.Msg t
--inForm =
--    wrapModel .formModel (\state form -> { state | formModel = form }) FormMsg
--
--
--init : Update State Msg a
--init =
--    let
--        api =
--            Api.init
--                { endpoint = "/auth/login"
--                , method = Api.HttpPost
--                , decoder = Json.field "session" Session.decoder
--                }
--    in
--    save State
--        |> andMap api
--        |> andMap (Form.init [] Form.Login.validate)
--
--
--handleSubmit : Form.Login.Fields -> State -> Update State Msg a
--handleSubmit form =
--    let
--        json =
--            form |> Form.Login.toJson |> Http.jsonBody
--    in
--    inApi (Api.sendRequest "" (Just json))
--
--
--update : { onAuthResponse : Maybe Session -> a } -> Msg -> State -> Update State Msg a
--update { onAuthResponse } msg =
--    let
--        handleApiResponse maybeSession =
--            inForm (Form.reset [])
--                >> andApply (onAuthResponse maybeSession)
--    in
--    case msg of
--        ApiMsg apiMsg ->
--            inApi (Api.update { onSuccess = handleApiResponse << Just, onError = handleApiResponse Nothing |> always } apiMsg)
--
--        FormMsg formMsg ->
--            inForm (Form.update { onSubmit = handleSubmit } formMsg)
--
--
--subscriptions : State -> (Msg -> msg) -> Sub msg
--subscriptions state toMsg =
--    Sub.none
--
--
--view : State -> (Msg -> msg) -> Html msg
--view { api, formModel } toMsg =
--    let
--        { form, disabled } =
--            formModel
--    in
--    div [ class "columns is-centered is-mobile", style "margin" "6em 0" ]
--        [ div [ class "column is-narrow" ]
--            [ card []
--                [ cardContent []
--                    [ h3 [ class "title is-3" ] [ text "Log in" ]
--                    , message { messageModifiers | color = Info }
--                        [ style "max-width" "360px" ]
--                        [ messageBody []
--                            [ text "This is a demo. Log in with username 'test' and password 'test'." ]
--                        ]
--                    , resourceErrorMessage api.resource
--                    , Form.Login.view form disabled (toMsg << FormMsg)
--                    ]
--                ]
--            ]
--        ]
