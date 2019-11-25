module Page.Register exposing (..)

--Msg(..), State, init, subscriptions, update, view)

import Bulma.Columns exposing (columnModifiers, columnsModifiers, narrowColumnModifiers)
import Bulma.Components exposing (..)
import Bulma.Form exposing (controlCheckBox, controlEmail, controlHelp, controlInput, controlInputModifiers, controlLabel, controlPassword, controlPhone, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Api as Api exposing (Resource(..))
import Burrito.Api.Json as JsonApi
import Burrito.Callback exposing (..)
import Burrito.Form as Form exposing (Variant(..))
import Burrito.Update exposing (..)
import Data.User as User exposing (User)
import Data.Websocket.UsernameAvailableResponse as UsernameAvailableResponse exposing (UsernameAvailableResponse)
import Form.Register as RegisterForm exposing (Fields(..), UsernameStatus(..))
import Helpers exposing (..)
import Helpers.Api exposing (requestErrorMessage)
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


checkUsernameAvailability : StateUpdate a
checkUsernameAvailability =
    using
        (\{ form, takenUsernames } ->
            let
                queryName name =
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
            in
            queryName (usernameFieldValue form.fields)
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
                        Form.Input Username _ ->
                            checkUsernameAvailability

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



--type alias UsernameIsAvailableResponse =
--    { username : String
--    , available : Bool
--    }
--
--
--webSocketUsernameIsAvailableResponseDecoder : Json.Decoder UsernameIsAvailableResponse
--webSocketUsernameIsAvailableResponseDecoder =
--    Json.map2 UsernameIsAvailableResponse
--        (Json.field "username" Json.string)
--        (Json.field "available" Json.bool)
--
--
--type WebSocketMessage
--    = WebSocketUsernameIsAvailableResponse UsernameIsAvailableResponse
--
--
--websocketMessageDecoder : Json.Decoder WebSocketMessage
--websocketMessageDecoder =
--    let
--        payloadDecoder type_ =
--            case type_ of
--                "username_available_response" ->
--                    Json.map WebSocketUsernameIsAvailableResponse webSocketUsernameIsAvailableResponseDecoder
--
--                _ ->
--                    Json.fail "Unrecognized message type"
--    in
--    Json.field "type" Json.string |> Json.andThen payloadDecoder
--
--
--type Msg
--    = ApiMsg (Api.Msg User)
--    | FormMsg Form.Msg
--    | WebsocketMsg String
--
--
--type alias State =
--    { api : Api.Model User
--    , formModel : Form.Model Form.Register.Custom.Error Form.Register.Fields
--    , usernames : Dict String Bool
--    , usernameStatus : UsernameStatus
--    }
--
--
--saveUsernameStatus : String -> Bool -> State -> Update State msg a
--saveUsernameStatus username available state =
--    save { state | usernames = Dict.insert username available state.usernames }
--
--
--inApi : Wrap State (Api.Model User) Msg (Api.Msg User) t
--inApi =
--    wrapModel .api (\state api -> { state | api = api }) ApiMsg
--
--
--inForm : Wrap State (Form.Model Form.Register.Custom.Error Form.Register.Fields) Msg Form.Msg t
--inForm =
--    wrapModel .formModel (\state form -> { state | formModel = form }) FormMsg
--
--
--setUsernameStatus : UsernameStatus -> State -> Update State Msg a
--setUsernameStatus status state =
--    save { state | usernameStatus = status }
--
--
--init : Update State Msg a
--init =
--    let
--        api =
--            Api.init
--                { endpoint = "/auth/register"
--                , method = Api.HttpPost
--                , decoder = Json.field "user" User.decoder
--                }
--    in
--    save State
--        |> andMap api
--        |> andMap (Form.init [] Form.Register.validate)
--        |> andMap (save Dict.empty)
--        |> andMap (save Blank)
--
--
--websocketIsAvailableQuery : String -> Json.Value
--websocketIsAvailableQuery username =
--    Encode.object
--        [ ( "type", Encode.string "username_available_query" )
--        , ( "username", Encode.string username )
--        ]
--
--
--checkIfIsAvailable : String -> State -> Update State Msg a
--checkIfIsAvailable username ({ usernames } as state) =
--    if String.isEmpty username then
--        state
--            |> setUsernameStatus Blank
--
--    else
--        case Dict.get username usernames of
--            Just isAvailable ->
--                state
--                    |> setUsernameStatus (IsAvailable isAvailable)
--
--            Nothing ->
--                state
--                    |> setUsernameStatus Unknown
--                    |> andAddCmd (Ports.websocketOut (Encode.encode 0 (websocketIsAvailableQuery username)))
--
--
--usernameFieldSpy : F.Msg -> State -> Update State Msg a
--usernameFieldSpy formMsg =
--    case formMsg of
--        F.Input "username" F.Text (String username) ->
--            checkIfIsAvailable username
--
--        _ ->
--            save
--
--
--handleSubmit : Form.Register.Fields -> State -> Update State Msg a
--handleSubmit form =
--    let
--        json =
--            form |> Form.Register.toJson |> Http.jsonBody
--    in
--    inApi (Api.sendRequest "" (Just json))
--
--
--update : Msg -> State -> Update State Msg a
--update msg =
--    case msg of
--        ApiMsg apiMsg ->
--            inApi (Api.update { onSuccess = always save, onError = always save } apiMsg)
--
--        FormMsg formMsg ->
--            inForm (Form.update { onSubmit = handleSubmit } formMsg)
--                >> andThen (usernameFieldSpy formMsg)
--
--        WebsocketMsg websocketMsg ->
--            case Json.decodeString websocketMessageDecoder websocketMsg of
--                Ok (WebSocketUsernameIsAvailableResponse { username, available }) ->
--                    with .formModel
--                        (\model ->
--                            let
--                                usernameField =
--                                    F.getFieldAsString "username" model.form
--                            in
--                            saveUsernameStatus username available
--                                >> andThen (checkIfIsAvailable <| Maybe.withDefault "" usernameField.value)
--                        )
--
--                _ ->
--                    save
--
--
--subscriptions : State -> (Msg -> msg) -> Sub msg
--subscriptions state toMsg =
--    Ports.websocketIn (toMsg << WebsocketMsg)
--
--
--view : State -> (Msg -> msg) -> Html msg
--view { api, formModel, usernameStatus } toMsg =
--    let
--        { form, disabled } =
--            formModel
--
--        formView =
--            case api.resource of
--                Available response ->
--                    content Standard
--                        []
--                        [ p [] [ b [] [ text "Thanks for registering!" ] ]
--                        , p []
--                            [ text "Now head over to the "
--                            , a [ href "/login" ] [ text "log in" ]
--                            , text " page and see how it goes."
--                            ]
--                        ]
--
--                Api.Error error ->
--                    requestErrorMessage api.resource
--
--                _ ->
--                    Form.Register.view form disabled usernameStatus (toMsg << FormMsg)
--    in
--    div [ class "columns is-centered", style "margin" "1.5em" ]
--        [ div [ class "column is-half" ]
--            [ card []
--                [ cardContent []
--                    [ h3 [ class "title is-3" ] [ text "Register" ]
--                    , formView
--                    ]
--                ]
--            ]
--        ]
