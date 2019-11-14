module Burrito.Form exposing (..)

import Burrito.Callback exposing (..)
import Burrito.Form.Field as Field exposing (Status)
import Burrito.Update exposing (..)
import Maybe.Extra as Maybe


type Msg msg
    = FieldMsg msg
    | Submit


type alias Model fields =
    { fields : fields
    , initial : fields
    , disabled : Bool
    , submitted : Bool
    }


type alias ModelUpdate fields msg a =
    Model fields -> Update (Model fields) (Msg msg) a


insertAsFieldsIn : Model fields -> fields -> Update (Model fields) msg a
insertAsFieldsIn model fields =
    save { model | fields = fields }


setDisabled : Bool -> ModelUpdate fields msg a
setDisabled disabled model =
    save { model | disabled = disabled }


setSubmitted : Bool -> ModelUpdate fields msg a
setSubmitted submitted model =
    save { model | submitted = submitted }


reset : ModelUpdate fields msg a
reset ({ initial } as model) =
    save
        { model
            | fields = initial
            , disabled = False
            , submitted = False
        }


init : fields -> Update (Model fields) msg a
init fields =
    save
        { fields = fields
        , initial = fields
        , disabled = False
        , submitted = False
        }


update :
    Msg msg
    ->
        { beforeSubmit : fields -> Update fields msg a
        , updateFields : msg -> fields -> Update fields msg a
        , formData : fields -> Maybe data
        , validate : fields -> Update fields msg a
        , isValid : fields -> Bool
        , onSubmit : data -> a
        }
    -> ModelUpdate fields msg a
update msg { beforeSubmit, updateFields, formData, validate, isValid, onSubmit } =
    let
        trySubmit fields =
            case ( isValid fields, formData fields ) of
                ( True, Just data ) ->
                    setDisabled True
                        >> andApply (onSubmit data)

                _ ->
                    save

        runUpdate doUpdate model =
            model.fields
                |> doUpdate
                |> andThen validate
                |> andThen (insertAsFieldsIn model)
                |> mapCmd FieldMsg
    in
    case msg of
        FieldMsg fieldMsg ->
            runUpdate (updateFields fieldMsg)

        Submit ->
            runUpdate beforeSubmit
                >> andThen (setSubmitted True)
                >> andThen (with .fields trySubmit)


values2 :
    (a -> b -> value)
    -> { s | status : Status a }
    -> { t | status : Status b }
    -> Maybe value
values2 f a b =
    Maybe.map2 f (Field.value a) (Field.value b)


values3 :
    (a -> b -> c -> value)
    -> { s | status : Status a }
    -> { t | status : Status b }
    -> { u | status : Status c }
    -> Maybe value
values3 f a b c =
    values2 f a b
        |> Maybe.andMap (Field.value c)


values4 :
    (a -> b -> c -> d -> value)
    -> { s | status : Status a }
    -> { t | status : Status b }
    -> { u | status : Status c }
    -> { v | status : Status d }
    -> Maybe value
values4 f a b c d =
    values3 f a b c
        |> Maybe.andMap (Field.value d)


values5 :
    (a -> b -> c -> d -> e -> value)
    -> { s | status : Status a }
    -> { t | status : Status b }
    -> { u | status : Status c }
    -> { v | status : Status d }
    -> { w | status : Status e }
    -> Maybe value
values5 f a b c d e =
    values4 f a b c d
        |> Maybe.andMap (Field.value e)
