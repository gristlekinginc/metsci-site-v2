import React, { useState } from 'react';

const portsData = [
  {
    port: 1,
    name: 'Port 1 - Set Trip Parameters',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Reserved', type: 'bit', range: '0-0', default: false },
      { offset: '1', description: 'Heartbeat interval', type: 'time', encoding: 'heartbeat', default: { days: 1, hours: 0, minutes: 0, seconds: 0 } },
      { offset: '2', description: 'Trip end timeout', type: 'time', encoding: 'trip_timeout', default: { days: 0, hours: 0, minutes: 5, seconds: 0 } },
      { offset: '3', description: 'In-trip fix work hours', type: 'time', encoding: 'trip_fix', default: { days: 0, hours: 0, minutes: 10, seconds: 0 } },
      { offset: '4', description: 'In-trip fix after hours', type: 'time', encoding: 'trip_fix', default: { days: 0, hours: 0, minutes: 10, seconds: 0 } },
      { offset: '5.0', description: 'Fix on trip start work hours', type: 'bit', range: '0-1', default: true },
      { offset: '5.1', description: 'Fix on trip end work hours', type: 'bit', range: '0-1', default: true },
      { offset: '5.2', description: 'Fix on trip start after hours', type: 'bit', range: '0-1', default: true },
      { offset: '5.3', description: 'Fix on trip end after hours', type: 'bit', range: '0-1', default: true },
      { offset: '5.4', description: 'Optimise GPS for trip tracking', type: 'bit', range: '0-1', default: true },
      { offset: '5.5', description: 'Disable stats messages', type: 'bit', range: '0-1', default: false },
      { offset: '5.6', description: 'Disable wakeup filtering work hours', type: 'bit', range: '0-1', default: false },
      { offset: '5.7', description: 'Disable wakeup filtering after hours', type: 'bit', range: '0-1', default: false },
      { offset: '6', description: 'Accelerometer wakeup threshold (1-8: 63-504mG)', type: 'number', range: '1-8', default: 2 },
      { offset: '7', description: 'Accelerometer wakeup count (1-12: 80-960ms)', type: 'number', range: '1-12', default: 1 }
    ]
  },
  {
    port: 2,
    name: 'Port 2 - Set After-Hours Schedule (Days 1-4)',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Reserved', type: 'bit', range: '0-0', default: false },
      { offset: '1', description: 'Monday start (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '2', description: 'Monday end (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '3', description: 'Tuesday start (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '4', description: 'Tuesday end (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '5', description: 'Wednesday start (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '6', description: 'Wednesday end (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '7', description: 'Thursday start (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '8', description: 'Thursday end (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 }
    ]
  },
  {
    port: 3,
    name: 'Port 3 - Set After-Hours Schedule (Days 5-7)',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Reserved', type: 'bit', range: '0-0', default: false },
      { offset: '1', description: 'Friday start (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '2', description: 'Friday end (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '3', description: 'Saturday start (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '4', description: 'Saturday end (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '5', description: 'Sunday start (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '6', description: 'Sunday end (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 }
    ]
  },
  {
    port: 4,
    name: 'Port 4 - Set Time Zone & Daylight Saving',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7-1.1', description: 'Reserved', type: 'number', range: '0-0', default: 0 },
      { offset: '1.2-2.1', description: 'Normal time zone offset from UTC (hours)', type: 'number', range: '-128-127', default: 0, signed: true },
      { offset: '2.2-2.5', description: 'Daylight saving time shift (hours)', type: 'number', range: '0-15', default: 0 },
      { offset: '2.6-3.0', description: 'Start of DST Nth day of month (0=first, 1=second, etc.)', type: 'number', range: '0-6', default: 0 },
      { offset: '3.1-3.5', description: 'Start DST day of week or absolute day', type: 'number', range: '1-31', default: 0 },
      { offset: '3.6-4.1', description: 'Start DST month (1-12)', type: 'number', range: '1-12', default: 0 },
      { offset: '4.2-5.2', description: 'Start offset from 00:00 local time (minutes)', type: 'number', range: '-512-511', default: 0, signed: true },
      { offset: '5.3-5.5', description: 'End of DST Nth day of month (0=first, 1=second, etc.)', type: 'number', range: '0-6', default: 0 },
      { offset: '5.6-6.2', description: 'End DST day of week or absolute day', type: 'number', range: '1-31', default: 0 },
      { offset: '6.3-6.6', description: 'End DST month (1-12)', type: 'number', range: '1-12', default: 0 },
      { offset: '6.7-7.7', description: 'End offset from 00:00 local DST (minutes)', type: 'number', range: '-512-511', default: 0, signed: true }
    ]
  },
  {
    port: 5,
    name: 'Port 5 - Set GPS Parameters (Basic)',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Require 3D GPS fixes', type: 'bit', range: '0-1', default: false },
      { offset: '1', description: 'Max coarse GPS fix time (45-127: secs, 129-255: mins)', type: 'number', range: '45-127,129-255', default: 131 },
      { offset: '2', description: 'Max fine GPS fix time (1-127: secs, 129-255: mins)', type: 'number', range: '0,1-127,129-255', default: 5 },
      { offset: '3', description: 'Target accuracy for fine GPS fix (meters)', type: 'number', range: '1-255', default: 20 },
      { offset: '4', description: 'Required PDOP (25-100: 2.5-10.0)', type: 'number', range: '25-100', default: 100 },
      { offset: '5', description: 'Required position accuracy (5-100 meters)', type: 'number', range: '5-100', default: 75 },
      { offset: '6', description: 'Required speed accuracy (8-55: 2.88-19.8 km/h)', type: 'number', range: '8-55', default: 28 },
      { offset: '7', description: 'Discard first N GPS points (0-32)', type: 'number', range: '0-32', default: 3 }
    ]
  },
  {
    port: 6,
    name: 'Port 6 - Set GPS Parameters (Advanced)',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Reserved', type: 'bit', range: '0-0', default: false },
      { offset: '1', description: 'Daily GPS budget (45-127: secs, 129-255: mins, 0: unlimited)', type: 'number', range: '0,45-127,129-255', default: 0 },
      { offset: '2', description: 'Max time for 1st satellite (×5s, 0: disable)', type: 'number', range: '0-255', default: 12 },
      { offset: '3', description: 'Max time for 2nd satellite (×5s)', type: 'number', range: '0-255', default: 12 },
      { offset: '4', description: 'Max time for 3rd satellite (×5s)', type: 'number', range: '0-255', default: 12 },
      { offset: '5', description: 'Max time for 4th satellite (×5s)', type: 'number', range: '0-255', default: 12 },
      { offset: '6.0-6.4', description: 'Satellite detection margin (-16 to +15 dB)', type: 'number', range: '-16-15', default: 0, signed: true },
      { offset: '6.5', description: 'Enable Autonomous Aiding', type: 'bit', range: '0-1', default: false },
      { offset: '6.6-6.7', description: 'Reserved', type: 'number', range: '0-0', default: 0 },
      { offset: '7', description: 'GPS model (0: Portable, 2: Stationary, 3: Pedestrian, 4: Auto)', type: 'number', range: '0,2-8', default: 4 },
      { offset: '8-9', description: 'Max error from Autonomous Aiding (5-1000m, 0: auto)', type: 'number', range: '0,5-1000', default: 100 }
    ]
  },
  {
    port: 7,
    name: 'Port 7 - Set LoRaWAN Channels & Data Rate',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Reserved', type: 'bit', range: '0-0', default: false },
      { offset: '1.0-1.3', description: 'Minimum data rate when ADR disabled (DR0-DR15)', type: 'number', range: '0-15', default: 0 },
      { offset: '1.4-1.7', description: 'Maximum data rate when ADR disabled (DR0-DR15)', type: 'number', range: '0-15', default: 2 },
      { offset: '2', description: 'Uplink channel mask (9 bytes as hex string, e.g. 000000000000000000 for all disabled)', type: 'hex', length: 9, default: '000000000000000000' }
    ]
  },
  {
    port: 8,
    name: 'Port 8 - Set LoRaWAN Join EUI',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Set Join EUI', type: 'bit', range: '0-1', default: false },
      { offset: '1', description: 'JoinEUI (8 bytes big-endian hex string, e.g. 70B3D57050000000)', type: 'hex', length: 8, default: '70B3D57050000000' }
    ]
  },
  {
    port: 9,
    name: 'Port 9 - Advanced LoRaWAN Options',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Reserved', type: 'bit', range: '0-0', default: false },
      { offset: '1', description: 'Days between network joins (days)', type: 'number', range: '0-255', default: 7 },
      { offset: '2.0-2.1', description: 'ADR support (0=disabled, 1=enabled, 2=forced)', type: 'number', range: '0-3', default: 0 },
      { offset: '2.2-2.3', description: 'Reserved', type: 'number', range: '0-0', default: 0 },
      { offset: '2.4-2.7', description: 'Initial frame repetitions (count)', type: 'number', range: '1-15', default: 1 },
      { offset: '3.0-3.3', description: 'Initial MaxCount0 (retries)', type: 'number', range: '0-15', default: 15 },
      { offset: '3.4-3.7', description: 'Initial MaxTime0 (seconds)', type: 'number', range: '0-15', default: 15 },
      { offset: '4.0-4.3', description: 'Initial AdrAckLimitExp (exponent)', type: 'number', range: '0-15', default: 6 },
      { offset: '4.4-4.7', description: 'Initial AdrAckDelayExp (exponent)', type: 'number', range: '0-15', default: 5 },
      { offset: '5', description: 'Maximum Tx power limit (dBm)', type: 'number', range: '-128-127', default: 127, signed: true },
      { offset: '6', description: 'Random Tx delay (seconds)', type: 'number', range: '0-255', default: 0 }
    ]
  },
  {
    port: 10,
    name: 'Port 10 - Man Down Detection',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Reserved', type: 'bit', range: '0-0', default: false },
      { offset: '1.0-1.1', description: 'Man Down fix on set (0=none, 1=low-accuracy, 2=high-accuracy)', type: 'number', range: '0-2', default: 0 },
      { offset: '1.2-1.3', description: 'Man Down fix on clear (0=none, 1=low-accuracy, 2=high-accuracy)', type: 'number', range: '0-2', default: 0 },
      { offset: '1.4-1.7', description: 'Reserved', type: 'number', range: '0-0', default: 0 },
      { offset: '2', description: 'Man Down timeout (minutes)', type: 'number', range: '0-255', default: 0 }
    ]
  },
  {
    port: 11,
    name: 'Port 11 - Scheduled Uploads (Times 1-10)',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Retry fix if network not ready', type: 'bit', range: '0-1', default: false },
      { offset: '1', description: 'Scheduled upload time 1 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '2', description: 'Scheduled upload time 2 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '3', description: 'Scheduled upload time 3 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '4', description: 'Scheduled upload time 4 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '5', description: 'Scheduled upload time 5 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '6', description: 'Scheduled upload time 6 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '7', description: 'Scheduled upload time 7 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '8', description: 'Scheduled upload time 8 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '9', description: 'Scheduled upload time 9 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '10', description: 'Scheduled upload time 10 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 }
    ]
  },
  {
    port: 12,
    name: 'Port 12 - Scheduled Uploads (Times 11-12)',
    fields: [
      { offset: '0.0-0.6', description: 'Downlink sequence number', type: 'number', range: '0-127', default: 0 },
      { offset: '0.7', description: 'Reserved', type: 'bit', range: '0-0', default: false },
      { offset: '1', description: 'Scheduled upload time 11 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 },
      { offset: '2', description: 'Scheduled upload time 12 (7.5-min intervals from midnight)', type: 'number', range: '0-192', default: 0 }
    ]
  }
];

// Time encoding functions
const encodeTime = (timeObj, encoding) => {
  const totalSeconds = timeObj.days * 86400 + timeObj.hours * 3600 + timeObj.minutes * 60 + timeObj.seconds;
  
  switch (encoding) {
    case 'heartbeat':
      // 1-127: minutes, 129-255: hours
      if (totalSeconds === 0) return 0;
      
      const totalMinutes = Math.round(totalSeconds / 60);
      const totalHours = Math.round(totalSeconds / 3600);
      
      if (totalMinutes <= 127) {
        return totalMinutes;
      } else if (totalHours <= 127) {
        return 128 + totalHours;
      } else {
        return 255; // Max value
      }
      
    case 'trip_timeout':
      // 10-second units, 0 = disable
      if (totalSeconds === 0) return 0;
      return Math.min(255, Math.round(totalSeconds / 10));
      
    case 'trip_fix':
      // 1-127: seconds, 129-255: minutes, 0 or 128 = disable
      if (totalSeconds === 0) return 0;
      
      const totalMinutes2 = Math.round(totalSeconds / 60);
      
      if (totalSeconds <= 127) {
        return totalSeconds;
      } else if (totalMinutes2 <= 127) {
        return 128 + totalMinutes2;
      } else {
        return 255; // Max value
      }
      
    default:
      return 0;
  }
};

const decodeTime = (value, encoding) => {
  switch (encoding) {
    case 'heartbeat':
      if (value === 0) return { days: 0, hours: 0, minutes: 0, seconds: 0 };
      if (value <= 127) {
        return { days: 0, hours: 0, minutes: value, seconds: 0 };
      } else {
        const hours = value - 128;
        return { days: 0, hours, minutes: 0, seconds: 0 };
      }
      
    case 'trip_timeout':
      if (value === 0) return { days: 0, hours: 0, minutes: 0, seconds: 0 };
      const seconds = value * 10;
      return { 
        days: 0, 
        hours: Math.floor(seconds / 3600), 
        minutes: Math.floor((seconds % 3600) / 60), 
        seconds: seconds % 60 
      };
      
    case 'trip_fix':
      if (value === 0 || value === 128) return { days: 0, hours: 0, minutes: 0, seconds: 0 };
      if (value <= 127) {
        return { days: 0, hours: 0, minutes: 0, seconds: value };
      } else {
        const minutes = value - 128;
        return { days: 0, hours: 0, minutes, seconds: 0 };
      }
      
    default:
      return { days: 0, hours: 0, minutes: 0, seconds: 0 };
  }
};

const parseOffset = (offset) => {
  if (typeof offset === 'number') return { byte: offset, bitStart: 0, bitEnd: 7, bits: 8 };
  if (offset.includes('-')) {
    const [start, end] = offset.split('-').map(s => s.trim());
    const [byteStart, bitStart = 0] = start.split('.').map(Number);
    const [byteEnd, bitEnd = 7] = end.split('.').map(Number);
    
    // Calculate total bits correctly for multi-byte ranges
    let totalBits;
    if (byteStart === byteEnd) {
      // Same byte - just count bits
      totalBits = bitEnd - bitStart + 1;
    } else {
      // Multiple bytes - count bits in first byte + full middle bytes + bits in last byte
      const firstByteBits = 8 - bitStart;
      const middleBytes = Math.max(0, byteEnd - byteStart - 1);
      const lastByteBits = bitEnd + 1;
      totalBits = firstByteBits + (middleBytes * 8) + lastByteBits;
    }
    
    return { byte: byteStart, bitStart, bitEnd: bitStart + totalBits - 1, bits: totalBits };
  } else if (offset.includes('.')) {
    const [byte, bit] = offset.split('.').map(Number);
    return { byte, bitStart: bit, bitEnd: bit, bits: 1 };
  } else {
    const byte = Number(offset);
    return { byte, bitStart: 0, bitEnd: 7, bits: 8 };
  }
};

const DownlinkGenerator = () => {
  const [selectedPort, setSelectedPort] = useState(portsData[0].port);
  const [values, setValues] = useState({});
  const [output, setOutput] = useState('');

  const currentPort = portsData.find(p => p.port === selectedPort);
  const maxByte = Math.max(...currentPort.fields.map(f => {
    const parsed = parseOffset(f.offset);
    if (f.type === 'hex') {
      return parsed.byte + f.length - 1;
    } else {
      // For bit fields, calculate the highest byte used
      const lastBitPosition = parsed.bitStart + parsed.bits - 1;
      return parsed.byte + Math.floor(lastBitPosition / 8);
    }
  })) + 1;
  const initialValues = currentPort.fields.reduce((acc, f) => ({ ...acc, [f.description]: f.default }), {});
  if (Object.keys(values).length === 0) setValues(initialValues);

  const handleChange = (desc, value) => setValues(prev => ({ ...prev, [desc]: value }));

  const handleTimeChange = (desc, timeField, value) => {
    setValues(prev => ({
      ...prev,
      [desc]: {
        ...prev[desc],
        [timeField]: Number(value)
      }
    }));
  };

  const generate = () => {
    const bytes = new Uint8Array(maxByte).fill(0);
    currentPort.fields.forEach(f => {
      let val = values[f.description];
      
      if (f.type === 'bit') {
        val = val ? 1 : 0;
      } else if (f.type === 'time') {
        val = encodeTime(val, f.encoding);
      }
      
      if (f.type === 'hex') {
        const parsed = parseOffset(f.offset);
        const hexStr = val.replace(/\s/g, '');
        for (let i = 0; i < f.length; i++) {
          if (i * 2 + 1 < hexStr.length) {
            bytes[parsed.byte + i] = parseInt(hexStr.substr(i * 2, 2), 16);
          }
        }
        return;
      }
      
      const parsed = parseOffset(f.offset);
      let bits = parsed.bits;
      
      // Handle signed numbers
      if (f.signed && val < 0) {
        val = (1 << bits) + val;
      }
      
      // Set bits in the correct positions
      for (let i = 0; i < bits; i++) {
        if (val & (1 << i)) {
          const globalBitPos = parsed.bitStart + i;
          const byteIndex = parsed.byte + Math.floor(globalBitPos / 8);
          const bitInByte = globalBitPos % 8;
          
          if (byteIndex < bytes.length) {
            bytes[byteIndex] |= (1 << bitInByte);
          }
        }
      }
    });
    
    const hex = Array.from(bytes).map(b => b.toString(16).padStart(2, '0').toUpperCase()).join('');
    setOutput(`Port: ${selectedPort}, Payload: ${hex}`);
  };

  return (
    <div>
      <select onChange={e => { setSelectedPort(Number(e.target.value)); setValues({}); }}>
        {portsData.map(p => <option key={p.port} value={p.port}>{p.name}</option>)}
      </select>
      {currentPort.fields.map(f => (
        <div key={f.description} style={{ marginBottom: '10px' }}>
          {f.type === 'bit' ? (
            <label style={{ display: 'flex', alignItems: 'center', fontWeight: 'bold', gap: '8px' }}>
              <input 
                type="checkbox" 
                checked={values[f.description]} 
                onChange={e => handleChange(f.description, e.target.checked)} 
              />
              {f.description}:
            </label>
          ) : (
            <>
              <label style={{ display: 'block', fontWeight: 'bold', marginBottom: '5px' }}>
                {f.description}:
              </label>
              {f.type === 'hex' ? (
                <input 
                  type="text" 
                  value={values[f.description]} 
                  onChange={e => handleChange(f.description, e.target.value)}
                  placeholder={`Range: ${f.range}`}
                />
              ) : f.type === 'time' ? (
                <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                  <label>Days: 
                    <input 
                      type="number" 
                      min="0" 
                      max="31" 
                      value={values[f.description]?.days || 0} 
                      onChange={e => handleTimeChange(f.description, 'days', e.target.value)}
                      style={{ width: '60px', marginLeft: '5px' }}
                    />
                  </label>
                  <label>Hours: 
                    <input 
                      type="number" 
                      min="0" 
                      max="23" 
                      value={values[f.description]?.hours || 0} 
                      onChange={e => handleTimeChange(f.description, 'hours', e.target.value)}
                      style={{ width: '60px', marginLeft: '5px' }}
                    />
                  </label>
                  <label>Minutes: 
                    <input 
                      type="number" 
                      min="0" 
                      max="59" 
                      value={values[f.description]?.minutes || 0} 
                      onChange={e => handleTimeChange(f.description, 'minutes', e.target.value)}
                      style={{ width: '60px', marginLeft: '5px' }}
                    />
                  </label>
                  <label>Seconds: 
                    <input 
                      type="number" 
                      min="0" 
                      max="59" 
                      value={values[f.description]?.seconds || 0} 
                      onChange={e => handleTimeChange(f.description, 'seconds', e.target.value)}
                      style={{ width: '60px', marginLeft: '5px' }}
                    />
                  </label>
                </div>
              ) : (
                <input 
                  type="number" 
                  value={values[f.description]} 
                  onChange={e => handleChange(f.description, Number(e.target.value))}
                  placeholder={`Range: ${f.range}`}
                />
              )}
            </>
          )}
        </div>
      ))}
      <button onClick={generate}>Generate Downlink</button>
      <p>{output}</p>
    </div>
  );
};

export default DownlinkGenerator;