{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -fno-warn-missing-fields #-}
-- | This module is currently in an identity crisis. Originally called Julius, now being changed to just Javascript (shakespeare-javascript)
module Text.Julius
    ( Julius
    , Javascript (..)
    , ToJavascript (..)
    , renderJulius
    , text
    , textFile
    , textFileDebug
    , textFileDebug
    ) where

import Language.Haskell.TH.Quote (QuasiQuoter (..))
import Language.Haskell.TH.Syntax
import Data.Text.Lazy.Builder (Builder, fromText, toLazyText, fromLazyText)
import Data.Monoid
import qualified Data.Text as TS
import qualified Data.Text.Lazy as TL
import Text.Shakespeare

renderJavascript :: Javascript -> TL.Text
renderJavascript (Javascript b) = toLazyText b

renderJulius :: (url -> [(TS.Text, TS.Text)] -> TS.Text) -> Julius url -> TL.Text
renderJulius r s = renderJavascript $ s r

newtype Javascript = Javascript { unJavascript :: Builder }
    deriving Monoid
type Julius url = (url -> [(TS.Text, TS.Text)] -> TS.Text) -> Javascript

class ToJavascript a where
    toJavascript :: a -> Builder
instance ToJavascript [Char] where toJavascript = fromLazyText . TL.pack
instance ToJavascript TS.Text where toJavascript = fromText
instance ToJavascript TL.Text where toJavascript = fromLazyText

settings :: Q ShakespeareSettings
settings = do
  toJExp <- [|toJavascript|]
  wrapExp <- [|Javascript|]
  unWrapExp <- [|unJavascript|]
  return $ defaultShakespeareSettings { toBuilder = toJExp
  , wrap = wrapExp
  , unwrap = unWrapExp
  }

text :: QuasiQuoter
text = QuasiQuoter { quoteExp = \s -> do
    rs <- settings
    quoteExp (shakespeare rs) s
    }

textFile :: FilePath -> Q Exp
textFile fp = do
    rs <- settings
    shakespeareFile rs fp


textFileDebug :: FilePath -> Q Exp
textFileDebug fp = do
    rs <- settings
    shakespeareFileDebug rs fp
