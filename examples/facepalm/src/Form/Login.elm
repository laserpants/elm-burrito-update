module Form.Login exposing (Fields, toJson, validate, view)

import Bulma.Form exposing (controlCheckBox, controlHelp, controlInput, controlInputModifiers, controlLabel, controlPassword, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Form exposing (Form)
import Form.Field exposing (FieldValue(..))
import Form.Validate as Validate exposing (Validation, andMap, field, succeed)
import Helpers.Form exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode


type alias Fields =
    { username : String
    , password : String
    , rememberMe : Bool
    }


validate : Validation Never Fields
validate =
    succeed Fields
        |> andMap (field "username" validateStringNonEmpty)
        |> andMap (field "password" validateStringNonEmpty)
        |> andMap (field "rememberMe" Validate.bool)


toJson : Fields -> Json.Value
toJson { username, password, rememberMe } =
    Encode.object
        [ ( "username", Encode.string username )
        , ( "password", Encode.string password )
        , ( "rememberMe", Encode.bool rememberMe )
        ]


view : Form Never Fields -> Bool -> (Form.Msg -> msg) -> Html msg
view form disabled toMsg =
    let
        info =
            fieldInfo (always "")

        usernameIcon =
            Just ( Small, [], i [ class "fa fa-user" ] [] )

        passwordIcon =
            Just ( Small, [], i [ class "fa fa-lock" ] [] )

        username =
            form |> Form.getFieldAsString "username" |> info { controlInputModifiers | iconLeft = usernameIcon }

        password =
            form |> Form.getFieldAsString "password" |> info { controlInputModifiers | iconLeft = passwordIcon }

        rememberMe =
            form |> Form.getFieldAsBool "rememberMe" |> info controlInputModifiers
    in
    [ fieldset [ Html.Attributes.disabled disabled ]
        [ Bulma.Form.field []
            [ controlLabel [] [ text "Username" ]
            , controlInput username.modifiers
                []
                [ placeholder "Username"
                , onFocus (Form.Focus username.path)
                , onBlur (Form.Blur username.path)
                , onInput (String >> Form.Input username.path Form.Text)
                , value (Maybe.withDefault "" username.value)
                ]
                []
            , controlHelp Danger [] [ Html.text username.errorMessage ]
            ]
        , Bulma.Form.field []
            [ controlLabel [] [ text "Password" ]
            , controlPassword password.modifiers
                []
                [ placeholder "Password"
                , onFocus (Form.Focus password.path)
                , onBlur (Form.Blur password.path)
                , onInput (String >> Form.Input password.path Form.Text)
                , value (Maybe.withDefault "" password.value)
                ]
                []
            , controlHelp Danger [] [ Html.text password.errorMessage ]
            ]
        , Bulma.Form.field []
            [ controlCheckBox False
                []
                []
                [ onFocus (Form.Focus rememberMe.path)
                , onBlur (Form.Blur rememberMe.path)
                , onCheck (Bool >> Form.Input rememberMe.path Form.Checkbox)
                , checked (Maybe.withDefault False rememberMe.value)
                ]
                [ text "Remember me" ]
            , controlHelp Danger [] [ Html.text rememberMe.errorMessage ]
            ]
        , Bulma.Form.field []
            [ div [ class "control" ]
                [ button [ type_ "submit", class "button is-primary" ]
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
        |> Html.form [ onSubmit Form.Submit ]
        |> Html.map toMsg
