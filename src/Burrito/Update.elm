module Burrito.Update exposing (Update, addCmd, andAddCmd, andMap, andThen, ap, join, kleisli, map, map2, map3, map4, map5, map6, map7, mapCmd, run, run2, run3, save, sequence)


type alias Update a m =
    ( a, List (Cmd m) )


save : a -> Update a m
save model =
    ( model, [] )


ap : Update (a -> b) m -> Update a m -> Update b m
ap ( f, cmds1 ) ( model, cmds2 ) =
    ( f model, cmds1 ++ cmds2 )


map : (a -> b) -> Update a m -> Update b m
map f ( model, cmds ) =
    ( f model, cmds )


map2 : (p -> q -> r) -> Update p m -> Update q m -> Update r m
map2 f =
    ap << map f


map3 : (p -> q -> r -> s) -> Update p m -> Update q m -> Update r m -> Update s m
map3 f a =
    ap << map2 f a


map4 : (p -> q -> r -> s -> t) -> Update p m -> Update q m -> Update r m -> Update s m -> Update t m
map4 f a b =
    ap << map3 f a b


map5 : (p -> q -> r -> s -> t -> u) -> Update p m -> Update q m -> Update r m -> Update s m -> Update t m -> Update u m
map5 f a b c =
    ap << map4 f a b c


map6 : (p -> q -> r -> s -> t -> u -> v) -> Update p m -> Update q m -> Update r m -> Update s m -> Update t m -> Update u m -> Update v m
map6 f a b c d =
    ap << map5 f a b c d


map7 : (p -> q -> r -> s -> t -> u -> v -> w) -> Update p m -> Update q m -> Update r m -> Update s m -> Update t m -> Update u m -> Update v m -> Update w m
map7 f a b c d e =
    ap << map6 f a b c d e


andMap : Update a m -> Update (a -> b) m -> Update b m
andMap a b =
    ap b a


join : Update (Update a m) m -> Update a m
join ( ( model, cmds1 ), cmds2 ) =
    ( model, cmds1 ++ cmds2 )


andThen : (b -> Update a m) -> Update b m -> Update a m
andThen fun =
    join << map fun


kleisli : (b -> Update d m) -> (a -> Update b m) -> a -> Update d m
kleisli f g =
    andThen f << g


sequence : List (a -> Update a m) -> a -> Update a m
sequence list model =
    List.foldr andThen (save model) list


addCmd : Cmd m -> a -> Update a m
addCmd cmd model =
    ( model, [ cmd ] )


mapCmd : (ma -> mb) -> Update a ma -> Update a mb
mapCmd f ( model, cmds ) =
    ( model, List.map (Cmd.map f) cmds )


andAddCmd : Cmd m -> Update a m -> Update a m
andAddCmd =
    andThen << addCmd


exec : Update a m -> ( a, Cmd m )
exec ( model, cmds ) =
    ( model, Cmd.batch cmds )


run : (p -> Update a m) -> p -> ( a, Cmd m )
run f =
    exec << f


run2 : (p -> q -> Update a m) -> p -> q -> ( a, Cmd m )
run2 f a =
    exec << f a


run3 : (p -> q -> r -> Update a m) -> p -> q -> r -> ( a, Cmd m )
run3 f a b =
    exec << f a b
