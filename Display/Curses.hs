module Display.Curses
  (displayId, startup, shutdown,
   display, nextEvent, setBG, setFG, Session,
   white, black, yellow, blue, magenta, red, green, attr, Display.Curses.Attr) where

import UI.HSCurses.Curses as C
import qualified UI.HSCurses.CursesHelper as C
import Data.List as L
import Data.Map as M
import Data.Char
import qualified Data.ByteString as BS

import Geometry

displayId = "curses"

data Session =
  Session
    { win :: Window,
      styles :: Map (Maybe AttrColor, Maybe AttrColor) C.CursesStyle }

startup :: (Session -> IO ()) -> IO ()
startup k =
  do
    C.start
    C.startColor
    cursSet CursorInvisible
    nr <- colorPairs
    let s = [ ((f,b), C.Style (toFColor f) (toBColor b))
            | f <- Nothing : L.map Just [minBound..maxBound],
              b <- Nothing : L.map Just [minBound..maxBound] ]
    let (ks, vs) = unzip (tail s)  -- drop the Nothing/Nothing combo
    ws <- C.convertStyles (take (nr - 1) vs)
    k (Session C.stdScr (M.fromList (zip ks ws)))

shutdown :: Session -> IO ()
shutdown w = C.end

display :: Area -> Session -> (Loc -> (Display.Curses.Attr, Char)) -> String -> String -> IO ()
display ((y0,x0),(y1,x1)) (Session { win = w, styles = s }) f msg status =
  do
    erase
    mvWAddStr w 0 0 msg
    sequence_ [ let (a,c) = f (y,x) in C.setStyle (findWithDefault C.defaultCursesStyle a s) >> mvWAddStr w (y+1) x [c]
              | x <- [x0..x1], y <- [y0..y1] ]
    mvWAddStr w (y1+2) 0 status
    refresh
{-
    in  V.update vty (Pic NoCursor 
         ((renderBS attr (BS.pack (L.map (fromIntegral . ord) (toWidth (x1-x0+1) msg)))) <->
          img <-> 
          (renderBS attr (BS.pack (L.map (fromIntegral . ord) (toWidth (x1-x0+1) status))))))
-}

{-
toWidth :: Int -> String -> String
toWidth n x = take n (x ++ repeat ' ')
-}

nextEvent :: Session -> IO String
nextEvent session =
  do
    e <- C.getKey refresh
    case e of
      C.KeyChar '<' -> return "less"
      C.KeyChar '>' -> return "greater"
      C.KeyChar '.' -> return "period"
      C.KeyChar ':' -> return "colon"
      C.KeyChar ',' -> return "comma"
      C.KeyChar ' ' -> return "space"
      C.KeyChar '\ESC' -> return "Escape"
      C.KeyChar c   -> return [c]
      C.KeyExit     -> return "Escape"
      _             -> nextEvent session

type Attr = (Maybe AttrColor, Maybe AttrColor)

attr = (Nothing, Nothing)

data AttrColor = White | Black | Yellow | Blue | Magenta | Red | Green 
  deriving (Show, Eq, Ord, Enum, Bounded)

toFColor :: Maybe AttrColor -> C.ForegroundColor
toFColor (Just White)    = C.WhiteF
toFColor (Just Black)    = C.BlackF
toFColor (Just Yellow)   = C.BrownF
toFColor (Just Blue)     = C.DarkBlueF
toFColor (Just Magenta)  = C.PurpleF
toFColor (Just Red)      = C.DarkRedF
toFColor (Just Green)    = C.DarkGreenF
toFColor Nothing         = C.DefaultF

toBColor :: Maybe AttrColor -> C.BackgroundColor
toBColor (Just White)    = C.WhiteB
toBColor (Just Black)    = C.BlackB
toBColor (Just Yellow)   = C.BrownB
toBColor (Just Blue)     = C.DarkBlueB
toBColor (Just Magenta)  = C.PurpleB
toBColor (Just Red)      = C.DarkRedB
toBColor (Just Green)    = C.DarkGreenB
toBColor Nothing         = C.DefaultB

white   = White
black   = Black
yellow  = Yellow
blue    = Blue
magenta = Magenta
red     = Red
green   = Green

setFG c (_, b) = (Just c, b)
setBG c (f, b) = (f, Just c)