"use client";

import React, { createContext, useContext, useState, useEffect, ReactNode, useMemo } from "react";
import { createThirdwebClient } from "thirdweb";
import { useActiveAccount, useActiveWallet, useDisconnect, useConnectionStatus } from "thirdweb/react";
import { connect } from "thirdweb/wallets";
import { defineChain } from "thirdweb/chains";
import { getBalance } from "thirdweb/extensions/erc20";
import { toEther } from "thirdweb/utils";

// Celo Sepolia chain configuration
export const CELO_SEPOLIA_CHAIN_ID = 11142220;

export const celoSepoliaChain = defineChain({
  id: CELO_SEPOLIA_CHAIN_ID,
  name: "Celo Sepolia",
  nativeCurrency: {
    name: "CELO",
    symbol: "CELO",
    decimals: 18,
  },
  rpc: "https://sepolia-forno.celo.org",
  testnet: true,
});

interface WalletContextType {
  address: string | undefined;
  balance: string;
  chainId: number | undefined;
  isConnected: boolean;
  isConnecting: boolean;
  error: string | null;
  connectWallet: (walletId: string) => Promise<void>;
  disconnectWallet: () => Promise<void>;
  switchNetwork: () => Promise<void>;
  isCorrectNetwork: boolean;
}

const WalletContext = createContext<WalletContextType | undefined>(undefined);

export const useWallet = () => {
  const context = useContext(WalletContext);
  if (!context) {
    throw new Error("useWallet must be used within WalletProvider");
  }
  return context;
};

interface WalletProviderProps {
  children: ReactNode;
  clientId: string;
}

export const WalletProvider: React.FC<WalletProviderProps> = ({ children, clientId }) => {
  const [address, setAddress] = useState<string | undefined>();
  const [balance, setBalance] = useState<string>("0");
  const [chainId, setChainId] = useState<number | undefined>();
  const [isConnected, setIsConnected] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const client = useMemo(() => createThirdwebClient({ clientId }), [clientId]);
  
  const activeAccount = useActiveAccount();
  const activeWallet = useActiveWallet();
  const disconnectWalletHook = useDisconnect();
  const connectionStatus = useConnectionStatus();

  // Update state based on active account
  useEffect(() => {
    if (activeAccount) {
      setAddress(activeAccount.address);
      setIsConnected(true);
      setError(null);
    } else {
      setAddress(undefined);
      setIsConnected(false);
      setBalance("0");
    }
  }, [activeAccount]);

  // Update chain ID when wallet changes
  useEffect(() => {
    if (activeWallet?.getChain) {
      activeWallet.getChain().then((chain) => {
        setChainId(chain?.id);
      }).catch(() => {
        setChainId(undefined);
      });
    } else {
      setChainId(undefined);
    }
  }, [activeWallet]);

  // Update connection status
  useEffect(() => {
    setIsConnecting(connectionStatus === "connecting");
  }, [connectionStatus]);

  // Check if connected to correct network
  const isCorrectNetwork = useMemo(() => {
    return chainId === CELO_SEPOLIA_CHAIN_ID;
  }, [chainId]);

  // Fetch balance when address or chainId changes
  useEffect(() => {
    const fetchBalance = async () => {
      if (!address || !chainId || !isConnected) {
        setBalance("0");
        return;
      }

      try {
        if (activeAccount) {
          // Fetch native CELO balance
          const balanceResult = await activeAccount.fetchBalance({
            chain: celoSepoliaChain,
          });
          const balanceInEther = toEther(balanceResult.value);
          setBalance(balanceInEther);
        }
      } catch (err: any) {
        console.error("Error fetching balance:", err);
        setBalance("0");
      }
    };

    if (isConnected && address) {
      fetchBalance();
      // Refresh balance every 10 seconds
      const interval = setInterval(fetchBalance, 10000);
      return () => clearInterval(interval);
    }
  }, [address, chainId, isConnected, activeAccount]);

  const connectWallet = async (walletId: string) => {
    setIsConnecting(true);
    setError(null);

    try {
      const wallet = connect({
        client,
        strategy: walletId as any,
        chain: celoSepoliaChain,
      });

      await wallet;
    } catch (err: any) {
      setError(err.message || "Failed to connect wallet");
      setIsConnected(false);
    } finally {
      setIsConnecting(false);
    }
  };

  const disconnectWallet = async () => {
    try {
      await disconnectWalletHook();
      setAddress(undefined);
      setBalance("0");
      setChainId(undefined);
      setIsConnected(false);
      setError(null);
    } catch (err: any) {
      setError(err.message || "Failed to disconnect wallet");
    }
  };

  const switchNetwork = async () => {
    if (!activeWallet) {
      setError("No wallet connected");
      return;
    }

    try {
      setError(null);
      await activeWallet.switchChain(celoSepoliaChain);
    } catch (err: any) {
      setError(err.message || "Failed to switch network. Please switch to Celo Sepolia manually.");
    }
  };

  return (
    <WalletContext.Provider
      value={{
        address,
        balance,
        chainId,
        isConnected,
        isConnecting,
        error,
        connectWallet,
        disconnectWallet,
        switchNetwork,
        isCorrectNetwork,
      }}
    >
      {children}
    </WalletContext.Provider>
  );
};
