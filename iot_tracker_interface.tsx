import React, { useState, useEffect } from 'react';
import { Radio, Activity, AlertTriangle, Wifi, Battery, MapPin, Settings, Users, TrendingUp } from 'lucide-react';

const IoTTrackerInterface = () => {
  const [activeTab, setActiveTab] = useState('map');
  const [sensors, setSensors] = useState([]);
  const [stats, setStats] = useState({ total: 0, active: 0, failed: 0, warning: 0 });
  const [selectedSensor, setSelectedSensor] = useState(null);
  const [crewStatus, setCrewStatus] = useState([]);

  useEffect(() => {
    const mockSensors = Array.from({ length: 50 }, (_, i) => ({
      id: `SNS-${String(i + 1).padStart(4, '0')}`,
      type: ['TRAFFIC', 'AIR_QUAL', 'WATER'][i % 3],
      x: Math.random() * 90 + 5,
      y: Math.random() * 90 + 5,
      z: Math.random() * 3,
      health: Math.random() * 100,
      uptime: Math.random() * 8760,
      nextFail: Math.random() * 2000 + 100,
      queuePos: Math.floor(Math.random() * 10)
    }));
    setSensors(mockSensors);
    
    const active = mockSensors.filter(s => s.health > 70).length;
    const warning = mockSensors.filter(s => s.health > 30 && s.health <= 70).length;
    const failed = mockSensors.filter(s => s.health <= 30).length;
    setStats({ total: mockSensors.length, active, warning, failed });

    setCrewStatus([
      { id: 'CREW-A', assigned: 3, location: 'SECTOR-NE', eta: 12 },
      { id: 'CREW-B', assigned: 1, location: 'SECTOR-SW', eta: 45 },
      { id: 'CREW-C', assigned: 0, location: 'BASE', eta: 0 }
    ]);
  }, []);

  const getHealthColor = (health) => {
    if (health > 70) return '#00ff00';
    if (health > 30) return '#ffaa00';
    return '#ff0000';
  };

  const getSensorIcon = (type) => {
    switch(type) {
      case 'TRAFFIC': return '🚦';
      case 'AIR_QUAL': return '🌫️';
      case 'WATER': return '💧';
      default: return '📡';
    }
  };

  return (
    <div style={{
      width: '100%',
      height: '100vh',
      background: 'linear-gradient(180deg, #1a1a1a 0%, #0d0d0d 100%)',
      fontFamily: '"Courier New", monospace',
      color: '#00ff00',
      display: 'flex',
      flexDirection: 'column',
      overflow: 'hidden'
    }}>
      {/* Antenna */}
      <div style={{
        width: '4px',
        height: '60px',
        background: 'linear-gradient(180deg, #333 0%, #666 100%)',
        margin: '0 auto',
        borderRadius: '2px',
        position: 'relative'
      }}>
        <div style={{
          width: '12px',
          height: '12px',
          background: '#ff0000',
          borderRadius: '50%',
          position: 'absolute',
          top: '-6px',
          left: '-4px',
          animation: 'blink 1s infinite'
        }} />
      </div>

      {/* Header Display */}
      <div style={{
        background: '#1a3a1a',
        border: '4px solid #2a5a2a',
        borderRadius: '8px',
        margin: '10px 20px',
        padding: '15px',
        boxShadow: 'inset 0 0 20px rgba(0,255,0,0.3)'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
          <div style={{ fontSize: '24px', fontWeight: 'bold', letterSpacing: '3px' }}>
            IOT-TRACK-9000
          </div>
          <div style={{ display: 'flex', gap: '15px', alignItems: 'center' }}>
            <Wifi size={20} />
            <Battery size={20} />
            <span style={{ fontSize: '14px' }}>89%</span>
          </div>
        </div>
        <div style={{ fontSize: '12px', opacity: 0.7 }}>
          {new Date().toLocaleString('en-US', { 
            year: 'numeric', 
            month: '2-digit', 
            day: '2-digit', 
            hour: '2-digit', 
            minute: '2-digit', 
            second: '2-digit',
            hour12: false 
          })}
        </div>
      </div>

      {/* Stats Bar */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: '10px',
        margin: '0 20px 10px',
        fontSize: '11px'
      }}>
        {[
          { label: 'TOTAL', value: stats.total, color: '#00aaff' },
          { label: 'ACTIVE', value: stats.active, color: '#00ff00' },
          { label: 'WARNING', value: stats.warning, color: '#ffaa00' },
          { label: 'FAILED', value: stats.failed, color: '#ff0000' }
        ].map(stat => (
          <div key={stat.label} style={{
            background: '#000',
            border: `2px solid ${stat.color}`,
            padding: '8px',
            textAlign: 'center',
            borderRadius: '4px'
          }}>
            <div style={{ opacity: 0.7 }}>{stat.label}</div>
            <div style={{ fontSize: '18px', fontWeight: 'bold', color: stat.color }}>{stat.value}</div>
          </div>
        ))}
      </div>

      {/* Navigation Buttons */}
      <div style={{
        display: 'flex',
        gap: '5px',
        margin: '0 20px 10px',
        flexWrap: 'wrap'
      }}>
        {[
          { id: 'map', icon: MapPin, label: 'MAP' },
          { id: 'sensors', icon: Radio, label: 'SENSORS' },
          { id: 'crews', icon: Users, label: 'CREWS' },
          { id: 'stats', icon: TrendingUp, label: 'ANALYTICS' },
          { id: 'control', icon: Settings, label: 'CONTROL' }
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              flex: 1,
              minWidth: '80px',
              background: activeTab === tab.id ? '#00ff00' : '#1a3a1a',
              color: activeTab === tab.id ? '#000' : '#00ff00',
              border: '2px solid #2a5a2a',
              padding: '10px 5px',
              cursor: 'pointer',
              fontFamily: 'inherit',
              fontSize: '11px',
              fontWeight: 'bold',
              borderRadius: '4px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: '3px'
            }}
          >
            <tab.icon size={16} />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Main Display Area */}
      <div style={{
        flex: 1,
        background: '#0a0a0a',
        border: '3px solid #2a5a2a',
        borderRadius: '8px',
        margin: '0 20px',
        padding: '15px',
        overflow: 'auto',
        boxShadow: 'inset 0 0 30px rgba(0,255,0,0.2)'
      }}>
        {activeTab === 'map' && (
          <div style={{ position: 'relative', height: '100%' }}>
            <div style={{ fontSize: '14px', marginBottom: '10px', textAlign: 'center', fontWeight: 'bold' }}>
              3D CITY SENSOR GRID
            </div>
            <div style={{
              position: 'relative',
              width: '100%',
              height: 'calc(100% - 30px)',
              background: 'radial-gradient(circle, #1a1a1a 0%, #000 100%)',
              border: '1px solid #2a5a2a',
              overflow: 'hidden'
            }}>
              {sensors.map(sensor => (
                <div
                  key={sensor.id}
                  onClick={() => setSelectedSensor(sensor)}
                  style={{
                    position: 'absolute',
                    left: `${sensor.x}%`,
                    top: `${sensor.y}%`,
                    width: `${8 + sensor.z * 2}px`,
                    height: `${8 + sensor.z * 2}px`,
                    background: getHealthColor(sensor.health),
                    borderRadius: '50%',
                    cursor: 'pointer',
                    boxShadow: `0 0 ${10 + sensor.z * 3}px ${getHealthColor(sensor.health)}`,
                    transition: 'all 0.3s',
                    transform: selectedSensor?.id === sensor.id ? 'scale(1.5)' : 'scale(1)',
                    zIndex: selectedSensor?.id === sensor.id ? 10 : 1
                  }}
                  title={`${sensor.id} - ${sensor.type} - ${sensor.health.toFixed(1)}%`}
                />
              ))}
              {selectedSensor && (
                <div style={{
                  position: 'absolute',
                  left: `${Math.min(selectedSensor.x + 5, 70)}%`,
                  top: `${Math.min(selectedSensor.y, 80)}%`,
                  background: 'rgba(0,0,0,0.95)',
                  border: '2px solid #00ff00',
                  padding: '10px',
                  borderRadius: '4px',
                  fontSize: '10px',
                  minWidth: '150px',
                  zIndex: 100
                }}>
                  <div style={{ fontWeight: 'bold', marginBottom: '5px' }}>{selectedSensor.id}</div>
                  <div>TYPE: {selectedSensor.type}</div>
                  <div>HEALTH: {selectedSensor.health.toFixed(1)}%</div>
                  <div>UPTIME: {selectedSensor.uptime.toFixed(0)}h</div>
                  <div>NEXT_FAIL: {selectedSensor.nextFail.toFixed(0)}h</div>
                  <div>QUEUE: #{selectedSensor.queuePos}</div>
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === 'sensors' && (
          <div style={{ height: '100%', overflow: 'auto' }}>
            <table style={{ width: '100%', fontSize: '10px', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid #2a5a2a' }}>
                  <th style={{ padding: '8px', textAlign: 'left' }}>ID</th>
                  <th style={{ padding: '8px', textAlign: 'left' }}>TYPE</th>
                  <th style={{ padding: '8px', textAlign: 'right' }}>HEALTH</th>
                  <th style={{ padding: '8px', textAlign: 'right' }}>UPTIME</th>
                  <th style={{ padding: '8px', textAlign: 'right' }}>EST_FAIL</th>
                  <th style={{ padding: '8px', textAlign: 'center' }}>STATUS</th>
                </tr>
              </thead>
              <tbody>
                {sensors.slice().sort((a, b) => a.health - b.health).map(sensor => (
                  <tr key={sensor.id} style={{ borderBottom: '1px solid #1a3a1a' }}>
                    <td style={{ padding: '8px' }}>{sensor.id}</td>
                    <td style={{ padding: '8px' }}>{getSensorIcon(sensor.type)} {sensor.type}</td>
                    <td style={{ padding: '8px', textAlign: 'right', color: getHealthColor(sensor.health) }}>
                      {sensor.health.toFixed(1)}%
                    </td>
                    <td style={{ padding: '8px', textAlign: 'right' }}>{sensor.uptime.toFixed(0)}h</td>
                    <td style={{ padding: '8px', textAlign: 'right' }}>{sensor.nextFail.toFixed(0)}h</td>
                    <td style={{ padding: '8px', textAlign: 'center' }}>
                      {sensor.health > 70 ? '✓' : sensor.health > 30 ? '⚠' : '✗'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {activeTab === 'crews' && (
          <div>
            <div style={{ fontSize: '14px', marginBottom: '15px', fontWeight: 'bold' }}>
              MAINTENANCE CREW STATUS
            </div>
            {crewStatus.map(crew => (
              <div key={crew.id} style={{
                background: '#1a1a1a',
                border: '2px solid #2a5a2a',
                borderRadius: '4px',
                padding: '12px',
                marginBottom: '10px'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <span style={{ fontWeight: 'bold', fontSize: '12px' }}>{crew.id}</span>
                  <span style={{ fontSize: '11px', opacity: 0.8 }}>{crew.location}</span>
                </div>
                <div style={{ fontSize: '10px', marginBottom: '5px' }}>
                  ASSIGNED TASKS: {crew.assigned}
                </div>
                <div style={{ fontSize: '10px' }}>
                  ETA TO NEXT: {crew.eta > 0 ? `${crew.eta} MIN` : 'STANDBY'}
                </div>
                <div style={{
                  width: '100%',
                  height: '4px',
                  background: '#0a0a0a',
                  marginTop: '8px',
                  borderRadius: '2px',
                  overflow: 'hidden'
                }}>
                  <div style={{
                    width: `${crew.assigned * 33}%`,
                    height: '100%',
                    background: crew.assigned > 2 ? '#ff0000' : crew.assigned > 0 ? '#ffaa00' : '#00ff00'
                  }} />
                </div>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'stats' && (
          <div>
            <div style={{ fontSize: '14px', marginBottom: '15px', fontWeight: 'bold' }}>
              RELIABILITY ANALYTICS
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', fontSize: '11px' }}>
              <div style={{ background: '#1a1a1a', padding: '10px', borderRadius: '4px', border: '1px solid #2a5a2a' }}>
                <div style={{ opacity: 0.7, marginBottom: '5px' }}>MTBF (MEAN TIME BETWEEN FAILURES)</div>
                <div style={{ fontSize: '18px', fontWeight: 'bold' }}>1,847 hrs</div>
              </div>
              <div style={{ background: '#1a1a1a', padding: '10px', borderRadius: '4px', border: '1px solid #2a5a2a' }}>
                <div style={{ opacity: 0.7, marginBottom: '5px' }}>MTTF (MEAN TIME TO FAILURE)</div>
                <div style={{ fontSize: '18px', fontWeight: 'bold' }}>2,134 hrs</div>
              </div>
              <div style={{ background: '#1a1a1a', padding: '10px', borderRadius: '4px', border: '1px solid #2a5a2a' }}>
                <div style={{ opacity: 0.7, marginBottom: '5px' }}>FLEET RELIABILITY</div>
                <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#00ff00' }}>94.7%</div>
              </div>
              <div style={{ background: '#1a1a1a', padding: '10px', borderRadius: '4px', border: '1px solid #2a5a2a' }}>
                <div style={{ opacity: 0.7, marginBottom: '5px' }}>CASCADE RISK</div>
                <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#ffaa00' }}>LOW</div>
              </div>
              <div style={{ background: '#1a1a1a', padding: '10px', borderRadius: '4px', border: '1px solid #2a5a2a', gridColumn: 'span 2' }}>
                <div style={{ opacity: 0.7, marginBottom: '5px' }}>AVG QUEUE WAIT TIME</div>
                <div style={{ fontSize: '18px', fontWeight: 'bold' }}>37 minutes</div>
              </div>
            </div>
            <div style={{ marginTop: '20px', fontSize: '11px' }}>
              <div style={{ fontWeight: 'bold', marginBottom: '10px' }}>ERLANG DISTRIBUTION ANALYSIS</div>
              <div style={{ background: '#1a1a1a', padding: '10px', borderRadius: '4px', border: '1px solid #2a5a2a' }}>
                <div>K-STAGE FAILURES DETECTED: 3</div>
                <div>SHAPE PARAMETER (k): 2.4</div>
                <div>RATE PARAMETER (λ): 0.00054</div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'control' && (
          <div>
            <div style={{ fontSize: '14px', marginBottom: '15px', fontWeight: 'bold' }}>
              DEVELOPER CONTROL PANEL
            </div>
            <div style={{ display: 'grid', gap: '10px' }}>
              {[
                { label: 'RECALCULATE RELIABILITY METRICS', color: '#00aaff' },
                { label: 'OPTIMIZE CREW ROUTING', color: '#00ff00' },
                { label: 'GENERATE REPLACEMENT SCHEDULE', color: '#ffaa00' },
                { label: 'EXPORT SENSOR DATA (CSV)', color: '#00aaff' },
                { label: 'RUN CASCADE SIMULATION', color: '#ff6600' },
                { label: 'UPDATE FAILURE MODELS', color: '#00ff00' },
                { label: 'RESET ALL PARAMETERS', color: '#ff0000' }
              ].map((btn, i) => (
                <button
                  key={i}
                  style={{
                    background: '#1a1a1a',
                    color: btn.color,
                    border: `2px solid ${btn.color}`,
                    padding: '15px',
                    fontSize: '11px',
                    fontFamily: 'inherit',
                    fontWeight: 'bold',
                    cursor: 'pointer',
                    borderRadius: '4px',
                    textAlign: 'left',
                    transition: 'all 0.2s'
                  }}
                  onMouseOver={(e) => {
                    e.target.style.background = btn.color;
                    e.target.style.color = '#000';
                  }}
                  onMouseOut={(e) => {
                    e.target.style.background = '#1a1a1a';
                    e.target.style.color = btn.color;
                  }}
                >
                  ▶ {btn.label}
                </button>
              ))}
            </div>
            <div style={{ marginTop: '20px', fontSize: '10px', opacity: 0.7 }}>
              <div>SYSTEM VERSION: 9000.4.2</div>
              <div>API ENDPOINT: https://api.iot-track.local:8443</div>
              <div>LAST SYNC: 2 SECONDS AGO</div>
            </div>
          </div>
        )}
      </div>

      {/* Bottom Status Bar */}
      <div style={{
        background: '#1a3a1a',
        border: '3px solid #2a5a2a',
        borderRadius: '8px',
        margin: '10px 20px 20px',
        padding: '10px 15px',
        fontSize: '10px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
      }}>
        <div style={{ display: 'flex', gap: '20px' }}>
          <div><Activity size={12} style={{ display: 'inline', marginRight: '5px' }} />SIGNAL: STRONG</div>
          <div><AlertTriangle size={12} style={{ display: 'inline', marginRight: '5px' }} />ALERTS: {stats.failed}</div>
        </div>
        <div>UPLINK: ACTIVE</div>
      </div>

      <style>{`
        @keyframes blink {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.3; }
        }
        
        ::-webkit-scrollbar {
          width: 8px;
          height: 8px;
        }
        
        ::-webkit-scrollbar-track {
          background: #0a0a0a;
        }
        
        ::-webkit-scrollbar-thumb {
          background: #2a5a2a;
          border-radius: 4px;
        }
        
        ::-webkit-scrollbar-thumb:hover {
          background: #00ff00;
        }
      `}</style>
    </div>
  );
};

export default IoTTrackerInterface;