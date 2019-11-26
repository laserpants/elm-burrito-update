module Burrito.Form.Validate exposing (alphanumeric, andThen, atLeastLength, checkbox, email, inputField, int, mustBeChecked, mustMatchField, record, stringNotEmpty, validate)

import Burrito.Form exposing (FieldList, Status(..), Variant(..), asBool, asString, lookupField)
import Regex exposing (Regex)


stepValidate :
    tag
    -> (Variant -> FieldList tag err -> Result err a2)
    -> (a -> b -> ( FieldList tag err, Maybe (a2 -> a1), Maybe tag ))
    -> a
    -> b
    -> ( FieldList tag err, Maybe a1, Maybe tag )
stepValidate target validator fun a b =
    let
        ( fields1, maybeFun, tag ) =
            fun a b

        ( fields2, maybeArg ) =
            validate target validator fields1
    in
    ( if Nothing == tag || Just target == tag then
        fields2 ++ fields1

      else
        fields1
    , case ( maybeFun, maybeArg ) of
        ( Just f, Just arg ) ->
            Just (f arg)

        _ ->
            Nothing
    , tag
    )


inputField :
    tag
    -> (String -> FieldList tag err -> Result err a2)
    -> (a -> b -> ( FieldList tag err, Maybe (a2 -> a1), Maybe tag ))
    -> a
    -> b
    -> ( FieldList tag err, Maybe a1, Maybe tag )
inputField target validator =
    stepValidate target (validator << asString)


checkbox :
    tag
    -> (Bool -> FieldList tag err -> Result err a2)
    -> (a -> b -> ( FieldList tag err, Maybe (a2 -> a1), Maybe tag ))
    -> a
    -> b
    -> ( FieldList tag err, Maybe a1, Maybe tag )
checkbox target validator =
    stepValidate target (validator << asBool)


record : a -> b -> c -> ( c, Maybe a, b )
record a b c =
    ( c, Just a, b )


validate :
    field
    -> (Variant -> FieldList field err -> Result err a)
    -> FieldList field err
    -> ( FieldList field err, Maybe a )
validate tag validator fields =
    case lookupField tag fields of
        Just field ->
            case validator field.value fields of
                Ok ok ->
                    ( [ ( tag, { field | status = Valid } ) ], Just ok )

                Err error ->
                    ( [ ( tag, { field | status = Error error } ) ], Nothing )

        Nothing ->
            ( [], Nothing )


andThen :
    (b -> FieldList tag err -> Result err c)
    -> (a -> FieldList tag err -> Result err b)
    -> a
    -> FieldList tag err
    -> Result err c
andThen next first a fields =
    first a fields
        |> Result.andThen (\b -> next b fields)


int : err -> Variant -> FieldList tag err -> Result err Int
int error variant _ =
    case variant of
        String str ->
            Result.fromMaybe error (String.toInt str)

        _ ->
            Err error


stringNotEmpty : err -> String -> FieldList tag err -> Result err String
stringNotEmpty error str _ =
    if String.isEmpty str then
        Err error

    else
        Ok str


atLeastLength : Int -> err -> String -> FieldList tag err -> Result err String
atLeastLength len error str _ =
    if String.length str < len then
        Err error

    else
        Ok str


validEmailPattern : Regex
validEmailPattern =
    "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.withDefault Regex.never


email : err -> String -> FieldList tag err -> Result err String
email error str _ =
    if Regex.contains validEmailPattern str then
        Ok str

    else
        Err error


alphanumeric : err -> String -> FieldList tag err -> Result err String
alphanumeric error str _ =
    if String.all Char.isAlphaNum str then
        Ok str

    else
        Err error


mustBeChecked : err -> Bool -> FieldList tag err -> Result err Bool
mustBeChecked error checked _ =
    if True == checked then
        Ok True

    else
        Err error


mustMatchField : tag -> err -> String -> FieldList tag err -> Result err String
mustMatchField tag error str fields =
    case lookupField tag fields of
        Just field ->
            if asString field.value == str then
                Ok str

            else
                Err error

        _ ->
            Err error
