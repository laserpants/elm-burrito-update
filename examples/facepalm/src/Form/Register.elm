module Form.Register exposing (Fields, UsernameStatus(..), toJson, validate, validateChecked, validatePassword, validatePasswordConfirmation, view)

import Bulma.Form exposing (controlCheckBox, controlEmail, controlHelp, controlInput, controlInputModifiers, controlLabel, controlPassword, controlPhone, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Form exposing (Form)
import Form.Error exposing (Error, ErrorValue(..))
import Form.Field exposing (Field, FieldValue(..))
import Form.Register.Custom as Custom
import Form.Validate as Validate exposing (Validation, andMap, andThen, customError, fail, field, minLength, oneOf, succeed)
import Helpers.Form exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode


type alias Fields =
    { name : String
    , email : String
    , username : String
    , phoneNumber : String
    , password : String
    , passwordConfirmation : String
    , agreeWithTerms : Bool
    }


type UsernameStatus
    = Blank
    | IsAvailable Bool
    | Unknown


validatePassword : Field -> Result (Error e) String
validatePassword =
    validateStringNonEmpty
        |> andThen (minLength 8)


validatePasswordConfirmation : Field -> Result (Error Custom.Error) String
validatePasswordConfirmation =
    let
        match password confirmation =
            if password == confirmation then
                succeed confirmation

            else
                fail (customError Custom.PasswordConfirmationMismatch)
    in
    [ Validate.string, Validate.emptyString ]
        |> oneOf
        |> field "password"
        |> andThen
            (\value ->
                validateStringNonEmpty
                    |> andThen (match value)
                    |> field "passwordConfirmation"
            )


validateChecked : Field -> Result (Error Custom.Error) Bool
validateChecked =
    Validate.bool
        |> andThen
            (\checked ->
                if checked then
                    succeed True

                else
                    fail (customError Custom.MustAgreeWithTerms)
            )


validate : Validation Custom.Error Fields
validate =
    succeed Fields
        |> andMap (field "name" validateStringNonEmpty)
        |> andMap (field "email" validateEmail)
        |> andMap (field "username" validateStringNonEmpty)
        |> andMap (field "phoneNumber" validateStringNonEmpty)
        |> andMap (field "password" validatePassword)
        |> andMap validatePasswordConfirmation
        |> andMap (field "agreeWithTerms" validateChecked)


toJson : Fields -> Json.Value
toJson { name, email, username, phoneNumber, password, agreeWithTerms } =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "email", Encode.string email )
        , ( "username", Encode.string username )
        , ( "phoneNumber", Encode.string phoneNumber )
        , ( "password", Encode.string password )
        , ( "agreeWithTerms", Encode.bool agreeWithTerms )
        ]


view : Form Custom.Error Fields -> Bool -> UsernameStatus -> (Form.Msg -> msg) -> Html msg
view form disabled usernameStatus toMsg =
    let
        info =
            fieldInfo Custom.errorToString controlInputModifiers

        name =
            form |> Form.getFieldAsString "name" |> info

        email =
            form |> Form.getFieldAsString "email" |> info

        phoneNumber =
            form |> Form.getFieldAsString "phoneNumber" |> info

        password =
            form |> Form.getFieldAsString "password" |> info

        passwordConfirmation =
            form |> Form.getFieldAsString "passwordConfirmation" |> info

        agreeWithTerms =
            form |> Form.getFieldAsBool "agreeWithTerms" |> info

        availableIcon =
            ( Small, [], i [ class "fa fa-check has-text-success" ] [] )

        unavailableIcon =
            ( Small, [], i [ class "fa fa-times has-text-danger" ] [] )

        username =
            let
                info_ =
                    form |> Form.getFieldAsString "username" |> info
            in
            case usernameStatus of
                IsAvailable True ->
                    { info_ | modifiers = { controlInputModifiers | color = Success, iconRight = Just availableIcon } }

                IsAvailable False ->
                    { info_
                        | modifiers = { controlInputModifiers | color = Danger, iconRight = Just unavailableIcon }
                        , errorMessage = "This username is not available"
                    }

                _ ->
                    info_
    in
    [ fieldset [ Html.Attributes.disabled disabled ]
        [ Bulma.Form.field []
            [ controlLabel [] [ text "Name" ]
            , controlInput name.modifiers
                []
                [ placeholder "Name"
                , onFocus (Form.Focus name.path)
                , onBlur (Form.Blur name.path)
                , onInput (String >> Form.Input name.path Form.Text)
                , value (Maybe.withDefault "" name.value)
                ]
                []
            , controlHelp Danger [] [ Html.text name.errorMessage ]
            ]
        , Bulma.Form.field []
            [ controlLabel [] [ text "Email" ]
            , controlEmail email.modifiers
                []
                [ placeholder "Email"
                , onFocus (Form.Focus email.path)
                , onBlur (Form.Blur email.path)
                , onInput (String >> Form.Input email.path Form.Text)
                , value (Maybe.withDefault "" email.value)
                ]
                []
            , controlHelp Danger [] [ Html.text email.errorMessage ]
            ]
        , Bulma.Form.field []
            [ controlLabel [] [ text "Username" ]
            , controlInput username.modifiers
                (if Unknown == usernameStatus then
                    [ class "is-loading" ]

                 else
                    []
                )
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
            [ controlLabel [] [ text "Phone number" ]
            , controlPhone phoneNumber.modifiers
                []
                [ placeholder "Phone number"
                , onFocus (Form.Focus phoneNumber.path)
                , onBlur (Form.Blur phoneNumber.path)
                , onInput (String >> Form.Input phoneNumber.path Form.Text)
                , value (Maybe.withDefault "" phoneNumber.value)
                ]
                []
            , controlHelp Danger [] [ Html.text phoneNumber.errorMessage ]
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
            [ controlLabel [] [ text "Password confirmation" ]
            , controlPassword passwordConfirmation.modifiers
                []
                [ placeholder "Password confirmation"
                , onFocus (Form.Focus passwordConfirmation.path)
                , onBlur (Form.Blur passwordConfirmation.path)
                , onInput (String >> Form.Input passwordConfirmation.path Form.Text)
                , value (Maybe.withDefault "" passwordConfirmation.value)
                ]
                []
            , controlHelp Danger [] [ Html.text passwordConfirmation.errorMessage ]
            ]
        , Bulma.Form.field []
            [ controlCheckBox False
                []
                []
                [ onFocus (Form.Focus agreeWithTerms.path)
                , onBlur (Form.Blur agreeWithTerms.path)
                , onCheck (Bool >> Form.Input agreeWithTerms.path Form.Checkbox)
                , checked (Maybe.withDefault False agreeWithTerms.value)
                ]
                [ text "I agree with terms and conditions" ]
            , controlHelp Danger [] [ Html.text agreeWithTerms.errorMessage ]
            ]
        , Bulma.Form.field []
            [ div [ class "control" ]
                [ button [ type_ "submit", class "button is-primary" ]
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
        |> Html.map toMsg
