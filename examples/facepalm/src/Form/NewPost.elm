module Form.NewPost exposing (..)

import Bulma.Form exposing (controlEmail, controlHelp, controlInput, controlInputModifiers, controlLabel, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Form2 as Form exposing (Validate, checkbox, inputField)
import Burrito.Form2.Validate as Validate
import Burrito.Update exposing (Update)
--import Form.Field exposing (FieldValue(..))
import Form.Error exposing (Error(..))
import Helpers.Form exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode


type Fields
    = Title
    | Body


type alias Msg =
    Form.Msg Fields


type alias Data =
    { title : String
    , body : String
    }


toJson : Data -> Json.Value
toJson { title, body } =
    Encode.object
        [ ( "title", Encode.string title )
        , ( "body", Encode.string body )
        ]


type alias Model =
    Form.Model Fields Error Data


type alias ModelUpdate a =
    Form.ModelUpdate Fields Error Data a


init : Update Model msg a
init =
    let
        fields =
            [ ( Title, inputField "" )
            , ( Body, inputField "" )
            ]
    in
    Form.init validate fields


validate : Validate Fields Error Data
validate =
    let
        validateTitle =
            Validate.stringNotEmpty MustNotBeEmpty

        validateBody =
            Validate.stringNotEmpty MustNotBeEmpty
    in
    Validate.record Data
        |> Validate.inputField Title validateTitle
        |> Validate.inputField Body validateBody


view : Model -> Html Msg
view { fields, disabled, submitted } =
    Form.lookup2 fields
        Title
        Body
        (\title body ->
            [ fieldset
                [ Html.Attributes.disabled disabled ]
                [ Bulma.Form.field []
                    [ controlLabel [] [ text "Title" ]
                    , controlInput_ Title title "Title"
                    , controlErrorHelp title
                    ]
                , Bulma.Form.field []
                    [ controlLabel [] [ text "Body" ]
                    , controlTextArea_ Body body "Body"
                    , controlErrorHelp body
                    ]
                , Bulma.Form.field []
                    [ div [ class "control" ]
                        [ button [ class "button is-primary" ]
                            [ text
                                (if disabled then
                                    "Please wait"

                                 else
                                    "Publish"
                                )
                            ]
                        ]
                    ]
                ]
            ]
                |> Html.form [ onSubmit Form.Submit ]
        )



--view : Form Never Fields -> Bool -> (Form.Msg -> msg) -> Html msg
--view form disabled toMsg =
--    Debug.todo ""
--    let
--        info =
--            fieldInfo (always "")
--
--        title =
--            form |> Form.getFieldAsString "title" |> info controlInputModifiers
--
--        body =
--            form |> Form.getFieldAsString "body" |> info controlTextAreaModifiers
--    in
--    [ fieldset [ Html.Attributes.disabled disabled ]
--        [ Bulma.Form.field []
--            [ controlLabel [] [ text "Title" ]
--            , controlInput title.modifiers
--                []
--                [ placeholder "Title"
--                , onFocus (Form.Focus title.path)
--                , onBlur (Form.Blur title.path)
--                , onInput (String >> Form.Input title.path Form.Text)
--                , value (Maybe.withDefault "" title.value)
--                ]
--                []
--            , controlHelp Danger [] [ Html.text title.errorMessage ]
--            ]
--        , Bulma.Form.field []
--            [ controlLabel [] [ text "Body" ]
--            , controlTextArea body.modifiers
--                []
--                [ placeholder "Body"
--                , onFocus (Form.Focus body.path)
--                , onBlur (Form.Blur body.path)
--                , onInput (String >> Form.Input body.path Form.Text)
--                , value (Maybe.withDefault "" body.value)
--                ]
--                []
--            , controlHelp Danger [] [ Html.text body.errorMessage ]
--            ]
--        , Bulma.Form.field []
--            [ div [ class "control" ]
--                [ button [ class "button is-primary" ]
--                    [ text
--                        (if disabled then
--                            "Please wait"
--
--                         else
--                            "Publish"
--                        )
--                    ]
--                ]
--            ]
--        ]
--    ]
--        |> Html.form [ onSubmit Form.Submit ]
--        |> Html.map toMsg
