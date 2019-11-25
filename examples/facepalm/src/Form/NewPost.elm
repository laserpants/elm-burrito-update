module Form.NewPost exposing (Data, Fields(..), Model, ModelUpdate, Msg, init, toJson, validate, view)

import Bulma.Form exposing (controlLabel)
import Bulma.Modifiers exposing (..)
import Burrito.Form as Form exposing (Validate, checkbox, inputField)
import Burrito.Form.Validate as Validate
import Burrito.Update exposing (Update)
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
