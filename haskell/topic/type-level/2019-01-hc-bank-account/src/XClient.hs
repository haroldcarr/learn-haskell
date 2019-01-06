{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE TypeFamilies          #-}

module XClient where

import           XTypes
------------------------------------------------------------------------------
import           Protolude

-- | For servers to send messages to clients.
class XSendClient m sm v where
  sendClient :: ClientId -> ClientResponse sm v -> m ()

-- | For servers to receive messages from clients.
class Show (XRecvClientError m v) => XRecvClient m v where
  type XRecvClientError m v
  receiveClient :: m (Either (XRecvClientError m v) (ClientRequest v))

data ClientRequest v
  = CreqUsernamePassword ClientId UsernamePassword
  | CreqPin              ClientId Pin
  | CreqAcctNumOrQuit    ClientId AccNumOrQuit
  deriving Show

data UsernamePassword = UsernamePassword
  { upUsername :: Text
  , upPassword :: Text
  } deriving Show

newtype Pin = Pin
  { pPin :: Text
  } deriving Show

newtype AccNumOrQuit = AccNumOrQuit
  { anoqAcctNumOrQuit :: Text
  } deriving Show

data ClientResponse s v
  = CresStateMachine s
  | CresEnterUsernamePassword
  | CresInvalidUserNamePassword
  | CresEnterPin
  | CresInvalidPin
  | CresEnterAcctNumOrQuit Text
  | CresInvalidAcctNum
  | CresAcctBalance v
  | CresQuit
  deriving Show
