import React, { useState } from 'react';

export default function DCcalculator() {
  const [payloadBytes, setPayloadBytes] = useState(6);
  const [messagesPerDay, setMessagesPerDay] = useState(24);
  const [packetsPerMessage, setPacketsPerMessage] = useState(6);
  const [results, setResults] = useState(null);

  const costPerDC = 0.0001; // Your custom rate

  const calculate = () => {
    const dcPerMessage = Math.ceil(payloadBytes / 24);
    const totalMessages = packetsPerMessage * messagesPerDay;
    const totalDC = totalMessages * dcPerMessage;
    const dailyCost = totalDC * costPerDC;
    const monthlyCost = dailyCost * 30;
    const yearlyCost = dailyCost * 365;

    setResults({
      dcPerMessage,
      totalDC,
      dailyCost: dailyCost.toFixed(4),
      monthlyCost: monthlyCost.toFixed(2),
      yearlyCost: yearlyCost.toFixed(2),
    });
  };

  return (
    <div style={{ 
      background: 'linear-gradient(135deg, #FA7F2A 0%, #D94A18 50%, #000000 100%)',
      padding: '2rem',
      borderRadius: '12px',
      color: '#FCF5F0',
      boxShadow: '0 8px 24px rgba(0, 0, 0, 0.3)',
      margin: '20px auto',
      maxWidth: '600px'
    }}>
      <h2 style={{ 
        color: '#FCF5F0',
        textAlign: 'center',
        marginBottom: '1.5rem',
        fontSize: '1.5rem',
        fontWeight: 'bold'
      }}>
        MeteoScientific Multi-Buy Cost Calculator
      </h2>
      
      <div style={{ display: 'grid', gap: '1rem', marginBottom: '1.5rem' }}>
        <div>
          <label style={{ 
            display: 'block', 
            marginBottom: '0.5rem', 
            color: '#FCF5F0',
            fontWeight: '500'
          }}>
            Payload Bytes:
          </label>
          <input 
            type="number" 
            value={payloadBytes} 
            onChange={e => setPayloadBytes(Number(e.target.value))}
            style={{
              width: '100%',
              padding: '0.75rem',
              borderRadius: '6px',
              border: '2px solid #18A7D9',
              backgroundColor: '#FCF5F0',
              color: '#000000',
              fontSize: '1rem',
              outline: 'none'
            }}
          />
        </div>
        
        <div>
          <label style={{ 
            display: 'block', 
            marginBottom: '0.5rem', 
            color: '#FCF5F0',
            fontWeight: '500'
          }}> 
            Messages per Day:
          </label>
          <input 
            type="number" 
            value={messagesPerDay} 
            onChange={e => setMessagesPerDay(Number(e.target.value))}
            style={{
              width: '100%',
              padding: '0.75rem',
              borderRadius: '6px',
              border: '2px solid #18A7D9',
              backgroundColor: '#FCF5F0',
              color: '#000000',
              fontSize: '1rem',
              outline: 'none'
            }}
          />
        </div>
        
        <div>
          <label style={{ 
            display: 'block', 
            marginBottom: '0.5rem', 
            color: '#FCF5F0',
            fontWeight: '500'
          }}>
            Multi-Buy:
          </label>
          <input 
            type="number" 
            value={packetsPerMessage} 
            onChange={e => setPacketsPerMessage(Number(e.target.value))}
            style={{
              width: '100%',
              padding: '0.75rem',
              borderRadius: '6px',
              border: '2px solid #18A7D9',
              backgroundColor: '#FCF5F0',
              color: '#000000',
              fontSize: '1rem',
              outline: 'none'
            }}
          />
        </div>
      </div>
      
      <button 
        onClick={calculate}
        style={{
          width: '100%',
          padding: '1rem',
          backgroundColor: '#18A7D9',
          color: '#FCF5F0',
          border: 'none',
          borderRadius: '8px',
          fontSize: '1.1rem',
          fontWeight: 'bold',
          cursor: 'pointer',
          transition: 'all 0.3s ease',
          boxShadow: '0 4px 12px rgba(24, 167, 217, 0.3)'
        }}
        onMouseOver={e => e.target.style.backgroundColor = '#1595c4'}
        onMouseOut={e => e.target.style.backgroundColor = '#18A7D9'}
      >
        Calculate Costs
      </button>

      {results && (
        <div style={{ 
          marginTop: '1.5rem',
          padding: '1.5rem',
          backgroundColor: 'rgba(252, 245, 240, 0.1)',
          borderRadius: '8px',
          border: '1px solid rgba(252, 245, 240, 0.2)'
        }}>
          <h3 style={{ 
            color: '#FCF5F0', 
            marginBottom: '1rem',
            textAlign: 'center',
            fontSize: '1.2rem'
          }}>
            Cost Breakdown
          </h3>
          <div style={{ display: 'grid', gap: '0.75rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#FCF5F0' }}>DC per message:</span>
              <strong style={{ color: '#18A7D9' }}>{results.dcPerMessage}</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#FCF5F0' }}>Total DC/day:</span>
              <strong style={{ color: '#18A7D9' }}>{results.totalDC.toLocaleString()}</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#FCF5F0' }}>Daily cost (USD):</span>
              <strong style={{ color: '#FA7F2A' }}>${results.dailyCost}</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#FCF5F0' }}>Monthly cost (USD):</span>
              <strong style={{ color: '#FA7F2A' }}>${results.monthlyCost}</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', paddingTop: '0.5rem', borderTop: '1px solid rgba(252, 245, 240, 0.3)' }}>
              <span style={{ color: '#FCF5F0', fontSize: '1.1rem' }}>Yearly cost (USD):</span>
              <strong style={{ color: '#FA7F2A', fontSize: '1.2rem' }}>${results.yearlyCost}</strong>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
