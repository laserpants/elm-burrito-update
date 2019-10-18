module Page.Register exposing (Msg(..), State, init, subscriptions, update, view)

import Bulma.Components exposing (..)
import Bulma.Elements exposing (..)
import Bulma.Form exposing (controlInputModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Burrito.Update.Api as Api exposing (Resource(..))
import Burrito.Update.Form as Form
import Data.User as User exposing (User)
import Dict exposing (Dict)
import Form as F
import Form.Field exposing (FieldValue(..))
import Form.Register exposing (UsernameStatus(..))
import Form.Register.Custom
import Helpers exposing (..)
import Helpers.Api exposing (resourceErrorMessage)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Json.Encode as Encode
import Ports


type alias UsernameIsAvailableResponse =
    { username : String
    , available : Bool
    }


webSocketUsernameIsAvailableResponseDecoder : Json.Decoder UsernameIsAvailableResponse
webSocketUsernameIsAvailableResponseDecoder =
    Json.map2 UsernameIsAvailableResponse
        (Json.field "username" Json.string)
        (Json.field "available" Json.bool)


type WebSocketMessage
    = WebSocketUsernameIsAvailableResponse UsernameIsAvailableResponse


websocketMessageDecoder : Json.Decoder WebSocketMessage
websocketMessageDecoder =
    let
        payloadDecoder type_ =
            case type_ of
                "username_available_response" ->
                    Json.map WebSocketUsernameIsAvailableResponse webSocketUsernameIsAvailableResponseDecoder

                _ ->
                    Json.fail "Unrecognized message type"
    in
    Json.field "type" Json.string |> Json.andThen payloadDecoder


type Msg
    = ApiMsg (Api.Msg User)
    | FormMsg Form.Msg
    | WebsocketMsg String


type alias State =
    { api : Api.Model User
    , formModel : Form.Model Form.Register.Custom.Error Form.Register.Fields
    , usernames : Dict String Bool
    , usernameStatus : UsernameStatus
    }


saveUsernameStatus : String -> Bool -> State -> Update State msg a
saveUsernameStatus username available state =
    save { state | usernames = Dict.insert username available state.usernames }


inApi : Wrap State (Api.Model User) Msg (Api.Msg User) t
inApi =
    wrapModel .api (\state api -> { state | api = api }) ApiMsg


inForm : Wrap State (Form.Model Form.Register.Custom.Error Form.Register.Fields) Msg Form.Msg t
inForm =
    wrapModel .formModel (\state form -> { state | formModel = form }) FormMsg


setUsernameStatus : UsernameStatus -> State -> Update State Msg a
setUsernameStatus status state =
    save { state | usernameStatus = status }


init : Update State Msg a
init =
    let
        api =
            Api.init
                { endpoint = "/auth/register"
                , method = Api.HttpPost
                , decoder = Json.field "user" User.decoder
                }
    in
    save State
        |> andMap api
        |> andMap (Form.init [] Form.Register.validate)
        |> andMap (save Dict.empty)
        |> andMap (save Blank)


websocketIsAvailableQuery : String -> Json.Value
websocketIsAvailableQuery username =
    Encode.object
        [ ( "type", Encode.string "username_available_query" )
        , ( "username", Encode.string username )
        ]


checkIfIsAvailable : String -> State -> Update State Msg a
checkIfIsAvailable username ({ usernames } as state) =
    if String.isEmpty username then
        state
            |> setUsernameStatus Blank

    else
        case Dict.get username usernames of
            Just isAvailable ->
                state
                    |> setUsernameStatus (IsAvailable isAvailable)

            Nothing ->
                state
                    |> setUsernameStatus Unknown
                    |> andAddCmd (Ports.websocketOut (Encode.encode 0 (websocketIsAvailableQuery username)))


usernameFieldSpy : F.Msg -> State -> Update State Msg a
usernameFieldSpy formMsg =
    case formMsg of
        F.Input "username" F.Text (String username) ->
            checkIfIsAvailable username

        _ ->
            save


handleSubmit : Form.Register.Fields -> State -> Update State Msg a
handleSubmit form =
    let
        json =
            form |> Form.Register.toJson |> Http.jsonBody
    in
    inApi (Api.sendRequest "" (Just json))


update : Msg -> State -> Update State Msg a
update msg =
    case msg of
        ApiMsg apiMsg ->
            inApi (Api.update { onSuccess = always save, onError = always save } apiMsg)

        FormMsg formMsg ->
            inForm (Form.update { onSubmit = handleSubmit } formMsg)
                >> andThen (usernameFieldSpy formMsg)

        WebsocketMsg websocketMsg ->
            case Json.decodeString websocketMessageDecoder websocketMsg of
                Ok (WebSocketUsernameIsAvailableResponse { username, available }) ->
                    with .formModel
                        (\model ->
                            let
                                usernameField =
                                    F.getFieldAsString "username" model.form
                            in
                            saveUsernameStatus username available
                                >> andThen (checkIfIsAvailable <| Maybe.withDefault "" usernameField.value)
                        )

                _ ->
                    save


subscriptions : State -> (Msg -> msg) -> Sub msg
subscriptions state toMsg =
    Ports.websocketIn (toMsg << WebsocketMsg)


view : State -> (Msg -> msg) -> Html msg
view { api, formModel, usernameStatus } toMsg =
    let
        { form, disabled } =
            formModel

        formView =
            case api.resource of
                Available response ->
                    content Standard
                        []
                        [ p [] [ b [] [ text "Thanks for registering!" ] ]
                        , p []
                            [ text "Now head over to the "
                            , a [ href "/login" ] [ text "log in" ]
                            , text " page and see how it goes."
                            ]
                        ]

                Api.Error error ->
                    resourceErrorMessage api.resource

                _ ->
                    Form.Register.view form disabled usernameStatus (toMsg << FormMsg)
    in
    div [ class "columns is-centered", style "margin" "1.5em" ]
        [ div [ class "column is-half" ]
            [ card []
                [ cardContent []
                    [ h3 [ class "title is-3" ] [ text "Register" ]
                    , formView
                    ]
                ]
            ]
        ]
