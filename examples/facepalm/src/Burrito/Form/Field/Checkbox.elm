module Burrito.Form.Field.Checkbox exposing (..)

import Burrito.Form.Field exposing (Error, Status(..), fieldError, setDirty)
import Burrito.Update exposing (..)
import Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type Msg
    = Check Bool
    | Focus
    | Blur


type alias Checkbox =
    { checked : Bool
    , dirty : Bool
    , status : Status Bool
    }


type alias CheckboxUpdate a =
    Checkbox -> Update Checkbox Msg a


setChecked : Bool -> CheckboxUpdate a
setChecked checked field =
    save { field | checked = checked, status = Valid checked }


init : Update Checkbox msg a
init =
    save
        { checked = False
        , dirty = False
        , status = Valid False
        }


update : Msg -> CheckboxUpdate a
update msg =
    case msg of
        Check checked ->
            setChecked checked
                >> andThen (setDirty True)

        Focus ->
            save

        Blur ->
            setDirty False


input : Checkbox -> Bool -> { attrs : List (Html.Attribute Msg), error : Maybe Error }
input { checked, status, dirty } submitted =
    { attrs =
        [ type_ "checkbox"
        , onCheck Check
        , onFocus Focus
        , onBlur Blur
        , Html.Attributes.checked checked
        ]
    , error = fieldError { status = status, dirty = dirty } submitted
    }
