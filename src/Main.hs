{-# LANGUAGE OverloadedStrings #-}
module Main where

import Prelude hiding (drop)
import Control.Concurrent (forkIO)
import Control.Exception (finally, fromException)
import Control.Monad.Trans (liftIO)
import Data.ByteString.Char8 (unpack, split, drop)
import Network (connectTo, PortID(..))
import System.Environment (getArgs)
import System.IO (hClose, hSetBuffering, Handle, BufferMode(..))
import qualified Data.ByteString as B
import qualified Network.WebSockets as WS

mkConnection :: B.ByteString -> IO Handle
mkConnection path = connectTo host (PortNumber port)
  where
    parse = map unpack . split '/' . drop 1
    host  = let host':_   = parse path in host'
    port  = let _:port':_ = parse path in fromIntegral (read port' :: Int)
    
application :: WS.Request -> WS.WebSockets WS.Hybi10 ()
application request = do
    handle <- liftIO $ mkConnection (WS.requestPath request)
    liftIO $ hSetBuffering handle NoBuffering
    WS.acceptRequest request
    sink <- WS.getSink
    _ <- liftIO
       $ forkIO
       $ doTcpWs handle sink `finally` hClose handle >> return ()
    doWsTcp handle
  where
    doTcpWs handle sink = do
        message <- B.hGetSome handle 4096
        if (B.null message)
            then WS.sendSink sink $ WS.close ("closed" :: B.ByteString)
            else do
                WS.sendSink sink (WS.textData message)
                doTcpWs handle sink
    doWsTcp handle = flip WS.catchWsError (catchDisconnect handle) $ do
        message <- WS.receiveData
        liftIO (B.hPut handle message)
        doWsTcp handle
    catchDisconnect handle e = case fromException e of
        Just WS.ConnectionClosed -> liftIO (hClose handle)
        _                        -> return ()
            
main :: IO ()
main = do
    [iface, port'] <- getArgs
    let port = fromIntegral (read port' :: Int)
    putStrLn $ "Listening on " ++ iface ++ ":" ++ show port
    WS.runServer iface port $ application
