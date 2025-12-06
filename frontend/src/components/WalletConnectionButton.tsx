"use client";

import React from "react";

interface WalletConnectionButtonProps {
  walletId: string;
  walletName: string;
  icon?: string;
  onClick: () => void;
  isConnecting?: boolean;
}

export const WalletConnectionButton: React.FC<WalletConnectionButtonProps> = ({
  walletName,
  icon,
  onClick,
  isConnecting = false,
}) => {
  return (
    <button
      onClick={onClick}
      disabled={isConnecting}
      className="flex items-center justify-center gap-3 px-6 py-3 rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
    >
      {icon && <span>{icon}</span>}
      <span>{walletName}</span>
      {isConnecting && <span className="text-sm text-gray-500">Connecting...</span>}
    </button>
  );
};

