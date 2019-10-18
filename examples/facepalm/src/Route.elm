module Route exposing (Route(..), fromUrl, parser)

import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, int, map, oneOf, parse, s, top)


type Route
    = Home
    | Login
    | Logout
    | Register
    | About
    | NewPost
    | ShowPost Int


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home top
        , map Login (s "login")
        , map Logout (s "logout")
        , map Register (s "register")
        , map About (s "about")
        , map NewPost (s "posts" </> s "new")
        , map ShowPost (s "posts" </> int)
        ]


fromUrl : Url -> Maybe Route
fromUrl =
    parse parser
