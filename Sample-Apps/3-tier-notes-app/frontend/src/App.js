import React, { useState } from 'react';
import Login from './components/Login';
import Register from './components/Register';
import Notes from './components/Notes';

export default function App() {
    const [token, setToken] = useState(() => localStorage.getItem('token'));
    const [view, setView] = useState('login'); // 'login' | 'register'

    const handleLogin = (tok) => {
        localStorage.setItem('token', tok);
        setToken(tok);
    };

    const handleLogout = () => {
        localStorage.removeItem('token');
        setToken(null);
        setView('login');
    };

    if (token) {
        return <Notes onLogout={handleLogout} />;
    }

    if (view === 'register') {
        return (
            <Register
                onRegistered={handleLogin}
                onShowLogin={() => setView('login')}
            />
        );
    }

    return (
        <Login
            onLogin={handleLogin}
            onShowRegister={() => setView('register')}
        />
    );
}
