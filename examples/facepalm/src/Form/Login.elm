module Form.Login exposing (..)

import Bulma.Components exposing (..)
import Bulma.Form exposing (controlCheckBox, controlHelp, controlInput, controlInputModifiers, controlLabel, controlPassword, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Form as Form exposing (Validate, checkbox, inputField)
import Burrito.Form.Validate as Validate
import Burrito.Update exposing (Update)
import Form.Error exposing (Error(..))
import Helpers.Form exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode


type Fields
    = Email
    | Password
    | RememberMe


type alias Msg =
    Form.Msg Fields


type alias Data =
    { email : String
    , password : String
    , rememberMe : Bool
    }


toJson : Data -> Json.Value
toJson { email, password, rememberMe } =
    Encode.object
        [ ( "email", Encode.string email )
        , ( "password", Encode.string password )
        , ( "rememberMe", Encode.bool rememberMe )
        ]


type alias Model =
    Form.Model Fields Error Data


type alias ModelUpdate a =
    Form.ModelUpdate Fields Error Data a


init : Update Model msg a
init =
    let
        fields =
            [ ( Email, inputField "" )
            , ( Password, inputField "" )
            , ( RememberMe, checkbox False )
            ]
    in
    Form.init validate fields


validate : Validate Fields Error Data
validate =
    let
        validateEmail =
            Validate.stringNotEmpty MustNotBeEmpty
                |> Validate.andThen (Validate.email MustBeValidEmail)

        validatePassword =
            Validate.stringNotEmpty MustNotBeEmpty
    in
    Validate.record Data
        |> Validate.inputField Email validateEmail
        |> Validate.inputField Password validatePassword
        |> Validate.checkbox RememberMe (always << Ok)


view : Model -> Html Msg
view { fields, disabled } =
    Form.lookup3 fields
        Email
        Password
        RememberMe
        (\email password rememberMe ->
            [ fieldset
                [ Html.Attributes.disabled disabled ]
                [ Bulma.Form.field []
                    [ controlLabel [] [ text "Email address" ]
                    , controlInput_ Email email "Email"
                    , controlErrorHelp email
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Password" ]
                    , controlPassword_ Password password "Password"
                    , controlErrorHelp password
                    ]
                , Bulma.Form.field []
                    [ controlCheckBox False
                        []
                        (Form.checkboxAttrs RememberMe rememberMe)
                        []
                        [ text "Remember me" ]
                    , controlErrorHelp rememberMe
                    ]
                , Bulma.Form.field []
                    [ div [ class "control" ]
                        [ button
                            [ class "button is-primary" ]
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
        )
