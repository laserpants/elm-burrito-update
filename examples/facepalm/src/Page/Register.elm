module Page.Register exposing (Msg(..), State, StateUpdate, init, subscriptions, update, view)

import Bulma.Columns exposing (columnModifiers, columnsModifiers)
import Bulma.Components exposing (..)
import Bulma.Modifiers exposing (..)
import Burrito.Api as Api exposing (Resource(..))
import Burrito.Api.Json as JsonApi
import Burrito.Form as Form exposing (Variant(..))
import Burrito.Update exposing (..)
import Data.User as User exposing (User)
import Data.Websocket.UsernameAvailableResponse as UsernameAvailableResponse exposing (UsernameAvailableResponse)
import Form.Register as RegisterForm exposing (Fields(..), UsernameStatus(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Json.Encode as Encode
import Ports
import Set exposing (Set)


type WebSocketMessage
    = WebSocketUsernameAvailableResponse UsernameAvailableResponse


websocketMessageDecoder : Json.Decoder WebSocketMessage
websocketMessageDecoder =
    let
        payloadDecoder messageType =
            case messageType of
                "username_available_response" ->
                    Json.map WebSocketUsernameAvailableResponse UsernameAvailableResponse.decoder

                _ ->
                    Json.fail "Unrecognized message type"
    in
    Json.field "type" Json.string
        |> Json.andThen payloadDecoder


type Msg
    = ApiMsg (Api.Msg User)
    | FormMsg RegisterForm.Msg
    | WebsocketMsg String


type alias State =
    { api : Api.Model User
    , form : RegisterForm.Model
    , takenUsernames : Set String
    }


type alias StateUpdate a =
    State -> Update State Msg a


insertAsApiIn : State -> Api.Model User -> Update State msg a
insertAsApiIn state api =
    save { state | api = api }


insertAsFormIn : State -> RegisterForm.Model -> Update State msg a
insertAsFormIn state form =
    save { state | form = form }


setUsernameTaken : String -> StateUpdate a
setUsernameTaken username state =
    save { state | takenUsernames = Set.insert username state.takenUsernames }


setUsernameStatus : UsernameStatus -> StateUpdate a
setUsernameStatus status =
    inRegisterForm (Form.setState status)


inRegisterApi : Api.ModelUpdate User (StateUpdate a) -> StateUpdate a
inRegisterApi doUpdate state =
    state.api
        |> doUpdate
        |> andThen (insertAsApiIn state)
        |> mapCmd ApiMsg
        |> runCallbacks


inRegisterForm : RegisterForm.ModelUpdate (StateUpdate a) -> StateUpdate a
inRegisterForm doUpdate state =
    state.form
        |> doUpdate
        |> andThen (insertAsFormIn state)
        |> mapCmd FormMsg
        |> runCallbacks


init : Update State msg a
init =
    let
        api =
            JsonApi.init
                { endpoint = "/auth/register"
                , method = Api.HttpPost
                , decoder = Json.field "user" User.decoder
                , headers = []
                }
    in
    save State
        |> andMap api
        |> andMap RegisterForm.init
        |> andMap (save Set.empty)


handleSubmit : RegisterForm.Data -> StateUpdate a
handleSubmit data =
    let
        json =
            Http.jsonBody (RegisterForm.toJson data)
    in
    inRegisterApi (Api.sendRequest "" (Just json))


websocketIsAvailableQuery : String -> Json.Value
websocketIsAvailableQuery username =
    Encode.object
        [ ( "type", Encode.string "username_available_query" )
        , ( "username", Encode.string username )
        ]


usernameFieldValue : Form.FieldList RegisterForm.Fields err -> String
usernameFieldValue =
    Form.lookupField Username
        >> Maybe.map (Form.asString << .value)
        >> Maybe.withDefault ""


validateUsernameField : StateUpdate a
validateUsernameField =
    inRegisterForm
        (Form.validateField Username
            >> andThen (Form.setFieldDirty Username False)
        )


checkUsernameAvailability : Variant -> StateUpdate a
checkUsernameAvailability username =
    using
        (\{ takenUsernames } ->
            let
                name =
                    Form.asString username
            in
            if String.isEmpty name then
                setUsernameStatus Blank

            else if Set.member name takenUsernames then
                setUsernameStatus (IsAvailable False)
                    >> andThen validateUsernameField

            else
                let
                    encodedMsg =
                        Encode.encode 0 (websocketIsAvailableQuery name)
                in
                setUsernameStatus Unknown
                    >> andAddCmd (Ports.websocketOut encodedMsg)
        )


update : Msg -> { onRegistrationComplete : User -> a } -> StateUpdate a
update msg { onRegistrationComplete } =
    case msg of
        ApiMsg apiMsg ->
            inRegisterApi
                (Api.update apiMsg
                    { onSuccess = apply << onRegistrationComplete
                    , onError = always save
                    }
                )

        FormMsg registerFormMsg ->
            inRegisterForm
                (Form.update registerFormMsg
                    { onSubmit = handleSubmit
                    }
                )
                >> andThen
                    (case registerFormMsg of
                        Form.Input Username name ->
                            checkUsernameAvailability name

                        _ ->
                            save
                    )

        WebsocketMsg websocketMsg ->
            case Json.decodeString websocketMessageDecoder websocketMsg of
                Ok (WebSocketUsernameAvailableResponse { username, available }) ->
                    using
                        (\{ form } ->
                            setUsernameStatus (IsAvailable available)
                                |> when (username == usernameFieldValue form.fields)
                        )
                        >> andIf (not available) (setUsernameTaken username)
                        >> andThen validateUsernameField

                _ ->
                    save


subscriptions : State -> Sub Msg
subscriptions _ =
    Ports.websocketIn WebsocketMsg


view : State -> Html Msg
view { form } =
    Bulma.Columns.columns
        { columnsModifiers | centered = True }
        [ style "margin" "1.5em"
        ]
        [ Bulma.Columns.column
            columnModifiers
            [ class "is-half" ]
            [ card []
                [ cardContent []
                    [ h3 [ class "title is-3" ] [ text "Register" ]
                    , Html.map FormMsg (RegisterForm.view form)
                    ]
                ]
            ]
        ]
