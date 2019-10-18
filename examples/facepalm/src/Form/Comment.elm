module Form.Comment exposing (Fields, toJson, validate, view)

import Bulma.Form exposing (controlEmail, controlHelp, controlInputModifiers, controlLabel, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Form exposing (Form)
import Form.Field exposing (FieldValue(..))
import Form.Validate exposing (Validation, andMap, field, succeed)
import Helpers.Form exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode


type alias Fields =
    { email : String
    , body : String
    }


validate : Validation Never Fields
validate =
    succeed Fields
        |> andMap (field "email" validateEmail)
        |> andMap (field "body" validateStringNonEmpty)


toJson : Int -> Fields -> Json.Value
toJson postId { email, body } =
    Encode.object
        [ ( "postId", Encode.int postId )
        , ( "email", Encode.string email )
        , ( "body", Encode.string body )
        ]


view : Form Never Fields -> Bool -> (Form.Msg -> msg) -> Html msg
view form disabled toMsg =
    let
        info =
            fieldInfo (always "")

        email =
            form |> Form.getFieldAsString "email" |> info controlInputModifiers

        body =
            form |> Form.getFieldAsString "body" |> info controlTextAreaModifiers
    in
    [ fieldset [ Html.Attributes.disabled disabled ]
        [ Bulma.Form.field []
            [ controlLabel [] [ text "Email" ]
            , controlEmail email.modifiers
                []
                [ placeholder "Email"
                , onFocus (Form.Focus email.path)
                , onBlur (Form.Blur email.path)
                , onInput (String >> Form.Input email.path Form.Text)
                , value (Maybe.withDefault "" email.value)
                ]
                []
            , controlHelp Danger [] [ Html.text email.errorMessage ]
            ]
        , Bulma.Form.field []
            [ controlLabel [] [ text "Body" ]
            , controlTextArea body.modifiers
                []
                [ placeholder "Body"
                , onFocus (Form.Focus body.path)
                , onBlur (Form.Blur body.path)
                , onInput (String >> Form.Input body.path Form.Text)
                , value (Maybe.withDefault "" body.value)
                ]
                []
            , controlHelp Danger [] [ Html.text body.errorMessage ]
            ]
        , Bulma.Form.field []
            [ div [ class "control" ]
                [ button [ type_ "submit", class "button is-primary" ]
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
        |> Html.map toMsg
