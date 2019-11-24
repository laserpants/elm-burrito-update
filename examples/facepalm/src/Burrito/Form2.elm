module Burrito.Form2 exposing (..)

import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra as Maybe


type Variant
    = String String
    | Bool Bool


asString : Variant -> String
asString var =
    case var of
        String string ->
            string

        _ ->
            ""


asBool : Variant -> Bool
asBool var =
    case var of
        Bool bool ->
            bool

        _ ->
            False


type Msg field
    = Focus field
    | Blur field
    | Input field Variant
    | Submit


fieldError : Field err -> Maybe err
fieldError { status, dirty, submitted } =
    case status of
        Error error ->
            if not dirty || submitted then
                Just error

            else
                Nothing

        _ ->
            Nothing


inputAttrs : field -> Field err -> List (Html.Attribute (Msg field))
inputAttrs tag { value } =
    [ onInput (Input tag << String)
    , onFocus (Focus tag)
    , onBlur (Blur tag)
    , Attributes.value (asString value)
    ]


checkboxAttrs : field -> Field err -> List (Html.Attribute (Msg field))
checkboxAttrs tag { value } =
    [ onCheck (Input tag << Bool)
    , onFocus (Focus tag)
    , onBlur (Blur tag)
    , Attributes.checked (asBool value)
    ]


type Status err
    = Pristine
    | Valid
    | Error err


type alias Field err =
    { value : Variant
    , dirty : Bool
    , status : Status err
    , submitted : Bool
    }


inputField : String -> Field err
inputField string =
    { value = String string
    , dirty = False
    , status = Pristine
    , submitted = False
    }


checkbox : Bool -> Field err
checkbox bool =
    { value = Bool bool
    , dirty = False
    , status = Pristine
    , submitted = False
    }


type alias FieldList field err =
    List ( field, Field err )


type alias Validate field err data =
    Maybe field
    -> FieldList field err
    -> ( FieldList field err, Maybe data, Maybe field )


type alias Model field err data =
    { fields : FieldList field err
    , initial : FieldList field err
    , validate : Validate field err data
    , disabled : Bool
    , submitted : Bool
    }


type alias ModelUpdate field err data a =
    Model field err data -> Update (Model field err data) (Msg field) a


insertAsFieldsIn :
    Model field err data
    -> FieldList field err
    -> Update (Model field err data) msg a
insertAsFieldsIn model fields =
    save { model | fields = fields }


applyToField :
    field
    -> (Field err -> Field err)
    -> FieldList field err
    -> FieldList field err
applyToField target fun =
    List.map
        (\( tag, field ) ->
            ( tag
            , if tag == target then
                fun field

              else
                field
            )
        )


setSubmitted : Bool -> ModelUpdate field error data a
setSubmitted submitted model =
    save { model | submitted = submitted }


setDisabled : Bool -> ModelUpdate field error data a
setDisabled disabled model =
    save { model | disabled = disabled }


lookupField : field -> FieldList field err -> Maybe (Field err)
lookupField target fields =
    let
        rec list =
            case list of
                [] ->
                    Nothing

                ( tag, field ) :: xs ->
                    if tag == target then
                        Just field

                    else
                        rec xs
    in
    rec fields


init :
    Validate field err data
    -> FieldList field err
    -> Update (Model field err data) msg a
init validate fields =
    save
        { fields = fields
        , initial = fields
        , validate = validate
        , disabled = False
        , submitted = False
        }


reset : Model field err data -> Update (Model field err data) msg a
reset model =
    save
        { model
            | fields = model.initial
            , disabled = False
            , submitted = False
        }


update : Msg field -> { onSubmit : data -> a } -> ModelUpdate field err data a
update msg { onSubmit } model =
    model.fields
        |> (case msg of
                Submit ->
                    List.map
                        (Tuple.mapSecond
                            (\field ->
                                { field | dirty = True, submitted = True }
                            )
                        )
                        >> model.validate Nothing

                Input target value ->
                    applyToField target
                        (\field ->
                            { field | value = value, dirty = True }
                        )
                        >> model.validate (Just target)

                Blur target ->
                    applyToField target
                        (\field ->
                            { field | dirty = False }
                        )
                        >> model.validate (Just target)

                Focus target ->
                    \fields -> ( fields, Nothing, Nothing )
           )
        |> (\( fields, maybeData, _ ) ->
                insertAsFieldsIn model fields
                    |> andThen
                        (if Submit == msg then
                            setSubmitted True
                                >> andThen
                                    (case maybeData of
                                        Just data ->
                                            setDisabled True
                                                >> andApply (onSubmit data)

                                        Nothing ->
                                            save
                                    )

                         else
                            save
                        )
           )


lookup2 :
    FieldList field err
    -> field
    -> field
    -> (Field err -> Field err -> Html msg)
    -> Html msg
lookup2 fields f1 f2 fun =
    Maybe.withDefault (text "")
        (Maybe.map2 fun
            (lookupField f1 fields)
            (lookupField f2 fields)
        )


lookup3 :
    FieldList field err
    -> field
    -> field
    -> field
    -> (Field err -> Field err -> Field err -> Html msg)
    -> Html msg
lookup3 fields f1 f2 f3 fun =
    Maybe.withDefault (text "")
        (Maybe.map3 fun
            (lookupField f1 fields)
            (lookupField f2 fields)
            (lookupField f3 fields)
        )


lookup4 :
    FieldList field err
    -> field
    -> field
    -> field
    -> field
    -> (Field err -> Field err -> Field err -> Field err -> Html msg)
    -> Html msg
lookup4 fields f1 f2 f3 f4 fun =
    Maybe.withDefault (text "")
        (Maybe.map4 fun
            (lookupField f1 fields)
            (lookupField f2 fields)
            (lookupField f3 fields)
            (lookupField f4 fields)
        )


lookup5 :
    FieldList field err
    -> field
    -> field
    -> field
    -> field
    -> field
    -> (Field err -> Field err -> Field err -> Field err -> Field err -> Html msg)
    -> Html msg
lookup5 fields f1 f2 f3 f4 f5 fun =
    Maybe.withDefault (text "")
        (Maybe.map5 fun
            (lookupField f1 fields)
            (lookupField f2 fields)
            (lookupField f3 fields)
            (lookupField f4 fields)
            (lookupField f5 fields)
        )


lookup6 :
    FieldList field err
    -> field
    -> field
    -> field
    -> field
    -> field
    -> field
    -> (Field err -> Field err -> Field err -> Field err -> Field err -> Field err -> Html msg)
    -> Html msg
lookup6 fields f1 f2 f3 f4 f5 f6 fun =
    Maybe.withDefault (text "")
        (Just fun
            |> Maybe.andMap (lookupField f1 fields)
            |> Maybe.andMap (lookupField f2 fields)
            |> Maybe.andMap (lookupField f3 fields)
            |> Maybe.andMap (lookupField f4 fields)
            |> Maybe.andMap (lookupField f5 fields)
            |> Maybe.andMap (lookupField f6 fields)
        )
