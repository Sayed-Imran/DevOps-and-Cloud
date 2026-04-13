import React, { useState, useEffect, useCallback } from 'react';
import { getNotes, createNote, updateNote, deleteNote } from '../api';
import NoteForm from './NoteForm';

export default function Notes({ onLogout }) {
    const [notes, setNotes] = useState([]);
    const [showForm, setShowForm] = useState(false);
    const [editingNote, setEditingNote] = useState(null);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(true);

    const fetchNotes = useCallback(async () => {
        try {
            const res = await getNotes();
            setNotes(res.data);
        } catch (err) {
            if (err.response?.status === 401) {
                onLogout();
            } else {
                setError('Failed to load notes.');
            }
        } finally {
            setLoading(false);
        }
    }, [onLogout]);

    useEffect(() => {
        fetchNotes();
    }, [fetchNotes]);

    const handleCreate = async (noteData) => {
        setError('');
        try {
            await createNote(noteData);
            setShowForm(false);
            fetchNotes();
        } catch {
            setError('Failed to create note.');
        }
    };

    const handleUpdate = async (noteData) => {
        setError('');
        try {
            await updateNote(editingNote.id, noteData);
            setEditingNote(null);
            fetchNotes();
        } catch {
            setError('Failed to update note.');
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Delete this note?')) return;
        setError('');
        try {
            await deleteNote(id);
            setNotes((prev) => prev.filter((n) => n.id !== id));
        } catch {
            setError('Failed to delete note.');
        }
    };

    const formatDate = (iso) =>
        new Date(iso).toLocaleString(undefined, {
            dateStyle: 'medium',
            timeStyle: 'short',
        });

    return (
        <div className="notes-layout">
            <div className="notes-header">
                <h1>My Notes</h1>
                <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                    {!showForm && !editingNote && (
                        <button
                            className="btn btn-secondary"
                            onClick={() => setShowForm(true)}
                        >
                            + New Note
                        </button>
                    )}
                    <button className="btn btn-danger btn-sm" onClick={onLogout}>
                        Logout
                    </button>
                </div>
            </div>

            {error && <div className="alert alert-error">{error}</div>}

            {showForm && (
                <NoteForm onSave={handleCreate} onCancel={() => setShowForm(false)} />
            )}

            {loading && <p style={{ color: '#999' }}>Loading…</p>}

            {!loading && notes.length === 0 && !showForm && (
                <p className="empty-state">No notes yet. Create your first one!</p>
            )}

            {notes.map((note) =>
                editingNote?.id === note.id ? (
                    <NoteForm
                        key={note.id}
                        note={note}
                        onSave={handleUpdate}
                        onCancel={() => setEditingNote(null)}
                    />
                ) : (
                    <div className="note-card" key={note.id}>
                        <div className="note-card-header">
                            <div>
                                <h3>{note.title}</h3>
                                <p>{note.content}</p>
                                <p className="note-meta">Updated {formatDate(note.updated_at)}</p>
                            </div>
                            <div className="note-card-actions">
                                <button
                                    className="btn btn-secondary btn-sm"
                                    onClick={() => {
                                        setShowForm(false);
                                        setEditingNote(note);
                                    }}
                                >
                                    Edit
                                </button>
                                <button
                                    className="btn btn-danger btn-sm"
                                    onClick={() => handleDelete(note.id)}
                                >
                                    Delete
                                </button>
                            </div>
                        </div>
                    </div>
                )
            )}
        </div>
    );
}
