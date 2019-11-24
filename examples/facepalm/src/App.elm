module App exposing (Flags, Msg(..), State, init, subscriptions, update, view)

import Browser exposing (Document)
import Browser.Navigation as Navigation
import Bulma.Layout exposing (SectionSpacing(..))
import Bulma.Modifiers exposing (..)
import Burrito.Callback exposing (..)
import Burrito.Router as Router
import Burrito.Update exposing (..)
import Data.Comment as Comment exposing (Comment)
import Data.Post as Post exposing (Post)
import Data.Session as Session exposing (Session)
import Html exposing (..)
import Json.Decode as Json
import Maybe.Extra as Maybe
import Page.Home as HomePage
import Page.Login as LoginPage
import Page.NewPost as NewPostPage
import Page.Register as RegisterPage
import Page.ShowPost as ShowPostPage
import Ports
import Route exposing (Route(..), fromUrl)
import Ui exposing (Toast)
import Ui.Page
import Ui.Toast
import Url exposing (Url)


type PageMsg
    = HomePageMsg HomePage.Msg
    | NewPostPageMsg NewPostPage.Msg
    | ShowPostPageMsg ShowPostPage.Msg
    | LoginPageMsg LoginPage.Msg
    | RegisterPageMsg RegisterPage.Msg


type Msg
    = RouterMsg Router.Msg
    | UiMsg Ui.Msg
    | PageMsg PageMsg


type alias Flags =
    { session : String
    , basePath : String
    }


type Page
    = PageNotFound
    | HomePage HomePage.State
    | NewPostPage NewPostPage.State
    | ShowPostPage ShowPostPage.State
    | LoginPage LoginPage.State
    | RegisterPage RegisterPage.State
    | AboutPage


type alias State =
    { session : Maybe Session
    , router : Router.State Route
    , ui : Ui.State
    , redirect : Maybe String
    , page : Page
    }


type alias StateUpdate a =
    State -> Update State Msg a


setSession : Maybe Session -> StateUpdate a
setSession session state =
    save { state | session = session }


insertAsRouterIn : State -> Router.State Route -> Update State msg a
insertAsRouterIn state router =
    save { state | router = router }


setRedirect : Url -> StateUpdate a
setRedirect { path } state =
    let
        url =
            String.dropLeft (String.length state.router.basePath) path
    in
    save { state | redirect = Just url }


resetRedirect : StateUpdate a
resetRedirect state =
    save { state | redirect = Nothing }


insertAsUiIn : State -> Ui.State -> Update State msg a
insertAsUiIn state ui =
    save { state | ui = ui }


setPage : Page -> StateUpdate a
setPage page state =
    save { state | page = page }


insertAsPageIn : State -> Page -> Update State msg a
insertAsPageIn state page =
    save { state | page = page }


inRouter : Router.StateUpdate Route (StateUpdate a) -> StateUpdate a
inRouter doUpdate state =
    doUpdate state.router
        |> andThen (insertAsRouterIn state)
        |> mapCmd RouterMsg
        |> runCallbacks


inUi : Ui.StateUpdate (StateUpdate a) -> StateUpdate a
inUi doUpdate state =
    doUpdate state.ui
        |> andThen (insertAsUiIn state)
        |> mapCmd UiMsg
        |> runCallbacks


inPage :
    (msg -> PageMsg)
    -> (page -> Page)
    -> Update page msg (StateUpdate a)
    -> StateUpdate a
inPage msg page pageUpdate state =
    pageUpdate
        |> andThen (page >> insertAsPageIn state)
        |> mapCmd (PageMsg << msg)
        |> runCallbacks


redirect : String -> StateUpdate a
redirect =
    inRouter << Router.redirect


showToast : Toast -> StateUpdate a
showToast =
    inUi << Ui.showToast


init : Flags -> Url -> Navigation.Key -> Update State Msg a
init { basePath, session } url key =
    let
        maybeSession =
            Json.decodeString Session.decoder session
                |> Result.toMaybe
                |> save

        router =
            Router.init fromUrl basePath key

        ui =
            Ui.init
    in
    save State
        |> andMap maybeSession
        |> andMap router
        |> andMap ui
        |> andMap (save Nothing)
        |> andMap (save PageNotFound)
        |> andThen (notifyUrlChange url)


notifyUrlChange : Url -> StateUpdate a
notifyUrlChange =
    update << RouterMsg << Router.UrlChange


pageSubscriptions : Page -> Sub PageMsg
pageSubscriptions page =
    case page of
        PageNotFound ->
            Sub.none

        HomePage homePageState ->
            Sub.map HomePageMsg (HomePage.subscriptions homePageState)

        NewPostPage newPostPageState ->
            Sub.map NewPostPageMsg (NewPostPage.subscriptions newPostPageState)

        ShowPostPage showPostPageState ->
            Sub.map ShowPostPageMsg (ShowPostPage.subscriptions showPostPageState)

        LoginPage loginPageState ->
            Sub.map LoginPageMsg (LoginPage.subscriptions loginPageState)

        RegisterPage registerPageState ->
            Sub.map RegisterPageMsg (RegisterPage.subscriptions registerPageState)

        AboutPage ->
            Sub.none


subscriptions : State -> Sub Msg
subscriptions { page } =
    Sub.batch
        [ Sub.map PageMsg (pageSubscriptions page)
        ]


handleRouteChange : Url -> Maybe Route -> StateUpdate a
handleRouteChange url maybeRoute =
    let
        ifAuthenticated pageUpdate =
            using
                (\{ session } ->
                    if Nothing == session then
                        -- Set URL to return to after successful login
                        setRedirect url
                            >> andThen (redirect "/login")
                            >> andThen
                                (showToast
                                    { message = "You must be logged in to access that page."
                                    , color = Warning
                                    }
                                )

                    else
                        pageUpdate
                )

        unlessAuthenticated pageUpdate =
            using
                (\{ session } ->
                    if Maybe.isJust session then
                        redirect "/"

                    else
                        pageUpdate
                )

        changePage =
            case maybeRoute of
                Nothing ->
                    setPage PageNotFound

                Just route ->
                    case route of
                        -- Redirect if already authenticated
                        Login ->
                            unlessAuthenticated
                                (inPage LoginPageMsg LoginPage LoginPage.init)

                        Register ->
                            unlessAuthenticated
                                (inPage RegisterPageMsg RegisterPage RegisterPage.init)

                        -- Authenticated only
                        NewPost ->
                            ifAuthenticated
                                (inPage NewPostPageMsg NewPostPage NewPostPage.init)

                        -- Other
                        About ->
                            setPage AboutPage

                        Home ->
                            inPage HomePageMsg HomePage HomePage.init

                        ShowPost id ->
                            inPage ShowPostPageMsg ShowPostPage (ShowPostPage.init id)

                        Logout ->
                            setSession Nothing
                                >> andThen (updateSessionStorage Nothing)
                                >> andThen (redirect "/")
                                >> andThen
                                    (showToast
                                        { message = "You have been logged out."
                                        , color = Info
                                        }
                                    )
    in
    using
        (\{ router } ->
            if Just Login /= router.route then
                resetRedirect

            else
                save
        )
        >> andThen changePage
        >> andThen (inUi Ui.closeMenu)


updateSessionStorage : Maybe Session -> StateUpdate a
updateSessionStorage maybeSession =
    case maybeSession of
        Nothing ->
            addCmd (Ports.clearSession ())

        Just session ->
            addCmd (Ports.setSession session)


returnToRestrictedUrl : StateUpdate a
returnToRestrictedUrl =
    with .redirect (redirect << Maybe.withDefault "/")


handleAuthResponse : Maybe Session -> StateUpdate a
handleAuthResponse maybeSession =
    let
        authenticated =
            Maybe.isJust maybeSession
    in
    setSession maybeSession
        >> andThen (updateSessionStorage maybeSession)
        >> andThen
            (if authenticated then
                returnToRestrictedUrl

             else
                save
            )


handlePostAdded : Post -> StateUpdate a
handlePostAdded post =
    redirect "/"
        >> andThen
            (inUi
                (Ui.showToast
                    { message = "Your post was published.", color = Info }
                )
            )


handleCommentCreated : Comment -> StateUpdate a
handleCommentCreated comment =
    inUi
        (Ui.showToast
            { message = "You have been logged out.", color = Info }
        )


update : Msg -> StateUpdate a
update msg =
    case msg of
        RouterMsg routerMsg ->
            inRouter (Router.update routerMsg { onRouteChange = handleRouteChange })

        UiMsg uiMsg ->
            inUi (Ui.update uiMsg)

        PageMsg pageMsg ->
            using
                (\{ page } ->
                    case ( pageMsg, page ) of
                        ( HomePageMsg homePageMsg, HomePage homePageState ) ->
                            inPage HomePageMsg
                                HomePage
                                (HomePage.update homePageMsg homePageState)

                        ( NewPostPageMsg newPostPageMsg, NewPostPage newPostPageState ) ->
                            inPage NewPostPageMsg
                                NewPostPage
                                (NewPostPage.update newPostPageMsg { onPostAdded = handlePostAdded } newPostPageState)

                        ( LoginPageMsg loginPageMsg, LoginPage loginPageState ) ->
                            inPage LoginPageMsg
                                LoginPage
                                (LoginPage.update loginPageMsg { onAuthResponse = handleAuthResponse } loginPageState)

                        ( RegisterPageMsg registerPageMsg, RegisterPage registerPageState ) ->
                            inPage RegisterPageMsg
                                RegisterPage
                                (RegisterPage.update registerPageMsg { onRegistrationComplete = always (redirect "/login") } registerPageState)

                        ( ShowPostPageMsg showPostPageMsg, ShowPostPage showPostPageState ) ->
                            inPage ShowPostPageMsg
                                ShowPostPage
                                (ShowPostPage.update showPostPageMsg { onCommentCreated = handleCommentCreated } showPostPageState)

                        _ ->
                            save
                )


pageView : Page -> Html PageMsg
pageView page =
    case page of
        PageNotFound ->
            Ui.Page.container "Error 404" [ text "That means we couldn’t find this page." ]

        HomePage homePageState ->
            Html.map HomePageMsg (HomePage.view homePageState)

        NewPostPage newPostPageState ->
            Html.map NewPostPageMsg (NewPostPage.view newPostPageState)

        ShowPostPage showPostPageState ->
            Html.map ShowPostPageMsg (ShowPostPage.view showPostPageState)

        LoginPage loginPageState ->
            Html.map LoginPageMsg (LoginPage.view loginPageState)

        RegisterPage registerPageState ->
            Html.map RegisterPageMsg (RegisterPage.view registerPageState)

        AboutPage ->
            Ui.Page.container "About" [ text "Welcome to Facepalm. A place to meet weird people while keeping all your personal data safe." ]


view : State -> Document Msg



--view ({ page, session, ui } as state) =


view { page, session, ui } =
    { title = "Welcome to Facepalm"
    , body =
        [ Bulma.Layout.section NotSpaced
            []
            [ Html.map UiMsg (Ui.navbar ui session)
            , Html.map PageMsg (pageView page)

            --            , text (Debug.toString state)
            ]
        ]
    }
