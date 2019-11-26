module Burrito.Form exposing (..)

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


type alias ModelExtra field err data state =
    { fields : FieldList field err
    , initial : FieldList field err
    , validate : state -> Validate field err data
    , disabled : Bool
    , submitted : Bool
    , state : state
    }


type alias Model field err data =
    ModelExtra field err data ()


type alias ModelExtraUpdate field err data state a =
    ModelExtra field err data state -> Update (ModelExtra field err data state) (Msg field) a


type alias ModelUpdate field err data a =
    ModelExtraUpdate field err data () a


setFields :
    FieldList field err
    -> ModelExtra field err data state
    -> Update (ModelExtra field err data state) msg a
setFields fields model =
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


withField : field -> (Field err -> Field err) -> ModelExtraUpdate field err data state a
withField target fun =
    with .fields (setFields << applyToField target fun)


setSubmitted : Bool -> ModelExtraUpdate field error data state a
setSubmitted submitted model =
    save { model | submitted = submitted }


setDisabled : Bool -> ModelExtraUpdate field error data state a
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


setState : state -> ModelExtraUpdate field error data state a
setState state model =
    save { model | state = state }


initExtra :
    (state -> Validate field err data)
    -> FieldList field err
    -> state
    -> Update (ModelExtra field err data state) msg a
initExtra validate fields state =
    save
        { fields = fields
        , initial = fields
        , validate = validate
        , disabled = False
        , submitted = False
        , state = state
        }


init :
    Validate field err data
    -> FieldList field err
    -> Update (Model field err data) msg a
init validate fields =
    save
        { fields = fields
        , initial = fields
        , validate = always validate
        , disabled = False
        , submitted = False
        , state = ()
        }


reset : ModelExtraUpdate field err data state a
reset model =
    save
        { model
            | fields = model.initial
            , disabled = False
            , submitted = False
        }


validateField : field -> ModelExtraUpdate field err data state a
validateField field =
    using
        (\{ validate, state, fields } ->
            validate state (Just field) fields
                |> (\( fields_, _, _ ) -> setFields fields_)
        )


setFieldDirty : field -> Bool -> ModelExtraUpdate field err data state a
setFieldDirty tag dirty =
    withField tag (\field -> { field | dirty = dirty })


update : Msg field -> { onSubmit : data -> a } -> ModelExtraUpdate field err data state a
update msg { onSubmit } =
    using
        (\{ fields, validate, state } ->
            fields
                |> (case msg of
                        Submit ->
                            List.map
                                (Tuple.mapSecond
                                    (\field ->
                                        { field | dirty = True, submitted = True }
                                    )
                                )
                                >> validate state Nothing

                        Input target value ->
                            applyToField target
                                (\field ->
                                    { field | value = value, dirty = True }
                                )
                                >> validate state (Just target)

                        Blur target ->
                            applyToField target
                                (\field ->
                                    { field | dirty = False }
                                )
                                >> validate state (Just target)

                        Focus _ ->
                            \fields_ -> ( fields_, Nothing, Nothing )
                   )
                |> (\( fields_, maybeData, _ ) ->
                        setFields fields_
                            >> andThen
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


lookup7 :
    FieldList field err
    -> field
    -> field
    -> field
    -> field
    -> field
    -> field
    -> field
    -> (Field err -> Field err -> Field err -> Field err -> Field err -> Field err -> Field err -> Html msg)
    -> Html msg
lookup7 fields f1 f2 f3 f4 f5 f6 f7 fun =
    Maybe.withDefault (text "")
        (Just fun
            |> Maybe.andMap (lookupField f1 fields)
            |> Maybe.andMap (lookupField f2 fields)
            |> Maybe.andMap (lookupField f3 fields)
            |> Maybe.andMap (lookupField f4 fields)
            |> Maybe.andMap (lookupField f5 fields)
            |> Maybe.andMap (lookupField f6 fields)
            |> Maybe.andMap (lookupField f7 fields)
        )
