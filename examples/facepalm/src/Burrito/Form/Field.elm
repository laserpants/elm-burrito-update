module Burrito.Form.Field exposing (..)

import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type Status a
    = Pristine
    | Error Error
    | Valid a


type Error
    = Empty
    | InvalidEmail
    | NotAnInt
    | NotAFloat
    | DoesNotMatchField String
    | ShorterThan Int
    | MustBeChecked


setDirty : Bool -> { f | dirty : Bool } -> Update { f | dirty : Bool } msg a
setDirty dirty field =
    save { field | dirty = dirty }


setStatusFromResult :
    Result Error val
    -> { f | status : Status val }
    -> Update { f | status : Status val } msg a
setStatusFromResult result field =
    save
        { field
            | status =
                case result of
                    Ok val ->
                        Valid val

                    Err err ->
                        Error err
        }


isValid : { f | status : Status v } -> Bool
isValid { status } =
    case status of
        Valid _ ->
            True

        _ ->
            False


value : { t | status : Status val } -> Maybe val
value { status } =
    case status of
        Valid val ->
            Just val

        _ ->
            Nothing


fieldError : { t | status : Status val, dirty : Bool } -> Bool -> Maybe Error
fieldError { status, dirty } submitted =
    case status of
        Error err ->
            if submitted || not dirty then
                Just err

            else
                Nothing

        _ ->
            Nothing
