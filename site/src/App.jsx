import { useState } from "react";
import Header from "./components/Header.jsx";
import GuestbookForm from "./components/GuestbookForm.jsx";
import GuestbookList from "./components/GuestbookList.jsx";

export default function App() {
  // refreshKey triggers GuestbookList to refetch after a new entry is signed
  const [refreshKey, setRefreshKey] = useState(0);

  return (
    <div className="container">
      <Header />
      <GuestbookForm onSigned={() => setRefreshKey((k) => k + 1)} />
      <div className="card">
        <GuestbookList refreshKey={refreshKey} />
      </div>
    </div>
  );
}
