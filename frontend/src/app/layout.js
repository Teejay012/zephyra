import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

import { Navbar } from "@/components/navbar/Navbar.jsx";
import { Footer } from "@/components/footer/Footer.jsx";
import { ZephyraProvider } from '@/hooks/contexts/ZephyraProvider';
import { Toaster } from 'react-hot-toast';

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata = {
  title: "Zephyra",
  description: "Created by TeeJay(EtherEngineer)",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <ZephyraProvider>
          <Toaster position="top-right" />
          <Navbar />
          {children}
          <Footer />
        </ZephyraProvider>
      </body>
    </html>
  );
}
