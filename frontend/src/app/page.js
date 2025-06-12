import Hero from "@/components/hero/Hero";
import HowItWorks from "@/components/howitworks/HowItWorks";
import KeyFeatures from "@/components/keyfeatures/KeyFeatures";
import LiveStats from "@/components/liveStats/LiveStats";
import CommunityCTA from "@/components/communityCta/CommunityCTA";

export default function Home() {
  return (
    <div>
      <Hero />
      <HowItWorks />
      <KeyFeatures />
      <LiveStats />
      <CommunityCTA />
    </div>
  );
}
