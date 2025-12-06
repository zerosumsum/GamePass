"use client";

import React from "react";
import { useWallet } from "@/src/context/WalletContext";

export const WalletInfoDisplay: React.FC = () => {
  const { address, balance, isConnected, disconnectWallet, switchNetwork, isCorrectNetwork } = useWallet();

  if (!isConnected || !address) {
    return null;
  }

  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  return (
    <div className="flex flex-col gap-4 p-4 border border-gray-200 rounded-lg">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-600">Connected Wallet</p>
          <p className="font-mono text-sm">{formatAddress(address)}</p>
        </div>
        <button
          onClick={disconnectWallet}
          className="px-4 py-2 text-sm text-red-600 border border-red-300 rounded hover:bg-red-50"
        >
          Disconnect
        </button>
      </div>
      
      <div>
        <p className="text-sm text-gray-600">Balance</p>
        <p className="text-lg font-semibold">{formatBalance(balance)} CELO</p>
      </div>

      {!isCorrectNetwork && (
        <button
          onClick={switchNetwork}
          className="w-full px-4 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600"
        >
          Switch to Celo Sepolia
        </button>
      )}
    </div>
  );
};

