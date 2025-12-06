"use client";

import React from "react";
import { useWallet } from "@/src/context/WalletContext";

export const ConnectionStatus: React.FC = () => {
  const { isConnected, isConnecting, error } = useWallet();

  if (!isConnected && !isConnecting && !error) {
    return null;
  }

  return (
    <div className="fixed top-4 right-4 z-50">
      {isConnecting && (
        <div className="px-4 py-2 bg-blue-100 text-blue-800 rounded-lg shadow-lg">
          Connecting to wallet...
        </div>
      )}
      {error && (
        <div className="px-4 py-2 bg-red-100 text-red-800 rounded-lg shadow-lg">
          {error}
        </div>
      )}
      {isConnected && !error && (
        <div className="px-4 py-2 bg-green-100 text-green-800 rounded-lg shadow-lg">
          Wallet connected
        </div>
      )}
    </div>
  );
};

