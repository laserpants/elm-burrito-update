module Ui exposing (Msg(..), State, StateUpdate, Toast, closeMenu, dismissToast, init, navbar, showInfoToast, showToast, spinner, toastMessage, toggleMenu, update)

import Bulma.Components exposing (..)
import Bulma.Elements exposing (..)
import Bulma.Modifiers exposing (..)
import Burrito.Update exposing (..)
import Data.Session exposing (Session)
import Helpers exposing (empty, when)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra as Maybe
import Process
import Task
import Ui.Toast


type Msg
    = ToggleMenu
    | DismissToast Int


type alias Toast =
    { message : String
    , color : Color
    }


type alias State =
    { menuIsOpen : Bool
    , toast : Maybe ( Int, Toast )
    , counter : Int
    }


type alias StateUpdate a =
    State -> Update State Msg a


incrementCounter : StateUpdate a
incrementCounter state =
    save { state | counter = state.counter + 1 }


toggleMenu : StateUpdate a
toggleMenu state =
    save { state | menuIsOpen = not state.menuIsOpen }


closeMenu : StateUpdate a
closeMenu state =
    save { state | menuIsOpen = False }


setToast : Toast -> StateUpdate a
setToast toast state =
    save { state | toast = Just ( state.counter, toast ) }


showToast : Toast -> StateUpdate a
showToast toast =
    using
        (\{ counter } ->
            let
                dismissToastTask =
                    always (DismissToast counter)
            in
            setToast toast
                >> andAddCmd (Task.perform dismissToastTask (Process.sleep 4000))
                >> andThen incrementCounter
        )


showInfoToast : String -> StateUpdate a
showInfoToast message =
    showToast { message = message, color = Info }


dismissToast : StateUpdate a
dismissToast state =
    save { state | toast = Nothing }


init : Update State msg a
init =
    save
        { menuIsOpen = False
        , toast = Nothing
        , counter = 1
        }


update : Msg -> StateUpdate a
update msg =
    case msg of
        ToggleMenu ->
            toggleMenu

        DismissToast id ->
            using
                (\{ toast } ->
                    case toast of
                        Nothing ->
                            save

                        Just ( toastId, _ ) ->
                            when (id == toastId) dismissToast
                )


toastMessage : State -> Html Msg
toastMessage { toast } =
    case toast of
        Nothing ->
            empty

        Just ( id, { message, color } ) ->
            let
                notification =
                    notificationWithDelete color [] (DismissToast id) [ text message ]
            in
            Ui.Toast.container notification



--navbar : Maybe Session -> { a | isHomePage : Bool, isNewPostPage : Bool, isAboutPage : Bool } -> State -> (Msg -> msg) -> Html msg


navbar { menuIsOpen } maybeSession =
    let
        burger =
            navbarBurger menuIsOpen
                [ class "has-text-white", onClick ToggleMenu ]
                [ span [] [], span [] [], span [] [] ]

        buttons =
            if Maybe.isNothing maybeSession then
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
        , navbarMenu menuIsOpen
            []
            [ navbarStart [ class "is-unselectable" ]
                [ navbarItemLink True [ href "/" ] [ text "Home" ]
                , navbarItemLink False [ href "/about" ] [ text "About" ]
                , navbarItemLink False [ href "/posts/new" ] [ text "New post" ]

                --[ navbarItemLink page.isHomePage [ href "/" ] [ text "Home" ]
                --, navbarItemLink page.isAboutPage [ href "/about" ] [ text "About" ]
                --, navbarItemLink page.isNewPostPage [ href "/posts/new" ] [ text "New post" ]
                ]
            , navbarEnd []
                [ navbarItem False [] [ div [ class "field is-grouped" ] buttons ] ]
            ]
        ]


spinner : Html msg
spinner =
    div
        [ class "sk-three-bounce" ]
        [ div [ class "sk-child sk-bounce1" ] []
        , div [ class "sk-child sk-bounce2" ] []
        , div [ class "sk-child sk-bounce3" ] []
        ]
