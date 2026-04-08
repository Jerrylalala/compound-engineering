import React, { useState, useEffect } from 'react';

interface User {
  id: number;
  name: string;
  email: string;
  avatarUrl: string;
}

interface UserProfileProps {
  userId: number;
}

function UserProfile({ userId }: UserProfileProps) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    // 问题 1：没有 AbortController
    // 问题 2：没有 cleanup 函数
    // 问题 3：快速切换 userId 时，旧请求的回调可能在新请求之后到达
    fetch(`/api/users/${userId}`)
      .then(res => {
        if (!res.ok) throw new Error('Failed to fetch');
        return res.json();
      })
      .then(data => {
        // 问题 4：组件可能已卸载，此时调用 setState 会导致内存泄漏
        setUser(data);
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  }, [userId]);

  if (loading) return <div className="spinner">Loading...</div>;
  if (error) return <div className="error">{error}</div>;
  if (!user) return null;

  return (
    <div className="user-profile">
      <img src={user.avatarUrl} alt={user.name} />
      <h2>{user.name}</h2>
      <p>{user.email}</p>
    </div>
  );
}

// 同一页面中快速切换用户的父组件
function UserList() {
  const [selectedUserId, setSelectedUserId] = useState(1);

  return (
    <div>
      <nav>
        {[1, 2, 3, 4, 5].map(id => (
          <button key={id} onClick={() => setSelectedUserId(id)}>
            User {id}
          </button>
        ))}
      </nav>
      {/* 快速点击按钮时，UserProfile 会快速 mount/unmount 或 re-render */}
      <UserProfile userId={selectedUserId} />
    </div>
  );
}

export default UserList;
