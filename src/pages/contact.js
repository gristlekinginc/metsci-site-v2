// src/pages/contact.js
// Contact form page for Docusaurus site
// This file creates a contact form at /contact

import React, { useState } from 'react';
import Layout from '@theme/Layout';
import { Turnstile } from '@marsidev/react-turnstile';

export default function Contact() {
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [token, setToken] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);

    if (!token) {
      setError('Please complete the security check.');
      return;
    }

    setLoading(true);

    const formData = new FormData(e.target);
    const data = {
      name: formData.get('name'),
      email: formData.get('email'),
      message: formData.get('message'),
      website: formData.get('website'), // honeypot
      'cf-turnstile-response': token,
    };

    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (response.ok) {
        setSubmitted(true);
      } else {
        const text = await response.text();
        setError('There was a problem sending your message: ' + text);
      }
    } catch (err) {
      setError('There was a problem sending your message.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Layout title="Contact Us">
      {/* Responsive styles for the contact form */}
      <style>{`
        .metsci-contact-container {
          max-width: 700px;
          width: 90%;
          margin: 3rem auto;
          padding: 2.5rem 2rem;
          background: #FCF5F0;
          border-radius: 18px;
          box-shadow: 0 4px 24px #0001;
        }
        .metsci-contact-title {
          color: #D94A18;
          font-size: 2.3rem;
          font-weight: 700;
          margin-bottom: 2rem;
          text-align: center;
        }
        .metsci-contact-label {
          font-weight: 600;
          margin-bottom: 0.5rem;
          display: block;
          color: #000;
        }
        .metsci-contact-input, .metsci-contact-textarea {
          width: 100%;
          padding: 0.9rem 1rem;
          border-radius: 7px;
          border: 1.5px solid #ccc;
          font-size: 1.1rem;
          margin-bottom: 1.5rem;
          background: #fff;
          transition: border-color 0.2s;
        }
        .metsci-contact-input:focus, .metsci-contact-textarea:focus {
          border-color: #18A7D9;
          outline: none;
        }
        .metsci-contact-button {
          background: #D94A18;
          color: #FCF5F0;
          padding: 1rem 2.5rem;
          border: none;
          border-radius: 7px;
          cursor: pointer;
          font-weight: bold;
          font-size: 1.1rem;
          margin-top: 0.5rem;
          transition: background 0.2s;
        }
        .metsci-contact-button:disabled {
          background: #FA7F2A;
          cursor: not-allowed;
        }
        .metsci-contact-error {
          color: #D94A18;
          margin-bottom: 1rem;
          text-align: center;
        }
        .metsci-contact-success {
          color: #18A7D9;
          text-align: center;
          font-size: 1.2rem;
        }
        @media (max-width: 600px) {
          .metsci-contact-container {
            padding: 1.2rem 0.5rem;
          }
          .metsci-contact-title {
            font-size: 1.5rem;
          }
        }
      `}</style>
      <div className="metsci-contact-container">
        <h1 className="metsci-contact-title">Contact Us</h1>
        {submitted ? (
          <p className="metsci-contact-success">Thank you for your message! We will get back to you soon.</p>
        ) : (
          <form onSubmit={handleSubmit} autoComplete="off">
            <label htmlFor="name" className="metsci-contact-label">Name</label>
            <input type="text" id="name" name="name" required className="metsci-contact-input" />

            <label htmlFor="email" className="metsci-contact-label">Email</label>
            <input type="email" id="email" name="email" required className="metsci-contact-input" />

            <label htmlFor="message" className="metsci-contact-label">Message</label>
            <textarea id="message" name="message" required rows={6} className="metsci-contact-textarea" />

            {/* Honeypot field for spam protection */}
            <div style={{ display: 'none' }}>
              <label htmlFor="website">Website</label>
              <input type="text" id="website" name="website" autoComplete="off" tabIndex="-1" />
            </div>
            
            <div style={{ marginBottom: '1.5rem' }}>
              <Turnstile 
                siteKey="0x4AAAAAAB8KJsd9ZQ5hEolp" // Cloudflare Turnstile Site Key
                onSuccess={setToken}
              />
            </div>

            {error && <p className="metsci-contact-error">{error}</p>}
            <button type="submit" className="metsci-contact-button" disabled={loading || !token}>
              {loading ? 'Sending…' : 'Send Message'}
            </button>
          </form>
        )}
      </div>
    </Layout>
  );
} 