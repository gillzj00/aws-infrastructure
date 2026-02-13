import { useState } from "react";
import { useAuth } from "../hooks/useAuth.jsx";
import { apiFetch, getLoginUrl } from "../lib/api.js";

export default function GuestbookForm({ onSigned }) {
  const { user } = useAuth();
  const [message, setMessage] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  if (!user) {
    return (
      <div className="card text-center" style={{ marginBottom: "1rem" }}>
        <p className="text-muted">
          <a href={getLoginUrl()}>Sign in with GitHub</a> to leave a message
        </p>
      </div>
    );
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!message.trim()) return;

    setSubmitting(true);
    setError(null);

    try {
      await apiFetch("/guestbook", {
        method: "POST",
        body: JSON.stringify({ message: message.trim() }),
      });
      setMessage("");
      onSigned(); // Trigger list refresh
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form className="card" style={{ marginBottom: "1rem" }} onSubmit={handleSubmit}>
      <div className="form-group">
        <textarea
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="Leave a message..."
          maxLength={500}
          disabled={submitting}
        />
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span className="text-muted" style={{ fontSize: "0.8rem" }}>
          {message.length}/500
        </span>
        <button className="btn" type="submit" disabled={submitting || !message.trim()}>
          {submitting ? "Signing..." : "Sign Guestbook"}
        </button>
      </div>
      {error && <div className="error-message">{error}</div>}
    </form>
  );
}
