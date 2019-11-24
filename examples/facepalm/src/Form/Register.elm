module Form.Register exposing (..)

import Bulma.Form exposing (controlCheckBox, controlEmail, controlHelp, controlInput, controlInputModifiers, controlLabel, controlPassword, controlPhone, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Form2 as Form exposing (Validate, checkbox, inputField)
import Burrito.Form2.Validate as Validate
import Burrito.Update exposing (Update)
import Form.Error exposing (Error(..))
import Helpers.Form exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode


type Fields
    = Name
    | Email
    | PhoneNumber
    | Password
    | PasswordConfirmation
    | AgreeWithTerms


type alias Msg =
    Form.Msg Fields


type alias Data =
    { name : String
    , email : String
    , phoneNumber : String
    , password : String
    , passwordConfirmation : String
    , agreeWithTerms : Bool
    }


toJson : Data -> Json.Value
toJson { name, email, phoneNumber, password, agreeWithTerms } =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "email", Encode.string email )
        , ( "phoneNumber", Encode.string phoneNumber )
        , ( "password", Encode.string password )
        , ( "agreeWithTerms", Encode.bool agreeWithTerms )
        ]


type alias Model =
    Form.Model Fields Error Data


type alias ModelUpdate a =
    Form.ModelUpdate Fields Error Data a


init : Update Model msg a
init =
    let
        fields =
            [ ( Name, inputField "" )
            , ( Email, inputField "" )
            , ( PhoneNumber, inputField "" )
            , ( Password, inputField "" )
            , ( PasswordConfirmation, inputField "" )
            , ( AgreeWithTerms, checkbox False )
            ]
    in
    Form.init validate fields


validate : Validate Fields Error Data
validate =
    let
        validateName =
            Validate.stringNotEmpty MustNotBeEmpty

        validateEmail =
            Validate.stringNotEmpty MustNotBeEmpty
                |> Validate.andThen (Validate.email MustBeValidEmail)

        validatePhoneNumber =
            Validate.stringNotEmpty MustNotBeEmpty

        validatePassword =
            Validate.stringNotEmpty MustNotBeEmpty
                |> Validate.andThen (Validate.atLeastLength 8 PasswordTooShort)

        validatePasswordConfirmation =
            Validate.stringNotEmpty MustNotBeEmpty
                |> Validate.andThen (Validate.mustMatchField Password MustMatchPassword)

        validateAgreeWithTerms =
            Validate.mustBeChecked MustAgreeWithTerms
    in
    Validate.record Data
        |> Validate.inputField Name validateName
        |> Validate.inputField Email validateEmail
        |> Validate.inputField PhoneNumber validatePhoneNumber
        |> Validate.inputField Password validatePassword
        |> Validate.inputField PasswordConfirmation validatePasswordConfirmation
        |> Validate.checkbox AgreeWithTerms validateAgreeWithTerms


view : Model -> Html Msg
view { fields, disabled, submitted } =
    Form.lookup6 fields
        Name
        Email
        PhoneNumber
        Password
        PasswordConfirmation
        AgreeWithTerms
        (\name email phoneNumber password passwordConfirmation agreeWithTerms ->
            [ fieldset
                [ Html.Attributes.disabled disabled ]
                [ Bulma.Form.field []
                    [ controlLabel [] [ text "Name" ]
                    , controlInput_ Name name "Name"
                    , controlErrorHelp name
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Email" ]
                    , controlInput_ Email email "Email"
                    , controlErrorHelp email
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Phone number" ]
                    , controlInput_ PhoneNumber phoneNumber "Phone number"
                    , controlErrorHelp phoneNumber
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Password" ]
                    , controlPassword_ Password password "Password"
                    , controlErrorHelp password
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Confirm password" ]
                    , controlPassword_ PasswordConfirmation passwordConfirmation "Confirm password"
                    , controlErrorHelp passwordConfirmation
                    ]
                , Bulma.Form.field []
                    [ controlCheckBox False
                        []
                        (Form.checkboxAttrs AgreeWithTerms agreeWithTerms)
                        []
                        [ text "I agree with terms and conditions" ]
                    , controlErrorHelp agreeWithTerms
                    ]
                , Bulma.Form.field []
                    [ div [ class "control" ]
                        [ button
                            [ class "button is-primary" ]
                            [ text
                                (if disabled then
                                    "Please wait"

                                 else
                                    "Send"
                                )
                            ]
                        ]
                    ]
                ]
            ]
                |> Html.form [ onSubmit Form.Submit ]
        )
