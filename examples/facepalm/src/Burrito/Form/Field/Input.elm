module Burrito.Form.Field.Input exposing (..)

import Burrito.Form.Field exposing (Error, Status(..), fieldError, setDirty, setStatusFromResult)
import Burrito.Update exposing (..)
import Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type Msg
    = Input String
    | Focus
    | Blur


type alias InputField v =
    { value : String
    , dirty : Bool
    , status : Status v
    }


type alias InputFieldUpdate v a =
    InputField v -> Update (InputField v) Msg a


setValue : String -> InputFieldUpdate v a
setValue value field =
    save { field | value = value }


validateField : (String -> Result Error v) -> InputFieldUpdate v a
validateField validator field =
    let
        { dirty, value } =
            field
    in
    field
        |> (if dirty then
                setStatusFromResult (validator value)

            else
                save
           )


init : String -> Update (InputField v) msg a
init value =
    save
        { value = value
        , dirty = False
        , status = Pristine
        }


update : Msg -> InputFieldUpdate v a
update msg =
    case msg of
        Input value ->
            setValue value
                >> andThen (setDirty True)

        Focus ->
            save

        Blur ->
            setDirty False


fieldInfo : InputField a -> String -> Bool -> { attrs : List (Html.Attribute Msg), error : Maybe Error }
fieldInfo { value, status, dirty } fieldType submitted =
    { attrs =
        [ type_ fieldType
        , onInput Input
        , onFocus Focus
        , onBlur Blur
        , Html.Attributes.value value
        ]
    , error = fieldError { status = status, dirty = dirty } submitted
    }


text : InputField a -> Bool -> { attrs : List (Html.Attribute Msg), error : Maybe Error }
text field =
    fieldInfo field "text"


password : InputField a -> Bool -> { attrs : List (Html.Attribute Msg), error : Maybe Error }
password field =
    fieldInfo field "password"
