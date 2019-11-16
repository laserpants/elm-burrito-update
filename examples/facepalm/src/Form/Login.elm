module Form.Login exposing (..)

import Burrito.Callback exposing (..)
import Burrito.Form2 as Form exposing (..)
import Burrito.Form2.Validate as Validate
import Burrito.Update exposing (..)



--type Status val err
--    = Pristine
--    | Error err
--    | Valid val
--
--
--type alias Input val err =
--    { val : String
--    , dirty : Bool
--    , status : Status val err
--    }
--
--
--type alias Checkbox =
--    { checked : Bool
--    , dirty : Bool
--    , status : Status Bool ()
--    }
--
--type alias Model fields =
--    { fields : fields
--    , initial : fields
--    , disabled : Bool
--    , submitted : Bool
--    }
--
--
--setDisabled : Bool -> Model fields -> Update (Model fields) msg a
--setDisabled disabled model =
--    save { model | disabled = disabled }
--
--
--setSubmitted : Bool -> Model fields -> Update (Model fields) msg a
--setSubmitted submitted model =
--    save { model | submitted = submitted }
--
--
--reset : Model fields -> Update (Model fields) msg a
--reset ({ initial } as model) =
--    save
--        { model
--            | fields = initial
--            , disabled = False
--            , submitted = False
--        }
--


type Msg
    = EmailFieldMsg Form.Msg
    | PasswordFieldMsg Form.Msg
    | RememberMeFieldMsg Form.Msg
    | Submit


type Error
    = MustNotBeEmpty


type alias EmailField =
    Field String Error


type alias PasswordField =
    Field String Error


type alias RememberMeField =
    Field Bool Never


type alias Fields =
    { email : EmailField
    , password : PasswordField
    , rememberMe : RememberMeField
    }


mapEmailField : (EmailField -> EmailField) -> Fields -> Fields
mapEmailField fun fields =
    { fields | email = fun fields.email }


mapPasswordField : (PasswordField -> PasswordField) -> Fields -> Fields
mapPasswordField fun fields =
    { fields | password = fun fields.password }


mapRememberMeField : (RememberMeField -> RememberMeField) -> Fields -> Fields
mapRememberMeField fun fields =
    { fields | rememberMe = fun fields.rememberMe }


validate : Fields -> Fields
validate fields =
    let
        { email, password } =
            fields
    in
    { fields
        | email = Form.validate (Validate.stringNotEmpty MustNotBeEmpty) email
        , password = Form.validate (Validate.stringNotEmpty MustNotBeEmpty) password
    }


init : Update (Form.Model Fields) Msg a
init =
    Form.init validate
        { email = initialString
        , password = initialString
        , rememberMe = initialBool
        }


update :
    Msg
    -> Form.Model Fields
    -> Update (Form.Model Fields) Msg a
update msg =
    case msg of
        EmailFieldMsg formMsg ->
            Form.update mapEmailField EmailFieldMsg formMsg

        PasswordFieldMsg formMsg ->
            Form.update mapPasswordField PasswordFieldMsg formMsg

        RememberMeFieldMsg formMsg ->
            Form.update mapRememberMeField RememberMeFieldMsg formMsg

        Submit ->
            Form.submit



--import Bulma.Form exposing (controlCheckBox, controlHelp, controlInput, controlInputModifiers, controlLabel, controlPassword, controlTextArea, controlTextAreaModifiers)
--import Bulma.Modifiers exposing (..)
--import Form exposing (Form)
--import Form.Field exposing (FieldValue(..))
--import Form.Validate as Validate exposing (Validation, andMap, field, succeed)
--import Helpers.Form exposing (..)
--import Html exposing (..)
--import Html.Attributes exposing (..)
--import Html.Events exposing (..)
--import Json.Decode as Json
--import Json.Encode as Encode
--
--
--type alias Fields =
--    { username : String
--    , password : String
--    , rememberMe : Bool
--    }
--
--
--validate : Validation Never Fields
--validate =
--    succeed Fields
--        |> andMap (field "username" validateStringNonEmpty)
--        |> andMap (field "password" validateStringNonEmpty)
--        |> andMap (field "rememberMe" Validate.bool)
--
--
--toJson : Fields -> Json.Value
--toJson { username, password, rememberMe } =
--    Encode.object
--        [ ( "username", Encode.string username )
--        , ( "password", Encode.string password )
--        , ( "rememberMe", Encode.bool rememberMe )
--        ]
--
--
--view : Form Never Fields -> Bool -> (Form.Msg -> msg) -> Html msg
--view form disabled toMsg =
--    let
--        info =
--            fieldInfo (always "")
--
--        usernameIcon =
--            Just ( Small, [], i [ class "fa fa-user" ] [] )
--
--        passwordIcon =
--            Just ( Small, [], i [ class "fa fa-lock" ] [] )
--
--        username =
--            form |> Form.getFieldAsString "username" |> info { controlInputModifiers | iconLeft = usernameIcon }
--
--        password =
--            form |> Form.getFieldAsString "password" |> info { controlInputModifiers | iconLeft = passwordIcon }
--
--        rememberMe =
--            form |> Form.getFieldAsBool "rememberMe" |> info controlInputModifiers
--    in
--    [ fieldset [ Html.Attributes.disabled disabled ]
--        [ Bulma.Form.field []
--            [ controlLabel [] [ text "Username" ]
--            , controlInput username.modifiers
--                []
--                [ placeholder "Username"
--                , onFocus (Form.Focus username.path)
--                , onBlur (Form.Blur username.path)
--                , onInput (String >> Form.Input username.path Form.Text)
--                , value (Maybe.withDefault "" username.value)
--                ]
--                []
--            , controlHelp Danger [] [ Html.text username.errorMessage ]
--            ]
--        , Bulma.Form.field []
--            [ controlLabel [] [ text "Password" ]
--            , controlPassword password.modifiers
--                []
--                [ placeholder "Password"
--                , onFocus (Form.Focus password.path)
--                , onBlur (Form.Blur password.path)
--                , onInput (String >> Form.Input password.path Form.Text)
--                , value (Maybe.withDefault "" password.value)
--                ]
--                []
--            , controlHelp Danger [] [ Html.text password.errorMessage ]
--            ]
--        , Bulma.Form.field []
--            [ controlCheckBox False
--                []
--                []
--                [ onFocus (Form.Focus rememberMe.path)
--                , onBlur (Form.Blur rememberMe.path)
--                , onCheck (Bool >> Form.Input rememberMe.path Form.Checkbox)
--                , checked (Maybe.withDefault False rememberMe.value)
--                ]
--                [ text "Remember me" ]
--            , controlHelp Danger [] [ Html.text rememberMe.errorMessage ]
--            ]
--        , Bulma.Form.field []
--            [ div [ class "control" ]
--                [ button [ type_ "submit", class "button is-primary" ]
--                    [ text
--                        (if disabled then
--                            "Please wait"
--
--                         else
--                            "Log in"
--                        )
--                    ]
--                ]
--            ]
--        ]
--    ]
--        |> Html.form [ onSubmit Form.Submit ]
--        |> Html.map toMsg
