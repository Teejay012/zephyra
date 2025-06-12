import DashboardLayout from '@/components/dashboardBase/DashboardLayout';


export default function layout({ children }) {
  return (
    <div>
      <DashboardLayout>{children}</DashboardLayout>
    </div>
  )
}