{-# LANGUAGE MultiWayIf        #-}
{-# LANGUAGE OverloadedStrings #-}

module TransportUDP
  (startNodeComm)
where

import           Logging                   (consensusFollower)

import           Control.Concurrent        (forkIO, takeMVar)
import           Data.ByteString           as BS (isPrefixOf)
import           Data.Monoid               ((<>))
import           Network.Multicast         as NM (multicastReceiver,
                                                  multicastSender)
import           Network.Socket            as N (PortNumber, Socket,
                                                 withSocketsDo)
import           Network.Socket.ByteString as N (recvFrom, sendTo)
import           System.Log.Logger         (infoM)

startNodeComm httpToConsensus host port = do
  infoN host port "startNodeComm: ENTER"
  startRcvComm host port
  startSndComm httpToConsensus host port
  infoN host port "startNodeComm: EXIT"

startRcvComm host port = withSocketsDo $ do
  infoN host port "startRcvComm: ENTER"
  sock <- multicastReceiver host port
  forkIO $ rec host port sock
  infoN host port "startRcvComm: EXIT"

rec host port sock = do
  infoN host port "rec: waiting"
  (msg,addr) <- N.recvFrom sock 1024
  infoN host port  ("rec: from: " <> show addr <> " " <> show msg)
  if | BS.isPrefixOf "{\"appendEntry\":" msg -> infoN host port "APPENDENTRY"
     | otherwise                             -> infoN host port "NO"
  rec host port sock

startSndComm httpToConsensus host port = withSocketsDo $ do
  infoN host port "startSndComm: ENTER"
  (sock, addr) <- multicastSender host port
  forkIO $ send httpToConsensus host port sock addr
  infoN host port "startSndComm: EXIT"

-- Read from httpToConsensus and broadcast
send httpToConsensus host port sock addr = do
  infoN host port "send: waiting"
  msg <- takeMVar httpToConsensus
  infoN host port ("send: " ++ show msg)
  sendTo sock msg addr
  send httpToConsensus host port sock addr

infoN h p msg = infoM consensusFollower ("N " <> h <> ":" <> show p <> " " <> msg)


