"use client";

import React from "react";
import { ThirdwebProvider } from "thirdweb/react";
import { WalletProvider } from "@/src/context/WalletContext";

const THIRDWEB_CLIENT_ID = process.env.NEXT_PUBLIC_THIRDWEB_CLIENT_ID || "";

export const Providers: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <ThirdwebProvider>
      <WalletProvider clientId={THIRDWEB_CLIENT_ID}>
        {children}
      </WalletProvider>
    </ThirdwebProvider>
  );
};

