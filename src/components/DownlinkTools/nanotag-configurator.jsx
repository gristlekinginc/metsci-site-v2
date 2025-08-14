import React, { useState } from 'react';

const NanotagConfigurator = () => {
  const [recordPeriod, setRecordPeriod] = useState(10);
  const [reportPeriod, setReportPeriod] = useState(20);
  const [timeUnit, setTimeUnit] = useState(0);
  const [result, setResult] = useState(null);



  const generateConfig = (record = recordPeriod, report = reportPeriod, unit = timeUnit) => {
    // Validate inputs
    if (record < 1 || record > 65535) {
      alert('Record period must be between 1 and 65535');
      return;
    }
    if (report < 1 || report > 65535) {
      alert('Report period must be between 1 and 65535');
      return;
    }
    
    // Validate that report period is equal to or a multiple of record period
    if (report < record) {
      alert('Report period cannot be shorter than record period. You cannot report data more frequently than you record it.');
      return;
    }
    if (report % record !== 0) {
      alert('Report period must be equal to or a multiple of the record period. For example, if recording every 5 minutes, you can report every 5, 10, 15, 20 minutes, etc.');
      return;
    }

    // Generate hex payload using correct Nanothings format:
    // Bytes 0-1: Record period (big endian) - raw value, not converted to seconds
    // Bytes 2-3: Report period (big endian) - raw value, not converted to seconds
    // Port determines the time unit: 28 = minutes, 29 = seconds
    
    const recordHex = record.toString(16).padStart(4, '0').toUpperCase();
    const reportHex = report.toString(16).padStart(4, '0').toUpperCase();
    
    const hexPayload = recordHex + reportHex;
    
    // Convert hex to base64 for Helium network
    const hexBytes = hexPayload.match(/.{2}/g).map(byte => parseInt(byte, 16));
    const uint8Array = new Uint8Array(hexBytes);
    const base64Payload = btoa(String.fromCharCode(...uint8Array));
    
    const unitText = unit === 0 ? 'minutes' : 'seconds';
    const port = unit === 0 ? 28 : 29; // Port 28 for minutes, Port 29 for seconds
    
    // Calculate actual seconds for display purposes
    const recordSeconds = record * (unit === 0 ? 60 : 1);
    const reportSeconds = report * (unit === 0 ? 60 : 1);
    
    setResult({
      hexPayload,
      base64Payload,
      port,
      record,
      report,
      unitText,
      recordSeconds,
      reportSeconds
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
        MeteoScientific Nanotag Downlink Generator
      </h2>
      

      <div style={{
        marginBottom: '1.5rem',
        padding: '1.5rem',
        backgroundColor: 'rgba(252, 245, 240, 0.05)',
        borderRadius: '8px',
        border: '1px solid rgba(252, 245, 240, 0.2)'
      }}>

        
        <div style={{ display: 'grid', gap: '1rem' }}>
          <div>
            <label htmlFor="recordPeriod" style={{
              display: 'block',
              marginBottom: '0.5rem',
              color: '#FCF5F0',
              fontWeight: '500'
            }}>
              Record Period:
            </label>
            <input 
              type="number" 
              id="recordPeriod" 
              value={recordPeriod}
              onChange={(e) => setRecordPeriod(parseInt(e.target.value))}
              min="1" 
              max="65535"
              style={{
                width: '100%',
                maxWidth: '200px',
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
            <label htmlFor="reportPeriod" style={{
              display: 'block',
              marginBottom: '0.5rem',
              color: '#FCF5F0',
              fontWeight: '500'
            }}>
              Report Period:
            </label>
            <input 
              type="number" 
              id="reportPeriod" 
              value={reportPeriod}
              onChange={(e) => setReportPeriod(parseInt(e.target.value))}
              min="1" 
              max="65535"
              style={{
                width: '100%',
                maxWidth: '200px',
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
            <label htmlFor="timeUnit" style={{
              display: 'block',
              marginBottom: '0.5rem',
              color: '#FCF5F0',
              fontWeight: '500'
            }}>
              Time Unit:
            </label>
            <select 
              id="timeUnit" 
              value={timeUnit}
              onChange={(e) => setTimeUnit(parseInt(e.target.value))}
              style={{
                width: '100%',
                maxWidth: '200px',
                padding: '0.75rem',
                borderRadius: '6px',
                border: '2px solid #18A7D9',
                backgroundColor: '#FCF5F0',
                color: '#000000',
                fontSize: '1rem',
                outline: 'none'
              }}
            >
              <option value="0">Minutes</option>
              <option value="1">Seconds</option>
            </select>
          </div>
        </div>
        
        <button 
          onClick={() => generateConfig()}
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
            boxShadow: '0 4px 12px rgba(24, 167, 217, 0.3)',
            marginTop: '1.5rem'
          }}
          onMouseOver={e => e.target.style.backgroundColor = '#1595c4'}
          onMouseOut={e => e.target.style.backgroundColor = '#18A7D9'}
        >
          Generate Configuration
        </button>
      </div>

      {result && (
        <div style={{
          backgroundColor: 'rgba(24, 167, 217, 0.1)',
          border: '1px solid rgba(24, 167, 217, 0.3)',
          padding: '1.5rem',
          borderRadius: '8px',
          marginBottom: '1.5rem'
        }}>
          <h3 style={{
            marginTop: 0,
            color: '#FCF5F0',
            fontSize: '1.4rem',
            fontWeight: 'bold',
            textShadow: '2px 2px 4px rgba(0, 0, 0, 0.5)'
          }}>
            Downlink Configuration
          </h3>
          <p style={{ color: '#FCF5F0', margin: '0.5rem 0' }}>
            <strong>Target fPort:</strong>
          </p>
          <div style={{
            fontFamily: 'monospace',
            fontSize: '1.5rem',
            fontWeight: 'bold',
            color: '#000000',
            backgroundColor: '#FCF5F0',
            padding: '1rem',
            borderRadius: '6px',
            textAlign: 'center',
            margin: '1rem 0',
            border: '2px solid #18A7D9',
            userSelect: 'all',
            letterSpacing: '2px'
          }}>
            {result.port}
          </div>
          <p style={{ color: '#FCF5F0', margin: '0.5rem 0' }}>
            <strong>Hex Payload:</strong>
          </p>
          <div style={{
            fontFamily: 'monospace',
            fontSize: '1.5rem',
            fontWeight: 'bold',
            color: '#000000',
            backgroundColor: '#FCF5F0',
            padding: '1rem',
            borderRadius: '6px',
            textAlign: 'center',
            margin: '1rem 0',
            border: '2px solid #18A7D9',
            userSelect: 'all',
            letterSpacing: '2px'
          }}>
            {result.hexPayload}
          </div>
          <p style={{ color: '#FCF5F0', margin: '0.5rem 0' }}>
            <strong>Base64 Payload (for MeteoScientific/Helium):</strong>
          </p>
          <div style={{
            fontFamily: 'monospace',
            fontSize: '1.5rem',
            fontWeight: 'bold',
            color: '#000000',
            backgroundColor: '#FCF5F0',
            padding: '1rem',
            borderRadius: '6px',
            textAlign: 'center',
            margin: '1rem 0',
            border: '2px solid #18A7D9',
            userSelect: 'all',
            letterSpacing: '2px'
          }}>
            {result.base64Payload}
          </div>
          <div>
           <p style={{ 
              color: '#18A7D9', 
              fontStyle: 'italic',
              margin: '1rem 0'
            }}>
              The device will record measurements every {result.record} {result.unitText} and send data every {result.report} {result.unitText}.
            </p>
            <p style={{ 
              color: '#FA7F2A', 
              fontStyle: 'italic',
              fontSize: '0.9rem',
              margin: '1rem 0',
              backgroundColor: 'rgba(250, 127, 42, 0.1)',
              padding: '0.75rem',
              borderRadius: '6px',
              border: '1px solid rgba(250, 127, 42, 0.3)'
            }}>
              <strong>For Helium Network:</strong> Use the Base64 payload above and enable confirmed downlinks for best delivery reliability.
            </p>
          </div>
        </div>
      )}

    </div>
  );
};

export default NanotagConfigurator;