export default function UserInfo({ user }) {
  return (
    <div className="user-info">
      <img
        className="user-avatar"
        src={user.avatar_url}
        alt={`${user.login}'s avatar`}
      />
      <span className="user-login">{user.login}</span>
    </div>
  );
}
