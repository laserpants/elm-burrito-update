module Page exposing (Msg(..), Page(..), current, subscriptions, update, view)

import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Data.Comment exposing (Comment)
import Data.Post exposing (Post)
import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Page.Home
import Page.Login
import Page.NewPost
import Page.Register
import Page.ShowPost
import Ui.Page


type Msg
    = HomePageMsg Page.Home.Msg
    | NewPostPageMsg Page.NewPost.Msg
    | ShowPostPageMsg Page.ShowPost.Msg
    | LoginPageMsg Page.Login.Msg
    | RegisterPageMsg Page.Register.Msg


type Page
    = HomePage Page.Home.State
    | NewPostPage Page.NewPost.State
    | ShowPostPage Page.ShowPost.State
    | LoginPage Page.Login.State
    | RegisterPage Page.Register.State
    | AboutPage
    | NotFoundPage


current : Page -> { isHomePage : Bool, isNewPostPage : Bool, isShowPostPage : Bool, isLoginPage : Bool, isRegisterPage : Bool, isAboutPage : Bool, isNotFoundPage : Bool }
current page =
    let
        none =
            { isHomePage = False, isNewPostPage = False, isShowPostPage = False, isLoginPage = False, isRegisterPage = False, isAboutPage = False, isNotFoundPage = False }
    in
    case page of
        HomePage _ ->
            { none | isHomePage = True }

        NewPostPage _ ->
            { none | isNewPostPage = True }

        ShowPostPage _ ->
            { none | isShowPostPage = True }

        LoginPage _ ->
            { none | isLoginPage = True }

        RegisterPage _ ->
            { none | isRegisterPage = True }

        AboutPage ->
            { none | isAboutPage = True }

        NotFoundPage ->
            { none | isNotFoundPage = True }


update :
    { onAuthResponse : Maybe Session -> a
    , onPostAdded : Post -> a
    , onCommentCreated : Comment -> a
    }
    -> Msg
    -> Page
    -> Update Page Msg a
update { onAuthResponse, onPostAdded, onCommentCreated } msg page =
    case ( page, msg ) of
        ( HomePage homePageState, HomePageMsg homeMsg ) ->
            homePageState
                |> Page.Home.update homeMsg
                |> Burrito.Update.map HomePage
                |> mapCmd HomePageMsg

        ( NewPostPage newPostPageState, NewPostPageMsg newPostMsg ) ->
            newPostPageState
                |> Page.NewPost.update { onPostAdded = onPostAdded } newPostMsg
                |> Burrito.Update.map NewPostPage
                |> mapCmd NewPostPageMsg

        ( ShowPostPage showPostPageState, ShowPostPageMsg showPostMsg ) ->
            showPostPageState
                |> Page.ShowPost.update { onCommentCreated = onCommentCreated } showPostMsg
                |> Burrito.Update.map ShowPostPage
                |> mapCmd ShowPostPageMsg

        ( LoginPage loginPageState, LoginPageMsg loginMsg ) ->
            loginPageState
                |> Page.Login.update { onAuthResponse = onAuthResponse } loginMsg
                |> Burrito.Update.map LoginPage
                |> mapCmd LoginPageMsg

        ( RegisterPage registerPageState, RegisterPageMsg registerMsg ) ->
            registerPageState
                |> Page.Register.update registerMsg
                |> Burrito.Update.map RegisterPage
                |> mapCmd RegisterPageMsg

        _ ->
            save page


subscriptions : Page -> (Msg -> msg) -> Sub msg
subscriptions page toMsg =
    case page of
        HomePage homePageState ->
            Page.Home.subscriptions homePageState (toMsg << HomePageMsg)

        NewPostPage newPostPageState ->
            Page.NewPost.subscriptions newPostPageState (toMsg << NewPostPageMsg)

        ShowPostPage showPostPageState ->
            Page.ShowPost.subscriptions showPostPageState (toMsg << ShowPostPageMsg)

        LoginPage loginPageState ->
            Page.Login.subscriptions loginPageState (toMsg << LoginPageMsg)

        RegisterPage registerPageState ->
            Page.Register.subscriptions registerPageState (toMsg << RegisterPageMsg)

        AboutPage ->
            Sub.none

        NotFoundPage ->
            Sub.none


view : Page -> (Msg -> msg) -> Html msg
view page toMsg =
    case page of
        HomePage homePageState ->
            Page.Home.view homePageState (toMsg << HomePageMsg)

        NewPostPage newPostPageState ->
            Page.NewPost.view newPostPageState (toMsg << NewPostPageMsg)

        ShowPostPage showPostPageState ->
            Page.ShowPost.view showPostPageState (toMsg << ShowPostPageMsg)

        LoginPage loginPageState ->
            Page.Login.view loginPageState (toMsg << LoginPageMsg)

        RegisterPage registerPageState ->
            Page.Register.view registerPageState (toMsg << RegisterPageMsg)

        AboutPage ->
            Ui.Page.container "About" [ text "Welcome to Facepalm. A place to meet weird people while keeping all your personal data safe." ]

        NotFoundPage ->
            Ui.Page.container "Error 404" [ text "That means we couldn’t find this page." ]
