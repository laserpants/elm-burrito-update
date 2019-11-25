module Form.Comment exposing (Data, Fields(..), Model, ModelUpdate, Msg, init, toJson, validate, view)

import Bulma.Form exposing (controlLabel)
import Bulma.Modifiers exposing (..)
import Burrito.Form as Form exposing (Validate, inputField)
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
    = Email
    | Body


type alias Msg =
    Form.Msg Fields


type alias Data =
    { email : String
    , body : String
    }


toJson : Data -> Json.Value
toJson { email, body } =
    Encode.object
        [ ( "email", Encode.string email )
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
            [ ( Email, inputField "" )
            , ( Body, inputField "" )
            ]
    in
    Form.init validate fields


validate : Validate Fields Error Data
validate =
    let
        validateEmail =
            Validate.stringNotEmpty MustNotBeEmpty
                |> Validate.andThen (Validate.email MustBeValidEmail)

        validateBody =
            Validate.stringNotEmpty MustNotBeEmpty
    in
    Validate.record Data
        |> Validate.inputField Email validateEmail
        |> Validate.inputField Body validateBody


view : Model -> Html Msg
view { fields, disabled } =
    Form.lookup2 fields
        Email
        Body
        (\email body ->
            [ fieldset
                [ Html.Attributes.disabled disabled ]
                [ Bulma.Form.field []
                    [ controlLabel [] [ text "Email" ]
                    , controlInput_ Email email "Email"
                    , controlErrorHelp email
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
                                    "Send comment"
                                )
                            ]
                        ]
                    ]
                ]
            ]
                |> Html.form [ onSubmit Form.Submit ]
        )
