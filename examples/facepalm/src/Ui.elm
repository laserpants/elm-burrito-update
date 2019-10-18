module Ui exposing (Msg(..), State, Toast, closeBurgerMenu, closeToast, init, navbar, showInfoToast, showToast, spinner, toastMessage, toggleMenuOpen, update)

import Bulma.Components exposing (..)
import Bulma.Elements exposing (..)
import Bulma.Modifiers exposing (..)
import Burrito.Update exposing (..)
import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra as Maybe
import Process
import Task
import Ui.Toast


type Msg
    = ToggleBurgerMenu
    | CloseToast Int


type alias Toast =
    { message : String
    , color : Color
    }


type alias State =
    { menuOpen : Bool
    , toast : Maybe ( Int, Toast )
    , toastCounter : Int
    }


incrementToastCounter : State -> Update State Msg a
incrementToastCounter state =
    save { state | toastCounter = 1 + state.toastCounter }


toggleMenuOpen : State -> Update State Msg a
toggleMenuOpen state =
    save { state | menuOpen = not state.menuOpen }


closeBurgerMenu : State -> Update State Msg a
closeBurgerMenu state =
    save { state | menuOpen = False }


setToast : Toast -> State -> Update State Msg a
setToast toast state =
    save { state | toast = Just ( state.toastCounter, toast ) }


showToast : Toast -> State -> Update State Msg a
showToast toast state =
    state
        |> setToast toast
        |> andAddCmd (Task.perform (CloseToast state.toastCounter |> always) (Process.sleep 4000))
        |> andThen incrementToastCounter


showInfoToast : String -> State -> Update State Msg a
showInfoToast message =
    showToast { message = message, color = Info }


closeToast : State -> Update State Msg a
closeToast state =
    save { state | toast = Nothing }


init : Update State msg a
init =
    save State
        |> andMap (save False)
        |> andMap (save Nothing)
        |> andMap (save 1)


update : Msg -> State -> Update State Msg a
update msg =
    case msg of
        ToggleBurgerMenu ->
            toggleMenuOpen

        CloseToast id ->
            with .toast
                (\toast ->
                    case toast of
                        Nothing ->
                            save

                        Just ( toastId, _ ) ->
                            if id == toastId then
                                closeToast

                            else
                                save
                )


toastMessage : State -> (Msg -> msg) -> Html msg
toastMessage { toast } toMsg =
    case toast of
        Nothing ->
            text ""

        Just ( id, { message, color } ) ->
            notificationWithDelete color [] (CloseToast id) [ text message ]
                |> Ui.Toast.container
                |> Html.map toMsg


navbar : Maybe Session -> { a | isHomePage : Bool, isNewPostPage : Bool, isAboutPage : Bool } -> State -> (Msg -> msg) -> Html msg
navbar session page { menuOpen } toMsg =
    let
        burger =
            navbarBurger menuOpen
                [ class "has-text-white", onClick ToggleBurgerMenu ]
                [ span [] [], span [] [], span [] [] ]

        buttons =
            if Maybe.isNothing session then
                [ p [ class "control" ]
                    [ a [ class "button is-primary", href "/register" ] [ text "Register" ] ]
                , p [ class "control" ]
                    [ a [ class "button is-light", href "/login" ] [ text "Log in" ] ]
                ]

            else
                [ p [ class "control" ]
                    [ a [ class "button is-primary", href "/logout" ] [ text "Log out" ] ]
                ]
    in
    fixedNavbar Top
        { navbarModifiers | color = Info }
        []
        [ navbarBrand []
            burger
            [ navbarItem False [] [ h5 [ class "title is-5" ] [ a [ class "has-text-white", href "/" ] [ text "Facepalm" ] ] ] ]
        , navbarMenu menuOpen
            []
            [ navbarStart [ class "is-unselectable" ]
                [ navbarItemLink page.isHomePage [ href "/" ] [ text "Home" ]
                , navbarItemLink page.isAboutPage [ href "/about" ] [ text "About" ]
                , navbarItemLink page.isNewPostPage [ href "/posts/new" ] [ text "New post" ]
                ]
            , navbarEnd []
                [ navbarItem False [] [ div [ class "field is-grouped" ] buttons ] ]
            ]
        ]
        |> Html.map toMsg


spinner : Html msg
spinner =
    div [ class "sk-three-bounce" ] [ div [ class "sk-child sk-bounce1" ] [], div [ class "sk-child sk-bounce2" ] [], div [ class "sk-child sk-bounce3" ] [] ]
