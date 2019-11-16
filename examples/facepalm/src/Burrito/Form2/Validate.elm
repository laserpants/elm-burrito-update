module Burrito.Form2.Validate exposing (..)

import Burrito.Form2 exposing (..)
import Regex exposing (Regex)


andThen :
    (b -> Result err c)
    -> (a -> Result err b)
    -> a
    -> Result err c
andThen validateSnd validateFst val =
    validateFst val
        |> Result.andThen validateSnd



--matchesField : String -> { f | status : Status val } -> val -> Result Error val


matchesField field { status } val =
    case status of
        Valid val1 ->
            if val1 == val then
                Ok val

            else
                Err (Debug.todo "")

        -- (DoesNotMatchField field)
        _ ->
            Ok val



--int : String -> Result Error Int


int =
    String.toInt >> Result.fromMaybe (Debug.todo "")



-- NotAnInt
--stringNotEmpty : String -> Result Error String
--stringNotEmpty : FieldValue -> Result Error String


stringNotEmpty err variant =
    case variant of
        String str ->
            if String.isEmpty str then
                Just (Err err)

            else
                Just (Ok str)

        _ ->
            Nothing



--atLeastLength : Int -> String -> Result Error String


atLeastLength len str =
    if String.length str < len then
        Err (Debug.todo "")
        -- (ShorterThan len)

    else
        Ok str


validEmailPattern : Regex
validEmailPattern =
    "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.withDefault Regex.never



--email : String -> Result Error String


email str =
    if Regex.contains validEmailPattern str then
        Ok str

    else
        Err (Debug.todo "")



-- InvalidEmail
