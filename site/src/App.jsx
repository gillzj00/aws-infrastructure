import { useState } from "react";
import { useAuth } from "./hooks/useAuth.jsx";
import Header from "./components/Header.jsx";
import GuestbookForm from "./components/GuestbookForm.jsx";
import GuestbookList from "./components/GuestbookList.jsx";

export default function App() {
  // refreshKey triggers GuestbookList to refetch after a new entry is signed or deleted
  const [refreshKey, setRefreshKey] = useState(0);
  const { user } = useAuth();
  const refresh = () => setRefreshKey((k) => k + 1);

  return (
    <div className="container">
      <Header />
      <GuestbookForm onSigned={refresh} />
      <div className="card">
        <GuestbookList refreshKey={refreshKey} user={user} onDeleted={refresh} />
      </div>
    </div>
  );
}
