module Burrito.Form2 exposing (..)

import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)


type FieldValue
    = String String
    | Bool Bool


toString : FieldValue -> String
toString variant =
    case variant of
        String string ->
            string

        _ ->
            ""


toBool : FieldValue -> Bool
toBool variant =
    case variant of
        Bool bool ->
            bool

        _ ->
            False


type Msg
    = Focus
    | Blur
    | Input FieldValue
    | Submit

type Status val err
    = Pristine
    | Error err
    | Valid val


type alias Field val err =
    { value : FieldValue
    , dirty : Bool
    , status : Status val err
    }


validate :
    (FieldValue -> Maybe (Result val err))
    -> Field err val
    -> Field err val
validate validator field =
    case validator field.value of
        Just result ->
            let
                status =
                    case result of
                        Ok ok ->
                            Valid ok

                        Err err ->
                            Error err
            in
            { field | status = status }

        Nothing ->
            field



--setValue :
--    Field val err
--    -> FieldValue
--    -> Update (Field val err) msg a
--setValue field value =
--    save { field | value = value }


initial : FieldValue -> Field val err
initial value =
    { value = value
    , dirty = False
    , status = Pristine
    }


initialString : Field val err
initialString =
    initial (String "")


initialBool : Field val err
initialBool =
    initial (Bool False)


inputAttrs : Field val err -> List (Html.Attribute Msg)
inputAttrs { value } =
    [ type_ "text"
    , onInput (Input << String)
    , onFocus Focus
    , onBlur Blur
    , Attributes.value (toString value)
    ]


passwordAttrs : Field val err -> List (Html.Attribute Msg)
passwordAttrs { value } =
    [ type_ "password"
    , onInput (Input << String)
    , onFocus Focus
    , onBlur Blur
    , Attributes.value (toString value)
    ]


checkboxAttrs : Field val err -> List (Html.Attribute Msg)
checkboxAttrs { value } =
    [ type_ "checkbox"
    , onCheck (Input << Bool)
    , onFocus Focus
    , onBlur Blur
    , Attributes.checked (toBool value)
    ]



--info :
--    String
--    -> Field val err
--    ->
--       { attrs : List (Html.Attribute msg)
--       , error : Maybe err
--       }
--info fieldType { value } =
--    Debug.todo ""
--    { attrs =
--        [ type_ fieldType
--        , onInput UpdateField
--        , onFocus Focus
--        , onBlur Blur
--        , Html.Attributes.value value
--        ]
--    , error = Nothing
--    }
--


type alias Model fields =
    { fields : fields
    , initial : fields
    , validate : fields -> fields
    , disabled : Bool
    , submitted : Bool
    }


insertAsFieldsIn : Model fields -> fields -> Update (Model fields) msg a
insertAsFieldsIn model fields =
    save { model | fields = fields }


type alias ModelUpdate fields msg a =
    Model fields -> Update (Model fields) msg a


setDisabled : Bool -> Model fields -> Update (Model fields) msg a
setDisabled disabled model =
    save { model | disabled = disabled }


setSubmitted : Bool -> Model fields -> Update (Model fields) msg a
setSubmitted submitted model =
    save { model | submitted = submitted }


reset : Model fields -> Update (Model fields) msg a
reset model =
    save
        { model
            | fields = model.initial
            , disabled = False
            , submitted = False
        }


init : (fields -> fields) -> fields -> Update (Model fields) msg a
init validateFields fields =
    save
        { fields = fields
        , initial = fields
        , validate = validateFields
        , disabled = False
        , submitted = False
        }


submit : ModelUpdate fields msg a
submit =
    save


updateField : Msg -> Field val err -> Field val err
updateField msg field =
    case msg of
        Submit ->
            { field | dirty = True }

        Input value ->
            { field | value = value, dirty = True }

        Blur ->
            { field | dirty = False }

        Focus ->
            field


update :
    ((Field val err -> Field val err) -> fields -> fields)
    -> (Msg -> msg)
    -> Msg
    -> ModelUpdate fields msg a
update lift toMsg msg model =
    model.fields
        |> lift (updateField msg)
        |> model.validate
        |> insertAsFieldsIn model
        |> andThen
            (if Submit == msg then
                setSubmitted True
                -- >> andThen (with .fields trySubmit)

             else
                save
            )
        |> mapCmd toMsg
        |> runCallbacks
