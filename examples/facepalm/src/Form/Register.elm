module Form.Register exposing (Data, Fields(..), Model, ModelUpdate, Msg, UsernameStatus(..), init, toJson, validate, view)

import Bulma.Form exposing (controlCheckBox, controlHelp, controlInput, controlLabel)
import Bulma.Modifiers exposing (..)
import Burrito.Form as Form exposing (Validate, checkbox, inputField)
import Burrito.Form.Validate as Validate
import Burrito.Update exposing (Update)
import Form.Error exposing (Error(..))
import Helpers exposing (empty)
import Helpers.Form
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode


type Fields
    = Name
    | Email
    | Username
    | PhoneNumber
    | Password
    | PasswordConfirmation
    | AgreeWithTerms


type alias Msg =
    Form.Msg Fields


type UsernameStatus
    = Blank
    | IsAvailable Bool
    | Unknown


type alias Data =
    { name : String
    , email : String
    , username : String
    , phoneNumber : String
    , password : String
    , passwordConfirmation : String
    , agreeWithTerms : Bool
    }


toJson : Data -> Json.Value
toJson { name, email, username, phoneNumber, password, agreeWithTerms } =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "email", Encode.string email )
        , ( "username", Encode.string username )
        , ( "phoneNumber", Encode.string phoneNumber )
        , ( "password", Encode.string password )
        , ( "agreeWithTerms", Encode.bool agreeWithTerms )
        ]


type alias Model =
    Form.ModelExtra Fields Error Data UsernameStatus


type alias ModelUpdate a =
    Form.ModelExtraUpdate Fields Error Data UsernameStatus a


init : Update Model msg a
init =
    let
        fields =
            [ ( Name, inputField "" )
            , ( Email, inputField "" )
            , ( Username, inputField "" )
            , ( PhoneNumber, inputField "" )
            , ( Password, inputField "" )
            , ( PasswordConfirmation, inputField "" )
            , ( AgreeWithTerms, checkbox False )
            ]
    in
    Form.initExtra validate fields Blank


validate : UsernameStatus -> Validate Fields Error Data
validate usernameStatus =
    let
        validateEmail =
            Validate.stringNotEmpty MustNotBeEmpty
                |> Validate.andThen (Validate.email MustBeValidEmail)

        validateUsername =
            Validate.stringNotEmpty MustNotBeEmpty
                |> Validate.andThen (Validate.alphanumeric NonAlphanumChar)
                |> Validate.andThen
                    (always
                        << (case usernameStatus of
                                IsAvailable False ->
                                    always (Err UsernameTaken)

                                _ ->
                                    Ok
                           )
                    )

        validatePassword =
            Validate.stringNotEmpty MustNotBeEmpty
                |> Validate.andThen (Validate.atLeastLength 8 PasswordTooShort)

        validatePasswordConfirmation =
            Validate.stringNotEmpty MustNotBeEmpty
                |> Validate.andThen (Validate.mustMatchField Password MustMatchPassword)
    in
    Validate.record Data
        |> Validate.inputField Name (Validate.stringNotEmpty MustNotBeEmpty)
        |> Validate.inputField Email validateEmail
        |> Validate.inputField Username validateUsername
        |> Validate.inputField PhoneNumber (Validate.stringNotEmpty MustNotBeEmpty)
        |> Validate.inputField Password validatePassword
        |> Validate.inputField PasswordConfirmation validatePasswordConfirmation
        |> Validate.checkbox AgreeWithTerms (Validate.mustBeChecked MustAgreeWithTerms)


view : Model -> Html Msg
view { fields, disabled, state } =
    Form.lookup7 fields
        Name
        Email
        Username
        PhoneNumber
        Password
        PasswordConfirmation
        AgreeWithTerms
        (\name email username phoneNumber password passwordConfirmation agreeWithTerms ->
            [ fieldset
                [ Html.Attributes.disabled disabled ]
                [ Bulma.Form.field []
                    [ controlLabel [] [ text "Name" ]
                    , Helpers.Form.controlInput Name name "Name"
                    , Helpers.Form.controlErrorHelp name
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Email" ]
                    , Helpers.Form.controlInput Email email "Email"
                    , Helpers.Form.controlErrorHelp email
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Username" ]
                    , Helpers.Form.control
                        (if Unknown == state then
                            [ class "is-loading" ]

                         else
                            []
                        )
                        (if IsAvailable True == state then
                            [ class "is-success" ]

                         else
                            []
                        )
                        []
                        controlInput
                        Username
                        username
                        "Username"
                    , Helpers.Form.controlErrorHelp username
                    , if Form.Valid == username.status && IsAvailable True == state then
                        controlHelp Success [] [ text "This username is available" ]

                      else
                        empty
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Phone number" ]
                    , Helpers.Form.controlInput PhoneNumber phoneNumber "Phone number"
                    , Helpers.Form.controlErrorHelp phoneNumber
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Password" ]
                    , Helpers.Form.controlPassword Password password "Password"
                    , Helpers.Form.controlErrorHelp password
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Confirm password" ]
                    , Helpers.Form.controlPassword PasswordConfirmation passwordConfirmation "Confirm password"
                    , Helpers.Form.controlErrorHelp passwordConfirmation
                    ]
                , Bulma.Form.field []
                    [ controlCheckBox False
                        []
                        (Form.checkboxAttrs AgreeWithTerms agreeWithTerms)
                        []
                        [ text "I agree with terms and conditions" ]
                    , Helpers.Form.controlErrorHelp agreeWithTerms
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
