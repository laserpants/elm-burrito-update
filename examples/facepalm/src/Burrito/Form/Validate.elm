module Burrito.Form.Validate exposing (..)

import Burrito.Form.Field exposing (..)
import Regex exposing (Regex)


andThen :
    (b -> Result Error c)
    -> (a -> Result Error b)
    -> a
    -> Result Error c
andThen validateSnd validateFst val =
    validateFst val
        |> Result.andThen validateSnd


matchesField : String -> { f | status : Status val } -> val -> Result Error val
matchesField field { status } val =
    case status of
        Valid val1 ->
            if val1 == val then
                Ok val

            else
                Err (DoesNotMatchField field)

        _ ->
            Ok val


int : String -> Result Error Int
int =
    String.toInt >> Result.fromMaybe NotAnInt


stringNotEmpty : String -> Result Error String
stringNotEmpty str =
    if String.isEmpty str then
        Err Empty

    else
        Ok str


atLeastLength : Int -> String -> Result Error String
atLeastLength len str =
    if String.length str < len then
        Err (ShorterThan len)

    else
        Ok str


validEmailPattern : Regex
validEmailPattern =
    "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.withDefault Regex.never


email : String -> Result Error String
email str =
    if Regex.contains validEmailPattern str then
        Ok str

    else
        Err InvalidEmail
