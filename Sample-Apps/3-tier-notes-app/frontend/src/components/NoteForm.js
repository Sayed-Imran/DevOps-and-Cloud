import React, { useState } from 'react';

export default function NoteForm({ note, onSave, onCancel }) {
    const [title, setTitle] = useState(note?.title || '');
    const [content, setContent] = useState(note?.content || '');

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({ title: title.trim(), content: content.trim() });
    };

    const isEdit = Boolean(note);

    return (
        <div className="note-form-card">
            <h3>{isEdit ? 'Edit Note' : 'New Note'}</h3>
            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <input
                        type="text"
                        placeholder="Title"
                        value={title}
                        onChange={(e) => setTitle(e.target.value)}
                        required
                    />
                </div>
                <div className="form-group">
                    <textarea
                        placeholder="Write your note here…"
                        value={content}
                        onChange={(e) => setContent(e.target.value)}
                        rows={4}
                        required
                    />
                </div>
                <div className="note-form-actions">
                    <button className="btn btn-primary" type="submit" style={{ width: 'auto' }}>
                        {isEdit ? 'Update' : 'Create'}
                    </button>
                    <button className="btn btn-secondary" type="button" onClick={onCancel}>
                        Cancel
                    </button>
                </div>
            </form>
        </div>
    );
}
