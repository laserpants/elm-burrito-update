module Helpers.Form exposing (..)

import Bulma.Components exposing (..)
import Bulma.Form exposing (controlCheckBox, controlHelp, controlInput, controlInputModifiers, controlLabel, controlPassword, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Form as Form
import Form.Error as Error
import Html exposing (text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra as Maybe


errorHelp =
    controlHelp Danger [] << List.singleton << text << Error.toString


controlErrorHelp =
    Maybe.withDefault (text "") << Maybe.map errorHelp << Form.fieldError


control__ ctrlAttrs inputAttrs children input tag field ph =
    let
        error =
            Form.fieldError field

        modifiers =
            { controlInputModifiers
                | color =
                    if Maybe.isNothing error then
                        controlInputModifiers.color

                    else
                        Danger
            }

        attributes =
            inputAttrs ++ [ placeholder ph ] ++ Form.inputAttrs tag field
    in
    input modifiers ctrlAttrs attributes children


controlInput_ =
    control__ [] [] [] controlInput


controlPassword_ =
    control__ [] [] [] controlPassword


controlTextArea_ tag field ph =
    let
        error =
            Form.fieldError field

        modifiers =
            { controlTextAreaModifiers
                | color =
                    if Maybe.isNothing error then
                        controlInputModifiers.color

                    else
                        Danger
            }

        attributes =
            [ placeholder ph ] ++ Form.inputAttrs tag field
    in
    controlTextArea modifiers [] attributes []



--fieldError field submitted =
--    Maybe.withDefault (text "") (Maybe.map errorHelp (Form.fieldError field submitted))
--
--
--validateStringNonEmpty : Field -> Result (Error e) String
--validateStringNonEmpty =
--    [ Validate.string, Validate.emptyString ]
--        |> oneOf
--        |> andThen Validate.nonEmpty
--
--
--validateEmail : Field -> Result (Error e) String
--validateEmail =
--    validateStringNonEmpty
--        |> andThen (always Validate.email)
--
--
--validationErrorToString : (a -> String) -> ErrorValue a -> String
--validationErrorToString customErrorToString error =
--    case error of
--        Empty ->
--            "This field is required"
--
--        InvalidString ->
--            "Not a valid string"
--
--        InvalidEmail ->
--            "Please enter a valid email address"
--
--        InvalidFormat ->
--            "Invalid format"
--
--        InvalidInt ->
--            "This value must be an integer"
--
--        InvalidFloat ->
--            "This value must be a real number"
--
--        InvalidBool ->
--            "Error"
--
--        SmallerIntThan int ->
--            "Error"
--
--        GreaterIntThan int ->
--            "Error"
--
--        SmallerFloatThan float ->
--            "Error"
--
--        GreaterFloatThan float ->
--            "Error"
--
--        ShorterStringThan int ->
--            "Must be at least " ++ String.fromInt int ++ " characters"
--
--        LongerStringThan int ->
--            "Must be no more than " ++ String.fromInt int ++ " characters"
--
--        NotIncludedIn ->
--            "Error"
--
--        CustomError e ->
--            customErrorToString e
--
--
--
----fieldInfo :
----    (a -> String)
----    -> { b | color : Color }
----    -> { e | liveError : Maybe (ErrorValue a), path : c, value : d }
----    ->
----        { errorMessage : String
----        , hasError : Bool
----        , modifiers : { b | color : Color }
----        , path : c
----        , value : d
----        }
----fieldInfo custom modifiers { liveError, path, value } =
----    case liveError of
----        Nothing ->
----            { path = path
----            , value = value
----            , hasError = False
----            , modifiers = modifiers
----            , errorMessage = ""
----            }
----
----        Just error ->
----            { path = path
----            , value = value
----            , hasError = True
----            , modifiers = { modifiers | color = Danger }
----            , errorMessage = validationErrorToString custom error
----            }
