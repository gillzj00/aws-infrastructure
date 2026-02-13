import { useState, useEffect } from "react";
import { apiFetch } from "../lib/api.js";

export default function GuestbookList({ refreshKey, user, onDeleted }) {
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [deletingId, setDeletingId] = useState(null);

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

  async function handleDelete(entryId) {
    if (!window.confirm("Are you sure you want to delete this entry?")) return;

    setDeletingId(entryId);
    try {
      await apiFetch(`/guestbook/${entryId}`, { method: "DELETE" });
      onDeleted();
    } catch (err) {
      alert(err.message);
    } finally {
      setDeletingId(null);
    }
  }

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
          <div style={{ flex: 1 }}>
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
          {user?.login === entry.login && (
            <button
              className="btn btn-danger"
              style={{ alignSelf: "flex-start", fontSize: "0.8rem", padding: "0.3rem 0.6rem" }}
              onClick={() => handleDelete(entry.entryId)}
              disabled={deletingId === entry.entryId}
            >
              {deletingId === entry.entryId ? "Deleting…" : "Delete"}
            </button>
          )}
        </div>
      ))}
    </div>
  );
}
