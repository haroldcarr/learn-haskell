{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# LANGUAGE LambdaCase                 #-}
{-# LANGUAGE NoMonomorphismRestriction  #-}
{-# LANGUAGE RankNTypes                 #-}

module P3 where

import           Control.Lens         hiding (Lens, Prism, prism)
import qualified Data.Text            as T
import           P0

type Lens  a b = Lens'  a b
type Prism a b = Prism' a b

prism = prism'

-- 25:00

-- for each type

data DbConfig = DbConfig
    { _dbConn   :: DbConnection
    , _dbSchema :: Schema
    }

-- associate a typeclass of optics for that type

class HasDbConfig t where
    dbConfig :: Lens t DbConfig
    dbConn   :: Lens t DbConnection
    dbSchema :: Lens t Schema
    dbConn   =  dbConfig . dbConn -- note: lens compose "in reverse"
    dbSchema =  dbConfig . dbSchema

instance HasDbConfig DbConfig where
    dbConfig = id
    dbConn   = lens _dbConn   (\d c -> d { _dbConn   = c})
    dbSchema = lens _dbSchema (\d s -> d { _dbSchema = s})

data NetworkConfig = NetConfig
    { _port :: Port
    , _ssl  :: SSL
    }

class HasNetworkConfig t where
    netConfig :: Lens t NetworkConfig
    netPort   :: Lens t Port
    netSSL    :: Lens t SSL
    netPort   =  netConfig . netPort
    netSSL    =  netConfig . netSSL

instance HasNetworkConfig NetworkConfig where
    netConfig = id
    netPort   = lens _port (\n p -> n { _port = p})
    netSSL    = lens _ssl  (\n s -> n { _ssl  = s})

data AppConfig = AppConfig
    { appDbConfig  :: DbConfig
    , appNetConfig :: NetworkConfig
    }

instance HasDbConfig AppConfig where
    dbConfig = lens appDbConfig (\app db -> app { appDbConfig = db})

instance HasNetworkConfig AppConfig where
    netConfig = lens appNetConfig (\app net -> app { appNetConfig = net})

-- 32:04

data DbError
    = QueryError T.Text
    | InvalidConnection
    deriving Show

class AsDbError t where
    _DbError     :: Prism t DbError
    _QueryError  :: Prism t T.Text
    _InvalidConn :: Prism t ()
    _QueryError  =  _DbError . _QueryError
    _InvalidConn =  _DbError . _InvalidConn

instance AsDbError DbError where
    _DbError     = id
    _QueryError  = prism QueryError
        $ \case QueryError t -> Just t
                _            -> Nothing
    _InvalidConn = prism (const InvalidConnection)
        $ \case InvalidConnection -> Just ()
                _                 -> Nothing

-- 32:04

data NetworkError
    = Timeout Int
    | ServerOnFire
    deriving Show

class AsNetworkError t where
    _NetworkError :: Prism t NetworkError
    _Timeout      :: Prism t Int
    _ServerOnFire :: Prism t ()
    _Timeout      =  _NetworkError . _Timeout
    _ServerOnFire =  _NetworkError . _ServerOnFire

instance AsNetworkError NetworkError where
    _NetworkError = id
    _Timeout      = prism Timeout
        $ \case Timeout t -> Just t
                _         -> Nothing
    _ServerOnFire = prism (const ServerOnFire)
        $ \case ServerOnFire -> Just ()
                _            -> Nothing

-- 34:00

data AppError
    = AppDbError  { dbError  :: DbError }
    | AppNetError { netError :: NetworkError }
    deriving Show

instance AsDbError AppError where
    _DbError     = prism AppDbError
        $ \case AppDbError dbe -> Just dbe
                _              -> Nothing

instance AsNetworkError AppError where
    _NetworkError = prism AppNetError
        $ \case AppNetError ne -> Just ne
                _              -> Nothing

-- 34:50

-- above boilerplate can be generated automatically:

-- makeClassyPrisms ''NetworkError  -- prism
-- makeClassy       ''DbConig       -- lens

