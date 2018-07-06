{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
module Data.Winery.Query.Parser (parseQuery) where

import Prelude hiding ((.), id)
import Control.Category
import Data.Winery.Query
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import qualified Data.Text as T
import Data.Text.Prettyprint.Doc (Doc, hsep)
import Data.Typeable
import Data.Void

type Parser = Parsec Void T.Text

symbol :: T.Text -> Parser T.Text
symbol = L.symbol space

name :: Parser T.Text
name = fmap T.pack (some (alphaNumChar <|> oneOf ("_\'" :: [Char])) <?> "field name")

parseQuery :: Typeable a => Parser (Query (Doc a) (Doc a))
parseQuery = foldr (.) id <$> sepBy1 parseTerms (symbol "|")

parseTerms :: Typeable a => Parser (Query (Doc a) (Doc a))
parseTerms = fmap hsep . sequenceA <$> sepBy1 parseTerm space

parseTerm :: Typeable a => Parser (Query (Doc a) (Doc a))
parseTerm = L.lexeme space $ choice
  [ char '.' >> choice
    [ do
      _ <- char '['
      i <- optional L.decimal
      j <- optional (symbol ":" >> L.decimal)
      _ <- char ']'
      return $ range (maybe 0 id i) (maybe (-1) id j)
    , field <$> name
    , return id
    ]
  ]
