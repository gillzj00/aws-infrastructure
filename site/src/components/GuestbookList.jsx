import { useState, useEffect } from "react";
import { apiFetch } from "../lib/api.js";

export default function GuestbookList({ refreshKey }) {
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    setLoading(true);
    apiFetch("/guestbook")
      .then((data) => {
        setEntries(data.entries);
        setError(null);
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [refreshKey]);

  if (loading) return <div className="loading">Loading guestbook...</div>;
  if (error) return <div className="error-message">Failed to load: {error}</div>;

  if (entries.length === 0) {
    return (
      <div className="text-center text-muted mt-1">
        <p>No entries yet. Be the first to sign the guestbook!</p>
      </div>
    );
  }

  return (
    <div>
      {entries.map((entry) => (
        <div key={entry.entryId} className="entry">
          <img
            className="entry-avatar"
            src={entry.avatarUrl}
            alt={`${entry.login}'s avatar`}
          />
          <div>
            <strong>{entry.login}</strong>
            <div className="entry-meta">
              {new Date(entry.createdAt).toLocaleDateString("en-US", {
                year: "numeric",
                month: "short",
                day: "numeric",
                hour: "2-digit",
                minute: "2-digit",
              })}
            </div>
            <div className="entry-message">{entry.message}</div>
          </div>
        </div>
      ))}
    </div>
  );
}
