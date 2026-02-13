import { useAuth } from "../hooks/useAuth.jsx";
import { getLoginUrl } from "../lib/api.js";
import UserInfo from "./UserInfo.jsx";

export default function Header() {
  const { user, loading, logout } = useAuth();

  return (
    <header className="header">
      <div className="header-title">
        <span className="badge">forfun</span>
        <h1>Guestbook</h1>
      </div>

      <div>
        {loading ? null : user ? (
          <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
            <UserInfo user={user} />
            <button className="btn btn-danger" onClick={logout}>
              Logout
            </button>
          </div>
        ) : (
          <a className="btn" href={getLoginUrl()}>
            Sign in with GitHub
          </a>
        )}
      </div>
    </header>
  );
}
