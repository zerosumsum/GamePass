"use client";

import React, { createContext, useContext, useState, useEffect, ReactNode } from "react";
import { createThirdwebClient } from "thirdweb";
import { connect, disconnect } from "thirdweb/wallets";
import { defineChain } from "thirdweb/chains";

// Celo Sepolia chain configuration
const CELO_SEPOLIA_CHAIN_ID = 11142220;

export const celoSepoliaChain = defineChain({
  id: CELO_SEPOLIA_CHAIN_ID,
  name: "Celo Sepolia",
  nativeCurrency: {
    name: "CELO",
    symbol: "CELO",
    decimals: 18,
  },
  rpc: "https://sepolia-forno.celo.org",
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

  const client = createThirdwebClient({ clientId });

